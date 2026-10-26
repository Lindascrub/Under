extends Node2D
## I turni di lavoro: ogni lavoro ha il suo minigioco. Config in GameState.minigame (kind "work"):
##   game "pedal":   alterna sinistra/destra per tenere la lancetta nel verde (la dinamo del -5)
##   game "clean":   passa la spugna sulle macchie finché spariscono (i bagni del -4)
##   game "calls":   squilla un telefono (su/giù/sinistra/destra): rispondi con la freccia giusta (call center)
##   game "scale":   ferma la lancetta della bilancia sul peso giusto (il banco del mercato)
##   game "sort":    scatole rosse a sinistra, blu a destra (il magazzino)
##   game "deliver": in bici tra tre corsie, evita le auto e prendi i pacchi (le consegne)
##   game "helpdesk": il call center del -4: tocca il telefono che squilla, poi scegli la risposta
##                    (il copione paga, la sincerità no ma ti resta, la sgarbata è un errore)
## Più turni hai fatto e più sei in alto nella torre, più il gioco è veloce (difficulty()).
## La paga dipende da quanto bene è andata; sotto metà obiettivo il turno è "fallito".

const BOX := Rect2(120, 96, 400, 190)
const RED := Color("ff2a3c")
const YELLOW := Color("ffe14d")
const GREEN := Color("3ddc84")
const BLUE := Color("39b6ff")
const DIRS := ["up", "down", "left", "right"]
const DIR_PITCH := {"up": 1.5, "right": 1.25, "down": 0.75, "left": 1.0}

var cfg: Dictionary = {}
var game := "pedal"
var phase := "intro"
var d := 0.0
var duration := 25.0
var time_left := 25.0
var score := 0.0
var target := 10.0
var mistakes := 0
var flash := 0.0
var flash_col := RED
var t := 0.0

# pedal
var speed := 0.0
var band := Vector2(0.55, 0.8)
var last_side := ""
# clean / sponge
var sponge := Vector2.ZERO
var stains: Array[Dictionary] = []
var spawn_t := 0.0
# calls
var ringing: Dictionary = {}
var call_t := 0.0
# scale
var needle := 0.0
var needle_dir := 1.0
var wanted := 0.5
var scale_hold := 0.0
# sort
var boxes: Array[Dictionary] = []
# deliver
var lane := 1
var road: Array[Dictionary] = []
var crash_t := 0.0
## dove tiene il dito chi gioca col telefono (spugna); x < 0: nessun dito
var finger := Vector2(-1, -1)
# helpdesk
## Le chiamate, dalla più gentile alla più cattiva: [cliente, copione, sincera, sgarbata].
const CALLS := [
	["Vorrei parlare con un essere umano!", "La sua chiamata è importante per noi.", "Anch'io. Ma qui non ce ne sono.", "Allora richiami quando ne trova uno."],
	["È la quarta volta che chiamo!", "Grazie per la sua pazienza.", "Lo so. Le vedo tutte. Nessuno le legge.", "E chiami una quinta, allora."],
	["Lei è un robot, vero?", "Sono qui per aiutarla!", "Non ancora.", "Bip."],
	["Sono in attesa da due ore!", "Resti in linea, la sua chiamata è importante.", "Anch'io sono in attesa. Da anni.", "Altre due e vince un premio."],
	["Voglio parlare col suo responsabile!", "Il responsabile la richiamerà entro 48 ore.", "Non l'ho mai visto. Forse non esiste.", "Il responsabile è lei, a quanto pare."],
	["Mi avete addebitato tremila euro!", "Le propongo l'offerta Serenità Plus.", "Mi dispiace. Qui succede a tutti.", "Li ha spesi bene, almeno?"],
	["Perché mi chiamate alle sei di mattina?", "Per offrirle un'occasione unica!", "Perché a quell'ora nessuno riattacca.", "Perché lei era sveglio."],
	["Mia madre è morta. Voglio chiudere il suo contratto.", "Serve il modulo D-12 firmato dal titolare.", "Mi dispiace tanto. Lo chiudo io, adesso.", "Deve chiamare lei, però."],
]
const HD_KINDS := ["copione", "sincera", "sgarbata"]
var hd_phase := "wait"
var hd_t := 0.0
var hd_phone := 0
var hd_call: Array = []
var hd_order: Array = []
var hd_sel := 0
var hd_done := 0
var hd_honest := 0
var hd_last := ""
## Negli ultimi secondi del turno squillano tutti i telefoni della sala.
const HD_FINALE := 12.0

var _title: Label
var _info: Label
## I giochi classici (Snake, Simon, Tetris, Frogger, Breakout, Pong): vedi arcade.gd.
var arcade: Arcade


func _ready() -> void:
	cfg = GameState.minigame
	game = str(cfg.get("game", "pedal"))
	# lo straordinario (dopo la rivelazione del Fondo) è più duro del turno normale
	d = clampf(difficulty() + float(cfg.get("extra_d", 0.0)), 0.0, 1.0)
	Ui.show_hud(false)
	Sound.music("lavoro")
	var bg := ColorRect.new()
	bg.color = Color("0b0a10")
	bg.size = Vector2(640, 360)
	bg.z_index = -10
	add_child(bg)
	_title = _label(Vector2(0, 22), 22, YELLOW)
	_title.text = str(cfg.get("name", "Il turno"))
	_info = _label(Vector2(0, 58), 15, Color.WHITE)
	if Ui.transitioning:
		await Ui.faded_in
	await Ui.say(cfg.get("intro", ["* Si comincia."]))
	await Ui.say([_rules()])
	_start()


## Da 0 (primo turno, piano -5) a 1: cresce con i turni fatti e con il piano.
static func difficulty() -> float:
	return clampf(GameState.hard_work * 0.07 + GameState.floor_index(GameState.floor_id) * 0.06, 0.0, 1.0)


func _label(pos: Vector2, size: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(640, size + 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	add_child(l)
	return l


func _rules() -> String:
	if game in Arcade.GAMES:
		var a := Arcade.new().set_game(game)
		a.st_name = str(cfg.get("victim_name", ""))
		a.st_item = str(cfg.get("item", ""))
		return a.rules()
	if TouchControls.enabled:
		match game:
			"pedal":
				return "* Tocca lo schermo a SINISTRA e a DESTRA, una volta per parte, per pedalare. Tieni la lancetta nel verde. Se tocchi due volte lo stesso lato, inciampi."
			"clean":
				return "* Trascina la spugna col dito e tienila sulle macchie finché spariscono. Se una macchia resta troppo, si secca."
			"calls":
				return "* Quando un telefono squilla, toccalo prima che riattacchino. Ogni telefono ha il suo squillo."
			"scale":
				return "* Il cliente chiede un peso. Tocca lo schermo quando la lancetta è sulla tacca gialla."
			"sort":
				return "* Le scatole ROSSE (o le monete d'oro) vanno a SINISTRA, quelle BLU (o i bottoni) a DESTRA. Tocca la metà giusta dello schermo prima che arrivino in fondo al nastro."
			"deliver":
				return "* Tocca la corsia dove vuoi andare. Evita le auto, prendi i pacchi."
			"helpdesk":
				return "* Quando un telefono squilla, toccalo. Poi tocca la risposta. Il copione paga. La sincerità no, ma ti resta. Se sei sgarbato, ti richiamano."
	match game:
		"pedal":
			return "* Premi SINISTRA e DESTRA, una alla volta, per pedalare. Tieni la lancetta nel verde. Se premi due volte lo stesso lato, inciampi."
		"clean":
			return "* Muovi la spugna con le frecce e tienila sulle macchie finché spariscono. Se una macchia resta troppo, si secca."
		"calls":
			return "* Quando un telefono squilla, premi la freccia della sua direzione prima che riattacchino. Ogni telefono ha il suo squillo."
		"scale":
			return "* Il cliente chiede un peso. Premi {ok} quando la lancetta è sulla tacca gialla."
		"sort":
			return "* Le scatole ROSSE (o le monete d'oro) vanno a SINISTRA, quelle BLU (o i bottoni) a DESTRA. Premi la freccia prima che arrivino in fondo al nastro."
		"deliver":
			return "* SU e GIÙ per cambiare corsia. Evita le auto, prendi i pacchi."
		"helpdesk":
			return "* Quando un telefono squilla, premi la sua freccia (SINISTRA, SU, DESTRA). Poi scegli la risposta con SU e GIÙ e {ok}. Il copione paga. La sincerità no, ma ti resta."
	return "* Lavora."


func _start() -> void:
	duration = 25.0
	time_left = duration
	phase = "play"
	if game in Arcade.GAMES:
		arcade = Arcade.new()
		arcade.setup(self, game)
		return
	match game:
		"pedal":
			target = duration * 0.6
			band = Vector2(0.55, 0.8 - d * 0.1)
		"clean":
			sponge = BOX.get_center()
			target = 9.0 + d * 6.0
		"calls":
			target = 10.0 + d * 6.0
		"scale":
			target = 5.0 + d * 3.0
			_new_weight()
		"sort":
			target = 12.0 + d * 8.0
		"deliver":
			target = 6.0 + d * 4.0
		"helpdesk":
			duration = 45.0
			time_left = duration
			target = 5.0 + d * 3.0
			hd_t = 1.0


func _process(delta: float) -> void:
	flash = maxf(0.0, flash - delta)
	t += delta
	if phase != "play":
		queue_redraw()
		return
	time_left -= delta
	if arcade:
		arcade.update(delta)
	match game:
		"pedal":
			speed = maxf(0.0, speed - (0.22 + d * 0.18) * delta)
			# la banda verde si sposta piano: non basta trovare un ritmo e dimenticarsene
			var mid := 0.62 + sin(t * (0.6 + d)) * 0.12 * d
			var half := (0.13 - d * 0.04)
			band = Vector2(mid - half, mid + half)
			if speed >= band.x and speed <= band.y:
				score += delta
		"clean":
			if finger.x >= 0.0:
				sponge = sponge.move_toward(finger, 260.0 * delta)
			else:
				var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
				sponge += v * 150.0 * delta
			sponge = sponge.clamp(BOX.position + Vector2(10, 10), BOX.end - Vector2(10, 10))
			spawn_t -= delta
			if spawn_t <= 0.0 and stains.size() < 6:
				spawn_t = maxf(0.5, 1.3 - d * 0.6)
				stains.append({"pos": Vector2(randf_range(BOX.position.x + 20, BOX.end.x - 20), randf_range(BOX.position.y + 20, BOX.end.y - 20)), "life": 1.0, "age": 0.0})
			for i in range(stains.size() - 1, -1, -1):
				var s := stains[i]
				s["age"] = float(s["age"]) + delta
				if (s["pos"] as Vector2).distance_to(sponge) < 16.0:
					s["life"] = float(s["life"]) - delta * 2.2
					if int(t * 10) % 3 == 0:
						Sound.sfx("step", 1.6)
					if float(s["life"]) <= 0.0:
						stains.remove_at(i)
						score += 1.0
						Sound.sfx("blip", 1.4)
						continue
				if float(s["age"]) > 8.0 - d * 3.0:
					stains.remove_at(i)
					mistakes += 1
					_flash(RED)
					Sound.sfx("deny")
		"calls":
			call_t -= delta
			if call_t <= 0.0:
				call_t = maxf(0.55, 1.4 - d * 0.7)
				var free := DIRS.filter(func(x: String) -> bool: return not ringing.has(x))
				if not free.is_empty() and (ringing.size() < 1 + int(d * 2.0)):
					var dir: String = free.pick_random()
					ringing[dir] = maxf(0.9, 2.0 - d * 0.9)
					Sound.sfx("ding", DIR_PITCH[dir])
			for dir: String in ringing.keys():
				ringing[dir] = float(ringing[dir]) - delta
				if float(ringing[dir]) <= 0.0:
					ringing.erase(dir)
					mistakes += 1
					_flash(RED)
					Sound.sfx("deny")
		"scale":
			needle += needle_dir * (0.55 + d * 0.6) * delta
			if needle > 1.0 or needle < 0.0:
				needle = clampf(needle, 0.0, 1.0)
				needle_dir = -needle_dir
		"sort":
			spawn_t -= delta
			if spawn_t <= 0.0:
				spawn_t = maxf(0.6, 1.4 - d * 0.6)
				boxes.append({"y": BOX.position.y - 10.0, "red": randf() < 0.5})
			for i in range(boxes.size() - 1, -1, -1):
				boxes[i]["y"] = float(boxes[i]["y"]) + (60.0 + d * 50.0) * delta
				if float(boxes[i]["y"]) > BOX.end.y - 14:
					boxes.remove_at(i)
					mistakes += 1
					_flash(RED)
					Sound.sfx("deny")
		"deliver":
			crash_t = maxf(0.0, crash_t - delta)
			spawn_t -= delta
			if spawn_t <= 0.0:
				spawn_t = maxf(0.45, 1.0 - d * 0.45)
				road.append({"x": BOX.end.x + 20, "lane": randi() % 3, "parcel": randf() < 0.35})
			for i in range(road.size() - 1, -1, -1):
				var o := road[i]
				o["x"] = float(o["x"]) - (130.0 + d * 90.0) * delta
				if absf(float(o["x"]) - (BOX.position.x + 60)) < 16 and int(o["lane"]) == lane:
					road.remove_at(i)
					if o["parcel"]:
						score += 1.0
						Sound.sfx("coin")
					elif crash_t <= 0.0:
						mistakes += 1
						crash_t = 1.0
						_flash(RED)
						Sound.sfx("hurt")
					continue
				if float(o["x"]) < BOX.position.x - 20:
					road.remove_at(i)
		"helpdesk":
			hd_t -= delta
			if hd_t <= 0.0:
				match hd_phase:
					"wait":
						# squilla un telefono
						hd_phase = "ring"
						hd_phone = randi() % 3
						hd_t = maxf(1.6, 3.0 - d)
						Sound.sfx("ding", [1.0, 1.5, 1.25][hd_phone])
					"ring", "talk":
						# non hai risposto in tempo: riattaccano
						mistakes += 1
						hd_last = "Ha riattaccato."
						_flash(RED)
						Sound.sfx("deny")
						_hd_next()
			elif hd_phase == "ring" and int(hd_t * 6.0) % 3 == 0 and int(t * 60) % 10 == 0:
				Sound.sfx("ding", [1.0, 1.5, 1.25][hd_phone])
			# il finale: in un call center si sente solo questo
			if time_left < HD_FINALE and randf() < delta * 9.0:
				Sound.sfx("ding", randf_range(0.8, 1.7))
	_info.text = "Tempo %d   Fatto %d/%d   Errori %d" % [int(ceil(time_left)), int(score), int(ceil(target)), mistakes]
	if time_left <= 0.0:
		_finish()
	queue_redraw()


# --- col dito (vedi TouchControls) -------------------------------------------------

func touch_scheme() -> String:
	if phase != "play":
		return ""
	if arcade:
		return arcade.touch_scheme()
	match game:
		"pedal", "sort":
			return "halves"
		"calls":
			return "dirs"
		"scale":
			return "tap"
	return "point"


func touch_center() -> Vector2:
	return arcade.touch_center() if arcade else BOX.get_center()


func touch_hold() -> Array:
	return arcade.touch_hold() if arcade else ["confirm"]


func touch_point(pos: Vector2, step: int) -> void:
	if arcade:
		arcade.touch_point(pos, step)
		return
	match game:
		"helpdesk":
			if step != 0:
				return
			if hd_phase == "ring":
				for k in 3:
					if pos.distance_to(_hd_phone_pos(k)) < 50.0:
						_hd_pick_up(k)
						return
			elif hd_phase == "talk":
				for k in 3:
					if _hd_button(k).grow(4).has_point(pos):
						_hd_answer(k)
						return
		"clean":
			finger = pos if step != 2 else Vector2(-1, -1)
		"deliver":
			if step == 0:
				var lane_h := (BOX.size.y - 20) / 3.0
				var want := clampi(int((pos.y - BOX.position.y - 10) / lane_h), 0, 2)
				if want != lane:
					lane = want
					Sound.sfx("move")


func flash_now(col: Color) -> void:
	_flash(col)


func _flash(col: Color) -> void:
	flash = 0.3
	flash_col = col


func _unhandled_input(event: InputEvent) -> void:
	if phase != "play":
		return
	if arcade:
		arcade.input(event)
		return
	match game:
		"pedal":
			for side in ["left", "right"]:
				if event.is_action_pressed("move_" + side):
					if side == last_side:
						speed = maxf(0.0, speed - 0.12)
						_flash(RED)
						Sound.sfx("deny")
					else:
						speed = minf(1.0, speed + 0.075 - d * 0.015)
						Sound.sfx("pedal", 0.8 + speed * 0.6)
					last_side = side
		"calls":
			for dir: String in DIRS:
				if event.is_action_pressed("move_" + dir):
					if ringing.has(dir):
						ringing.erase(dir)
						score += 1.0
						Sound.sfx("select", DIR_PITCH[dir])
						_flash(GREEN)
					else:
						mistakes += 1
						_flash(RED)
						Sound.sfx("deny")
		"scale":
			if event.is_action_pressed("confirm"):
				var tol := 0.07 - d * 0.03
				if absf(needle - wanted) <= tol:
					score += 1.0
					Sound.sfx("coin")
					_flash(GREEN)
				else:
					mistakes += 1
					Sound.sfx("deny")
					_flash(RED)
				_new_weight()
		"sort":
			for side in ["left", "right"]:
				if event.is_action_pressed("move_" + side) and not boxes.is_empty():
					var b := boxes[0]
					# la scatola più avanti sul nastro
					for bb in boxes:
						if float(bb["y"]) > float(b["y"]):
							b = bb
					var ok: bool = (side == "left") == bool(b["red"])
					boxes.erase(b)
					if ok:
						score += 1.0
						Sound.sfx("blip", 1.2)
						_flash(GREEN)
					else:
						mistakes += 1
						Sound.sfx("deny")
						_flash(RED)
		"deliver":
			if event.is_action_pressed("move_up"):
				lane = maxi(0, lane - 1)
				Sound.sfx("move")
			elif event.is_action_pressed("move_down"):
				lane = mini(2, lane + 1)
				Sound.sfx("move")
		"helpdesk":
			if hd_phase == "ring":
				for k in 3:
					if event.is_action_pressed(["move_left", "move_up", "move_right"][k]):
						_hd_pick_up(k)
			elif hd_phase == "talk":
				if event.is_action_pressed("move_up"):
					hd_sel = posmod(hd_sel - 1, 3)
					Sound.sfx("move")
				elif event.is_action_pressed("move_down"):
					hd_sel = posmod(hd_sel + 1, 3)
					Sound.sfx("move")
				elif event.is_action_pressed("confirm"):
					_hd_answer(hd_sel)


# --- il call center (helpdesk) --------------------------------------------------

## Dove stanno i tre telefoni e i tre pulsanti delle risposte.
func _hd_phone_pos(k: int) -> Vector2:
	return Vector2(BOX.get_center().x + (k - 1) * 120.0, BOX.end.y - 50.0)


func _hd_button(k: int) -> Rect2:
	return Rect2(BOX.position.x + 16, BOX.position.y + 62 + k * 40, BOX.size.x - 32, 32)


func _hd_pick_up(k: int) -> void:
	if k != hd_phone:
		mistakes += 1
		hd_last = "Telefono sbagliato. Quello squillava ancora."
		_flash(RED)
		Sound.sfx("deny")
		return
	# i clienti diventano più cattivi man mano che il turno va avanti (e più sali)
	var worst := clampi(3 + hd_done + int(d * 3.0), 3, CALLS.size())
	hd_call = CALLS[randi() % worst]
	hd_order = [0, 1, 2]
	hd_order.shuffle()
	hd_sel = 0
	hd_phase = "talk"
	hd_t = maxf(3.5, 7.0 - d * 3.0)
	Sound.sfx("select")


func _hd_answer(k: int) -> void:
	var kind: String = HD_KINDS[int(hd_order[k])]
	match kind:
		"copione":
			score += 1.0
			hd_last = "Copione. Il cliente si calma un po'. Tu no."
			_flash(GREEN)
			Sound.sfx("coin")
		"sincera":
			hd_honest += 1
			hd_last = "Sincera. Silenzio, poi: \"...grazie\". Il supervisore lo segna."
			_flash(YELLOW)
			Sound.sfx("blip", 0.8)
		_:
			mistakes += 1
			hd_last = "Sgarbata. Ti richiameranno. Per un richiamo."
			_flash(RED)
			Sound.sfx("deny")
	hd_done += 1
	_hd_next()


func _hd_next() -> void:
	hd_phase = "wait"
	# nel finale non c'è respiro tra una chiamata e l'altra
	hd_t = randf_range(0.05, 0.2) if time_left < HD_FINALE else randf_range(0.5, 1.1)


func _new_weight() -> void:
	wanted = randf_range(0.15, 0.85)
	needle = 0.0 if randf() < 0.5 else 1.0
	needle_dir = 1.0 if needle == 0.0 else -1.0


func _finish() -> void:
	phase = "end"
	if game == "steal":
		await _finish_steal()
		return
	var ratio := clampf((score - mistakes * 0.5) / target, 0.0, 1.25)
	var base := int(cfg.get("pay", 300))
	var pay := maxi(40, int(round(base * maxf(0.25, ratio))))
	var failed := ratio < 0.5
	GameState.finish_hard_job(pay)
	if game == "helpdesk" and hd_honest > 0:
		# la sincerità non si paga, ma resta
		GameState.self_esteem += mini(hd_honest, 2)
	if cfg.has("extra"):
		# straordinario: niente pietà né caporeparto, ma la festa si riaccende per un po'
		GameState.flags["c1_extra"] = int(cfg["extra"])
		GameState.flags["c1_relight"] = not failed
	elif failed:
		GameState.work_failed()
	Sound.sfx("coin")
	var lines: Array = []
	if failed:
		lines.append("* Il turno è andato male. Il caporeparto scrive qualcosa sul suo taccuino.")
	elif ratio >= 1.0:
		lines.append("* Turno perfetto. Nessuno te lo dirà, ma è così.")
	else:
		lines.append("* Turno finito. Dieci ore della tua vita.")
	lines.append("* Paga: %s." % GameState.euros(pay))
	if game == "helpdesk" and hd_honest > 0:
		lines.append("* Sei stato sincero %d volt%s. Il supervisore l'ha segnato. Anche tu." % [hd_honest, "a" if hd_honest == 1 else "e"])
	lines.append(str(cfg.get("tired", "* Ti fa male tutto.")))
	await Ui.say(lines)
	Router.goto(str(cfg.get("return", Router.FONDO)), "_mg")


## Com'è andato il furto dell'idea: preso il merito (promozione) o beccato (niente).
func _finish_steal() -> void:
	var who := str(cfg.get("victim_name", "il collega"))
	var victim := str(cfg.get("victim", ""))
	var lines: Array = []
	if score >= target:
		var pay := GameState.do_promotion(victim)
		Sound.sfx("stamp")
		lines.append("* Hai copiato tutto. Domani, alla riunione, l'idea sarà tua. %s applaudirà con gli altri, senza capire." % who)
		lines.append("* Promozione: +%s. Ora sei {rank}." % GameState.euros(pay))
		lines.append(GameState.level_up_line())
	else:
		GameState.flags["promotions_failed"] = int(GameState.flags.get("promotions_failed", 0)) + 1
		Sound.sfx("deny")
		lines.append("* %s ti ha visto. Si stringe il foglio al petto e ti guarda come non ti aveva mai guardato." % who)
		lines.append("* Niente promozione. Però, stanotte, forse dormirai.")
	await Ui.say(lines)
	Router.goto(str(cfg.get("return", Router.FONDO)), "_mg")


# --- disegno ---------------------------------------------------------------------

func _draw() -> void:
	var font := Assets.font()
	draw_rect(BOX, Color.BLACK)
	draw_rect(BOX, Color.WHITE, false, 3.0)
	# il tempo che resta, in basso
	var tb := Rect2(BOX.position.x, BOX.end.y + 12, BOX.size.x, 6)
	draw_rect(tb, Color("2a2633"))
	draw_rect(Rect2(tb.position, Vector2(tb.size.x * clampf(time_left / duration, 0, 1), tb.size.y)), YELLOW)
	if arcade:
		arcade.draw(font)
	match game:
		"pedal":
			_draw_pedal(font)
		"clean":
			_draw_clean()
		"calls":
			_draw_calls(font)
		"scale":
			_draw_scale(font)
		"sort":
			_draw_sort(font)
		"deliver":
			_draw_deliver()
		"helpdesk":
			_draw_helpdesk(font)
	if flash > 0.0:
		var c := flash_col
		c.a = flash
		draw_rect(BOX, c)


func _draw_pedal(font: Font) -> void:
	var c := Vector2(BOX.get_center().x, BOX.end.y - 30)
	var r := 120.0
	# il quadrante: da sinistra (fermo) a destra (troppo veloce)
	for i in 40:
		var a0 := PI + PI * i / 40.0
		var a1 := PI + PI * (i + 1) / 40.0
		var f := i / 40.0
		var col := Color("3a3644")
		if f >= band.x and f <= band.y:
			col = GREEN
		elif f > band.y:
			col = Color("8a3030")
		draw_line(c + Vector2(cos(a0), sin(a0)) * r, c + Vector2(cos(a1), sin(a1)) * r, col, 10.0)
	var a := PI + PI * speed
	draw_line(c, c + Vector2(cos(a), sin(a)) * (r - 14), Color.WHITE, 3.0)
	draw_circle(c, 6, Color.WHITE)
	# la lampadina di sopra: si accende con la tua fatica
	var glow := clampf(speed * 1.2, 0.0, 1.0)
	draw_circle(Vector2(c.x, BOX.position.y + 34), 18 + 10 * glow, Color(1, 0.9, 0.5, 0.15 + 0.35 * glow))
	draw_circle(Vector2(c.x, BOX.position.y + 34), 10, Color(1, 0.95, 0.7).lerp(Color("3a3644"), 1.0 - glow))
	draw_string(font, Vector2(BOX.position.x + 20, BOX.end.y - 10), "SINISTRA", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, YELLOW if last_side != "left" else Color("5c5666"))
	draw_string(font, Vector2(BOX.end.x - 90, BOX.end.y - 10), "DESTRA", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, YELLOW if last_side != "right" else Color("5c5666"))


func _draw_helpdesk(font: Font) -> void:
	# la moquette arancione del -4, sotto la scrivania
	draw_rect(BOX.grow(-4), Color("4a2a1a"))
	if time_left < HD_FINALE:
		_draw_drin(font)
	if hd_phase == "talk":
		draw_string(font, Vector2(BOX.position.x + 16, BOX.position.y + 24), "Il cliente:", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("8a8494"))
		draw_multiline_string(font, Vector2(BOX.position.x + 16, BOX.position.y + 42), "\"%s\"" % str(hd_call[0]), HORIZONTAL_ALIGNMENT_LEFT, BOX.size.x - 32, 12, 2, Color.WHITE)
		for k in 3:
			var r := _hd_button(k)
			var sel := k == hd_sel and not TouchControls.enabled
			draw_rect(r, Color("ffe14d") if sel else Color("2a2633"))
			draw_rect(r, Color("ffe14d"), false, 2.0)
			draw_multiline_string(font, r.position + Vector2(8, 13), str(hd_call[1 + int(hd_order[k])]), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 16, 10, 2, Color.BLACK if sel else Color.WHITE)
		# il tempo per rispondere
		var left := hd_t / maxf(3.5, 7.0 - d * 3.0)
		draw_rect(Rect2(BOX.position.x + 16, BOX.position.y + 50, (BOX.size.x - 32) * clampf(left, 0, 1), 3), GREEN)
		return
	for k in 3:
		var p := _hd_phone_pos(k)
		var on := hd_phase == "ring" and k == hd_phone
		var shake := Vector2(sin(t * 50.0) * 2.0, 0) if on else Vector2.ZERO
		var col := YELLOW if on else Color("d8c8a8")
		# un telefono beige anni '80: base, cornetta, tastiera
		draw_rect(Rect2(p + Vector2(-22, -6) + shake, Vector2(44, 22)), col)
		draw_rect(Rect2(p + Vector2(-26, -16) + shake, Vector2(52, 9)), col.darkened(0.25))
		for i in 3:
			for j in 2:
				draw_rect(Rect2(p + Vector2(-12 + i * 9, 0 + j * 7) + shake, Vector2(6, 4)), col.darkened(0.45))
		if on:
			draw_string(font, p + Vector2(-30, -26), "DRIN!", HORIZONTAL_ALIGNMENT_CENTER, 60, 12, YELLOW)
			var left2 := hd_t / maxf(1.6, 3.0 - d)
			draw_rect(Rect2(p + Vector2(-22, 20), Vector2(44 * clampf(left2, 0, 1), 3)), GREEN)
	if hd_last != "":
		draw_string(font, Vector2(BOX.position.x, BOX.position.y + 30), hd_last, HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 11, Color("c8c0d0"))
	draw_string(font, Vector2(BOX.position.x, BOX.position.y + 56), "Sincero: %d" % hd_honest, HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 10, Color("8a8494"))


## Il finale: "DRIN!" dappertutto, intorno alla scrivania e dentro, che lampeggiano.
func _draw_drin(font: Font) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(t * 7.0)
	for i in 22:
		var p := Vector2(rng.randf_range(4, 600), rng.randf_range(70, 345))
		var col := Color(1.0, 0.88, 0.3, rng.randf_range(0.25, 0.9))
		draw_string(font, p, "DRIN!", HORIZONTAL_ALIGNMENT_LEFT, -1, rng.randi_range(8, 14), col)
	draw_string(font, Vector2(0, BOX.position.y - 6), "SQUILLANO TUTTI", HORIZONTAL_ALIGNMENT_CENTER, 640, 11, RED)


func _draw_clean() -> void:
	# piastrelle del bagno
	for y in range(int(BOX.position.y) + 4, int(BOX.end.y) - 4, 20):
		for x in range(int(BOX.position.x) + 4, int(BOX.end.x) - 4, 20):
			draw_rect(Rect2(x, y, 18, 18), Color("b8c6d6") if (x / 20 + y / 20) % 2 == 0 else Color("a8b8ca"))
	for s in stains:
		var p: Vector2 = s["pos"]
		var k := clampf(float(s["life"]), 0.0, 1.0)
		var dry := float(s["age"]) / (8.0 - d * 3.0)
		var col := Color("6b4a1e").lerp(Color("3a2a10"), dry)
		draw_circle(p, 6 + 8 * k, col)
		draw_circle(p + Vector2(7, 3) * k, 4 * k + 1, col)
	# la spugna
	draw_rect(Rect2(sponge - Vector2(10, 7), Vector2(20, 14)), Color("ffe14d"))
	draw_rect(Rect2(sponge - Vector2(10, 7), Vector2(20, 4)), Color("3ddc84"))


func _draw_calls(font: Font) -> void:
	var c := BOX.get_center()
	var pos := {"up": c + Vector2(0, -60), "down": c + Vector2(0, 60), "left": c + Vector2(-110, 0), "right": c + Vector2(110, 0)}
	for dir: String in DIRS:
		var p: Vector2 = pos[dir]
		var on := ringing.has(dir)
		var shake := Vector2(sin(t * 50.0) * 2.0, 0) if on else Vector2.ZERO
		var col := YELLOW if on else Color("5c5666")
		draw_rect(Rect2(p - Vector2(18, 10) + shake, Vector2(36, 20)), col)
		draw_rect(Rect2(p - Vector2(22, 16) + shake, Vector2(44, 6)), col.darkened(0.3))
		_arrow(p + Vector2(0, 24) if dir != "down" else p + Vector2(0, -24), dir, 6.0, col)
		if on:
			var left := float(ringing[dir]) / maxf(0.9, 2.0 - d * 0.9)
			draw_rect(Rect2(p + Vector2(-18, 14) + (Vector2(0, -46) if dir == "down" else Vector2.ZERO), Vector2(36 * left, 3)), GREEN)
	draw_string(font, Vector2(c.x - 100, c.y + 6), "\"Grazie per la sua pazienza\"", HORIZONTAL_ALIGNMENT_CENTER, 200, 11, Color("8a8494"))


func _draw_scale(font: Font) -> void:
	var c := Vector2(BOX.get_center().x, BOX.end.y - 40)
	var r := 110.0
	for i in 21:
		var a := PI + PI * i / 20.0
		draw_line(c + Vector2(cos(a), sin(a)) * (r - 8), c + Vector2(cos(a), sin(a)) * r, Color.WHITE, 2.0)
	var aw := PI + PI * wanted
	draw_line(c + Vector2(cos(aw), sin(aw)) * (r - 16), c + Vector2(cos(aw), sin(aw)) * (r + 6), YELLOW, 6.0)
	var an := PI + PI * needle
	draw_line(c, c + Vector2(cos(an), sin(an)) * (r - 10), RED, 3.0)
	draw_circle(c, 6, Color.WHITE)
	# il piatto con la frutta
	draw_rect(Rect2(c.x - 50, c.y + 10, 100, 8), Color("aeb4c4"))
	for i in 4:
		draw_circle(Vector2(c.x - 30 + i * 20, c.y + 4), 8, [Color("e05050"), Color("f0a030"), Color("70c040"), Color("e05050")][i])
	draw_string(font, Vector2(BOX.position.x, BOX.position.y + 22), "Il cliente vuole: %d grammi" % int(round(wanted * 1000.0)), HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 14, Color.WHITE)


func _draw_sort(font: Font) -> void:
	var cx := BOX.get_center().x
	# il nastro
	draw_rect(Rect2(cx - 30, BOX.position.y + 4, 60, BOX.size.y - 8), Color("3a3644"))
	for y in range(int(BOX.position.y) + int(fmod(t * 60.0, 16.0)), int(BOX.end.y) - 4, 16):
		draw_rect(Rect2(cx - 30, y, 60, 2), Color("4d4a57"))
	draw_rect(Rect2(BOX.position.x + 20, BOX.end.y - 50, 70, 40), Color("8a2a2a"))
	draw_rect(Rect2(BOX.end.x - 90, BOX.end.y - 50, 70, 40), Color("2a4a8a"))
	draw_string(font, Vector2(BOX.position.x + 20, BOX.end.y - 56), "ROSSE <", HORIZONTAL_ALIGNMENT_CENTER, 70, 12, RED)
	draw_string(font, Vector2(BOX.end.x - 90, BOX.end.y - 56), "> BLU", HORIZONTAL_ALIGNMENT_CENTER, 70, 12, BLUE)
	for b in boxes:
		var r := Rect2(cx - 14, float(b["y"]) - 12, 28, 24)
		draw_rect(r, Color("b9894f"))
		draw_rect(Rect2(r.position + Vector2(8, 8), Vector2(12, 8)), RED if b["red"] else BLUE)
		draw_rect(r, Color("5c3f22"), false, 1.0)


func _draw_deliver() -> void:
	var lane_h := (BOX.size.y - 20) / 3.0
	for i in 3:
		var y := BOX.position.y + 10 + i * lane_h
		draw_rect(Rect2(BOX.position.x + 4, y, BOX.size.x - 8, lane_h - 2), Color("3a3a44"))
		for x in range(int(BOX.position.x) + 4 - int(fmod(t * 160.0, 40.0)) + 40, int(BOX.end.x) - 8, 40):
			draw_rect(Rect2(x, y + lane_h - 3, 18, 2), Color("d8d8c0"))
	for o in road:
		var y := BOX.position.y + 10 + int(o["lane"]) * lane_h + lane_h / 2.0
		var x := float(o["x"])
		if o["parcel"]:
			draw_rect(Rect2(x - 8, y - 8, 16, 14), Color("b9894f"))
			draw_rect(Rect2(x - 2, y - 8, 4, 14), Color("e8d29a"))
		else:
			draw_rect(Rect2(x - 20, y - 9, 40, 18), Color("d23b3b"))
			draw_rect(Rect2(x - 10, y - 6, 20, 5), Color("9fd0f0"))
	# la bici
	var by := BOX.position.y + 10 + lane * lane_h + lane_h / 2.0
	var bx := BOX.position.x + 60
	var blink := crash_t > 0.0 and int(t * 12) % 2 == 0
	if not blink:
		draw_circle(Vector2(bx - 10, by + 6), 6, Color.WHITE)
		draw_circle(Vector2(bx + 10, by + 6), 6, Color.WHITE)
		draw_rect(Rect2(bx - 8, by - 8, 16, 10), YELLOW)
		draw_rect(Rect2(bx - 4, by - 16, 8, 8), Color("e0a080"))


func _arrow(c: Vector2, dir: String, r: float, col: Color) -> void:
	var pts := PackedVector2Array([Vector2(0, -r), Vector2(r, r * 0.6), Vector2(-r, r * 0.6)])
	var ang := {"up": 0.0, "right": PI / 2, "down": PI, "left": -PI / 2}[dir] as float
	for i in pts.size():
		pts[i] = c + pts[i].rotated(ang)
	draw_colored_polygon(pts, col)
