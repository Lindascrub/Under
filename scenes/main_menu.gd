extends Control
## Schermata del titolo.

const INTRO := [
	"Tuo padre se n'è andato in silenzio, come faceva tutto.",
	"Ti ha lasciato una casa vuota...",
	"...e un debito di {debt}.",
	"La banca ti ha già scritto. Gli interessi corrono ogni notte.",
	"Domani inizi a lavorare alla CHEAP S.p.A.",
	"Hai {last_day} giorni.",
]

var _options: Array[String] = []
var _sel := 0
var _list: Label
var _locked := false


func _ready() -> void:
	Ui.show_hud(false)
	Ui.cutscene = false
	var bg := ColorRect.new()
	bg.color = Color("0b0a10")
	bg.size = Vector2(640, 360)
	add_child(bg)

	var title := _label("CHEAP", 64, Color.WHITE)
	title.position = Vector2(0, 36)
	var sub := _label("quanto costa diventare ricchi?", 16, Color("8a8494"))
	sub.position = Vector2(0, 116)

	_list = _label("", 18, Color.WHITE)
	_list.position = Vector2(0, 160)

	# Le persone del quartiere: le stesse che il giocatore incontrerà.
	for i in 7:
		var s := AnimatedSprite2D.new()
		s.sprite_frames = Assets.character("char_%02d" % (i + 2))
		s.scale = Vector2(2, 2)
		s.position = Vector2(176 + i * 48, 292)
		s.play("idle_down")
		s.frame = i % 6
		add_child(s)

	var credits := _label("Grafica: LimeZu (limezu.itch.io)", 11, Color("5c5666"))
	credits.position = Vector2(0, 338)

	if GameState.has_save():
		_options.assign(["Continua", "Nuova partita", "Esci"])
	else:
		_options.assign(["Nuova partita", "Esci"])
	_render()


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.size = Vector2(640, size + 12)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	add_child(l)
	return l


func _render() -> void:
	var lines: Array[String] = []
	for i in _options.size():
		lines.append(("> %s <" if i == _sel else "%s") % _options[i])
	_list.text = "\n".join(lines)
	_list.size = Vector2(640, 30 * _options.size())


func _unhandled_input(event: InputEvent) -> void:
	if _locked or Ui.blocks_input():
		return
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		var y := (event as InputEventScreenTouch).position.y - _list.position.y
		var i := int(y / (_list.get_line_height() + 1))
		if y >= 0 and i < _options.size():
			_sel = i
			_render()
			_choose(_options[_sel])
		return
	if event.is_action_pressed("move_up"):
		_sel = posmod(_sel - 1, _options.size())
		_render()
	elif event.is_action_pressed("move_down"):
		_sel = posmod(_sel + 1, _options.size())
		_render()
	elif event.is_action_pressed("confirm"):
		_choose(_options[_sel])


func _choose(option: String) -> void:
	_locked = true
	match option:
		"Nuova partita":
			GameState.new_game()
			GameState.delete_save()
			Router.goto(Router.HOME, "bed", INTRO)
		"Continua":
			Router.continue_game()
		"Esci":
			get_tree().quit()
