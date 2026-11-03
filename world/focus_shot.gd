class_name FocusShot
extends RefCounted
## Una ripresa temporanea verso un nodo Inquadratura della scena. Conserva anche limiti e offset
## della camera del giocatore, per rimetterli com'erano.

static func begin(room: Room, shot: Inquadratura) -> Dictionary:
	var cam := room.player.camera
	var saved := {"camera": cam, "top_level": cam.top_level, "position": cam.position,
		"zoom": cam.zoom, "offset": cam.offset, "smooth": cam.position_smoothing_enabled,
		"limits": [cam.limit_left, cam.limit_top, cam.limit_right, cam.limit_bottom],
		"back": shot.durata_ritorno}
	var start := _inside(cam, cam.get_screen_center_position())
	cam.position_smoothing_enabled = false
	cam.top_level = true
	cam.offset = Vector2.ZERO
	# i limiti restano: anche nelle inquadrature non si vede mai fuori dalla stanza
	cam.global_position = start
	var tw := room.create_tween().set_parallel()
	tw.tween_property(cam, "global_position", shot.global_position, shot.durata).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var z := maxf(shot.zoom, room.zoom_minimo())
	tw.tween_property(cam, "zoom", Vector2(z, z), shot.durata).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	return saved


## Il punto più vicino che la camera può davvero inquadrare: con i limiti, una camera "fuori"
## resterebbe ferma sul bordo e il movimento partirebbe in ritardo.
static func _inside(cam: Camera2D, p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, cam.limit_left, cam.limit_right), clampf(p.y, cam.limit_top, cam.limit_bottom))


static func restore(room: Room, saved: Dictionary) -> void:
	var cam: Camera2D = saved["camera"]
	var destination: Vector2 = room.player.to_global(saved["position"]) if not saved["top_level"] else saved["position"]
	var tw := room.create_tween().set_parallel()
	tw.tween_property(cam, "global_position", destination, saved["back"]).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(cam, "zoom", saved["zoom"], saved["back"])
	await tw.finished
	cam.top_level = saved["top_level"]
	cam.position = saved["position"]
	cam.offset = saved["offset"]
	cam.limit_left = saved["limits"][0]; cam.limit_top = saved["limits"][1]
	cam.limit_right = saved["limits"][2]; cam.limit_bottom = saved["limits"][3]
	cam.position_smoothing_enabled = saved["smooth"]
	cam.reset_smoothing()
