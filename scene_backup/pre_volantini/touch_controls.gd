extends CanvasLayer
## Comandi touch per il telefono: joystick a sinistra, pulsanti a destra.
## Trasformano i tocchi nelle stesse azioni della tastiera (move_*, confirm, cancel, menu),
## così il resto del gioco non deve sapere se si gioca col dito o con la tastiera.
## Si attivano da soli sui dispositivi touch; su PC si possono provare avviando con --touch.
##
## I minigiochi invece si giocano col dito, senza joystick: la scena dice come con touch_scheme()
##   "halves"  tieni il dito a sinistra o a destra dello schermo (move_left / move_right)
##   "hold"    tieni il dito ovunque: tiene premute le azioni di touch_hold()
##   "tap"     un tocco ovunque = {ok}
##   "dirs"    tocca sopra/sotto/a sinistra/a destra di touch_center(): una freccia
##   "swipe"   scorri il dito: una freccia; un tocco breve = {ok}
##   "point"   la scena riceve il dito: touch_point(posizione, fase) con fase 0 giù, 1 trascina, 2 su
## Una stringa vuota: per ora niente (per esempio durante i dialoghi).

const STICK_CENTER := Vector2(72, 292)
const STICK_RADIUS := 40.0
const KNOB_RADIUS := 17.0
const DEAD_ZONE := 0.35
## Quanto bisogna scorrere il dito perché conti come una freccia.
const SWIPE_MIN := 22.0
## Pulsanti: azione -> [centro, raggio, scritta]
const BUTTONS := {
	"confirm": [Vector2(592, 292), 26.0, "OK"],
	"cancel": [Vector2(540, 324), 19.0, "X"],
	"menu": [Vector2(612, 238), 15.0, "C"],
}

var enabled := false
## Cosa si vede adesso: il joystick e/o i pulsanti (dipende da dove sei, vedi _process).
var show_stick := true
var show_buttons := true
var _stick_finger := -1
var _stick_vec := Vector2.ZERO
var _held_dirs: Array[String] = []
var _button_fingers := {}
var _canvas: Node2D
## Il modo di gioco col dito della scena di adesso (vedi sopra) e le dita che lo stanno usando.
var scheme := ""
var _g_start := {}
var _g_held := {}
var _g_fired := {}


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	enabled = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or "--touch" in OS.get_cmdline_user_args() \
		or "--touch" in OS.get_cmdline_args()
	_canvas = Node2D.new()
	_canvas.draw.connect(_draw_controls)
	add_child(_canvas)
	visible = enabled


func _process(_delta: float) -> void:
	if not enabled:
		return
	var stick := true
	var buttons := true
	var scene := get_tree().current_scene
	var path := scene.scene_file_path if scene else ""
	var want := ""
	if scene and scene.has_method("touch_scheme") and not Ui.busy and not Ui.transitioning:
		want = str(scene.call("touch_scheme"))
	if want != scheme:
		_release_gestures()
		scheme = want
		_canvas.queue_redraw()
	if scene and scene.has_method("touch_scheme"):
		# i minigiochi si giocano col dito: niente joystick né pulsanti
		stick = false
		buttons = false
	elif Ui.busy or Ui.transitioning or Ui.cutscene or path == "res://scenes/main_menu.tscn":
		stick = false
		buttons = false
	elif path == "res://scenes/battle/battle.tscn":
		stick = scene.get("phase") == "dodge"
		buttons = false
	elif path == "res://scenes/minigame/minigame.tscn":
		stick = scene.get("phase") in ["play", "show"] and scene.get("type") != "timing"
		buttons = false
	if stick != show_stick or buttons != show_buttons:
		show_stick = stick
		show_buttons = buttons
		if not show_stick:
			_stick_finger = -1
			_move_stick(STICK_CENTER)
		if not show_buttons:
			for f in _button_fingers:
				_send(_button_fingers[f], false)
			_button_fingers.clear()
		_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if not enabled:
		return
	if scheme != "" and (event is InputEventScreenTouch or event is InputEventScreenDrag):
		_gesture(event)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if show_stick and t.position.distance_to(STICK_CENTER) < STICK_RADIUS * 1.6 and _stick_finger == -1:
				_stick_finger = t.index
				_move_stick(t.position)
				get_viewport().set_input_as_handled()
				return
			for action: String in BUTTONS:
				var b: Array = BUTTONS[action]
				if show_buttons and t.position.distance_to(b[0]) < float(b[1]) * 1.3:
					_button_fingers[t.index] = action
					_send(action, true)
					get_viewport().set_input_as_handled()
					_canvas.queue_redraw()
					return
		else:
			if t.index == _stick_finger:
				_stick_finger = -1
				_move_stick(STICK_CENTER)
				get_viewport().set_input_as_handled()
			elif _button_fingers.has(t.index):
				_send(_button_fingers[t.index], false)
				_button_fingers.erase(t.index)
				get_viewport().set_input_as_handled()
				_canvas.queue_redraw()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _stick_finger:
			_move_stick(d.position)
			get_viewport().set_input_as_handled()


func _move_stick(pos: Vector2) -> void:
	_stick_vec = (pos - STICK_CENTER).limit_length(STICK_RADIUS) / STICK_RADIUS
	var want: Array[String] = []
	if _stick_vec.length() > DEAD_ZONE:
		if _stick_vec.x < -DEAD_ZONE:
			want.append("move_left")
		if _stick_vec.x > DEAD_ZONE:
			want.append("move_right")
		if _stick_vec.y < -DEAD_ZONE:
			want.append("move_up")
		if _stick_vec.y > DEAD_ZONE:
			want.append("move_down")
	for a in _held_dirs:
		if a not in want:
			_send(a, false)
	for a in want:
		if a not in _held_dirs:
			_send(a, true)
	_held_dirs = want
	_canvas.queue_redraw()


## Un dito nei minigiochi: diventa frecce e {ok} secondo il modo della scena.
func _gesture(event: InputEvent) -> void:
	var scene := get_tree().current_scene
	if event is InputEventScreenDrag:
		var dr := event as InputEventScreenDrag
		if scheme == "point":
			scene.call("touch_point", dr.position, 1)
		elif scheme == "swipe" and _g_start.has(dr.index) and not _g_fired.has(dr.index):
			# la freccia parte appena il dito ha scorso abbastanza, senza aspettare che si stacchi
			var mv: Vector2 = dr.position - _g_start[dr.index]
			if mv.length() >= SWIPE_MIN:
				_g_fired[dr.index] = true
				_tap("move_" + _dir_of(mv))
		return
	var t := event as InputEventScreenTouch
	if t.pressed:
		_g_start[t.index] = t.position
		var acts: Array = []
		match scheme:
			"halves":
				acts = ["move_left" if t.position.x < 320.0 else "move_right"]
			"hold":
				acts = scene.call("touch_hold") if scene.has_method("touch_hold") else ["confirm"]
			"tap":
				_tap("confirm")
			"dirs":
				var c: Vector2 = scene.call("touch_center") if scene.has_method("touch_center") else Vector2(320, 180)
				_tap("move_" + _dir_of(t.position - c))
			"point":
				scene.call("touch_point", t.position, 0)
		for a: String in acts:
			_send(a, true)
		_g_held[t.index] = acts
		_canvas.queue_redraw()
	else:
		for a: String in _g_held.get(t.index, []):
			_send(a, false)
		_g_held.erase(t.index)
		if scheme == "swipe" and _g_start.has(t.index) and not _g_fired.has(t.index):
			var mv: Vector2 = t.position - _g_start[t.index]
			_tap("move_" + _dir_of(mv) if mv.length() >= SWIPE_MIN else "confirm")
		elif scheme == "point":
			scene.call("touch_point", t.position, 2)
		_g_start.erase(t.index)
		_g_fired.erase(t.index)
		_canvas.queue_redraw()


## La direzione (up/down/left/right) che conta di più in uno spostamento.
static func _dir_of(v: Vector2) -> String:
	if absf(v.x) > absf(v.y):
		return "right" if v.x > 0.0 else "left"
	return "down" if v.y > 0.0 else "up"


## Preme e lascia subito un'azione (un tocco).
func _tap(action: String) -> void:
	_send(action, true)
	_send(action, false)


## Lascia tutto quello che le dita stavano tenendo (cambia il modo, o si apre un dialogo).
func _release_gestures() -> void:
	for f in _g_held:
		for a: String in _g_held[f]:
			_send(a, false)
	_g_held.clear()
	_g_start.clear()
	_g_fired.clear()


## Invia un'azione come se fosse un tasto: aggiorna lo stato e genera l'evento per i menu.
func _send(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)


func _draw_controls() -> void:
	var font := Assets.font()
	var base := Color(1, 1, 1, 0.18)
	var line := Color(1, 1, 1, 0.45)
	if scheme == "halves":
		# le due metà dello schermo: dove tenere il dito
		for k in 2:
			var held := ("move_left" if k == 0 else "move_right") in _held_actions()
			_canvas.draw_rect(Rect2(k * 320 + 6, 312, 308, 42), Color(1, 0.88, 0.3, 0.28) if held else Color(1, 1, 1, 0.07))
			_canvas.draw_string(font, Vector2(k * 320 + 6, 338), "TOCCA QUI" if k == 0 else "E QUI", HORIZONTAL_ALIGNMENT_CENTER, 308, 12, Color(1, 1, 1, 0.5))
	elif scheme == "hold":
		var down := not _g_held.is_empty()
		_canvas.draw_rect(Rect2(6, 312, 628, 42), Color(1, 0.88, 0.3, 0.28) if down else Color(1, 1, 1, 0.07))
		_canvas.draw_string(font, Vector2(6, 338), "TIENI IL DITO SULLO SCHERMO" if not down else "...", HORIZONTAL_ALIGNMENT_CENTER, 628, 12, Color(1, 1, 1, 0.5))
	if show_stick:
		_draw_stick(base, line)
	if not show_buttons:
		return
	for action: String in BUTTONS:
		var b: Array = BUTTONS[action]
		var down := action in _button_fingers.values()
		_canvas.draw_circle(b[0], b[1], Color(1, 0.88, 0.3, 0.55) if down else base)
		_canvas.draw_arc(b[0], b[1], 0, TAU, 32, line, 2.0)
		var size := 14 if float(b[1]) > 20 else 11
		_canvas.draw_string(font, b[0] + Vector2(-b[1], size * 0.35), str(b[2]), HORIZONTAL_ALIGNMENT_CENTER, float(b[1]) * 2.0, size, Color(1, 1, 1, 0.85))


func _held_actions() -> Array:
	var out: Array = []
	for f in _g_held:
		out.append_array(_g_held[f])
	return out


func _draw_stick(base: Color, line: Color) -> void:
	_canvas.draw_circle(STICK_CENTER, STICK_RADIUS, base)
	_canvas.draw_arc(STICK_CENTER, STICK_RADIUS, 0, TAU, 32, line, 2.0)
	_canvas.draw_circle(STICK_CENTER + _stick_vec * STICK_RADIUS, KNOB_RADIUS, Color(1, 1, 1, 0.45))
