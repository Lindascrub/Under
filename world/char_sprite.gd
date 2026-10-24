@tool
class_name CharSprite
extends AnimatedSprite2D
## Un personaggio LimeZu che si vede anche nell'editor: scegli il foglio ("char_14")
## e l'animazione ("idle_down", "sit_left", "phone"...). I piedi stanno sul punto del nodo.

@export var sheet := "char_02":
	set(v):
		sheet = v
		_refresh()
@export var anim := "idle_down":
	set(v):
		anim = v
		_refresh()
## Spostamento in più dello sprite (per esempio per sedersi su una cassetta).
@export var nudge := Vector2.ZERO:
	set(v):
		nudge = v
		_refresh()
## Grigio: per chi, nel mondo colorato, non sorride (Fermo).
@export var grey := false:
	set(v):
		grey = v
		_refresh()


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if not is_inside_tree() and not Engine.is_editor_hint():
		return
	sprite_frames = Assets.character(sheet)
	centered = false
	offset = Vector2(-8, -31) + nudge
	if sprite_frames and sprite_frames.has_animation(anim):
		play(anim)
	if grey:
		var m := ShaderMaterial.new()
		m.shader = preload("res://shaders/greyscale.gdshader")
		material = m
	else:
		material = null
