extends Node
const B := preload("res://scripts/boss_missions.gd")
var n: Node
var controlli := 0
var errori: Array[String] = []
var touch := false
var scadenza := 0.0

func check(ok: bool, nota: String) -> void:
	controlli += 1
	if not ok:
		errori.append(nota)
		push_error(nota)

func _process(dt: float) -> void:
	scadenza += dt
	if scadenza > 90:
		push_error("Timeout montaggio")
		get_tree().quit(1)

func frames() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

func evento(pos: Vector2, fase: int) -> void:
	pos = get_viewport().get_screen_transform() * n.get_global_transform_with_canvas() * pos
	if touch:
		if fase == 1:
			var e := InputEventScreenDrag.new()
			e.index = 0; e.position = pos; Input.parse_input_event(e)
		else:
			var e := InputEventScreenTouch.new()
			e.index = 0; e.position = pos; e.pressed = fase == 0; Input.parse_input_event(e)
	else:
		if fase == 1:
			var e := InputEventMouseMotion.new()
			e.position = pos; e.button_mask = MOUSE_BUTTON_MASK_LEFT; Input.parse_input_event(e)
		else:
			var e := InputEventMouseButton.new()
			e.button_index = MOUSE_BUTTON_LEFT; e.position = pos; e.global_position = pos; e.pressed = fase == 0; Input.parse_input_event(e)
	await frames()

func clic(pos: Vector2) -> void:
	await evento(pos, 0)
	await evento(pos, 2)

func drag(da: Vector2, a: Vector2) -> void:
	await evento(da, 0)
	await evento(a, 1)
	await evento(a, 2)

func tasto(codice: Key, shift := false) -> void:
	var e := InputEventKey.new(); e.keycode = codice; e.pressed = true; e.shift_pressed = shift; Input.parse_input_event(e)
	await frames()
	e = InputEventKey.new(); e.keycode = codice; e.shift_pressed = shift; Input.parse_input_event(e)
	await frames()

func fresh() -> void:
	GameState.new_game()
	GameState.floor_id = "0"
	B.state("0").merge({"status": "active", "instructions_seen": true, "return": Router.CITY}, true)
	B.record_quote("student", "Studente", "Sono qui perché chiudono il posto dove studio.", "La protesta riguarda la chiusura della Casa Comune.", 20)
	B.record_quote("casa", "Ada", "Vogliamo capire perché l'unica soluzione proposta è far pagare chi lo usa.", "Ada ha detto che tetto e manutenzione richiedono soldi.", 22)
	B.record_quote("rina", "Rina", "L'avevo appena riparata.", "La vetrina è rotta. Non si è visto chi è stato; Rina non ha chiesto di chiudere la Casa.", 18)
	GameState.minigame = {"boss_floor": "0"}
	n = Control.new()
	n.set_script(load("res://tests/spia_montaggio.gd"))
	get_tree().root.add_child(n)
	get_tree().current_scene = n
	await frames()

func _ready() -> void:
	GameState.save_path = "user://test_montaggio_isolato.json"
	await frames()
	for size in [Vector2i(640, 360), Vector2i(1280, 720), Vector2i(1000, 600)]:
		get_window().size = size
		for tel in [false, true]:
			touch = tel
			TouchControls.enabled = tel
			await fresh()
			var v: Node = n.visuale
			# Fuori dalla pista: nessuna consegna, nessun taglio, nessun premio.
			await drag(v.rett_fonte(0).get_center(), Vector2(345, 200))
			check(n.p.clips.is_empty() and GameState.money == 0, "Rilascio fuori annulla")
			for i in 3:
				await drag(v.rett_fonte(i).get_center(), Vector2(615, 310))
			check(n.p.clips.size() == 3 and B.news_time(n.p) == 60, "Tre rulli reali occupano sessanta secondi")
			await drag(v.rett_fonte(0).get_center(), Vector2(615, 310))
			check(n.p.clips.size() == 3 and GameState.money == 0, "Rullo duplicato non aggiunto e montaggio non pagato in anticipo")
			await drag(v.rett_clip(0).get_center(), Vector2(618, 310))
			check(n.p.clips[2].id == "student", "Riordino tramite trascinamento")
			await clic(v.rett("Taglia").get_center())
			await clic(v.rett_clip(2).get_center())
			check(n.p.clips[2].cut and B.news_time(n.p) == 48, "Forbici applicate allo spezzone scelto")
			check(v.didascalia == B.news_sources()[0].quote and v.contesto_originale == B.news_sources()[0].context, "Originale e montaggio mostrano la stessa persona dopo il riordino")
			check(B.news_sources()[0].quote == "Sono qui perché chiudono il posto dove studio.", "Tagliare non cancella la testimonianza originale")
			await clic(v.rett("Fatti").get_center())
			check(n.p.facts and B.news_time(n.p) == 58 and v.inquadratura().id == "facts", "Fatti occupano spazio e si possono leggere nell'anteprima")
			await clic(v.rett("Ripristina").get_center())
			await clic(v.rett_clip(2).get_center())
			check(n.p.clips[2].cut and B.news_time(n.p) == 58, "Ripristino senza spazio non cambia o taglia altre registrazioni")
			await clic(v.rett("Fatti").get_center())
			await clic(v.rett("Ripristina").get_center())
			await clic(v.rett_clip(2).get_center())
			check(not n.p.clips[2].cut and B.news_time(n.p) == 60, "Ripristino ricompone parole e durata originali")
			await drag(v.rett_clip(1).get_center(), v.rett_fonte(1).get_center())
			check(n.p.clips.size() == 2 and n.p.clips[1].id == "student", "Riportare un rullo alle fonti lo toglie dalla pista")
			await clic(v.rett("Trasmetti").get_center())
			check(not v.conferma_aperta and B.state("0").status == "active", "Trasmissione incompleta non consegnata")
			await drag(v.rett_fonte(2).get_center(), Vector2(618, 310))
			await clic(v.rett("Taglia").get_center())
			await clic(v.rett_clip(2).get_center())
			await clic(v.rett("Anteprima").get_center())
			v.riproduzione_indice = 1
			await clic(v.rett("Anteprima").get_center())
			check(not v.riproduzione and v.clip_fuoco == 1, "Pausa ferma la registrazione corrente")
			var draft: Dictionary = n.p.duplicate(true)
			B.checkpoint("0")
			GameState.load_game()
			check(B.progress("0") == JSON.parse_string(JSON.stringify(draft)) and B.state("0").status == "active", "Ricarica conserva ordine, tagli e fonti senza premio")
			# Il controller conserva i riferimenti alla bozza corrente dopo la ricarica.
			n.p = B.progress("0"); n._sync_visuale()
			await clic(v.rett("Trasmetti").get_center())
			check(v.conferma_aperta and not n.completato and GameState.money == 0, "Trasmissione richiede conferma separata")
			await clic(v.rett("Conferma/Indietro").get_center())
			check(not v.conferma_aperta and B.state("0").status == "active", "Si può tornare a modificare prima di trasmettere")
			await clic(v.rett("Trasmetti").get_center())
			await clic(v.rett("Conferma/Invia").get_center())
			check(n.completato and GameState.money == 2000 and B.state("0").result.cuts == 1, "Consegna applica il premio e la conseguenza di un solo taglio")
			var premio := GameState.money
			B.finish_news()
			check(GameState.money == premio, "Premio accreditato una sola volta")
			n.queue_free(); await frames()
	# Tastiera: fonte + pista, poi editing e riordino senza trascinamento.
	touch = false; TouchControls.enabled = false
	await fresh()
	var v: Node = n.visuale
	for i in 3:
		n._act("mont_fonte_%d" % i)
		n._act("mont_aggiungi")
	check(n.p.clips.size() == 3, "Inserimento a due passi disponibile con tastiera")
	n._act("mont_clip_1")
	await tasto(KEY_LEFT, true)
	check(n.p.clips[0].id == "casa", "Tastiera riordina lo spezzone")
	await tasto(KEY_DELETE)
	check(n.p.clips.size() == 2 and n.p.clips[0].id == "student", "Tastiera toglie lo spezzone selezionato")
	n.queue_free(); await frames()
	print("BOSS MONTAGGIO: %d controlli, errori %s" % [controlli, errori])
	get_tree().quit(errori.size())
