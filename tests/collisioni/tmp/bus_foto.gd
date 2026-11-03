extends Node
var out := "C:/Users/linda/AppData/Local/Temp/claude/C--Users-linda-Documents-sito-siw-personle/2f16c58e-bb47-4c51-9f96-d6f04090c739/scratchpad/bus/"


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
	GameState.save_path = "user://bus_foto.json"
	GameState.new_game()
	TouchControls.enabled = true
	var placeholder := Node.new()
	get_tree().root.add_child.call_deferred(placeholder)
	await get_tree().process_frame
	get_tree().current_scene = placeholder
	GameState.minigame = {"kind": "help", "type": "coincidenze", "title": "Prova", "count": 10, "time": 60,
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
	var l: Dictionary = {}
	for x: Dictionary in m.call("_cz_lines"):
		if x["linea"] == "Bus 12":
			l = x
	var curve: PackedVector2Array = m.call("_cz_curve", l)
	var t := InputEventScreenTouch.new()
	t.position = curve[0] * 2.0
	t.pressed = true
	Input.parse_input_event(t)
	await get_tree().create_timer(0.2).timeout
	for i in range(1, 13):
		var d := InputEventScreenDrag.new()
		d.position = curve[i] * 2.0
		Input.parse_input_event(d)
		await get_tree().process_frame
	for i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "trascino.png")
	get_tree().quit(0)
