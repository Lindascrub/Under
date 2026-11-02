class_name Car
extends StaticBody2D
## Un'auto che percorre la strada. Se sei davanti si ferma e suona il clacson.
## Se sei sulle strisce pedonali (Strisce), si ferma prima e aspetta, senza suonare.

var direction := 1.0
var speed := 70.0
var min_x := -100.0
var max_x := 1100.0
## Quanto occupa sulla strada (la collisione, appoggiata sulle ruote).
var body_size := Vector2(56, 24)
var _sprite: Sprite2D
var _wait := 0.0
var _honked := false


func _ready() -> void:
	add_to_group("car")
	_sprite = Sprite2D.new()
	_sprite.centered = false
	add_child(_sprite)
	var shape := RectangleShape2D.new()
	shape.size = body_size
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -body_size.y / 2.0 - 1.0)
	add_child(col)
	_new_look()
	_wait = randf_range(0.0, 6.0)


func _new_look() -> void:
	var side := "right" if direction > 0 else "left"
	var tex := Assets.tex("cars/car_%s_%d.png" % [side, randi_range(1, 6)], Vector2i(64, 48))
	_sprite.texture = tex
	_sprite.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
	speed = randf_range(55.0, 85.0)


func _process(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		return
	if _car_ahead() or _crosswalk_stop():
		return
	if _blocked():
		if not _honked:
			_honked = true
			Sound.sfx("honk")
		return
	_honked = false
	position.x += direction * speed * delta
	if (direction > 0 and position.x > max_x) or (direction < 0 and position.x < min_x):
		position.x = min_x if direction > 0 else max_x
		_new_look()
		_wait = randf_range(1.0, 7.0)


func _blocked() -> bool:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p == null:
		return false
	var d := p.global_position - global_position
	return absf(d.y + 6) < 16 and d.x * direction > 0 and absf(d.x) < 56


## Un'altra auto nella stessa corsia, troppo vicina davanti: si aspetta in coda.
func _car_ahead() -> bool:
	for other in get_tree().get_nodes_in_group("car"):
		if other == self or not other.visible:
			continue
		var d: Vector2 = (other as Node2D).global_position - global_position
		if absf(d.y) < 4 and d.x * direction > 0 and absf(d.x) < 74:
			return true
	return false


## Ci sono strisce occupate poco più avanti: ci si ferma prima, col muso a `distanza_stop` pixel.
func _crosswalk_stop() -> bool:
	var front := global_position.x + direction * 30.0
	for s in get_tree().get_nodes_in_group("strisce"):
		var st := s as Strisce
		if st == null or not st.occupata:
			continue
		var edge := st.global_position.x if direction > 0 else st.global_position.x + st.larghezza
		var gap := (edge - front) * direction
		if gap >= -2.0 and gap <= st.distanza_stop + 2.0 and absf(st.global_position.y + 16.0 - global_position.y) < 40.0:
			return true
	return false
