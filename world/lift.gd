@tool
class_name Lift
extends Node2D
## Ascensore in vetro originale LimeZu: 14 fotogrammi, apertura fino al 7 e richiusura.
## Fuori servizio mantiene le stesse porte, con la luce spenta.

const SHEET := "res://assets/limezu/animations/elevator_glass.png"
const OPEN_FRAME := 7
const FPS := 12.0

## Dentro è buio (la luce della cabina è spenta): tra le porte aperte si vede nero, non grigio.
@export var dark_inside := false:
	set(v):
		dark_inside = v
		queue_redraw()

var is_open := false
var _spr: Sprite2D
var _frame := 0
var _off := false


func _ready() -> void:
	_spr = Sprite2D.new()
	_spr.centered = false
	add_child(_spr)
	_show()
	queue_redraw()


func _draw() -> void:
	# Recessed jamb around the original animated glass doors, at native pixel scale.
	draw_rect(Rect2(-2, -2, 36, 35), Color("34313f"))
	draw_rect(Rect2(-1, -1, 34, 33), Color("999dad"))
	draw_rect(Rect2(0, -1, 32, 1), Color("e8e7ef"))
	if dark_inside or _off:
		draw_rect(Rect2(0, 0, 32, 32), Color("05040a"))


## Le porte si aprono (e restano aperte).
func open(animate := true) -> void:
	is_open = true
	await _run(OPEN_FRAME, animate)


## Le porte si chiudono.
func close(animate := true) -> void:
	is_open = false
	await _run(13, animate)
	_frame = 0
	_show()


## Le luci spente: l'ascensore non va (rotto, o serve un badge che non hai).
func set_off(off: bool) -> void:
	_off = off
	_show()
	queue_redraw()


func _run(to: int, animate: bool) -> void:
	_off = false
	queue_redraw()
	if not animate:
		_frame = to
		_show()
		return
	while _frame != to:
		_frame = (_frame + 1) % 14
		_show()
		await get_tree().create_timer(1.0 / FPS).timeout


func _show() -> void:
	if _spr == null:
		return
	if ResourceLoader.exists(SHEET):
		_spr.texture = load(SHEET)
		_spr.region_enabled = true
		_spr.region_rect = Rect2((0 if _off else _frame) * 32, 0, 32, 32)
		_spr.modulate = Color(0.65,0.66,0.71) if _off else Color.WHITE
