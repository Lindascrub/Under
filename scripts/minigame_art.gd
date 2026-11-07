extends RefCounted
const Products := preload("res://scripts/product_art.gd")
## Presentation only. Coordinates stay inside each minigame's existing hit areas.

const INK := Color("241d32")
const CREAM := Color("fff0cd")
const GOLD := Color("f4c85c")
const STEEL := Color("8b9eae")
const TEAL := Color("326e78")

static func panel(ci: CanvasItem, r: Rect2, base := Color("24313e"), trim := STEEL) -> void:
	ci.draw_rect(r, INK)
	ci.draw_rect(r.grow(-2), base)
	ci.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 2)), trim)
	ci.draw_rect(Rect2(r.position + Vector2(2, 4), Vector2(1, r.size.y - 7)), base.lightened(0.2))
	ci.draw_rect(Rect2(r.position + Vector2(3, r.size.y - 4), Vector2(r.size.x - 6, 2)), base.darkened(0.45))
	if r.size.x > 60 and r.size.y > 24:
		for x in [r.position.x + 6, r.end.x - 7]:
			for y in [r.position.y + 7, r.end.y - 8]:
				ci.draw_rect(Rect2(x, y, 2, 2), trim)

static func backdrop(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 640, 360), Color("171d2a"))
	ci.draw_rect(Rect2(0, 0, 640, 4), TEAL)
	ci.draw_rect(Rect2(0, 354, 640, 6), Color("101622"))
	for x in range(20, 640, 40):
		ci.draw_rect(Rect2(x, 344, 18, 1), Color("293747"))

static func pixel(ci: CanvasItem, at: Vector2, pattern: Array, palette: Dictionary, unit := 1.0) -> void:
	var origin := at.round()
	for y in pattern.size():
		var row: String = pattern[y]
		for x in row.length():
			var key := row.substr(x, 1)
			if palette.has(key):
				ci.draw_rect(Rect2(origin + Vector2(x, y) * unit, Vector2.ONE * unit), palette[key])

## La lampadina: sempre l'immagine a pixel art/lampadina_cassetta.png (quella del Fondo), ingrandita
## a pixel interi. Accesa = colori veri; spenta = scura; rotta = scura con la crepa.
const LAMPADINA := preload("res://art/lampadina_cassetta.png")

static func bulb(ci: CanvasItem, c: Vector2, state := "buona", unit := 2.0, lit := true) -> void:
	var k := maxf(1.0, roundf(unit * 2.0))
	var size := Vector2(LAMPADINA.get_width(), LAMPADINA.get_height()) * k
	var at := (c - size / 2.0).round()
	var col := Color.WHITE if lit and state != "rotta" else (Color(0.38, 0.38, 0.44) if state == "rotta" else Color(0.55, 0.57, 0.65))
	ci.draw_texture_rect(LAMPADINA, Rect2(at, size), false, col)
	if state == "rotta":
		ci.draw_polyline(PackedVector2Array([at + Vector2(1, 1) * k, at + Vector2(3, 2.5) * k, at + Vector2(2, 3.5) * k, at + Vector2(4.5, 5) * k]), INK, maxf(1, k * 0.6))
	elif lit and state != "rotta" and k >= 2.0:
		for side in [-1, 1]:
			ci.draw_rect(Rect2(c + Vector2(side * (size.x / 2.0 + k * 1.5) - k * 0.75, -size.y * 0.25), Vector2(k * 1.5, k * 0.5)), GOLD)

static func carton(ci: CanvasItem, r: Rect2, label := GOLD, open := false) -> void:
	ci.draw_rect(r, INK)
	ci.draw_rect(r.grow(-1), Color("bd8755"))
	ci.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, maxf(2, r.size.y * 0.23))), Color("e3b478"))
	ci.draw_rect(Rect2(r.get_center().x - 2, r.position.y + 1, 4, r.size.y - 2), Color("ead29b"))
	ci.draw_rect(Rect2(r.end.x - 3, r.position.y + 2, 2, r.size.y - 3), Color("8e5d43"))
	if r.size.x >= 20:
		ci.draw_rect(Rect2(r.position + Vector2(4, r.size.y * 0.48), Vector2(maxf(5, r.size.x * 0.3), maxf(3, r.size.y * 0.22))), label)
	if open:
		ci.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 5)), Color("6a4940"))
		ci.draw_rect(Rect2(r.position + Vector2(-2, -2), Vector2(r.size.x * 0.44, 4)), Color("e3b478"))
		ci.draw_rect(Rect2(r.position + Vector2(r.size.x * 0.58, -2), Vector2(r.size.x * 0.44, 4)), Color("e3b478"))

static func phone(ci: CanvasItem, c: Vector2, lit := false, tint := CREAM) -> void:
	var p := c.round() - Vector2(24, 16)
	var body := GOLD if lit else tint
	ci.draw_rect(Rect2(p + Vector2(3, 11), Vector2(42, 22)), INK)
	ci.draw_rect(Rect2(p + Vector2(5, 12), Vector2(38, 18)), body)
	ci.draw_rect(Rect2(p + Vector2(6, 13), Vector2(36, 2)), body.lightened(0.2))
	ci.draw_rect(Rect2(p + Vector2(5, 28), Vector2(38, 3)), body.darkened(0.3))
	ci.draw_rect(Rect2(p + Vector2(0, 2), Vector2(48, 10)), INK)
	ci.draw_rect(Rect2(p + Vector2(2, 1), Vector2(12, 14)), INK)
	ci.draw_rect(Rect2(p + Vector2(34, 1), Vector2(12, 14)), INK)
	ci.draw_rect(Rect2(p + Vector2(3, 3), Vector2(42, 6)), body)
	ci.draw_rect(Rect2(p + Vector2(4, 3), Vector2(9, 10)), body)
	ci.draw_rect(Rect2(p + Vector2(35, 3), Vector2(9, 10)), body)
	ci.draw_rect(Rect2(p + Vector2(5, 3), Vector2(38, 2)), body.lightened(0.25))
	for y in 3:
		for x in 3:
			ci.draw_rect(Rect2(p + Vector2(15 + x * 7, 16 + y * 4), Vector2(5, 3)), Color("526075"))
	for y in 4:
		ci.draw_rect(Rect2(p + Vector2(44 + y % 2 * 2, 17 + y * 3), Vector2(3, 2)), INK)
	if lit:
		for s in [-1, 1]:
			ci.draw_line(c + Vector2(s * 29, -12), c + Vector2(s * 34, -17), GOLD, 2)
			ci.draw_line(c + Vector2(s * 30, -4), c + Vector2(s * 37, -5), GOLD, 2)

static func product(ci: CanvasItem, r: Rect2, name: String) -> void:
	Products.draw(ci, r, name)

static func cable(ci: CanvasItem, points: PackedVector2Array, color: Color, width := 3.0, tips := false) -> void:
	if points.size() < 2: return
	var snapped := PackedVector2Array()
	for p in points: snapped.append(p.round())
	ci.draw_polyline(snapped, INK, width + 2, false)
	ci.draw_polyline(snapped, color, width, false)
	if tips:
		for i in [0, snapped.size() - 1]:
			var p := snapped[i]
			var other := snapped[1] if i == 0 else snapped[snapped.size() - 2]
			var dir := (p - other).normalized()
			ci.draw_line(p - dir * 2, p + dir * 1, Color("38424d"), width + 2)
			ci.draw_line(p + dir, p + dir * 4, Color("d8a46c"), maxf(1, width - 1))

static func lead(ci: CanvasItem, a: Vector2, b: Vector2, color: Color, width := 3.0) -> void:
	var points := PackedVector2Array()
	for i in 21:
		var k := i / 20.0
		var p := a.lerp(b, k)
		p.y += sin(k * PI) * 8
		points.append(p)
	cable(ci, points, color, width)

static func paper(ci: CanvasItem, r: Rect2, base := Color("f4efdc")) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(2, 3), r.size), INK)
	ci.draw_rect(r, Color("a9977d"))
	ci.draw_rect(r.grow(-1), base)
	ci.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 8, 2)), CREAM)
	ci.draw_rect(Rect2(r.end.x - 7, r.position.y + 1, 6, 6), Color("d7cbb0"))
	ci.draw_line(Vector2(r.end.x - 7, r.position.y + 1), Vector2(r.end.x - 1, r.position.y + 7), Color("9d8c76"), 1)

static func collectible(ci: CanvasItem, c: Vector2, color: Color, title: String) -> void:
	if title.to_lower().contains("croccant"):
		pixel(ci, c - Vector2(4, 3), ["..####..", ".#llrr#.", "#lrrrrd#", "#rrrrrd#", ".#rddd#.", "..####.."], {"#": INK, "r": color, "l": color.lightened(0.3), "d": color.darkened(0.3)})
	else:
		pixel(ci, c - Vector2(4, 4), ["....gg..", "..gggg..", ".gggld..", "gggld...", ".gld....", "..d....."], {"g": color, "l": color.lightened(0.3), "d": color.darkened(0.3)})
