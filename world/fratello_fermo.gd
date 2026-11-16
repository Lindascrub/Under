extends Node2D
## Stessa faccia di Fermo, vestiti colorati e badge. Non entra nel conteggio degli aiuti.
@export_enum("banca", "fondo", "scale_chiuse", "sottoufficio") var place := "banca"
@export var speed := 64.0
@onready var sprite: CharSprite = $Sprite
@onready var body: StaticBody2D = $Corpo
@onready var talk_point: Interactable = $Parla
var room: Room
var busy := false
var seat_position := Vector2.ZERO

func setup_in_room(here: Room) -> void:
	room = here
	seat_position = position
	talk_point.action = talk
	talk_point.add_to_group("walker")
	GameState.changed.connect(sync)
	sync()

func sync() -> void:
	if busy: return
	var together := FratelliFermo.reunited() or bool(FratelliFermo.state().get("robot_visit_seen", false))
	var closed: bool = GameState.flags.get("c1_sbarrato", false)
	var active := false
	match place:
		"banca", "sottoufficio": active = not FratelliFermo.delivered()
		"scale_chiuse": active = FratelliFermo.delivered() and closed and not together
		"fondo": active = FratelliFermo.delivered() and (not closed or together)
	visible = active
	body.collision_layer = 1 if active else 0
	if active:
		if not talk_point.is_in_group("interactable"): talk_point.add_to_group("interactable")
	else:
		talk_point.remove_from_group("interactable")
	if place == "scale_chiuse" and active:
		global_position = room.get_node("Punti/FratelloScaleChiuse").global_position
		sprite.anim = "idle_left"
	if place == "fondo" and active:
		if together:
			position = seat_position
			sit()
		else:
			global_position = room.get_node("Punti/FratelloIngresso").global_position
			sprite.anim = "idle_left"

func talk() -> void:
	await FratelliFermo.talk_brother(room, self)

func face_player() -> void:
	if place == "fondo" and (FratelliFermo.reunited() or FratelliFermo.state().get("robot_visit_seen", false)): return
	var direction := room.player.global_position - global_position
	sprite.anim = "idle_" + _direction(direction)

func _direction(delta: Vector2) -> String:
	if absf(delta.x) > absf(delta.y): return "right" if delta.x > 0 else "left"
	return "down" if delta.y > 0 else "up"

func walk(points: Array[Vector2], camera: Camera2D = null) -> void:
	for point: Vector2 in points:
		var delta := point - global_position
		if delta.length() < 0.1: continue
		sprite.anim = "walk_" + _direction(delta)
		var movement := create_tween()
		movement.tween_property(self, "global_position", point, delta.length() / speed)
		if camera:
			movement.parallel().tween_property(camera, "global_position", point + Vector2(0, -18), delta.length() / speed)
		await movement.finished
	sprite.anim = "idle_left"

func sit() -> void:
	sprite.anim = "sit_right"
	sprite.nudge = Vector2(0, 6)
	$Badge.visible = false
