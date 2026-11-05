extends Node
const B := preload("res://scripts/boss_missions.gd")
func _ready() -> void:
	TouchControls.enabled = "--touch" in OS.get_cmdline_user_args()
	GameState.save_path = "user://test_capo5.json"
	GameState.new_game()
	GameState.minigame = {"boss_floor": "-5"}
	await get_tree().process_frame
	var cur: Node = load(B.SCENE).instantiate(); get_tree().root.add_child(cur); get_tree().current_scene = cur
	for i in 20: await get_tree().process_frame
	var d: Node = cur.get("dinamo")
	print("dinamo: ", d != null)
	for t in [0, 3]:
		d.call("_metti", t)
		for i in 40: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/collisioni/tmp/foto_giochi/capo5_%d%s.png" % [t, "_tel" if TouchControls.enabled else ""])
		print("tacca ", t, " p=", cur.get("p"))
	get_tree().quit(0)
