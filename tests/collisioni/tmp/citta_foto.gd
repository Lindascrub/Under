extends Node
var out := "C:/Users/linda/AppData/Local/Temp/claude/C--Users-linda-Documents-sito-siw-personle/2f16c58e-bb47-4c51-9f96-d6f04090c739/scratchpad/citta/"

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
	GameState.save_path = "user://citta_foto.json"
	GameState.new_game()
	for f in ["c5_ada", "met_ada", "c5_lettera"]:
		GameState.flags[f] = true
	var placeholder := Node.new()
	get_tree().root.add_child.call_deferred(placeholder)
	await get_tree().process_frame
	get_tree().current_scene = placeholder
	Router.goto("res://chapters/c5/citta.tscn", "default")
	var r: Node = null
	for i in 900:
		await get_tree().process_frame
		r = get_tree().current_scene
		if r and r.scene_file_path.ends_with("citta.tscn") and not Ui.transitioning and r.get("player") != null:
			break
	await get_tree().create_timer(1.0).timeout
	var p: Node2D = r.get("player")
	var cam: Camera2D = p.get("camera")
	print("limiti ", cam.limit_left, " ", cam.limit_right, " ", cam.limit_top, " ", cam.limit_bottom)
	cam.enabled = false
	Ui.show_hud(false)
	var k := 0
	for v: Vector4 in [Vector4(560, -64, 1056, 352), Vector4(-592, -64, 600, 352)]:
		var sc := minf(640.0 / (v.z - v.x), 360.0 / (v.w - v.y))
		get_viewport().canvas_transform = Transform2D(0.0, Vector2(sc, sc), 0.0, -Vector2(v.x, v.y) * sc)
		for i in 8:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out + "mappa_%d.png" % k)
		k += 1
	get_tree().quit(0)
