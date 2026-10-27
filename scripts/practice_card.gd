class_name PracticeCard
const Art := preload("res://scripts/minigame_art.gd")
## Il foglio di una pratica di credito, disegnato uguale allo sportello della Banca (TURNO, work.gd)
## e nella PRATICA IMPOSSIBILE di Teo (minigame.gd). Dati in data/bank.json.

const PAPER := Color("f4f1e6")
const INK := Color("2a2633")
const FAINT := Color("8a8494")


## `stamp` (facoltativo) è il timbro sopra il foglio: "APPROVATA", "IN VERIFICA"...
static func draw(ci: CanvasItem, r: Rect2, p: Dictionary, font: Font, stamp := "", stamp_col := Color("c0302a")) -> void:
	Art.paper(ci, r, PAPER)
	var title := "PRATICA N. %s" % str(p.get("id", "000"))
	if p.has("nome"):
		title += " — " + str(p["nome"]).to_upper()
	ci.draw_string(font, r.position + Vector2(10, 18), title, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 20, 11, INK)
	ci.draw_line(r.position + Vector2(10, 24), r.position + Vector2(r.size.x - 10, 24), FAINT, 1.0)
	var y := r.position.y + 42
	for line: String in p.get("righe", []):
		ci.draw_string(font, Vector2(r.position.x + 12, y), line, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 24, 10, INK)
		y += 17
	if stamp != "":
		var c := r.get_center() + Vector2(r.size.x * 0.18, 8)
		ci.draw_set_transform(c, -0.18)
		var w := 150.0
		ci.draw_rect(Rect2(-w / 2.0, -16, w, 28), stamp_col, false, 3.0)
		ci.draw_string(font, Vector2(-w / 2.0, 4), stamp, HORIZONTAL_ALIGNMENT_CENTER, w, 14, stamp_col)
		ci.draw_set_transform(Vector2.ZERO)


## Un bottone grande, comodo per il dito.
static func button(ci: CanvasItem, r: Rect2, text: String, col: Color, font: Font, selected := false, size := 13) -> void:
	Art.panel(ci, r, col, Color("ffe14d") if selected else col.lightened(0.4))
	if selected: ci.draw_rect(r.grow(-1), Color("ffe14d"), false, 2.0)
	var lines := text.split("\n")
	var y := r.get_center().y + 5 - (lines.size() - 1) * (size + 2) / 2.0
	for l in lines:
		ci.draw_string(font, Vector2(r.position.x, y), l, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, size, Color.WHITE)
		y += size + 2
