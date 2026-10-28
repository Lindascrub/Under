class_name Lift
extends Node2D
## L'ascensore di LimeZu (quello della stazione): due caselle di parete con le porte che si aprono
## e si chiudono davvero (14 fotogrammi: si apre fino al 7, poi si richiude), la freccia verde sopra.
## Rotto o fuori servizio: le luci spente. Il nodo sta nell'angolo in alto a sinistra.

const SHEET := "res://assets/limezu/tiles/elevator_anim.png"
const OFF := "res://assets/limezu/tiles/elevator_off.png"
const OPEN_FRAME := 7
const FPS := 12.0

var is_open := false
var _spr: Sprite2D
var _frame := 0
var _off := false


func _ready() -> void:
	_spr = Sprite2D.new()
	_spr.centered = false
	add_child(_spr)
	_show()


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


func _run(to: int, animate: bool) -> void:
	_off = false
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
	if _off and ResourceLoader.exists(OFF):
		_spr.texture = load(OFF)
		_spr.region_enabled = false
	elif ResourceLoader.exists(SHEET):
		_spr.texture = load(SHEET)
		_spr.region_enabled = true
		_spr.region_rect = Rect2(_frame * 32, 0, 32, 32)
