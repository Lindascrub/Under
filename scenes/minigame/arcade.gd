class_name Arcade
extends RefCounted

const Art := preload("res://scripts/minigame_art.gd")
## Il furto dell'idea, con la grafica di Cheap (sprite LimeZu):
##   "steal"    la promozione: copia il lavoro del collega quando non ti guarda (un, due, tre, stella!)
## `w` è la scena del turno (work.gd): qui si leggono e scrivono w.score, w.target, w.mistakes,
## w.time_left, w.d (difficoltà 0..1) e si disegna con w.draw_*.

const GAMES := ["steal"]
const BOX := Rect2(120, 96, 400, 190)

var game := ""
var w: Node2D
var t := 0.0

# steal: il collega lavora (di spalle), si gira (attenzione!), ti guarda
var st_progress := 0.0
var st_state := "work"
var st_t := 2.0
var st_caught_t := 0.0
var st_victim: SpriteFrames
var st_name := ""
var st_item := ""
## un, due, tre, stella: tu ti avvicini (st_x) mentre il collega ti dà le spalle
var st_x := 0.0
var st_seated := false
var st_bump := 0.0
const ST_START := 168.0
const ST_DESK := 352.0
var hero: SpriteFrames


func setup(scene: Node2D, which: String) -> void:
	w = scene
	game = which
	var d: float = w.d
	match game:
		"steal":
			w.duration = 30.0
			w.target = 1.0
			st_victim = Assets.character(str(w.cfg.get("victim_sheet", "char_02")))
			st_name = str(w.cfg.get("victim_name", "il collega"))
			st_item = str(w.cfg.get("item", "il suo lavoro"))
			hero = Assets.character("char_01")
			st_t = randf_range(1.5, 2.5)
			st_x = ST_START
			st_seated = bool(w.cfg.get("seated", false))
	w.time_left = w.duration


func set_game(which: String) -> Arcade:
	game = which
	return self


func rules() -> String:
	if TouchControls.enabled:
		match game:
			"steal":
				return "* Un, due, tre, stella. Tieni il dito sullo schermo per avvicinarti a %s, e tienilo ancora per copiare %s. Quando si gira (vedi \"?\"), STACCA il dito: se ti vede muovere, ti rimanda indietro. C'è poco tempo." % [st_name if st_name != "" else "il collega", st_item if st_item != "" else "il suo lavoro"]
	# (solo PC) da qui in giù: il telefono è già tornato sopra
	match game:
		"steal":
			return "* Un, due, tre, stella. Avvicinati di soppiatto a %s tenendo premuto DESTRA, poi tieni premuto {ok} per copiare %s. Quando si gira (vedi \"?\"), fermati: se ti vede muovere, ti rimanda indietro. C'è poco tempo." % [st_name if st_name != "" else "il collega", st_item if st_item != "" else "il suo lavoro"]
	return ""


# --- aggiornamento ------------------------------------------------------------------

func update(delta: float) -> void:
	t += delta
	var d: float = w.d
	match game:
		"steal":
			st_progress = maxf(st_progress, w.score)
			st_caught_t = maxf(0.0, st_caught_t - delta)
			st_bump = maxf(0.0, st_bump - delta * 4.0)
			st_t -= delta
			if st_t <= 0.0:
				match st_state:
					"work":
						st_state = "turn"
						st_t = maxf(0.3, 0.7 - d * 0.35)
						Sound.sfx("step", 0.7)
					"turn":
						st_state = "look"
						st_bump = 1.0
						st_t = randf_range(0.9, 1.6)
					_:
						st_state = "work"
						st_t = randf_range(maxf(0.7, 1.4 - d * 0.6), maxf(1.4, 2.8 - d * 1.0))
			if st_caught_t > 0.0:
				return
			var walking := Input.is_action_pressed("move_right") and st_x < ST_DESK
			var copying := Input.is_action_pressed("confirm") and st_x >= ST_DESK
			if (walking or copying) and st_state == "look":
				# beccato! torni indietro, e quello che avevi copiato in parte si perde
				w.mistakes += 1
				st_progress = maxf(0.0, st_progress - 0.25)
				st_x = maxf(ST_START, st_x - 70.0)
				st_caught_t = 1.2
				w.flash_now(Color("ff2a3c"))
				Sound.sfx("deny")
			elif walking:
				st_x = minf(ST_DESK, st_x + (55.0 + d * 15.0) * delta)
				if int(t * 6) % 2 == 0:
					Sound.sfx("step", 1.2)
			elif copying:
				st_progress = minf(1.0, st_progress + (0.22 - d * 0.06) * delta)
				if int(t * 8) % 2 == 0:
					Sound.sfx("step", 1.8)
			w.score = st_progress
			if st_progress >= 1.0 or w.mistakes >= 3:
				w.time_left = 0.0


## Il furto si gioca tenendo premuto (Input.is_action_pressed in update): niente da fare qui.
func input(_event: InputEvent) -> void:
	pass


# --- col dito (vedi TouchControls) ------------------------------------------------------

func touch_scheme() -> String:
	match game:
		"steal":
			return "hold"
	return "point"


func touch_center() -> Vector2:
	return BOX.get_center()


## Un, due, tre, stella: il dito giù = cammini (o copi, quando sei arrivato alla scrivania).
func touch_hold() -> Array:
	return ["move_right", "confirm"]


func touch_point(_pos: Vector2, _step: int) -> void:
	pass


# --- disegno --------------------------------------------------------------------------

func draw(font: Font) -> void:
	match game:
		"steal":
			_draw_steal(font)


func _draw_steal(font: Font) -> void:
	# il pavimento dell'ufficio (o del Fondo)
	w.draw_rect(BOX.grow(-3), Color("d9cbb0"))
	for x in range(int(BOX.position.x) + 3, int(BOX.end.x) - 3, 24):
		w.draw_rect(Rect2(x, BOX.position.y + 3, 1, BOX.size.y - 6), Color("cbbd9f"))
	var floor_y := BOX.position.y + 150
	var vpos := Vector2(ST_DESK + 56, floor_y)
	# il collega: di spalle mentre lavora, si gira, ti guarda
	var anim := ""
	if st_seated:
		anim = {"work": "sit_right", "turn": "idle_up", "look": "sit_left"}[st_state]

	else:
		anim = {"work": "idle_up", "turn": "idle_left", "look": "idle_down"}[st_state]
	var hop := -6.0 * st_bump
	var shake := Vector2(sin(t * 60.0) * 2.0, 0) if st_state == "turn" else Vector2.ZERO
	var vf := st_victim.get_frame_texture(anim, int(t * 6) % 6)
	var vrect := Rect2(vpos + Vector2(-24, -96 + hop) + shake, Vector2(48, 96))
	if st_seated:
		vrect.position.y -= 14
	w.draw_texture_rect(vf, vrect, false)
	if st_seated:
		# la cassetta davanti alle gambe: Fermo ci sta seduto sopra
		var crate := Assets.tex("street/box_trash.png", Vector2i(16, 16))
		w.draw_texture_rect(crate, Rect2(vpos + Vector2(-22, -40), Vector2(44, 40)), false)
	# il quaderno, per terra accanto a lui
	var book := Rect2(ST_DESK - 10, floor_y - 22, 24, 18)
	Art.paper(w, book, Color("f6f2e6"))
	for k in 3:
		w.draw_rect(Rect2(book.position + Vector2(4, 5 + k * 4), Vector2(16, 1)), Color("8a8494"))
	# tu: cammini di soppiatto, ti fermi, copi
	var walking := Input.is_action_pressed("move_right") and st_x < ST_DESK and st_caught_t <= 0.0
	var copying := Input.is_action_pressed("confirm") and st_x >= ST_DESK and st_caught_t <= 0.0
	var hanim := "walk_right" if walking else ("phone" if copying else "idle_right")
	var hf := hero.get_frame_texture(hanim, int(t * 10) % 6)
	w.draw_texture_rect(hf, Rect2(Vector2(st_x - 24, floor_y - 96), Vector2(48, 96)), false)
	# i segnali: la testa che si gira, lo sguardo che ti becca
	var sign_pos := vpos + Vector2(-6, -112 if not st_seated else -142)
	if st_state == "turn":
		w.draw_string(font, sign_pos, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("ffe14d"))
	elif st_state == "look":
		w.draw_string(font, sign_pos, "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("ff2a3c"))
	if st_caught_t > 0.0:
		w.draw_string(font, Vector2(BOX.position.x, BOX.position.y + 22), "\"Ehi! Cosa stai facendo?\"", HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 14, Color("ff2a3c"))
	elif st_x < ST_DESK:
		w.draw_string(font, Vector2(BOX.position.x, BOX.position.y + 22), "Dito giù: avvicinati. Si gira? Stacca il dito!" if TouchControls.enabled else "Tieni DESTRA per avvicinarti. Fermati quando si gira!", HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 11, Color("3a3644"))
	else:
		w.draw_string(font, Vector2(BOX.position.x, BOX.position.y + 22), "Dito giù: copia. Si gira? Stacca il dito!" if TouchControls.enabled else GameState.fmt("Tieni {ok} per copiare. Lascia quando si gira!"), HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 11, Color("3a3644"))
	# il tempo che resta, grande
	w.draw_string(font, Vector2(BOX.end.x - 70, BOX.position.y + 44), "%d" % int(ceil(maxf(0.0, w.time_left))), HORIZONTAL_ALIGNMENT_RIGHT, 60, 26, Color("c0302a") if w.time_left < 10.0 else Color("3a3644"))
	# quanto hai copiato
	var bar := Rect2(BOX.position.x + 30, BOX.end.y - 18, BOX.size.x - 60, 8)
	w.draw_rect(bar, Color("3a3644"))
	w.draw_rect(Rect2(bar.position, Vector2(bar.size.x * st_progress, bar.size.y)), Color("3ddc84"))
	w.draw_string(font, Vector2(bar.position.x, bar.position.y - 4), "Copiato: %d%%" % int(st_progress * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("3a3644"))


# --- aiuti ------------------------------------------------------------------------------

