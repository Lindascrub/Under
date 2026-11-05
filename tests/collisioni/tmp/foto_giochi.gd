extends Node
const NPC := preload("res://scripts/npc.gd")
const B := preload("res://scripts/boss_missions.gd")
var cur: Node
func _process(_d: float) -> void:
	if Ui.busy and Engine.get_process_frames() % 4 == 0:
		var e := InputEventAction.new(); e.action = "confirm"; e.pressed = true; Input.parse_input_event(e)
		var u := InputEventAction.new(); u.action = "confirm"; u.pressed = false; Input.parse_input_event(u)
func _open(path: String) -> void:
	if is_instance_valid(cur): cur.queue_free()
	await get_tree().process_frame
	cur = load(path).instantiate()
	get_tree().root.add_child(cur); get_tree().current_scene = cur
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tests/collisioni/tmp/foto_giochi/%s.png" % name)
	print("foto ", name)
func _ready() -> void:
	GameState.save_path = "user://test_foto_giochi.json"
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/npcs.json"))
	for id in ["olga", "teo", "ada", "amir"]:
		GameState.new_game()
		GameState.minigame = NPC.minigame_cfg(id, str(d[id]["name"]), d[id]["help"], Router.BANCA, Vector2.ZERO)
		await _open(Router.MINIGAME)
		var n := 0
		while (str(cur.get("phase")) != "play" or Ui.busy) and n < 3000:
			await get_tree().process_frame; n += 1
		for i in 90: await get_tree().process_frame
		await _shot(id)
		if id == "olga":
			cur.set("time_left", 999.0)
	for floor in ["-5", "-4", "-3", "-2", "0"]:
		GameState.new_game(); GameState.floor_id = floor
		GameState.minigame = {"boss_floor": floor}
		await _open(B.SCENE)
		for i in 60: await get_tree().process_frame
		await _shot("capo_" + floor.replace("-", "m"))
	get_tree().quit(0)
