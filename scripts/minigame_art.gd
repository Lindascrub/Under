extends RefCounted
const Products := preload("res://scripts/product_art.gd")
## Presentation only. Coordinates stay inside each minigame's existing hit areas.

const INK := Color("241d32")
const CREAM := Color("fff0cd")
const GOLD := Color("f4c85c")
const STEEL := Color("8b9eae")
const TEAL := Color("326e78")
const GENERATOR: Texture2D = preload("res://art/generator.png")
const FURNITURE := {
	"tavolo": preload("res://art/c5/tavolo_lungo.png"),
	"scaffale": preload("res://art/c5/libreria.png"),
	"sedie": preload("res://art/c5/sedie_spaiate.png"),
}

static func furniture(ci: CanvasItem, r: Rect2, kind: String) -> void:
	var tex: Texture2D = FURNITURE.get(kind, FURNITURE["tavolo"])
	var k := minf(r.size.x / tex.get_width(), r.size.y / tex.get_height())
	var size := (tex.get_size() * k).floor()
	ci.draw_texture_rect(tex, Rect2((r.get_center() - size / 2).floor(), size), false)

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

static func bulb(ci: CanvasItem, c: Vector2, state := "buona", unit := 2.0, lit := true) -> void:
	var glass := Color("f4cc59") if lit else Color("8d93a3")
	if state == "rotta": glass = Color("858895")
	var pattern := [".....####.....", "...##hhhh##...", "..#hhhhhhhg#..", ".#hWWhhhhhhg#.", ".#hWhhhhhhhg#.", "#hhhhhhhhhhgs#", "#hhhhhhhhhhgs#", "#hhhffhffhhgs#", ".#hhhfFfhhgs#.", ".#hhhhFhhhgs#.", "..#hhhFhhgs#..", "...#hhFhgs#...", "...########...", "....#mmmm#....", "....#llll#....", "....#mmmm#....", "....#llll#....", ".....#mm#.....", "......##......"]
	var colors := {"#": INK, "h": glass, "g": glass.darkened(0.17), "s": glass.darkened(0.34), "W": CREAM if lit else Color("b8c3cc"), "f": Color("a77640"), "F": CREAM if lit else INK, "m": STEEL, "l": Color("d2dce0")}
	pixel(ci, c - Vector2(7, 9) * unit, pattern, colors, unit)
	if state == "rotta":
		ci.draw_polyline(PackedVector2Array([c + Vector2(-3, -5) * unit, c + Vector2(1, -2) * unit, c + Vector2(-1, 1) * unit, c + Vector2(3, 3) * unit]), INK, maxf(1, unit))
	elif lit and unit >= 1.0:
		for side in [-1, 1]:
			ci.draw_rect(Rect2(c + Vector2(side * 10 - 1, -3) * unit, Vector2(3, 1) * unit), GOLD)

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

static func sponge(ci: CanvasItem, c: Vector2) -> void:
	var r := Rect2(c.round() - Vector2(10, 7), Vector2(20, 14))
	ci.draw_rect(r.grow(1), INK)
	ci.draw_rect(r, GOLD)
	ci.draw_rect(Rect2(r.position, Vector2(20, 4)), Color("4b9174"))
	ci.draw_rect(Rect2(r.position + Vector2(1, 4), Vector2(18, 2)), CREAM)
	for p in [Vector2(4, 9), Vector2(11, 7), Vector2(15, 11)]:
		ci.draw_rect(Rect2(r.position + p, Vector2(2, 2)), Color("c28b47"))
	ci.draw_rect(Rect2(r.position + Vector2(1, 12), Vector2(18, 2)), Color("c28b47"))

static func stain(ci: CanvasItem, c: Vector2, radius: float, color := Color("725144")) -> void:
	var p := c.round()
	ci.draw_rect(Rect2(p - Vector2(radius, radius * 0.4), Vector2(radius * 2, radius * 0.8)), color)
	ci.draw_rect(Rect2(p - Vector2(radius * 0.65, radius * 0.7), Vector2(radius * 1.35, radius * 1.4)), color)
	ci.draw_rect(Rect2(p + Vector2(radius * 0.7, radius * 0.25), Vector2(radius * 0.6, radius * 0.35)), color)
	ci.draw_rect(Rect2(p - Vector2(radius * 0.4, radius * 0.3), Vector2(radius * 0.5, 2)), color.lightened(0.18))

static func fruit(ci: CanvasItem, c: Vector2, color := Color("dc5b4a"), unit := 1.0) -> void:
	pixel(ci, c - Vector2(6, 7) * unit, ["......ss....", ".....ssgg...", ".....sggg...", "..###s###...", ".#rrrlrrr#..", "#rllrrrrrr#.", "#rlrrrrrrr#.", "#rrrrrrrrd#.", "#rrrrrrrrd#.", ".#rrrrrrd#..", "..##rrd##...", "....###....."], {"#": INK, "r": color, "l": color.lightened(0.3), "d": color.darkened(0.3), "s": Color("765343"), "g": Color("65996e")}, unit)

static func product(ci: CanvasItem, r: Rect2, name: String) -> void:
	Products.draw(ci, r, name)

static func car(ci: CanvasItem, r: Rect2, color := Color("d75a58")) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(4, -2), Vector2(r.size.x - 8, r.size.y + 4)), INK)
	ci.draw_rect(r, INK)
	ci.draw_rect(r.grow(-1), color)
	ci.draw_rect(Rect2(r.position + Vector2(8, 2), Vector2(r.size.x - 16, r.size.y - 4)), Color("9fd0dd"))
	ci.draw_rect(Rect2(r.position + Vector2(15, 3), Vector2(r.size.x - 27, r.size.y - 6)), color.darkened(0.22))
	ci.draw_rect(Rect2(r.position + Vector2(3, 2), Vector2(3, 3)), CREAM)
	ci.draw_rect(Rect2(r.position + Vector2(3, r.size.y - 5), Vector2(3, 3)), CREAM)
	ci.draw_rect(Rect2(r.end.x - 4, r.position.y + 2, 2, 3), Color("983b47"))

static func courier(ci: CanvasItem, c: Vector2, t: float) -> void:
	for dx in [-11, 11]:
		ci.draw_circle(c + Vector2(dx, 7), 7, INK)
		ci.draw_circle(c + Vector2(dx, 7), 5, STEEL)
		ci.draw_circle(c + Vector2(dx, 7), 3, INK)
	var points := PackedVector2Array([c + Vector2(-11, 7), c + Vector2(-4, -4), c + Vector2(5, 7), c + Vector2(11, 7), c + Vector2(5, -8), c + Vector2(-4, -4)])
	ci.draw_polyline(points, INK, 4)
	ci.draw_polyline(points, GOLD, 2)
	ci.draw_rect(Rect2(c + Vector2(-3, -24), Vector2(9, 9)), INK)
	ci.draw_rect(Rect2(c + Vector2(-1, -23), Vector2(6, 7)), Color("e4b893"))
	ci.draw_rect(Rect2(c + Vector2(-4, -25), Vector2(11, 3)), Color("5699b2"))
	ci.draw_line(c + Vector2(0, -15), c + Vector2(-3, -6), Color("5699b2"), 6)
	ci.draw_line(c + Vector2(-3, -7), c + Vector2(3, 2 + sin(t * 12) * 2), Color("4f526f"), 3)
	ci.draw_line(c + Vector2(1, -13), c + Vector2(8, -8), Color("e4b893"), 2)
	carton(ci, Rect2(c + Vector2(-20, -9), Vector2(11, 10)), CREAM)

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

static func coin(ci: CanvasItem, c: Vector2, unit := 1.0) -> void:
	pixel(ci, c - Vector2(6, 6) * unit, ["...######...", "..#yyyyyy#..", ".#yyhhhyyy#.", "#yyhhyyyyyd#", "#yhyyyyyyyd#", "#yhyyhhhyyd#", "#yhyyhyyyyd#", "#yyyyhhhyyd#", "#yyyyyyyyyd#", ".#yyyyyydd#.", "..#yddddd#..", "...######..."], {"#": INK, "y": GOLD, "h": CREAM, "d": Color("bd8548")}, unit)

static func collectible(ci: CanvasItem, c: Vector2, color: Color, title: String) -> void:
	if title.to_lower().contains("croccant"):
		pixel(ci, c - Vector2(4, 3), ["..####..", ".#llrr#.", "#lrrrrd#", "#rrrrrd#", ".#rddd#.", "..####.."], {"#": INK, "r": color, "l": color.lightened(0.3), "d": color.darkened(0.3)})
	else:
		pixel(ci, c - Vector2(4, 4), ["....gg..", "..gggg..", ".gggld..", "gggld...", ".gld....", "..d....."], {"g": color, "l": color.lightened(0.3), "d": color.darkened(0.3)})
