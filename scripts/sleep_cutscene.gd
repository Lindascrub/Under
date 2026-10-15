class_name SleepCutscene
extends Node2D
## Quando vai a dormire: una finestra dove il cielo passa dall'ora in cui ti sei sdraiato
## (tramonto, sera o notte) al buio con stelle e luna, poi l'alba e il sole che sorge.
## La sveglia suona dopo, quando ti risvegli nel letto (vedi home.gd).

const WIN := Rect2(200, 60, 240, 150)
const DURATION := 2.2

var from_hour := 22.0
var t := 0.0
var alarm := false
var _stars: Array[Vector2] = []


## Mostra l'animazione sopra a tutto e aspetta che finisca.
static func play(parent: Node, from_minutes: int) -> void:
	Ui.cutscene = true
	var layer := CanvasLayer.new()
	layer.layer = 15
	parent.add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color("0b0a10")
	bg.size = Vector2(640, 360)
	layer.add_child(bg)
	var scene := SleepCutscene.new()
	scene.from_hour = clampf(from_minutes / 60.0, 7.0, 24.0)
	layer.add_child(scene)
	await scene.run()
	layer.queue_free()
	Ui.cutscene = false


func _ready() -> void:
	for i in 26:
		_stars.append(Vector2(randf_range(WIN.position.x + 6, WIN.end.x - 6), randf_range(WIN.position.y + 6, WIN.end.y - 50)))


func run() -> void:
	var tw := create_tween()
	tw.tween_property(self, "t", 1.0, DURATION)
	await tw.finished
	await get_tree().create_timer(0.3).timeout


## Ora del giorno che si vede dalla finestra (oltre le 24 è il mattino dopo).
func _hour() -> float:
	return lerpf(from_hour, 31.0, t)


func _sky(h: float) -> Color:
	var keys := [
		[7.0, Color("8ec5ff")], [17.0, Color("8ec5ff")], [19.0, Color("f08a5a")], [21.0, Color("4a3a78")],
		[23.0, Color("141a3a")], [28.5, Color("141a3a")], [30.0, Color("f0a868")], [31.0, Color("8ec5ff")],
	]
	for i in keys.size() - 1:
		var a: Array = keys[i]
		var b: Array = keys[i + 1]
		if h >= a[0] and h <= b[0]:
			return (a[1] as Color).lerp(b[1], (h - a[0]) / maxf(0.01, b[0] - a[0]))
	return keys[keys.size() - 1][1]


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var h := _hour()
	draw_rect(WIN, _sky(h))
	# stelle, solo quando è buio
	var dark := clampf(1.0 - absf(h - 26.0) / 4.0, 0.0, 1.0)
	for s in _stars:
		if dark > 0.1 and int(s.x + s.y + t * 40) % 7 != 0:
			draw_rect(Rect2(s, Vector2.ONE), Color(1, 1, 1, dark))
	# luna: dalle 20 alle 30, attraversa la finestra
	if h > 20.0 and h < 30.0:
		var k := (h - 20.0) / 10.0
		var p := Vector2(lerpf(WIN.position.x + 20, WIN.end.x - 20, k), WIN.position.y + 70 - sin(k * PI) * 50)
		draw_circle(p, 9, Color("f4f0d8"))
		draw_circle(p + Vector2(4, -2), 7, _sky(h))
	# sole: tramonta prima delle 20, sorge dopo le 29
	if h < 20.0:
		var k2 := clampf((h - 7.0) / 13.0, 0.0, 1.0)
		draw_circle(Vector2(lerpf(WIN.position.x + 30, WIN.end.x - 30, k2), WIN.position.y + 40 + k2 * 70), 12, Color("ffd34a"))
	elif h > 29.0:
		var k3 := (h - 29.0) / 2.0
		draw_circle(Vector2(WIN.position.x + 50 + k3 * 40, WIN.end.y - 30 - k3 * 60), 12, Color("ffd34a"))
	# la città: sagome dei palazzi con qualche finestra accesa di notte
	var bx := WIN.position.x
	for i in 7:
		if bx >= WIN.end.x - 4:
			break
		var w := minf(30.0 + (i * 13) % 14, WIN.end.x - bx)
		var top := WIN.end.y - 30.0 - (i * 17) % 35
		draw_rect(Rect2(bx, top, w, WIN.end.y - top), Color("1c1824"))
		if dark > 0.3:
			for j in 3:
				draw_rect(Rect2(bx + 5 + j * 8, top + 6, 3, 3), Color(1, 0.85, 0.4, dark * 0.8))
		bx += w + 3
	# cornice della finestra
	draw_rect(WIN, Color("6b4a2a"), false, 6.0)
	draw_line(Vector2(WIN.get_center().x, WIN.position.y), Vector2(WIN.get_center().x, WIN.end.y), Color("6b4a2a"), 4.0)
	draw_line(Vector2(WIN.position.x, WIN.get_center().y), Vector2(WIN.end.x, WIN.get_center().y), Color("6b4a2a"), 4.0)
	# orologio
	var shown := fmod(h, 24.0)
	draw_string(Assets.font(), Vector2(0, 250), "%02d:%02d" % [int(shown), int(fmod(shown, 1.0) * 60.0)], HORIZONTAL_ALIGNMENT_CENTER, 640, 22, Color.WHITE)
	# sveglia che trema
	if alarm:
		var c := Vector2(320 + randf_range(-3, 3), 300 + randf_range(-2, 2))
		draw_circle(c, 18, Color("d0302f"))
		draw_circle(c, 14, Color("f2f0e6"))
		draw_line(c, c + Vector2(0, -9), Color.BLACK, 2.0)
		draw_line(c, c + Vector2(6, 0), Color.BLACK, 2.0)
		draw_circle(c + Vector2(-14, -16), 6, Color("d0302f"))
		draw_circle(c + Vector2(14, -16), 6, Color("d0302f"))
