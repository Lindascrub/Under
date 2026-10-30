@tool
extends Node2D
## Banco completo: sedia, computer con il suo supporto e fronte in legno originali.

func _ready() -> void:
	y_sort_enabled=true
	_piece("themes/hospital.png",Rect2(160,304,16,16),Vector2(5,-20))
	_piece("themes/conference.png",Rect2(144,72,56,16),Vector2.ZERO)
	var monitor:=_piece("props/computer.png",Rect2(0,0,16,20),Vector2(36,1))
	monitor.offset=Vector2(0,-29)
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/monitor_gray.gdshader")
	monitor.material=material

func _piece(file:String,rect:Rect2,feet:Vector2) -> Sprite2D:
	var sprite:=Sprite2D.new()
	sprite.texture=Assets.tex(file);sprite.centered=false
	var height:=float(sprite.texture.get_height())
	if rect.size!=Vector2.ZERO:
		sprite.region_enabled=true;sprite.region_rect=rect;height=rect.size.y
	sprite.position=feet;sprite.offset=Vector2(0,-height)
	sprite.set_meta("prop_talk_skip",true)
	add_child(sprite)
	return sprite
