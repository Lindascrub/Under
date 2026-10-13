extends Node2D
## Battaglia in stile Undertale. La configurazione arriva da GameState.battle:
##   kind "person": una persona ti travolge coi suoi problemi.
##       PROMUOVI (le "proponi un affare": guadagni, lei diventa un robot)  PARLA (fiducia)  OGGETTI  AIUTA (quando il nome è giallo)
##   kind "work":   un turno di lavoro duro.
##       LAVORA (avanzi)  PARLA  OGGETTI  MOLLA
##   kind "sign":   il lavoro facile. Tutti e quattro i pulsanti dicono FIRMA.
## Durante il turno avversario muovi il cuore nel riquadro ed eviti gli "attacchi".

const MAIN_BOX := Rect2(32, 170, 576, 104)
const DODGE_BOX := Rect2(240, 162, 160, 116)
const BTN_Y := 314.0
const SOUL_SPEED := 130.0
const SOUL_R := 5.0
const ATTACK_TIME := 6.0
const RED := Color("ff2a3c")
const ORANGE := Color("ff8a1f")
const YELLOW := Color("ffe14d")
const GREY := Color("6c6878")
const BLUE := Color("39b6ff")

var cfg: Dictionary = {}
var kind := "person"
var phase := "intro"
var menu := 0
var sub := 0
var sub_items: Array = []
var sub_kind := ""
var trust := 0
var progress := 0
var hits := 0
var turn := 0
## Usato solo dal test automatico per scegliere la voce del sottomenu.
var _pending_sub := 0

var box := MAIN_BOX
var box_target := MAIN_BOX
var soul := Vector2.ZERO
var soul_moved := false
var iframes := 0.0
var bullets: Array[Dictionary] = []
var attack := ""
var attack_t := 0.0
var spawn_t := 0.0

var _msgs: Array = []
var _after: Callable
var _enemy: AnimatedSprite2D
var _enemy_mat: ShaderMaterial
var _text: Label
var _bubble: Panel
var _bubble_label: Label
var _typed := 0.0
var _typing := false
var _last_blip := 0
var _shake := 0.0


func _ready() -> void:
	cfg = GameState.battle
	kind = str(cfg.get("kind", "person"))
	Ui.show_hud(false)
	Sound.music("battaglia")

	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.size = Vector2(640, 360)
	bg.z_index = -10
	add_child(bg)

	_enemy = AnimatedSprite2D.new()
	_enemy.sprite_frames = Assets.character(str(cfg.get("sheet", "char_13")))
	_enemy.centered = false
	_enemy.scale = Vector2(4, 4)
	_enemy.position = Vector2(320 - 32, 26)
	_enemy_mat = ShaderMaterial.new()
	_enemy_mat.shader = preload("res://shaders/robot.gdshader")
	_enemy.material = _enemy_mat
	add_child(_enemy)
	_enemy.play("idle_down")

	_text = Label.new()
	_text.add_theme_font_size_override("font_size", 16)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_text)

	_bubble = Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color.WHITE
	st.set_corner_radius_all(4)
	_bubble.add_theme_stylebox_override("panel", st)
	_bubble.position = Vector2(372, 34)
	_bubble.size = Vector2(190, 70)
	_bubble.visible = false
	add_child(_bubble)
	_bubble_label = Label.new()
	_bubble_label.add_theme_font_size_override("font_size", 14)
	_bubble_label.add_theme_color_override("font_color", Color.BLACK)
	_bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_label.position = Vector2(10, 6)
	_bubble_label.size = Vector2(170, 58)
	_bubble.add_child(_bubble_label)

	if Ui.transitioning:
		await Ui.faded_in
	_show_menu_text(str(cfg.get("intro", "* Qualcuno ti si avvicina.")))


# --- testo ------------------------------------------------------------------

func _show_menu_text(t: String) -> void:
	phase = "menu"
	_set_text(GameState.fmt(t))


func _set_text(t: String) -> void:
	_text.text = t
	_text.visible_characters = 0
	_typed = 0.0
	_last_blip = 0
	_typing = true


## Mostra dei messaggi uno dopo l'altro (Z per andare avanti), poi chiama `after`.
func _say(lines: Array, after: Callable) -> void:
	_msgs = lines.duplicate()
	_after = after
	phase = "msg"
	box_target = MAIN_BOX
	_set_text(GameState.fmt(str(_msgs.pop_front())))


func _next_msg() -> void:
	if _msgs.is_empty():
		_after.call()
	else:
		_set_text(GameState.fmt(str(_msgs.pop_front())))


# --- pulsanti ---------------------------------------------------------------

func _buttons() -> Array[String]:
	match kind:
		"work":
			return ["LAVORA", "PARLA", "OGGETTI", "MOLLA"]
		"sign":
			return ["FIRMA", "FIRMA", "FIRMA", "FIRMA"]
	return ["PROMUOVI", "PARLA", "OGGETTI", "AIUTA"]


func _ready_to_help() -> bool:
	return trust >= int(cfg.get("trust_goal", 2))


func _choose_button() -> void:
	Sound.sfx("select")
	if kind == "sign":
		_sign()
		return
	match menu:
		0:
			if kind == "work":
				progress += 1
				var goal := int(cfg.get("goal", 4))
				_say(["* " + str(cfg.get("work_line", "Lavori sodo.")) + " (%d/%d)" % [progress, goal]], _enemy_turn)
			else:
				var ex: Dictionary = cfg.get("exploit", {})
				_open_sub("exploit", [str(ex.get("name", "Approfittane"))])
		1:
			var names: Array = []
			for a: Dictionary in cfg.get("acts", []):
				names.append(a.get("name", "?"))
			_open_sub("act", names)
		2:
			if GameState.items.is_empty():
				Sound.sfx("deny")
				return
			_open_sub("item", GameState.items.duplicate())
		3:
			if kind == "work":
				_open_sub("quit", ["Molla il turno"])
			else:
				var opts: Array = ["Aiuta", "Vai via"]
				_open_sub("mercy", opts)


func _open_sub(k: String, items: Array) -> void:
	sub_kind = k
	sub_items = items
	sub = 0
	phase = "sub"
	_text.text = ""


func _choose_sub() -> void:
	Sound.sfx("select")
	match sub_kind:
		"exploit":
			var ex: Dictionary = cfg.get("exploit", {})
			var pay := int(ex.get("pay", 200))
			GameState.exploit(str(cfg.get("id", "")), pay)
			Sound.sfx("coin")
			var lines: Array = ex.get("lines", ["* Ne approfitti."]).duplicate()
			lines.append("* +%s. Sei stato promosso: ora sei {rank}." % GameState.euros(pay))
			_say(lines, func() -> void: _fade_enemy_and(_end_battle))
		"act":
			var act: Dictionary = cfg.get("acts", [])[sub]
			trust += int(act.get("trust", 0))
			var lines: Array = act.get("lines", ["* ..."]).duplicate()
			if kind == "person" and _ready_to_help():
				lines.append("* (%s si fida di te. Ora puoi AIUTARE.)" % cfg.get("name", ""))
			_say(lines, _enemy_turn)
		"item":
			Sound.sfx("heal")
			_say(GameState.use_item(sub).split("\n"), _enemy_turn)
		"quit":
			_finish_work(true)
		"mercy":
			if sub == 1:
				_say(["* Te ne vai. %s ti guarda andare via." % cfg.get("name", "")], _end_battle)
			elif not _ready_to_help():
				_say(["* %s non si fida ancora abbastanza di te." % cfg.get("name", "")], _enemy_turn)
			else:
				_help()


func _help() -> void:
	var h: Dictionary = cfg.get("help", {})
	var kind_ := str(h.get("kind", "time"))
	var cost := int(h.get("cost", 0))
	if kind_ == "time" and h.has("minigame"):
		if not GameState.has_time(GameState.COST_HELP_TIME):
			Sound.sfx("deny")
			_say(["* Vorresti aiutare, ma è troppo tardi: non ti resta abbastanza tempo oggi."], _enemy_turn)
			return
		Sound.sfx("spare")
		phase = "end"
		var back := str(cfg.get("return", Router.STREET))
		var back_pos: Vector2 = cfg.get("return_pos", Vector2(100, 150))
		Router.minigame(Npc.minigame_cfg(str(cfg.get("id", "")), str(cfg.get("name", "")), h, back, back_pos))
		return
	if GameState.help(str(cfg.get("id", "")), kind_, cost):
		Sound.sfx("spare")
		var lines: Array = ["* " + str(h.get("ask", ""))]
		lines.append_array(h.get("yes", ["Grazie."]))
		if kind_ == "money":
			lines.append("* Hai dato %s." % GameState.euros(cost))
		else:
			lines.append("* Ci hai messo due ore. Ne è valsa la pena.")
		_say(lines, _end_battle)
	elif kind_ == "money":
		Sound.sfx("deny")
		_say(["* Vorresti aiutare, ma non hai %s." % GameState.euros(cost)], _enemy_turn)
	else:
		Sound.sfx("deny")
		_say(["* Vorresti aiutare, ma è troppo tardi: non ti resta abbastanza tempo oggi."], _enemy_turn)


# --- lavoro facile ----------------------------------------------------------

func _sign() -> void:
	var pay := GameState.do_easy_job()
	Sound.sfx("stamp")
	phase = "anim"
	_text.text = ""
	# Un attimo, per un istante, si vede qualcosa di strano.
	for i in 3:
		Sound.sfx("glitch")
		_enemy_mat.set_shader_parameter("amount", 0.9)
		await get_tree().create_timer(0.08).timeout
		_enemy_mat.set_shader_parameter("amount", 0.0)
		await get_tree().create_timer(0.12).timeout
	var tw := create_tween()
	tw.tween_property(_enemy, "modulate:a", 0.0, 0.8)
	await tw.finished
	Sound.sfx("coin")
	_say([
		"* Hai firmato. Ci è voluto un secondo.",
		"* +%s. Il capo è soddisfatto: ora sei {rank}!" % GameState.euros(pay),
		"* %s non lo vedrai firmare niente. Non lo vedrai più, a dire il vero." % cfg.get("name", "Qualcuno"),
	], _end_battle)


# --- turno avversario -------------------------------------------------------

func _enemy_turn() -> void:
	var attacks: Array = cfg.get("attacks", ["bills"])
	attack = str(attacks[turn % attacks.size()])
	turn += 1
	var talk: Array = cfg.get("talk", ["..."])
	var line := str(talk[(turn - 1) % talk.size()])
	if attack == "camera":
		line = "Ti tengo d'occhio. Se ti muovi quando la luce è BLU, lo vedo."
	_bubble_label.text = line
	_bubble.visible = true
	phase = "bubble"
	_text.text = ""
	box_target = DODGE_BOX
	soul = DODGE_BOX.get_center()


func _start_dodge() -> void:
	_bubble.visible = false
	phase = "dodge"
	attack_t = 0.0
	spawn_t = 0.0
	bullets.clear()


func _end_dodge() -> void:
	bullets.clear()
	box_target = MAIN_BOX
	if kind == "work" and progress >= int(cfg.get("goal", 4)):
		_finish_work(false)
		return
	var flavor: Array = cfg.get("flavor", ["* ..."])
	var t := str(flavor[turn % flavor.size()])
	if kind == "person" and _ready_to_help():
		t = "* %s ti guarda con speranza." % cfg.get("name", "")
	_show_menu_text(t)


func _finish_work(quit: bool) -> void:
	var goal := int(cfg.get("goal", 4))
	var base := int(cfg.get("pay", 220))
	var pay := maxi(30, int(base * float(progress) / goal) - hits * 8)
	if quit:
		pay = int(pay * 0.5)
	GameState.finish_hard_job(pay)
	Sound.sfx("coin")
	var lines: Array = []
	if quit:
		lines.append("* Molli il turno a metà. Il caporeparto scuote la testa.")
	else:
		lines.append("* Turno finito. Otto ore della tua vita.")
	lines.append("* Paga: %s. Colpi presi: %d." % [GameState.euros(pay), hits])
	lines.append(str(cfg.get("tired", "* Ti fa male tutto.")))
	_say(lines, _end_battle)


# --- fine -------------------------------------------------------------------

func _fade_enemy_and(next: Callable) -> void:
	phase = "anim"
	Sound.sfx("glitch")
	var tw := create_tween()
	tw.tween_property(_enemy, "modulate:a", 0.0, 0.6)
	await tw.finished
	next.call()


func _end_battle() -> void:
	phase = "end"
	var back := str(cfg.get("return", Router.STREET))
	var spawn := "_back" if cfg.has("return_pos") else str(cfg.get("spawn", "default"))
	Router.goto(back, spawn)


func _burnout() -> void:
	phase = "anim"
	bullets.clear()
	Sound.sfx("hurt", 0.6)
	await get_tree().create_timer(0.8).timeout
	GameState.energy = GameState.MAX_ENERGY / 2
	if kind == "work":
		GameState.refuse_work()
	GameState.spend(3 * 60)
	_say(["* Il cuore ti batte troppo forte. Ti siedi per terra.", "* Sei crollato dallo stress. Passano tre ore prima che tu riesca ad alzarti."], _end_battle)


# --- ciclo ------------------------------------------------------------------

func _process(delta: float) -> void:
	box.position = box.position.lerp(box_target.position, 0.25)
	box.size = box.size.lerp(box_target.size, 0.25)
	_text.position = box.position + Vector2(16, 12)
	_text.size = Vector2(box.size.x - 32, box.size.y - 20)
	_shake = maxf(0.0, _shake - delta * 20.0)

	if _typing:
		_typed += delta * 45.0
		_text.visible_characters = int(_typed)
		if int(_typed) - _last_blip >= 2:
			_last_blip = int(_typed)
			Sound.blip(0.9)
		if int(_typed) >= _text.get_total_character_count():
			_text.visible_characters = -1
			_typing = false

	if phase == "dodge":
		_dodge(delta)
	queue_redraw()


func _dodge(delta: float) -> void:
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed := SOUL_SPEED * (0.5 if Input.is_action_pressed("cancel") else 1.0)
	var before := soul
	soul += v * speed * delta
	var inner := box.grow(-SOUL_R - 4)
	soul = soul.clamp(inner.position, inner.end)
	soul_moved = soul.distance_to(before) > 0.1
	iframes = maxf(0.0, iframes - delta)

	attack_t += delta
	spawn_t -= delta
	Patterns.update(self, attack, delta)
	for b in bullets:
		b["vel"] = (b["vel"] as Vector2) + (b.get("acc", Vector2.ZERO) as Vector2) * delta
		b["pos"] = (b["pos"] as Vector2) + (b["vel"] as Vector2) * delta
		b["t"] = float(b.get("t", 0.0)) + delta
	var keep: Array[Dictionary] = []
	var far := box.grow(90)
	for b in bullets:
		if far.has_point(b["pos"]) and float(b["t"]) < float(b.get("life", 99.0)):
			keep.append(b)
	bullets = keep

	if iframes <= 0.0:
		for b in bullets:
			if b.get("harmless", false):
				continue
			if b.get("blue", false) and not soul_moved:
				continue
			if _hits(b):
				var dmg := int(cfg.get("damage", 3))
				GameState.hurt(dmg)
				hits += 1
				iframes = 1.0
				_shake = 4.0
				Sound.sfx("hurt")
				if GameState.energy <= 0:
					_burnout()
					return
				break
	if attack_t >= ATTACK_TIME:
		_end_dodge()


func _hits(b: Dictionary) -> bool:
	var size: Vector2 = b.get("size", Vector2(8, 8))
	var r := Rect2((b["pos"] as Vector2) - size / 2.0, size)
	var closest := soul.clamp(r.position, r.end)
	return closest.distance_to(soul) < SOUL_R - 1.0


## Sul telefono si possono toccare direttamente pulsanti e voci dei menu.
func _touch(pos: Vector2) -> void:
	match phase:
		"menu":
			for i in 4:
				if Rect2(32 + i * 149, BTN_Y, 130, 32).has_point(pos):
					menu = i
					if _typing:
						_typing = false
						_text.visible_characters = -1
					_choose_button()
					return
		"sub":
			for i in sub_items.size():
				if Rect2(box.position.x + 20, box.position.y + 14 + i * 22, box.size.x - 40, 22).has_point(pos):
					sub = i
					_choose_sub()
					return
		"msg":
			if _typing:
				_typing = false
				_text.visible_characters = -1
			else:
				_next_msg()
		"bubble":
			_start_dodge()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_touch((event as InputEventScreenTouch).position)
		return
	var n := 4
	match phase:
		"menu":
			if event.is_action_pressed("move_left"):
				menu = posmod(menu - 1, n)
				Sound.sfx("move")
			elif event.is_action_pressed("move_right"):
				menu = posmod(menu + 1, n)
				Sound.sfx("move")
			elif event.is_action_pressed("confirm"):
				if _typing:
					_typing = false
					_text.visible_characters = -1
				_choose_button()
		"sub":
			if event.is_action_pressed("move_up"):
				sub = posmod(sub - 1, sub_items.size())
				Sound.sfx("move")
			elif event.is_action_pressed("move_down"):
				sub = posmod(sub + 1, sub_items.size())
				Sound.sfx("move")
			elif event.is_action_pressed("confirm"):
				_choose_sub()
			elif event.is_action_pressed("cancel"):
				_show_menu_text(_text.text if _text.text != "" else "* ...")
		"msg":
			if event.is_action_pressed("confirm") or event.is_action_pressed("cancel"):
				if _typing:
					_typing = false
					_text.visible_characters = -1
				elif event.is_action_pressed("confirm"):
					_next_msg()
		"bubble":
			if event.is_action_pressed("confirm"):
				_start_dodge()


# --- disegno ----------------------------------------------------------------

func _draw() -> void:
	var font := Assets.font()
	var off := Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	# riquadro
	draw_rect(Rect2(box.position + off, box.size), Color.BLACK)
	draw_rect(Rect2(box.position + off, box.size), Color.WHITE, false, 3.0)

	if phase == "sub":
		for i in sub_items.size():
			var p := box.position + Vector2(48, 30 + i * 22)
			var col := Color.WHITE
			if sub_kind == "mercy" and i == 0 and _ready_to_help():
				col = YELLOW
			draw_string(font, p, "* " + str(sub_items[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
			if i == sub:
				_heart(p + Vector2(-14, -5), RED)

	if phase == "dodge" or phase == "bubble":
		Patterns.draw_all(self, bullets)
		if iframes <= 0.0 or int(iframes * 12) % 2 == 0:
			_heart(soul + off, BLUE if attack == "camera" else RED)

	# nome e barra della fiducia / del lavoro
	var name_col := YELLOW if kind == "person" and _ready_to_help() else Color.WHITE
	draw_string(font, Vector2(32, 160), str(cfg.get("name", "")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, name_col)
	if kind == "person":
		_bar(Vector2(170, 160), "FIDUCIA", trust, int(cfg.get("trust_goal", 2)), YELLOW)
	elif kind == "work":
		_bar(Vector2(170, 160), "TURNO", progress, int(cfg.get("goal", 4)), Color("3ddc84"))

	# statistiche
	draw_string(font, Vector2(32, 300), "TU   %s" % GameState.rank_name(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	draw_string(font, Vector2(300, 300), "ENERGIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	var w := 80.0
	draw_rect(Rect2(362, 289, w, 12), Color("8a1020"))
	draw_rect(Rect2(362, 289, w * GameState.energy / GameState.MAX_ENERGY, 12), YELLOW)
	draw_string(font, Vector2(450, 300), "%d / %d" % [GameState.energy, GameState.MAX_ENERGY], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	draw_string(font, Vector2(530, 300), GameState.clock(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("8a8494"))

	# pulsanti
	var labels := _buttons()
	for i in 4:
		var r := Rect2(32 + i * 149, BTN_Y, 130, 32)
		var sel := i == menu and (phase == "menu" or phase == "sub")
		var col := YELLOW if sel else ORANGE
		if kind == "person" and i == 3 and _ready_to_help() and not sel:
			col = YELLOW.darkened(0.2)
		draw_rect(r, col, false, 2.0)
		if sel and phase == "menu":
			_heart(r.position + Vector2(16, 16), RED)
		draw_string(font, r.position + Vector2(30, 22), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)


func _bar(pos: Vector2, label: String, value: int, goal: int, col: Color) -> void:
	var font := Assets.font()
	draw_string(font, pos + Vector2(0, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("8a8494"))
	var w := 90.0
	draw_rect(Rect2(pos + Vector2(60, -9), Vector2(w, 8)), Color("2a2633"))
	draw_rect(Rect2(pos + Vector2(60, -9), Vector2(w * clampf(float(value) / maxf(1, goal), 0, 1), 8)), col)


## Cuore pixel art 9x8.
func _heart(c: Vector2, col: Color) -> void:
	const ROWS := ["011000110", "111101111", "111111111", "111111111", "011111110", "001111100", "000111000", "000010000"]
	var o := c - Vector2(4.5, 4)
	for y in ROWS.size():
		var row: String = ROWS[y]
		for x in row.length():
			if row[x] == "1":
				draw_rect(Rect2(o + Vector2(x, y), Vector2.ONE), col)
