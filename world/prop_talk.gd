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
			if spr.texture == null or not spr.is_visible_in_tree() or _skip_branch(spr, room):
				continue
			var entry: Dictionary = _data.get(_key(spr), {})
			if entry.is_empty():
				# Gli oggetti composti gestiscono già il proprio punto d'uso.
				if spr.get_parent() != parent:
					continue
				entry = {"lines": _fallback(spr)}
			var rect := _rect(spr)
			if entry.has("footprint"):
				_apply_footprint(spr, entry["footprint"])
			if entry.has("lines") and not _busy(tree, rect.grow(4), made):
				var e := Interactable.new()
				var lines: Array = entry["lines"]
				e.action = func() -> void: await Ui.say(lines)
				e.set_meta("inspect_prop", true)
				spr.get_parent().add_child(e)
				e.global_position = Vector2(rect.get_center().x, rect.end.y - 4)
				e.interaction_bounds = Rect2(rect.position - e.global_position + Vector2.ONE, rect.size - Vector2(2, 2))
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
				if _key(spr) == "street/bench_side.png":
					seat.low_pose = true
					seat.set_meta("bench", true)
					seat.approach = Vector2.LEFT if seat.dir == "left" else Vector2.RIGHT
					seat.interaction_bounds = Rect2(-3, -16, 6, 28)
					seat.reach = 12.0
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


static func _skip_branch(node: Node, room: Node) -> bool:
	var current := node
	while current != null and current != room:
		if current.get_meta("prop_talk_skip", false):
			return true
		current = current.get_parent()
	return false


static func _fallback(spr: Sprite2D) -> Array:
	var label := str(spr.name).to_lower()
	if "scatol" in label or "cassa" in label or "box" in label:
		return ["* Scatole CHEAP. Sul nastro adesivo: NON APRIRE PRIMA DI IERI."]
	if "poster" in label or "cartell" in label or "insegna" in label:
		return ["* Una promessa stampata a colori. Le condizioni, come sempre, sono in piccolo."]
	if "pianta" in label:
		return ["* Una pianta. È qui da più tempo di quasi tutti i dipendenti."]
	if "frigo" in label:
		return ["* Un frigorifero CHEAP. Le etichette si rinnovano più spesso dei prodotti."]
	if "sedia" in label or "panchina" in label:
		return ["* Un posto per fermarsi un momento."]
	return ["* Anche questo oggetto porta il marchio CHEAP. Qui niente è lasciato al caso. Nemmeno la polvere."]


## L'ingombro del mobile sostituisce il piccolo rettangolo ai piedi degli sprite.
## Il corpo resta figlio del mobile, ma le dimensioni fisiche sono espresse nel mondo.
static func _apply_footprint(spr: Sprite2D, values: Array) -> void:
	if values.is_empty() or spr.has_meta("footprint_applied"):
		return
	spr.set_meta("footprint_applied", true)
	var size := spr.region_rect.size if spr.region_enabled else spr.texture.get_size()
	var offset := spr.offset - (size / 2.0 if spr.centered else Vector2.ZERO)
	var bodies := spr.find_children("*", "StaticBody2D", true, false)
	var body := bodies[0] as StaticBody2D if not bodies.is_empty() else StaticBody2D.new()
	if bodies.is_empty():
		body.name = "IngombroMobile"
		spr.add_child(body)
	for shape in body.get_children():
		if shape is CollisionShape2D:
			shape.disabled = true
			shape.queue_free()
	body.top_level = true
	body.global_transform = Transform2D.IDENTITY
	body.global_position = spr.global_position
	var boxes: Array = values if values[0] is Array else [values]
	for v: Array in boxes:
		var box := Rect2(float(v[0]), float(v[1]), float(v[2]), float(v[3]))
		if spr.flip_h:
			box.position.x = size.x - box.end.x
		if spr.flip_v:
			box.position.y = size.y - box.end.y
		var first := spr.global_transform * (offset + box.position)
		var last := spr.global_transform * (offset + box.end)
		var bounds := Rect2(first, Vector2.ZERO).expand(last).abs()
		var rectangle := RectangleShape2D.new()
		rectangle.size = bounds.size
		var collision := CollisionShape2D.new()
		collision.position = bounds.get_center() - body.global_position
		collision.shape = rectangle
		body.add_child(collision)


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
