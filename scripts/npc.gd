class_name Npc
extends StaticBody2D
## Una persona del quartiere. Testi e aiuti sono in data/npcs.json.
## Se GameState.is_robot(id) è vero, la persona è stata sostituita da un robot:
## stessa faccia, frasi vuote, e non "respira" più (l'animazione è ferma).

const ROBOT_SHADER := preload("res://shaders/robot.gdshader")

var id := ""
var facing := "down"
var data: Dictionary = {}
var sprite: AnimatedSprite2D
var _mat: ShaderMaterial


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("npc")
	data = GameState.npc_data(id)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Assets.character(str(data.get("sheet", "char_02")))
	sprite.centered = false
	sprite.offset = Vector2(-8, -31)
	_mat = ShaderMaterial.new()
	_mat.shader = ROBOT_SHADER
	sprite.material = _mat
	add_child(sprite)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 8)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -4)
	add_child(col)
	sprite.play("idle_" + facing)
	sprite.frame = randi() % 6
	if GameState.is_robot(id):
		sprite.speed_scale = 0.0


func hotspot() -> Vector2:
	return global_position + Vector2(0, -8)


func display_name() -> String:
	return str(data.get("name", id.capitalize()))


func face(dir: String) -> void:
	facing = dir
	sprite.play("idle_" + dir)


## Mostra il robot che c'era sotto (usato nel finale ricco).
func reveal(time := 2.0) -> void:
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: _mat.set_shader_parameter("amount", v), 0.0, 1.0, time)
	await tw.finished


func interact() -> void:
	_face_player()
	var who := display_name()
	if GameState.is_robot(id):
		await Ui.say([GameState.robot_line(id)], who)
		return
	await Ui.say(_lines(), who)
	await _offer_help(who)


func _face_player() -> void:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p == null:
		return
	var d := p.global_position - global_position
	if absf(d.x) > absf(d.y):
		face("right" if d.x > 0 else "left")
	else:
		face("down" if d.y > 0 else "up")


func _lines() -> Array:
	var met_key := "met_" + id
	if not GameState.flags.get(met_key, false) and data.has("intro"):
		GameState.flags[met_key] = true
		return data["intro"]
	if id == "nico":
		return GameState.nico_lines()
	if id in GameState.helped_ids and data.has("helped"):
		return data["helped"]
	var days: Array = data.get("days", [["..."]])
	return days[clampi(GameState.day - 1, 0, days.size() - 1)]


func _offer_help(who: String) -> void:
	if not data.has("help") or not GameState.can_help(id):
		return
	var h: Dictionary = data["help"]
	var kind := str(h.get("kind", "time"))
	var cost := int(h.get("cost", 0))
	var label := ("Aiuta (-%s)" % GameState.euros(cost)) if kind == "money" \
		else ("Dai una mano (tempo libero: %d)" % GameState.free_time)
	var choice: int = await Ui.choose(str(h.get("ask", "")), [label, "Non ora"], who)
	if choice != 0:
		return
	if GameState.help(id, kind, cost):
		await Ui.say(h.get("yes", ["Grazie."]), who)
	elif kind == "money":
		await Ui.say(["* Non hai abbastanza soldi."])
	else:
		await Ui.say(["* Sei troppo stanco. Oggi non ti resta tempo libero."])
