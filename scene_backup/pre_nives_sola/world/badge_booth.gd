@tool
extends Node2D
## La biglietteria originale LimeZu (scena world/badge_booth.tscn): parete, vetri, sportello,
## porta, addetta e collisione sono nodi veri, si vedono e si spostano nell'editor.
## Il nodo sta nell'angolo in basso a sinistra della cabina (96x48 px).
## Lo script tiene solo la porta che si apre e l'addetta che esce e rientra.

const HOME := Vector2(40, -18)
const INSIDE := Vector2(72, -18)
const OUTSIDE := Vector2(72, 12)

@onready var clerk: AnimatedSprite2D = $Addetta
@onready var door: Sprite2D = $Porta
@onready var door_backing: Polygon2D = $VetroPorta
var door_frame := 0


## Il gioco la trova da sola nella stanza: sportello per comprare il badge davanti al vetro.
func setup_in_room(room: Room) -> void:
	room.use_badge_booth(self)


func _show_door() -> void:
	door.region_rect = Rect2(door_frame * 16, 0, 16, 48)
	if door_backing: door_backing.visible = door_frame == 0 or door_frame == 11

func open_door() -> void:
	for i in range(0, 6):
		door_frame = i; _show_door()
		await get_tree().create_timer(0.075).timeout

func close_door() -> void:
	for i in range(6, 12):
		door_frame = i; _show_door()
		await get_tree().create_timer(0.075).timeout
	door_frame = 0; _show_door()

func walk_to(point: Vector2) -> void:
	var delta := point - clerk.global_position
	if delta.length() < 0.5: return
	var facing := "right" if delta.x > 0 else "left"
	if absf(delta.y) > absf(delta.x): facing = "down" if delta.y > 0 else "up"
	clerk.play("walk_" + facing)
	var tween := create_tween()
	tween.tween_property(clerk, "global_position", point, delta.length() / 62.0)
	await tween.finished
	clerk.play("idle_" + facing)

func come_out() -> void:
	await open_door()
	await walk_to(to_global(INSIDE))
	await walk_to(to_global(OUTSIDE))

func go_inside() -> void:
	await walk_to(to_global(OUTSIDE))
	await walk_to(to_global(INSIDE))
	await walk_to(to_global(HOME))
	clerk.play("idle_down")
	await close_door()
