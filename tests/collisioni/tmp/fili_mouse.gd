extends Node
const NPC := preload("res://scripts/npc.gd")
var cur: Node
func _process(_d: float) -> void:
	if Ui.busy and Engine.get_process_frames() % 4 == 0:
		var e := InputEventAction.new(); e.action = "confirm"; e.pressed = true; Input.parse_input_event(e)
		var u := InputEventAction.new(); u.action = "confirm"; u.pressed = false; Input.parse_input_event(u)
func _mouse(pos: Vector2, pressed: bool) -> void:
	var b := InputEventMouseButton.new(); b.button_index = MOUSE_BUTTON_LEFT; b.pressed = pressed; b.position = pos
	cur._unhandled_input(b) if cur.has_method("_unhandled_input") else cur._input(b)
func _move(pos: Vector2) -> void:
	var m := InputEventMouseMotion.new(); m.position = pos; m.button_mask = MOUSE_BUTTON_MASK_LEFT
	cur._unhandled_input(m) if cur.has_method("_unhandled_input") else cur._input(m)
func _ready() -> void:
	TouchControls.enabled = false
	GameState.save_path = "user://test_fili.json"
	GameState.new_game()
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/npcs.json"))
	GameState.minigame = NPC.minigame_cfg("bulbo", str(d["bulbo"]["name"]), d["bulbo"]["help"], Router.FONDO, Vector2.ZERO)
	await get_tree().process_frame
	cur = load(Router.MINIGAME).instantiate(); get_tree().root.add_child(cur); get_tree().current_scene = cur
	var n := 0
	while (str(cur.get("phase")) != "play" or Ui.busy) and n < 3000:
		await get_tree().process_frame; n += 1
	print("info: ", (cur.get("_info") as Label).text if cur.get("_info") else "?", " fase ", cur.get("phase"))
	var box: Rect2 = cur.BOX
	var y0 := box.position.y + 26
	var gap := (box.size.y - 52) / 3.0
	var right: Array = cur.get("wire_right")
	# filo 0 (sinistra) va al posto di destra dove wire_right[k] == 0
	var k := right.find(0)
	_mouse(Vector2(box.position.x + 20, y0), true)
	_move(Vector2(box.get_center().x, y0 + gap * k * 0.5))
	_move(Vector2(box.end.x - 20, y0 + gap * k))
	_mouse(Vector2(box.end.x - 20, y0 + gap * k), false)
	await get_tree().process_frame
	print("collegati: ", cur.get("wire_done"), " errori: ", cur.get("misses"))
	get_tree().quit(0)
