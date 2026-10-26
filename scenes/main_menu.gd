extends Control
## Schermata del titolo.

const INTRO := [
	"Tuo padre se n'è andato in silenzio, come faceva tutto.",
	"Ti ha lasciato una casa vuota e un debito di {debt}.",
	"La lettera della banca diceva solo:\n\"Si presenti alla Torre CHEAP. Piano -5.\"",
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
		_options.assign(["Continua", "Nuova partita", "Audio", "Esci"])
	else:
		_options.assign(["Nuova partita", "Audio", "Esci"])
	_render()


## Prima di cominciare: come ti chiami? (Sul telefono si apre la tastiera.)
func _ask_name() -> String:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.96)
	shade.size = Vector2(640, 360)
	add_child(shade)
	var q := _label("Come ti chiami?", 22, Color.WHITE)
	q.position = Vector2(0, 110)
	var edit := LineEdit.new()
	edit.max_length = 12
	edit.placeholder_text = "il tuo nome"
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.add_theme_font_size_override("font_size", 20)
	edit.position = Vector2(220, 150)
	edit.size = Vector2(200, 36)
	add_child(edit)
	var ok := Button.new()
	ok.text = "Comincia"
	ok.add_theme_font_size_override("font_size", 18)
	ok.position = Vector2(260, 200)
	ok.size = Vector2(120, 34)
	add_child(ok)
	edit.grab_focus()
	# sotto, la torre risponde (come in Undertale: il nome non è mai solo un nome)
	var reply := _label("", 14, Color("c8c0d0"))
	reply.position = Vector2(20, 246)
	reply.size = Vector2(600, 60)
	reply.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var done := [false]
	edit.text_submitted.connect(func(_t: String) -> void: done[0] = true)
	ok.pressed.connect(func() -> void: done[0] = true)
	edit.text_changed.connect(func(_t: String) -> void: ok.text = "Comincia")
	var empty := 0
	var pending := ""
	var who := ""
	while true:
		done[0] = false
		while not done[0]:
			await get_tree().process_frame
			if name_override != "":
				edit.text = name_override
				done[0] = true
		who = edit.text.strip_edges()
		if name_override != "":
			break
		if who == "":
			if empty >= EMPTY_REPLIES.size():
				reply.text = "Va bene. Ti chiameremo \"Tu\". Come tutti quelli che non hanno tempo per un nome."
				Sound.sfx("deny", 0.7)
				await get_tree().create_timer(2.2).timeout
				who = "Tu"
				break
			reply.text = EMPTY_REPLIES[empty]
			empty += 1
			Sound.sfx("deny")
			edit.grab_focus()
			continue
		var key := who.to_lower()
		if BLOCKED_NAMES.has(key):
			reply.text = BLOCKED_NAMES[key]
			Sound.sfx("deny")
			edit.text = ""
			edit.grab_focus()
			pending = ""
			ok.text = "Comincia"
			continue
		if SPECIAL_NAMES.has(key) and pending != key:
			# un commento, e la seconda volta vale come un sì
			reply.text = SPECIAL_NAMES[key] + "\n(Tocca di nuovo per tenerlo.)"
			Sound.sfx("select")
			pending = key
			ok.text = "Sì, è questo"
			edit.grab_focus()
			continue
		break
	for n in [shade, q, edit, ok, reply]:
		n.queue_free()
	return who


## Solo per i test: un nome già scritto.
var name_override := ""

## Se non scrivi niente: la torre te lo fa notare, ogni volta un po' più stanca.
const EMPTY_REPLIES: Array[String] = [
	"Niente? Anche il silenzio è un nome. Ma non si può stampare su un badge.",
	"La CHEAP ha bisogno di un nome. Per il contratto. E per la lapide.",
	"Ah, sei uno di quelli che non leggono le istruzioni. Ottimo. Diventerai un ottimo dipendente.",
	"Il modulo è vuoto. Il debito, invece, è già compilato.",
]
## Nomi che la torre non ti lascia prendere.
const BLOCKED_NAMES := {
	"fermo": "Quel nome è già preso. Da undici anni. Seduto su una cassetta.",
	"presidente": "Ti piacerebbe.",
	"il presidente": "Ti piacerebbe.",
	"capo": "No. Il capo c'è già. Il capo c'è sempre.",
	"cheap": "La CHEAP è un marchio registrato. Tu no.",
	"debito": "Questo nome è già occupato. Da te.",
	"sans": "No.",
}
## Nomi che fanno dire qualcosa alla torre (poi puoi tenerli).
const SPECIAL_NAMES := {
	"tu": "Tu. Comodo: così non dobbiamo ricordarci di te.",
	"io": "Io. Anche il Presidente comincia così ogni frase.",
	"nessuno": "Nessuno. Come Ulisse. Peccato che qui il Ciclope sia una banca.",
	"mina": "Come l'elettricista del Fondo? Lui le lampadine di sopra le ha avvitate tutte. Tu, per ora, nessuna.",
	"bulbo": "Come la bambina delle lampadine? Lei almeno sa dove va ognuna. Tu dove vai?",
	"soldi": "Soldi. Finalmente qualcuno onesto.",
	"ricco": "Ottimismo. Ci piace. Il debito ti piacerà meno.",
	"robot": "Ci stai già pensando, eh? Ci arriverai.",
	"gratis": "Niente è gratis. Nemmeno il tuo nome. Ma per ora te lo lasciamo.",
	"frisk": "Questo nome ti porterà sfortuna. Ma qui non c'è bisogno di aiuto, ci pensa il mutuo.",
	"chara": "Il vero nome. Ma qui il vero nome è quello sul contratto.",
	"marx": "Hm. Il sistema prende nota.",
	"linda": "Bel nome. Lo stamperemo piccolo piccolo, in fondo al contratto.",
}


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
			var who := await _ask_name()
			GameState.new_game()
			GameState.player_name = who
			GameState.delete_save()
			Router.goto(Router.ELEVATOR, "", INTRO)
		"Audio":
			await Ui.audio_menu()
			_locked = false
		"Continua":
			Router.continue_game()
		"Esci":
			get_tree().quit()
