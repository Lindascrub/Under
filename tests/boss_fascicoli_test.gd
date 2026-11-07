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
	if tempo > 120:
		push_error("Timeout fascicoli")
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

func crea() -> void:
	GameState.minigame = {"boss_floor": "-4"}
	n = Control.new()
	n.set_script(load("res://tests/spia_fascicoli.gd"))
	get_tree().root.add_child(n)
	get_tree().current_scene = n
	await frames()

func fresh() -> void:
	GameState.new_game()
	GameState.floor_id = "-4"
	B.state("-4").merge({"status": "active", "instructions_seen": true, "return": Router.SOTTOUFFICIO}, true)
	await crea()

func sistema() -> void:
	var v: Node = n.visuale
	for i in v.campi.size():
		if v.campi[i].available: await drag(v.rett_carta(i).get_center(), v.rett_sagoma(i).get_center())

func timbra(indice: int) -> void:
	await drag(n.visuale.rett("Timbri/Timbro%d" % indice).get_center(), Vector2(315, 284))

func consegna() -> void:
	await clic(n.visuale.rett("Consegna").get_center())
	await get_tree().create_timer(0.42).timeout

func scegli(azione: String) -> void:
	n.buttons = n.visuale.bersagli()
	for i in n.buttons.size():
		if n.buttons[i].action == azione:
			n.selected = i
			await action("confirm")
			return
	check(false, "Bersaglio da tastiera mancante: " + azione)

func _ready() -> void:
	GameState.save_path = "user://test_fascicoli_isolato.json"
	await frames()
	for size in [Vector2i(640, 360), Vector2i(1280, 720), Vector2i(1000, 600)]:
		get_window().size = size
		for tel in [false, true]:
			for chiude in [false, true]:
				touch = tel; TouchControls.enabled = tel
				await fresh()
				var v: Node = n.visuale
				await consegna()
				check(int(n.p.document) == 0 and not n.completato, "Non si consegna senza preparare e timbrare")
				await timbra(3)
				check(B.document_stamp() == -1, "Il timbro non sostituisce i documenti")
				await drag(v.rett_carta(0).get_center(), Vector2(350, 45))
				check(B.document_placed().is_empty(), "Rilascio fuori dal fascicolo annulla")
				await drag(v.rett_carta(0).get_center(), v.rett_sagoma(1).get_center())
				check(B.document_placed().is_empty() and n.msg != "", "Una sagoma diversa non accetta il documento")
				await sistema()
				check(B.document_ready() and B.document_placed().size() == 2, "Ricevuta e conferma entrano nel fascicolo")
				await timbra(3)
				check(B.document_stamp() == 3 and int(n.p.document) == 0, "Il timbro lascia la pratica ancora modificabile")
				await drag(v.rett_carta(0).get_center(), Vector2(60, 120))
				check(0 not in B.document_placed() and B.document_stamp() == -1, "Togliere una prova invalida l'impronta precedente")
				await drag(v.rett_carta(0).get_center(), v.rett_sagoma(0).get_center())
				await timbra(0)
				await consegna()
				check(int(n.p.document) == 0 and GameState.money == 0 and n.msg != "", "Destinazione sbagliata non archivia e permette di riprovare")
				await timbra(3)
				await consegna()
				check(int(n.p.document) == 1 and n.p.decisions.size() == 1, "Il rimborso già pagato si chiude una volta sola")
				check(not v.campi[1].available and B.place_document_piece(1, 1) != "", "Il registro di Ercole non viene inventato")
				await sistema()
				await timbra(3)
				var bozza: Dictionary = n.p.duplicate(true)
				B.checkpoint("-4")
				GameState.load_game()
				n.queue_free(); await frames(); await crea(); v = n.visuale
				check(n.p == JSON.parse_string(JSON.stringify(bozza)) and B.document_placed() == [0] and B.document_stamp() == 3, "Ripresa conserva fogli e timbro del fascicolo corrente")
				check(not v.campi[1].available and GameState.money == 0, "Ricarica non produce registro né premio")
				await consegna()
				check(v.conferma_aperta and int(n.p.document) == 1, "Chiudere Ercole senza registro richiede conferma distinta")
				await clic(v.rett("Consegna").get_center())
				check(v.conferma_aperta and int(n.p.document) == 1, "Ripetere il gesto precedente non conferma la chiusura")
				await clic(v.rett("Conferma/Indietro").get_center())
				check(not v.conferma_aperta and int(n.p.document) == 1, "Si può tornare al tavolo senza chiudere Ercole")
				if chiude:
					await consegna()
					await clic(v.rett("Conferma/Chiudi").get_center())
					await get_tree().create_timer(0.42).timeout
				else:
					await timbra(2)
					await consegna()
				check(int(n.p.document) == 2 and int(n.p.decisions[1].action) == (3 if chiude else 2), "E-27 mantiene distinti chiusura e richiesta del registro")
				await sistema(); await timbra(1); await consegna()
				check(int(n.p.document) == 3, "Cambio turno con firme va al Personale")
				await sistema(); await timbra(2); await consegna()
				check(n.completato and GameState.money == (900 if chiude else 0), "Quattro fascicoli applicano il premio canonico")
				check(bool(GameState.flags.boss_ercole_archived) == chiude and not GameState.is_robot("ercole") and not GameState.is_robot("tilde"), "Conseguenza di Ercole preservata senza nuovi robot")
				var saldo := GameState.money
				B.submit_prepared_document()
				check(GameState.money == saldo and n.p.decisions.size() == 4, "Doppia consegna non ripete premio o fascicoli")
				n.queue_free(); await frames()
	touch = false; TouchControls.enabled = false
	await fresh()
	var v: Node = n.visuale
	n.selected = 0
	await action("confirm")
	await action("move_right")
	check(n.buttons[n.selected].action == "fasc_sagoma_0", "La freccia destra raggiunge la sagoma sulla scrivania")
	await action("confirm")
	check(B.document_placed() == [0], "Tastiera inserisce un foglio senza trascinare")
	await scegli("fasc_carta_1"); await scegli("fasc_sagoma_1")
	await scegli("fasc_timbro_3"); await scegli("fasc_fascicolo")
	check(B.document_ready() and B.document_stamp() == 3, "Tastiera prepara e timbra la pratica")
	await scegli("fasc_dettagli")
	check(v.dettagli_aperti, "Il testo completo è disponibile nei dettagli facoltativi")
	await action("ui_cancel")
	check(not v.dettagli_aperti and int(n.p.document) == 0, "Chiudere i dettagli non consegna nulla")
	await scegli("fasc_timbro_0"); await action("ui_cancel")
	check(v.in_mano == "" and B.document_stamp() == 3, "Annulla restituisce l'utensile senza cambiare l'impronta")
	await scegli("fasc_consegna")
	await get_tree().create_timer(0.42).timeout
	check(int(n.p.document) == 1, "La consegna completa funziona anche da tastiera")
	n.queue_free(); await frames()
	print("BOSS FASCICOLI: %d controlli, errori %s" % [controlli, errori])
	get_tree().quit(errori.size())
