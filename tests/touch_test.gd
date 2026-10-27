extends Node
## Test dei comandi col dito: simula tocchi, scorrimenti e dita tenute giù sui minigiochi,
## poi prova lo straordinario in cyclette e lo sguardo indietro di fine capitolo 1.
## Esegui:  Godot --headless --path . res://tests/touch_test.tscn
## Alla fine stampa "TOUCH TEST OK" oppure gli errori trovati.

var _failures: Array[String] = []
var _frame := 0
var choose_index := 0
## true: i turni finiscono da soli appena iniziano (per i pezzi di storia)
var auto_work := false


func _ready() -> void:
	GameState.save_path = "user://test_save.json"
	TouchControls.enabled = true
	var placeholder := Node.new()
	get_tree().root.add_child.call_deferred(placeholder)
	await get_tree().process_frame
	get_tree().current_scene = placeholder
	await _run()


func _process(_delta: float) -> void:
	_frame += 1
	var scene := get_tree().current_scene
	if auto_work and scene and scene.scene_file_path == Router.WORK and not Ui.transitioning and scene.get("phase") == "play":
		scene.set("score", scene.get("target"))
		scene.set("time_left", 0.0)
	elif Ui.busy and _frame % 3 == 0:
		if Ui.get("_mode") == "choose":
			Ui.set("_sel", choose_index)
		var down := InputEventAction.new()
		down.action = "confirm"
		down.pressed = true
		Input.parse_input_event(down)
		var up := InputEventAction.new()
		up.action = "confirm"
		Input.parse_input_event(up)


func _touch(pos: Vector2, pressed: bool, index := 0) -> void:
	var t := InputEventScreenTouch.new()
	t.position = pos
	t.pressed = pressed
	t.index = index
	Input.parse_input_event(t)


func _drag(pos: Vector2, index := 0) -> void:
	var d := InputEventScreenDrag.new()
	d.position = pos
	d.index = index
	Input.parse_input_event(d)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _tap_at(pos: Vector2) -> void:
	_touch(pos, true)
	await _frames(2)
	_touch(pos, false)
	await _frames(2)


func _swipe(from: Vector2, to: Vector2) -> void:
	_touch(from, true)
	await _frames(1)
	_drag(from.lerp(to, 0.5))
	await _frames(1)
	_drag(to)
	await _frames(1)
	_touch(to, false)
	await _frames(2)


func _scene_path() -> String:
	var s := get_tree().current_scene
	return s.scene_file_path if s else ""


func _wait_scene(path: String, max_frames := 20000) -> void:
	var n := 0
	while (_scene_path() != path or Ui.transitioning) and n < max_frames:
		await get_tree().process_frame
		n += 1
	if n >= max_frames:
		_fail("timeout aspettando %s (scena attuale %s)" % [path, _scene_path()])
	await get_tree().process_frame


## Aspetta che il minigioco sia partito (dopo i dialoghi d'inizio).
func _wait_play(max_frames := 6000) -> Node:
	var n := 0
	while (get_tree().current_scene.get("phase") != "play" or Ui.busy) and n < max_frames:
		await get_tree().process_frame
		n += 1
	await _frames(3)
	return get_tree().current_scene


func _idle(max_frames := 20000) -> void:
	var n := 0
	await get_tree().process_frame
	while (Ui.busy or Ui.transitioning or Ui.cutscene) and n < max_frames:
		await get_tree().process_frame
		n += 1
	await get_tree().process_frame


func _check(cond: bool, what: String) -> void:
	if not cond:
		_fail(what)


func _fail(what: String) -> void:
	_failures.append(what)
	push_error("TEST: " + what)


func _work(game: String, extra := {}) -> Node:
	GameState.minigame = {"kind": "work", "game": game, "name": "Prova", "pay": 100,
		"intro": ["* Prova."], "return": Router.FONDO}
	GameState.minigame.merge(extra, true)
	Router.goto(Router.WORK)
	await _wait_scene(Router.WORK)
	return await _wait_play()


func _help(type: String) -> Node:
	GameState.minigame = {"kind": "help", "type": type, "title": "Prova", "count": 10, "time": 60,
		"intro": ["* Prova."], "return": Router.FONDO}
	Router.goto(Router.MINIGAME)
	await _wait_scene(Router.MINIGAME)
	return await _wait_play()


func _run() -> void:
	GameState.new_game()

	# --- pedalare: tocchi alternati a sinistra e a destra
	var w := await _work("pedal")
	_check(TouchControls.scheme == "halves", "la cyclette dovrebbe usare le due metà dello schermo (è %s)" % TouchControls.scheme)
	_check(not TouchControls.show_stick and not TouchControls.show_buttons, "nei minigiochi non dovrebbero esserci joystick e pulsanti")
	_check("Tocca" in w.call("_rules"), "le regole della cyclette dovrebbero dire 'tocca'")
	for i in 6:
		await _tap_at(Vector2(100, 200))
		await _tap_at(Vector2(540, 200))
	_check(float(w.get("speed")) > 0.3, "pedalare col dito non fa salire la lancetta (%.2f)" % float(w.get("speed")))
	var sp := float(w.get("speed"))
	await _tap_at(Vector2(540, 200))
	_check(float(w.get("speed")) < sp, "toccare due volte lo stesso lato dovrebbe far inciampare")

	# --- il magazzino: tocca la metà giusta
	w = await _work("sort")
	(w.get("boxes") as Array).append({"y": 200.0, "red": true})
	await _tap_at(Vector2(80, 150))
	_check(float(w.get("score")) >= 1.0, "toccare a sinistra dovrebbe smistare la scatola rossa")

	# --- i bagni: la spugna segue il dito
	w = await _work("clean")
	var s0: Vector2 = w.get("sponge")
	_touch(Vector2(200, 130), true)
	await _frames(30)
	_check((w.get("sponge") as Vector2).distance_to(Vector2(200, 130)) < s0.distance_to(Vector2(200, 130)) - 20, "la spugna dovrebbe andare verso il dito")
	_touch(Vector2(200, 130), false)
	await _frames(2)

	# --- le consegne: tocca la corsia
	w = await _work("deliver")
	await _tap_at(Vector2(320, 110))
	_check(int(w.get("lane")) == 0, "toccare la corsia in alto dovrebbe portarci la bici")

	# --- il call center del -4: tocca il telefono che squilla, poi la risposta
	w = await _work("helpdesk")
	w.set("hd_phase", "ring")
	w.set("hd_phone", 2)
	w.set("hd_t", 5.0)
	await _tap_at(w.call("_hd_phone_pos", 0))
	_check(int(w.get("mistakes")) == 1, "toccare il telefono sbagliato dovrebbe essere un errore")
	await _tap_at(w.call("_hd_phone_pos", 2))
	_check(str(w.get("hd_phase")) == "talk", "toccare il telefono che squilla dovrebbe rispondere")
	var kinds: Array = w.get("hd_order")
	await _tap_at((w.call("_hd_button", kinds.find(0)) as Rect2).get_center())
	_check(float(w.get("score")) >= 1.0 and str(w.get("hd_phase")) == "wait", "la risposta del copione dovrebbe contare")
	w.set("hd_phase", "ring")
	w.set("hd_phone", 1)
	w.set("hd_t", 5.0)
	await _tap_at(w.call("_hd_phone_pos", 1))
	kinds = w.get("hd_order")
	await _tap_at((w.call("_hd_button", kinds.find(1)) as Rect2).get_center())
	_check(int(w.get("hd_honest")) == 1, "la risposta sincera dovrebbe essere contata")

	# --- il call center: tocca il telefono che squilla
	w = await _work("calls")
	(w.get("ringing") as Dictionary).clear()
	(w.get("ringing") as Dictionary)["left"] = 5.0
	await _tap_at(Vector2(200, 191))
	_check(float(w.get("score")) >= 1.0, "toccare il telefono a sinistra dovrebbe rispondere")

	# --- un, due, tre, stella: il dito giù fa avvicinare
	w = await _work("steal", {"victim_name": "Fermo", "victim_sheet": "char_14", "item": "il quaderno", "seated": true})
	var arc: Object = w.get("arcade")
	_check(TouchControls.scheme == "hold", "il furto dovrebbe usare il dito tenuto giù")
	arc.set("st_state", "work")
	arc.set("st_t", 99.0)
	var x0 := float(arc.get("st_x"))
	_touch(Vector2(320, 200), true)
	await _frames(40)
	_check(float(arc.get("st_x")) > x0 + 10, "tenendo il dito si dovrebbe avanzare (%.1f -> %.1f)" % [x0, float(arc.get("st_x"))])
	_touch(Vector2(320, 200), false)
	await _frames(3)
	var x1 := float(arc.get("st_x"))
	await _frames(20)
	_check(is_equal_approx(float(arc.get("st_x")), x1), "staccando il dito ci si dovrebbe fermare")

	# --- breakout: la barra segue il dito
	w = await _work("breakout")
	arc = w.get("arcade")
	_touch(Vector2(160, 250), true)
	await _frames(40)
	_check(float(arc.get("br_paddle")) < 300.0, "la barra dovrebbe seguire il dito (%.0f)" % float(arc.get("br_paddle")))
	_touch(Vector2(160, 250), false)
	await _frames(3)
	_check(not bool(arc.get("br_stuck")), "staccare il dito dovrebbe lanciare la pallina")

	# --- snake: scorrere gira il mocio
	w = await _work("snake")
	arc = w.get("arcade")
	await _swipe(Vector2(320, 200), Vector2(320, 120))
	_check(arc.get("sn_next") == Vector2i.UP, "scorrere in su dovrebbe girare il mocio in su")

	# --- lampadine: scorri a destra = buona
	var m := await _help("bulbs")
	_check(TouchControls.scheme == "swipe", "le lampadine dovrebbero usare lo scorrimento")
	m.set("bulb", "buona")
	await _swipe(Vector2(300, 200), Vector2(400, 200))
	_check(int(m.get("bulb_done")) == 1, "scorrere a destra una lampadina buona dovrebbe contarla")
	m.set("bulb", "fioca")
	m.set("bulb_fix", 0)
	await _swipe(Vector2(300, 200), Vector2(300, 140))
	await _swipe(Vector2(300, 200), Vector2(300, 260))
	_check(str(m.get("bulb")) == "buona", "scorrere su e giù dovrebbe avvitare la lampadina che sfarfalla")

	# --- fili: tocca un filo, poi il suo posto
	m = await _help("wires")
	var right: Array = m.get("wire_right")
	var box: Rect2 = m.BOX
	var y0 := box.position.y + 26
	var gap := (box.size.y - 52) / 3.0
	await _tap_at(Vector2(box.position.x + 25, y0))
	_check(int(m.get("wire_pick")) == 0, "toccare il primo filo dovrebbe sceglierlo")
	await _tap_at(Vector2(box.end.x - 25, y0 + right.find(0) * gap))
	_check(0 in (m.get("wire_done") as Array), "toccare il posto giusto dovrebbe collegare il filo")

	# --- Leda, SCATOLE E SCAFFALI: tocca lo scaffale giusto
	m = await _help("inventory")
	var good: Array = (m.get("inv_queue") as Array)[0]
	var wrong := (int(good[1]) + 1) % 4
	await _tap_at((m.call("_inv_shelf", wrong) as Rect2).get_center())
	_check(int(m.get("misses")) == 1, "lo scaffale sbagliato dovrebbe essere un errore")
	await _tap_at((m.call("_inv_shelf", int(good[1])) as Rect2).get_center())
	_check(int(m.get("inv_done")) == 1, "lo scaffale giusto dovrebbe sistemare il prodotto")

	# --- Amir, L'ULTIMA CONSEGNA: tocca gli incroci (la strada sicura arriva in tempo)
	m = await _help("route")
	await _tap_at(m.RT_NODES[4])
	_check((m.get("rt_done") as Array).is_empty(), "un incrocio lontano non si raggiunge")
	for n in [2, 5]:
		await _tap_at(m.RT_NODES[n])
		# il cuore cammina fino all'incrocio, poi si può toccare il prossimo
		for i in 600:
			if float(m.get("rt_k")) >= 1.0:
				break
			await _frames(1)
	_check((m.get("rt_done") as Array).size() == 2 and int(m.get("rt_left")) == 40, "la strada sicura: Scala B e Piazza in 80 minuti (ne restano 40 per Via dei Fiori)")

	# --- la cassa del Mercato: tocca l'articolo, poi CORREGGI il prezzo sbagliato
	w = await _work("cassa", {"job": {"pay_max": 160, "duration": 40}})
	w.set("cs_item", {"name": "Pane", "tag": 12, "screen": 20})
	w.set("cs_phase", "scan")
	w.set("cs_t", 5.0)
	await _tap_at(Vector2(320, 190))
	_check(str(w.get("cs_phase")) == "check", "toccare l'articolo dovrebbe passarlo allo scanner")
	await _tap_at((w.call("_cs_button", 1) as Rect2).get_center())
	for i in 600:
		if str(w.get("cs_phase")) != "verify":
			break
		await _frames(1)
	_check(int(w.get("cs_fixed")) == 1 and float(w.get("score")) >= 1.0, "CORREGGI dovrebbe correggere il sovrapprezzo")
	w.set("cs_item", {"name": "Latte", "tag": 24, "screen": 32})
	w.set("cs_phase", "check")
	await _tap_at((w.call("_cs_button", 0) as Rect2).get_center())
	_check(int(w.get("cs_accepted")) == 1, "CONFERMA dovrebbe confermare il sovrapprezzo")
	_check(float(w.get("err_t")) > 0.0, "un sovrapprezzo passato si deve vedere")
	var errs := int(w.get("mistakes"))
	w.set("cs_item", {"name": "Pane", "tag": 12, "screen": 12})
	w.set("cs_phase", "check")
	await _tap_at((w.call("_cs_button", 1) as Rect2).get_center())
	for i in 600:
		if str(w.get("cs_phase")) != "verify":
			break
		await _frames(1)
	_check(int(w.get("mistakes")) == errs + 1, "correggere un prezzo giusto è un errore (e conta)")

	# --- Olga, LE RATE MANCANTI: tocca i documenti in ordine, poi la voce doppia
	m = await _help("rate")
	var cards: Array = m.get("rate_cards")
	_check(cards != [0, 1, 2, 3, 4, 5], "i documenti dovrebbero partire in disordine")
	await _tap_at((m.call("_rate_card", cards.find(1)) as Rect2).get_center())
	_check(int(m.get("misses")) == 1 and (m.get("rate_placed") as Array).is_empty(), "un documento fuori ordine dovrebbe essere un errore")
	for doc in 6:
		await _tap_at((m.call("_rate_card", cards.find(doc)) as Rect2).get_center())
	_check(str(m.get("rate_phase")) == "find", "sei documenti in ordine: poi l'estratto conto")
	await _tap_at((m.call("_rate_row", 0) as Rect2).get_center())
	_check(int(m.get("misses")) == 2 and str(m.get("phase")) == "play", "la rata non è la voce doppia")
	await _tap_at((m.call("_rate_row", 3) as Rect2).get_center())
	_check(str(m.get("phase")) != "play", "la seconda commissione è la voce doppia: il minigioco finisce")

	# --- Teo, LA PRATICA IMPOSSIBILE: tocca il tipo di problema giusto
	m = await _help("pratiche")
	var list: Array = GameState.bank["teo"]["pratiche"]
	var wrong_type := (int(list[0]["tipo"]) + 1) % 5
	await _tap_at((m.call("_pr_button", wrong_type) as Rect2).get_center())
	_check(int(m.get("misses")) == 1 and int(m.get("pr_i")) == 0, "il tipo sbagliato dovrebbe essere un errore")
	await _tap_at((m.call("_pr_button", int(list[0]["tipo"])) as Rect2).get_center())
	_check(int(m.get("pr_i")) == 1, "il tipo giusto dovrebbe chiudere la pratica")

	# --- lo sportello della Banca: APPROVA subito, RICHIEDI VERIFICA ci mette di più
	w = await _work("sportello", {"job": {"pay_max": 1000, "duration": 45}})
	w.set("sp_cur", {"id": "027", "righe": ["Busta paga: 1.300 €"], "verifica": true})
	await _tap_at((w.call("_sp_button", 0) as Rect2).get_center())
	_check(int(w.get("sp_rushed")) == 1 and str(w.get("sp_phase")) == "stamp", "APPROVA una pratica col problema: frettolosa")
	for i in 600:
		if str(w.get("sp_phase")) == "read":
			break
		await _frames(1)
	w.set("sp_cur", {"id": "041", "righe": ["Busta paga: 1.300 €"], "verifica": true})
	await _tap_at((w.call("_sp_button", 1) as Rect2).get_center())
	_check(int(w.get("sp_correct")) == 1 and str(w.get("sp_phase")) == "verify", "RICHIEDI VERIFICA sulla pratica col problema: giusta")
	for i in 600:
		if str(w.get("sp_phase")) == "read":
			break
		await _frames(1)
	_check(float(w.get("score")) >= 2.0, "le pratiche chiuse contano tutte, giuste o no")

	# --- Ada, UNA STANZA PER TUTTI: tocca un mobile, poi la stanza (in alto: più in basso ci sono i mobili già messi)
	m = await _help("stanze")
	await _tap_at((m.call("_st_done_button") as Rect2).get_center())
	_check(int(m.get("misses")) == 0 and str(m.get("phase")) == "play", "con dei mobili ancora nel vassoio non si chiude (e non è un errore)")
	for i in 3:
		await _tap_at((m.call("_st_piece", i) as Rect2).get_center())
		await _tap_at((m.call("_st_room", 0) as Rect2).position + Vector2(86, 20))
	await _tap_at((m.call("_st_piece", 3) as Rect2).get_center())
	await _tap_at((m.call("_st_room", 0) as Rect2).position + Vector2(86, 20))
	_check(int((m.get("st_where") as Array)[3]) == -1, "una stanza piena non prende un quarto mobile")
	# lo scaffale torna nel vassoio e va nel laboratorio; le sedie restano senza stanza giusta
	await _tap_at((m.call("_st_piece", 2) as Rect2).get_center())
	await _tap_at((m.call("_st_room", 1) as Rect2).position + Vector2(86, 20))
	await _tap_at((m.call("_st_piece", 3) as Rect2).get_center())
	await _tap_at((m.call("_st_room", 1) as Rect2).position + Vector2(86, 20))
	for p: Array in [[4, 1], [5, 0]]:
		await _tap_at((m.call("_st_piece", p[0]) as Rect2).get_center())
		await _tap_at((m.call("_st_room", p[1]) as Rect2).position + Vector2(86, 20))
	_check((m.get("st_where") as Array) == [0, 0, 1, 1, 1, 0], "i mobili dovrebbero stare dove li hai messi (%s)" % str(m.get("st_where")))
	await _tap_at((m.call("_st_done_button") as Rect2).get_center())
	_check(int(m.get("misses")) == 1 and str(m.get("phase")) == "play", "senza sedie la stanza degli incontri non funziona: un errore")
	for p: Array in [[4, 2], [5, 2]]:
		await _tap_at((m.call("_st_piece", p[0]) as Rect2).get_center())
		await _tap_at((m.call("_st_room", p[1]) as Rect2).position + Vector2(86, 20))
	await _tap_at((m.call("_st_done_button") as Rect2).get_center())
	_check(str(m.get("phase")) != "play" and GameState.flags.has("c5_stanze"), "tre stanze che funzionano: il minigioco finisce")

	# --- Nadir, IL PERCORSO POSSIBILE: tratta dopo tratta; lento, caro, poi il compromesso
	m = await _help("percorso")
	await _tap_at((m.call("_pc_label", 4) as Rect2).get_center())
	_check((m.get("pc_path") as Array).is_empty(), "da casa la navetta non parte")
	for e in [0, 1]:
		await _tap_at((m.call("_pc_label", e) as Rect2).get_center())
	_check(int(m.get("misses")) == 1 and (m.get("pc_path") as Array).is_empty(), "il percorso economico arriva tardi: si riparte")
	for e in [2, 4]:
		await _tap_at((m.call("_pc_label", e) as Rect2).get_center())
	_check(int(m.get("misses")) == 2 and str(m.get("phase")) == "play", "il percorso veloce costa troppo")
	for e in [2, 3]:
		await _tap_at((m.call("_pc_label", e) as Rect2).get_center())
	_check(str(m.get("phase")) != "play" and GameState.flags.get("c5_nadir_tratta", []) == [2, 3], "il compromesso (bus 4 + treno): Nadir arriva")

	# --- il centralino della Città: destinazioni; poi le discrepanze (VERIFICA, CONFERMA)
	w = await _work("smistamento", {"job": {"pay": 1600, "pay_max": 2000, "duration": 45}})
	w.set("sm_cur", {"testo": "Libri", "cat": "Consegne", "dest": 0})
	await _tap_at((w.call("_sm_button", 1) as Rect2).get_center())
	_check(int(w.get("sm_wrong")) == 1 and int(w.get("mistakes")) == 1, "i libri alla fermata: destinazione sbagliata")
	for i in 600:
		if str(w.get("sm_phase")) == "read":
			break
		await _frames(1)
	w.set("sm_cur", {"id": "082", "testo": "Richiesta n. 082", "cat": "Consegne", "proposta": "ARCHIVIO CENTRALE", "dest": 0})
	await _tap_at((w.call("_sm_button", 1) as Rect2).get_center())
	_check(int(w.get("sm_found")) == 1 and str(w.get("sm_phase")) == "verify", "VERIFICA una discrepanza: trovata (e ci vuole più tempo)")
	for i in 600:
		if str(w.get("sm_phase")) == "read":
			break
		await _frames(1)
	w.set("sm_cur", {"id": "091", "testo": "Richiesta n. 091", "cat": "Servizi", "proposta": "ARCHIVIO CENTRALE", "dest": 0})
	await _tap_at((w.call("_sm_button", 0) as Rect2).get_center())
	_check(int(w.get("sm_confirmed")) == 1 and int(w.get("mistakes")) == 1, "CONFERMA non è un errore tuo: il sistema ha proposto")
	for i in 600:
		if str(w.get("sm_phase")) == "read":
			break
		await _frames(1)
	_check(float(w.get("score")) >= 3.0, "le richieste chiuse contano tutte")

	# --- la Cima, il TURNO di Direzione: più e meno sulle voci, CONFERMA solo a 100
	GameState.flags["chapter_6"] = {"elevator": {"intro_seen": true}, "director_turn": {"rules_seen": true}}
	GameState.minigame = {"cycle": 1}
	Router.goto(Router.DIREZIONE)
	await _wait_scene(Router.DIREZIONE)
	var dz := get_tree().current_scene
	for i in 6000:
		if str(dz.get("phase")) == "alloc" and not Ui.busy:
			break
		await _frames(1)
	await _tap_at((dz.call("plus_button", 1) as Rect2).get_center())
	_check(int(dz.get("alloc")["servizi"]) == 20, "a 100 unità il più non aggiunge")
	await _tap_at((dz.call("minus_button", 3) as Rect2).get_center())
	await _tap_at((dz.call("plus_button", 1) as Rect2).get_center())
	_check(int(dz.get("alloc")["servizi"]) == 25 and int(dz.get("alloc")["riserve"]) == 10, "togliere dalle riserve, dare ai servizi")
	for i in 3:
		await _tap_at((dz.call("minus_button", 0) as Rect2).get_center())
	_check(int(dz.get("alloc")["stipendi"]) == 30, "gli stipendi non scendono sotto 30")
	await _tap_at((dz.call("confirm_button") as Rect2).get_center())
	_check(str(dz.get("phase")) == "alloc" and "90" in str(dz.get("msg")), "con 90 unità CONFERMA dice perché non si può")
	for i in 2:
		await _tap_at((dz.call("plus_button", 2) as Rect2).get_center())
	await _tap_at((dz.call("confirm_button") as Rect2).get_center())
	var c6: Dictionary = GameState.flags["chapter_6"]
	_check(c6["director_turn"].get("cycle_1_completed", false) and int(c6["director_turn"]["state"]["log"][0]["alloc"]["stipendi"]) == 30, "CONFERMA a 100: il ciclo 1 è deciso")
	c6["director_turn"]["pending"] = null
	await _wait_scene(Router.CIMA, 60000)
	await _idle()

	# --- lo straordinario dopo la rivelazione: paga meno, e la festa si riaccende
	GameState.new_game()
	for f in ["c1_arrivo", "fermo_talked", "fermo_called", "c1_rivelazione", "c1_restato", "c1_lift_broken", "boss_call_floor_-5"]:
		GameState.flags[f] = true
	GameState.worked_today = true
	Router.goto(Router.FONDO)
	await _wait_scene(Router.FONDO)
	await _idle()
	var money0 := GameState.money
	auto_work = true
	choose_index = 0
	get_tree().current_scene.call("_station", GameState.job("dinamo"))
	await _wait_scene(Router.WORK)
	_check(float(get_tree().current_scene.get("d")) >= 0.25, "lo straordinario dovrebbe essere più difficile")
	await _wait_scene(Router.FONDO)
	await _frames(30)
	_check(Ui.cutscene, "tornati dallo straordinario la festa dovrebbe riaccendersi")
	await _idle()
	auto_work = false
	_check(int(GameState.flags.get("c1_extra", 0)) == 1, "lo straordinario non è stato contato")
	_check(GameState.money - money0 > 0 and GameState.money - money0 <= 150, "lo straordinario dovrebbe pagare meno di un turno (%d)" % (GameState.money - money0))

	# --- lo sguardo indietro, in cima alle scale
	var fondo := get_tree().current_scene
	_check(fondo.call("on_stairs_top", fondo.get("player")), "in cima alle scale dovrebbe partire lo sguardo indietro")
	await _wait_scene(Router.SOTTOUFFICIO, 60000)
	_check(GameState.flags.get("c1_fine", false), "lo sguardo indietro non è stato segnato")

	if _failures.is_empty():
		print("TOUCH TEST OK")
	else:
		for f in _failures:
			print("FALLITO: " + f)
	get_tree().quit(0 if _failures.is_empty() else 1)
