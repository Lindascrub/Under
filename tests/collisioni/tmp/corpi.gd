extends Node
var frame := 0
func _ready() -> void:
	await get_tree().process_frame
	GameState.save_path = "user://collisioni_tmp.json"
	var path := "res://chapters/c5/citta.tscn"
	var area := Rect2(-10000, -10000, 20000, 20000)
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--map="):
			path = a.trim_prefix("--map=")
		if a.begins_with("--rect="):
			var v := a.trim_prefix("--rect=").split(",")
			area = Rect2(float(v[0]), float(v[1]), float(v[2]), float(v[3]))
	var room: Room = await MappaAperta.apri(self, path)
	for n in room.find_children("*", "CollisionShape2D", true, false):
		var c := n as CollisionShape2D
		if c.disabled or c.shape == null: continue
		var r := c.shape.get_rect()
		var g := c.global_transform * r.position
		var g2 := c.global_transform * r.end
		var gr := Rect2(g, g2 - g).abs()
		if not gr.intersects(area): continue
		var body := c.get_parent()
		var kind := body.get_class()
		if body is CollisionObject2D and not (body is Area2D):
			print("CORPO ", room.get_path_to(c), "  ", gr, "  layer ", (body as CollisionObject2D).collision_layer)
	for n in room.find_children("*", "CollisionPolygon2D", true, false):
		var c := n as CollisionPolygon2D
		print("POLY ", room.get_path_to(c), " ", c.global_position, " ", c.polygon)
	for n in room.find_children("*", "Sprite2D", true, false):
		var s := n as Sprite2D
		if s.texture == null or not s.is_visible_in_tree(): continue
		var r := s.get_rect()
		var g := s.global_transform * r.position
		var g2 := s.global_transform * r.end
		var gr := Rect2(g, g2 - g).abs()
		if gr.intersects(area):
			print("SPRITE ", room.get_path_to(s), "  ", gr, "  z ", s.z_index, " ", s.texture.resource_path.get_file())
	get_tree().quit(0)
func _process(_d: float) -> void:
	frame += 1
	MappaAperta.salta_dialoghi(frame)
