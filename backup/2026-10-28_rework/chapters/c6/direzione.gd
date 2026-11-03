extends Node2D

const Art := preload("res://scripts/minigame_art.gd")
## Capitolo 6 — il TURNO di Direzione: uno schermo, tre cicli (GameState.minigame = {"cycle": n}).
## Non c'è uno stipendio: si dividono 100 unità fra stipendi, servizi, manutenzione e riserve.
## Le regole sono in direzione_regole.gd; qui c'è solo lo schermo (dito, mouse, tastiera).
## Il ciclo 2 decide anche della Casa Comune, il ciclo 3 della regola dei debiti.
## Alla conferma lo stato comune va in GameState.flags["chapter_6"]["director_turn"], poi si torna alla Cima.

const RULES := preload("res://chapters/c6/direzione_regole.gd")
const CIMA := "res://chapters/c6/cima.tscn"
const PRES := "La Presidente"
const VOICE := "Voce CHEAP"
const GOLD := Color("ffe14d")
const GREEN := Color("3ddc84")
const RED := Color("ff2a3c")
const DIM := Color("8a8494")
const PANEL := Color("1a1420")

## Le righe delle voci, i pulsanti e CONFERMA (in coordinate dello schermo 640x360).
const ROW_Y := 88
const ROW_H := 44

var cycle := 1
var st: Dictionary = {}
var alloc: Dictionary = {}
## "alloc" (si dividono le unità), "casa" (ciclo 2), "debiti" (ciclo 3), "done"
var phase := "intro"
var sel := 0
var msg := ""
var options: Array = []
var choice_id := ""


func _ready() -> void:
	cycle = int(GameState.minigame.get("cycle", 1))
	var dt := _dt()
	if dt.get("cycle_%d_completed" % cycle, false):
		# già fatto (un caricamento, un tocco di troppo): niente doppioni
		Router.goto(CIMA, "desk")
		return
	st = (dt.get("state", {}) as Dictionary).duplicate(true)
	if st.is_empty():
		st = RULES.new_state()
	st["cycle"] = cycle
	alloc = RULES.start_alloc(st)
	Ui.show_hud(false)
	Sound.music("cima")
	queue_redraw()
	await get_tree().process_frame
	await _intro()
	phase = "alloc"
	queue_redraw()


func _dt() -> Dictionary:
	var c6: Dictionary = GameState.flags.get("chapter_6", {})
	if not c6.has("director_turn"):
		c6["director_turn"] = {}
	GameState.flags["chapter_6"] = c6
	return c6["director_turn"]


## Cosa c'è sul tavolo all'inizio del ciclo (con le spese già annunciate).
func situation() -> Array:
	var out: Array = []
	match cycle:
		1:
			out = ["I lavoratori chiedono un aumento.", "La manutenzione richiede fondi.", "E naturalmente dobbiamo mantenere delle riserve."]
		2:
			out = ["La Casa Comune, i trasporti, gli sportelli: chi li paga, chi li usa, chi li decide."]
			match RULES.casa_state():
				"riconversione":
					out.append("La Casa Comune è un centro CHEAP, con il tornello. Si può comprare l'accesso, o rinegoziare.")
				"comunitaria":
					out.append("La Casa Comune la gestisce chi la usa. Si può darle risorse, o lasciarla fare da sola.")
				_:
					out.append("La Casa Comune è sospesa: la chiusura è stata rinviata. Si può prorogare, o proporre un altro modello.")
		3:
			out = ["Il debito di tutti: le regole con cui la Torre si paga il futuro."]
	var d := RULES.due(st)
	if d > 0:
		out.append("Da pagare in questo ciclo: %d (%s)." % [d, "la bolletta della dinamo" if cycle == 2 and not st.get("bill_paid", false) else "il guasto annunciato"])
	return out


func _intro() -> void:
	phase = "intro"
	match cycle:
		1:
			await Ui.say(situation(), PRES)
			if not _dt().get("rules_seen", false):
				_dt()["rules_seen"] = true
				await Ui.say(["Cento unità. Quattro voci. Tocca più o meno, poi CONFERMA.",
					"Sotto ogni numero c'è scritto cosa succede. Io lo leggo sempre. Quasi sempre."], PRES)
		2:
			await Ui.say(situation(), PRES)
		3:
			await Ui.say(situation(), PRES)
			await Ui.say(["ATTENZIONE.", "La stabilità economica è importante.", "Soprattutto per chi è già stabile."], VOICE)


# --- disegno -----------------------------------------------------------------------------------------

func _cat_row(i: int) -> Rect2:
	return Rect2(16, ROW_Y + i * ROW_H, 300, ROW_H - 6)


func minus_button(i: int) -> Rect2:
	return Rect2(176, ROW_Y + i * ROW_H + 4, 40, 30)


func plus_button(i: int) -> Rect2:
	return Rect2(270, ROW_Y + i * ROW_H + 4, 40, 30)


func confirm_button() -> Rect2:
	return Rect2(16, 268, 300, 36)


func rules_button() -> Rect2:
	return Rect2(16, 312, 140, 30)


func option_button(i: int) -> Rect2:
	return Rect2(24, 96 + i * 46, 592, 40)


func _draw() -> void:
	var font := Assets.font()
	Art.backdrop(self)
	draw_string(font, Vector2(16, 26), "TURNO — DIREZIONE · CICLO %d DI 3" % cycle, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, DIM)
	draw_string(font, Vector2(16, 48), RULES.QUESTIONS[cycle], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, GOLD)
	draw_string(font, Vector2(400, 26), "Riserve: %d   Arretrato: %d" % [int(st.get("reserve", 0)), int(st.get("backlog", 0))],
		HORIZONTAL_ALIGNMENT_LEFT, 230, 11, DIM)
	if phase in ["alloc", "intro"]:
		_draw_alloc(font)
	elif phase in ["casa", "debiti"]:
		_draw_options(font)


func _draw_alloc(font: Font) -> void:
	var t := RULES.total(alloc)
	draw_string(font, Vector2(16, 72), "Unità assegnate: %d / %d" % [t, RULES.TOTAL], HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
		GREEN if t == RULES.TOTAL else (RED if t > RULES.TOTAL else Color.WHITE))
	for i in RULES.CATS.size():
		var c: String = RULES.CATS[i]
		var row := _cat_row(i)
		Art.panel(self, row, PANEL, Color("7896a7"))
		if sel == i:
			draw_rect(row, GOLD, false, 2.0)
		draw_string(font, row.position + Vector2(8, 16), RULES.NAMES[c], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		var base := int(RULES.BASE[c])
		draw_string(font, row.position + Vector2(8, 32), "di solito %d" % base + (" · minimo %d" % RULES.minimum(st, c) if RULES.minimum(st, c) > 0 else ""),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 9, DIM)
		for b: Rect2 in [minus_button(i), plus_button(i)]:
			draw_rect(b, Color("2a2434"))
			draw_rect(b, Color.WHITE, false, 1.0)
		draw_string(font, minus_button(i).position + Vector2(0, 21), "−", HORIZONTAL_ALIGNMENT_CENTER, 40, 16, Color.WHITE)
		draw_string(font, plus_button(i).position + Vector2(0, 21), "+", HORIZONTAL_ALIGNMENT_CENTER, 40, 16, Color.WHITE)
		draw_string(font, Vector2(218, row.position.y + 25), str(int(alloc[c])), HORIZONTAL_ALIGNMENT_CENTER, 50, 16, GOLD)
	var bad := RULES.invalid(st, alloc)
	var cb := confirm_button()
	draw_rect(cb, Color("1f3a2a") if bad == "" else Color("2a2434"))
	draw_rect(cb, GOLD if sel == 4 else (GREEN if bad == "" else DIM), false, 2.0)
	draw_string(font, cb.position + Vector2(0, 23), "CONFERMA" if bad == "" else bad, HORIZONTAL_ALIGNMENT_CENTER, cb.size.x, 12 if bad == "" else 10,
		Color.WHITE if bad == "" else DIM)
	var rb := rules_button()
	draw_rect(rb, Color("2a2434"))
	draw_rect(rb, GOLD if sel == 5 else DIM, false, 1.0)
	draw_string(font, rb.position + Vector2(0, 20), "LE REGOLE", HORIZONTAL_ALIGNMENT_CENTER, rb.size.x, 11, Color.WHITE)
	# a destra: cosa succede con questa distribuzione, prima di confermare
	Art.panel(self, Rect2(330, 64, 294, 280), PANEL, Color("7896a7"))
	draw_string(font, Vector2(342, 82), "SE CONFERMI:", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, DIM)
	var y := 100.0
	for line: String in RULES.hints(st, alloc):
		y = _wrap(font, line, Vector2(342, y), 272, 10, Color.WHITE) + 6
	if msg != "":
		_wrap(font, msg, Vector2(342, maxf(y, 300)), 272, 10, GOLD)


func _draw_options(font: Font) -> void:
	draw_string(font, Vector2(24, 80), "LA CASA COMUNE" if phase == "casa" else "LA REGOLA DEI DEBITI", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, DIM)
	for i in options.size():
		var o: Array = options[i]
		var r := option_button(i)
		var closed := str(o[o.size() - 1]) != ""
		Art.panel(self, r, PANEL, Color("7896a7"))
		draw_rect(r, GOLD if sel == i else (DIM if closed else Color.WHITE), false, 2.0 if sel == i else 1.0)
		draw_string(font, r.position + Vector2(10, 16), str(o[1]), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 20, 12, DIM if closed else Color.WHITE)
		var sub := str(o[o.size() - 1]) if closed else (str(o[2]) if phase == "debiti" else "")
		if sub != "":
			draw_string(font, r.position + Vector2(10, 32), sub, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 20, 9, RED if closed else DIM)
	if msg != "":
		_wrap(font, msg, Vector2(24, 96 + options.size() * 46 + 14), 592, 10, GOLD)


## Scrive andando a capo dentro `width`; restituisce la y dopo l'ultima riga.
func _wrap(font: Font, text: String, pos: Vector2, width: float, size: int, col: Color) -> float:
	var words := text.split(" ")
	var line := ""
	var y := pos.y
	for w in words:
		var test := (line + " " + w).strip_edges()
		if font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width and line != "":
			draw_string(font, Vector2(pos.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
			y += size + 4
			line = w
		else:
			line = test
	if line != "":
		draw_string(font, Vector2(pos.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
		y += size + 4
	return y


# --- comandi -----------------------------------------------------------------------------------------

func touch_scheme() -> String:
	return "point" if phase in ["alloc", "casa", "debiti"] else ""


func touch_center() -> Vector2:
	return Vector2(320, 180)


func touch_point(pos: Vector2, step: int) -> void:
	if step != 0 or Ui.busy:
		return
	if phase == "alloc":
		for i in RULES.CATS.size():
			if minus_button(i).grow(4).has_point(pos):
				sel = i
				_nudge(i, -1)
				return
			if plus_button(i).grow(4).has_point(pos):
				sel = i
				_nudge(i, 1)
				return
		if confirm_button().has_point(pos):
			sel = 4
			_confirm()
		elif rules_button().has_point(pos):
			sel = 5
			_show_rules()
	elif phase in ["casa", "debiti"]:
		for i in options.size():
			if option_button(i).has_point(pos):
				sel = i
				_pick(i)
				return


func _unhandled_input(event: InputEvent) -> void:
	if Ui.busy or not phase in ["alloc", "casa", "debiti"]:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and not TouchControls.enabled:
		touch_point((event as InputEventMouseButton).position, 0)
		return
	var n := 6 if phase == "alloc" else options.size()
	if event.is_action_pressed("move_up"):
		sel = posmod(sel - 1, n)
		Sound.sfx("move")
	elif event.is_action_pressed("move_down"):
		sel = posmod(sel + 1, n)
		Sound.sfx("move")
	elif phase == "alloc" and sel < 4 and (event.is_action_pressed("move_left") or event.is_action_pressed("move_right")):
		_nudge(sel, -1 if event.is_action_pressed("move_left") else 1)
	elif event.is_action_pressed("confirm"):
		if phase == "alloc":
			if sel == 4:
				_confirm()
			elif sel == 5:
				_show_rules()
			else:
				_nudge(sel, 1)
		else:
			_pick(sel)
	queue_redraw()


func _nudge(i: int, d: int) -> void:
	var c: String = RULES.CATS[i]
	var before := int(alloc[c])
	alloc = RULES.nudge(st, alloc, c, d)
	if int(alloc[c]) == before:
		msg = "Non ci sono più unità da assegnare: togline da un'altra voce." if d > 0 and RULES.total(alloc) >= RULES.TOTAL else \
			("Gli stipendi non scendono sotto %d." % RULES.minimum(st, c) if c == "stipendi" and d < 0 else "")
		Sound.sfx("deny")
	else:
		msg = ""
		Sound.sfx("blip", 1.0 + 0.05 * d)
	queue_redraw()


func _show_rules() -> void:
	await Ui.say(["STIPENDI: sotto 30 non si coprono i contratti. Un aumento è per sempre. Al -3 i prezzi sono saliti di un terzo: con 55 l'aumento li copre.",
		"SERVIZI: sotto 15 diventano a pagamento, da 25 si allargano. Più persone li usano, più si consumano: +5 alla manutenzione che serve dopo.",
		"MANUTENZIONE: ne servono 25. Quello che manca diventa arretrato. Con 10 di arretrato un guasto è annunciato, e si paga al ciclo dopo.",
		"RISERVE: restano in cassa. Coprono le spese annunciate. Quando non bastano, si prende dai servizi."])


func _confirm() -> void:
	var bad := RULES.invalid(st, alloc)
	if bad != "":
		msg = bad
		Sound.sfx("deny")
		queue_redraw()
		return
	Sound.sfx("stamp")
	if cycle == 2:
		options = RULES.casa_options(st, alloc)
		phase = "casa"
		sel = 0
		msg = ""
		queue_redraw()
	elif cycle == 3:
		options = RULES.debt_options(st, alloc)
		phase = "debiti"
		sel = 0
		msg = ""
		queue_redraw()
	else:
		await _finish()


func _pick(i: int) -> void:
	var o: Array = options[i]
	var closed := str(o[o.size() - 1])
	if closed != "":
		msg = closed
		Sound.sfx("deny")
		queue_redraw()
		return
	choice_id = str(o[0])
	Sound.sfx("stamp")
	await _finish()


## Il ciclo è deciso: lo stato comune si aggiorna una volta, si salva, e si torna alla Cima.
func _finish() -> void:
	if phase == "done":
		return
	var chose_phase := phase
	phase = "done"
	queue_redraw()
	var lines := RULES.apply(st, alloc)
	if chose_phase == "casa":
		RULES.apply_casa(st, choice_id)
		lines.append("La Casa Comune: " + _casa_text(str(st["casa"])))
	elif chose_phase == "debiti":
		st["debt_rule"] = choice_id
		lines.append("La regola dei debiti: " + _debt_text(choice_id))
	var dt := _dt()
	dt["state"] = st
	dt["cycle_%d_completed" % cycle] = true
	var decisions: Array = dt.get("decisions", [])
	decisions.append({"cycle": cycle, "alloc": alloc.duplicate(), "choice": choice_id})
	dt["decisions"] = decisions
	dt["pending"] = cycle
	await Ui.say(lines)
	Router.goto(CIMA, "desk")


static func _casa_text(c: String) -> String:
	match c:
		"riconvertita_con_accessi":
			return "resta un centro CHEAP, ma con accessi gratuiti pagati dalla Torre."
		"contratto_rinegoziato":
			return "il contratto torna al canone vecchio. Si riapre, con i conti in mano."
		"comunitaria_sostenuta":
			return "la gestiscono loro, con risorse della Torre."
		"comunitaria_autonoma":
			return "la gestiscono loro, da soli. Nessuno controlla, nessuno paga."
		"prorogata":
			return "la chiusura è rinviata di un anno. Pagato dalle riserve."
		"nuovo_modello":
			return "si riapre come l'aveva organizzata Ada: studio, laboratorio, incontri."
		"riconvertita":
			return "resta un centro CHEAP. Con il tornello."
	return "chiude. Nessuno ha deciso niente: è bastato."


static func _debt_text(c: String) -> String:
	match c:
		"interessi":
			return "interessi ridotti allo 0,5% a notte."
		"revisione":
			return "i debiti senza firma sono sospesi e in revisione."
		"alternative":
			return "le reti che già funzionano pagano una parte dei servizi."
	return "tutto come prima."
