extends Node2D
## Minigiochi "a sorpresa": partono quando dai una mano a qualcuno. Config in GameState.minigame:
##   type "timing":   premi Z quando il segno è nella zona verde (riparare, accordare, salire le scale)
##   type "collect":  muovi il cuore e raccogli tutto prima che scada il tempo (foglie, croccantini)
##   type "sequence": ricorda e ripeti la sequenza di frecce (pratiche, post-it, curriculum)
## Se vinci, la persona ti ringrazia e ti dà qualche euro.

const BOX := Rect2(170, 120, 300, 150)
const RED := Color("ff2a3c")
const YELLOW := Color("ffe14d")
const GREEN := Color("3ddc84")
const ARROWS := ["up", "down", "left", "right"]

var cfg: Dictionary = {}
var type := "timing"
var phase := "intro"
var won := false

# timing
var marker := 0.0
var marker_dir := 1.0
var marker_speed := 0.7
var zone := Vector2(0.4, 0.55)
var hits := 0
var misses := 0
var flash := 0.0
# collect
var soul := Vector2.ZERO
var items: Array[Vector2] = []
var time_left := 15.0
# sequence
var seq: Array[String] = []
var shown := 0
var show_t := 0.0
var typed: Array[String] = []
var round_n := 0

var _title: Label
var _info: Label


func _ready() -> void:
	cfg = GameState.minigame
	type = str(cfg.get("type", "timing"))
	Ui.show_hud(false)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.size = Vector2(640, 360)
	bg.z_index = -10
	add_child(bg)
	_title = _label(Vector2(0, 40), 22, YELLOW)
	_title.text = str(cfg.get("title", "Dai una mano"))
	_info = _label(Vector2(0, 80), 16, Color.WHITE)
	if Ui.transitioning:
		await Ui.faded_in
	await Ui.say(cfg.get("intro", ["* Dai una mano."]))
	_start()


func _label(pos: Vector2, size: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(640, size + 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	add_child(l)
	return l


func _start() -> void:
	phase = "play"
	match type:
		"timing":
			_info.text = "Premi Z quando il segno è nel verde"
			_new_zone()
		"collect":
			_info.text = "Raccogli tutto con le frecce"
			soul = BOX.get_center()
			for i in int(cfg.get("count", 10)):
				items.append(Vector2(randf_range(BOX.position.x + 12, BOX.end.x - 12), randf_range(BOX.position.y + 12, BOX.end.y - 12)))
			time_left = float(cfg.get("time", 15.0))
		"sequence":
			_next_round()


func _new_zone() -> void:
	var w := maxf(0.1, 0.2 - hits * 0.025)
	var a := randf_range(0.05, 0.95 - w)
	zone = Vector2(a, a + w)


func _next_round() -> void:
	round_n += 1
	seq.clear()
	typed.clear()
	for i in 3 + round_n:
		seq.append(ARROWS[randi() % 4])
	shown = 0
	show_t = 0.8
	phase = "show"
	_info.text = "Guarda bene... (%d/2)" % round_n


func _process(delta: float) -> void:
	flash = maxf(0.0, flash - delta)
	match phase:
		"play":
			if type == "timing":
				marker += marker_dir * marker_speed * delta
				if marker > 1.0 or marker < 0.0:
					marker = clampf(marker, 0.0, 1.0)
					marker_dir = -marker_dir
			elif type == "collect":
				var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
				soul = (soul + v * 140.0 * delta).clamp(BOX.position + Vector2(8, 8), BOX.end - Vector2(8, 8))
				for i in range(items.size() - 1, -1, -1):
					if items[i].distance_to(soul) < 10.0:
						items.remove_at(i)
						Sound.sfx("blip", 1.5)
				time_left -= delta
				_info.text = "Tempo: %d   Mancano: %d" % [int(ceil(time_left)), items.size()]
				if items.is_empty():
					_finish(true)
				elif time_left <= 0.0:
					_finish(false)
		"show":
			show_t -= delta
			if show_t <= 0.0:
				shown += 1
				show_t = maxf(0.4, 0.75 - round_n * 0.1)
				Sound.sfx("move")
				if shown > seq.size():
					phase = "play"
					_info.text = "Ora ripeti con le frecce!"
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if phase != "play":
		return
	if type == "timing" and event.is_action_pressed("confirm"):
		if marker >= zone.x and marker <= zone.y:
			hits += 1
			Sound.sfx("select")
			marker_speed += 0.2
			_new_zone()
			if hits >= int(cfg.get("hits", 4)):
				_finish(true)
		else:
			misses += 1
			flash = 0.25
			Sound.sfx("deny")
			if misses >= 3:
				_finish(false)
	elif type == "sequence":
		for a: String in ARROWS:
			if event.is_action_pressed("move_" + a):
				typed.append(a)
				if typed[typed.size() - 1] != seq[typed.size() - 1]:
					flash = 0.3
					Sound.sfx("deny")
					misses += 1
					if misses >= 2:
						_finish(false)
					else:
						round_n -= 1
						_next_round()
					return
				Sound.sfx("blip", 1.3)
				if typed.size() == seq.size():
					if round_n >= 2:
						_finish(true)
					else:
						Sound.sfx("select")
						_next_round()
				return


func _finish(success: bool) -> void:
	phase = "end"
	won = success
	var who := str(cfg.get("name", ""))
	var id := str(cfg.get("id", ""))
	GameState.help(id, "time", GameState.COST_HELP_TIME)
	var lines: Array = []
	if success:
		Sound.sfx("spare")
		var reward := int(cfg.get("reward", 10))
		GameState.money += reward
		GameState.changed.emit()
		lines.append_array(cfg.get("win", ["Grazie!"]))
		lines.append("Tieni, non è molto, ma te li sei guadagnati.")
		lines.append("* %s ti dà %s." % [who, GameState.euros(reward)])
	else:
		lines.append_array(cfg.get("lose", ["Non fa niente, grazie lo stesso."]))
		lines.append("* Non è andata benissimo, ma %s apprezza che ci hai provato." % who)
	await Ui.say(lines, who)
	Router.goto(str(cfg.get("return", Router.STREET)), "_mg")


func _draw() -> void:
	var font := Assets.font()
	draw_rect(BOX, Color.BLACK)
	draw_rect(BOX, Color.WHITE, false, 3.0)
	match type:
		"timing":
			var bar := Rect2(BOX.position.x + 20, BOX.get_center().y - 10, BOX.size.x - 40, 20)
			draw_rect(bar, Color("2a2633"))
			draw_rect(Rect2(bar.position.x + bar.size.x * zone.x, bar.position.y, bar.size.x * (zone.y - zone.x), bar.size.y), GREEN)
			var mx := bar.position.x + bar.size.x * marker
			draw_rect(Rect2(mx - 2, bar.position.y - 8, 4, bar.size.y + 16), Color.WHITE)
			draw_string(font, Vector2(BOX.position.x, BOX.end.y - 16), "Riusciti %d/%d    Errori %d/3" % [hits, int(cfg.get("hits", 4)), misses],
				HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 16, Color.WHITE)
		"collect":
			var col := Color(str(cfg.get("color", "#e0a030")))
			for it in items:
				draw_rect(Rect2(it - Vector2(3, 2), Vector2(6, 4)), col)
				draw_rect(Rect2(it - Vector2(1, 3), Vector2(2, 1)), col.lightened(0.3))
			_heart(soul, RED)
		"sequence":
			var cx := BOX.get_center()
			if phase == "show" and shown >= 1 and shown <= seq.size():
				_arrow(cx, seq[shown - 1], 18.0, YELLOW)
			elif phase == "play":
				var n := seq.size()
				for i in n:
					var p := Vector2(cx.x + (i - (n - 1) / 2.0) * 34.0, cx.y)
					if i < typed.size():
						_arrow(p, typed[i], 10.0, Color.WHITE)
					else:
						draw_rect(Rect2(p + Vector2(-8, 8), Vector2(16, 2)), Color("8a8494"))
	if flash > 0.0:
		draw_rect(BOX, Color(1, 0.2, 0.2, flash))


## Freccia piena (triangolo) che punta in una direzione.
func _arrow(c: Vector2, dir: String, r: float, col: Color) -> void:
	var pts := PackedVector2Array([Vector2(0, -r), Vector2(r, r * 0.6), Vector2(-r, r * 0.6)])
	var ang := {"up": 0.0, "right": PI / 2, "down": PI, "left": -PI / 2}[dir] as float
	for i in pts.size():
		pts[i] = c + pts[i].rotated(ang)
	draw_colored_polygon(pts, col)


func _heart(c: Vector2, col: Color) -> void:
	const ROWS := ["011000110", "111101111", "111111111", "111111111", "011111110", "001111100", "000111000", "000010000"]
	var o := c - Vector2(4.5, 4)
	for y in ROWS.size():
		var row: String = ROWS[y]
		for x in row.length():
			if row[x] == "1":
				draw_rect(Rect2(o + Vector2(x, y), Vector2.ONE), col)
