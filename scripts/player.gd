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
var _step_t := 0.0
var _shadow: Sprite2D
var _sprite: AnimatedSprite2D


func _ready() -> void:
	add_to_group("player")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_shadow = Sprite2D.new()
	_shadow.texture = Assets.shadow()
	_shadow.position = Vector2(0, -1)
	add_child(_shadow)
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
	if v != Vector2.ZERO and velocity.length() > 1.0:
		_step_t -= _delta
		if _step_t <= 0.0:
			_step_t = 0.22 if running else 0.32
			Sound.sfx("step", randf_range(0.9, 1.1))
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


## Cammina sulle scale fino a `to`, un gradino alla volta. `fade_out`: la luce cala (stai
## lasciando il piano); altrimenti torna (stai arrivando).
func climb(to: Vector2, dir: String, fade_out: bool) -> void:
	facing = dir
	_sprite.play("walk_" + dir)
	_shadow.visible = false
	var t := 1.2
	var tw := create_tween()
	tw.tween_property(self, "position", to, t)
	tw.parallel().tween_property(_sprite, "modulate", Color(0.3, 0.3, 0.36) if fade_out else Color.WHITE, t)
	var steps := create_tween()
	for i in 5:
		steps.tween_callback(Sound.sfx.bind("step", 1.05 - i * 0.05))
		steps.tween_interval(t / 5.0)
	await tw.finished
	_shadow.visible = not fade_out
	_sprite.play("idle_" + dir)


## Cammina fino a `to` (senza fisica), guardando nella direzione in cui va.
func walk_to(to: Vector2) -> void:
	var delta_pos := to - position
	if delta_pos.length() < 1.0:
		return
	if absf(delta_pos.x) > absf(delta_pos.y):
		facing = "right" if delta_pos.x > 0 else "left"
	else:
		facing = "down" if delta_pos.y > 0 else "up"
	_sprite.play("walk_" + facing)
	var tw := create_tween()
	tw.tween_property(self, "position", to, delta_pos.length() / SPEED)
	await tw.finished
	_sprite.play("idle_" + facing)


## 0 = luce piena, 1 = buio (mentre fai le scale).
func set_shade(f: float) -> void:
	if _sprite:
		_sprite.modulate = Color.WHITE.lerp(Color(0.3, 0.3, 0.36), f)


func set_dark(dark: bool) -> void:
	if _sprite == null:
		await ready
	_sprite.modulate = Color(0.3, 0.3, 0.36) if dark else Color.WHITE


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
		# Se una persona e un oggetto sono nello stesso punto (Bruno sulla panchina), vince la persona.
		if n.is_in_group("npc") or n.is_in_group("walker"):
			d -= 6.0
		if d < best_d:
			best_d = d
			best = n
	return best


var _sleep_nodes: Array[Node] = []


## Si sdraia nel letto: la testa sul cuscino che respira, e sopra la coperta.
## `bed_top_left` è l'angolo in alto a sinistra dello sprite del letto.
func lie_down(bed_top_left: Vector2) -> void:
	get_up_instant()
	_sprite.visible = false
	_shadow.visible = false
	var head := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	var tex := Assets.tex("characters/%s.png" % sheet, Vector2i(896, 656))
	for i in 6:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * 16, 96, 16, 20)
		frames.add_frame("default", at)
	frames.set_animation_speed("default", 3.0)
	head.sprite_frames = frames
	head.centered = false
	head.top_level = true
	head.global_position = bed_top_left + Vector2(1, -1)
	head.z_index = 20
	head.play()
	add_child(head)
	var blanket := Sprite2D.new()
	var bt := AtlasTexture.new()
	bt.atlas = Assets.tex("props/bed.png", Vector2i(32, 48))
	bt.region = Rect2(0, 15, 32, 23)
	blanket.texture = bt
	blanket.centered = false
	blanket.top_level = true
	blanket.global_position = bed_top_left + Vector2(0, 15)
	blanket.z_index = 21
	add_child(blanket)
	_sleep_nodes = [head, blanket]


func get_up_instant() -> void:
	for n in _sleep_nodes:
		n.queue_free()
	_sleep_nodes.clear()
	_sprite.visible = true
	_shadow.visible = true


## Si alza dal letto e fa due passi fino a `to`.
func get_up(to: Vector2) -> void:
	get_up_instant()
	facing = "right"
	_sprite.play("walk_right")
	var tw := create_tween()
	tw.tween_property(self, "position", to, 0.6)
	await tw.finished
	_sprite.play("idle_down")
	facing = "down"
