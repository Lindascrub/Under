extends Node
const B := preload("res://scripts/boss_missions.gd")
func _process(_d: float) -> void:
	if Ui.busy and Engine.get_process_frames() % 4 == 0:
		var e := InputEventAction.new(); e.action = "confirm"; e.pressed = true; Input.parse_input_event(e)
		var u := InputEventAction.new(); u.action = "confirm"; u.pressed = false; Input.parse_input_event(u)
func _ready() -> void:
	GameState.save_path = "user://test_capo5b.json"
	var arg := OS.get_cmdline_user_args()
	var t := int(arg[0]) if arg.size() > 0 else 0
	GameState.new_game()
	B.state("-5")["status"] = "active"
	var soldi := GameState.money
	GameState.minigame = {"boss_floor": "-5"}
	await get_tree().process_frame
	var cur: Node = load(B.SCENE).instantiate(); get_tree().root.add_child(cur); get_tree().current_scene = cur
	for i in 10: await get_tree().process_frame
	cur.dinamo.call("_metti", t)
	cur.dinamo.call("_conferma")
	for i in 300: await get_tree().process_frame
	print("tacca ", t, ": stato ", B.state("-5").get("status"), " premio ", GameState.money - soldi, " risultato ", B.state("-5").get("result"))
	get_tree().quit(0)
