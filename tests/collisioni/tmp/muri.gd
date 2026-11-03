extends SceneTree
func _initialize() -> void:
	var path := "res://chapters/c6/cima.tscn"
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--map="): path = a.trim_prefix("--map=")
	var root := (load(path) as PackedScene).instantiate()
	var muri := root.get_node("Muri") as TileMapLayer
	var pav := root.get_node("Pavimento") as TileMapLayer
	var r := muri.get_used_rect().merge(pav.get_used_rect())
	print("rect ", r)
	for y in range(r.position.y, r.end.y):
		var line := ""
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			var sid := muri.get_cell_source_id(c)
			if sid == -1:
				line += "." if pav.get_cell_source_id(c) != -1 else " "
				continue
			var td := muri.get_cell_tile_data(c)
			var solid := td != null and td.get_collision_polygons_count(0) > 0
			line += "#" if solid else "o"
		print("%3d %s" % [y, line])
	quit()
