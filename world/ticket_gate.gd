@tool
extends Sprite2D
## Il tornello a due ante originale del museo. Si apre nei fotogrammi 0–4, fino al verde.

const SHEET=preload("res://assets/limezu/animations/ticket_turnstile.png")
var current_frame:=0
var opened:=false
var animating:=false

func _ready() -> void:
	texture=SHEET;centered=false;offset=Vector2(0,-48);region_enabled=true
	_show()

func _show() -> void:
	region_rect=Rect2(current_frame*32,0,32,48)

func unlock(animate:=true) -> void:
	if opened or animating:return
	opened=true
	if not animate:current_frame=4;_show();return
	animating=true
	for i in range(0,5):
		current_frame=i;_show()
		await get_tree().create_timer(0.09).timeout
	animating=false
