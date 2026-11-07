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
	if tempo > 150:
		push_error("Timeout cartellini")
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
	await evento(pos, 0)
	await evento(pos, 2)
func drag(da: Vector2, a: Vector2) -> void:
	await evento(da, 0)
	await evento(a, 1)
	await evento(a, 2)
func action(nome: String) -> void:
	var e := InputEventAction.new(); e.action = nome; e.pressed = true; Input.parse_input_event(e)
	await frames()
	e = InputEventAction.new(); e.action = nome; Input.parse_input_event(e)
	await frames()
func scegli(azione: String) -> void:
	n.buttons = n.visuale.bersagli()
	for i in n.buttons.size():
		if n.buttons[i].action == azione:
			n.selected = i
			await action("confirm")
			return
	check(false, "Oggetto da tastiera mancante: " + azione)
func crea() -> void:
	GameState.minigame = {"boss_floor": "-3"}
	n = Control.new()
	n.set_script(load("res://tests/spia_cartellini.gd"))
	get_tree().root.add_child(n)
	get_tree().current_scene = n
	await frames()
func fresh() -> void:
	GameState.new_game()
	GameState.floor_id = "-3"
	B.state("-3").merge({"status": "active", "instructions_seen": true, "return": Router.MERCATO}, true)
	await crea()
func applica() -> void:
	await clic(n.visuale.rett("Applica").get_center())
	if n.visuale.conferma_aperta: await clic(n.visuale.rett("Conferma/Applica").get_center())
	# I tocchi ripetuti mentre il cartellino si applica non avanzano al prodotto dopo.
	await clic(n.visuale.rett("Applica").get_center())
	await clic(n.visuale.rett("Applica").get_center())
	await get_tree().create_timer(0.4).timeout
func _ready() -> void:
	GameState.save_path = "user://test_cartellini_isolato.json"
	await frames()
	for size in [Vector2i(640, 360), Vector2i(1280, 720), Vector2i(1000, 600)]:
		get_window().size = size
		for tel in [false, true]:
			for nasconde in [false, true]:
				touch = tel; TouchControls.enabled = tel
				await fresh()
				var v: Node = n.visuale
				await clic(v.rett("Applica").get_center())
				check(int(n.p.round) == 0 and GameState.money == 0, "Non si applica un cartellino ancora da stampare")
				await clic(v.rett("Rotella").get_center())
				check(int(n.p.rate) == 10, "La rotella cambia la percentuale")
				await drag(v.rett("Listini/Listino1").get_center(), Vector2(330, 40))
				check(int(n.p.reference) == 0, "Listino rilasciato fuori dalla stampante non cambia la base")
				await drag(v.rett("Listini/Listino1").get_center(), v.rett("Riferimento").get_center())
				check(int(n.p.reference) == 1, "Il listino futuro entra nella stampante")
				await clic(v.rett("Stampa").get_center())
				await clic(v.rett("Applica").get_center())
				check(int(n.p.round) == 0 and not B.market_preview(n.p).valid, "Non si spaccia per sconto un prezzo superiore a quello di oggi")
				await clic(v.rett("Rotella").get_center())
				check(not B.market_print_current(), "Cambiare percentuale rende vecchia la stampa")
				await clic(v.rett("Applica").get_center())
				check(int(n.p.round) == 0, "La stampa vecchia non viene applicata")
				await clic(v.rett("Stampa").get_center())
				await drag(v.rett("Prodotti/Minimo2").get_center(), Vector2(330, 40))
				check(int(n.p.units) == 1, "Prodotto rilasciato fuori dalla cassa non cambia il minimo")
				await drag(v.rett("Prodotti/Minimo2").get_center(), v.rett("Cassa").get_center())
				check(int(n.p.units) == 2 and not B.market_print_current(), "Due prodotti cambiano minimo e richiedono ristampa")
				await clic(v.rett("Stampa").get_center())
				var prima: Vector2 = B.market_sticker_position("discount")
				await drag(v.rett_adesivo("discount").get_center(), v.rett("Cartellino").position + Vector2(120, 122))
				check(B.market_sticker_position("discount") == prima and n.p.visible and n.msg != "", "Sovrapporre non nasconde le condizioni e non cambia la disposizione")
				await drag(v.rett_adesivo("discount").get_center(), Vector2(400, 40))
				check(B.market_sticker_position("discount") == prima and n.p.visible, "Rilascio fuori dal cartellino annulla")
				await drag(v.rett_adesivo("discount").get_center(), v.rett("Cartellino").position + Vector2(74, 59))
				check(B.market_sticker_position("discount") == Vector2(4, 30), "La composizione accetta una disposizione alternativa leggibile")
				await drag(v.rett_adesivo("conditions").get_center(), v.rett("Terminale").get_center())
				check(not n.p.visible and B.market_preview(n.p).hidden and int(v.v.basket) == 2500, "Le condizioni al terminale lasciano il costo reale visibile alla cassa")
				await clic(v.rett("Applica").get_center())
				check(v.conferma_aperta and int(n.p.round) == 0 and GameState.money == 0, "Le condizioni nascoste richiedono conferma separata")
				await clic(v.rett("Applica").get_center())
				check(v.conferma_aperta and int(n.p.round) == 0, "Ripetere il gesto precedente non conferma")
				await clic(v.rett("Conferma/Indietro").get_center())
				check(not v.conferma_aperta and int(n.p.round) == 0, "Si può tornare alla bozza senza conseguenze")
				await drag(v.rett_adesivo("conditions").get_center(), v.rett("Cartellino").position + Vector2(121, 129))
				check(n.p.visible and not B.market_preview(n.p).hidden and B.market_print_current(), "Rimettere le condizioni ripristina la leggibilità senza cambiare l'offerta")
				var bozza: Dictionary = n.p.duplicate(true)
				B.checkpoint("-3"); GameState.load_game()
				n.queue_free(); await frames(); await crea(); v = n.visuale
				check(n.p == JSON.parse_string(JSON.stringify(bozza)) and B.market_print_current(), "Ripresa conserva offerta, stampa e disposizione")
				if nasconde: await drag(v.rett_adesivo("conditions").get_center(), v.rett("Terminale").get_center())
				await applica()
				check(int(n.p.round) == 1 and n.p.labels.size() == 1 and not n.p.has("label_work") and GameState.money == 0, "La prima etichetta avanza una volta senza anticipare il premio")
				check(int(n.p.units) == 1 and int(n.p.rate) == 0 and n.p.visible, "Il nuovo prodotto parte con condizioni trasparenti")
				for i in 2:
					if nasconde: await clic(v.rett("Prodotti/Minimo2").get_center())
					await clic(v.rett("Stampa").get_center())
					if nasconde: await drag(v.rett_adesivo("conditions").get_center(), v.rett("Terminale").get_center())
					await applica()
				check(n.completato and GameState.money == (1500 if nasconde else 0), "Tre cartellini mantengono i premi delle due scelte narrative")
				check(int(B.state("-3").result.hidden) == (3 if nasconde else 0) and not GameState.is_robot("amir"), "Reclami e umanità di Amir restano coerenti")
				var saldo := GameState.money
				B.finish_market()
				check(B.submit_prepared_market() != "" and GameState.money == saldo and n.p.labels.size() == 3, "Nessun quarto cartellino e nessun doppio premio")
				n.queue_free(); await frames()
	touch = false; TouchControls.enabled = false
	await fresh()
	var v: Node = n.visuale
	await scegli("label_rate")
	await scegli("label_stampa")
	check(B.market_print_current() and int(n.p.rate) == 10, "Tastiera imposta e stampa l'offerta")
	await scegli("label_discount")
	var da: Vector2 = B.market_sticker_position("discount")
	var key := InputEventKey.new(); key.keycode = KEY_RIGHT; key.shift_pressed = true; key.pressed = true; Input.parse_input_event(key)
	await frames()
	key = InputEventKey.new(); key.keycode = KEY_RIGHT; key.shift_pressed = true; Input.parse_input_event(key)
	await frames()
	check(B.market_sticker_position("discount") == da + Vector2(4, 0), "Tastiera sposta le etichette senza trascinare")
	await action("ui_cancel")
	await scegli("label_units_2"); await scegli("label_stampa")
	await scegli("label_conditions"); await scegli("label_terminale")
	check(not n.p.visible and v.in_mano == "", "Tastiera sposta le condizioni al terminale")
	await scegli("label_conditions"); await scegli("label_cartellino")
	check(n.p.visible, "Tastiera rimette le condizioni sul cartellino")
	await scegli("label_applica")
	await get_tree().create_timer(0.4).timeout
	check(int(n.p.round) == 1, "Tastiera applica il cartellino completo")
	n.queue_free(); await frames()
	print("BOSS CARTELLINI: %d controlli, errori %s" % [controlli, errori])
	get_tree().quit(errori.size())
