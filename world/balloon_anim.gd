class_name BalloonAnim
extends Node
## I palloncini della festa si muovono: ogni Sprite2D "Palloncino*" col palloncino fermo di birthday.png
## prende il foglio animato di LimeZu dello stesso colore (5 fotogrammi da 16x32) e ondeggia, ognuno
## col suo ritmo. Resta uno Sprite2D: si sposta nell'editor e si sgonfia come prima.
## Sgonfio (quando la festa si spegne) sta fermo.

const SHEETS := {0: "yellow", 16: "blue", 32: "red", 48: "green"}
const FRAMES := 5
const STEP := 0.16

var _balloons: Array[Sprite2D] = []
var _phase: Array[float] = []
var _time := 0.0


static func apply(room: Node) -> void:
	var anim := BalloonAnim.new()
	for n in room.find_children("Palloncino*", "Sprite2D", true, false):
		var s := n as Sprite2D
		if s.texture == null or not s.region_enabled or not s.texture.resource_path.ends_with("birthday.png"):
			continue
		var color: String = SHEETS.get(int(s.region_rect.position.x), "")
		var path := Assets.ROOT + "props/balloon_%s.png" % color
		if color == "" or not ResourceLoader.exists(path):
			continue
		s.texture = load(path)
		s.region_rect = Rect2(0, 0, 16, 32)
		anim._balloons.append(s)
		anim._phase.append(randf() * FRAMES * STEP)
	if anim._balloons.is_empty():
		anim.free()
		return
	room.add_child(anim)


func _process(delta: float) -> void:
	_time += delta
	for i in _balloons.size():
		var s := _balloons[i]
		if not is_instance_valid(s) or s.scale.y < 0.9:
			continue
		var f := int((_time + _phase[i]) / STEP) % FRAMES
		s.region_rect = Rect2(f * 16, 0, 16, 32)
