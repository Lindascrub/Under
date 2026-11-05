extends Node
## Lampadina che sfarfalla: avvitala (su/giù) e mettila nelle BUONE (destra). Tasti e dito (temporaneo).
const NPC := preload("res://scripts/npc.gd")
var cur: Node

func _process(_d: float) -> void:
	if Ui.busy and Engine.get_process_frames() % 4 == 0:
		var e := InputEventAction.new(); e.action = "confirm"; e.pressed = true; Input.parse_input_event(e)
		var u := InputEventAction.new(); u.action = "confirm"; u.pressed = false; Input.parse_input_event(u)

func _premi(a: String) -> void:
	var e := InputEventAction.new(); e.action = a; e.pressed = true; Input.parse_input_event(e)
	await get_tree().process_frame
	var u := InputEventAction.new(); u.action = a; u.pressed = false; Input.parse_input_event(u)
	for i in 3: await get_tree().process_frame

func _scorri(da: Vector2, a: Vector2) -> void:
	var t := InputEventScreenTouch.new(); t.position = da; t.pressed = true; Input.parse_input_event(t)
	await get_tree().process_frame
	var d := InputEventScreenDrag.new(); d.position = a; d.relative = a - da; Input.parse_input_event(d)
	await get_tree().process_frame
	var r := InputEventScreenTouch.new(); r.position = a; r.pressed = false; Input.parse_input_event(r)
	for i in 3: await get_tree().process_frame

func _ready() -> void:
	var tocco := "--touch" in OS.get_cmdline_user_args()
	TouchControls.enabled = tocco
	GameState.save_path = "user://test_avvitate.json"
	GameState.new_game()
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/npcs.json"))
	GameState.minigame = NPC.minigame_cfg("mina", str(d["mina"]["name"]), d["mina"]["help"], Router.FONDO, Vector2.ZERO)
	await get_tree().process_frame
	cur = load(Router.MINIGAME).instantiate(); get_tree().root.add_child(cur); get_tree().current_scene = cur
	var n := 0
	while (str(cur.get("phase")) != "play" or Ui.busy) and n < 3000:
		await get_tree().process_frame; n += 1
	for k in 3:
		cur.set("bulb", "fioca"); cur.set("bulb_fix", 0); cur.set("bulb_fixed", false); cur.set("bulb_t", 0.0)
		var prima := int(cur.get("bulb_done")); var err := int(cur.get("misses"))
		if tocco:
			await _scorri(Vector2(320, 200), Vector2(320, 140))
			await _scorri(Vector2(320, 200), Vector2(320, 260)); await _scorri(Vector2(320, 200), Vector2(320, 140))
			print("dopo avvitata: ", cur.get("bulb"), " fixed=", cur.get("bulb_fixed"))
			await _scorri(Vector2(300, 180), Vector2(400, 180))
		else:
			await _premi("move_up"); await _premi("move_up"); await _premi("move_down")
			print("dopo avvitata: ", cur.get("bulb"), " fixed=", cur.get("bulb_fixed"))
			await _premi("move_right")
		print("giro ", k, ": smistate ", prima, " -> ", cur.get("bulb_done"), "  errori ", err, " -> ", cur.get("misses"))
	get_tree().quit(0)
