extends Node

func _ready() -> void:
	GameState.save_path = "user://test_save.json"
	GameState.new_game()
	GameState.badges.assign(["-4", "-3", "-2"])
	for f in ["c1_arrivo", "c2_arrivo", "c3_arrivo", "c4_arrivo"]:
		GameState.flags[f] = true
	GameState.floor_id = "-3"
	Router.goto("res://chapters/c3/mercato.tscn", "")
	await get_tree().create_timer(4.0).timeout
	var r = get_tree().current_scene
	r.player.global_position = Vector2(10 * 16, 12 * 16)
	await get_tree().create_timer(1.0).timeout
	await _snap("C:/Users/linda/AppData/Local/Temp/claude/C--Users-linda-Documents-sito-siw-personle/2f16c58e-bb47-4c51-9f96-d6f04090c739/scratchpad/m2_casse.png")
	var cam: Camera2D = r.player.camera
	cam.limit_left = -10000; cam.limit_right = 10000; cam.limit_top = -10000; cam.limit_bottom = 10000
	cam.position_smoothing_enabled = false
	cam.zoom = Vector2(1.1, 1.1)
	r.player.global_position = Vector2(18 * 16, 8.5 * 16)
	await get_tree().create_timer(0.8).timeout
	await _snap("C:/Users/linda/AppData/Local/Temp/claude/C--Users-linda-Documents-sito-siw-personle/2f16c58e-bb47-4c51-9f96-d6f04090c739/scratchpad/m2_all.png")
	GameState.floor_id = "-5"
	Router.goto("res://chapters/c1/fondo.tscn", "")
	await get_tree().create_timer(4.0).timeout
	r = get_tree().current_scene
	r.player.global_position = Vector2(27 * 16 + 8, 7 * 16)
	await get_tree().create_timer(0.6).timeout
	var seats = []
	for n in get_tree().get_nodes_in_group("interactable"):
		if n is Seat: seats.append(n)
	print("SEATS ", seats.size())
	for n in seats:
		if n.global_position.y < 6 * 16:
			n.interact()
			break
	await get_tree().create_timer(0.6).timeout
	await _snap("C:/Users/linda/AppData/Local/Temp/claude/C--Users-linda-Documents-sito-siw-personle/2f16c58e-bb47-4c51-9f96-d6f04090c739/scratchpad/f2_sofa.png")
	r.player.stand_up()
	r.player.global_position = Vector2(26 * 16 + 8, 10 * 16)
	for n in seats:
		if n.global_position.y > 7 * 16:
			n.interact()
			break
	await get_tree().create_timer(0.6).timeout
	await _snap("C:/Users/linda/AppData/Local/Temp/claude/C--Users-linda-Documents-sito-siw-personle/2f16c58e-bb47-4c51-9f96-d6f04090c739/scratchpad/f2_chair.png")
	get_tree().quit()

func _snap(p: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(p)
