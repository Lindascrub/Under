@tool
class_name RoomFeature
extends Node2D
## Un pezzo "speciale" della stanza, da mettere e spostare nell'editor. La posizione del nodo
## è l'angolo in alto a sinistra della casella su cui sta (in basso a sinistra per le scale).
##   kind "stairs_up"   scale per il piano di sopra (con tornello): target, spawn, need (badge)
##   kind "stairs_down" la botola per il piano di sotto: target, spawn
##   kind "save"        la stellina
##   kind "station"     un posto di lavoro: job (id in data/worklist.json)
##   kind "badge"       lo sportello dei badge (l'addetta sta qui, la scrivania sotto)

@export_enum("stairs_up", "stairs_down", "save", "station", "badge") var kind := "save":
	set(v):
		kind = v
		_preview()
@export_file("*.tscn") var target := ""
@export var spawn := ""
@export var need := ""
@export var job := ""

const T := 16
var _shown: Node2D


func _ready() -> void:
	_preview()


func cell() -> Vector2i:
	return Vector2i(int(round(position.x / T)), int(round(position.y / T)))


## Nell'editor: un'anteprima di quello che comparirà nel gioco.
func _preview() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	if _shown:
		_shown.queue_free()
	_shown = Node2D.new()
	add_child(_shown)
	var generic := Assets.tex("tiles/generic.png", Vector2i(256, 1248))
	var stair_texture := Assets.tex("themes/condominium.png", Vector2i(256,1664))
	match kind:
		"stairs_up":
			_region(stair_texture, Rect2(16,0,32,64), Vector2(0,T-64))
		"stairs_down":
			_region(stair_texture, Rect2(64,32,32,32), Vector2(0,T-32))
		"save":
			var st := Sprite2D.new()
			st.texture = load("res://art/save_star.png")
			st.region_enabled = true
			st.region_rect = Rect2(0, 0, 13, 13)
			st.position = Vector2(8, 4)
			_shown.add_child(st)
		"station":
			if job == "dinamo":
				# The real CycletteDinamo is already in the scene; no second preview on top.
				_shown.queue_free()
				_shown = null
				return
			var caption := Label.new()
			caption.text = "TURNO"
			caption.position = Vector2(-12, -12)
			caption.add_theme_font_override("font", preload("res://fonts/Silkscreen-Regular.ttf"))
			caption.add_theme_font_size_override("font_size", 8)
			_shown.add_child(caption)
		"badge":
			var booth: Node2D = load("res://world/badge_booth.tscn").instantiate()
			booth.position = Vector2(-32,32)
			_shown.add_child(booth)
	_shown.modulate.a = 0.8


func _region(tex: Texture2D, r: Rect2, at: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.region_enabled = true
	s.region_rect = r
	s.centered = false
	s.position = at
	_shown.add_child(s)
	return s


## Nel gioco: chiede alla stanza di costruire la cosa vera, poi sparisce.
func setup_in_room(room: Room) -> void:
	var c := cell()
	match kind:
		"stairs_up":
			room.add_stairs_up(c, target, spawn, need)
		"stairs_down":
			# la stanza può decidere da sé (il -4: scale vere o buco sbarrato)
			if room.has_method("place_stairs_down"):
				room.call("place_stairs_down", c, target, spawn)
			else:
				room.add_stairs_down(c, target, spawn)
		"save":
			room.add_save_point(c)
		"station":
			var j := GameState.job(job)
			if not j.is_empty():
				room.add_station_at(j, c)
		"badge":
			room.add_badge_machine(c)
	queue_free()
