extends "res://tests/smoke_test.gd"
const C6 := preload("res://chapters/c6/cima_c6.gd")
const IDS := ["bulbo","mina","tilde","ercole","leda","amir","olga","teo","ada","nadir"]
var checks := 0
var said: Array[String] = []
var options_seen: Array = []
var route_count := 0
var work_target := ""
func check(ok: bool, note: String) -> void:
	checks += 1
	_check(ok,note)
func _process(_dt: float) -> void:
	_frame += 1
	if Ui.busy:
		var label: Label = Ui.get("_label")
		if is_instance_valid(label) and label.text not in said: said.append(label.text)
		if Ui.get("_mode")=="choose":
			var opts: Array=Ui.get("_options")
			if not opts in options_seen: options_seen.append(opts.duplicate())
		if _frame%2==0:
			if Ui.get("_mode")=="choose":
				var selection: int=choose_queue.pop_front() if not choose_queue.is_empty() else choose_index
				Ui.set("_sel",mini(selection,(Ui.get("_options") as Array).size()-1))
			_tap("confirm")
	elif _frame%2==0 and _scene_path()==Router.MINIGAME and get_tree().current_scene.phase=="done": _tap("confirm")
func fresh() -> void:
	GameState.new_game()
	GameState.save_path="user://test_correzioni_nov9.json"
	for flag in ["c1_arrivo","c2_arrivo","c3_arrivo","c4_arrivo","c5_arrivo","c5_casa","fermo_talked","fermo_called"]: GameState.flags[flag]=true
	GameState.flags["boss_missions"]={}
	for f in ["-5","-4","-3","-2","0","cima"]: GameState.flags.boss_missions[f]={"status":"legacy","seen":true}
	Ui.cutscene=false
	choose_index=0;choose_queue=[];said.clear();options_seen.clear()
func heard(s: String) -> bool: return " ".join(said).contains(s)
func result(id: String, success: bool, misses: int, previous: int) -> void:
	var data:=GameState.npc_data(id)
	var cfg:=Npc.minigame_cfg(id,data.name,data.help,Router.MENU,Vector2.ZERO)
	cfg.intro=[];cfg.prima_prova=false
	if int(GameState.flags.get("tentativi_"+id,0))>0:
		cfg.rigioco=true;cfg.stelle_prima=previous
	GameState.minigame=cfg
	var old:=get_tree().current_scene
	var mg: Node=load(Router.MINIGAME).instantiate()
	get_tree().root.add_child(mg);get_tree().current_scene=mg
	if old!=self and is_instance_valid(old):old.queue_free()
	await get_tree().process_frame
	mg.set_process(false)
	if mg.visivo:mg.visivo.set_process(false)
	if mg.has_node("ErcoleGomitata"):mg.get_node("ErcoleGomitata").set_process(false)
	mg.phase="play";mg.misses=misses
	mg._risposta.fermo_vittoria=0;mg._risposta.durata_stelle=0.03
	await mg._finish(success)
	await _wait_scene(Router.MENU)
	await _idle()
func walk(room: Room, goal: Vector2) -> bool:
	var path:=room.walk_path(room.player.global_position,goal,[room.player.get_rid()],Vector2(16,8))
	if path.is_empty():
		print("WALK EMPTY ",room.name," from ",room.player.position," goal ",goal)
		return false
	for point: Vector2 in path:
		var ticks:=0
		while room.player.global_position.distance_to(point)>1.0 and ticks<1500:
			var delta:=point-room.player.global_position
			for action in ["move_left","move_right","move_up","move_down"]:Input.action_release(action)
			var direction := delta.normalized()
			if absf(direction.x)>0.01:Input.action_press("move_right" if direction.x>0 else "move_left",absf(direction.x))
			if absf(direction.y)>0.01:Input.action_press("move_down" if direction.y>0 else "move_up",absf(direction.y))
			await get_tree().physics_frame
			ticks+=1
		if ticks>=1500:
			print("WALK STUCK ",room.name," at ",room.player.position," next ",point," goal ",goal)
			for action in ["move_left","move_right","move_up","move_down"]:Input.action_release(action)
			return false
	for action in ["move_left","move_right","move_up","move_down"]:Input.action_release(action)
	return true
func _run() -> void:
	Ui.velocita_scrittura=100000
	get_tree().create_timer(360).timeout.connect(func():print("CORREZIONI TIMEOUT: ",checks);get_tree().quit(2))
	if "--solo-accessi" in OS.get_cmdline_user_args():
		await accessi()
		print("ACCESSI NOV9: %d controlli, errori %s"%[checks,_failures])
		get_tree().quit(0 if _failures.is_empty() else 1)
		return
	# Dieci partite terminate davvero: la nona resta disponibile, la decima chiude.
	fresh()
	for n in 10:
		GameState.minutes=GameState.DAY_START
		await result("bulbo",false,3,0)
		check(int(GameState.flags.get("tentativi_bulbo",0))==n+1,"conto persistente prova %d"%(n+1))
		check(GameState.minigame_closed("bulbo")== (n==9),"chiusura solo al decimo tentativo")
	check(GameState.minigame_mastered("bulbo") and int(GameState.flags.get("stelle_bulbo",0))==3,"dopo dieci prove: tre stelle per l'impegno")
	GameState.save_game(Router.MENU);GameState.new_game();GameState.load_game()
	check(GameState.minigame_closed("bulbo") and int(GameState.flags.tentativi_bulbo)==10,"chiusura e tentativi sopravvivono al caricamento")
	for id: String in IDS:
		fresh();GameState.flags["tentativi_"+id]=9
		var before:=GameState.minutes
		await result(id,false,3,0)
		check(GameState.minigame_closed(id) and GameState.minigame_mastered(id),id+": al decimo tentativo arrivano le tre stelle")
		check(GameState.minutes==before+GameState.COST_HELP_TIME,id+": esattamente un'ora, senza doppio costo")
		check(id in GameState.helped_ids and heard(str(GameState.npc_data(id).help.minigame.dopo_dieci[0])),id+": impegno riconosciuto e battuta realmente mostrata")
		for flag: String in GameState.npc_data(id).help.minigame.get("win_flags",[]):check(bool(GameState.flags.get(flag,false))==(not flag.ends_with("_bonus")),id+": al decimo tentativo il lavoro risulta fatto, senza premi in denaro "+flag)
		var npc: Npc=load("res://scripts/npc.tscn").instantiate();npc.id=id;add_child(npc)
		options_seen.clear();await npc._offer_replay(npc.display_name())
		check(options_seen.is_empty(),id+": nessuna undicesima partita proposta")
		npc.queue_free()
	fresh();GameState.flags.tentativi_bulbo=9
	await result("bulbo",true,0,0)
	check(GameState.minigame_mastered("bulbo") and not GameState.flags.get("aiuto_concluso_bulbo",false),"tre stelle al decimo restano una vittoria normale")
	for floor_id in ["-5","-4","-3","-2","0"]:
		fresh()
		for id in GameState.floor_minigames(floor_id):GameState.flags["aiuto_concluso_"+id]=true
		check(GameState.floor_minigames_mastered(floor_id),floor_id+": rinunce riconosciute per il regalo di Nives")
		GameState.robots.append(GameState.floor_minigames(floor_id)[0])
		check(not GameState.floor_minigames_mastered(floor_id),floor_id+": sfruttare non dà il regalo")
	# Il lancio avviene anche lontano dalle case; la facciata intera accetta il pacco.
	for touch in [false,true]:
		TouchControls.enabled=touch
		var game: Node=load("res://scenes/minigame/rifatti/consegne.tscn").instantiate();add_child(game);game.avvia({});game.set_process(false)
		var house: Node=game.porte[0];game.corsia=game.corsie.find(house.position.y)
		house.position.x=game.get_node("Mira").position.x+game.velocita*game.durata_lancio+50
		game.punta(Vector2(20,340),0);game.punta(Vector2(20,340),2)
		await get_tree().create_timer(0.4).timeout
		check(game.consegnati==1 and game.errori==0,"Amir: tocco ovunque e impatto sulla casa fuori dalla porta "+str(touch))
		if touch:
			var packages: int=game.rimasti
			game.punta(Vector2(10,300),0);game.punta(Vector2(10,220),1);game.punta(Vector2(10,220),2)
			check(game.rimasti==packages,"Amir: swipe cambia corsia senza lanciare")
		game.queue_free();await get_tree().process_frame
	TouchControls.enabled=false
	# Agenda timbra quando le parli, senza richiedere una seconda consegna.
	fresh();GameState.flags.c2_b4=true;GameState.flags.c2_firma=true;GameState.flags.c2_timbro=true
	var room: Room=await _go(Router.SOTTOUFFICIO)
	options_seen.clear();await room._agenda()
	check(GameState.flags.get("c2_modulo_ok",false) and not str(options_seen).contains("Ecco il modulo"),"Agenda: autorizzazione registrata direttamente nel dialogo")
	# Tre comparse distinte: collisione fisica e interazione al posto della sedia.
	fresh();room=await _go(Router.BANCA)
	for n in room.find_children("SedutoAttesa*","",true,false):
		check(n.has_node("CorpoSeduto/CollisionShape2D") or n.get_node("CorpoSeduto").get_child_count()>0,"Banca: corpo solido di "+n.name)
		room.player.global_position=n.global_position+Vector2(0,18);room.player.face("up")
		check(room.player._find_target()==n.get_node("Parla"),"Banca: la persona seduta vince sulla sedia "+n.name)
		said.clear();await n.get_node("Parla").interact();await _idle()
		check(not said.is_empty(),"Banca: cliente risponde "+n.name)
	# Non si fanno copiare ricevute a chi ha rifiutato la richiesta.
	GameState.flags.c4_olga=true;GameState.flags.c4_olga_contestazione=true;GameState.flags.c4_teo_aiutato=true
	said.clear();await room._farewell()
	check(not heard("Dammi la ricevuta") and not GameState.flags.get("c4_ricevuta_copia",false),"rifiuto della richiesta: nessuna copia o promessa di risposta")
	# Teo sul divano mantiene il gioco accessibile (qui si rifiuta senza costo).
	fresh();GameState.flags.c4_olga=true;GameState.flags.c4_olga_contestazione=true;GameState.flags.c4_teo=true;GameState.flags.c4_teo_aiutato=true
	GameState.helped_ids.assign(["olga","teo"]);GameState.flags.stelle_teo=2
	room=await _go(Router.BANCA);choose_index=1
	options_seen.clear();await room._talk_on_sofa("teo");await _idle()
	check(str(options_seen).contains("Riprova"),"Teo sul divano propone di nuovo il minigioco")
	await accessi()
	print("CORREZIONI NOV9: %d controlli, errori %s"%[checks,_failures])
	get_tree().quit(0 if _failures.is_empty() else 1)

func accessi() -> void:
	var room: Room
	# Accesso camminando ai turni: non si usa l'apertura diretta della postazione.
	for test in [[Router.MERCATO,Vector2(204,250),"left"],[Router.CITY,Vector2(320,266),"up"]]:
		fresh();room=await _go(test[0])
		check(await walk(room,test[1]),"percorso fisico fino al turno "+str(test[0]))
		room.player.face(test[2]);await get_tree().physics_frame
		var target:=room.player._find_target()
		check(target!=null and target.has_meta("job_id"),"tasto sceglie il turno e non un mobile "+str(test[0]))
		if target and target.has_meta("job_id"):
			choose_index=0;target.interact();await _wait_scene(Router.WORK)
			check(_scene_path()==Router.WORK,"turno avviato dalla mappa "+str(test[0]))
	# La Presidente avvia direttamente il turno dal proprio menu.
	fresh();C6.c6().elevator.intro_seen=true;C6.c6().president.offer_received=true;C6.c6().president.met=true
	room=await _go(Router.CIMA)
	check(room.get_node("Pavimento").get_used_rect().end.x>=58,"Cima: mappa effettivamente ampliata")
	check(await walk(room,Vector2(696,180)),"Cima: Presidente raggiungibile camminando")
	choose_queue=[4];room._president_menu();await _wait_scene(Router.DIREZIONE)
	check(_scene_path()==Router.DIREZIONE and str(options_seen).contains("Cominciamo il turno"),"turno della Presidente parte dalla scelta del dialogo")
