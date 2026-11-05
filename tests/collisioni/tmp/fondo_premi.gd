extends Node
func _process(_d: float) -> void:
	if Ui.busy and Engine.get_process_frames() % 4 == 0:
		var e := InputEventAction.new(); e.action = "confirm"; e.pressed = true; Input.parse_input_event(e)
		var u := InputEventAction.new(); u.action = "confirm"; u.pressed = false; Input.parse_input_event(u)
func _ready() -> void:
	GameState.save_path = "user://test_fondo_premi.json"
	GameState.new_game()
	GameState.flags["c1_arrivo"] = true
	if not "--senza" in OS.get_cmdline_user_args():
		GameState.flags["stelle_bulbo"] = 2
		GameState.flags["stelle_mina"] = 3
	await get_tree().process_frame
	var f: Node = load(Router.FONDO).instantiate(); get_tree().root.add_child(f); get_tree().current_scene = f
	for i in 200: await get_tree().process_frame
	var cam := get_viewport().get_camera_2d()
	print("premi visibili: ", f.get_node("Mondo/PremioMina").visible, " ", f.get_node("Mondo/PremioBulbo").visible, " lamp4 ", f.get_node("Mondo/ScatolaLampadine1/Lampadina4").visible)
	for target in [Vector2(104, 140), Vector2(295, 175)]:
		var p: Node2D = null
		for c in f.get_tree().get_nodes_in_group("player"): p = c
		if p: p.global_position = target + Vector2(0, 30)
		for i in 30: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/collisioni/tmp/foto_giochi/fondo_premio_%d.png" % int(target.x))
	get_tree().quit(0)
