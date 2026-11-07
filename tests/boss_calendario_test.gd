extends Node
const B := preload("res://scripts/boss_missions.gd")
var n: Node
var touch := false
var controlli := 0
var errori: Array[String] = []
var tempo := 0.0
func check(ok: bool, nota: String) -> void:
	controlli += 1
	if not ok:
		errori.append(nota)
		push_error(nota)
func _process(dt: float) -> void:
	tempo += dt
	if tempo > 100:
		push_error("Timeout calendario")
		get_tree().quit(1)
func frames() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
func evento(pos: Vector2, fase: int) -> void:
	pos = get_viewport().get_screen_transform() * n.get_global_transform_with_canvas() * pos
	if touch:
		if fase == 1:
			var e := InputEventScreenDrag.new(); e.index = 0; e.position = pos; Input.parse_input_event(e)
		else:
			var e := InputEventScreenTouch.new(); e.index = 0; e.position = pos; e.pressed = fase == 0; Input.parse_input_event(e)
	else:
		if fase == 1:
			var e := InputEventMouseMotion.new(); e.position = pos; e.button_mask = MOUSE_BUTTON_MASK_LEFT; Input.parse_input_event(e)
		else:
			var e := InputEventMouseButton.new(); e.button_index = MOUSE_BUTTON_LEFT; e.position = pos; e.global_position = pos; e.pressed = fase == 0; Input.parse_input_event(e)
	await frames()
func clic(pos: Vector2) -> void:
	await evento(pos, 0); await evento(pos, 2)
func drag(da: Vector2, a: Vector2) -> void:
	await evento(da, 0); await evento(a, 1); await evento(a, 2)
func action(nome: String) -> void:
	var e := InputEventAction.new(); e.action = nome; e.pressed = true; Input.parse_input_event(e)
	await frames()
	e = InputEventAction.new(); e.action = nome; Input.parse_input_event(e)
	await frames()
func scegli(azione: String) -> void:
	n.buttons = n.visuale.bersagli()
	for i in n.buttons.size():
		if n.buttons[i].action == azione:
			n.selected = i; await action("confirm"); return
	check(false, "Oggetto non raggiungibile da tastiera: " + azione)
func crea() -> void:
	GameState.minigame = {"boss_floor": "-2"}
	n = Control.new(); n.set_script(load("res://tests/spia_calendario.gd"))
	get_tree().root.add_child(n); get_tree().current_scene = n
	await frames()
func fresh() -> void:
	GameState.new_game(); GameState.floor_id = "-2"
	B.state("-2").merge({"status": "active", "instructions_seen": true, "return": Router.BANCA}, true)
	await crea()
func chiudi() -> void:
	n.queue_free(); get_tree().current_scene = self
	await frames()
func _ready() -> void:
	GameState.save_path = "user://test_calendario_isolato.json"
	await frames()
	for size in [Vector2i(640, 360), Vector2i(1280, 720), Vector2i(1000, 600)]:
		get_window().size = size
		for tel in [false, true]:
			for nascosto in [false, true]:
				touch = tel; TouchControls.enabled = tel
				await fresh()
				var v: Node = n.visuale
				var soldi: int = GameState.money
				await clic(v.rett("Calendario/Anno1").get_center())
				check(int(n.p.months) == 12 and int(v.v.monthly) > 6500, "Un anno supera il budget")
				await clic(v.rett("Invia").get_center())
				check(not v.conferma_aperta and B.active("-2") and GameState.money == soldi, "Non si invia una rata fuori budget")
				var breve: Dictionary = B.contract_preview(n.p)
				await get_tree().create_timer(0.18).timeout
				await drag(v.maniglia().get_center(), Vector2(352, 110))
				check(int(n.p.months) == 36 and int(v.v.monthly) < int(breve.monthly) and int(v.v.total) > int(breve.total), "Allungare il calendario abbassa rata e aumenta costo")
				await clic(v.rett("Tasso").get_center())
				check(int(n.p.apr) == 8 and int(v.v.total) > int(B.contract_preview({"months":36,"apr":4,"fee":0}).total), "La rotella del tasso aggiorna il costo")
				var rata: int = v.v.monthly
				var totale: int = v.v.total
				await clic(v.rett("Spesa").get_center())
				check(int(n.p.fee) == 60 and int(v.v.monthly) == rata and int(v.v.total) == totale + 6000, "La spesa iniziale non si finge parte della rata")
				await drag(v.rett_riepilogo().get_center(), Vector2(400, 40))
				check(bool(n.p.visible), "Rilascio fuori dalle copie annulla")
				await drag(v.rett_riepilogo().get_center(), v.rett("Interno").get_center())
				check(not bool(n.p.visible) and v.riepilogo_interno.contains(B.cash(int(v.v.total))), "Il foglio ripiegato non nasconde il totale al giocatore")
				var snapshot: Dictionary = n.p.duplicate(true)
				await chiudi()
				GameState.load_game(); await crea(); v = n.visuale
				check(n.p == JSON.parse_string(JSON.stringify(snapshot)) and GameState.money == soldi and B.active("-2"), "Salvare la bozza mantiene entrambe le copie senza inviare")
				await drag(v.rett_riepilogo().get_center(), v.rett("Olga").get_center())
				check(bool(n.p.visible) and int(v.v.total) == totale + 6000, "Restituire il foglio a Olga conserva tutti i costi")
				if nascosto:
					await clic(v.rett_riepilogo().get_center())
					await clic(v.rett("Interno").get_center())
				await clic(v.rett("Invia").get_center())
				check(v.conferma_aperta and not n.completato, "Ogni proposta richiede una conferma")
				await clic(v.rett("Invia").get_center())
				check(v.conferma_aperta and not n.completato, "Doppio tocco sul vecchio invio non conferma")
				await clic(v.rett("Conferma/Indietro").get_center())
				check(not v.conferma_aperta and B.active("-2"), "Si può rivedere la proposta senza conseguenze")
				await clic(v.rett("Invia").get_center())
				await clic(v.rett("Conferma/Invia").get_center())
				await clic(v.rett("Conferma/Invia").get_center())
				await get_tree().create_timer(0.38).timeout
				check(n.completato and str(B.state("-2").status) == "done", "L'invio termina l'incarico")
				check(GameState.money == soldi + (3000 if nascosto else 0), "Premio originale, accreditato una sola volta")
				check(not GameState.is_robot("teo"), "Inviare non robotizza Teo")
				var r: Dictionary = GameState.flags.get("boss_olga_offer", {})
				check(not r.is_empty() and bool(r.visible) == not nascosto and int(r.months) == 36 and int(r.fee) == 60, "La proposta canonica conserva costi e visibilità")
				var risposta := " ".join(B.result_lines("-2"))
				check(risposta.contains("prima di firmare" if nascosto else "non è ancora una firma"), "Olga deve ancora scegliere, nessun prestito firmato")
				check(B.set_contract_value("months", 12) != "", "La proposta già inviata non cambia")
				await chiudi()
	touch = false; TouchControls.enabled = false
	await fresh()
	await scegli("loan_year_36")
	check(int(n.p.months) == 36, "Tastiera usa il calendario")
	await scegli("loan_summary"); await scegli("loan_interno")
	check(not bool(n.p.visible), "Tastiera ripiega il riepilogo")
	await scegli("loan_summary"); await action("ui_cancel")
	check(not n.visuale.in_mano, "Annulla restituisce il foglio")
	await scegli("loan_invia"); await action("ui_cancel")
	check(not n.visuale.conferma_aperta and B.active("-2"), "Annulla chiude la conferma")
	await scegli("loan_summary"); await scegli("loan_olga")
	check(bool(n.p.visible), "Tastiera restituisce il riepilogo a Olga")
	check(B.set_contract_value("months", 0) != "" and B.set_contract_value("inventato", 1) != "", "Valori fuori elenco non entrano nella bozza")
	await chiudi()
	print("CALENDARIO OLGA: %d controlli, errori %s" % [controlli, errori])
	get_tree().quit(errori.size())
