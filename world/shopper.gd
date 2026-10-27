@tool
class_name Shopper
extends StaticBody2D
## Una comparsa che gira per la stanza (chi fa la spesa, chi aspetta in banca): va da un punto all'altro
## di `route`, a ogni punto si ferma a guardare (lo scaffale, il tabellone), poi riparte.
## Non ti passa attraverso: se sei davanti, o le sei vicino, si ferma. Toccandola dice una frase.

## Il foglio LimeZu ("char_07") e se è grigia (le persone vere, nei piani colorati e finti).
@export var sheet := "char_07":
	set(v):
		sheet = v
		_refresh()
@export var grey := false:
	set(v):
		grey = v
		_refresh()
## Il giro: punti (in pixel, coordinate della stanza) da visitare in ordine, poi si ricomincia.
@export var route: PackedVector2Array = []
## Dove guarda quando si ferma a ogni punto ("up" = lo scaffale contro il muro).
@export var look := "up"
@export var lines: PackedStringArray = []
@export var who := "Cliente"

const SPEED := 22.0
var _sprite: AnimatedSprite2D
var _next := 0
var _wait := 0.0
var _line := 0
var _stuck := 0


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	add_to_group("interactable")
	add_to_group("walker")
	var shadow := Sprite2D.new()
	shadow.texture = Assets.shadow()
	shadow.position = Vector2(0, -1)
	add_child(shadow)
	move_child(shadow, 0)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 6)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -3)
	add_child(col)
	_wait = randf_range(0.5, 3.0)
	_line = randi() % maxi(lines.size(), 1)
	if not route.is_empty():
		_next = randi() % route.size()


func _refresh() -> void:
	if not is_inside_tree():
		return
	if _sprite == null:
		_sprite = AnimatedSprite2D.new()
		_sprite.centered = false
		_sprite.offset = Vector2(-8, -31)
		add_child(_sprite)
	_sprite.sprite_frames = Assets.character(sheet)
	_sprite.play("idle_" + look)
	_sprite.material = null
	if grey:
		var m := ShaderMaterial.new()
		m.shader = preload("res://shaders/greyscale.gdshader")
		_sprite.material = m


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or route.is_empty():
		return
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if Ui.blocks_input() or (p != null and p.global_position.distance_to(global_position) < 26):
		_idle()
		return
	if _wait > 0.0:
		_wait -= delta
		return
	var to := route[_next] - position
	if to.length() < 1.0:
		# arrivata: guarda lo scaffale, poi il prossimo punto
		_sprite.play("idle_" + look)
		_wait = randf_range(2.0, 5.0)
		_next = (_next + 1) % route.size()
		return
	# un passo alla volta, prima in orizzontale e poi in verticale (come si cammina tra gli scaffali)
	var step := Vector2(signf(to.x), 0.0) if absf(to.x) >= 1.0 else Vector2(0.0, signf(to.y))
	if test_move(global_transform, step * 3.0):
		# c'è qualcuno (o qualcosa) davanti: aspetta un momento; se non si libera, cambia meta
		_idle()
		_wait = 0.6
		_stuck += 1
		if _stuck > 6:
			_stuck = 0
			_next = (_next + 1) % route.size()
		return
	_stuck = 0
	var amount := minf(SPEED * delta, absf(to.x) if step.x != 0.0 else absf(to.y))
	position += step * amount
	var anim := "walk_" + _dir(step)
	if _sprite.animation != anim:
		_sprite.play(anim)


func _idle() -> void:
	if _sprite.animation.begins_with("walk"):
		_sprite.play("idle_" + _sprite.animation.trim_prefix("walk_"))


func _dir(v: Vector2) -> String:
	if absf(v.x) > absf(v.y):
		return "right" if v.x > 0 else "left"
	return "down" if v.y > 0 else "up"


func hotspot() -> Vector2:
	return global_position + Vector2(0, -8)


func interact() -> void:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p:
		_sprite.play("idle_" + _dir(p.global_position - global_position))
	if lines.is_empty():
		return
	await Ui.say([lines[_line % lines.size()]], who, sheet)
	_line += 1
