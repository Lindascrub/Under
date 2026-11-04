extends Node
func _premi(a: String) -> void:
	var e := InputEventAction.new(); e.action = a; e.pressed = true
	Input.parse_input_event(e)
	var u := InputEventAction.new(); u.action = a; u.pressed = false
	Input.parse_input_event(u)
func _ready() -> void:
	await get_tree().process_frame
	var ev := InputEventKey.new(); ev.physical_keycode = KEY_ESCAPE; ev.pressed = true
	print("esc e cancel: ", ev.is_action("cancel"), "  esc e quit: ", ev.is_action("quit"))
	var cg = Controls.get_child(0)
	print("figlio: ", cg.name)
	get_tree().auto_accept_quit = false
	get_tree().root.close_requested.connect(func(): pass)
	_premi("quit")
	for i in 5: await get_tree().process_frame
	print("avviso visibile: ", cg.get_node("Avviso").visible)
	for i in 150: await get_tree().process_frame
	print("dopo il tempo: ", cg.get_node("Avviso").visible)
	var c = load("res://scenes/comandi.tscn").instantiate()
	add_child(c)
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://tests/collisioni/tmp/comandi_esc.png")
	print("OK prova esc")
	get_tree().quit(0)
