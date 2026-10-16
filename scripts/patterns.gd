class_name Patterns
extends RefCounted
## Gli "attacchi" delle battaglie: ogni persona e ogni lavoro ti lancia addosso i suoi problemi.
## update() crea i proiettili nel riquadro, draw_all() li disegna in pixel art.
## Un proiettile è un Dictionary: type, pos, vel, acc, size, life, t, blue, harmless.


static func _spawn(b: Node, type: String, pos: Vector2, vel: Vector2, size: Vector2, extra := {}) -> Dictionary:
	var d := {"type": type, "pos": pos, "vel": vel, "size": size, "t": 0.0}
	d.merge(extra)
	b.bullets.append(d)
	return d


static func _every(b: Node, seconds: float) -> bool:
	if b.spawn_t <= 0.0:
		b.spawn_t = seconds
		return true
	return false


static func update(b: Node, attack: String, _delta: float) -> void:
	var box: Rect2 = b.box_target
	var t: float = b.attack_t
	match attack:
		"bills":
			if _every(b, 0.32):
				_spawn(b, "bill", Vector2(randf_range(box.position.x + 8, box.end.x - 8), box.position.y - 8),
					Vector2(randf_range(-20, 20), randf_range(70, 120)), Vector2(14, 10))
		"emails":
			if _every(b, 0.42):
				var left := randf() < 0.5
				_spawn(b, "mail", Vector2(box.position.x - 10 if left else box.end.x + 10, randf_range(box.position.y + 8, box.end.y - 8)),
					Vector2(140 if left else -140, 0), Vector2(14, 10))
		"boxes":
			if _every(b, 0.6):
				_spawn(b, "box", Vector2(randf_range(box.position.x + 12, box.end.x - 12), box.position.y - 12),
					Vector2(0, 30), Vector2(20, 16), {"acc": Vector2(0, 260)})
		"cars":
			if _every(b, 0.85):
				var lane := randi() % 3
				var y := box.position.y + 20 + lane * (box.size.y - 40) / 2.0
				var right := lane % 2 == 0
				_spawn(b, "car", Vector2(box.position.x - 30 if right else box.end.x + 30, y),
					Vector2(170 if right else -170, 0), Vector2(36, 16))
		"pigeons":
			if _every(b, 0.45):
				var left := randf() < 0.5
				var d := _spawn(b, "pigeon", Vector2(box.position.x - 8 if left else box.end.x + 8, randf_range(box.position.y + 10, box.end.y - 10)),
					Vector2(110 if left else -110, 0), Vector2(10, 8))
				d["wave"] = randf() * TAU
			for d in b.bullets:
				if d["type"] == "pigeon":
					d["vel"] = Vector2((d["vel"] as Vector2).x, sin(float(d["t"]) * 7.0 + float(d.get("wave", 0))) * 80.0)
		"crumbs":
			if _every(b, 0.09):
				_spawn(b, "crumb", Vector2(randf_range(box.position.x + 4, box.end.x - 4), box.position.y - 4),
					Vector2(randf_range(-10, 10), randf_range(90, 130)), Vector2(4, 4))
		"toys":
			if t < 0.1 and b.bullets.is_empty():
				for i in 3:
					_spawn(b, "ball", box.get_center() + Vector2(randf_range(-40, 40), -40),
						Vector2(randf_range(-90, 90), randf_range(40, 90)), Vector2(10, 10), {"hue": randf()})
			for d in b.bullets:
				var p: Vector2 = d["pos"]
				var v: Vector2 = d["vel"]
				if p.x < box.position.x + 6 or p.x > box.end.x - 6:
					v.x = -v.x
				if p.y < box.position.y + 6 or p.y > box.end.y - 6:
					v.y = -v.y
				d["vel"] = v
				d["pos"] = p.clamp(box.position + Vector2(6, 6), box.end - Vector2(6, 6))
			if _every(b, 1.6) and b.bullets.size() < 6:
				_spawn(b, "ball", Vector2(box.get_center().x, box.position.y + 8),
					Vector2(randf_range(-90, 90), 80), Vector2(10, 10), {"hue": randf()})
		"books":
			if _every(b, 0.14):
				var a := PI / 2.0 + sin(t * 2.2) * 1.1
				_spawn(b, "book", Vector2(box.get_center().x, box.position.y - 6), Vector2(cos(a), sin(a)) * 105.0, Vector2(10, 8))
		"coffee":
			if _every(b, 0.22):
				var left := randf() < 0.5
				_spawn(b, "drop", Vector2(box.position.x + 4 if left else box.end.x - 4, box.end.y),
					Vector2(randf_range(30, 90) * (1 if left else -1), randf_range(-190, -150)), Vector2(6, 8), {"acc": Vector2(0, 230)})
		"stains":
			# macchie che compaiono sul pavimento: prima un alone innocuo, poi diventano pericolose
			if _every(b, 0.42):
				var p := Vector2(randf_range(box.position.x + 12, box.end.x - 12), randf_range(box.position.y + 12, box.end.y - 12))
				_spawn(b, "stain", p, Vector2.ZERO, Vector2(16, 12), {"harmless": true, "life": 1.6})
			for d in b.bullets:
				if d["type"] == "stain":
					d["harmless"] = float(d["t"]) < 0.7
		"notifications":
			if _every(b, 0.5):
				var p := Vector2(randf_range(box.position.x + 14, box.end.x - 14), randf_range(box.position.y + 14, box.end.y - 14))
				_spawn(b, "ping", p, Vector2.ZERO, Vector2(18, 18), {"harmless": true, "life": 1.2})
			for d in b.bullets:
				d["harmless"] = float(d["t"]) < 0.6
		"keys":
			if b.bullets.is_empty():
				for i in 2:
					_spawn(b, "key", box.get_center(), Vector2.ZERO, Vector2(10, 10), {"phase": i * PI})
			for d in b.bullets:
				var ang := sin(t * 2.4 + float(d["phase"])) * 1.25
				var pivot := Vector2(box.get_center().x, box.position.y - 20)
				d["vel"] = Vector2.ZERO
				d["pos"] = pivot + Vector2(sin(ang), cos(ang)) * (box.size.y + 6)
		"postits":
			if _every(b, 0.3):
				var d := _spawn(b, "postit", Vector2(randf_range(box.position.x + 8, box.end.x - 8), box.position.y - 8),
					Vector2(0, 65), Vector2(10, 10))
				d["wave"] = randf() * TAU
			for d in b.bullets:
				if d["type"] == "postit":
					d["vel"] = Vector2(sin(float(d["t"]) * 4.0 + float(d["wave"])) * 70.0, 65.0)
		"papers":
			if _every(b, 1.0):
				var gap := 30.0
				var gy := randf_range(box.position.y + 8, box.end.y - 8 - gap)
				var x := box.end.x + 8
				var top_h := gy - box.position.y
				var bot_h := box.end.y - gy - gap
				_spawn(b, "paper", Vector2(x, box.position.y + top_h / 2.0), Vector2(-95, 0), Vector2(10, top_h))
				_spawn(b, "paper", Vector2(x, gy + gap + bot_h / 2.0), Vector2(-95, 0), Vector2(10, bot_h))
		"rain":
			if _every(b, 0.05):
				_spawn(b, "rain", Vector2(randf_range(box.position.x, box.end.x + 30), box.position.y - 6),
					Vector2(-40, 210), Vector2(2, 6))
		"camera":
			if _every(b, 1.4):
				var left := randf() < 0.5
				_spawn(b, "beam", Vector2(box.position.x - 6 if left else box.end.x + 6, box.get_center().y),
					Vector2(110 if left else -110, 0), Vector2(10, box.size.y), {"blue": true})
			if _every(b, 0.5) and randf() < 0.4:
				_spawn(b, "mail", Vector2(box.position.x - 10, randf_range(box.position.y + 8, box.end.y - 8)),
					Vector2(120, 0), Vector2(14, 10))


static func draw_all(b: Node2D, bullets: Array[Dictionary]) -> void:
	var box: Rect2 = b.box
	for d in bullets:
		var p: Vector2 = (d["pos"] as Vector2).round()
		if not box.grow(2).has_point(p):
			continue
		var s: Vector2 = d["size"]
		var r := Rect2(p - s / 2.0, s)
		match str(d["type"]):
			"bill":
				b.draw_rect(r, Color("f2f0e6"))
				b.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(8, 1)), Color("8a8494"))
				b.draw_rect(Rect2(r.position + Vector2(2, 5), Vector2(6, 1)), Color("8a8494"))
				b.draw_rect(Rect2(r.end - Vector2(5, 4), Vector2(3, 3)), Color("d0302f"))
			"mail":
				b.draw_rect(r, Color.WHITE)
				b.draw_line(r.position, r.get_center(), Color("8a8494"), 1.0)
				b.draw_line(Vector2(r.end.x, r.position.y), r.get_center(), Color("8a8494"), 1.0)
			"box":
				b.draw_rect(r, Color("b9894f"))
				b.draw_rect(Rect2(r.position + Vector2(s.x / 2 - 2, 0), Vector2(4, s.y)), Color("e8d29a"))
				b.draw_rect(r, Color("5c3f22"), false, 1.0)
			"car":
				b.draw_rect(r, Color("d23b3b"))
				b.draw_rect(Rect2(r.position + Vector2(8, 3), Vector2(s.x - 16, 5)), Color("9fd0f0"))
				b.draw_rect(Rect2(r.position + Vector2(4, s.y - 3), Vector2(6, 3)), Color.BLACK)
				b.draw_rect(Rect2(r.end - Vector2(10, 3), Vector2(6, 3)), Color.BLACK)
			"pigeon":
				b.draw_rect(r, Color("9a9aa8"))
				var wing := 3.0 if int(float(d["t"]) * 10) % 2 == 0 else -3.0
				b.draw_rect(Rect2(r.position + Vector2(2, wing), Vector2(6, 3)), Color("c8c8d4"))
				b.draw_rect(Rect2(r.position + Vector2(s.x - 2, 2), Vector2(2, 2)), Color("ffb03a"))
			"crumb":
				b.draw_rect(r, Color("e0b878"))
			"ball":
				b.draw_circle(p, s.x / 2.0, Color.from_hsv(float(d["hue"]), 0.7, 1.0))
			"book":
				b.draw_rect(r, Color("3f6fd8"))
				b.draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(2, s.y - 2)), Color.WHITE)
			"drop":
				b.draw_rect(r, Color("7a4a26"))
			"ping":
				var warn: bool = d["harmless"]
				var col := Color(1, 0.3, 0.3, 0.35 if warn else 1.0)
				if warn and int(float(d["t"]) * 10) % 2 == 0:
					col.a = 0.1
				b.draw_circle(p, s.x / 2.0, col)
				b.draw_rect(Rect2(p + Vector2(-1, -5), Vector2(2, 6)), Color.WHITE)
				b.draw_rect(Rect2(p + Vector2(-1, 3), Vector2(2, 2)), Color.WHITE)
			"stain":
				var warn2: bool = d["harmless"]
				var sc := Color("6b4a1e")
				sc.a = 0.35 if warn2 else 1.0
				b.draw_circle(p, 7.0, sc)
				b.draw_circle(p + Vector2(5, 2), 4.0, sc)
				b.draw_circle(p + Vector2(-5, 3), 3.0, sc)
			"key":
				b.draw_circle(p + Vector2(-3, 0), 3.0, Color("f0c040"))
				b.draw_rect(Rect2(p + Vector2(0, -1), Vector2(6, 2)), Color("f0c040"))
			"postit":
				b.draw_rect(r, Color("ffe14d"))
				b.draw_rect(Rect2(r.position, Vector2(s.x, 2)), Color("e0b020"))
			"paper":
				b.draw_rect(r, Color("f2f0e6"))
				var y := r.position.y + 3
				while y < r.end.y - 2:
					b.draw_rect(Rect2(r.position.x + 1, y, s.x - 2, 1), Color("c8c4b8"))
					y += 4
			"rain":
				b.draw_rect(r, Color("7fb8ff"))
			"beam":
				b.draw_rect(r, Color(0.22, 0.71, 1.0, 0.85))
			_:
				b.draw_rect(r, Color.WHITE)
