class_name PropTalk
extends RefCounted
## Ogni oggetto della mappa si può guardare (e le sedie usare) anche senza un esame scritto a mano:
## le frasi, i posti a sedere e i piedi solidi sono in data/props.json, per file (e pezzo) della texture.
## Se vicino all'oggetto c'è già qualcosa con cui interagire (un esame, una persona), le frasi non si aggiungono.

const DATA := "res://data/props.json"
static var _data: Dictionary = {}


static func apply(room: Node) -> void:
	if _data.is_empty():
		var f := FileAccess.open(DATA, FileAccess.READ)
		if f == null:
			return
		_data = JSON.parse_string(f.get_as_text())
	var tree := room.get_tree()
	var made: Array = []
	for parent_name in ["Mondo", "Decori"]:
		var parent := room.get_node_or_null(parent_name)
		if parent == null:
			continue
		for s in parent.find_children("*", "Sprite2D", true, false):
			var spr := s as Sprite2D
			if spr.texture == null or not spr.is_visible_in_tree():
				continue
			var entry: Dictionary = _data.get(_key(spr), {})
			if entry.is_empty():
				continue
			var rect := _rect(spr)
			if entry.has("lines") and not _busy(tree, rect.grow(4), made):
				var e := Interactable.new()
				var lines: Array = entry["lines"]
				e.action = func() -> void: await Ui.say(lines)
				spr.get_parent().add_child(e)
				e.global_position = Vector2(rect.get_center().x, rect.end.y - 4)
				made.append(e)
			for st: Array in entry.get("seats", []):
				var x := float(st[0])
				if spr.flip_h:
					x = rect.size.x - x
				var at := Vector2(rect.position.x + x, rect.end.y + float(st[1]))
				if _person_near(room, tree, at):
					continue
				var seat := Seat.new()
				seat.dir = str(st[2])
				if spr.flip_h and seat.dir in ["left", "right"]:
					seat.dir = "right" if seat.dir == "left" else "left"
				seat.lift = float(st[3]) if st.size() > 3 else 6.0
				spr.get_parent().add_child(seat)
				seat.global_position = at
				made.append(seat)
			var solid := int(entry.get("solid", 0))
			if solid > 0 and spr.find_children("*", "StaticBody2D", true, false).is_empty():
				var body := StaticBody2D.new()
				var shape := CollisionShape2D.new()
				var r := RectangleShape2D.new()
				r.size = Vector2(rect.size.x - 4, solid)
				shape.shape = r
				body.add_child(shape)
				spr.get_parent().add_child(body)
				body.global_position = Vector2(rect.get_center().x, rect.end.y - solid / 2.0)


## La chiave in props.json: il file (dopo assets/limezu/), più @x,y del pezzo se è un foglio.
static func _key(s: Sprite2D) -> String:
	var path := s.texture.resource_path
	var rel := path.trim_prefix("res://assets/limezu/") if path.begins_with("res://assets/limezu/") else path.trim_prefix("res://")
	if s.region_enabled:
		rel += "@%d,%d" % [int(s.region_rect.position.x), int(s.region_rect.position.y)]
	return rel


static func _rect(s: Sprite2D) -> Rect2:
	var size := s.region_rect.size if s.region_enabled else s.texture.get_size()
	var top_left := s.offset - (size / 2.0 if s.centered else Vector2.ZERO)
	var a := s.global_transform * top_left
	var b := s.global_transform * (top_left + size)
	return Rect2(a, Vector2.ZERO).expand(b).abs()


## C'è già qualcosa da toccare dentro (o vicino) a questo oggetto?
static func _busy(tree: SceneTree, r: Rect2, made: Array) -> bool:
	for n in tree.get_nodes_in_group("interactable"):
		if n in made or not n.has_method("hotspot"):
			continue
		if r.has_point(n.call("hotspot")):
			return true
	return false


static func _person_near(room: Node, tree: SceneTree, at: Vector2) -> bool:
	for n in tree.get_nodes_in_group("npc"):
		if (n as Node2D).global_position.distance_to(at) < 12:
			return true
	for c in room.find_children("*", "CharSprite", true, false):
		if (c as Node2D).global_position.distance_to(at) < 12:
			return true
	return false
