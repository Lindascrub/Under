extends Node
var out := "C:/Users/linda/AppData/Local/Temp/claude/C--Users-linda-Documents-sito-siw-personle/2f16c58e-bb47-4c51-9f96-d6f04090c739/scratchpad/snake/"


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
	GameState.save_path = "user://snake_foto.json"
	GameState.new_game()
	TouchControls.enabled = true
	var placeholder := Node.new()
	get_tree().root.add_child.call_deferred(placeholder)
	await get_tree().process_frame
	get_tree().current_scene = placeholder
	var mg: Dictionary = (GameState.npc_data("amir")["help"]["minigame"] as Dictionary).duplicate(true)
	mg["intro"] = ["* Prova."]
	mg["return"] = Router.FONDO
	mg["seed"] = 3
	GameState.minigame = mg
	Router.goto(Router.MINIGAME)
	var m: Node = null
	for i in 600:
		await get_tree().process_frame
		m = get_tree().current_scene
		if m and m.scene_file_path == Router.MINIGAME and m.get("phase") == "play" and not Ui.transitioning:
			break
	set_process(false)
	await get_tree().create_timer(0.5).timeout
	await get_tree().create_timer(1.4).timeout
	var d := InputEventAction.new()
	d.action = "move_down"
	d.pressed = true
	Input.parse_input_event(d)
	await get_tree().create_timer(0.6).timeout
	print("corpo ", m.get("sn_body"), " pacco ", m.get("sn_parcel"), " errori ", m.get("misses"))
	for i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "trascino.png")
	get_tree().quit(0)
