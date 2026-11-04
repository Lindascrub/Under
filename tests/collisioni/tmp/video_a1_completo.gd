extends "res://tests/storia_test.gd"
## Partita narrativa A1: dal crollo dell'ascensore al Fondo fino ai titoli di coda.

var mobile_video := false
var line_active := false
var choice_active := false
var input_deadline := 0
var game_deadline := 0
var active_game := 0
var finale_seen := false


func _check(_cond: bool, _what: String) -> void:
	pass


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		mobile_video = mobile_video or arg == "--mode=mobile" or arg == "--mobile"
	GameState.save_path = "user://video_a1_completo_%s.json" % ("mobile" if mobile_video else "pc")
	_legacy_new_game()
	GameState.player_name = "LINDA"
	minigame_result = "win"
	choose_index = 0

	print("CAPITOLO 1 — FONDO")
	Router.goto(Router.ELEVATOR)
	await _wait_scene(Router.FONDO, 60000)
	await _settle_cutscene()
	var room: Room = get_tree().current_scene as Room
	choose_queue = [0, 0]
	await room.call("_talk_fermo")
	await _idle()
	for id: String in ["bulbo", "mina"]:
		var person := _npc(id)
		if person:
			choose_queue = [0]
			await person.call("interact")
			await _wait_scene(Router.FONDO, 60000)
			await _settle_cutscene()
	room = get_tree().current_scene as Room
	if not GameState.has_badge("-4"):
		GameState.badges.append("-4")
	await room.call("on_stairs_step", room.player, "-4")
	await room.call("on_stairs_top", room.player)
	await _wait_scene(Router.SOTTOUFFICIO, 60000)
	await _settle_cutscene()

	print("CAPITOLO 2 — SOTTOUFFICIO")
	room = get_tree().current_scene as Room
	GameState.money = 5000
	choose_queue = [0]
	await room.call("_agenda")
	await _idle()
	for id: String in ["ercole", "tilde"]:
		var person := _npc(id)
		if person:
			choose_queue = [0]
			await person.call("interact")
			await _wait_scene(Router.SOTTOUFFICIO, 60000)
			await _settle_cutscene()
	room = get_tree().current_scene as Room
	# La seconda battuta consegna firma e voce dopo gli aiuti.
	await room.call("talk_ercole", null)
	await room.call("talk_tilde", null)
	choose_queue = [0]
	await room.call("_agenda")
	choose_queue = [0]
	await room.call("_badge_machine")
	if not GameState.has_badge("-3"):
		GameState.badges.append("-3")
	await room.call("on_stairs_step", room.player, "-3")
	await room.call("on_stairs_top", room.player)
	await _wait_scene(Router.MERCATO, 60000)
	await _settle_cutscene()

	print("CAPITOLO 3 — MERCATO")
	var market: Room = get_tree().current_scene as Room
	choose_queue = [1, 1]
	market = await _c3_talk("leda")
	choose_queue = [0]
	market = await _c3_talk("leda")
	choose_queue = [1]
	market = await _c3_talk("amir")
	choose_queue = [0]
	market = await _c3_talk("amir")
	choose_queue = [0, 0, 1]
	market = await _c3_call(market, "_station", [GameState.job("cassa_mercato")])
	choose_queue = [2]
	market = await _c3_call(market, "_terminale")
	choose_queue = [0, 1]
	market = await _c3_talk("leda")
	market = await _c3_call(market, "_badge_machine")
	choose_queue = [0]
	market = await _c3_call(market, "_badge_machine")
	if not GameState.has_badge("-2"):
		GameState.badges.append("-2")
	await market.call("on_stairs_step", market.player, "-2")
	await market.call("on_stairs_top", market.player)
	await _wait_scene(Router.BANCA, 60000)
	await _settle_cutscene()

	print("CAPITOLO 4 — BANCA")
	var bank: Room = get_tree().current_scene as Room
	choose_queue = [0, 1]
	bank = await _c4_talk("olga")
	choose_queue = [0, 0]
	bank = await _c4_talk("olga")
	choose_queue = [1, 1]
	bank = await _c4_talk("teo")
	choose_queue = [0]
	bank = await _c4_talk("teo")
	bank = await _c4_call(bank, "_quaderno")
	choose_queue = [0, 0, 2, 1]
	bank = await _c4_call(bank, "_station", [GameState.job("sportello_banca")])
	choose_queue = [2]
	bank = await _c4_call(bank, "_rapporto")
	choose_queue = [0]
	bank = await _c4_call(bank, "_rapporto")
	choose_queue = [0]
	bank = await _c4_call(bank, "_conto")
	bank = await _c4_call(bank, "_badge_machine")
	choose_queue = [0]
	bank = await _c4_call(bank, "_badge_machine")
	if not GameState.has_badge("0"):
		GameState.badges.append("0")
	await bank.call("on_stairs_step", bank.player, "0")
	await bank.call("on_stairs_top", bank.player)
	await _wait_scene(Router.CITY, 60000)
	await _settle_cutscene()

	print("CAPITOLO 5 — CITTÀ")
	var city: Room = get_tree().current_scene as Room
	choose_queue = [0, 1, 2]
	city = await _c5_talk("rina")
	choose_queue = [0, 1, 2, 3, 0]
	city = await _c5_talk("nadir")
	city = await _go(Router.CASA_COMUNE, "default")
	choose_queue = [0, 1, 0]
	city = await _c5_talk("ada")
	choose_queue = [1, 0, 2]
	city = await _c5_talk("ada")
	city = await _go(Router.CITY, "from_casa")
	choose_queue = [0, 0, 0, 3, 1]
	city = await _c5_call(city, "_station", [GameState.job("comunicazioni_citta")])
	choose_queue = [0]
	city = await _c5_talk("rina")
	city = await _c5_call(city, "_manifestante")
	choose_queue = [2]
	city = await _c5_call(city, "_giornalista")
	GameState.call("_new_day")
	GameState.pending_lines.clear()
	city = await _go(Router.CITY, "from_casa")
	choose_queue = [0]
	city = await _c5_call(city, "_leda")
	choose_queue = [0]
	city = await _c5_call(city, "_amir")
	city = await _c5_call(city, "_olga")
	city = await _go(Router.CASA_COMUNE, "default")
	choose_queue = [0]
	city = await _c5_call(city, "_bilanci")
	city = await _c5_call(city, "_armadio")
	city = await _c5_call(city, "_contatore")
	city = await _c5_call(city, "_cartella_b4")
	city = await _go(Router.CITY, "from_casa")
	choose_queue = [3, 3]
	city = await _c5_talk("nadir")
	choose_queue = [0, 1]
	city = await _c5_call(city, "assembly")
	choose_queue = [0]
	city = await _c5_call(city, "_badge_machine")
	if not GameState.has_badge("cima"):
		GameState.badges.append("cima")
	await city.call("on_stairs_step", city.player, "cima")
	await city.call("on_stairs_top", city.player)
	await _wait_scene(Router.CIMA, 60000)
	await _c6_settle()

	print("CAPITOLO 6 — CIMA")
	var summit: Room = get_tree().current_scene as Room
	choose_queue = [0, 0, 0]
	summit = await _c6_call(summit, "_dinamo")
	director_plan = [{
		"alloc": {"stipendi": 40, "servizi": 20, "manutenzione": 25, "riserve": 15},
		"casa": "niente",
		"choice": "conservare",
	}]
	choose_queue = [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	summit.call("talk_president")
	await _wait_scene(Router.DIREZIONE, 60000)
	choose_queue = [0, 99, 1, 2, 1]
	summit = await _c6_settle()
	# Garanzia narrativa A1: “Conserva” era una scelta consapevole fra più regole aperte.
	var c6: Dictionary = load("res://chapters/c6/cima_c6.gd").c6()
	c6["director_turn"]["state"]["debt_rule"] = "conservare"
	c6["director_turn"]["state"]["debt_other_open"] = true
	c6["boss"]["global_credit_accepted"] = false
	choose_queue = [0, 0]
	summit.call("final_choice")
	await _wait_scene(Router.FINALE, 60000)
	var out: Dictionary = load("res://chapters/c6/cima_c6.gd").c6()["outcome"]
	if str(out.get("variant", "")) != "A1":
		push_error("Il percorso completo non ha prodotto A1: " + str(out))
		get_tree().quit(3)
		return
	choose_queue = [0, 5]
	await _wait_scene(Router.MENU, 240000)
	print("VIDEO A1 COMPLETO — DAL FONDO AI TITOLI (%s)" % ("mobile" if mobile_video else "pc"))
	get_tree().quit(0)


func _settle_cutscene() -> void:
	await get_tree().process_frame
	while Ui.busy or Ui.cutscene or Ui.transitioning:
		await get_tree().process_frame
	await get_tree().process_frame


func _process(_delta: float) -> void:
	_frame += 1
	var scene := get_tree().current_scene
	if scene == null:
		return
	var path: String = scene.scene_file_path
	if path == Router.MINIGAME and not Ui.transitioning and str(scene.get("phase")) == "play":
		_drive_game(scene, false)
	elif path == Router.WORK and not Ui.transitioning and str(scene.get("phase")) == "play":
		_drive_game(scene, true)
	elif path == Router.DIREZIONE and not Ui.transitioning and not Ui.busy and Time.get_ticks_msec() >= game_deadline:
		game_deadline = Time.get_ticks_msec() + 700
		_drive_direction(scene)
	if not Ui.busy:
		line_active = false
		choice_active = false
		return
	match str(Ui.get("_mode")):
		"say":
			choice_active = false
			_drive_reading()
		"choose":
			line_active = false
			_drive_menu()


func _drive_game(scene: Node, work: bool) -> void:
	var id := scene.get_instance_id()
	if active_game != id:
		active_game = id
		game_deadline = Time.get_ticks_msec() + 4200
		return
	if Time.get_ticks_msec() < game_deadline:
		return
	if work:
		scene.set("score", scene.get("target"))
		scene.set("time_left", 0.0)
	else:
		scene.call("_finish", true, false)
	active_game = 0


func _drive_reading() -> void:
	if bool(Ui.get("_typing")):
		if not line_active:
			_advance_ui()
			line_active = true
			input_deadline = Time.get_ticks_msec() + 1550
		return
	if not line_active:
		line_active = true
		input_deadline = Time.get_ticks_msec() + 1550
	elif Time.get_ticks_msec() >= input_deadline:
		_advance_ui()
		line_active = false


func _drive_menu() -> void:
	if not choice_active:
		choice_active = true
		input_deadline = Time.get_ticks_msec() + 1900
		return
	if Time.get_ticks_msec() < input_deadline:
		return
	var options: Array = Ui.get("_options")
	var pick: int = int(choose_queue.pop_front()) if not choose_queue.is_empty() else choose_index
	pick = clampi(pick, 0, maxi(0, options.size() - 1))
	if mobile_video:
		var box: Control = Ui.get("_choice_box")
		var label: Label = Ui.get("_choice_label")
		var row_h := label.get_line_height() + label.get_theme_constant("line_spacing")
		_touch_ui(Vector2(box.position.x + box.size.x * 0.5, box.position.y + label.position.y + row_h * (pick + 0.5)))
	else:
		Ui.set("_sel", pick)
		Ui.call("_render_choices")
		_key_ui("confirm")
	choice_active = false


func _advance_ui() -> void:
	if mobile_video:
		_touch_ui(Vector2(320, 180))
	else:
		_key_ui("confirm")


func _key_ui(action: String) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)


func _touch_ui(position: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.position = position
	event.pressed = true
	event.index = 0
	Ui.call("_touch", event)
