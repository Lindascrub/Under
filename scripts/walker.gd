class_name Walker
extends StaticBody2D
## Un passante senza nome che attraversa la strada. Più persone sfrutti,
## più passanti rispondono come robot.

const LINES := [
	"Scusa, ho fretta. Sono in ritardo da quando sono nato.",
	"Lavoro alla CHEAP. No, non voglio parlarne.",
	"Hai visto quanto costa il pane? Io l'ho visto e sono scappato.",
	"Bella giornata, eh? Peccato doverla passare a lavorare.",
	"Il mio capo dice che siamo una famiglia. Io a casa mia non vengo licenziato.",
	"Cerco lavoro. Se ne vedi uno in giro, fischia.",
	"Dicono che domani piove. Dicono anche che l'affitto aumenta. Le cose che dicono si avverano sempre.",
]

var sheet := "char_13"
var direction := 1.0
var min_x := 0.0
var max_x := 1000.0
var speed := 26.0
var _sprite: AnimatedSprite2D
var _robot := false
var _line := 0
var _stuck := 0.0


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("walker")
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
	_robot = randf() < GameState.exploited * 0.25
	_unstick.call_deferred()
	_line = randi() % LINES.size()
	speed = randf_range(22.0, 32.0)


func _process(delta: float) -> void:
	if Ui.blocks_input():
		if _sprite.animation.begins_with("walk"):
			_sprite.play("idle_" + ("right" if direction > 0 else "left"))
		return
	# Se è finito sopra qualcuno, continua a camminare finché non si separano.
	var inside := test_move(global_transform, Vector2(0.5, 0)) and test_move(global_transform, Vector2(-0.5, 0))
	# Altrimenti, prima di fare un passo controlla se c'è qualcuno (o qualcosa) davanti.
	if not inside and test_move(global_transform, Vector2(direction * 3.0, 0)):
		_sprite.play("idle_" + ("right" if direction > 0 else "left"))
		_stuck += delta
		if _stuck > 1.2:
			_stuck = 0.0
			direction = -direction
		return
	_stuck = 0.0
	position.x += direction * speed * delta
	var anim := "walk_right" if direction > 0 else "walk_left"
	if _sprite.animation != anim:
		_sprite.play(anim)
	if position.x > max_x or position.x < min_x:
		direction = -direction


func hotspot() -> Vector2:
	return global_position + Vector2(0, -8)


func interact() -> void:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p:
		_sprite.play("idle_" + ("right" if p.global_position.x > global_position.x else "left"))
	if _robot:
		await Ui.say([GameState.robot_line(sheet)], "Passante", sheet)
	else:
		await Ui.say([LINES[_line]], "Passante", sheet)


## Se compare sopra qualcuno (o dentro un oggetto), si sposta finché non è libero.
func _unstick() -> void:
	await get_tree().physics_frame
	for i in 40:
		if not test_move(global_transform, Vector2(0.5, 0)) and not test_move(global_transform, Vector2(-0.5, 0)):
			return
		position.x = wrapf(position.x + 16.0 * randi_range(1, 4), min_x, max_x)
