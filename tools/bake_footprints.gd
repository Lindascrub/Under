extends Node
## Scrive DENTRO le scene da editor l'ingombro dei mobili di data/props.json ("footprint"): così la
## CollisionShape2D che vedi nell'editor è quella vera del gioco. Lo sprite prende il metadato
## footprint_applied e PropTalk non la sostituisce più quando la stanza parte.
## Da lì in poi la collisione si sistema a mano nell'editor (trascinando le maniglie della forma).
## Esegui:  Godot --headless --path . res://tools/bake_footprints.tscn

const SCENES := [
	"res://chapters/c1/fondo.tscn",
	"res://chapters/c2/sottoufficio.tscn",
	"res://chapters/c3/mercato.tscn",
	"res://chapters/c4/banca.tscn",
	"res://chapters/c5/citta.tscn",
	"res://chapters/c5/casa_comune.tscn",
	"res://chapters/c6/cima.tscn",
]


func _ready() -> void:
	var props: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/props.json"))
	for path: String in SCENES:
		var root := (load(path) as PackedScene).instantiate()
		var n := 0
		for spr in root.find_children("*", "Sprite2D", true, false):
			var s := spr as Sprite2D
			if s.texture == null or s.has_meta("footprint_applied") or s.owner != root:
				continue
			var entry: Variant = props.get(_key(s))
			if not entry is Dictionary or not (entry as Dictionary).has("footprint"):
				continue
			_bake(root, s, entry["footprint"])
			n += 1
		var packed := PackedScene.new()
		var err := packed.pack(root)
		if err == OK:
			err = ResourceSaver.save(packed, path)
		print("INGOMBRI ", path, ": ", n, " mobili -> ", error_string(err))
		root.free()
	get_tree().quit()


func _bake(root: Node, s: Sprite2D, values: Array) -> void:
	var size := s.region_rect.size if s.region_enabled else s.texture.get_size()
	var offset := s.offset - (size / 2.0 if s.centered else Vector2.ZERO)
	var bodies := s.find_children("*", "StaticBody2D", true, false)
	var body: StaticBody2D
	if bodies.is_empty():
		body = StaticBody2D.new()
		body.name = "Collisione"
		s.add_child(body)
		body.owner = root
	else:
		body = bodies[0]
	for c in body.get_children():
		if c is CollisionShape2D:
			body.remove_child(c)
			c.free()
	var boxes: Array = values if values[0] is Array else [values]
	var i := 0
	for v: Array in boxes:
		var box := Rect2(float(v[0]), float(v[1]), float(v[2]), float(v[3]))
		if s.flip_h:
			box.position.x = size.x - box.end.x
		if s.flip_v:
			box.position.y = size.y - box.end.y
		var rect := RectangleShape2D.new()
		rect.size = box.size
		var shape := CollisionShape2D.new()
		shape.name = "Ingombro" if boxes.size() == 1 else "Ingombro%d" % i
		shape.shape = rect
		shape.position = offset + box.get_center() - body.position
		body.add_child(shape)
		shape.owner = root
		i += 1
	s.set_meta("footprint_applied", true)


## Come PropTalk._key: il file dopo assets/limezu/, più @x,y del pezzo se è un foglio.
func _key(s: Sprite2D) -> String:
	var path := s.texture.resource_path
	var rel := path.trim_prefix("res://assets/limezu/") if path.begins_with("res://assets/limezu/") else path.trim_prefix("res://")
	if s.region_enabled:
		rel += "@%d,%d" % [int(s.region_rect.position.x), int(s.region_rect.position.y)]
	return rel
