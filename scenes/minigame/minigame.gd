extends Node2D
## Minigiochi "a sorpresa": partono quando dai una mano a qualcuno. Config in GameState.minigame:
##   type "timing":   premi Z quando il segno è nella zona verde (riparare, accordare, salire le scale)
##   type "collect":  muovi il cuore e raccogli tutto prima che scada il tempo (foglie, croccantini)
##   type "sequence": ricorda e ripeti la sequenza di frecce (pratiche, post-it, curriculum)
##   type "bulbs":    smista le lampadine: buona a DESTRA, rotta a SINISTRA, quella che sfarfalla
##                    si aggiusta con SU o GIÙ (Mina)
##   type "wires":    collega i fili dello stesso colore, come in Among Us (Nonno Bulbo)
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
var hazards: Array[Dictionary] = []
# lampadine
var bulb := "buona"
var bulb_fix := 0
var bulb_done := 0
var bulb_t := 0.0
# fili
const WIRE_COLS := [Color("d23b3b"), Color("39b6ff"), Color("ffe14d"), Color("3ddc84")]
var wire_right: Array[int] = []
var wire_done: Array[int] = []
var wire_sel := 0
var wire_pick := -1
var wire_round := 0
var hurt_t := 0.0
# sequence
var seq: Array[String] = []
var shown := 0
var show_t := 0.0
var typed: Array[String] = []
var round_n := 0
var show_len := 0.75
## Ogni direzione ha il suo suono, così si capisce anche a orecchio.
const ARROW_PITCH := {"up": 1.5, "right": 1.25, "down": 0.75, "left": 1.0}

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
			_info.text = GameState.fmt("Premi {ok} quando il segno è nel verde")
			_new_zone()
		"collect":
			_info.text = "Raccogli tutto con le frecce ed evita le cose rosse"
			soul = BOX.get_center()
			for i in int(cfg.get("count", 10)):
				items.append(Vector2(randf_range(BOX.position.x + 12, BOX.end.x - 12), randf_range(BOX.position.y + 12, BOX.end.y - 12)))
			time_left = float(cfg.get("time", 15.0)) * 0.7
			for i in 3:
				var hp := Vector2(randf_range(BOX.position.x + 20, BOX.end.x - 20), randf_range(BOX.position.y + 20, BOX.end.y - 20))
				if hp.distance_to(soul) < 50.0:
					hp.x = BOX.position.x + 30 if soul.x > BOX.get_center().x else BOX.end.x - 30
				hazards.append({"pos": hp, "vel": Vector2.from_angle(randf() * TAU) * randf_range(55.0, 85.0)})
		"sequence":
			_next_round()
		"bulbs":
			_info.text = "DESTRA buona   SINISTRA rotta   SU/GIÙ aggiusta"
			time_left = float(cfg.get("time", 25.0))
			_new_bulb()
		"wires":
			_info.text = "SU/GIÙ scegli il filo, %s per collegarlo" % GameState.fmt("{ok}")
			time_left = float(cfg.get("time", 30.0))
			_new_wires()


func _new_bulb() -> void:
	bulb = ["buona", "rotta", "fioca"].pick_random()
	bulb_fix = 0
	bulb_t = 0.0


func _bulb_answer(ok: bool) -> void:
	if ok:
		bulb_done += 1
		Sound.sfx("blip", 1.3)
	else:
		misses += 1
		flash = 0.3
		Sound.sfx("deny")
	if bulb_done >= int(cfg.get("count", 10)):
		_finish(true)
	elif misses >= 4:
		_finish(false)
	else:
		_new_bulb()


func _new_wires() -> void:
	wire_right.assign([0, 1, 2, 3])
	wire_right.shuffle()
	wire_done.clear()
	wire_sel = 0
	wire_pick = -1


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


var t_spin := 0.0


func _process(delta: float) -> void:
	flash = maxf(0.0, flash - delta)
	t_spin += delta * 4.0
	match phase:
		"play":
			if type == "timing":
				marker += marker_dir * marker_speed * delta
				if marker > 1.0 or marker < 0.0:
					marker = clampf(marker, 0.0, 1.0)
					marker_dir = -marker_dir
			elif type == "bulbs" or type == "wires":
				bulb_t += delta
				time_left -= delta
				if type == "bulbs":
					_info.text = "Tempo: %d   Smistate: %d/%d   Errori: %d/4" % [int(ceil(time_left)), bulb_done, int(cfg.get("count", 10)), misses]
				else:
					_info.text = "Tempo: %d   Pannello %d/2   Errori: %d/4" % [int(ceil(time_left)), wire_round + 1, misses]
				if time_left <= 0.0:
					_finish(false)
			elif type == "collect":
				var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
				soul = (soul + v * 140.0 * delta).clamp(BOX.position + Vector2(8, 8), BOX.end - Vector2(8, 8))
				for i in range(items.size() - 1, -1, -1):
					if items[i].distance_to(soul) < 10.0:
						items.remove_at(i)
						Sound.sfx("blip", 1.5)
				hurt_t = maxf(0.0, hurt_t - delta)
				for h in hazards:
					var hp: Vector2 = h["pos"]
					var hv: Vector2 = h["vel"]
					hp += hv * delta
					if hp.x < BOX.position.x + 8 or hp.x > BOX.end.x - 8:
						hv.x = -hv.x
					if hp.y < BOX.position.y + 8 or hp.y > BOX.end.y - 8:
						hv.y = -hv.y
					h["pos"] = hp.clamp(BOX.position + Vector2(8, 8), BOX.end - Vector2(8, 8))
					h["vel"] = hv
					if hurt_t <= 0.0 and hp.distance_to(soul) < 11.0:
						hurt_t = 1.0
						time_left -= 2.0
						flash = 0.3
						Sound.sfx("hurt")
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
				show_len = maxf(0.55, 0.85 - round_n * 0.1)
				show_t = show_len
				if shown <= seq.size():
					Sound.sfx("blip", ARROW_PITCH[seq[shown - 1]])
				if shown > seq.size():
					phase = "play"
					_info.text = "Ora ripeti con le frecce!"
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if phase != "play":
		return
	var tapped := event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed
	if type == "timing" and (event.is_action_pressed("confirm") or tapped):
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
	elif type == "bulbs":
		if event.is_action_pressed("move_right"):
			_bulb_answer(bulb == "buona")
		elif event.is_action_pressed("move_left"):
			_bulb_answer(bulb == "rotta")
		elif event.is_action_pressed("move_up") or event.is_action_pressed("move_down"):
			if bulb == "fioca":
				bulb_fix += 1
				Sound.sfx("move", 1.0 + bulb_fix * 0.2)
				if bulb_fix >= 2:
					bulb = "buona"
			else:
				_bulb_answer(false)
	elif type == "wires":
		var free_left: Array[int] = []
		for i in 4:
			if i not in wire_done:
				free_left.append(i)
		if event.is_action_pressed("move_up") or event.is_action_pressed("move_down"):
			var step := -1 if event.is_action_pressed("move_up") else 1
			if wire_pick < 0:
				var at := free_left.find(wire_sel)
				wire_sel = free_left[posmod(at + step, free_left.size())]
			else:
				wire_sel = posmod(wire_sel + step, 4)
			Sound.sfx("move")
		elif event.is_action_pressed("confirm") or event.is_action_pressed("move_right") or tapped:
			if wire_pick < 0:
				wire_pick = wire_sel
				wire_sel = 0
				Sound.sfx("select")
			else:
				# il filo di sinistra `wire_pick` va al posto di destra `wire_sel`
				if wire_right[wire_sel] == wire_pick:
					wire_done.append(wire_pick)
					Sound.sfx("coin")
					if wire_done.size() >= 4:
						wire_round += 1
						if wire_round >= 2:
							_finish(true)
							return
						_new_wires()
						return
				else:
					misses += 1
					flash = 0.3
					Sound.sfx("deny")
					if misses >= 4:
						_finish(false)
						return
				wire_pick = -1
				for i in 4:
					if i not in wire_done:
						wire_sel = i
						break
		elif event.is_action_pressed("move_left") and wire_pick >= 0:
			wire_sel = wire_pick
			wire_pick = -1
	elif type == "sequence":
		for a: String in ARROWS:
			if event.is_action_pressed("move_" + a):
				typed.append(a)
				Sound.sfx("blip", ARROW_PITCH[a])
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
	if cfg.has("quest"):
		# Il giorno dopo chi te l'ha chiesto ti dirà com'è andata.
		GameState.flags["quest_news_" + str(cfg["quest"])] = "done" if success else "fail"
	var lines: Array = []
	if success:
		Sound.sfx("spare")
		var reward := int(cfg.get("reward", 10))
		GameState.money += reward
		GameState.changed.emit()
		lines.append_array(cfg.get("win", ["Grazie!"]))
		if reward > 0:
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
			# gli imprevisti: rossi, con le punte
			for h in hazards:
				var hp: Vector2 = h["pos"]
				draw_circle(hp, 6, Color("c0302a"))
				for k in 4:
					var a := t_spin + k * PI / 2.0
					draw_line(hp, hp + Vector2.from_angle(a) * 10.0, Color("ff6a5a"), 2.0)
			if hurt_t <= 0.0 or int(hurt_t * 12) % 2 == 0:
				_heart(soul, RED)
		"bulbs":
			_draw_bulbs(font)
		"wires":
			_draw_wires(font)
		"sequence":
			var cx := BOX.get_center()
			# la freccia resta accesa per due terzi del tempo, poi si spegne: così si vede quando cambia
			if phase == "show" and shown >= 1 and shown <= seq.size() and show_t > show_len * 0.33:
				_arrow(cx, seq[shown - 1], 18.0, YELLOW)
			if phase == "show" and shown >= 1 and shown <= seq.size():
				draw_string(font, Vector2(BOX.position.x, BOX.end.y - 14), "%d / %d" % [shown, seq.size()], HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 14, Color("8a8494"))
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


func _draw_bulbs(font: Font) -> void:
	var c := BOX.get_center() + Vector2(0, -6)
	# a sinistra il secchio delle rotte, a destra la scatola delle buone
	draw_rect(Rect2(BOX.position.x + 14, BOX.end.y - 56, 70, 44), Color("6a2a2a"))
	draw_string(font, Vector2(BOX.position.x + 14, BOX.end.y - 62), "< ROTTE", HORIZONTAL_ALIGNMENT_CENTER, 70, 12, RED)
	draw_rect(Rect2(BOX.end.x - 84, BOX.end.y - 56, 70, 44), Color("b9894f"))
	draw_string(font, Vector2(BOX.end.x - 84, BOX.end.y - 62), "BUONE >", HORIZONTAL_ALIGNMENT_CENTER, 70, 12, GREEN)
	# la lampadina da guardare
	var glass := Color("ffe680")
	match bulb:
		"rotta":
			glass = Color("787882")
		"fioca":
			glass = Color("fff0c0") if int(bulb_t * 9.0) % 3 != 0 else Color("6a6458")
	if bulb == "buona" or (bulb == "fioca" and glass.v > 0.5):
		draw_circle(c, 34, Color(1, 0.92, 0.5, 0.18))
	draw_circle(c, 20, Color("221c28"))
	draw_circle(c, 18, glass)
	draw_circle(c + Vector2(-6, -6), 4, Color(1, 1, 1, 0.6))
	draw_rect(Rect2(c + Vector2(-9, 16), Vector2(18, 14)), Color("221c28"))
	draw_rect(Rect2(c + Vector2(-7, 17), Vector2(14, 12)), Color("a0a0aa"))
	for k in 3:
		draw_rect(Rect2(c + Vector2(-7, 19 + k * 4), Vector2(14, 1)), Color("6a6a74"))
	if bulb == "rotta":
		draw_line(c + Vector2(-10, -10), c + Vector2(4, 2), Color("221c28"), 2.0)
		draw_line(c + Vector2(4, 2), c + Vector2(-2, 12), Color("221c28"), 2.0)
	if bulb == "fioca":
		draw_string(font, Vector2(BOX.position.x, BOX.position.y + 18), "Sfarfalla! SU o GIÙ per avvitarla (%d/2)" % bulb_fix, HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 12, YELLOW)


func _draw_wires(font: Font) -> void:
	if wire_right.size() < 4:
		return
	var lx := BOX.position.x + 40
	var rx := BOX.end.x - 40
	var y0 := BOX.position.y + 26
	var gap := (BOX.size.y - 52) / 3.0
	draw_rect(Rect2(BOX.position.x + 10, BOX.position.y + 10, BOX.size.x - 20, BOX.size.y - 20), Color("3a3644"))
	for i in 4:
		var yl := y0 + i * gap
		var col: Color = WIRE_COLS[i]
		draw_rect(Rect2(lx - 30, yl - 4, 30, 8), col)
		var j := wire_right[i]
		var colr: Color = WIRE_COLS[j]
		draw_rect(Rect2(rx, y0 + i * gap - 4, 30, 8), colr)
		if i in wire_done:
			var to := wire_right.find(i)
			draw_line(Vector2(lx, yl), Vector2(rx, y0 + to * gap), col, 6.0)
	# cosa stai scegliendo
	if wire_pick < 0:
		draw_rect(Rect2(lx - 34, y0 + wire_sel * gap - 8, 38, 16), Color.WHITE, false, 2.0)
	else:
		var yl2 := y0 + wire_pick * gap
		var yr := y0 + wire_sel * gap
		draw_line(Vector2(lx, yl2), Vector2(rx, yr), WIRE_COLS[wire_pick], 4.0)
		draw_rect(Rect2(rx - 4, yr - 8, 38, 16), Color.WHITE, false, 2.0)
	draw_string(font, Vector2(BOX.position.x, BOX.end.y - 6), "Pannello %d di 2" % (wire_round + 1), HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 11, Color("8a8494"))


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
