class_name PropTalk
extends RefCounted
## Ogni oggetto della mappa si può guardare (e le sedie usare) anche senza un esame scritto a mano:
## le frasi, i posti a sedere e i piedi solidi sono in data/props.json, per file (e pezzo) della texture.
## Se vicino all'oggetto c'è già qualcosa con cui interagire (un esame, una persona), le frasi non si aggiungono.

const DATA := "res://data/props.json"
static var _data: Dictionary = {}


static func apply(room: Node) -> void:
	if room.get_meta("prop_talk_applied", false):
		return
	if _data.is_empty():
		var f := FileAccess.open(DATA, FileAccess.READ)
		if f == null:
			return
		_data = JSON.parse_string(f.get_as_text())
	room.set_meta("prop_talk_applied", true)
	var tree := room.get_tree()
	var made: Array = []
	for parent_name in ["Mondo", "Decori"]:
		var parent := room.get_node_or_null(parent_name)
		if parent == null:
			continue
		var covered := {}
		for s in parent.find_children("*", "Sprite2D", true, false):
			var spr := s as Sprite2D
			if spr.texture == null or not spr.is_visible_in_tree() or _skip_branch(spr, room):
				continue
			var root := _root_child(spr, parent)
			var explicit: Dictionary = _data.get(_key(spr), {})
			if explicit.is_empty():
				# Gli oggetti composti gestiscono già il proprio punto d'uso.
				if spr.get_parent() != parent:
					continue
			var entry := _entry_for(spr, room, spr.get_parent() == parent)
			if entry.is_empty():
				continue
			var rect := _rect(spr)
			if entry.has("footprint"):
				_apply_footprint(spr, entry["footprint"])
			if entry.has("lines") and not _busy(tree, rect.grow(4), made):
				_add_inspection(spr.get_parent(), spr, rect, entry, made)
				covered[root] = true
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
				var seat_lines := _seat_lines(spr, room)
				if not seat_lines.is_empty():
					seat.line = str(seat_lines[0])
					if seat_lines.size() > 1:
						seat.repeat_line = str(seat_lines[1])
				if _key(spr) == "street/bench_side.png":
					seat.low_pose = true
					seat.set_meta("bench", true)
					seat.approach = Vector2.LEFT if seat.dir == "left" else Vector2.RIGHT
					seat.interaction_bounds = Rect2(-3, -16, 6, 28)
					seat.reach = 12.0
				spr.get_parent().add_child(seat)
				seat.global_position = at
				made.append(seat)
				covered[root] = true
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
		# Un mobile composto da più sprite riceve un solo punto d'esame sull'ingombro totale.
		# Contenitori con uno script o con prop_talk_skip restano di competenza della loro logica.
		for child in parent.get_children():
			if child in covered or child is Sprite2D or child.get_script() != null or _skip_branch(child, room):
				continue
			var sprites: Array[Sprite2D] = []
			for found in child.find_children("*", "Sprite2D", true, false):
				var part := found as Sprite2D
				if part.texture and part.is_visible_in_tree() and not _skip_branch(part, room):
					sprites.append(part)
			if sprites.is_empty():
				continue
			var rect := _rect(sprites[0])
			for i in range(1, sprites.size()):
				rect = rect.merge(_rect(sprites[i]))
			# Evita di trasformare intere facciate o sfondi in un unico enorme pulsante.
			if rect.size.x > 128.0 or rect.size.y > 96.0 or _busy(tree, rect.grow(4), made):
				continue
			var entry := _fallback_entry(sprites[0], room, str(child.name))
			_add_inspection(parent, sprites[0], rect, entry, made)


static func _skip_branch(node: Node, room: Node) -> bool:
	var current := node
	while current != null and current != room:
		if current.get_meta("prop_talk_skip", false):
			return true
		current = current.get_parent()
	return false


static func _entry_for(spr: Sprite2D, room: Node, allow_fallback: bool) -> Dictionary:
	var raw: Dictionary = _data.get(_key(spr), {})
	if raw.is_empty():
		return _fallback_entry(spr, room) if allow_fallback else {}
	var entry := raw.duplicate(true)
	var category := _category(spr)
	entry["_category"] = category
	# Le voci solo fisiche (footprint/solid) meritano comunque una descrizione.
	# Le sedute fanno già qualcosa, quindi il testo passa dalla Seat e non da un punto sovrapposto.
	if not entry.has("lines") and not entry.has("seats") and bool(entry.get("inspect", true)):
		entry["lines"] = _fallback_lines(category, spr, room)
	if not entry.has("repeat"):
		entry["repeat"] = _fallback_repeat(category, spr, room)
	return entry


static func _fallback_entry(spr: Sprite2D, room: Node, label := "") -> Dictionary:
	var category := _category(spr, label)
	return {"lines": _fallback_lines(category, spr, room),
		"repeat": _fallback_repeat(category, spr, room), "_category": category}


static func _fallback_lines(category: String, spr: Sprite2D, room: Node) -> Array:
	var pools: Dictionary = _data.get("_fallbacks", {})
	var key := category
	if key == "default":
		var floor_key := "floor_" + str(room.get("floor_id"))
		if pools.has(floor_key):
			key = floor_key
	return _pick(pools.get(key, pools.get("default", [])), _key(spr) + str(spr.name) + key)


static func _fallback_repeat(category: String, spr: Sprite2D, room: Node) -> Array:
	var pools: Dictionary = _data.get("_repeats", {})
	return _pick(pools.get(category, pools.get("default", [])), _key(spr) + str(spr.name) + str(room.get("floor_id")) + "repeat")


static func _pick(pool: Array, seed: String) -> Array:
	if pool.is_empty():
		return []
	var value = pool[posmod(hash(seed), pool.size())]
	return (value as Array).duplicate() if value is Array else [str(value)]


static func _category(spr: Sprite2D, extra := "") -> String:
	var label := (extra + " " + str(spr.name) + " " + _key(spr)).to_lower()
	if "computer" in label or "terminal" in label or "monitor" in label or "schermo" in label or "televis" in label or "display" in label:
		return "machine"
	if "frigo" in label or "freezer" in label:
		return "fridge"
	if "sedia" in label or "chair" in label or "panch" in label or "bench" in label or "divan" in label or "sofa" in label or "poltron" in label:
		return "seat"
	if "scrivania" in label or "desk" in label or "tavol" in label or "table" in label or "bancone" in label or "counter" in label:
		return "desk"
	if "scaff" in label or "shelf" in label or "librer" in label or "cabinet" in label or "archiv" in label or "schedar" in label or "armadio" in label:
		return "storage"
	if "scatol" in label or "cassa" in label or "box" in label or "pallet" in label or "crate" in label:
		return "container"
	if "pianta" in label or "plant" in label or "palm" in label or "albero" in label:
		return "plant"
	if "poster" in label or "cartell" in label or "insegna" in label or "avviso" in label or "bacheca" in label:
		return "sign"
	if "lamp" in label or "light" in label or "neon" in label:
		return "light"
	if "distribut" in label or "vending" in label:
		return "vending"
	if "porta" in label or "door" in label or "tornell" in label or "gate" in label:
		return "door"
	if "cestin" in label or "trash" in label or "rifiut" in label:
		return "trash"
	return "default"


static func _seat_lines(spr: Sprite2D, room: Node) -> Array:
	var pools: Dictionary = _data.get("_seat_lines", {})
	var label := (_key(spr) + " " + str(spr.name)).to_lower()
	var kind := "default"
	if "office" in label:
		kind = "office"
	elif "living_room" in label or "sofa" in label or "divan" in label:
		kind = "sofa"
	elif "bench" in label or "panch" in label:
		kind = "bench"
	elif "hospital" in label:
		kind = "waiting"
	return _pick(pools.get(kind, pools.get("default", [])), _key(spr) + str(room.get("floor_id")) + "seat")


static func _add_inspection(holder: Node, spr: Sprite2D, rect: Rect2, entry: Dictionary, made: Array) -> void:
	var lines: Array = entry.get("lines", [])
	if lines.is_empty():
		return
	var repeat: Array = entry.get("repeat", [])
	var category := str(entry.get("_category", "default"))
	var e := Interactable.new()
	e.set_meta("inspect_prop", true)
	e.set_meta("inspect_prop_key", _key(spr))
	e.set_meta("inspect_prop_category", category)
	e.set_meta("inspect_count", 0)
	e.action = func() -> void:
		var count := int(e.get_meta("inspect_count", 0))
		e.set_meta("inspect_count", count + 1)
		_prop_sound(category)
		await Ui.say(repeat if count > 0 and not repeat.is_empty() else lines)
	holder.add_child(e)
	e.global_position = Vector2(rect.get_center().x, rect.end.y - 4)
	var inner := rect.grow(-1.0) if rect.size.x > 2.0 and rect.size.y > 2.0 else rect
	e.interaction_bounds = Rect2(inner.position - e.global_position, inner.size)
	e.reach = 12.0
	made.append(e)


static func _prop_sound(category: String) -> void:
	match category:
		"machine": Sound.sfx("arcade/computer_1", 1.0, -5.0)
		"container": Sound.sfx("clunk", 0.75, -6.0)
		"light": Sound.sfx("spark", 0.8, -8.0)
		"door": Sound.sfx("door", 0.8, -10.0)
		_: Sound.sfx("arcade/select_2", 0.85, 1.0)


static func _root_child(node: Node, parent: Node) -> Node:
	var current := node
	while current.get_parent() != null and current.get_parent() != parent:
		current = current.get_parent()
	return current


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
		if v.size() < 4:
			push_warning("Ingombro incompleto in props.json per %s" % _key(spr))
			continue
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
