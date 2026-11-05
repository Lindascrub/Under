extends Node
const NPC := preload("res://scripts/npc.gd")
var cur: Node
var foto_rossa := false
func _process(_d: float) -> void:
	if Ui.busy and Engine.get_process_frames() % 4 == 0:
		var e := InputEventAction.new(); e.action = "confirm"; e.pressed = true; Input.parse_input_event(e)
		var u := InputEventAction.new(); u.action = "confirm"; u.pressed = false; Input.parse_input_event(u)
	if is_instance_valid(cur) and not foto_rossa and str(cur.get("phase")) == "show":
		var sh := int(cur.get("shown")); var rs: Array = cur.get("seq_rosse")
		if sh >= 1 and sh <= rs.size() and rs[sh - 1] and float(cur.get("show_t")) > float(cur.get("show_len")) * 0.5:
			foto_rossa = true; _shot("tilde_rossa")
func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tests/collisioni/tmp/foto_giochi/%s.png" % n)
func _premi(a: String) -> void:
	var e := InputEventAction.new(); e.action = "move_" + a; e.pressed = true; Input.parse_input_event(e)
	await get_tree().process_frame
	var u := InputEventAction.new(); u.action = "move_" + a; u.pressed = false; Input.parse_input_event(u)
	for i in 3: await get_tree().process_frame
func _apri() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/npcs.json"))
	GameState.minigame = NPC.minigame_cfg("tilde", "Tilde", d["tilde"]["help"], Router.SOTTOUFFICIO, Vector2.ZERO)
	if is_instance_valid(get_tree().current_scene) and get_tree().current_scene != self: get_tree().current_scene.queue_free()
	await get_tree().process_frame
	cur = load(Router.MINIGAME).instantiate(); get_tree().root.add_child(cur); get_tree().current_scene = cur
func _aspetta_play() -> void:
	var n := 0
	while is_instance_valid(cur) and (str(cur.get("phase")) != "play" or Ui.busy) and n < 4000:
		await get_tree().process_frame; n += 1
func _ready() -> void:
	GameState.save_path = "user://test_tilde.json"
	GameState.new_game()
	# 1. tutto giusto, saltando le rosse
	await _apri()
	for giro in 2:
		await _aspetta_play()
		var rs: Array = cur.get("seq_rosse")
		print("giro ", giro + 1, ": ", cur.get("seq"), " rosse ", rs)
		var dire: Array = cur.call("_da_dire")
		for i in dire.size():
			await _premi(dire[i])
			if giro == 1 and i == 1: await _shot("tilde_ripeti")
	var n := 0
	while is_instance_valid(cur) and cur.is_inside_tree() and n < 3000:
		await get_tree().process_frame; n += 1
	print("giusto: stelle=", GameState.flags.get("stelle_tilde", 0), " (atteso 3)")
	# 2. ripete la rossa: errore
	await _apri()
	await _aspetta_play()
	cur.set("seq", ["up", "down", "left", "right"] as Array[String])
	var rs2: Array[bool] = [false, true, false, false]
	cur.set("seq_rosse", rs2); cur.set("typed", [] as Array[String])
	var seq: Array = cur.get("seq")
	var at := 1
	var prima := int(cur.get("misses"))
	for i in at + 1:
		await _premi(seq[i])
		if int(cur.get("misses")) > prima: break
	print("ripete la rossa: errori ", prima, " -> ", cur.get("misses"), " (atteso +1, a meno che la rossa sia uguale alla freccia dopo)")
	get_tree().quit(0)
