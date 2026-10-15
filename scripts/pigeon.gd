class_name Pigeon
extends Node2D
## Un piccione che becca per terra e vola via quando ti avvicini. Dopo un po' torna.

const FLEE_DISTANCE := 30.0

var _sprite: AnimatedSprite2D
var _home := Vector2.ZERO
var _flying := false
var _peck := 0.0


func _ready() -> void:
	_home = position
	_sprite = AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	var tex: Texture2D = load("res://art/pigeon.png") if ResourceLoader.exists("res://art/pigeon.png") else Assets.tex("_pigeon", Vector2i(20, 8))
	for i in 2:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * 10, 0, 10, 8)
		frames.add_frame("default", at)
	frames.set_animation_speed("default", 0.0)
	_sprite.sprite_frames = frames
	_sprite.centered = false
	_sprite.offset = Vector2(-5, -8)
	_sprite.flip_h = randf() < 0.5
	add_child(_sprite)
	_peck = randf_range(0.5, 2.0)


func _process(delta: float) -> void:
	if _flying:
		return
	_peck -= delta
	if _peck <= 0.0:
		_sprite.frame = 1 - _sprite.frame
		_peck = randf_range(0.2, 1.5) if _sprite.frame == 1 else randf_range(0.8, 2.5)
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p and p.global_position.distance_to(global_position) < FLEE_DISTANCE:
		_fly_away(p.global_position)


func _fly_away(from: Vector2) -> void:
	_flying = true
	Sound.sfx("flap")
	var dir := (global_position - from).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	_sprite.flip_h = dir.x > 0
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "position", position + Vector2(dir.x * 70, -60), 0.9)
	tw.tween_property(self, "modulate:a", 0.0, 0.9)
	await tw.finished
	await get_tree().create_timer(randf_range(6.0, 10.0)).timeout
	position = _home
	var back := create_tween()
	back.tween_property(self, "modulate:a", 1.0, 0.5)
	await back.finished
	_flying = false
