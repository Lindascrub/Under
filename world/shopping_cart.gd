@tool
class_name ShoppingCart
extends Sprite2D
## Un carrello della spesa animato (LimeZu, 3 fotogrammi da 32x32): le ruote girano.
## Si sposta nell'editor come uno sprite qualunque (e si vede già animato). La posizione è
## l'angolo in basso a sinistra, come gli altri oggetti delle stanze.

const FRAMES := 3
const STEP := 0.2
const LINES := [
	["* Un carrello della spesa. Una ruota gira per conto suo, come tutti qui."],
	["* Il carrello è pieno di offerte. Nessuna serviva davvero."],
	["* Sul manico c'è scritto: \"Spingi. Compra. Ripeti.\""],
]

@export_enum("blue", "green", "red") var color := "blue":
	set(v):
		color = v
		_apply()
@export_enum("empty", "full1", "full2", "full3") var load_kind := "empty":
	set(v):
		load_kind = v
		_apply()
@export_enum("down", "up", "left", "right") var facing := "down":
	set(v):
		facing = v
		_apply()

var _time := 0.0


func _ready() -> void:
	centered = false
	region_enabled = true
	offset = Vector2(0, -32)
	_apply()
	set_meta("prop_talk_skip", true)
	_time = randf() * FRAMES * STEP


func _apply() -> void:
	var path := "res://assets/limezu/props/cart_%s_%s_%s.png" % [color, load_kind, facing]
	if not ResourceLoader.exists(path):
		# il verde pieno (1) verso sinistra LimeZu non lo ha: si usa quello verso destra girato
		path = "res://assets/limezu/props/cart_%s_%s_%s.png" % [color, load_kind, "right" if facing == "left" else facing]
		flip_h = facing == "left"
	else:
		flip_h = false
	texture = load(path) if ResourceLoader.exists(path) else null
	region_rect = Rect2(0, 0, 32, 32)


## La collisione (`Collisione`) e la frase (`Guarda`) sono nodi figli nella scena: si vedono e si
## cambiano nell'editor. Se mancano (un carrello aggiunto a mano), li crea qui.
func setup_in_room(room: Room) -> void:
	if find_children("*", "StaticBody2D", true, false).is_empty():
		var side := facing == "left" or facing == "right"
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(22 if side else 14, 8)
		shape.shape = rect
		shape.position = Vector2(16, -5)
		body.add_child(shape)
		add_child(body)
	if find_children("*", "Examine", true, false).is_empty():
		var e := Examine.new()
		e.lines = PackedStringArray(LINES[abs(int(position.x + position.y)) % LINES.size()])
		e.position = Vector2(16, -8)
		add_child(e)
		e.setup_in_room(room)


func _process(delta: float) -> void:
	_time += delta
	region_rect = Rect2(int(_time / STEP) % FRAMES * 32, 0, 32, 32)
