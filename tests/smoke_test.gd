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
	_check(GameState.npc_place("sig_bruno").get("anim") == "sit_right", "il signor Bruno dovrebbe stare seduto")

	choose_index = 0
	GameState.met_today.clear()
	var minutes_before := GameState.minutes
	plan = [[1, 0], [1, 1], [3, 0]]
	_npc("sig_bruno").call("interact")
	await _wait_scene(Router.BATTLE)
	await _wait_scene(Router.STREET)
	await _idle()
	_check("sig_bruno" in GameState.helped_ids, "aiutare il signor Bruno nella battaglia dovrebbe funzionare")
	_check(GameState.minutes >= minutes_before + 180, "ascoltare e aiutare dovrebbe costare 3 ore")

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

	# --- salvataggio
	GameState.save_game()
	_check(GameState.load_game(), "il salvataggio non si ricarica")

	# --- i tre finali
	for route in ["ricco", "onesto", "ribelle"]:
		GameState.new_game()
		match route:
			"ricco":
				GameState.exploited = 5
				GameState.money = 90000
				GameState.debt = 0
			"ribelle":
				GameState.refused = 4
				GameState.helped = 5
				GameState.helped_ids.assign(["marta", "lea"])
			"onesto":
				GameState.helped_ids.assign(["sig_bruno", "dario"])
		_check(GameState.route() == route, "route() dovrebbe dare " + route)
		Router.goto(Router.ENDING)
		await _wait_scene(Router.MENU, 60000)
		await _idle()

	if _failures.is_empty():
		print("SMOKE TEST OK")
	else:
		print("SMOKE TEST FALLITO:\n- " + "\n- ".join(_failures))
	get_tree().quit(0 if _failures.is_empty() else 1)
