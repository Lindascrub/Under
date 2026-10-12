extends Node
## Test automatico: gioca da solo tutte le scene e i tre finali, premendo Z al posto tuo.
## Esegui:  Godot --headless --path . res://tests/smoke_test.tscn
## Alla fine stampa "SMOKE TEST OK" oppure gli errori trovati.

var _frame := 0
var _failures: Array[String] = []


func _ready() -> void:
	# Questo nodo deve sopravvivere ai cambi di scena.
	var placeholder := Node.new()
	get_tree().root.add_child.call_deferred(placeholder)
	await get_tree().process_frame
	get_tree().current_scene = placeholder
	await _run()


func _process(_delta: float) -> void:
	_frame += 1
	if Ui.busy and _frame % 3 == 0:
		_tap("confirm")


func _tap(action: String) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)


func _idle(max_frames := 6000) -> void:
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
	await get_tree().process_frame
	await _idle()
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path != path:
		_fail("la scena attesa era %s" % path)
	return scene


func _scene_path() -> String:
	var scene := get_tree().current_scene
	return scene.scene_file_path if scene else ""


func _check(cond: bool, what: String) -> void:
	if not cond:
		_fail(what)


func _fail(what: String) -> void:
	_failures.append(what)
	push_error("TEST: " + what)


func _run() -> void:
	# Menu
	await _go(Router.MENU)

	# Giorno 1: casa, strada, ufficio, lavoro facile
	GameState.new_game()
	var home := await _go(Router.HOME, "bed")
	home.call("_computer")
	await _idle()
	home.call("_robot_toy")
	await _idle()

	var street := await _go(Router.STREET, "home")
	for n in get_tree().get_nodes_in_group("npc"):
		n.call("interact")
		await _idle()
		n.call("interact")
		await _idle()
	_check(GameState.helped > 0, "aiutare qualcuno col tempo libero dovrebbe funzionare")

	var office := await _go(Router.OFFICE, "street")
	office.call("_terminal")
	await _idle()
	_check(GameState.exploited == 1, "il lavoro facile non è stato registrato")
	_check(GameState.is_robot("marta"), "Marta dovrebbe essere diventata un robot")
	_check(GameState.rank == 1, "dopo la firma dovresti essere promosso")

	# Le persone-robot parlano come robot
	await _go(Router.STREET, "office")
	for n in get_tree().get_nodes_in_group("npc"):
		if n.get("id") == "marta":
			n.call("interact")
			await _idle()

	# Minigiochi
	for path in [Router.WAREHOUSE, Router.DELIVERY]:
		var mg := await _go(path)
		var waited := 0
		while not mg.get("started") and waited < 2000:
			await get_tree().process_frame
			waited += 1
		mg.set("time_left", 0.05)
		var guard := 0
		while get_tree().current_scene == mg and guard < 6000:
			await get_tree().process_frame
			guard += 1
		await _idle()
		_check(_scene_path() == Router.OFFICE, "dopo il minigioco si torna in ufficio")
	_check(GameState.hard_work == 2, "i turni duri non sono stati pagati")

	# Dormire
	home = await _go(Router.HOME, "bed")
	var day_before := GameState.day
	home.call("_sleep")
	await _idle()
	await _idle()
	_check(GameState.day == day_before + 1, "dormire dovrebbe far passare il giorno")

	# Salvataggio
	GameState.save_game()
	_check(GameState.load_game(), "il salvataggio non si ricarica")

	# I tre finali
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
		var guard := 0
		while _scene_path() != Router.ENDING and guard < 2000:
			await get_tree().process_frame
			guard += 1
		_check(_scene_path() == Router.ENDING, "il finale %s non si è aperto" % route)
		guard = 0
		while _scene_path() != Router.MENU and guard < 20000:
			await get_tree().process_frame
			guard += 1
		await _idle()
		_check(_scene_path() == Router.MENU, "il finale %s dovrebbe tornare al menu" % route)

	if _failures.is_empty():
		print("SMOKE TEST OK")
	else:
		print("SMOKE TEST FALLITO:\n- " + "\n- ".join(_failures))
	get_tree().quit(0 if _failures.is_empty() else 1)
