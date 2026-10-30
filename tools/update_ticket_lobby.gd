extends SceneTree
## Narrow scene edit: preserve all other nodes and all manual map edits.
func _initialize() -> void:
 call_deferred("_update")

func _update() -> void:
 var path := "res://chapters/c1/fondo.tscn"
 var root: Node = load(path).instantiate()
 var floors: TileMapLayer = root.get_node("Pavimento")
 var walls: TileMapLayer = root.get_node("Muri")
 var tiles: TileSet = load("res://world/tilesets/interni.tres")
 var header := FileAccess.get_file_as_string("res://world/tilesets/interni.tres").get_slice("\n", 0)
 var atlas: TileSetAtlasSource = tiles.get_source(0)
 for x in range(38, 41):
  for y in range(13, 15):
   if not atlas.has_tile(Vector2i(x, y)): atlas.create_tile(Vector2i(x, y))
 ResourceSaver.save(tiles, "res://world/tilesets/interni.tres")
 if header.contains("uid="):
  var content := FileAccess.get_file_as_string("res://world/tilesets/interni.tres")
  var file := FileAccess.open("res://world/tilesets/interni.tres", FileAccess.WRITE)
  file.store_string(header + "\n" + content.substr(content.find("\n") + 1)); file.close()
 for c: Vector2i in floors.get_used_cells():
  if c.x >= 24:
   floors.set_cell(c, 0, Vector2i(38 + c.x % 3, 13 + c.y % 2))
 # Remove only the old full-width divider; the new six-pixel wall has its own exact collision.
 for y in range(1, 13):
  walls.erase_cell(Vector2i(23, y))
  floors.set_cell(Vector2i(23, y), 0, Vector2i(38 + 23 % 3, 13 + y % 2))
 var architecture := root.get_node_or_null("MuriBiglietteria")
 if not architecture:
  architecture = Node2D.new()
  architecture.name = "MuriBiglietteria"
  architecture.set_script(load("res://world/ticket_lobby.gd"))
  root.add_child(architecture); architecture.owner = root
 root.move_child(architecture, root.get_node("Mondo").get_index())
 root.get_node("Mondo/ScaleSu").position = Vector2(512, 48)
 if root.has_node("Mondo/Cyclette"): root.get_node("Mondo/Cyclette").name = "UsaCycletteDinamo"
 if not root.has_node("Mondo/AscensoreOriginale"):
  var elevator := Node2D.new()
  elevator.name = "AscensoreOriginale"
  elevator.set_script(load("res://world/lift.gd"))
  elevator.position = Vector2(176, 16)
  root.get_node("Mondo").add_child(elevator); elevator.owner = root
 _camera(root, Vector2(304, 24), false)
 _camera(root, Vector2(496, 40), true)
 _save(root, path)
 for scene: String in ["res://chapters/c2/sottoufficio.tscn", "res://chapters/c4/banca.tscn"]:
  root = load(scene).instantiate()
  _camera(root, Vector2(192 if scene.contains("c2") else 320, 28), false)
  _camera(root, Vector2(432, 28) if scene.contains("c2") else Vector2(608, 24), true)
  _save(root, scene)
 print("Ticket lobby: native tiles, thin partition, return, stair pier, six native cameras, existing glass elevator.")
 quit()

func _camera(root: Node, at: Vector2, flip: bool) -> void:
 if root.has_node("Mondo/TelecameraCHEAP_%d" % int(at.x)): return
 var sprite := Sprite2D.new()
 sprite.name = "TelecameraCHEAP_%d" % int(at.x)
 sprite.texture = load("res://assets/limezu/tiles/room_builder.png")
 sprite.region_enabled = true
 sprite.region_rect = Rect2(800, 336, 16, 16)
 sprite.centered = false
 sprite.flip_h = flip
 sprite.position = at
 sprite.set_meta("prop_talk_skip", true)
 root.get_node("Mondo").add_child(sprite); sprite.owner = root

func _save(root: Node, path: String) -> void:
 var original_header := FileAccess.get_file_as_string(path).get_slice("\n", 0)
 var packed := PackedScene.new()
 var error := packed.pack(root)
 if error == OK: error = ResourceSaver.save(packed, path)
 if error != OK: push_error("Scene edit failed " + path); quit(1)
 if original_header.contains("uid="):
  var content := FileAccess.get_file_as_string(path)
  var file := FileAccess.open(path, FileAccess.WRITE)
  file.store_string(original_header + "\n" + content.substr(content.find("\n") + 1)); file.close()
 root.free()
