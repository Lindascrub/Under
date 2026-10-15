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


func _ready() -> void:
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
		scene.call("_finish", true)
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

	# --- ufficio: turno duro (battaglia di lavoro)
	GameState.minutes = GameState.DAY_START
	var office := await _go(Router.OFFICE, "street")
	choose_queue = [1, 0]
	plan = []
	fallback = [0, 0]
	office.call("_terminal")
	await _wait_scene(Router.BATTLE)
	await _wait_scene(Router.OFFICE)
	await _idle()
	_check(GameState.hard_work == 1 and GameState.worked_today, "il turno duro non è stato pagato")

	# --- ascensore per l'ufficio del Capo (serve il grado di Supervisore)
	GameState.rank = 2
	office = await _go(Router.OFFICE, "street")
	office.call("_ride_elevator")
	await _wait_scene(Router.BOSS)
	await _idle()
	var ex_before := GameState.exploited
	choose_queue = [0]
	get_tree().current_scene.call("_talk")
	await _idle()
	_check(GameState.exploited == ex_before + 1, "l'incarico extra del Capo dovrebbe contare come promozione")
	GameState.rank = 1

	# --- ufficio: firma (lavoro facile) il giorno dopo
	GameState.end_day(true)
	choose_queue = [0, 0]
	office = await _go(Router.OFFICE, "street")
	office.call("_terminal")
	await _wait_scene(Router.BATTLE)
	await _wait_scene(Router.OFFICE)
	await _idle()
	_check(GameState.is_robot("sig_bruno"), "la firma del giorno 2 dovrebbe colpire il signor Bruno")

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

	# --- mezzanotte: si torna a casa e si dorme per forza
	await _idle()
	var day_before := GameState.day
	GameState.minutes = GameState.MIDNIGHT - 5
	Router.goto(Router.STREET, "home")
	await _wait_scene(Router.HOME)
	await _idle()
	await _idle()
	await _wait_scene(Router.HOME)
	await _idle()
	_check(GameState.day == day_before + 1, "a mezzanotte dovrebbe finire la giornata")
	_check(GameState.minutes == GameState.DAY_START, "il nuovo giorno dovrebbe iniziare alle 7:00")

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
	GameState.money = 10000
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
	plan = [[1, 3], [1, 0], [3, 1]]
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

	# --- i finali: capitalismo, comunismo e le tre varianti del baratto
	var cases := [
		["capitalismo", 3, [], ""],
		["comunismo", 0, [], ""],
		["baratto", 0, ["marta"], "pochi"],
		["baratto", 0, ["marta", "lea", "dario"], "soglia"],
		["baratto", 0, ["marta", "lea", "dario", "giulia", "ragazzo_sami"], "quasi_tutti"],
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
