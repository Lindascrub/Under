extends Node
## Test automatico: gioca da solo scene, battaglie e i tre finali.
## Esegui:  Godot --headless --path . res://tests/smoke_test.tscn
## Alla fine stampa "SMOKE TEST OK" oppure gli errori trovati.

var _frame := 0
var _failures: Array[String] = []
## Quale opzione scegliere quando si apre una scelta (Ui.choose).
var choose_index := 0
## Scelte specifiche da fare in ordine (poi si torna a choose_index).
var choose_queue: Array = []
## Piano per la battaglia: lista di [pulsante, voce del sottomenu].
var plan: Array = []
var fallback := [3, 1]
var fast_dodge := true
var immortal := false
## Come finiscono da soli i minigiochi di aiuto: "win", "fail" o "partial".
var minigame_result := "win"


func _ready() -> void:
	# i test non toccano il salvataggio della partita vera
	GameState.save_path = "user://test_save.json"
	var placeholder := Node.new()
	get_tree().root.add_child.call_deferred(placeholder)
	await get_tree().process_frame
	get_tree().current_scene = placeholder
	await _run()


func _process(_delta: float) -> void:
	_frame += 1
	if immortal:
		GameState.energy = GameState.MAX_ENERGY
	var scene := get_tree().current_scene
	if scene and scene.scene_file_path == Router.BATTLE and not Ui.transitioning:
		_drive_battle(scene)
	elif scene and scene.scene_file_path == Router.MINIGAME and not Ui.transitioning and scene.get("phase") == "play":
		scene.call("_finish", minigame_result == "win", minigame_result == "partial")
	elif scene and scene.scene_file_path == Router.WORK and not Ui.transitioning and scene.get("phase") == "play":
		scene.set("score", scene.get("target"))
		scene.set("time_left", 0.0)
	elif Ui.busy and _frame % 3 == 0:
		if Ui.get("_mode") == "choose":
			var idx: int = choose_queue.pop_front() if not choose_queue.is_empty() else choose_index
			Ui.set("_sel", mini(idx, (Ui.get("_options") as Array).size() - 1))
		_tap("confirm")


func _drive_battle(b: Node) -> void:
	if _frame % 3 != 0:
		return
	match str(b.get("phase")):
		"menu":
			var step: Array = plan.pop_front() if not plan.is_empty() else fallback
			b.set("menu", step[0])
			b.set("_pending_sub", step[1])
			_tap("confirm")
		"sub":
			var items: Array = b.get("sub_items")
			b.set("sub", mini(int(b.get("_pending_sub")), items.size() - 1))
			_tap("confirm")
		"msg", "bubble":
			_tap("confirm")
		"dodge":
			if fast_dodge:
				b.set("attack_t", 99.0)


func _tap(action: String) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)


func _touch(pos: Vector2, pressed: bool, index: int) -> void:
	var t := InputEventScreenTouch.new()
	t.position = pos
	t.pressed = pressed
	t.index = index
	Input.parse_input_event(t)


func _drag(pos: Vector2, index: int) -> void:
	var d := InputEventScreenDrag.new()
	d.position = pos
	d.index = index
	Input.parse_input_event(d)


func _scene_path() -> String:
	var scene := get_tree().current_scene
	return scene.scene_file_path if scene else ""


func _wait_scene(path: String, max_frames := 30000) -> void:
	var n := 0
	while (_scene_path() != path or Ui.transitioning) and n < max_frames:
		await get_tree().process_frame
		n += 1
	if n >= max_frames:
		_fail("timeout aspettando %s (scena attuale %s)" % [path, _scene_path()])
	await get_tree().process_frame
	# l'arrivo dalle scale (pochi secondi di scena scriptata)
	var t0 := Time.get_ticks_msec()
	while Ui.cutscene and Time.get_ticks_msec() - t0 < 3000 and path in Router.WORLD:
		await get_tree().process_frame


func _idle(max_frames := 8000) -> void:
	var n := 0
	await get_tree().process_frame
	while (Ui.busy or Ui.transitioning) and n < max_frames:
		await get_tree().process_frame
		n += 1
	if n >= max_frames:
		_fail("timeout: l'interfaccia è rimasta bloccata")
	await get_tree().process_frame


func _go(path: String, spawn := "") -> Node:
	Router.goto(path, spawn)
	await _wait_scene(path)
	await _idle()
	return get_tree().current_scene


func _npc(id: String) -> Node:
	for n in get_tree().get_nodes_in_group("npc"):
		if n.get("id") == id:
			return n
	_fail("non trovo %s nella scena" % id)
	return null


func _check(cond: bool, what: String) -> void:
	if not cond:
		_fail(what)


func _fail(what: String) -> void:
	_failures.append(what)
	push_error("TEST: " + what)


## Il Mercato da capo, al -3 col badge del -3 (l'arrivo già visto).
func _c3_reset(money := 0) -> Room:
	GameState.new_game()
	GameState.badges.assign(["-4", "-3"])
	GameState.flags["c3_arrivo"] = true
	GameState.money = money
	choose_queue = []
	minigame_result = "win"
	return await _go(Router.MERCATO, "from_below")


## Parla con qualcuno e aspetta che sia tutto finito (anche un minigioco e il ritorno).
func _c3_talk(id: String) -> Room:
	var n := _npc(id)
	if n:
		await n.call("interact")
	return await _c3_settle()


func _c3_call(m: Room, method: String, args: Array = []) -> Room:
	await m.callv(method, args)
	return await _c3_settle()


## Aspetta il ritorno al Mercato (anche da un minigioco) e la fine di ogni scena: tornando dal
## furto, la scelta al terminale e l'aumento dei prezzi partono da soli, con delle pause in mezzo.
func _c3_settle() -> Room:
	await get_tree().process_frame
	await _wait_scene(Router.MERCATO, 60000)
	await _idle()
	while Ui.cutscene or Ui.busy or Ui.transitioning:
		await get_tree().process_frame
	await _idle()
	return get_tree().current_scene as Room


func _test_chapter3() -> void:
	# 9-10: dal Sottoufficio si arriva al Mercato; l'ingresso si vede una volta sola
	GameState.new_game()
	GameState.badges.assign(["-4", "-3"])
	var m: Room = await _go(Router.MERCATO, "from_below")
	while Ui.cutscene or Ui.busy:
		await get_tree().process_frame
	_check(_scene_path() == Router.MERCATO and GameState.floor_id == "-3" and GameState.flags.get("c3_arrivo", false), "il Mercato dovrebbe aprirsi al -3, con l'arrivo")
	_check(m.player.position.distance_to(m.get("_stairs_down_exit")) < 4.0, "dal Sottoufficio si dovrebbe arrivare alle scale")
	_check(not m.call("_prices_due"), "i prezzi non dovrebbero cambiare prima del primo turno")
	# 11: Leda e Amir ci sono e si parla con loro
	_check(_npc("leda") != null and _npc("amir") != null, "Leda e Amir dovrebbero essere al Mercato")
	GameState.minutes = GameState.DAY_START
	choose_queue = [1, 1]
	m = await _c3_talk("leda")
	_check(GameState.flags.get("c3_leda", false) and not GameState.flags.get("c3_leda_inventario", false), "Leda: il primo incontro, senza aiuto")
	# 12: l'inventario si può sbagliare e riprovare; conta solo se riesce
	minigame_result = "fail"
	choose_queue = [0]
	m = await _c3_talk("leda")
	_check(not GameState.flags.get("c3_leda_inventario", false) and "leda" not in GameState.helped_ids, "un inventario sbagliato non dovrebbe contare come aiuto")
	minigame_result = "win"
	choose_queue = [0]
	m = await _c3_talk("leda")
	_check(GameState.flags.get("c3_leda_inventario", false) and "leda" in GameState.helped_ids and "Biscotti di Leda" in GameState.items, "l'inventario riuscito: flag, aiuto e biscotti")
	_check(GameState.money == 0, "Leda non ha soldi da dare: niente premio in euro")
	# 13: le consegne di Amir: a metà (aiutato, niente bonus), poi riprovate
	choose_queue = [1]
	m = await _c3_talk("amir")
	_check(GameState.flags.get("c3_amir", false) and not GameState.flags.get("c3_amir_aiutato", false), "Amir: il primo incontro")
	minigame_result = "partial"
	choose_queue = [0]
	m = await _c3_talk("amir")
	_check(GameState.flags.get("c3_amir_aiutato", false) and not GameState.flags.get("c3_amir_bonus", false), "consegne a metà: aiutato ma senza bonus")
	_check(GameState.flags.get("c3_amir_sogno", false), "dopo le consegne Amir dovrebbe raccontare il sogno")
	minigame_result = "win"
	choose_queue = [0]
	m = await _c3_talk("amir")
	_check(GameState.flags.get("c3_amir_bonus", false), "riprovando, il bonus delle consegne")
	# l'acqua: saldo zero, saldo insufficiente, poi una bottiglia sola
	GameState.money = 0
	choose_queue = [0]
	m = await _c3_call(m, "_acqua")
	_check(not GameState.flags.get("c3_acqua", false) and GameState.money == 0, "senza soldi l'acqua non si compra")
	GameState.money = 9
	choose_queue = [0]
	m = await _c3_call(m, "_acqua")
	_check(GameState.money == 9 and "Acqua economica" not in GameState.items, "con 9 € l'acqua (10 €) non si compra")
	GameState.money = 30
	choose_queue = [0]
	m = await _c3_call(m, "_acqua")
	choose_queue = [0]
	m = await _c3_call(m, "_acqua")
	_check(GameState.money == 20 and GameState.items.count("Acqua economica") == 1, "l'acqua costa 10 € e si compra una volta sola")
	choose_queue = [0]
	m = await _c3_talk("amir")
	_check(GameState.flags.get("c3_acqua_amir", false) and "Acqua economica" not in GameState.items, "l'acqua si può regalare ad Amir")

	# 14-16, 23: il turno alla cassa paga 120 €, una volta al giorno; il capo chiama una volta
	var money0 := GameState.money
	choose_queue = [0, 0, 1]
	m = await _c3_call(m, "_station", [GameState.job("cassa_mercato")])
	_check(GameState.money == money0 + 120 and int(GameState.flags.get("c3_turni", 0)) == 1, "il turno alla cassa dovrebbe pagare 120 € (pagati %d)" % (GameState.money - money0))
	_check(GameState.flags.get("c3_capo", false) and GameState.flags.get("c3_capo_sospeso", false) and not GameState.flags.get("c3_capo_chiuso", false), "dopo il turno il capo chiama; 'Ci penso' lascia l'offerta aperta")
	choose_queue = [0]
	m = await _c3_call(m, "_station", [GameState.job("cassa_mercato")])
	_check(GameState.money == money0 + 120, "un secondo turno nello stesso giorno non dovrebbe pagare")
	# la notte passa: gli interessi salgono, i soldi no
	var debt0 := GameState.debt
	GameState.call("_new_day")
	GameState.call("_new_day")
	_check(GameState.debt > debt0 and GameState.money == money0 + 120, "due notti: il debito cresce, il saldo resta")
	GameState.pending_lines.clear()
	choose_queue = [0]
	m = await _c3_call(m, "_station", [GameState.job("cassa_mercato")])
	_check(GameState.money == money0 + 240 and int(GameState.flags.get("c3_turni", 0)) == 2, "il giorno dopo si lavora di nuovo, sempre 120 €")
	_check(choose_queue.is_empty() and GameState.flags.get("c3_capo_sospeso", false), "il capo non dovrebbe richiamare")
	# 18: al terminale si chiude l'offerta per sempre; 21-22: poi i prezzi salgono, una volta
	choose_queue = [2]
	m = await _c3_call(m, "_terminale")
	_check(GameState.flags.get("c3_capo_chiuso", false) and not GameState.is_robot("amir"), "chiudere l'offerta non dovrebbe robotizzare Amir")
	m = await _go(Router.MERCATO, "from_below")
	_check(GameState.flags.get("c3_prezzi", false) and GameState.market_price("pane") == 25 and GameState.market_price("latte") == 32 and GameState.market_price("acqua") == 15, "i prezzi dovrebbero salire: pane 25, latte 32, acqua 15")
	_check((m.call("board") as Sprite2D).texture.resource_path == m.BOARD_NEW, "il tabellone dovrebbe mostrare i prezzi nuovi")
	_check(not m.call("_prices_due"), "l'aggiornamento dei prezzi avviene una volta sola")
	GameState.worked_today = false
	money0 = GameState.money
	choose_queue = [0]
	m = await _c3_call(m, "_station", [GameState.job("cassa_mercato")])
	_check(GameState.money == money0 + 120, "dopo l'aumento dei prezzi la paga resta 120 €")
	# 24: la seconda visita a Leda: gli ordini condivisi solo dopo l'inventario e la fattura
	money0 = GameState.money
	choose_queue = [0, 1]
	m = await _c3_talk("leda")
	_check(GameState.flags.get("c3_leda_fattura", false) and GameState.flags.get("c3_leda_mamma", false) and GameState.flags.get("c3_leda_ordini", false), "Leda: fattura, la madre, poi gli ordini condivisi")
	_check(GameState.money == money0, "gli ordini condivisi non costano niente")
	# 31: la scena segreta (Amir umano, tutti e due aiutati, le storie sentite)
	m = await _go(Router.MERCATO, "from_below")
	_check(m.find_child("SedutaLeda", true, false) != null, "Leda e Amir dovrebbero essere seduti sulle cassette")
	choose_queue = [0]
	m = await _c3_call(m, "_secret")
	_check(GameState.flags.get("c3_segreta", false), "la scena segreta si dovrebbe vedere")
	m = await _go(Router.MERCATO, "from_below")
	_check(m.find_child("SedutaLeda", true, false) == null, "la scena segreta non si ripete")
	# 25, 27: il badge regalato (niente soldi, niente debito), mai due volte
	money0 = GameState.money
	debt0 = GameState.debt
	m = await _c3_call(m, "_badge_machine")
	choose_queue = [0]
	m = await _c3_call(m, "_badge_machine")
	_check(GameState.has_badge("-2") and GameState.money == money0 and GameState.debt == debt0 and GameState.flags.get("c3_badge", "") == "regalo", "il badge regalato non tocca soldi né debito")
	m = await _c3_call(m, "_badge_machine")
	_check(GameState.badges.count("-2") == 1, "nessun badge due volte")
	# 28-30: la rivelazione e lo sguardo indietro, poi la Banca col salvataggio automatico
	await m.call("on_stairs_step", m.player, "-2")
	_check(GameState.flags.get("c3_rivelazione", false) and GameState.flags.get("c3_riepilogo", false), "sul primo gradino lo scontrino")
	_check("RETRIBUZIONE TURNO: 120 €" in m.call("receipt_lines") and "PREZZO PANE AGGIORNATO: 25 €" in m.call("receipt_lines"), "lo scontrino dovrebbe riportare paga e pane")
	_check(m.call("look_back_line") == "Per la prima volta, qualcuno aveva smesso di fare i conti da solo.", "con gli ordini condivisi, la frase degli ordini")
	_check(m.call("on_stairs_top", m.player), "in cima alle scale lo sguardo indietro")
	await _wait_scene(Router.BANCA, 60000)
	await _idle()
	while Ui.cutscene or Ui.busy:
		await get_tree().process_frame
	_check(GameState.floor_id == "-2" and GameState.flags.get("c3_fine", false), "dopo lo sguardo indietro si arriva alla Banca")
	var esito: Dictionary = GameState.flags.get("c3_esito", {})
	_check(esito.get("leda", "") == "rete" and esito.get("amir", "") == "umano" and esito.get("amir_sorella", false), "le conseguenze per i capitoli dopo")
	_check(GameState.has_save(), "lo sguardo indietro dovrebbe salvare")

	# 17, 19, 20, 34, 35: aiutare Amir e poi rubargli il merito
	m = await _c3_reset()
	for f in ["c3_amir", "c3_amir_aiutato", "c3_amir_sogno", "c3_capo", "c3_capo_sospeso"]:
		GameState.flags[f] = true
	GameState.flags["c3_turni"] = 1
	var lv0 := GameState.lv()
	choose_queue = [0, 2, 0]
	m = await _c3_call(m, "_terminale")
	_check(GameState.flags.get("c3_furto_ok", false) and GameState.flags.get("c3_capo_firmato", false), "un, due, tre, stella, poi la firma (dividere: no)")
	_check(GameState.money == 1500 and GameState.is_robot("amir") and GameState.lv() == lv0 + 1, "firmare: 1.500 €, Amir robot, LV su")
	m = await _c3_call(m, "_terminal_choice")
	await m.call("_sign", 1500)
	_check(GameState.money == 1500 and GameState.exploited == 1, "il premio del capo non si prende due volte")
	var robot := [GameState.robot_line("amir"), GameState.robot_line("amir"), GameState.robot_line("amir"), GameState.robot_line("amir")]
	_check("LA CONSEGNA È FELICITÀ." in robot and "PRODOTTO NON DISPONIBILE." in robot, "Amir robot: frasi sue (e quelle del sogno)")
	_check(GameState.flags.get("c3_prezzi", false), "chiusa l'offerta (firmando), i prezzi salgono")
	_check(m.call("look_back_line") == "Il Mercato era più efficiente di quando eri arrivato.", "con Amir robot, la frase dell'efficienza")
	# senza Amir umano niente regalo: il badge si compra (2.000 € esatti)
	GameState.money = 1999
	GameState.flags["c3_nives"] = true
	choose_queue = [0]
	m = await _c3_call(m, "_badge_machine")
	_check(not GameState.has_badge("-2"), "con 1.999 € il badge non si compra")
	GameState.money = 2000
	debt0 = GameState.debt
	choose_queue = [0]
	m = await _c3_call(m, "_badge_machine")
	_check(GameState.has_badge("-2") and GameState.money == 0 and GameState.debt == debt0 - 2000 and GameState.flags.get("c3_badge", "") == "comprato", "2.000 € esatti: badge comprato, debito giù")
	GameState.save_game(Router.MERCATO, m.player.position)
	GameState.new_game()
	GameState.load_game()
	_check(GameState.is_robot("amir") and GameState.flags.get("c3_capo_firmato", false) and GameState.has_badge("-2") and int(GameState.flags.get("c3_turni", 0)) == 1, "salvare e ricaricare conserva tutto")

	# 33: si finisce senza aiutare nessuno (solo lavoro); saldo sopra i 2.000 €
	m = await _c3_reset(2500)
	GameState.flags["c3_turni"] = 3
	GameState.flags["c3_nives"] = true
	choose_queue = [0]
	m = await _c3_call(m, "_badge_machine")
	_check(GameState.has_badge("-2") and GameState.money == 500, "con 2.500 € il badge lascia 500 €")
	_check(m.call("look_back_line") == "Il Mercato non aveva bisogno di sapere chi fossi per continuare a funzionare.", "solo lavoro: la frase del Mercato che funziona")
	_check(m.find_child("SedutaLeda", true, false) == null, "senza aiutare nessuno, niente scena segreta")
	GameState.flags["c3_leda_inventario"] = true
	GameState.flags["c3_amir_aiutato"] = true
	_check(m.call("look_back_line") == "Non avevi risolto i loro problemi. Almeno avevi imparato i loro nomi.", "tutti e due aiutati: la frase dei nomi")


## La Banca da capo, al -2 col badge del -2 (l'arrivo già visto).
func _c4_reset(money := 0) -> Room:
	GameState.new_game()
	GameState.badges.assign(["-4", "-3", "-2"])
	GameState.flags["c4_arrivo"] = true
	GameState.money = money
	choose_queue = []
	minigame_result = "win"
	return await _go(Router.BANCA, "from_below")


func _c4_talk(id: String) -> Room:
	var n := _npc(id)
	if n:
		await n.call("interact")
	return await _c4_settle()


func _c4_call(m: Room, method: String, args: Array = []) -> Room:
	await m.callv(method, args)
	return await _c4_settle()


## Aspetta il ritorno in Banca (anche da un minigioco) e la fine di ogni dialogo.
func _c4_settle() -> Room:
	await get_tree().process_frame
	await _wait_scene(Router.BANCA, 60000)
	await _idle()
	while Ui.cutscene or Ui.busy or Ui.transitioning:
		await get_tree().process_frame
	await _idle()
	return get_tree().current_scene as Room


func _test_chapter4() -> void:
	var bank := GameState.bank
	# 1-2: dal Mercato si arriva alla Banca, l'arrivo una volta sola; Olga e Teo ci sono, grigi
	GameState.new_game()
	GameState.badges.assign(["-4", "-3", "-2"])
	var m: Room = await _go(Router.BANCA, "from_below")
	while Ui.cutscene or Ui.busy:
		await get_tree().process_frame
	_check(_scene_path() == Router.BANCA and GameState.floor_id == "-2" and GameState.flags.get("c4_arrivo", false), "la Banca dovrebbe aprirsi al -2, con l'arrivo")
	_check(m.player.position.distance_to(m.get("_stairs_down_exit")) < 4.0, "dal Mercato si dovrebbe arrivare alle scale")
	_check(_npc("olga") != null and _npc("teo") != null and not GameState.is_robot("teo"), "Olga e Teo dovrebbero essere in Banca")
	_check(not GameState.flags.has("chapter_4"), "il riepilogo del capitolo si scrive solo alla fine")
	# 3: il SALTAFILA è una battuta, non costa niente
	GameState.money = 50
	choose_queue = [2, 1]
	m = await _c4_call(m, "_distributore")
	_check(GameState.flags.get("c4_saltafila_chiesto", false) and not GameState.flags.get("c4_saltafila", false) and GameState.money == 50, "SALTAFILA: 'Quanto costa?' e poi no, gratis")
	GameState.money = 0
	# 4-7: Olga; LE RATE MANCANTI si può sbagliare e riprovare; poi la contestazione
	GameState.minutes = GameState.DAY_START
	choose_queue = [0, 1]
	m = await _c4_talk("olga")
	_check(GameState.flags.get("c4_olga", false) and not GameState.flags.get("c4_olga_ordinati", false), "Olga: il primo incontro, senza aiuto")
	minigame_result = "fail"
	choose_queue = [0]
	m = await _c4_talk("olga")
	_check(not GameState.flags.get("c4_olga_ordinati", false) and "olga" not in GameState.helped_ids, "rate sbagliate: non conta come aiuto")
	minigame_result = "win"
	choose_queue = [0, 0]
	m = await _c4_talk("olga")
	_check(GameState.flags.get("c4_olga_ordinati", false) and GameState.flags.get("c4_olga_doppia", false) and "olga" in GameState.helped_ids, "rate in ordine e commissione doppia trovata")
	_check(GameState.flags.get("c4_olga_contestazione", false) and GameState.money == 0, "tornando dal minigioco la contestazione (e nessun premio in euro)")
	# l'aritmetica dell'estratto conto torna, e la voce doppia è una sola commissione
	var st: Dictionary = bank["olga"]["estratto"]
	var total := int(st["saldo_iniziale"])
	for r: Array in st["righe"]:
		total += int(r[2])
	var dup: Array = st["doppie"]
	_check(total == int(st["saldo_finale"]) and dup.size() == 2 and st["righe"][dup[0]][1] == st["righe"][dup[1]][1] and -int(st["righe"][dup[0]][2]) == int(bank["olga"]["rimborso"]), "l'estratto conto di Olga dovrebbe tornare")
	m = await _c4_talk("olga")
	_check(not GameState.flags.get("c4_olga_risposta", false), "la risposta alla contestazione arriva dopo una notte")
	GameState.call("_new_day")
	GameState.pending_lines.clear()
	m = await _c4_talk("olga")
	_check(GameState.flags.get("c4_olga_risposta", false) and GameState.money == 0, "dopo una notte Olga ha il rimborso (suo, non tuo)")
	# 8-11: Teo; LA PRATICA IMPOSSIBILE; il quaderno
	GameState.minutes = GameState.DAY_START
	choose_queue = [1, 1]
	m = await _c4_talk("teo")
	_check(GameState.flags.get("c4_teo", false) and not GameState.flags.get("c4_teo_aiutato", false), "Teo: il primo incontro")
	minigame_result = "fail"
	choose_queue = [0]
	m = await _c4_talk("teo")
	_check(not GameState.flags.get("c4_teo_aiutato", false), "pratiche sbagliate: Teo non è aiutato")
	minigame_result = "win"
	choose_queue = [0]
	m = await _c4_talk("teo")
	_check(GameState.flags.get("c4_teo_aiutato", false) and "teo" in GameState.helped_ids, "pratiche controllate: Teo aiutato")
	m = await _c4_call(m, "_quaderno")
	_check(GameState.flags.get("c4_teo_sogno", false), "il quaderno: il sogno di Teo")
	# 12-16: il TURNO paga 800 €, una volta al giorno; il capo chiama una volta, dopo il primo
	var money0 := GameState.money
	var job := GameState.job("sportello_banca")
	choose_queue = [0, 0, 2, 1]
	m = await _c4_call(m, "_station", [job])
	_check(GameState.money == money0 + 800 and int(GameState.flags.get("c4_turni", 0)) == 1, "il turno allo sportello dovrebbe pagare 800 € (pagati %d)" % (GameState.money - money0))
	_check(GameState.flags.get("c4_capo", false) and GameState.flags.get("c4_capo_sospeso", false) and not GameState.flags.get("c4_capo_chiuso", false), "dopo il turno il capo chiama; 'Ci penso' lascia l'offerta aperta")
	choose_queue = [0]
	m = await _c4_call(m, "_station", [job])
	_check(GameState.money == money0 + 800, "un secondo turno nello stesso giorno non paga")
	GameState.call("_new_day")
	GameState.pending_lines.clear()
	choose_queue = [0]
	m = await _c4_call(m, "_station", [job])
	_check(GameState.money == money0 + 1600 and int(GameState.flags.get("c4_turni", 0)) == 2 and choose_queue.is_empty(), "il giorno dopo si lavora ancora (e il capo non richiama)")
	# 17: dal terzo turno le pratiche raggruppate: stessa paga, niente minigioco
	GameState.call("_new_day")
	GameState.pending_lines.clear()
	choose_queue = [1]
	m = await _c4_call(m, "_station", [job])
	_check(GameState.money == money0 + 2400 and int(GameState.flags.get("c4_raggruppate", 0)) == 1 and GameState.worked_today, "pratiche raggruppate: 800 €, un turno")
	# 18-19: prima che l'offerta sia chiusa il terminale del conto non risponde; poi si chiude
	m = await _c4_call(m, "_conto")
	_check(not GameState.flags.get("c4_conto", false), "il terminale del conto si accende dopo l'offerta del capo")
	var refused := int(GameState.flags.get("promotions_refused", 0))
	choose_queue = [2]
	m = await _c4_call(m, "_rapporto")
	_check(GameState.flags.get("c4_capo_chiuso", false) and not GameState.is_robot("teo") and int(GameState.flags.get("promotions_refused", 0)) == refused + 1, "chiudere l'offerta non robotizza Teo")
	choose_queue = [0]
	m = await _c4_call(m, "_rapporto")
	_check(GameState.flags.get("c4_teo_rapporto", false) and GameState.flags.get("c4_teo_copia", false), "rifiutata l'offerta, il rapporto si segnala col nome di Teo")
	# 20-22: il conto mostra il debito vero; l'anomalia; Teo spiega il codice
	_check(("* DEBITO ATTUALE: %s." % GameState.euros(GameState.debt)) in m.call("account_lines"), "il terminale dovrebbe mostrare il debito vero")
	var debt0 := GameState.debt
	choose_queue = [0]
	m = await _c4_call(m, "_conto")
	_check(GameState.flags.get("c4_conto", false) and GameState.flags.get("c4_anomalia", false) and GameState.flags.get("c4_teo_codice", false), "l'anomalia del debito, e Teo che legge il codice")
	_check(GameState.debt == debt0, "guardare il conto non cambia il debito")
	money0 = GameState.money
	choose_queue = [2, 0]
	m = await _c4_call(m, "_conto")
	_check(GameState.debt == debt0 - GameState.MIN_PAYMENT and GameState.money == money0 - GameState.MIN_PAYMENT, "'Voglio soltanto pagarlo': la rata scala il debito")
	# 23: la scena segreta (Olga e il quaderno di Teo), una volta sola, senza premi
	m = await _go(Router.BANCA, "from_below")
	_check(m.find_child("SedutoTeo", true, false) != null, "Olga dovrebbe essere alla scrivania di Teo")
	money0 = GameState.money
	m = await _c4_call(m, "_secret")
	_check(GameState.flags.get("c4_segreta", false) and GameState.money == money0, "la scena segreta si vede, senza premi")
	m = await _go(Router.BANCA, "from_below")
	_check(m.find_child("SedutoTeo", true, false) == null, "la scena segreta non si ripete")
	# 24-25: il badge regalato (niente soldi, niente debito), mai due volte
	money0 = GameState.money
	debt0 = GameState.debt
	m = await _c4_call(m, "_badge_machine")
	_check(GameState.flags.get("c4_nives", false) and not GameState.has_badge("0"), "Nives: prima il prezzo")
	choose_queue = [0]
	m = await _c4_call(m, "_badge_machine")
	_check(GameState.has_badge("0") and GameState.money == money0 and GameState.debt == debt0 and GameState.flags.get("c4_badge", "") == "regalo", "il badge regalato non tocca soldi né debito")
	m = await _c4_call(m, "_badge_machine")
	_check(GameState.badges.count("0") == 1, "nessun badge due volte")
	# 26-28: la rivelazione, lo sguardo indietro, il riepilogo e il capitolo dopo
	await m.call("on_stairs_step", m.player, "0")
	_check(GameState.flags.get("c4_rivelazione", false) and "NESSUN DOCUMENTO TROVATO." in m.call("revelation_lines"), "sul primo gradino la rivelazione")
	_check(m.call("look_back_line") == "Non avevi cancellato i debiti. Avevi aiutato qualcuno a non affrontarli da solo.", "tutti e due aiutati: la frase dell'aiuto")
	var next: String = m.call("next_scene")
	_check(m.call("on_stairs_top", m.player), "in cima alle scale lo sguardo indietro")
	var out: Dictionary = GameState.flags.get("chapter_4", {})
	_check(out.get("completed", false) and out["olga"]["complaint_submitted"] and out["teo"]["practices_helped"] and not out["teo"]["robotized"] and out["exit"]["badge_source"] == "regalo" and out["debt"]["anomaly_discovered"] and out["secret_scene_seen"], "il riepilogo chapter_4 per i capitoli dopo")
	_check(out["turn"]["completed_count"] == 3 and out["teo"]["report_copy_saved"] and not out["boss"]["offer_accepted"], "il riepilogo: turni e rapporto")
	await _wait_scene(next, 60000)
	await _idle()
	_check(GameState.has_save() and GameState.flags.get("c4_fine", false), "lo sguardo indietro dovrebbe salvare")

	# 29-30: rubare il rapporto 404: un, due, tre, stella; leggere non decide; firmare una volta
	m = await _c4_reset()
	for f in ["c4_teo", "c4_teo_aiutato", "c4_teo_sogno", "c4_capo", "c4_capo_sospeso"]:
		GameState.flags[f] = true
	GameState.flags["c4_turni"] = 1
	var lv0 := GameState.lv()
	choose_queue = [0, 2, 0]
	m = await _c4_call(m, "_rapporto")
	_check(GameState.flags.get("c4_furto_ok", false) and GameState.flags.get("c4_rapporto_letto", false) and GameState.flags.get("c4_capo_firmato", false), "un, due, tre, stella; leggere; poi la firma")
	_check(GameState.money == int(bank["premio_capo"]) and GameState.is_robot("teo") and GameState.lv() == lv0 + 1, "firmare: 3.000 €, Teo robot, LV su")
	await m.call("_sign", 3000)
	_check(GameState.money == 3000 and GameState.exploited == 1, "il premio del capo non si prende due volte")
	var robot := []
	for i in 8:
		robot.append(GameState.robot_line("teo"))
	_check("LA PRECISIONE È PRODUTTIVITÀ." in robot and "ATTIVITÀ NON RILEVANTE." in robot, "Teo robot: frasi sue (e quelle del quaderno)")
	m = await _c4_call(m, "_quaderno")
	_check(GameState.flags.get("c4_quaderno_robot", false), "il quaderno resta, anche con Teo robot")
	_check(m.call("look_back_line") == "La Banca aveva guadagnato un impiegato perfetto. Nessuno aveva chiesto cosa avesse perso.", "con Teo robot, la frase dell'impiegato perfetto")
	GameState.flags["c4_olga_contestazione"] = true
	_check(not m.call("gift_allowed"), "con Teo robot niente badge regalato")
	m = await _go(Router.BANCA, "from_below")
	_check(m.find_child("SedutoTeo", true, false) == null and _npc("teo").has_node("Antenna"), "Teo robot: niente scena segreta, e l'antenna")
	choose_queue = [0]
	m = await _c4_call(m, "_conto")
	_check(GameState.flags.get("c4_anomalia", false) and not GameState.flags.get("c4_teo_codice", false), "con Teo robot nessuno spiega il codice")
	# senza regalo il badge si compra (4.000 € esatti), niente softlock
	GameState.money = 3999
	GameState.flags["c4_nives"] = true
	choose_queue = [2, 0]
	m = await _c4_call(m, "_badge_machine")
	_check(not GameState.has_badge("0"), "con 3.999 € il badge non si compra")
	GameState.money = 4000
	debt0 = GameState.debt
	choose_queue = [2, 0]
	m = await _c4_call(m, "_badge_machine")
	_check(GameState.has_badge("0") and GameState.money == 0 and GameState.debt == debt0 - 4000 and GameState.flags.get("c4_badge", "") == "comprato", "4.000 € esatti: badge comprato, debito giù")
	GameState.save_game(Router.BANCA, m.player.position)
	GameState.new_game()
	GameState.load_game()
	_check(GameState.is_robot("teo") and GameState.flags.get("c4_capo_firmato", false) and GameState.has_badge("0"), "salvare e ricaricare conserva tutto")

	# lasciare la firma di Teo: niente soldi, niente robot, l'anomalia si può segnalare
	m = await _c4_reset()
	for f in ["c4_teo", "c4_capo", "c4_capo_sospeso"]:
		GameState.flags[f] = true
	choose_queue = [0, 1, 0]
	m = await _c4_call(m, "_rapporto")
	_check(GameState.flags.get("c4_teo_lasciato", false) and GameState.flags.get("c4_capo_chiuso", false) and GameState.flags.get("c4_teo_copia", false), "lasciare la firma di Teo, poi segnalarlo")
	_check(GameState.money == 0 and not GameState.is_robot("teo") and GameState.exploited == 0, "lasciare la firma: niente premio, Teo resta Teo")
	_check(m.call("look_back_line") == "Avevi attraversato la Banca. La Banca sarebbe rimasta.", "senza aiuti né anomalia, la frase generale")
	GameState.flags["c4_anomalia"] = true
	_check(m.call("look_back_line") == "Per la prima volta, non eri sicuro di dovere davvero ciò che ti chiedevano.", "con l'anomalia, la frase del dubbio")

	# economia A (solo lavoro): da zero, cinque turni bastano per il badge da 4.000 €
	m = await _c4_reset()
	var turns := 0
	while GameState.money < GameState.badge_cost("0") and turns < 10:
		GameState.worked_today = false
		if turns < 2:
			choose_queue = [0]
			m = await _c4_call(m, "_station", [GameState.job("sportello_banca")])
		else:
			m = await _c4_call(m, "quick_turn")
		turns += 1
	_check(turns == 5 and GameState.money == 4000, "solo lavoro: 5 turni per 4.000 € (turni %d, soldi %d)" % [turns, GameState.money])


## La Città da capo, al piano terra col badge del piano terra (l'arrivo già visto).
func _c5_reset(money := 0) -> Room:
	GameState.new_game()
	GameState.badges.assign(["-4", "-3", "-2", "0"])
	GameState.flags["c5_arrivo"] = true
	GameState.money = money
	choose_queue = []
	minigame_result = "win"
	return await _go(Router.CITY, "from_below")


func _c5_talk(id: String) -> Room:
	var n := _npc(id)
	if n:
		await n.call("interact")
	return await _c5_settle()


func _c5_call(m: Room, method: String, args: Array = []) -> Room:
	await m.callv(method, args)
	return await _c5_settle()


## Aspetta di essere di nuovo in una stanza della Città (anche dopo un minigioco) e la fine di ogni scena.
func _c5_settle() -> Room:
	await get_tree().process_frame
	var n := 0
	while (_scene_path() not in [Router.CITY, Router.CASA_COMUNE] or Ui.transitioning) and n < 60000:
		await get_tree().process_frame
		n += 1
	if n >= 60000:
		_fail("timeout aspettando la Città (scena attuale %s)" % _scene_path())
	await _idle()
	while Ui.cutscene or Ui.busy or Ui.transitioning:
		await get_tree().process_frame
	await _idle()
	return get_tree().current_scene as Room


func _test_chapter5() -> void:
	var city := GameState.city
	var logic: GDScript = load("res://chapters/c5/citta_c5.gd")
	# 13-15: dalla Banca si arriva alla Città, l'arrivo una volta sola; Nadir e Rina ci sono, grigi
	GameState.new_game()
	GameState.badges.assign(["-4", "-3", "-2", "0"])
	GameState.flags["c1_arrivo"] = true
	GameState.flags["c2_b4"] = true
	GameState.helped_ids.append("tilde")
	GameState.flags["fermo_talked"] = true
	var m: Room = await _go(Router.CITY, "from_below")
	while Ui.cutscene or Ui.busy:
		await get_tree().process_frame
	_check(_scene_path() == Router.CITY and GameState.floor_id == "0" and GameState.flags.get("c5_arrivo", false), "la Città dovrebbe aprirsi al piano terra, con l'uscita dalla Torre")
	_check(m.player.position.distance_to(m.get("spawns")["from_below"]) < 4.0, "dalla Banca si dovrebbe arrivare davanti alla porta di vetro")
	_check(_npc("nadir") != null and _npc("rina") != null, "Nadir e Rina dovrebbero essere in piazza")
	_check(GameState.floor_above() == "cima" and GameState.badge_cost("cima") == 8000, "l'ultimo badge: la Cima, 8.000 €")
	_check(logic.closure_text() == "CHIUSURA PREVISTA: FRA 3 GIORNI.", "l'avviso: fra 3 giorni")
	m = await _go(Router.CITY, "from_below")
	_check(not Ui.cutscene and not GameState.flags.has("chapter_5"), "l'uscita dalla Torre si vede una volta sola")
	for i in 3:
		m = await _c5_call(m, "_albero")
	_check(int(GameState.flags.get("c5_albero", 0)) == 3, "l'albero: tre volte")
	# 20: Rina, ascoltata
	choose_queue = [0, 1, 2]
	m = await _c5_talk("rina")
	_check(GameState.flags.get("c5_rina", false) and GameState.flags.get("c5_rina_ascoltata", false), "Rina: 'Non toccare quella', poi le sue preoccupazioni")
	# 18-19: Nadir, il tabellone, IL PERCORSO POSSIBILE (sbagliare e riprovare)
	GameState.minutes = GameState.DAY_START
	choose_queue = [0, 2, 3, 0]
	minigame_result = "fail"
	m = await _c5_talk("nadir")
	_check(GameState.flags.get("c5_nadir", false) and GameState.flags.get("c5_tabellone", false) and GameState.flags.get("c5_nadir_lavoro", false) and GameState.flags.get("c5_nadir_uccelli", false), "Nadir: il tabellone che fa retromarcia, il lavoro, il merlo")
	_check(not GameState.flags.get("c5_nadir_percorso", false) and "nadir" not in GameState.helped_ids, "percorso sbagliato: non conta come aiuto")
	minigame_result = "win"
	choose_queue = [3, 0]
	m = await _c5_talk("nadir")
	_check(GameState.flags.get("c5_nadir_percorso", false) and "nadir" in GameState.helped_ids, "percorso trovato: Nadir aiutato")
	# la matematica del percorso: il compromesso è l'unico valido
	var pc: Dictionary = city["percorso"]
	_check(int(pc["entrata"]) - int(pc["partenza"]) == 80 and int(pc["budget"]) == 6, "il percorso: 80 minuti e 6 €")
	# 16-17: Ada, UNA STANZA PER TUTTI, la lettera
	m = await _go(Router.CASA_COMUNE, "default")
	_check(_npc("ada") != null and m.find_child("PortaArchivio", true, false) != null, "nella Casa Comune c'è Ada, e l'archivio è chiuso")
	choose_queue = [0, 1, 0]
	m = await _c5_talk("ada")
	_check(GameState.flags.get("c5_ada", false) and GameState.flags.get("c5_ada_stanze", false) and "ada" in GameState.helped_ids, "Ada: 'Sei alto?', poi le stanze sistemate")
	_check(_scene_path() == Router.CASA_COMUNE, "dal minigioco si torna nella Casa Comune")
	choose_queue = [1, 0, 2]
	m = await _c5_talk("ada")
	_check(GameState.flags.get("c5_lettera", false) and GameState.flags.get("c5_ada_vorrebbe", false), "la proposta CHEAP, e cosa farebbe Ada")
	m = await _c5_call(m, "_porta_archivio")
	m = await _c5_call(m, "_bacheca")
	_check(not GameState.flags.get("c5_rapporto", false), "prima della manifestazione i bilanci non si leggono")
	# 21-23: il TURNO paga 1.600 €; il capo chiama una volta; 'No. È di Ada.'; poi la manifestazione
	m = await _go(Router.CITY, "from_casa")
	var money0 := GameState.money
	var job := GameState.job("comunicazioni_citta")
	choose_queue = [0, 0, 0, 3, 1]
	m = await _c5_call(m, "_station", [job])
	_check(GameState.money == money0 + 1600 and int(GameState.flags.get("c5_turni", 0)) == 1, "il turno al centralino dovrebbe pagare 1.600 € (pagati %d)" % (GameState.money - money0))
	_check(GameState.flags.get("c5_capo", false) and GameState.flags.get("c5_capo_chiuso", false) and not GameState.is_robot("ada") and GameState.exploited == 0, "il capo chiama; 'No' chiude l'offerta e Ada resta Ada")
	# 28, 30: la manifestazione, le tre proposte, la vetrina
	_check(GameState.flags.get("c5_protesta", false) and GameState.flags.get("c5_vetrina", false) and str(GameState.flags.get("c5_proposta", "")) == "B", "la manifestazione parte, si sostiene B, poi CRASH")
	_check(m.find_child("VetrinaRottaNuova", true, false) != null and m.get("people").has("Ada") and m.get("people").has("Giornalista"), "in piazza: la vetrina rotta, Ada, il giornalista")
	choose_queue = [0]
	m = await _c5_call(m, "_station", [job])
	_check(GameState.money == money0 + 1600, "un secondo turno nello stesso giorno non paga")
	choose_queue = [0]
	m = await _c5_talk("rina")
	_check(GameState.flags.get("c5_vetrina_aiuto", false) and "rina" in GameState.helped_ids and m.find_child("Cartone", true, false) != null, "Rina: la vetrina messa in sicurezza (1 ora, senza soldi)")
	_check(GameState.money == money0 + 1600, "aiutare Rina non costa soldi")
	m = await _c5_call(m, "_manifestante")
	choose_queue = [2]
	m = await _c5_call(m, "_giornalista")
	_check(GameState.flags.get("c5_manifestante", false) and GameState.flags.get("c5_giornalista", false) and str(GameState.flags.get("c5_dichiarazione", "")) == "non_visto", "dopo la vetrina: chi manifesta, il giornalista, in fila (non si escludono)")
	choose_queue = [0]
	m = await _c5_talk("rina")
	_check(GameState.flags.get("c5_rina_vetrina", false), "Rina si può ascoltare anche dopo il giornalista")
	# 31: la notizia del giorno dopo (il giornalista ha parlato con tutti: confronto aperto)
	GameState.call("_new_day")
	GameState.pending_lines.clear()
	m = await _go(Router.CITY, "from_casa")
	_check(str(GameState.flags.get("c5_titolo", "")) == "Manifestazione per la Casa Comune: confronto aperto sul futuro dell'edificio.", "il titolo dipende da cosa si sa (titolo: %s)" % str(GameState.flags.get("c5_titolo", "")))
	# 32: gli ospiti dai capitoli prima compaiono solo se li hai conosciuti
	_check(not m.get("people").has("Leda") and not m.get("people").has("Teo"), "chi non hai conosciuto non compare")
	GameState.flags["c3_leda"] = true
	GameState.flags["c3_leda_ordini"] = true
	GameState.flags["c3_amir"] = true
	GameState.flags["c4_olga"] = true
	GameState.flags["c4_olga_contestazione"] = true
	m = await _go(Router.CITY, "from_casa")
	_check(m.get("people").has("Leda") and m.get("people").has("Amir") and m.get("people").has("Olga"), "Leda, Amir e Olga in piazza (conosciuti davvero)")
	choose_queue = [0]
	m = await _c5_call(m, "_leda")
	choose_queue = [0]
	m = await _c5_call(m, "_amir")
	m = await _c5_call(m, "_olga")
	_check(GameState.flags.get("c5_leda_collabora", false) and GameState.flags.get("c5_amir_consegne", false) and GameState.flags.get("c5_olga_racconto", false), "Leda (ordini condivisi), Amir umano (consegne), Olga (la Banca)")
	# 33-34: i bilanci, le note, il documento nascosto; i capitoli prima (contatore, B-4)
	m = await _go(Router.CASA_COMUNE, "default")
	_check(m.find_child("PortaArchivio", true, false) == null and _npc("ada") != null and not _npc("ada").visible, "dopo la manifestazione l'archivio è aperto (e Ada è in piazza)")
	m = await _c5_call(m, "_armadio")
	_check(not GameState.flags.get("c5_documento", false), "senza il rapporto, l'armadio è solo carta")
	choose_queue = [0]
	m = await _c5_call(m, "_bilanci")
	m = await _c5_call(m, "_armadio")
	m = await _c5_call(m, "_contatore")
	m = await _c5_call(m, "_cartella_b4")
	var b: Dictionary = city["bilanci"]
	_check(int(b["manutenzione"]) + int(b["canone_cheap"]) + int(b["oneri"]) - int(b["entrate"]) == 44000 and logic.deficit() == 44000, "i bilanci tornano: disavanzo 44.000 €")
	_check(GameState.flags.get("c5_rapporto", false) and GameState.flags.get("c5_documento", false) and GameState.flags.get("c5_contatore", false) and GameState.flags.get("c5_b4_capito", false), "rapporto, VALUTAZIONE OPPORTUNITÀ, contatore (Fondo), B-4 (Tilde)")
	# la rete dei pendolari (Nadir conosce Ada, adesso)
	m = await _go(Router.CITY, "from_casa")
	choose_queue = [3, 3]
	m = await _c5_talk("nadir")
	_check(GameState.flags.get("c5_nadir_rete", false), "Nadir: la rete dei pendolari")
	# 29, 35: l'assemblea: rapporto presentato, stanze organizzate, quattro risorse vere -> gestione comunitaria
	choose_queue = [0, 1]
	m = await _c5_call(m, "assembly")
	_check(GameState.flags.get("c5_assemblea", false) and GameState.flags.get("c5_rapporto_presentato", false) and str(GameState.flags.get("c5_esito", "")) == "comunitaria", "assemblea: conti veri, stanze, risorse: gestione comunitaria (esito %s)" % str(GameState.flags.get("c5_esito", "")))
	_check(m.find_child("InsegnaEsito", true, false) != null and not m.get("people").has("Manifestante"), "dopo l'assemblea la folla se ne va, resta l'insegna")
	_check(logic.closure_text().begins_with("CHIUSURA ANNULLATA"), "l'avviso segue l'esito")
	# 40: la scena segreta, una volta sola, senza premi
	m = await _go(Router.CITY, "from_casa")
	_check(m.find_child("PancaAda", true, false) != null, "Ada, Rina e Nadir sulla panchina")
	var money1 := GameState.money
	m = await _c5_call(m, "_panchina")
	_check(GameState.flags.get("c5_segreta", false) and GameState.money == money1, "i biscotti: la scena segreta, senza premi")
	m = await _go(Router.CITY, "from_casa")
	_check(m.find_child("PancaAda", true, false) == null, "la scena segreta non si ripete")
	# 36: il badge regalato (niente soldi, niente debito), mai due volte
	money1 = GameState.money
	var debt0 := GameState.debt
	choose_queue = [0]
	m = await _c5_call(m, "_badge_machine")
	_check(GameState.has_badge("cima") and GameState.money == money1 and GameState.debt == debt0 and str(GameState.flags.get("c5_badge", "")) == "regalo", "il badge regalato non tocca soldi né debito")
	m = await _c5_call(m, "_badge_machine")
	_check(GameState.badges.count("cima") == 1, "nessun badge due volte")
	# 38-41: la rivelazione, lo sguardo indietro, il riepilogo, il capitolo 6
	await m.call("on_stairs_step", m.player, "cima")
	_check(GameState.flags.get("c5_rivelazione", false) and "RISULTATO COMPLESSIVO: CRESCITA POSITIVA." in m.call("revelation_lines") and "COSTO DEI BENI ESSENZIALI: IN AUMENTO." in m.call("revelation_lines"), "sul primo gradino il bilancio della città")
	_check(logic.look_back_line() == "Non avevano trovato una soluzione perfetta. Avevano deciso di continuare a cercarla insieme.", "gestione comunitaria: la frase del cercare insieme")
	_check(m.call("on_stairs_top", m.player), "in cima alla scala lo sguardo indietro")
	var out: Dictionary = GameState.flags.get("chapter_5", {})
	_check(out.get("completed", false) and out["ada"]["room_minigame_completed"] and out["ada"]["helped"] and not out["ada"]["robotized"] and out["nadir"]["commuters_network_proposed"], "il riepilogo chapter_5: Ada e Nadir")
	_check(out["rina"]["window_help_offered"] and out["protest"]["community_outcome"] == "comunitaria" and out["protest"]["proposal_supported"] == "B" and out["report"]["hidden_document_found"] and out["report"]["prior_chapters_connected"], "il riepilogo: vetrina, assemblea, bilanci")
	_check(out["exit"]["badge_source"] == "regalo" and out["secret_scene_seen"] and out["turn"]["completed_count"] == 1 and not out["boss"]["offer_accepted"], "il riepilogo: badge, scena segreta, turni, capo")
	await _wait_scene("res://scenes/world/boss_office.tscn", 60000)
	await _idle()
	_check(GameState.has_save() and GameState.flags.get("c5_fine", false), "lo sguardo indietro dovrebbe salvare e portare alla Cima")

	# 24-27 e percorso D: aiutare Ada e poi rubarle il progetto; leggere non decide; firmare una volta
	m = await _c5_reset()
	for f in ["c5_ada", "c5_ada_stanze", "c5_capo", "c5_capo_sospeso", "c5_nadir", "c5_nadir_percorso", "c5_rina_ascoltata"]:
		GameState.flags[f] = true
	GameState.helped_ids.append("ada")
	GameState.flags["c5_turni"] = 1
	GameState.flags["c5_turno_giorno"] = GameState.day
	var lv0 := GameState.lv()
	choose_queue = [0, 2, 0, 3]
	m = await _c5_call(m, "_presentazioni")
	_check(GameState.flags.get("c5_furto_ok", false) and GameState.flags.get("c5_progetto_letto", false) and GameState.flags.get("c5_capo_firmato", false), "un, due, tre, stella; leggere il progetto; poi la firma")
	_check(GameState.money == int(city["premio_capo"]) and GameState.is_robot("ada") and GameState.lv() == lv0 + 1, "firmare: 6.000 €, Ada robot, LV su")
	_check(GameState.flags.get("c5_ada_stanze", false) and "ada" in GameState.helped_ids, "i progressi di Ada prima del robot restano registrati")
	await m.call("_sign", 6000)
	_check(GameState.money == 6000 and GameState.exploited == 1, "il premio del capo non si prende due volte")
	_check(GameState.flags.get("c5_protesta", false) and m.call("organizer") == "Studente" and m.get("people").has("AdaRobot"), "la manifestazione c'è anche con Ada robot: organizza uno studente")
	_check(not logic.gift_allowed(), "con Ada robot niente badge regalato")
	var robot := []
	for i in 4:
		robot.append(GameState.robot_line("ada"))
	_check("IL FUTURO DELL'ISTRUZIONE È EFFICIENTE." in robot and "IL TUO POTENZIALE È IL NOSTRO PROFITTO." in robot, "Ada robot: frasi sue")
	choose_queue = [1]
	m = await _c5_call(m, "robot_talk_ada", [null])
	m = await _go(Router.CASA_COMUNE, "default")
	_check(_npc("ada").has_node("Antenna"), "Ada robot ha l'antenna anche nella Casa Comune")
	choose_queue = [0]
	m = await _c5_call(m, "_bilanci")
	_check(GameState.flags.get("c5_rapporto", false), "il rapporto si legge anche con Ada robot")
	m = await _go(Router.CITY, "from_casa")
	choose_queue = [0, 3]
	m = await _c5_call(m, "assembly")
	_check(str(GameState.flags.get("c5_esito", "")) == "rinvio", "conti presentati ma nessuna risorsa, astenendosi: rinvio (esito %s)" % str(GameState.flags.get("c5_esito", "")))
	_check(logic.look_back_line() == "A volte una decisione non conclude una storia. Decide soltanto cosa bisognerà affrontare domani.", "rinvio: la frase della situazione sospesa")
	# 37: senza regalo il badge si compra (8.000 € esatti), niente softlock
	GameState.money = 7999
	choose_queue = [0]
	m = await _c5_call(m, "_badge_machine")
	_check(not GameState.has_badge("cima") and GameState.flags.get("c5_nives", false), "con 7.999 € il badge non si compra")
	GameState.money = 8000
	debt0 = GameState.debt
	choose_queue = [1, 0]
	m = await _c5_call(m, "_badge_machine")
	_check(GameState.has_badge("cima") and GameState.money == 0 and GameState.debt == debt0 - 8000 and str(GameState.flags.get("c5_badge", "")) == "comprato", "8.000 € esatti: badge comprato, debito giù")
	GameState.save_game(Router.CITY, m.player.position)
	GameState.new_game()
	GameState.load_game()
	_check(GameState.is_robot("ada") and GameState.flags.get("c5_capo_firmato", false) and GameState.has_badge("cima") and GameState.flags.get("c5_assemblea", false), "salvare e ricaricare conserva tutto")

	# 'Ci penso': l'offerta resta aperta; il giorno dopo la presentazione è passata (niente blocchi)
	m = await _c5_reset()
	choose_queue = [0, 1, 1, 1]
	m = await _c5_call(m, "_station", [job])
	_check(GameState.flags.get("c5_capo_sospeso", false) and not GameState.flags.get("c5_protesta", false), "'Ci penso': l'offerta resta aperta, niente manifestazione")
	GameState.call("_new_day")
	GameState.pending_lines.clear()
	choose_queue = [3]
	m = await _go(Router.CITY, "from_casa")
	m = await _c5_settle()
	_check(GameState.flags.get("c5_protesta", false) and GameState.flags.get("c5_capo_chiuso", false) and not GameState.is_robot("ada") and str(GameState.flags.get("c5_proposta", "")) == "nessuna", "il giorno dopo: l'offerta scade, la manifestazione parte")
	_check(logic.look_back_line() == "Erano tutti nella stessa città. Non stavano vivendo la stessa vita.", "senza assemblea: la frase della città frammentata")

	# le regole dell'assemblea (nessun punteggio): sostenere B non basta; pronti + A = rinvio
	GameState.flags["c5_rapporto_presentato"] = false
	GameState.flags["c5_ada_stanze"] = false
	_check(logic.outcome("B")["esito"] == "rinvio", "B senza conti né stanze: non passa da solo")
	_check(logic.outcome("A")["esito"] == "riconversione", "sostenere A senza alternative pronte: riconversione")
	for f in ["c5_rapporto_presentato", "c5_ada_stanze", "c5_nadir_rete", "c5_vetrina_aiuto"]:
		GameState.flags[f] = true
	_check(logic.outcome("A")["esito"] == "rinvio" and logic.outcome("nessuna")["esito"] == "comunitaria", "con i conti e le risorse: A divide (rinvio), astenersi lascia decidere gli altri")

	# economia A (solo lavoro, si rifiuta il capo): da zero, cinque turni per il badge da 8.000 €
	m = await _c5_reset()
	var turns := 0
	while GameState.money < GameState.badge_cost("cima") and turns < 12:
		GameState.worked_today = false
		if turns == 0:
			choose_queue = [0, 2, 1, 3, 3]
			m = await _c5_call(m, "_station", [job])
		elif turns == 1:
			choose_queue = [0]
			m = await _c5_call(m, "_station", [job])
		else:
			m = await _c5_call(m, "quick_turn")
		turns += 1
	_check(turns == 5 and GameState.money == 8000 and GameState.exploited == 0, "solo lavoro: 5 turni per 8.000 € (turni %d, soldi %d)" % [turns, GameState.money])
	_check(int(GameState.flags.get("c5_rapidi", 0)) == 3 and GameState.flags.get("c5_protesta", false), "dal terzo turno lo smistamento rapido; la manifestazione c'è comunque")


func _run() -> void:
	await _go(Router.MENU)

	# --- casa
	GameState.new_game()
	var home := await _go(Router.HOME, "bed")
	home.call("_computer")
	await _idle()

	# --- comandi touch: il joystick muove il personaggio, un tocco fa avanzare il dialogo
	TouchControls.enabled = true
	var start_x: float = (home as Room).player.position.x
	_touch(TouchControls.STICK_CENTER, true, 0)
	_drag(TouchControls.STICK_CENTER + Vector2(35, 0), 0)
	for i in 30:
		await get_tree().physics_frame
	_touch(TouchControls.STICK_CENTER + Vector2(35, 0), false, 0)
	_check((home as Room).player.position.x > start_x + 5, "il joystick touch dovrebbe muovere il personaggio")
	Ui.say(["Prova touch."])
	var guard_t := 0
	while Ui.busy and guard_t < 200:
		_touch(Vector2(300, 120), true, 1)
		_touch(Vector2(300, 120), false, 1)
		await get_tree().process_frame
		guard_t += 1
	_check(not Ui.busy, "un tocco sullo schermo dovrebbe far avanzare il dialogo")
	TouchControls.enabled = false
	for spot in get_tree().get_nodes_in_group("interactable"):
		if spot is Interactable and spot.position.y > 60:
			spot.call("interact")
			await _idle()
			break

	# --- strada: parlare con tutti, poi una battaglia in cui aiuti e una in cui sfrutti
	await _go(Router.STREET, "home")
	choose_index = 1
	for n in get_tree().get_nodes_in_group("npc"):
		n.call("interact")
		await _idle()
	_check("Caffè di Nico" in GameState.items, "Nico dovrebbe regalare un caffè")
	_check(GameState.npc_place("sig_bruno").get("anim") == "sit_left", "il signor Bruno dovrebbe stare seduto")
	# Parlare col signor Bruno seduto sulla panchina: deve rispondere lui, non la panchina.
	var st: Room = get_tree().current_scene
	st.player.position = st.cell_feet(Vector2i(11, 10))
	st.player.facing = "right"
	await get_tree().physics_frame
	var target: Node = st.player.call("_find_target")
	_check(target != null and target.get("id") == "sig_bruno", "parlando verso la panchina dovrebbe rispondere il signor Bruno")
	# Passare accanto al palo del lampione (colonna 18, riga 10) senza muri invisibili.
	st.player.position = st.cell_feet(Vector2i(19, 10)) + Vector2(4, 0)
	await get_tree().physics_frame
	var blocked: bool = st.player.test_move(st.player.global_transform, Vector2(0, -16))
	_check(not blocked, "accanto al lampione non dovrebbe esserci un muro invisibile")

	choose_index = 0
	GameState.met_today.clear()
	var minutes_before := GameState.minutes
	plan = [[1, 0], [1, 1], [3, 0]]
	_npc("sig_bruno").call("interact")
	await _wait_scene(Router.BATTLE)
	await _wait_scene(Router.STREET)
	await _idle()
	_check("sig_bruno" in GameState.helped_ids, "aiutare il signor Bruno (minigioco) dovrebbe funzionare")
	_check(GameState.money >= 10, "dopo il minigioco il signor Bruno dovrebbe darti 10 euro")
	_check(GameState.npc_place("sig_bruno").get("room") == "none", "dopo l'aiuto il signor Bruno dovrebbe tornare a casa")

	# Ivo: aiutarlo sblocca il Rifugio
	GameState.minutes = GameState.DAY_START
	plan = [[1, 0], [1, 1], [3, 0]]
	_npc("portiere_ivo").call("interact")
	await _wait_scene(Router.BATTLE)
	await _wait_scene(Router.STREET)
	await _idle()
	_check(GameState.flags.get("shelter_key", false), "aiutare Ivo dovrebbe dare la chiave del Rifugio")
	get_tree().current_scene.call("_blue_door")
	await _wait_scene(Router.SHELTER)
	await _idle()
	get_tree().current_scene.call("_bread")
	await _idle()
	_check(GameState.items.count("Panino") >= 1, "al Rifugio dovrebbe esserci il pane")
	await _go(Router.STREET, "shelter")
	_check(GameState.minutes >= minutes_before + 120, "ascoltare e aiutare dovrebbe costare 2 ore")

	# --- parco: persone nuove, aiuto diretto col minigioco, punto di salvataggio
	var park := await _go(Router.PARK, "street")
	GameState.quests["gatto_elsa"] = "declined"
	var money_before := GameState.money
	choose_index = 0
	_npc("elsa").call("interact")
	await _wait_scene(Router.MINIGAME)
	await _wait_scene(Router.PARK)
	await _idle()
	_check(GameState.money == money_before + 10, "aiutare Elsa dovrebbe dare 10 euro")
	park = get_tree().current_scene
	for spot in get_tree().get_nodes_in_group("interactable"):
		if spot is Interactable and spot.position.distance_to(park.cell_center(Vector2i(18, 16))) < 2:
			spot.call("interact")
			await _idle()
	var saved_minutes := GameState.minutes
	GameState.minutes += 120
	Router.continue_game()
	await _wait_scene(Router.PARK)
	await _idle()
	_check(GameState.minutes == saved_minutes, "Continua dovrebbe riportare all'ora del salvataggio")
	park = get_tree().current_scene
	_check(park.cell_center(Vector2i(18, 17)).distance_to((park as Room).player.position) < 20,
		"Continua dovrebbe riportare vicino al punto di salvataggio")
	await _go(Router.STREET, "park")

	plan = [[0, 0]]
	_npc("marta").call("interact")
	await _wait_scene(Router.BATTLE)
	await _wait_scene(Router.STREET)
	await _idle()
	_check(GameState.is_robot("marta"), "sfruttare Marta dovrebbe renderla un robot")
	_check(GameState.exploited == 1, "lo sfruttamento non è stato contato")

	# --- il Sottoufficio (-4): un turno al call center, poi la telefonata del capo (rifiutata)
	GameState.minutes = GameState.DAY_START
	GameState.worked_today = false
	var sotto: Room = await _go(Router.SOTTOUFFICIO, "from_below")
	choose_queue = [0, 1]
	plan = []
	fallback = [0, 0]
	sotto.call("_station", GameState.job("callcenter"))
	await _wait_scene(Router.WORK)
	await _wait_scene(Router.SOTTOUFFICIO)
	await _idle()
	await _idle()
	_check(GameState.hard_work == 1 and GameState.worked_today, "il turno al call center non è stato pagato")
	_check(GameState.flags.get("boss_call_done_%d" % GameState.day, false), "dopo il turno il capo dovrebbe telefonare")
	_check(GameState.flags.get("promotions_refused", 0) == 1, "rifiutare la promozione dovrebbe essere ricordato")
	GameState.flags["boss_call_day"] = GameState.day
	GameState.flags.erase("boss_call_done_%d" % GameState.day)
	_check(not GameState.boss_call_pending(), "il capo dovrebbe chiamare una volta sola per piano")
	GameState.flags["boss_call_done_%d" % GameState.day] = true

	# --- ascensore per la Direzione (serve il badge della Cima)
	GameState.badges.append("cima")
	var office := await _go(Router.OFFICE, "street")
	choose_queue = [0]
	office.call("_ride_elevator")
	await _wait_scene(Router.BOSS)
	await _idle()
	var ex_before := GameState.exploited
	choose_queue = [0]
	get_tree().current_scene.call("_talk")
	await _wait_scene(Router.WORK)
	await _wait_scene(Router.BOSS)
	await _idle()
	_check(GameState.exploited == ex_before + 1, "l'incarico extra del Capo dovrebbe contare come promozione")
	GameState.badges.clear()

	# --- la telefonata del capo il giorno dopo: firmare la promozione
	GameState.end_day(true)
	GameState.flags["met_marta"] = true
	var victim := GameState.promotion_victim()
	GameState.flags["boss_call_day"] = GameState.day
	GameState.flags.erase("boss_call_floor_" + GameState.floor_id)
	choose_queue = [0]
	await _go(Router.STREET, "home")
	await _wait_scene(Router.WORK)
	await _wait_scene(Router.STREET)
	await _idle()
	_check(victim != "" and GameState.is_robot(victim), "firmare la promozione dovrebbe colpire qualcuno che conosci (" + victim + ")")

	# --- tutti gli attacchi, giocati per intero
	immortal = true
	fast_dodge = false
	fallback = [1, 0]
	GameState.battle = {
		"kind": "work", "name": "Test", "sheet": "char_13", "goal": 99, "pay": 10,
		"acts": [{"name": "Prova", "trust": 0, "lines": ["* Prova."]}],
		"attacks": ["bills", "emails", "boxes", "cars", "pigeons", "crumbs", "toys", "books",
			"coffee", "notifications", "keys", "postits", "papers", "rain", "camera"],
		"return": Router.HOME, "spawn": "bed",
	}
	Router.goto(Router.BATTLE)
	await _wait_scene(Router.BATTLE)
	var battle := get_tree().current_scene
	var guard := 0
	while int(battle.get("turn")) < 16 and guard < 60000:
		await get_tree().process_frame
		guard += 1
	_check(int(battle.get("turn")) >= 16, "non tutti gli attacchi sono stati giocati")
	battle.call("_end_battle")
	await _wait_scene(Router.HOME)
	immortal = false
	fast_dodge = true
	fallback = [3, 1]

	# --- i giorni non sono contati: a mezzanotte comincia un altro giorno, e il debito cresce
	await _idle()
	var day_before := GameState.day
	var debt_night := GameState.debt
	GameState.minutes = GameState.MIDNIGHT - 5
	GameState.spend(10)
	_check(GameState.day == day_before + 1, "a mezzanotte dovrebbe cominciare un altro giorno")
	_check(GameState.minutes == GameState.DAY_START + 5, "il nuovo giorno dovrebbe ripartire dalle 7:00")
	_check(GameState.debt > debt_night, "ogni notte il debito dovrebbe crescere")
	GameState.pending_lines.clear()

	# --- missioni: trovare il gatto di Elsa e portare il pacco di Sami
	GameState.quests.clear()
	GameState.minutes = GameState.DAY_START
	GameState.robots.clear()
	GameState.helped_today.clear()
	GameState.met_today.clear()
	choose_queue = [0]
	var p2 := await _go(Router.PARK, "street")
	_npc("elsa").call("interact")
	await _idle()
	_check(Quests.state("gatto_elsa") == "active", "accettare la missione del gatto dovrebbe attivarla")
	var spot := Quests.find_spot(Quests.get_quest("gatto_elsa"))
	var room_path := "res://scenes/world/%s.tscn" % spot["room"]
	var rm: Node = await _go(room_path, "street")
	var picked := false
	for it in get_tree().get_nodes_in_group("interactable"):
		if it is Interactable and it.position.distance_to((rm as Room).cell_feet(Vector2i(int(spot["cell"][0]), int(spot["cell"][1]))) + Vector2(0, -6)) < 2:
			it.call("interact")
			picked = true
			break
	await _idle()
	_check(picked and Quests.state("gatto_elsa") == "found", "il gatto dovrebbe essere nascosto dove dice la missione")
	var money_q := GameState.money
	p2 = await _go(Router.PARK, "street")
	_npc("elsa").call("interact")
	await _idle()
	_check(Quests.state("gatto_elsa") == "done" and GameState.money == money_q + 15, "riportare il gatto dovrebbe chiudere la missione con 15 euro")
	_check("Economia è scappato" not in Quests.active_titles(), "la missione finita non dovrebbe restare nel menu")
	GameState.quests["pacco_sami"] = "active"
	_npc("rocco").call("interact")
	await _idle()
	_check(Quests.state("pacco_sami") == "found", "consegnare il pacco a Rocco dovrebbe funzionare")
	GameState.quests["esame_luca"] = "active"
	Quests.end_day()
	_check(Quests.state("esame_luca") == "failed" and GameState.flags.has("quest_news_esame_luca"), "una missione non finita dovrebbe fallire a fine giornata")
	await _go(Router.STREET, "park")

	# --- salvataggio
	GameState.save_game()
	_check(not GameState.load_game().is_empty(), "il salvataggio non si ricarica")

	# --- di sera le persone cambiano posto
	GameState.minutes = 19 * 60
	_check(GameState.npc_place("sig_bruno").get("room") == "park", "di sera il signor Bruno dovrebbe essere al parco")
	await _go(Router.PARK, "street")
	_check(_npc("sig_bruno") != null, "il signor Bruno dovrebbe essere nel parco la sera")
	GameState.minutes = GameState.DAY_START

	# --- debito pagato: dormendo si va al finale
	GameState.new_game()
	GameState.exploited = 2
	GameState.money = GameState.debt + 10000
	GameState.pay_debt(GameState.debt)
	home = await _go(Router.HOME, "bed")
	choose_queue = [0, 1]
	home.call("_sleep")
	await _wait_scene(Router.ENDING, 20000)
	await _wait_scene(Router.MENU, 60000)
	await _idle()
	_check(GameState.debt <= 0, "pagando tutto il debito dovrebbe arrivare a zero")

	# --- strada del baratto: chiedere il motivo, conquistare fiducia, liberare
	GameState.new_game()
	GameState.flags["street_intro"] = true
	GameState.quests["esame_luca"] = "declined"
	choose_queue = []
	choose_index = 0
	await _go(Router.STREET, "home")
	plan = [[1, 3], [1, 0], [1, 0], [1, 0], [3, 1]]
	fallback = [3, 2]
	_npc("marta").call("interact")
	await _wait_scene(Router.BATTLE)
	await _wait_scene(Router.STREET)
	await _idle()
	_check("marta" in GameState.motives_known, "chiedere a Marta perché lavora dovrebbe rivelare il motivo")
	_check(GameState.npc_state("marta") == "libero", "Marta dovrebbe essere libera dopo averla convinta")
	_check(GameState.npc_place("marta").get("room") == "park", "chi è libero dovrebbe stare fuori dal lavoro (al parco)")
	fallback = [3, 1]

	# --- LV: sale quando sfrutti
	var lv_before := GameState.lv()
	GameState.exploit("lea", 100)
	_check(GameState.lv() == lv_before + 1 and GameState.pending_level_up, "sfruttare dovrebbe alzare il LV")
	GameState.level_up_line()
	_check(GameState.own_hours() >= 0.0, "le ore tue non dovrebbero essere negative")

	# --- nessuna persona sovrapposta, in nessuna stanza, giorno, ora o stato
	for state in ["normale", "liberi", "aiutati"]:
		for day in [1, 2, 3, 4]:
			for minutes in [9 * 60, 19 * 60]:
				GameState.new_game()
				for f in ["street_intro", "park_intro", "shelter_intro", "office_intro"]:
					GameState.flags[f] = true
				GameState.day = day
				GameState.minutes = minutes
				GameState.refused = 1
				if state == "liberi":
					GameState.freed.assign(GameState.workers())
				elif state == "aiutati":
					GameState.helped_today.assign(GameState.npc_ids())
				for room in [Router.PARK, Router.STREET, Router.SHELTER, Router.OFFICE]:
					GameState.minutes = minutes
					await _go(room, "street")
					var ps := get_tree().get_nodes_in_group("npc")
					for i in ps.size():
						for j in range(i + 1, ps.size()):
							var dd: Vector2 = (ps[i] as Node2D).position - (ps[j] as Node2D).position
							if absf(dd.x) < 14 and absf(dd.y) < 24:
								_fail("%s e %s sovrapposti in %s (giorno %d, ore %d, %s)" % [ps[i].get("id"), ps[j].get("id"), room.get_file(), day, minutes / 60, state])

	# --- una nuova partita: l'ascensore scende e si rompe al piano -5
	GameState.new_game()
	choose_queue = []
	choose_index = 0
	Router.goto(Router.ELEVATOR)
	await _wait_scene(Router.FONDO, 40000)
	await _idle()
	var fondo: Room = get_tree().current_scene
	_check(GameState.floor_id == "-5", "la partita dovrebbe cominciare al piano -5")
	await get_tree().create_timer(1.5).timeout
	await _idle()
	choose_queue = [0, 0]
	fondo.call("_talk_fermo")
	var gf := 0
	while not GameState.flags.get("fermo_talked", false) and gf < 30000:
		await get_tree().process_frame
		gf += 1
	await get_tree().create_timer(2.5).timeout
	await _idle()
	await get_tree().physics_frame
	_check(GameState.flags.get("fermo_talked", false), "si dovrebbe poter parlare con Fermo")
	# il lavoro: la cyclette
	choose_queue = [0, 1]
	plan = []
	fallback = [0, 0]
	fondo.call("_station", GameState.job("dinamo"))
	await _wait_scene(Router.WORK)
	await _wait_scene(Router.FONDO)
	await _idle()
	await _idle()
	_check(GameState.worked_today and GameState.money >= 150, "pedalare alla dinamo dovrebbe pagare il turno")
	fondo = get_tree().current_scene
	# il distributore: senza soldi niente badge, con i soldi sì (e il debito scende)
	var cash := GameState.money
	GameState.money = 0
	choose_queue = [0]
	fondo.call("_badge_machine")
	await _idle()
	_check(not GameState.has_badge("-4"), "senza soldi il distributore non dovrebbe dare il badge")
	GameState.money = maxi(cash, GameState.badge_cost("-4"))
	choose_queue = [0]
	fondo.call("_badge_machine")
	await _idle()
	_check(GameState.has_badge("-4") and GameState.debt == GameState.START_DEBT - GameState.badge_cost("-4"), "il badge dovrebbe scalare dal debito")
	# tre giorni di seguito di turni falliti: Fermo offre i soldi, il Signor Rata il contratto
	var saved_money := GameState.money
	var saved_badges := GameState.badges.duplicate()
	var saved_debt := GameState.debt
	GameState.badges.clear()
	GameState.money = 0
	for k in 3:
		GameState.work_failed()
		GameState.day += 1
	GameState.day -= 1
	_check(GameState.pity_pending(), "dopo tre giorni di turni falliti qualcuno dovrebbe avere pena di te")
	choose_queue = [0]
	fondo.call("_pity_offer")
	await _idle()
	await get_tree().create_timer(0.3).timeout
	await _idle()
	_check(GameState.money == GameState.badge_cost("-4") and GameState.flags.get("pity_fermo", false), "accettando la pietà dovresti avere i soldi che mancano")
	GameState.money = 0
	for k in 3:
		GameState.day += 1
		GameState.work_failed()
	var debt_c := GameState.debt
	choose_queue = [1]
	fondo.call("_pity_offer")
	await _idle()
	await get_tree().create_timer(0.3).timeout
	await _idle()
	_check(GameState.has_badge("-4") and GameState.debt == debt_c + int(round(GameState.badge_cost("-4") * 1.5)), "il contratto del Signor Rata dovrebbe dare il badge e alzare il debito")
	_check(GameState.interest_rate() > GameState.DAILY_INTEREST, "dopo il contratto gli interessi dovrebbero salire")
	GameState.flags.erase("contracts")
	GameState.badges.assign(saved_badges)
	GameState.money = saved_money
	GameState.debt = saved_debt
	# la stellina fa passare la notte: il giorno dopo si può lavorare di nuovo
	var day_star := GameState.day
	choose_queue = [1]
	fondo.call("_save_here", Vector2i(12, 9))
	await get_tree().create_timer(0.5).timeout
	await _wait_scene(Router.FONDO)
	await _idle()
	_check(GameState.day == day_star + 1 and not GameState.worked_today, "la stellina dovrebbe far passare la notte (e ridare il turno)")
	fondo = get_tree().current_scene
	# le scale: con il badge si sale al -4
	fondo.player.position = Vector2(21 * 16 + 16, 16 + 6)
	await _wait_scene(Router.SOTTOUFFICIO)
	await _idle()
	_check(GameState.floor_id == "-4", "con il badge le scale dovrebbero portare al piano -4")
	# senza il badge del -3 il tornello respinge
	var s4: Room = get_tree().current_scene
	s4.player.position = s4.cell_feet(Vector2i(21, 3))
	for i in 10:
		await get_tree().physics_frame
	await _idle()
	_check(_scene_path() == Router.SOTTOUFFICIO, "senza badge il tornello non dovrebbe far passare")

	# --- chi aiuta tutti quelli del piano riceve il badge in regalo (e un'amica)
	GameState.new_game()
	GameState.flags["fermo_talked"] = true
	GameState.flags["fermo_called"] = true
	var esteem0 := GameState.self_esteem
	GameState.helped_ids.assign(GameState.floor_people("-5"))
	GameState.flags["c1_arrivo"] = true
	await _go(Router.FONDO, "elevator")
	await get_tree().create_timer(0.5).timeout
	await _idle()
	_check(not GameState.floor_people("-5").is_empty() and GameState.has_badge("-4"), "aiutando tutti al -5 dovresti ricevere il badge in regalo")
	_check(GameState.flags.get("clerk_friend", false) and GameState.self_esteem > esteem0, "l'addetta ai badge dovrebbe diventare tua amica e l'autostima salire")

	# --- capitolo 2: il giro del Modulo B-4, e come se ne esce (Ercole firma, Tilde fa la voce)
	GameState.new_game()
	GameState.flags["c2_arrivo"] = true
	GameState.money = 5000
	var c2: Room = await _go(Router.SOTTOUFFICIO, "from_below")
	choose_queue = [0]
	await c2.call("_badge_machine")
	_check(not GameState.has_badge("-3"), "senza B-4 timbrato lo sportello non dovrebbe vendere il badge")
	await c2.call("_agenda")
	_check(GameState.flags.get("c2_b4", false), "l'Agenda dovrebbe dare il B-4")
	choose_queue = [0]
	await c2.call("_agenda")
	_check(not GameState.flags.get("c2_modulo_ok", false), "il B-4 vuoto non dovrebbe essere timbrato")
	_check(not await c2.call("talk_ercole", null), "Ercole firma solo dopo che l'hai aiutato")
	GameState.helped_ids.append("ercole")
	_check(await c2.call("talk_ercole", null) and GameState.flags.get("c2_firma", false), "Ercole aiutato dovrebbe firmare il B-4")
	_check(await c2.call("talk_tilde", null) and not GameState.flags.get("c2_timbro", false), "Tilde prima chiede aiuto col copione")
	GameState.helped_ids.append("tilde")
	_check(await c2.call("talk_tilde", null) and GameState.flags.get("c2_timbro", false), "Tilde aiutata dovrebbe fare la voce del responsabile")
	choose_queue = [0]
	await c2.call("_agenda")
	_check(GameState.flags.get("c2_modulo_ok", false), "col timbro di Tilde l'Agenda dovrebbe timbrare il B-4")
	choose_queue = [0]
	await c2.call("_badge_machine")
	_check(GameState.has_badge("-3"), "col B-4 timbrato il badge del -3 si dovrebbe comprare")
	await c2.call("on_stairs_step", c2.player, "-3")
	_check(GameState.flags.get("c2_rivelazione", false), "sul primo gradino la musica si dovrebbe fermare")
	_check(c2.call("on_stairs_top", c2.player), "in cima alle scale dovrebbe partire lo sguardo indietro")
	await _wait_scene(Router.MERCATO, 60000)
	await _idle()
	_check(GameState.flags.get("c2_fine", false) and GameState.floor_id == "-3", "dopo lo sguardo indietro si dovrebbe arrivare al Mercato")
	# la procedura d'urgenza: paghi e il B-4 è timbrato subito
	GameState.new_game()
	GameState.flags["c2_arrivo"] = true
	GameState.flags["c2_b4"] = true
	GameState.money = 1000
	c2 = await _go(Router.SOTTOUFFICIO, "from_below")
	choose_queue = [1]
	await c2.call("_agenda")
	_check(GameState.flags.get("c2_pagato", false) and GameState.flags.get("c2_modulo_ok", false) and GameState.money == 700, "la procedura d'urgenza dovrebbe costare 300 e timbrare il B-4")

	# --- capitolo 3: il Mercato (test 9-35 di docs/capitoli/capitolo_3_il_mercato.md)
	await _test_chapter3()

	# --- capitolo 4: la Banca (test di docs/CHAPTER_04_BANK.md)
	await _test_chapter4()
	# --- capitolo 5: la Città
	await _test_chapter5()

	# --- in cima c'è tuo padre
	GameState.day = 4
	var pres: Room = await _go(Router.PRESIDENCY, "stairs")
	choose_queue = [1]
	pres.call("_talk")
	await _wait_scene(Router.ENDING, 40000)
	await _wait_scene(Router.MENU, 60000)
	await _idle()
	_check(GameState.flags.get("father_met", false) and GameState.flags.get("sat_with_president", false), "in cima dovresti incontrare tuo padre")

	# --- i finali: capitalismo, comunismo e le tre varianti del baratto
	var cases := [
		["capitalismo", 3, [], ""],
		["comunismo", 0, [], ""],
		["baratto", 0, ["marta"], "pochi"],
		["baratto", 0, GameState.workers().slice(0, ceili(GameState.workers().size() * 0.6)), "soglia"],
		["baratto", 0, GameState.workers().slice(0, ceili(GameState.workers().size() * 0.9)), "quasi_tutti"],
	]
	for c: Array in cases:
		GameState.new_game()
		GameState.exploited = int(c[1])
		if c[0] == "capitalismo":
			GameState.money = 90000
			GameState.debt = 0
		GameState.freed.assign(c[2])
		_check(GameState.route() == c[0], "route() dovrebbe dare " + str(c[0]))
		if c[3] != "":
			_check(GameState.barter_level() == c[3], "la massa critica dovrebbe essere " + str(c[3]))
		Router.goto(Router.ENDING)
		await _wait_scene(Router.MENU, 60000)
		await _idle()

	if _failures.is_empty():
		print("SMOKE TEST OK")
	else:
		print("SMOKE TEST FALLITO:\n- " + "\n- ".join(_failures))
	get_tree().quit(0 if _failures.is_empty() else 1)
