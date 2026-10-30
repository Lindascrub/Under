@tool
class_name SecurityCamera
extends Sprite2D
## Una telecamera a muro (LimeZu, 10 fotogrammi da 16x16): gira piano e la lucina rossa lampeggia.
## Il capo ci guarda. Si sposta nell'editor come uno sprite qualunque (e si vede già animata).
## `facing`: da che parte guarda ("left" o "right").

const FRAMES := 10
const STEP := 0.18
const LINES := [
	"* Una telecamera. La lucina rossa lampeggia.",
	"* Da qualche parte, ai piani alti, qualcuno ti sta guardando.",
]

@export_enum("left", "right") var facing := "right":
	set(v):
		facing = v
		_apply()

var _time := 0.0


func _ready() -> void:
	centered = false
	region_enabled = true
	_apply()
	set_meta("prop_talk_skip", true)
	_time = randf() * FRAMES * STEP


func _apply() -> void:
	var path := "res://assets/limezu/props/camera_%s.png" % facing
	texture = load(path) if ResourceLoader.exists(path) else null
	region_rect = Rect2(0, 0, 16, 16)


## La frase (`Guarda`, toccandola dal pavimento) è un nodo figlio nella scena: si vede e si cambia
## nell'editor. Se manca (una telecamera aggiunta a mano), la crea qui.
func setup_in_room(room: Room) -> void:
	if not find_children("*", "Examine", true, false).is_empty():
		return
	var e := Examine.new()
	e.lines = PackedStringArray(LINES)
	e.position = Vector2(8, 40)
	add_child(e)
	e.setup_in_room(room)


func _process(delta: float) -> void:
	_time += delta
	region_rect = Rect2(int(_time / STEP) % FRAMES * 16, 0, 16, 16)
