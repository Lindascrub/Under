class_name FocusShot
extends RefCounted
## Una ripresa temporanea. Conserva anche limiti e offset della camera del giocatore.

static func begin(room: Room, point: Vector2, zoom := 3.0) -> Dictionary:
	var cam := room.player.camera
	var saved := {"camera": cam, "top_level": cam.top_level, "position": cam.position,
		"zoom": cam.zoom, "offset": cam.offset, "smooth": cam.position_smoothing_enabled,
		"limits": [cam.limit_left, cam.limit_top, cam.limit_right, cam.limit_bottom]}
	var start := cam.get_screen_center_position()
	cam.position_smoothing_enabled = false
	cam.top_level = true
	cam.offset = Vector2.ZERO
	cam.limit_left = -100000; cam.limit_top = -100000
	cam.limit_right = 100000; cam.limit_bottom = 100000
	cam.global_position = start
	var tw := room.create_tween().set_parallel()
	tw.tween_property(cam, "global_position", point + Vector2(0, 27), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(cam, "zoom", Vector2(zoom, zoom), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	return saved


static func restore(room: Room, saved: Dictionary) -> void:
	var cam: Camera2D = saved["camera"]
	var destination: Vector2 = room.player.to_global(saved["position"]) if not saved["top_level"] else saved["position"]
	var tw := room.create_tween().set_parallel()
	tw.tween_property(cam, "global_position", destination, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(cam, "zoom", saved["zoom"], 0.65)
	await tw.finished
	cam.top_level = saved["top_level"]
	cam.position = saved["position"]
	cam.offset = saved["offset"]
	cam.limit_left = saved["limits"][0]; cam.limit_top = saved["limits"][1]
	cam.limit_right = saved["limits"][2]; cam.limit_bottom = saved["limits"][3]
	cam.position_smoothing_enabled = saved["smooth"]
	cam.reset_smoothing()
