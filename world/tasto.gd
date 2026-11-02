@tool
class_name Tasto
extends Control
## Un tasto della tastiera disegnato (la pagina "Comandi" del menu iniziale).
## Il disegno è un pezzo del foglio dei tasti (assets/ui/tasti.png, non nel repository):
## "regione" dice quale pezzo; il nodo lo disegna grande quanto la sua "size".
## Se il foglio manca, disegna un tasto semplice con la "scritta".

## Il foglio con tutti i tasti.
@export_file("*.png") var foglio := "res://assets/ui/tasti.png":
	set(value):foglio=value;_tex=null;queue_redraw()
## Il pezzo del foglio con questo tasto (16 pixel di altezza).
@export var regione := Rect2(0, 0, 16, 16):
	set(value):regione=value;queue_redraw()
## Cosa c'è scritto sul tasto, se il foglio manca.
@export var scritta := "":
	set(value):scritta=value;queue_redraw()

var _tex: Texture2D


func _draw() -> void:
	if _tex == null and ResourceLoader.exists(foglio):
		_tex = load(foglio) as Texture2D
	var area := Rect2(Vector2.ZERO, size)
	if _tex:
		draw_texture_rect_region(_tex, area, regione)
		return
	draw_rect(area, Color("1b1b2b"))
	draw_rect(area.grow(-2), Color("a3a6c0"))
	draw_string(Assets.font(), Vector2(0, size.y * 0.5 + 4), scritta, HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, Color("1b1b2b"))
