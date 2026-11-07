extends Node
const R := preload("res://chapters/c6/direzione_regole.gd")
var n: Node
var tel := false
var checks := 0
var errori: Array[String] = []
var tempo := 0.0
var automatico := false
func check(ok: bool, testo: String) -> void:
	checks += 1
	if not ok: errori.append(testo); push_error(testo)
func _process(dt: float) -> void:
	tempo += dt
	if tempo > 120: push_error("Timeout tavolo"); get_tree().quit(1)
	if automatico and Ui.busy:
		if Ui.get("_mode") == "choose":
			var opzioni: Array = Ui.get("_options")
			if opzioni.has("Mantieni le tutele"): Ui.set("_sel", 0)
		var e := InputEventAction.new(); e.action = "confirm"; e.pressed = true; Input.parse_input_event(e)
		e = InputEventAction.new(); e.action = "confirm"; Input.parse_input_event(e)
func frames() -> void:
	await get_tree().process_frame; await get_tree().process_frame
func evento(pos: Vector2, fase: int) -> void:
	pos = get_viewport().get_screen_transform() * n.get_global_transform_with_canvas() * pos
	if tel:
		if fase == 1:
			var e := InputEventScreenDrag.new(); e.index=0; e.position=pos; Input.parse_input_event(e)
		else:
			var e := InputEventScreenTouch.new(); e.index=0; e.position=pos; e.pressed=fase==0; Input.parse_input_event(e)
	else:
		if fase == 1:
			var e := InputEventMouseMotion.new(); e.position=pos; e.button_mask=MOUSE_BUTTON_MASK_LEFT; Input.parse_input_event(e)
		else:
			var e := InputEventMouseButton.new(); e.position=pos; e.global_position=pos; e.button_index=MOUSE_BUTTON_LEFT; e.pressed=fase==0; Input.parse_input_event(e)
	await frames()
func clic(pos: Vector2) -> void:
	await evento(pos,0); await evento(pos,2)
func drag(da: Vector2, a: Vector2) -> void:
	await evento(da,0); await evento(a,1); await evento(a,2)
func key(nome: String) -> void:
	var e := InputEventAction.new(); e.action=nome; e.pressed=true; Input.parse_input_event(e)
	await frames()
	e = InputEventAction.new(); e.action=nome; Input.parse_input_event(e)
	await frames()
func crea(fresh := true) -> void:
	if fresh:
		GameState.new_game()
		GameState.flags["c5_assemblea"] = true
		GameState.flags["c5_esito"] = "comunitaria"
	n = Node2D.new(); n.set_script(load("res://tests/spia_tavolo.gd"))
	get_tree().root.add_child(n); get_tree().current_scene=n
	await frames()
func chiudi() -> void:
	n.queue_free(); get_tree().current_scene=self; await frames()
func centro(i: int) -> Vector2:
	return n.visuale.vasca(i).position + Vector2(72,65)
func _ready() -> void:
	GameState.save_path = "user://tavolo_direzione_test.json"
	await frames()
	# Regole del movimento: non duplicare fondi, non saltare i contratti, preservare le anteprime.
	var st := R.new_state()
	for da in [-1,0,1,2,3]:
		for dest in [-1,0,1,2,3]:
			for amount in [1,5,100]:
				var a := R.transfer(st, R.BASE, da, dest, amount)
				check(R.total(a) <= 100 and int(a.stipendi)>=30 and a.values().all(func(v):return int(v)>=0 and int(v)<=60), "Trasferimento entro fondi e contratti")
	var snapshot := st.duplicate(true)
	for mode in ["", "tutele", "tariffe", "accentrata", "condivisa"]:
		st.mandate=mode
		for alloc in [R.BASE, {"stipendi":55,"servizi":25,"manutenzione":15,"riserve":5}, {"stipendi":30,"servizi":10,"manutenzione":0,"riserve":60}]:
			var before := st.duplicate(true)
			var p := R.preview(st,alloc)
			var reale := st.duplicate(true); R.apply(reale,alloc)
			check(p.state == reale and st == before, "Anteprima esatta e priva di effetti sullo stato")
	st=snapshot
	for size in [Vector2i(640,360),Vector2i(1280,720),Vector2i(1000,600)]:
		get_window().size=size
		for touch in [false,true]:
			tel=touch; TouchControls.enabled=touch; await crea()
			var before: Dictionary = n.alloc.duplicate()
			await drag(centro(3), Vector2(630,350))
			check(n.alloc == before, "Fuori da una destinazione si annulla")
			await drag(centro(3), centro(1))
			check(int(n.alloc.riserve)==10 and int(n.alloc.servizi)==25 and R.total(n.alloc)==100, "Trascinare sposta cinque unità vere")
			check(int(n.visuale.preview.services_eff)==25, "Il servizio si allarga nell'anteprima")
			await clic(n.visuale.rett("Passo").get_center())
			await drag(centro(3),centro(0))
			check(int(n.alloc.stipendi)==41 and int(n.alloc.riserve)==9 and n.visuale.passo==1, "Il gettone preciso trasferisce una unità")
			await clic(n.minus_button(2).get_center())
			check(R.total(n.alloc)==99, "Togliere una unità la lascia sul tavolo")
			await clic(n.visuale.rett("Liberi").get_center()); await clic(centro(2))
			check(R.total(n.alloc)==100 and int(n.alloc.manutenzione)==25, "Selezione e destinazione assegnano le unità libere")
			await clic(n.plus_button(0).get_center())
			check(R.total(n.alloc)==100 and int(n.alloc.stipendi)==41, "Non si creano fondi con il pulsante più")
			n.visuale.passo=5
			n.alloc={"stipendi":40,"servizi":20,"manutenzione":39,"riserve":1};n._sync_view()
			await drag(centro(3),centro(1))
			check(int(n.alloc.riserve)==0 and int(n.alloc.servizi)==21 and n.visuale.anim_quantita==1, "Il gettone residuo trasferisce e anima una sola unità")
			n.alloc={"stipendi":30,"servizi":20,"manutenzione":25,"riserve":25};n._sync_view()
			await drag(centro(0),centro(3))
			check(int(n.alloc.stipendi)==30 and int(n.alloc.riserve)==25, "Non si spostano i contratti già dovuti")
			n.alloc=R.BASE.duplicate();n._save_draft()
			var a: Dictionary=n.alloc.duplicate()
			await chiudi();GameState.load_game();await crea(false)
			check(n.alloc==JSON.parse_string(JSON.stringify(a)) and n.phase=="alloc", "La bozza riparte con gli stessi fondi")
			# La stessa scelta istituzionale ora richiede selezione e applicazione distinta.
			n.phase="casa"; n.options=R.casa_options(n.st,n.alloc);n._sync_view()
			await clic(n.option_button(0).get_center())
			check(n.phase=="casa" and n.casa_id=="", "Toccare una scelta apre i dettagli senza applicarla")
			automatico=true
			await clic(n.confirm_button().get_center())
			for i in 1000:
				await frames()
				if n.phase=="debiti" and not Ui.busy:break
			automatico=false
			check(n.phase=="debiti" and n.casa_id=="risorse", "Il secondo gesto sceglie la Casa")
			await chiudi();GameState.load_game();await crea(false)
			check(n.phase=="debiti" and n.casa_id=="risorse", "Ripresa mantiene Casa scelta e mandato")
			check(n.intro_chiamate==0, "Riprendere dai debiti non ripete la richiesta di distribuire i fondi")
			await clic(n.option_button(2).get_center())
			await clic(n.confirm_button().get_center())
			check(n.phase=="debiti" and n.msg!="", "Una revisione senza prove resta chiusa")
			await clic(n.option_button(0).get_center());await clic(n.confirm_button().get_center())
			check(n.scelta_finale=="conservare", "Solo la scelta aperta arriva alla conclusione")
			await chiudi()
	TouchControls.enabled=false;tel=false;await crea()
	n.visuale.focus=0;await key("confirm");await key("move_right");await key("confirm")
	check(int(n.alloc.stipendi)==35 and int(n.alloc.servizi)==25, "Frecce e INVIO trasferiscono fra destinazioni adiacenti")
	await key("confirm");await key("ui_cancel")
	check(n.visuale.preso == -2, "Annulla lascia il gettone senza spendere")
	await chiudi()
	# Le vecchie bozze hanno solo ciclo e alloc; i cicli diversi venivano già ignorati.
	GameState.flags["chapter_6"]["director_turn"]["draft"]={"cycle":1,"alloc":{"stipendi":45,"servizi":20,"manutenzione":25,"riserve":10}}
	await crea(false)
	check(n.phase=="alloc" and int(n.alloc.stipendi)==45 and n.casa_id=="" and str(n.st.mandate)=="", "Una vecchia bozza senza fase resta modificabile")
	await chiudi()
	GameState.flags["chapter_6"]["director_turn"]["draft"]={"cycle":2,"alloc":R.BASE.duplicate(),"phase":"debiti","casa_id":"proroga","mandate":"tariffe"}
	await crea(false)
	check(n.phase=="alloc" and n.casa_id=="" and str(n.st.mandate)=="", "Una bozza di un vecchio ciclo non applica decisioni nel turno unico")
	await chiudi()
	print("TAVOLO DIREZIONE: %d controlli, errori %s" % [checks,errori])
	get_tree().quit(errori.size())
