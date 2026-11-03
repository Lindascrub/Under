extends CanvasLayer
## Interfaccia globale: HUD, box dei dialoghi, scelte, dissolvenze e testo narrato.
## Uso tipico:  await Ui.say(["Ciao!"], "Nico")   /   var i: int = await Ui.choose("Sì o no?", ["Sì", "No"])
## È la scena autoload/ui.tscn: Hud, TurnoDiOggi, Riquadro (Nome, Ritratto, Testo), Scelte (Righe),
## Buio (le dissolvenze) e Narrazione. Posizioni, font e colori si cambiano lì.

signal faded_in
signal _advance
signal _chosen(index: int)

## Lettere al secondo quando il testo si scrive.
@export var velocita_scrittura := 45.0
## Il ritratto del Capo (arcobaleno).
@export var materiale_capo: Material
## La riga "Turno di oggi" sotto l'HUD: i colori per da fare, fatto, e la Cima.
@export var colore_turno_da_fare := Color("ffb03a")
@export var colore_turno_fatto := Color("3ddc84")
@export var colore_turno_cima := Color("ffe14d")
## Le scelte: l'angolo in basso a destra del riquadro, quanto è alta ogni riga e i margini.
@export var angolo_scelte := Vector2(624, 252)
@export var altezza_riga_scelte := 23.0
@export var margine_scelte := Vector2(28, 14)
## Quanto spazio resta fra il ritratto e il testo.
@export var spazio_dopo_ritratto := 10.0

## Vero mentre un dialogo o una scelta è aperta.
var busy := false
## Vero durante le dissolvenze tra scene.
var transitioning := false
## Vero durante le scene scriptate (finali): il giocatore non si muove.
var cutscene := false

@onready var _hud: Label = $Hud
@onready var _box: Panel = $Riquadro
@onready var _name: Label = $Riquadro/Nome
@onready var _text: Label = $Riquadro/Testo
@onready var _choice_box: Panel = $Scelte
@onready var _choice_label: Label = $Scelte/Righe
@onready var _fade: ColorRect = $Buio
@onready var _narr: Label = $Narrazione
@onready var _time_bar: Label = $TurnoDiOggi
@onready var _portrait: TextureRect = $Riquadro/Ritratto
@onready var _portrait_tex: AtlasTexture = _portrait.texture as AtlasTexture
## Dove stanno nome e testo senza ritratto (presi dalla scena).
@onready var _text_x := _text.position.x
@onready var _text_w := _text.size.x
@onready var _name_x := _name.position.x
## Il fotogramma del ritratto a bocca chiusa (la regione dell'AtlasTexture nella scena).
@onready var _portrait_x := _portrait_tex.region.position.x
var _talk_t := 0.0
## Ritratti extra per chi non è in npcs.json.
const EXTRA_PORTRAITS := {
	"Dottor Prezzi": "char_18", "Il Presidente": "char_19", "Papà": "char_19",
	"Signora Agenda": "char_20", "Il capo": "char_18", "Signor Tasso": "char_04", "Fermo": "cheap_fermo", "Signor Rata": "char_18", "Addetta ai badge": "char_13",
}

var _mode := ""
var _label: Label
var _typed := 0.0
var _typing := false
var _options: Array = []
var _sel := 0
var _pitch := 1.0
var _last_blip := 0


func _ready() -> void:
	GameState.changed.connect(_refresh_hud)
	_refresh_hud()
	show_hud(false)


func blocks_input() -> bool:
	return busy or transitioning or cutscene


func show_hud(visible_: bool) -> void:
	_hud.visible = visible_
	if _time_bar:
		_time_bar.visible = visible_


## Sotto all'HUD: il turno di oggi è da fare o è fatto (e come far passare la notte).
func _update_time_bar() -> void:
	# alla Cima non c'è un lavoro pagato: c'è il TURNO di Direzione, tre cicli alla scrivania della Presidente
	if GameState.floor_id == "cima" and GameState.flags.has("chapter_6"):
		var dt: Dictionary = (GameState.flags["chapter_6"] as Dictionary).get("director_turn", {})
		var done := 0
		for i in range(1, 4):
			if dt.get("cycle_%d_completed" % i, false):
				done += 1
		_time_bar.text = "TURNO di Direzione: %d cicli su 3 (la scrivania della Presidente)." % done if done < 3 else "TURNO di Direzione: fatto. Resta da decidere."
		_time_bar.add_theme_color_override("font_color", colore_turno_cima)
	elif GameState.worked_today:
		_time_bar.text = "Turno di oggi: fatto. Per il prossimo, fai passare la notte a una stellina."
		_time_bar.add_theme_color_override("font_color", colore_turno_fatto)
	else:
		_time_bar.text = "Turno di oggi: da fare (cerca la scritta TURNO)."
		_time_bar.add_theme_color_override("font_color", colore_turno_da_fare)


func _refresh_hud() -> void:
	_hud.text = "%s  %s  LV %d  Debito %s  Soldi %s  Energia %d/%d  Autostima %d" % [
		GameState.floor_name(), GameState.clock(), GameState.lv(),
		GameState.euros_short(GameState.debt), GameState.euros(GameState.money),
		GameState.energy, GameState.MAX_ENERGY, GameState.self_esteem,
	]
	_update_time_bar()


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
	_portrait.material = materiale_capo if speaker == "Il capo" else null
	if has:
		_portrait_tex.atlas = Assets.tex("characters/%s.png" % sheet, Vector2i(896, 656))
		_portrait_tex.region.position.x = _portrait_x
	# con il ritratto, nome e testo si spostano a destra del ritratto
	var shift := (_portrait.position.x + _portrait.size.x + spazio_dopo_ritratto - _text_x) if has else 0.0
	_name.position.x = _name_x + shift
	_text.position.x = _text_x + shift
	_text.size.x = _text_w - shift


func say(lines: Array, speaker: String = "", portrait: String = "") -> void:
	busy = true
	_box.visible = true
	_name.text = speaker
	_name.visible = speaker != ""
	_show_portrait(speaker, portrait)
	_pitch = 1.0 if speaker == "" else 0.75 + float(absi(speaker.hash()) % 50) / 100.0
	for line: Variant in lines:
		# una frase troppo lunga per il riquadro diventa più pagine
		for page in _pages(GameState.fmt(str(line))):
			await _type(_text, page)
	_box.visible = false
	busy = false


## Divide il testo in pezzi che stanno dentro il riquadro (a parole intere).
func _pages(text: String) -> Array[String]:
	# si misura sul riquadro vero (che scrive in maiuscolo): quante righe ci stanno
	var line_h := _text.get_line_height() + _text.get_theme_constant("line_spacing")
	var max_lines := maxi(1, int((_text.size.y + 2.0) / line_h))
	var fits := func(t: String) -> bool:
		_text.text = t
		return _text.get_line_count() <= max_lines
	var out: Array[String] = []
	if fits.call(text):
		out.append(text)
		return out
	var cur := ""
	for w in text.split(" "):
		var next := w if cur == "" else cur + " " + w
		if cur != "" and not fits.call(next):
			out.append(cur)
			cur = w
		else:
			cur = next
	if cur != "":
		out.append(cur)
	return out


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
	options.append("Impostazioni")
	options.append("Chiudi")
	var prompt := "{rank}. {floor}, ore {clock}. Badge: %d. Energia %d/%d." % [
		GameState.badges.size(), GameState.energy, GameState.MAX_ENERGY]
	var missions := Quests.active_titles()
	if not missions.is_empty():
		prompt += "
Missioni: " + ", ".join(missions) + "."
	if GameState.items.is_empty():
		prompt += "
Non hai oggetti."
	var i: int = await choose(prompt, options, "Stato")
	if i == GameState.items.size():
		await settings_menu()
		return
	if i < GameState.items.size():
		Sound.sfx("heal")
		await say(GameState.use_item(i).split("
"))


## Le pagine che si aprono sopra a tutto: i comandi (tasti disegnati) e i crediti.
const COMANDI := preload("res://scenes/comandi.tscn")
## La stessa pagina per chi gioca col dito: il joystick e i pulsanti OK, X, C.
const COMANDI_TELEFONO := preload("res://scenes/comandi_telefono.tscn")
const CREDITI := preload("res://scenes/crediti.tscn")
## La voce delle Impostazioni (solo dalla schermata iniziale) per cancellare la memoria di Nives.
const FORGET := "Dimentica le partite"


## Le impostazioni: il volume di musica ed effetti (ogni scelta abbassa di un gradino, dopo lo zero si
## ricomincia dal massimo). Lo schermo intero non è nel menu: sul computer resta il tasto F11.
## Dalla schermata iniziale (from_title) anche "Dimentica le partite", se Nives si ricorda qualcosa.
func settings_menu(from_title := false) -> void:
	while true:
		var m := Sound.volume("Music")
		var s := Sound.volume("SFX")
		var options: Array[String] = ["Musica: %s" % _vol_text(m), "Effetti: %s" % _vol_text(s)]
		if from_title and MemoriaNives.count() > 0:
			options.append(FORGET)
		options.append("Fatto")
		var c: int = await choose("Impostazioni (scegli per cambiare)", options, "Impostazioni")
		var picked := options[c]
		if c == 0:
			Sound.set_volume("Music", _next_vol(m))
		elif c == 1:
			Sound.set_volume("SFX", _next_vol(s))
			Sound.sfx("coin")
		elif picked == FORGET:
			await MemoriaNives.forget_dialog()
		else:
			return


## Apre una pagina (COMANDI, CREDITI) e aspetta che si chiuda.
func show_page(scene: PackedScene) -> void:
	var page := scene.instantiate()
	add_child(page)
	busy = true
	await page.chiuso
	page.queue_free()
	busy = false


func _next_vol(v: float) -> float:
	return 1.0 if v <= 0.01 else maxf(0.0, snappedf(v - 0.2, 0.2))


func _vol_text(v: float) -> String:
	var n := int(round(v * 5.0))
	return "[" + "#".repeat(n) + "-".repeat(5 - n) + "] %d%%" % int(round(v * 100.0))


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
		w = maxf(w, font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x)
	_choice_box.size = Vector2(w + margine_scelte.x, _options.size() * altezza_riga_scelte + margine_scelte.y)
	_choice_box.position = angolo_scelte - _choice_box.size


func _process(delta: float) -> void:
	if not _typing or _label == null:
		return
	_typed += delta * velocita_scrittura
	_label.visible_characters = int(_typed)
	if _portrait.visible and _label == _text:
		_talk_t += delta
		# "bocca" che si muove: alterna due fotogrammi mentre il testo scorre
		_portrait_tex.region.position.x = _portrait_x + (int(_talk_t * 8.0) % 2) * 32
	if int(_typed) - _last_blip >= 2:
		_last_blip = int(_typed)
		var ch := _label.text.substr(clampi(_last_blip - 1, 0, _label.text.length() - 1), 1)
		if ch != " " and ch != "*":
			Sound.blip(_pitch)
	if int(_typed) >= _label.get_total_character_count():
		_label.visible_characters = -1
		_typing = false
		_portrait_tex.region.position.x = _portrait_x


## Tocchi sullo schermo: un tocco sul dialogo lo fa avanzare, un tocco su una scelta la seleziona.
func _touch(event: InputEventScreenTouch) -> bool:
	if not event.pressed:
		return false
	if _mode == "say":
		if _typing:
			_typing = false
			_label.visible_characters = -1
			Sound.stop_blip()
		else:
			_advance.emit()
		return true
	if _mode == "choose":
		var r := Rect2(_choice_box.position, _choice_box.size)
		if r.has_point(event.position):
			var i := clampi(int((event.position.y - r.position.y - _choice_label.position.y) / altezza_riga_scelte), 0, _options.size() - 1)
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
				Sound.stop_blip()
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
