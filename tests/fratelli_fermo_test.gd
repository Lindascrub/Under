extends "res://tests/smoke_test.gd"
const C6 := preload("res://chapters/c6/cima_c6.gd")
const RULES := preload("res://chapters/c6/direzione_regole.gd")
var checks := 0
var lines: Array[String] = []
var shots := ""
var shot_busy := false
var photographed: Dictionary = {}
var section := ""
var moving_actor: Node2D
var moved := 0.0
var actor_last := Vector2.ZERO
var blocked_samples := 0

func _check(ok: bool, message: String) -> void:
	checks += 1
	super(ok,message)

func _process(_delta: float) -> void:
	_frame += 1
	var scene := get_tree().current_scene
	if scene and scene.scene_file_path == Router.FINALE: scene.fast = true
	if is_instance_valid(moving_actor) and moving_actor.busy:
		moved += actor_last.distance_to(moving_actor.global_position)
		actor_last = moving_actor.global_position
		var shape := RectangleShape2D.new(); shape.size = Vector2(8,4)
		var query := PhysicsShapeQueryParameters2D.new(); query.shape=shape;query.collision_mask=1
		query.transform=Transform2D(0,moving_actor.global_position+Vector2(0,-2))
		query.exclude=[moving_actor.body.get_rid()]
		if not moving_actor.get_world_2d().direct_space_state.intersect_shape(query).is_empty(): blocked_samples += 1
	if shot_busy: return
	if Ui.busy:
		var label: Label = Ui.get("_label")
		if is_instance_valid(label) and label.text not in lines: lines.append(label.text)
		if not shots.is_empty() and is_instance_valid(label) and label.visible_ratio >= 1:
			var key := section+"|"+label.text+"|"+str(Ui.get("_mode"))
			if not photographed.has(key):
				photographed[key]=true
				capture("%03d_%s" % [photographed.size(),section])
				return
		if _frame % 3 == 0:
			if Ui.get("_mode") == "choose":
				var selection: int = choose_queue.pop_front() if not choose_queue.is_empty() else choose_index
				Ui.set("_sel",mini(selection,(Ui.get("_options") as Array).size()-1))
			_tap("confirm")

func capture(name: String) -> void:
	if shots.is_empty(): return
	shot_busy=true
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shots.path_join(name+".png"))
	shot_busy=false

func fresh() -> void:
	GameState.new_game()
	GameState.player_name="Linda"
	GameState.flags["c1_arrivo"]=true
	GameState.flags["c2_arrivo"]=true
	GameState.flags["c4_arrivo"]=true
	GameState.flags["fermo_talked"]=true
	GameState.flags["met_fermo"]=true
	GameState.flags["fermo_called"]=true
	GameState.flags["boss_missions"]={"-5":{"status":"legacy","seen":true},"-4":{"status":"legacy","seen":true}}
	lines.clear()

func heard(text: String) -> bool:
	return " ".join(lines).contains(text)

func economy() -> Array:
	return [GameState.money,GameState.debt,GameState.minutes,GameState.helped,GameState.self_esteem,GameState.badges.duplicate(),GameState.helped_ids.duplicate()]

func walk_player(room: Room, goal: Vector2) -> void:
	var path := room.walk_path(room.player.global_position,goal,[room.player.get_rid()])
	_check(not path.is_empty(),"percorso a piedi fino al fratello disponibile")
	for point: Vector2 in path:
		var ticks := 0
		while room.player.global_position.distance_to(point)>3 and ticks<500:
			var delta := point-room.player.global_position
			for action in ["move_left","move_right","move_up","move_down"]: Input.action_release(action)
			Input.action_press("move_"+("right" if delta.x>0 else "left") if absf(delta.x)>absf(delta.y) else "move_"+("down" if delta.y>0 else "up"))
			await get_tree().physics_frame
			ticks+=1
		_check(ticks<500,"giocatore passa fisicamente nell'ufficio senza restare incastrato")
	for action in ["move_left","move_right","move_up","move_down"]: Input.action_release(action)
	await get_tree().physics_frame

func _run() -> void:
	GameState.save_path="user://test_fratelli_fermo.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--foto="): shots=arg.trim_prefix("--foto=")
	if not shots.is_empty(): DirAccess.make_dir_recursive_absolute(shots)
	for tel in [false,true]:
		fresh()
		TouchControls.enabled=tel
		section="touch" if tel else "pc"
		var npc_count := GameState.npc_ids().size()
		var floor_games := GameState.floor_minigames("-4").duplicate()
		var office := await _go(Router.BANCA)
		var brother: Node2D=office.get_node("Mondo/FratelloFermo")
		_check(brother.visible,"fratello presente in Banca")
		await walk_player(office,Vector2(328,164))
		office.player.face("up")
		_check(office.player._find_target()==brother.get_node("Parla"),"tastiera/OK prende il fratello, non un mobile")
		var before := economy()
		if tel:
			await get_tree().process_frame
			var down:=InputEventScreenTouch.new();down.index=0;down.position=Vector2(592,292);down.pressed=true;Input.parse_input_event(down)
			var up:=InputEventScreenTouch.new();up.index=0;up.position=down.position;Input.parse_input_event(up)
		else:
			_tap("confirm")
		for i in 240:
			await get_tree().process_frame
			if FratelliFermo.state().get("met",false) and not Ui.blocks_input(): break
		await _idle()
		_check(FratelliFermo.state().get("met",false) and heard("Sono suo fratello"),"incontro reale prima di conoscere il messaggio")
		_check(not FratelliFermo.delivered() and economy()==before,"incontro facoltativo senza costi o messaggi inventati")
		var fondo := await _go(Router.FONDO)
		section+=("_messaggio")
		await fondo._talk_fermo()
		_check(FratelliFermo.has_message() and heard("Lui capisce"),"Fermo affida il messaggio anche dopo aver incontrato prima il fratello")
		office=await _go(Router.BANCA)
		brother=office.get_node("Mondo/FratelloFermo")
		choose_index=1
		before=economy()
		await brother.talk()
		_check(not FratelliFermo.delivered() and economy()==before,"non adesso lascia l'incontro disponibile")
		choose_index=0
		section+="_consegna"
		moving_actor=brother;actor_last=brother.global_position;moved=0;blocked_samples=0
		await brother.talk()
		_check(FratelliFermo.delivered() and not brother.visible,"messaggio consegnato, il fratello è partito")
		_check(heard("Vado a vedere come funziona lassù. Poi torno.") and heard("Pensavo che ormai non volesse più vedermi"),"passato e risposta approvati mostrati")
		_check(moved>45 and blocked_samples==0,"il fratello cammina alle scale senza attraversare oggetti")
		_check(economy()==before,"nessuna ricompensa, ora o requisito aggiunto")
		GameState.save_game(Router.BANCA,office.player.position)
		GameState.new_game()
		var loaded := GameState.load_game()
		_check(not loaded.is_empty() and FratelliFermo.delivered(),"la consegna sopravvive al salvataggio e caricamento")
		office=await _go(Router.BANCA)
		_check(not office.get_node("Mondo/FratelloFermo").visible,"nessun doppione rimasto in ufficio dopo il caricamento")
		fondo=await _go(Router.FONDO)
		brother=fondo.get_node("Mondo/FratelloFermo")
		_check(brother.visible and not FratelliFermo.reunited(),"il fratello aspetta al Fondo")
		# Non dipendere dal rialzo automatico della camera dei dialoghi.
		fondo.alza_nei_dialoghi=0;fondo.camera_lift=0
		fondo.player.camera.offset=Vector2(4,-6)
		var camera_before: Vector2=fondo.player.camera.offset
		var camera_top: bool=fondo.player.camera.top_level
		before=economy();lines.clear();section+="_ricongiungimento"
		moving_actor=brother;actor_last=brother.global_position;moved=0;blocked_samples=0
		await fondo._talk_fermo()
		_check(FratelliFermo.reunited() and heard("Poteva almeno scendere a chiedermelo") and heard("La torta è ancora quella"),"risposta e ricongiungimento completo")
		_check(moved>200 and blocked_samples==0,"camminata nel Fondo senza attraversare muri o mobili")
		_check(brother.sprite.animation==&"sit_right" and brother.position.distance_to(Vector2(208,84))<12,"fratello seduto davvero accanto alla cassetta")
		_check(not Ui.cutscene and fondo.player.camera.offset==camera_before and fondo.player.camera.top_level==camera_top,"camera e comandi ripristinati")
		_check(economy()==before and GameState.npc_ids().size()==npc_count and GameState.floor_minigames("-4")==floor_games,"economia, legami e stelle invariati")
		await capture(section+"_seduti")
		_check(not await FratelliFermo.talk_fermo(fondo),"il ricongiungimento non si ripete e i dialoghi ordinari restano disponibili")
		GameState.save_game(Router.FONDO,fondo.player.position)
		GameState.new_game();GameState.load_game()
		fondo=await _go(Router.FONDO)
		_check(FratelliFermo.reunited() and fondo.get_node("Mondo/FratelloFermo").sprite.animation==&"sit_right","posa e progresso restano dopo ricaricamento")
		lines.clear();before=economy()
		await fondo.get_node("Mondo/FratelloFermo").talk()
		_check(heard("Sto imparando a stare qui"),"primo saluto dopo il ricongiungimento")
		lines.clear()
		await fondo.get_node("Mondo/FratelloFermo").talk()
		_check(heard("Sono ancora al primo giorno"),"saluto successivo diverso")
		_check(economy()==before and not Ui.cutscene,"saluti senza costi o comandi bloccati")
	# Un vecchio messaggio resta valido, senza inventare che il giocatore lo abbia già consegnato.
	fresh();GameState.flags["fermo_badge_line"]=true
	_check(FratelliFermo.has_message() and not FratelliFermo.delivered(),"compatibilità con la vecchia battuta sul sosia")
	# Percorso con Fondo sbarrato: il fratello resta dal lato corretto del divieto.
	fresh();GameState.flags["fermo_badge_line"]=true;GameState.flags["c1_sbarrato"]=true
	var blocked_office := await _go(Router.BANCA)
	var blocked_brother: Node2D=blocked_office.get_node("Mondo/FratelloFermo")
	choose_index=0;section="scale_chiuse";lines.clear()
	await blocked_brother.talk()
	_check(not blocked_brother.visible, "il fratello lascia la Banca anche se il Fondo è chiuso")
	blocked_office=await _go(Router.SOTTOUFFICIO)
	blocked_brother=blocked_office.get_node("Mondo/FratelloFermo")
	await blocked_brother.talk()
	_check(FratelliFermo.delivered() and blocked_brother.visible and not FratelliFermo.pending_visit(),"scale chiuse: messaggio consegnato, nessuna discesa impossibile")
	_check(heard("Potevo tornare quando erano aperte") and not heard("La torta è ancora quella"),"dialogo riconosce il blocco senza fingere una riunione")
	_check(blocked_brother.position.distance_to(Vector2(36,212))<1,"fratello rimasto davanti al blocco")
	# Vecchio Fermo robot: si può visitare, ma il dialogo non lo ripristina.
	fresh();GameState.robots.append("fermo");FratelliFermo.state()["delivered"]=true
	var robot_room := await _go(Router.FONDO)
	section="ritorno_robot";lines.clear()
	await robot_room._talk_fermo()
	_check(GameState.is_robot("fermo") and not FratelliFermo.reunited() and FratelliFermo.state().get("robot_visit_seen",false),"visita reale al vecchio Fermo robot senza guarigione inventata")
	_check(heard("BUONA FESTA") and not heard("La torta è ancora quella"),"risposta robot diversa dalla riconciliazione umana")
	if "--solo-storia" in OS.get_cmdline_user_args():
		print("FRATELLI FERMO SCENE: %d controlli, errori %s" % [checks,_failures])
		get_tree().quit(0 if _failures.is_empty() else 1)
		return
	# Chiusura nell'epilogo reale di ogni variante, anche senza ritorno del giocatore al Fondo.
	TouchControls.enabled=false
	for variant in ["A1","A2","A3","B1","B2","C1","C2","C3","robot","nessun_messaggio","scale_chiuse","gia_riuniti"]:
		fresh();section="epilogo_"+variant
		GameState.flags["fermo_badge_line"]=true
		FratelliFermo.state()["delivered"]=variant!="nessun_messaggio"
		if variant=="scale_chiuse":GameState.flags["c1_sbarrato"]=true
		if variant=="gia_riuniti":FratelliFermo.state()["reunited"]=true
		if variant=="robot": GameState.robots.append("fermo")
		var d:=C6.c6()
		var family: String=variant.left(1) if variant.length()==2 else "A"
		d.final_decision.confirmed=true;d.final_decision.selected=family
		d.director_turn.state=RULES.new_state()
		d.outcome={"family":family,"variant":variant if variant.length()==2 else "A1","debt_status":"registrato","governance_status":"","engine":2}
		d.epilogue.step=5
		choose_queue=[5];choose_index=0;lines.clear()
		Router.goto(Router.FINALE)
		await _wait_scene(Router.FINALE)
		await _wait_scene(Router.MENU,100000)
		await _idle()
		_check(C6.c6().completed,"epilogo arriva ai titoli: "+variant)
		if variant=="gia_riuniti":
			_check(FratelliFermo.reunited() and heard("Scendo anche domani") and not heard("La torta è ancora quella"),"nell'epilogo non si ripete una riunione già vista")
		elif variant=="scale_chiuse":
			_check(not FratelliFermo.reunited() and FratelliFermo.state().get("closed_epilogue_seen",false) and not heard("La torta è ancora quella"),"epilogo a scale chiuse rispetta il blocco")
		elif variant=="robot":
			_check(not FratelliFermo.reunited() and FratelliFermo.state().get("robot_visit_seen",false) and not heard("La torta è ancora quella"),"vecchio Fermo robot non torna umano per la visita")
		elif variant=="nessun_messaggio":
			_check(not FratelliFermo.reunited() and not heard("La torta è ancora quella"),"nessuna riunione inventata senza aver consegnato il messaggio")
		else:
			_check(FratelliFermo.reunited() and heard("La torta è ancora quella") and C6.c6().outcome.variant==variant,"chiusura visibile senza cambiare il finale: "+variant)
	print("FRATELLI FERMO: %d controlli, errori %s" % [checks,_failures])
	get_tree().quit(0 if _failures.is_empty() else 1)
