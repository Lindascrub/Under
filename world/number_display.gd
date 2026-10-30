@tool
extends Node2D
## Tabellone della fila: testo disegnato col font del gioco, leggibile anche da vicino.

@export_range(0, 999, 1) var number := 4:
	set(value):
		number = value
		queue_redraw()

func _draw() -> void:
	var panel := Rect2(0, -20, 64, 20)
	draw_rect(panel, Color("25313a"))
	draw_rect(panel.grow(-1), Color("b0b8bc"), false, 1.0)
	draw_line(Vector2(41, -18), Vector2(41, -2), Color("53616c"), 1.0)
	var font := Assets.font()
	draw_string(font, Vector2(4, -11), "NUMERO", HORIZONTAL_ALIGNMENT_LEFT, 36, 6, Color("e5ece7"))
	draw_string(font, Vector2(4, -3), "SERVITO", HORIZONTAL_ALIGNMENT_LEFT, 36, 6, Color("e5ece7"))
	draw_string(font, Vector2(43, -2), str(number), HORIZONTAL_ALIGNMENT_CENTER, 17, 18, Color("ffad90"))
