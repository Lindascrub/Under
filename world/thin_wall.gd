@tool
class_name ThinWall
extends StaticBody2D
## Un muro sottile (tramezzo) con il bordo bianco in cima, come i muri tagliati di LimeZu.
## Il disegno segue la sua CollisionShape2D figlia ("Forma"): nell'editor sposti il nodo o
## tiri le maniglie della forma, e il muro si allunga/accorcia con la collisione.
## Se è largo almeno 16 px si vede anche la faccia davanti.

const INK := Color("34313f")
const CAP := Color("f4f2ee")
const FACE := Color("aaaeb3")
const SIDE := Color("7e828b")

var _last := Rect2()


func _ready() -> void:
	set_meta("prop_talk_skip", true)
	queue_redraw()


func _rect() -> Rect2:
	var shape := get_node_or_null("Forma") as CollisionShape2D
	if shape == null or not shape.shape is RectangleShape2D:
		return Rect2()
	var size: Vector2 = (shape.shape as RectangleShape2D).size
	return Rect2(shape.position - size / 2.0, size)


func _process(_delta: float) -> void:
	# nell'editor: ridisegna quando cambi la forma
	if Engine.is_editor_hint() and _rect() != _last:
		queue_redraw()


func _draw() -> void:
	var r := _rect()
	_last = r
	if r.size == Vector2.ZERO:
		return
	draw_rect(r, INK)
	draw_rect(r.grow(-1), CAP)
	if r.size.x >= 16:
		draw_rect(Rect2(r.position + Vector2(2, 6), r.size - Vector2(4, 7)), FACE)
		draw_rect(Rect2(r.position + Vector2(r.size.x - 3, 6), Vector2(2, r.size.y - 7)), SIDE)
		draw_line(r.position + Vector2(1, 5), r.position + Vector2(r.size.x - 2, 5), INK, 1)
