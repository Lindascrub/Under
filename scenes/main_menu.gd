extends Control
## Schermata del titolo (scenes/main_menu.tscn): Titolo, Voci (il menu), Persone,
## e SceltaNome (Velo, Domanda, Campo, Ok, Risposta), nascosta finché non scegli "Nuova partita".

## Dopo tre nomi vuoti, quanti secondi resta la risposta prima di chiamarti "Tu".
@export var attesa_nome_vuoto := 2.2

var _options: Array[String] = []
var _sel := 0
@onready var _list: Label = $Voci
var _locked := false


func _ready() -> void:
	Ui.show_hud(false)
	Ui.cutscene = false
	Sound.music("titolo")
	# un vecchio salvataggio già finito: Nives se lo ricorda (una volta sola, vedi MemoriaNives)
	MemoriaNives.import_legacy()
	# Le persone del quartiere: le stesse che il giocatore incontrerà (ognuna a un passo diverso).
	var people := $Persone.get_children()
	for i in people.size():
		(people[i] as AnimatedSprite2D).frame = i % 6

	_fill_options()


func _fill_options() -> void:
	if GameState.has_save():
		_options.assign(["Continua", "Nuova partita", "Impostazioni", "Comandi", "Crediti", "Esci"])
	else:
		_options.assign(["Nuova partita", "Impostazioni", "Comandi", "Crediti", "Esci"])
	# sul telefono il gioco si chiude come tutte le app: "Esci" non serve
	if OS.has_feature("mobile"):
		_options.erase("Esci")
	_sel = mini(_sel, _options.size() - 1)
	_render()


## Prima di cominciare: come ti chiami? (Sul telefono si apre la tastiera.)
func _ask_name() -> String:
	var screen := $SceltaNome as Control
	var edit := $SceltaNome/Campo as LineEdit
	var ok := $SceltaNome/Ok as Button
	var reply := $SceltaNome/Risposta as Label
	screen.visible = true
	edit.grab_focus()
	# sotto, la torre risponde (come in Undertale: il nome non è mai solo un nome)
	var done := [false]
	edit.text_submitted.connect(func(_t: String) -> void: done[0] = true)
	ok.pressed.connect(func() -> void: done[0] = true)
	edit.text_changed.connect(func(t: String) -> void:
		ok.text = "Comincia"
		# solo lettere (anche accentate), spazi e apostrofi: numeri e simboli spariscono appena li scrivi
		# e la prima lettera sempre maiuscola, anche mentre scrivi
		var clean := GameState.capital(clean_name(t))
		if clean != t:
			var col := edit.caret_column - (t.length() - clean.length())
			edit.text = clean
			edit.caret_column = clampi(col, 0, clean.length())
			if clean.to_lower() != t.to_lower():
				reply.text = NO_DIGITS if _digits(t) > 0 else NO_SIGNS
				Sound.sfx("deny"))
	var empty := 0
	var rude := 0
	var pending := ""
	var who := ""
	while true:
		done[0] = false
		while not done[0]:
			await get_tree().process_frame
			if name_override != "":
				edit.text = name_override
				done[0] = true
		who = GameState.capital(edit.text.strip_edges())
		if name_override != "":
			break
		if who == "":
			if empty >= EMPTY_REPLIES.size():
				reply.text = "Va bene. Ti chiameremo \"Tu\". Come tutti quelli che non hanno tempo per un nome."
				Sound.sfx("deny", 0.7)
				await get_tree().create_timer(attesa_nome_vuoto).timeout
				who = "Tu"
				break
			reply.text = EMPTY_REPLIES[empty]
			empty += 1
			Sound.sfx("deny")
			edit.grab_focus()
			continue
		var key := who.to_lower()
		if is_rude(key):
			reply.text = RUDE_REPLIES[rude % RUDE_REPLIES.size()]
			rude += 1
			Sound.sfx("deny")
			edit.text = ""
			edit.grab_focus()
			pending = ""
			ok.text = "Comincia"
			continue
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
			reply.text = SPECIAL_NAMES[key] + ("\n(Tocca di nuovo per tenerlo.)" if TouchControls.enabled else "\n(Premi di nuovo INVIO per tenerlo.)")
			Sound.sfx("select")
			pending = key
			ok.text = "Sì, è questo"
			edit.grab_focus()
			continue
		break
	screen.visible = false
	return who


## Solo per i test: un nome già scritto.
var name_override := ""

## Quando scrivi un numero o un simbolo: sparisce, e la torre lo dice.
const NO_DIGITS := "Solo lettere. I numeri, qui, li scrive la banca."
const NO_SIGNS := "Niente simboli. Su un badge ci sta un nome, non una password."
## Le parolacce: la torre non le stampa, e ogni volta risponde un po' diversamente.
const RUDE_REPLIES: Array[String] = [
	"Questo sul badge non lo stampiamo. Gli interessi sì, ma questo no.",
	"La Torre ha sentito. Fa finta di no. Scrivi un nome.",
	"Le parolacce qui sono riservate a chi legge l'estratto conto.",
	"Il modulo arrossisce. Riprova con un nome da persona.",
]
## Pezzi di parola vietati ovunque nel nome (lettere attaccate, senza spazi né accenti).
const RUDE_PARTS: Array[String] = [
	"cazz", "merd", "stronz", "fancul", "vaffa", "puttan", "mignott", "zoccol", "coglion", "minchi",
	"bastard", "fottut", "fottit", "porcodio", "diocane", "dioporco", "porcamadonna", "ricchion",
	"culatton", "froci", "fuck", "shit", "bitch", "cunt", "nigg", "whore", "sborr",
]
## Parole vietate solo intere (dentro altri nomi sono innocue: "Pasculli", "Figari", "Troiani", "Negroni").
const RUDE_WORDS: Array[String] = ["culo", "figa", "fica", "pirla", "ass", "dick", "cock", "tette", "pene", "ano", "troia", "negro", "negra"]


## Toglie tutto quello che non è una lettera, uno spazio o un apostrofo.
static func clean_name(t: String) -> String:
	var out := ""
	for ch in t:
		if ch == " " or ch == "'" or ch == "’" or ch.to_upper() != ch.to_lower():
			out += ch
	return out


static func _digits(t: String) -> int:
	var n := 0
	for ch in t:
		if ch >= "0" and ch <= "9":
			n += 1
	return n


static func _plain(t: String) -> String:
	t = t.to_lower()
	for pair: Array in [["àáâä", "a"], ["èéêë", "e"], ["ìíîï", "i"], ["òóôö", "o"], ["ùúûü", "u"]]:
		for ch in str(pair[0]):
			t = t.replace(ch, str(pair[1]))
	return t


## Una parolaccia, anche scritta con spazi o apostrofi in mezzo.
static func is_rude(t: String) -> bool:
	var p := _plain(t).replace("’", "'")
	var glued := p.replace(" ", "").replace("'", "")
	for part in RUDE_PARTS:
		if part in glued:
			return true
	for w in p.replace("'", " ").split(" ", false):
		if w in RUDE_WORDS:
			return true
	return glued in RUDE_WORDS


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
	"mina": "Come l'elettricista del Fondo? Lei le lampadine di sopra le ha avvitate tutte. Tu, per ora, nessuna.",
	"bulbo": "Come il nonno delle lampadine? Lui almeno sa dove va ognuna. Tu dove vai?",
	"soldi": "Soldi. Finalmente qualcuno onesto.",
	"ricco": "Ottimismo. Ci piace. Il debito ti piacerà meno.",
	"robot": "Ci stai già pensando, eh? Ci arriverai.",
	"gratis": "Niente è gratis. Nemmeno il tuo nome. Ma per ora te lo lasciamo.",
	"frisk": "Questo nome ti porterà sfortuna. Ma qui non c'è bisogno di aiuto, ci pensa il mutuo.",
	"chara": "Il vero nome. Ma qui il vero nome è quello sul contratto.",
	"marx": "Hm. Il sistema prende nota.",
	"linda": "Bel nome, ma onestamente non te lo meriti.",
	# le persone che incontrerai: la torre le conosce tutte (e non ne parla benissimo)
	"tilde": "Come la signora del call center? Resti in linea, la sua chiamata è importante per noi.",
	"ercole": "Come il custode dell'archivio? Dodici fatiche. Lui ne fa tredici, e senza straordinari.",
	"rosa": "Come quella delle fragole di plastica? Profumano. Come le promesse della CHEAP.",
	"ottavio": "Come l'ottimista degli ombrelli? Qui sotto non piove. Ma un debito in testa ti cade lo stesso.",
	"ines": "Come l'impiegata dello sportello due? Sempre chiuso. Come il tuo conto, fra un po'.",
	"sandro": "Come la guardia giurata? Lui protegge i soldi. Chi protegge te non è previsto dal contratto.",
	"leda": "Come quella del negozietto del Mercato? Vent'euro al giorno. Contali due volte.",
	"amir": "Come quello delle consegne? Diciassette. Il numero preferito di nessuno.",
	"olga": "Come la signora delle ricevute? Ha una ricevuta per ogni cosa. Anche per questo nome.",
	"teo": "Come quello dello sportello della Banca? Quarantadue pratiche al giorno. Ne legge sei.",
	"ada": "Ada. Un nome che sta in piedi da solo. Come una libreria che pende. Lo terremo d'occhio.",
	"nadir": "Nadir: il punto più basso. Sei nel posto giusto: si parte da sotto il Fondo.",
	"rina": "Rina. Non toccare quella. E nemmeno questo modulo, finché non firmi.",
	"nives": "Come quella dello sportello dei badge? Sorride a tutti. Soprattutto a chi paga.",
	"agenda": "Agenda. Pagine bianche, tutte già prenotate. Da noi.",
	"signora agenda": "La Signora Agenda è allo sportello B-4. Per un nome uguale al suo serve il modulo B-4.",
	"rata": "Rata. Bel nome per un contratto. Il Signor Rata ne ha uno pronto per te.",
	"signor rata": "Il Signor Rata ti ringrazia. Gli interessi, da domani, avranno il tuo nome.",
	"tasso": "Tasso. Sale ogni notte, mentre dormi. Chiedi al Signor Tasso.",
	"signor tasso": "Il Signor Tasso gioca a ping pong con le monete. Le tue, di solito.",
}


func _render() -> void:
	var lines: Array[String] = []
	for i in _options.size():
		lines.append(("> %s <" if i == _sel else "%s") % _options[i])
	_list.text = "\n".join(lines)


## Sul telefono il dito non arriva da solo ai pulsanti (il tocco non fa da mouse, vedi project.godot):
## nella scelta del nome, toccare Ok lo preme e toccare il campo riapre la tastiera.
func _input(event: InputEvent) -> void:
	var screen := $SceltaNome as Control
	if not screen.visible or not (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed):
		return
	var at := (event as InputEventScreenTouch).position
	var ok := $SceltaNome/Ok as Button
	var edit := $SceltaNome/Campo as LineEdit
	if ok.get_global_rect().has_point(at):
		get_viewport().set_input_as_handled()
		ok.pressed.emit()
	elif edit.get_global_rect().has_point(at):
		get_viewport().set_input_as_handled()
		edit.grab_focus()
		DisplayServer.virtual_keyboard_show(edit.text)


func _unhandled_input(event: InputEvent) -> void:
	if _locked or Ui.blocks_input():
		return
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		var y := (event as InputEventScreenTouch).position.y - _list.position.y
		var i := int(y / (_list.get_line_height() + 1))
		if y >= 0 and i < _options.size():
			_sel = i
			_render()
			Sound.sfx("select")
			_choose(_options[_sel])
		return
	# gli stessi suoni delle scelte nei dialoghi
	if event.is_action_pressed("move_up"):
		_sel = posmod(_sel - 1, _options.size())
		Sound.sfx("move")
		_render()
	elif event.is_action_pressed("move_down"):
		_sel = posmod(_sel + 1, _options.size())
		Sound.sfx("move")
		_render()
	elif event.is_action_pressed("confirm"):
		Sound.sfx("select")
		_choose(_options[_sel])


func _choose(option: String) -> void:
	_locked = true
	match option:
		"Nuova partita":
			var who := await _ask_name()
			GameState.new_game()
			# una partita nuova ha un numero nuovo: la memoria di Nives resta, e sa che questa è un'altra
			GameState.flags["run_id"] = MemoriaNives.new_run_id()
			GameState.player_name = who
			GameState.delete_save()
			Router.goto(Router.ELEVATOR)
		"Impostazioni":
			# dalla schermata iniziale c'è anche "Dimentica le partite" (se Nives si ricorda qualcosa)
			await Ui.settings_menu(true)
			_locked = false
		"Comandi":
			await Ui.show_page(Ui.COMANDI_TELEFONO if TouchControls.enabled else Ui.COMANDI)
			_locked = false
		"Crediti":
			await Ui.show_page(Ui.CREDITI)
			_locked = false
		"Continua":
			Router.continue_game()
		"Esci":
			get_tree().quit()
