class_name Arcade
extends RefCounted
## I giochi classici dei turni di lavoro, rifatti con la grafica di Cheap (sprite LimeZu):
##   "snake"    il mocio dei bagni: cresce a ogni macchia pulita (Snake)
##   "simon"    i quattro telefoni del call center: ripeti la sequenza di squilli (Simon)
##   "tetris"   lo scaffale del magazzino: incastra le scatole, ogni riga piena si spedisce (Tetris)
##   "frogger"  le consegne: attraversa la strada tra le auto fino alla porta (Frogger)
##   "breakout" la dinamo del -5: ogni mattoncino rotto accende una lampadina di sopra (Breakout)
##   "pong"     la cassa della banca: rimanda il debito al Signor Tasso (Pong)
##   "steal"    la promozione: copia il lavoro del collega quando non ti guarda (un, due, tre, stella!)
## `w` è la scena del turno (work.gd): qui si leggono e scrivono w.score, w.target, w.mistakes,
## w.time_left, w.d (difficoltà 0..1) e si disegna con w.draw_*.

const GAMES := ["snake", "simon", "tetris", "frogger", "breakout", "pong", "steal"]
const BOX := Rect2(120, 96, 400, 190)
const PHONES := {
	"up": Rect2(167, 632, 16, 15), "right": Rect2(201, 632, 16, 15),
	"down": Rect2(201, 665, 16, 15), "left": Rect2(167, 665, 16, 15),
}
const PAD_COL := {"up": Color("3ddc84"), "right": Color("39b6ff"), "down": Color("ff4a5a"), "left": Color("ffe14d")}
const PITCH := {"up": 1.5, "right": 1.25, "down": 0.75, "left": 1.0}

var game := ""
var w: Node2D
var t := 0.0

# snake
const SN_CELL := 18
const SN_COLS := 22
const SN_ROWS := 10
var sn_body: Array[Vector2i] = []
var sn_dir := Vector2i.RIGHT
var sn_next := Vector2i.RIGHT
var sn_step := 0.0
var sn_food: Array[Vector2i] = []
var sn_hurt := 0.0

# simon
var si_seq: Array[String] = []
var si_shown := 0
var si_show_t := 0.0
var si_input := 0
var si_phase := "show"
var si_lit := ""
var si_lit_t := 0.0

# tetris
const TE_COLS := 10
const TE_ROWS := 14
const TE_CELL := 13
const TE_SHAPES := [
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],
]
const TE_COLORS := [Color("c9a46a"), Color("e0b878"), Color("b9894f"), Color("d8c08a"), Color("a87a48"), Color("caa070"), Color("bf9058")]
var te_grid := {}
var te_piece: Array[Vector2i] = []
var te_pos := Vector2i.ZERO
var te_kind := 0
var te_fall := 0.0
var box_tex: Texture2D

# frogger
const FR_COLS := 13
const FR_ROWS := 7
var fr_pos := Vector2i(6, 6)
var fr_cars: Array[Dictionary] = []
var fr_hurt := 0.0
var car_tex: Array[Texture2D] = []
var car_tex_left: Array[Texture2D] = []
var hero: SpriteFrames

# breakout
var br_paddle := 320.0
var br_ball := Vector2.ZERO
var br_vel := Vector2.ZERO
var br_stuck := true
var br_bricks: Array[Rect2] = []
var br_lit := 0

# pong
var po_left := 0.0
var po_right := 0.0
var po_ball := Vector2.ZERO
var po_vel := Vector2.ZERO
var po_wait := 0.0
var tasso: SpriteFrames

# steal: il collega lavora (di spalle), si gira (attenzione!), ti guarda
var st_progress := 0.0
var st_state := "work"
var st_t := 2.0
var st_caught_t := 0.0
var st_victim: SpriteFrames
var st_name := ""
var st_item := ""


func setup(scene: Node2D, which: String) -> void:
	w = scene
	game = which
	var d: float = w.d
	match game:
		"snake":
			w.duration = 30.0
			w.target = 8.0 + d * 4.0
			sn_body = [Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5)]
			_sn_food()
		"simon":
			w.duration = 40.0
			w.target = 4.0 + d * 2.0
			_si_round(3)
		"tetris":
			w.duration = 50.0
			w.target = 3.0 + d * 3.0
			box_tex = Assets.tex("market/box_1.png", Vector2i(32, 32))
			_te_new()
		"frogger":
			w.duration = 40.0
			w.target = 3.0 + d * 2.0
			hero = Assets.character("char_01")
			for i in range(1, 7):
				car_tex.append(Assets.tex("cars/car_right_%d.png" % i, Vector2i(64, 48)))
				car_tex_left.append(Assets.tex("cars/car_left_%d.png" % i, Vector2i(64, 48)))
			for lane in range(1, 6):
				var dir := 1.0 if lane % 2 == 0 else -1.0
				var speed := (40.0 + lane * 9.0) * (1.0 + d * 0.8) * dir
				for k in 2 + int(d * 1.5):
					fr_cars.append({"lane": lane, "x": randf_range(0, BOX.size.x) + k * 150.0, "v": speed, "tex": randi() % 6})
		"breakout":
			w.duration = 40.0
			w.target = 14.0 + d * 8.0
			for r in 4:
				for c in 10:
					br_bricks.append(Rect2(BOX.position.x + 22 + c * 36, BOX.position.y + 14 + r * 14, 32, 10))
			br_paddle = BOX.get_center().x
		"steal":
			w.duration = 30.0
			w.target = 1.0
			st_victim = Assets.character(str(w.cfg.get("victim_sheet", "char_02")))
			st_name = str(w.cfg.get("victim_name", "il collega"))
			st_item = str(w.cfg.get("item", "il suo lavoro"))
			hero = Assets.character("char_01")
			st_t = randf_range(1.5, 2.5)
		"pong":
			w.duration = 40.0
			w.target = 4.0 + d * 2.0
			tasso = Assets.character("char_04")
			hero = Assets.character("char_01")
			po_left = BOX.get_center().y
			po_right = BOX.get_center().y
			_po_serve(1.0)
	w.time_left = w.duration


func set_game(which: String) -> Arcade:
	game = which
	return self


func rules() -> String:
	match game:
		"snake":
			return "* Muovi il mocio con le frecce. Ogni macchia pulita lo allunga. Non sbattere contro i muri o contro te stesso."
		"simon":
			return "* I telefoni squillano in sequenza. Guarda e ascolta, poi ripeti con le frecce. Ogni giro, uno squillo in più."
		"tetris":
			return "* Le scatole cadono: SINISTRA e DESTRA per spostarle, SU per girarle, GIÙ per farle scendere. Ogni riga piena viene spedita."
		"frogger":
			return "* Attraversa la strada con le frecce fino alle porte in alto. Ogni consegna conta. Le auto non si fermano."
		"breakout":
			return "* SINISTRA e DESTRA muovono la barra, {ok} lancia la pallina. Ogni lampadina che rompi si accende al piano di sopra."
		"steal":
			return "* Tieni premuto {ok} per copiare %s, ma solo quando %s ti dà le spalle. Quando si gira (lo vedi muovere la testa), lascia subito!" % [st_item if st_item != "" else "il suo lavoro", st_name if st_name != "" else "il collega"]
		"pong":
			return "* SU e GIÙ muovono la tua racchetta. Rimanda la moneta al Signor Tasso: se gli passa, è un punto per te."
	return ""


# --- aggiornamento ------------------------------------------------------------------

func update(delta: float) -> void:
	t += delta
	var d: float = w.d
	match game:
		"snake":
			sn_hurt = maxf(0.0, sn_hurt - delta)
			sn_step -= delta
			if sn_step <= 0.0:
				sn_step = maxf(0.08, 0.2 - d * 0.08)
				sn_dir = sn_next
				var head := sn_body[0] + sn_dir
				if head.x < 0 or head.y < 0 or head.x >= SN_COLS or head.y >= SN_ROWS or head in sn_body:
					_sn_crash()
					return
				sn_body.push_front(head)
				if head in sn_food:
					sn_food.erase(head)
					w.score += 1.0
					Sound.sfx("blip", 1.4)
					_sn_food()
				else:
					sn_body.pop_back()
		"simon":
			si_lit_t = maxf(0.0, si_lit_t - delta)
			if si_lit_t <= 0.0:
				si_lit = ""
			if si_phase == "show":
				si_show_t -= delta
				if si_show_t <= 0.0:
					if si_shown < si_seq.size():
						_si_light(si_seq[si_shown], maxf(0.3, 0.55 - d * 0.2))
						si_shown += 1
						si_show_t = maxf(0.45, 0.8 - d * 0.3)
					else:
						si_phase = "input"
						si_input = 0
		"tetris":
			te_fall -= delta
			var speed := maxf(0.18, 0.6 - d * 0.3)
			if Input.is_action_pressed("move_down"):
				speed = 0.05
			if te_fall <= 0.0:
				te_fall = speed
				if not _te_move(Vector2i(0, 1)):
					_te_lock()
		"frogger":
			fr_hurt = maxf(0.0, fr_hurt - delta)
			for c in fr_cars:
				c["x"] = fposmod(float(c["x"]) + float(c["v"]) * delta, BOX.size.x + 80.0)
			if fr_hurt <= 0.0:
				var me := _fr_cell_rect(fr_pos).grow(-6)
				for c in fr_cars:
					if int(c["lane"]) == fr_pos.y and me.intersects(_fr_car_rect(c)):
						fr_hurt = 1.0
						w.mistakes += 1
						w.flash_now(Color("ff2a3c"))
						Sound.sfx("honk")
						fr_pos = Vector2i(6, 6)
						break
		"breakout":
			var v := Input.get_axis("move_left", "move_right")
			br_paddle = clampf(br_paddle + v * 260.0 * delta, BOX.position.x + 30, BOX.end.x - 30)
			if br_stuck:
				br_ball = Vector2(br_paddle, BOX.end.y - 24)
				return
			br_ball += br_vel * delta
			if br_ball.x < BOX.position.x + 6 or br_ball.x > BOX.end.x - 6:
				br_vel.x = -br_vel.x
				br_ball.x = clampf(br_ball.x, BOX.position.x + 6, BOX.end.x - 6)
			if br_ball.y < BOX.position.y + 6:
				br_vel.y = absf(br_vel.y)
			var pad := Rect2(br_paddle - 28, BOX.end.y - 18, 56, 6)
			if br_vel.y > 0 and pad.has_point(br_ball):
				br_vel.y = -absf(br_vel.y)
				br_vel.x = (br_ball.x - br_paddle) * 5.0
				br_vel = br_vel.normalized() * (170.0 + d * 80.0)
				Sound.sfx("blip", 0.9)
			for i in range(br_bricks.size() - 1, -1, -1):
				if br_bricks[i].grow(3).has_point(br_ball):
					br_bricks.remove_at(i)
					br_vel.y = -br_vel.y
					w.score += 1.0
					br_lit += 1
					Sound.sfx("ding", 1.2 + randf() * 0.3)
					break
			if br_bricks.is_empty():
				setup_bricks()
			if br_ball.y > BOX.end.y:
				w.mistakes += 1
				w.flash_now(Color("ff2a3c"))
				Sound.sfx("deny")
				br_stuck = true
		"steal":
			st_progress = maxf(st_progress, w.score)
			st_caught_t = maxf(0.0, st_caught_t - delta)
			st_t -= delta
			if st_t <= 0.0:
				match st_state:
					"work":
						st_state = "turn"
						st_t = maxf(0.3, 0.7 - d * 0.35)
					"turn":
						st_state = "look"
						st_t = randf_range(0.9, 1.6)
					_:
						st_state = "work"
						st_t = randf_range(maxf(0.7, 1.4 - d * 0.6), maxf(1.4, 2.8 - d * 1.0))
			var copying := Input.is_action_pressed("confirm") and st_caught_t <= 0.0
			if copying:
				if st_state == "look":
					# beccato!
					w.mistakes += 1
					st_progress = maxf(0.0, st_progress - 0.25)
					st_caught_t = 1.2
					w.flash_now(Color("ff2a3c"))
					Sound.sfx("deny")
				else:
					st_progress = minf(1.0, st_progress + (0.2 - d * 0.06) * delta)
					if int(t * 8) % 2 == 0:
						Sound.sfx("step", 1.8)
			w.score = st_progress
			if st_progress >= 1.0 or w.mistakes >= 3:
				w.time_left = 0.0
		"pong":
			var vy := Input.get_axis("move_up", "move_down")
			po_left = clampf(po_left + vy * 200.0 * delta, BOX.position.y + 22, BOX.end.y - 22)
			# il Signor Tasso segue la moneta, ma non troppo in fretta
			var ai := 80.0 + d * 70.0
			po_right = move_toward(po_right, po_ball.y, ai * delta)
			po_right = clampf(po_right, BOX.position.y + 22, BOX.end.y - 22)
			if po_wait > 0.0:
				po_wait -= delta
				return
			po_ball += po_vel * delta
			if po_ball.y < BOX.position.y + 6 or po_ball.y > BOX.end.y - 6:
				po_vel.y = -po_vel.y
			var lp := Rect2(BOX.position.x + 22, po_left - 20, 6, 40)
			var rp := Rect2(BOX.end.x - 28, po_right - 20, 6, 40)
			if po_vel.x < 0 and lp.grow(3).has_point(po_ball):
				po_vel.x = absf(po_vel.x) * 1.05
				po_vel.y = (po_ball.y - po_left) * 4.0
				Sound.sfx("blip", 1.1)
			elif po_vel.x > 0 and rp.grow(3).has_point(po_ball):
				po_vel.x = -absf(po_vel.x) * 1.05
				po_vel.y = (po_ball.y - po_right) * 4.0
				Sound.sfx("blip", 0.8)
			if po_ball.x > BOX.end.x:
				w.score += 1.0
				Sound.sfx("coin")
				_po_serve(-1.0)
			elif po_ball.x < BOX.position.x:
				w.mistakes += 1
				w.flash_now(Color("ff2a3c"))
				Sound.sfx("deny")
				_po_serve(1.0)


func input(event: InputEvent) -> void:
	match game:
		"snake":
			var map := {"move_up": Vector2i.UP, "move_down": Vector2i.DOWN, "move_left": Vector2i.LEFT, "move_right": Vector2i.RIGHT}
			for a: String in map:
				if event.is_action_pressed(a) and (map[a] as Vector2i) != -sn_dir:
					sn_next = map[a]
		"simon":
			if si_phase != "input":
				return
			for dir: String in PAD_COL:
				if event.is_action_pressed("move_" + dir):
					_si_light(dir, 0.25)
					if dir == si_seq[si_input]:
						si_input += 1
						if si_input >= si_seq.size():
							w.score += 1.0
							w.flash_now(Color("3ddc84"))
							Sound.sfx("select")
							_si_round(si_seq.size() + 1)
					else:
						w.mistakes += 1
						w.flash_now(Color("ff2a3c"))
						Sound.sfx("deny")
						_si_round(si_seq.size(), true)
		"tetris":
			if event.is_action_pressed("move_left"):
				_te_move(Vector2i(-1, 0))
			elif event.is_action_pressed("move_right"):
				_te_move(Vector2i(1, 0))
			elif event.is_action_pressed("move_up"):
				_te_rotate()
		"frogger":
			var map2 := {"move_up": Vector2i.UP, "move_down": Vector2i.DOWN, "move_left": Vector2i.LEFT, "move_right": Vector2i.RIGHT}
			for a: String in map2:
				if event.is_action_pressed(a):
					var n: Vector2i = fr_pos + map2[a]
					if n.x >= 0 and n.x < FR_COLS and n.y >= 0 and n.y < FR_ROWS:
						fr_pos = n
						Sound.sfx("step", 1.2)
					if fr_pos.y == 0:
						w.score += 1.0
						Sound.sfx("coin")
						w.flash_now(Color("3ddc84"))
						fr_pos = Vector2i(6, 6)
		"breakout":
			if br_stuck and event.is_action_pressed("confirm"):
				br_stuck = false
				br_vel = Vector2(randf_range(-0.6, 0.6), -1.0).normalized() * (170.0 + w.d * 80.0)


# --- disegno --------------------------------------------------------------------------

func draw(font: Font) -> void:
	match game:
		"snake":
			_draw_snake()
		"simon":
			_draw_simon(font)
		"tetris":
			_draw_tetris(font)
		"frogger":
			_draw_frogger()
		"breakout":
			_draw_breakout(font)
		"pong":
			_draw_pong(font)
		"steal":
			_draw_steal(font)


func _sn_origin() -> Vector2:
	return BOX.position + (BOX.size - Vector2(SN_COLS, SN_ROWS) * SN_CELL) / 2.0


func _draw_snake() -> void:
	var o := _sn_origin()
	var tiles := Assets.tex("tiles/room_builder.png")
	for y in SN_ROWS:
		for x in SN_COLS:
			w.draw_texture_rect_region(tiles, Rect2(o + Vector2(x, y) * SN_CELL, Vector2(SN_CELL, SN_CELL)), Rect2((42 + x % 3) * 16, (25 + y % 2) * 16, 16, 16))
	for f in sn_food:
		var c := o + (Vector2(f) + Vector2(0.5, 0.5)) * SN_CELL
		w.draw_circle(c, 6, Color("6b4a1e"))
		w.draw_circle(c + Vector2(4, 2), 3, Color("6b4a1e"))
	var blink := sn_hurt > 0.0 and int(t * 12) % 2 == 0
	if blink:
		return
	for i in range(sn_body.size() - 1, -1, -1):
		var r := Rect2(o + Vector2(sn_body[i]) * SN_CELL + Vector2(2, 2), Vector2(SN_CELL - 4, SN_CELL - 4))
		if i == 0:
			# la testa del mocio: frange grigie e il manico
			w.draw_rect(r.grow(1), Color("d8d8d0"))
			for k in 4:
				w.draw_rect(Rect2(r.position + Vector2(1 + k * 4, r.size.y - 4), Vector2(2, 5)), Color("a8a8a0"))
			w.draw_rect(Rect2(r.get_center() - Vector2(1, 8), Vector2(3, 8)), Color("8a5a2a"))
		else:
			w.draw_rect(r, Color("9fd0f0") if i % 2 == 0 else Color("7fb8e0"))


func _draw_simon(font: Font) -> void:
	var c := BOX.get_center()
	var pos := {"up": c + Vector2(0, -56), "down": c + Vector2(0, 56), "left": c + Vector2(-120, 0), "right": c + Vector2(120, 0)}
	var sheet := Assets.tex("tiles/generic.png", Vector2i(256, 1248))
	for dir: String in PAD_COL:
		var p: Vector2 = pos[dir]
		var on := si_lit == dir
		var col: Color = PAD_COL[dir]
		w.draw_rect(Rect2(p - Vector2(34, 22), Vector2(68, 44)), col if on else col.darkened(0.7))
		w.draw_rect(Rect2(p - Vector2(34, 22), Vector2(68, 44)), Color.WHITE if on else Color("3a3644"), false, 2.0)
		var shake := Vector2(sin(t * 60.0) * 2.0, 0) if on else Vector2.ZERO
		w.draw_texture_rect_region(sheet, Rect2(p - Vector2(16, 15) + shake, Vector2(32, 30)), PHONES[dir])
	var msg := "Guarda e ascolta..." if si_phase == "show" else "Tocca a te: %d / %d" % [si_input, si_seq.size()]
	w.draw_string(font, Vector2(c.x - 100, c.y + 5), msg, HORIZONTAL_ALIGNMENT_CENTER, 200, 12, Color.WHITE)


func _te_origin() -> Vector2:
	return Vector2(BOX.get_center().x - TE_COLS * TE_CELL / 2.0, BOX.position.y + 3)


func _draw_tetris(font: Font) -> void:
	var o := _te_origin()
	w.draw_rect(Rect2(o - Vector2(2, 2), Vector2(TE_COLS, TE_ROWS) * TE_CELL + Vector2(4, 4)), Color("2a2633"))
	for cell: Vector2i in te_grid:
		_te_box(o, cell, TE_COLORS[int(te_grid[cell])])
	for b in te_piece:
		_te_box(o, te_pos + b, TE_COLORS[te_kind])
	w.draw_string(font, Vector2(BOX.position.x + 8, BOX.position.y + 30), "Righe spedite", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("8a8494"))
	w.draw_string(font, Vector2(BOX.position.x + 8, BOX.position.y + 50), "%d" % int(w.score), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)


## Una scatola di cartone: il colore, il nastro adesivo in mezzo e il bordo scuro.
func _te_box(o: Vector2, cell: Vector2i, col: Color) -> void:
	var r := Rect2(o + Vector2(cell) * TE_CELL, Vector2(TE_CELL, TE_CELL))
	w.draw_rect(r, col)
	w.draw_rect(Rect2(r.position + Vector2(r.size.x / 2.0 - 1.5, 0), Vector2(3, r.size.y)), Color("e8d29a"))
	w.draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), col.lightened(0.25))
	w.draw_rect(r, Color("5c3f22"), false, 1.0)


func _fr_cell_size() -> Vector2:
	return Vector2(BOX.size.x / FR_COLS, BOX.size.y / FR_ROWS)


func _fr_cell_rect(cell: Vector2i) -> Rect2:
	var s := _fr_cell_size()
	return Rect2(BOX.position + Vector2(cell) * s, s)


func _fr_car_rect(c: Dictionary) -> Rect2:
	var s := _fr_cell_size()
	return Rect2(BOX.position.x + float(c["x"]) - 40.0, BOX.position.y + int(c["lane"]) * s.y + 2, 40, s.y - 4)


func _draw_frogger() -> void:
	var s := _fr_cell_size()
	for row in FR_ROWS:
		var r := Rect2(BOX.position + Vector2(0, row * s.y), Vector2(BOX.size.x, s.y))
		if row == 0 or row == FR_ROWS - 1:
			w.draw_rect(r, Color("c8c0b0"))
		else:
			w.draw_rect(r, Color("3a3a44"))
			for x in range(0, int(BOX.size.x) - 14, 30):
				w.draw_rect(Rect2(r.position.x + x, r.end.y - 2, 14, 2), Color("d8d8c0"))
	# le porte dove consegnare, in alto
	for k in 4:
		w.draw_rect(Rect2(BOX.position.x + 30 + k * 100, BOX.position.y + 3, 22, s.y - 6), Color("6a4a30"))
		w.draw_rect(Rect2(BOX.position.x + 46 + k * 100, BOX.position.y + 12, 3, 3), Color("ffe14d"))
	for c in fr_cars:
		var cr := _fr_car_rect(c)
		if cr.position.x < BOX.position.x + 2 or cr.end.x > BOX.end.x - 2:
			continue
		var tex: Texture2D = car_tex[int(c["tex"])] if float(c["v"]) > 0 else car_tex_left[int(c["tex"])]
		w.draw_texture_rect(tex, cr, false)
	if fr_hurt > 0.0 and int(t * 12) % 2 == 0:
		return
	var me := _fr_cell_rect(fr_pos)
	var frame := hero.get_frame_texture("walk_up", int(t * 8) % 6)
	w.draw_texture_rect(frame, Rect2(me.get_center() - Vector2(8, 22), Vector2(16, 32)), false)


func setup_bricks() -> void:
	br_bricks.clear()
	for r in 4:
		for c in 10:
			br_bricks.append(Rect2(BOX.position.x + 22 + c * 36, BOX.position.y + 14 + r * 14, 32, 10))


func _draw_breakout(font: Font) -> void:
	# le finestre del piano di sopra: si accendono una per lampadina rotta
	for i in 20:
		var on := i < br_lit
		w.draw_rect(Rect2(BOX.position.x + 12 + i * 19, BOX.position.y - 18, 14, 10), Color("ffe9a8") if on else Color("2a2633"))
	for b in br_bricks:
		w.draw_circle(b.get_center() + Vector2(0, -1), 5, Color("e8e0b0"))
		w.draw_rect(Rect2(b.get_center() + Vector2(-3, 3), Vector2(6, 3)), Color("8a8494"))
	w.draw_rect(Rect2(br_paddle - 28, BOX.end.y - 18, 56, 6), Color("aeb4c4"))
	w.draw_rect(Rect2(br_paddle - 28, BOX.end.y - 18, 56, 2), Color("dfe3ec"))
	w.draw_circle(br_ball, 4, Color("ffe14d"))
	if br_stuck:
		w.draw_string(font, Vector2(BOX.position.x, BOX.end.y - 34), GameState.fmt("{ok} per lanciare"), HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 12, Color("8a8494"))


func _draw_steal(font: Font) -> void:
	# l'ufficio: il pavimento, la scrivania del collega, lui seduto di spalle
	w.draw_rect(BOX.grow(-3), Color("d9cbb0"))
	for x in range(int(BOX.position.x) + 3, int(BOX.end.x) - 3, 24):
		w.draw_rect(Rect2(x, BOX.position.y + 3, 1, BOX.size.y - 6), Color("cbbd9f"))
	var desk_sheet := Assets.tex("tiles/generic.png", Vector2i(256, 1248))
	var dpos := Vector2(BOX.get_center().x + 40, BOX.position.y + 20)
	w.draw_texture_rect_region(desk_sheet, Rect2(dpos, Vector2(48, 120)), Rect2(96, 8, 16, 40))
	var anim := {"work": "idle_up", "turn": "idle_left", "look": "idle_down"}[st_state] as String
	var vf := st_victim.get_frame_texture(anim, int(t * 6) % 6)
	w.draw_texture_rect(vf, Rect2(dpos + Vector2(0, 46), Vector2(48, 96)), false)
	# il foglio con l'idea, sul bordo della scrivania
	var paper := Rect2(dpos + Vector2(-34, 70), Vector2(26, 32))
	w.draw_rect(paper, Color("f6f2e6"))
	for k in 5:
		w.draw_rect(Rect2(paper.position + Vector2(4, 6 + k * 5), Vector2(18, 1)), Color("8a8494"))
	# tu, che sbirci
	var copying := Input.is_action_pressed("confirm") and st_caught_t <= 0.0
	var hf := hero.get_frame_texture("walk_right" if copying else "idle_right", int(t * 10) % 6)
	w.draw_texture_rect(hf, Rect2(Vector2(BOX.position.x + 60, BOX.position.y + 66), Vector2(48, 96)), false)
	# i segnali: la testa che si gira, lo sguardo che ti becca
	if st_state == "turn":
		w.draw_string(font, dpos + Vector2(10, 40), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("ffe14d"))
	elif st_state == "look":
		w.draw_string(font, dpos + Vector2(10, 40), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("ff2a3c"))
	if st_caught_t > 0.0:
		w.draw_string(font, Vector2(BOX.position.x, BOX.position.y + 22), "\"Ehi! Cosa stai guardando?\"", HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 13, Color("ff2a3c"))
	# quanto hai copiato
	var bar := Rect2(BOX.position.x + 30, BOX.end.y - 22, BOX.size.x - 60, 10)
	w.draw_rect(bar, Color("3a3644"))
	w.draw_rect(Rect2(bar.position, Vector2(bar.size.x * st_progress, bar.size.y)), Color("3ddc84"))
	w.draw_string(font, Vector2(bar.position.x, bar.position.y - 4), "Copiato: %d%%" % int(st_progress * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("3a3644"))


func _draw_pong(font: Font) -> void:
	for y in range(int(BOX.position.y) + 4, int(BOX.end.y) - 4, 14):
		w.draw_rect(Rect2(BOX.get_center().x - 1, y, 2, 7), Color("3a3644"))
	w.draw_rect(Rect2(BOX.position.x + 22, po_left - 20, 6, 40), Color.WHITE)
	w.draw_rect(Rect2(BOX.end.x - 28, po_right - 20, 6, 40), Color("ffe14d"))
	w.draw_texture_rect(hero.get_frame_texture("idle_right", int(t * 6) % 6), Rect2(BOX.position.x + 2, po_left - 16, 16, 32), false)
	w.draw_texture_rect(tasso.get_frame_texture("idle_left", int(t * 6) % 6), Rect2(BOX.end.x - 18, po_right - 16, 16, 32), false)
	w.draw_circle(po_ball, 5, Color("f0c040"))
	w.draw_circle(po_ball, 3, Color("c88c1e"))
	w.draw_string(font, Vector2(BOX.position.x, BOX.position.y + 16), "Tu %d   -   %d Signor Tasso" % [int(w.score), int(w.mistakes)], HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 12, Color("8a8494"))


# --- aiuti ------------------------------------------------------------------------------

func _sn_food() -> void:
	while sn_food.size() < 1 + int(w.d * 2.0):
		var c := Vector2i(randi() % SN_COLS, randi() % SN_ROWS)
		if c not in sn_body and c not in sn_food:
			sn_food.append(c)


func _sn_crash() -> void:
	w.mistakes += 1
	w.flash_now(Color("ff2a3c"))
	Sound.sfx("hurt")
	sn_hurt = 1.0
	var keep := maxi(3, sn_body.size() - 2)
	sn_body = [Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5)]
	for i in keep - 3:
		sn_body.append(Vector2i(maxi(0, 2 - i), 5))
	sn_dir = Vector2i.RIGHT
	sn_next = Vector2i.RIGHT


func _si_round(n: int, same := false) -> void:
	if not same:
		si_seq.clear()
		for i in n:
			si_seq.append(PAD_COL.keys().pick_random())
	si_shown = 0
	si_input = 0
	si_show_t = 0.8
	si_phase = "show"


func _si_light(dir: String, time: float) -> void:
	si_lit = dir
	si_lit_t = time
	Sound.sfx("ding", PITCH[dir])


func _te_new() -> void:
	te_kind = randi() % TE_SHAPES.size()
	te_piece.assign(TE_SHAPES[te_kind])
	te_pos = Vector2i(TE_COLS / 2 - 2, 0)
	if not _te_fits(te_pos, te_piece):
		# lo scaffale è pieno: si svuota, ma è un errore
		te_grid.clear()
		w.mistakes += 2
		w.flash_now(Color("ff2a3c"))
		Sound.sfx("hurt")


func _te_fits(pos: Vector2i, piece: Array[Vector2i]) -> bool:
	for b in piece:
		var c := pos + b
		if c.x < 0 or c.x >= TE_COLS or c.y >= TE_ROWS or te_grid.has(c):
			return false
	return true


func _te_move(d: Vector2i) -> bool:
	if _te_fits(te_pos + d, te_piece):
		te_pos += d
		return true
	return false


func _te_rotate() -> void:
	var rot: Array[Vector2i] = []
	for b in te_piece:
		rot.append(Vector2i(2 - b.y, b.x))
	for kick in [0, -1, 1, -2, 2]:
		if _te_fits(te_pos + Vector2i(kick, 0), rot):
			te_piece = rot
			te_pos.x += kick
			Sound.sfx("move")
			return


func _te_lock() -> void:
	for b in te_piece:
		te_grid[te_pos + b] = te_kind
	Sound.sfx("step", 0.8)
	var y := TE_ROWS - 1
	while y >= 0:
		var full := true
		for x in TE_COLS:
			if not te_grid.has(Vector2i(x, y)):
				full = false
				break
		if full:
			var moved := {}
			for cell: Vector2i in te_grid:
				if cell.y < y:
					moved[cell + Vector2i(0, 1)] = te_grid[cell]
				elif cell.y > y:
					moved[cell] = te_grid[cell]
			te_grid = moved
			w.score += 1.0
			w.flash_now(Color("3ddc84"))
			Sound.sfx("coin")
		else:
			y -= 1
	_te_new()


func _po_serve(dir: float) -> void:
	po_ball = BOX.get_center()
	po_vel = Vector2(dir, randf_range(-0.5, 0.5)).normalized() * (150.0 + w.d * 70.0)
	po_wait = 0.8
