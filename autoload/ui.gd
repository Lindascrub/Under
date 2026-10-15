extends CanvasLayer
## Interfaccia globale: HUD, box dei dialoghi, scelte, dissolvenze e testo narrato.
## Uso tipico:  await Ui.say(["Ciao!"], "Nico")   /   var i: int = await Ui.choose("Sì o no?", ["Sì", "No"])

signal faded_in
signal _advance
signal _chosen(index: int)

const TYPE_SPEED := 45.0
const COL_TEXT := Color.WHITE
const COL_NAME := Color("ffe14d")
const COL_DIM := Color("8a8494")

## Vero mentre un dialogo o una scelta è aperta.
var busy := false
## Vero durante le dissolvenze tra scene.
var transitioning := false
## Vero durante le scene scriptate (finali): il giocatore non si muove.
var cutscene := false

var _hud: Label
var _box: Panel
var _name: Label
var _text: Label
var _choice_box: Panel
var _choice_label: Label
var _fade: ColorRect
var _narr: Label
var _time_bar: Control
var _portrait: TextureRect
var _portrait_tex: AtlasTexture
var _talk_t := 0.0
## Ritratti extra per chi non è in npcs.json.
const EXTRA_PORTRAITS := {"Dottor Prezzi": "char_18"}

var _mode := ""
var _label: Label
var _typed := 0.0
var _typing := false
var _options: Array = []
var _sel := 0
var _pitch := 1.0
var _last_blip := 0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	GameState.changed.connect(_refresh_hud)
	_refresh_hud()
	show_hud(false)


func blocks_input() -> bool:
	return busy or transitioning or cutscene


func show_hud(visible_: bool) -> void:
	_hud.visible = visible_
	if _time_bar:
		_time_bar.visible = visible_


## La giornata in 24 caselle: sonno, ore passate, lavoro che ti aspetta e il poco tempo davvero tuo.
func _draw_time_bar() -> void:
	var font := Assets.font()
	var w := 7.0
	var now := GameState.minutes / 60.0
	var work_left := 0.0 if GameState.worked_today else 10.0
	var own := GameState.own_hours()
	var future_i := 0
	for h in 24:
		var col: Color
		if h < 7:
			col = Color("2b3a6b")
		elif h + 1 <= now:
			col = Color("3a3644")
		else:
			if future_i < int(work_left):
				col = Color("c06a2a")
			elif future_i >= int(work_left) + int(own):
				col = Color("5c5666")
			else:
				col = Color("3ddc84")
			future_i += 1
		_time_bar.draw_rect(Rect2(h * w, 0, w - 1, 6), col)
	_time_bar.draw_rect(Rect2(clampf(now, 0, 24) * w - 1, -2, 2, 10), Color.WHITE)
	_time_bar.draw_string(font, Vector2(24 * w + 6, 7), "Tempo tuo: %d h" % int(own), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("3ddc84"))


# --- costruzione ------------------------------------------------------------

func _panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color.BLACK
	s.border_color = Color.WHITE
	s.set_border_width_all(3)
	return s


func _make_label(size: int, color := COL_TEXT) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _build() -> void:
	_hud = _make_label(13)
	_hud.position = Vector2(8, 6)
	_hud.add_theme_constant_override("outline_size", 5)
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(_hud)
	_time_bar = Control.new()
	_time_bar.position = Vector2(8, 24)
	_time_bar.size = Vector2(300, 12)
	_time_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_time_bar.draw.connect(_draw_time_bar)
	add_child(_time_bar)

	_box = Panel.new()
	_box.add_theme_stylebox_override("panel", _panel_style())
	_box.position = Vector2(16, 258)
	_box.size = Vector2(608, 90)
	add_child(_box)
	_name = _make_label(13, COL_NAME)
	_name.position = Vector2(14, 6)
	_box.add_child(_name)
	_portrait_tex = AtlasTexture.new()
	_portrait = TextureRect.new()
	_portrait.texture = _portrait_tex
	_portrait.position = Vector2(12, 21)
	_portrait.size = Vector2(48, 48)
	_portrait.stretch_mode = TextureRect.STRETCH_SCALE
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_box.add_child(_portrait)
	_text = _make_label(16)
	_text.position = Vector2(14, 24)
	_text.size = Vector2(580, 62)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(_text)
	_box.visible = false

	_choice_box = Panel.new()
	_choice_box.add_theme_stylebox_override("panel", _panel_style())
	add_child(_choice_box)
	_choice_label = _make_label(16)
	_choice_label.position = Vector2(12, 8)
	_choice_box.add_child(_choice_label)
	_choice_box.visible = false

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.position = Vector2.ZERO
	_fade.size = Vector2(640, 360)
	add_child(_fade)

	_narr = _make_label(18)
	_narr.position = Vector2(60, 40)
	_narr.size = Vector2(520, 280)
	_narr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_narr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_narr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_narr.visible = false
	add_child(_narr)


func _refresh_hud() -> void:
	_hud.text = "%s %s   LV %d   Giorno %d/%d   Debito %s   Soldi %s   Energia %d/%d" % [
		GameState.day_name(), GameState.clock(), GameState.lv(), mini(GameState.day, GameState.LAST_DAY), GameState.LAST_DAY,
		GameState.euros(GameState.debt), GameState.euros(GameState.money),
		GameState.energy, GameState.MAX_ENERGY,
	]
	if _time_bar:
		_time_bar.queue_redraw()


# --- dialoghi ---------------------------------------------------------------

## Mostra il ritratto (testa ingrandita) di chi parla, come in Undertale.
func _show_portrait(speaker: String, sheet: String) -> void:
	if sheet == "" and speaker != "":
		sheet = EXTRA_PORTRAITS.get(speaker, "")
		if sheet == "":
			for id: String in GameState.npc_ids():
				var d := GameState.npc_data(id)
				if str(d.get("name", "")) == speaker:
					sheet = str(d.get("sheet", ""))
					break
	var has := sheet != ""
	_portrait.visible = has
	if has:
		_portrait_tex.atlas = Assets.tex("characters/%s.png" % sheet, Vector2i(896, 656))
		_portrait_tex.region = Rect2(18 * 16, 41, 16, 16)
	_name.position.x = 70.0 if has else 14.0
	_text.position.x = 70.0 if has else 14.0
	_text.size.x = 524.0 if has else 580.0


func say(lines: Array, speaker: String = "", portrait: String = "") -> void:
	busy = true
	_box.visible = true
	_name.text = speaker
	_name.visible = speaker != ""
	_show_portrait(speaker, portrait)
	_pitch = 1.0 if speaker == "" else 0.75 + float(absi(speaker.hash()) % 50) / 100.0
	for line: Variant in lines:
		await _type(_text, GameState.fmt(str(line)))
	_box.visible = false
	busy = false


func choose(prompt: String, options: Array, speaker: String = "") -> int:
	busy = true
	_box.visible = true
	_name.text = speaker
	_name.visible = speaker != ""
	_show_portrait(speaker, "")
	_text.text = GameState.fmt(prompt)
	_text.visible_characters = -1
	_options = options
	_sel = 0
	_render_choices()
	_choice_box.visible = true
	_mode = "choose"
	var idx: int = await _chosen
	_mode = ""
	_choice_box.visible = false
	_box.visible = false
	busy = false
	return idx


## Testo centrato su schermo nero (intro, cambio giorno, finali). Usalo dopo fade_out().
func narrate(lines: Array) -> void:
	busy = true
	_pitch = 0.6
	_narr.visible = true
	for line: Variant in lines:
		await _type(_narr, GameState.fmt(str(line)))
	_narr.visible = false
	busy = false


func show_status() -> void:
	var hours := GameState.hours_left()
	var options: Array = []
	for item in GameState.items:
		options.append(item)
	options.append("Chiudi")
	var prompt := "{rank}. {day_name} {clock}: mancano %d ore a mezzanotte. Energia %d/%d." % [
		int(hours), GameState.energy, GameState.MAX_ENERGY]
	var missions := Quests.active_titles()
	if not missions.is_empty():
		prompt += "
Missioni: " + ", ".join(missions) + "."
	if GameState.items.is_empty():
		prompt += "
Non hai oggetti."
	var i: int = await choose(prompt, options, "Stato")
	if i < GameState.items.size():
		Sound.sfx("heal")
		await say(GameState.use_item(i).split("
"))


func _type(label: Label, text: String) -> void:
	label.text = text
	label.visible_characters = 0
	_label = label
	_last_blip = 0
	_typed = 0.0
	_typing = true
	_mode = "say"
	await _advance
	_mode = ""


func _render_choices() -> void:
	var lines: Array[String] = []
	for i in _options.size():
		lines.append(("> " if i == _sel else "   ") + GameState.fmt(str(_options[i])))
	_choice_label.text = "\n".join(lines)
	var w := 0.0
	var font := _choice_label.get_theme_font("font")
	for l in lines:
		w = maxf(w, font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x)
	_choice_box.size = Vector2(w + 28, _options.size() * 23 + 14)
	_choice_box.position = Vector2(624 - _choice_box.size.x, 252 - _choice_box.size.y)


func _process(delta: float) -> void:
	if not _typing or _label == null:
		return
	_typed += delta * TYPE_SPEED
	_label.visible_characters = int(_typed)
	if _portrait.visible and _label == _text:
		_talk_t += delta
		# "bocca" che si muove: alterna due fotogrammi mentre il testo scorre
		_portrait_tex.region.position.x = (18 + (int(_talk_t * 8.0) % 2) * 2) * 16
	if int(_typed) - _last_blip >= 2:
		_last_blip = int(_typed)
		var ch := _label.text.substr(clampi(_last_blip - 1, 0, _label.text.length() - 1), 1)
		if ch != " " and ch != "*":
			Sound.blip(_pitch)
	if int(_typed) >= _label.get_total_character_count():
		_label.visible_characters = -1
		_typing = false
		_portrait_tex.region.position.x = 18 * 16


## Tocchi sullo schermo: un tocco sul dialogo lo fa avanzare, un tocco su una scelta la seleziona.
func _touch(event: InputEventScreenTouch) -> bool:
	if not event.pressed:
		return false
	if _mode == "say":
		if _typing:
			_typing = false
			_label.visible_characters = -1
		else:
			_advance.emit()
		return true
	if _mode == "choose":
		var r := Rect2(_choice_box.position, _choice_box.size)
		if r.has_point(event.position):
			var i := clampi(int((event.position.y - r.position.y - 8.0) / 23.0), 0, _options.size() - 1)
			_sel = i
			_render_choices()
			Sound.sfx("select")
			_chosen.emit(_sel)
			return true
	return false


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if _touch(event):
			get_viewport().set_input_as_handled()
		return
	if _mode == "say":
		if event.is_action_pressed("confirm") or event.is_action_pressed("cancel"):
			get_viewport().set_input_as_handled()
			if _typing:
				_typing = false
				_label.visible_characters = -1
			elif event.is_action_pressed("confirm"):
				_advance.emit()
	elif _mode == "choose":
		if event.is_action_pressed("move_up"):
			get_viewport().set_input_as_handled()
			_sel = posmod(_sel - 1, _options.size())
			Sound.sfx("move")
			_render_choices()
		elif event.is_action_pressed("move_down"):
			get_viewport().set_input_as_handled()
			_sel = posmod(_sel + 1, _options.size())
			Sound.sfx("move")
			_render_choices()
		elif event.is_action_pressed("confirm"):
			get_viewport().set_input_as_handled()
			Sound.sfx("select")
			_chosen.emit(_sel)


# --- dissolvenze ------------------------------------------------------------

func fade_out(time := 0.35) -> void:
	transitioning = true
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, time)
	await tw.finished


func fade_in(time := 0.35) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, time)
	await tw.finished
	transitioning = false
	faded_in.emit()
