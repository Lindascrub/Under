@tool
class_name PulsanteTocco
extends Control
## Un comando del telefono disegnato come sullo schermo di gioco (autoload/touch_controls.gd):
## un pulsante tondo con la scritta, o il joystick (cerchio grande con il pomello dentro).
## Usato dalla pagina "Comandi" del telefono (scenes/comandi_telefono.tscn). Grande quanto la sua "size".

## Cosa c'è scritto dentro (OK, X, C). Vuoto per il joystick.
@export var scritta := "":
	set(value):scritta=value;queue_redraw()
## Disegna il joystick invece di un pulsante.
@export var joystick := false:
	set(value):joystick=value;queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 1.0
	draw_circle(c, r, Color(1, 1, 1, 0.18))
	draw_arc(c, r, 0, TAU, 32, Color(1, 1, 1, 0.6), 2.0)
	if joystick:
		draw_circle(c, r * 0.42, Color(1, 1, 1, 0.45))
		return
	var font := get_theme_default_font()
	var fs := int(r * 0.8)
	draw_string(font, Vector2(0, c.y + fs * 0.35), scritta, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Color(1, 1, 1, 0.9))
