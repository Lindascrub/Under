extends Node
var out := "C:/Users/linda/AppData/Local/Temp/claude/C--Users-linda-Documents-sito-siw-personle/2f16c58e-bb47-4c51-9f96-d6f04090c739/scratchpad/fili/"


func _process(_d: float) -> void:
	if Ui.busy:
		var e := InputEventAction.new()
		e.action = "confirm"
		e.pressed = true
		Input.parse_input_event(e)
		var u := InputEventAction.new()
		u.action = "confirm"
		Input.parse_input_event(u)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	GameState.save_path = "user://fili_foto.json"
	GameState.new_game()
	TouchControls.enabled = true
	var placeholder := Node.new()
	get_tree().root.add_child.call_deferred(placeholder)
	await get_tree().process_frame
	get_tree().current_scene = placeholder
	GameState.minigame = {"kind": "help", "type": "wires", "title": "Prova", "count": 10, "time": 60,
		"intro": ["* Prova."], "return": Router.FONDO}
	Router.goto(Router.MINIGAME)
	var m: Node = null
	for i in 600:
		await get_tree().process_frame
		m = get_tree().current_scene
		if m and m.scene_file_path == Router.MINIGAME and m.get("phase") == "play" and not Ui.transitioning:
			break
	set_process(false)
	await get_tree().create_timer(0.5).timeout
	var box: Rect2 = m.BOX
	var y0 := box.position.y + 26
	var gap := (box.size.y - 52) / 3.0
	var t := InputEventScreenTouch.new()
	t.position = Vector2(box.position.x + 25, y0 + gap) * 2.0
	t.pressed = true
	Input.parse_input_event(t)
	await get_tree().create_timer(0.2).timeout
	var d := InputEventScreenDrag.new()
	d.position = (box.get_center() + Vector2(30, -20)) * 2.0
	Input.parse_input_event(d)
	for i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "trascino.png")
	get_tree().quit(0)
