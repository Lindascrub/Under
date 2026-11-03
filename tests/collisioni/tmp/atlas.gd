extends SceneTree
func _initialize() -> void:
	var root := (load("res://chapters/c6/cima.tscn") as PackedScene).instantiate()
	var muri := root.get_node("Muri") as TileMapLayer
	var found := {}
	for c in muri.get_used_cells():
		var td := muri.get_cell_tile_data(c)
		if td and td.get_collision_polygons_count(0) == 0:
			found["%d:%s" % [muri.get_cell_source_id(c), muri.get_cell_atlas_coords(c)]] = true
	print("SENZA ", found.keys())
	# dove compaiono negli altri livelli
	for p in ["res://chapters/c1/fondo.tscn","res://chapters/c2/sottoufficio.tscn","res://chapters/c3/mercato.tscn","res://chapters/c4/banca.tscn","res://chapters/c5/casa_comune.tscn","res://chapters/c6/cima.tscn","res://scenes/world/boss_office.tscn","res://chapters/c5/citta.tscn"]:
		var r := (load(p) as PackedScene).instantiate()
		for l in r.find_children("*", "TileMapLayer", true, false):
			var t := l as TileMapLayer
			if t.tile_set != muri.tile_set: continue
			var n := 0
			for c in t.get_used_cells():
				if found.has("%d:%s" % [t.get_cell_source_id(c), t.get_cell_atlas_coords(c)]): n += 1
			if n > 0: print(p, " ", t.name, " ", n)
		r.free()
	var ts := muri.tile_set
	print("physics layers ", ts.get_physics_layers_count())
	quit()
