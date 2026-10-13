class_name Player
extends CharacterBody2D
## Il protagonista. Frecce per muoversi, X per correre, Z per interagire, C per lo stato.

const SPEED := 72.0
const RUN_SPEED := 115.0
const FACING_VECTORS := {
	"right": Vector2.RIGHT, "left": Vector2.LEFT, "up": Vector2.UP, "down": Vector2.DOWN,
}

var sheet := "char_01"
var facing := "down"
var camera: Camera2D
var _sprite: AnimatedSprite2D


func _ready() -> void:
	add_to_group("player")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shadow := Sprite2D.new()
	shadow.texture = Assets.shadow()
	shadow.position = Vector2(0, -1)
	add_child(shadow)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = Assets.character(sheet)
	_sprite.centered = false
	_sprite.offset = Vector2(-8, -31)
	add_child(_sprite)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 6)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -3)
	add_child(col)
	camera = Camera2D.new()
	camera.zoom = Vector2(2, 2)
	add_child(camera)
	camera.make_current()
	_sprite.play("idle_" + facing)


func _physics_process(_delta: float) -> void:
	var v := Vector2.ZERO
	if not Ui.blocks_input():
		v = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if v != Vector2.ZERO:
		if absf(v.x) > absf(v.y):
			facing = "right" if v.x > 0 else "left"
		else:
			facing = "down" if v.y > 0 else "up"
	var running := Input.is_action_pressed("cancel")
	velocity = v * (RUN_SPEED if running else SPEED)
	move_and_slide()
	var anim := ("walk_" if v != Vector2.ZERO else "idle_") + facing
	if _sprite.animation != anim:
		_sprite.play(anim)


func _unhandled_input(event: InputEvent) -> void:
	if Ui.blocks_input():
		return
	if event.is_action_pressed("confirm"):
		var target: Node = _find_target()
		if target:
			get_viewport().set_input_as_handled()
			target.call("interact")
	elif event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		Ui.show_status()


func face(dir: String) -> void:
	facing = dir
	_sprite.play("idle_" + dir)


## Cerca la cosa più vicina davanti al giocatore (gruppo "interactable", metodo hotspot()).
func _find_target() -> Node:
	var probe := global_position + Vector2(0, -6) + (FACING_VECTORS[facing] as Vector2) * 12.0
	var best: Node = null
	var best_d := 16.0
	for n in get_tree().get_nodes_in_group("interactable"):
		var d := probe.distance_to(n.call("hotspot"))
		if d < best_d:
			best_d = d
			best = n
	return best
