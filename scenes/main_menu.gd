extends Control
## Schermata del titolo (scenes/main_menu.tscn): Titolo, Sottotitolo, Voci (il menu), Persone, Crediti,
## e SceltaNome (Velo, Domanda, Campo, Ok, Risposta), nascosta finché non scegli "Nuova partita".

const INTRO := [
	"Tuo padre se n'è andato in silenzio, come faceva tutto.",
	"Ti ha lasciato una casa vuota e un debito di {debt}.",
	"La lettera della banca diceva solo:\n\"Si presenti alla Torre CHEAP. Piano -5.\"",
]

## Dopo tre nomi vuoti, quanti secondi resta la risposta prima di chiamarti "Tu".
@export var attesa_nome_vuoto := 2.2

var _options: Array[String] = []
var _sel := 0
@onready var _list: Label = $Voci
var _locked := false


func _ready() -> void:
	Ui.show_hud(false)
	Ui.cutscene = false
	# Le persone del quartiere: le stesse che il giocatore incontrerà (ognuna a un passo diverso).
	var people := $Persone.get_children()
	for i in people.size():
		(people[i] as AnimatedSprite2D).frame = i % 6

	if GameState.has_save():
		_options.assign(["Continua", "Nuova partita", "Audio", "Esci"])
	else:
		_options.assign(["Nuova partita", "Audio", "Esci"])
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
				await get_tree().create_timer(attesa_nome_vuoto).timeout
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
	screen.visible = false
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
	# le persone che incontrerai: la torre le conosce tutte (e non ne parla benissimo)
	"nico": "Come quello del caffè nella tazza gigante? Almeno lui una tazza ce l'ha.",
	"marta": "Come la vicina del secondo piano? Anche lei ha una bolletta col tuo nome sopra.",
	"bruno": "Come il signore della panchina? Guardare la gente passare: un lavoro che la CHEAP non ha ancora tolto.",
	"signor bruno": "Signor Bruno. La panchina è già sua. Tu cercatene un'altra.",
	"lea": "Come la studentessa con tre lavori? Ti mancano solo due lavori per raggiungerla.",
	"sami": "Come il rider? Hai dodici minuti per scegliere un nome. Ne sono già passati undici.",
	"ivo": "Come il portiere? Anche lui abita in uno sgabuzzino. Non dirlo all'amministratore.",
	"dario": "Come quello con quindici anni d'ufficio? Tre figli, zero ferie. Benvenuto nel club.",
	"giulia": "Come la collega gentile del terminale? Lei almeno sa come funziona. Tu no.",
	"tano": "Come il musicista del parco? Il marciapiede è grande, c'è posto per un altro senza orchestra.",
	"elsa": "Come la signora dei gatti? I gatti hanno nomi di ministri. Il tuo nome, per ora, non conta.",
	"signora elsa": "Signora Elsa. Sette gatti, sette ministri. Nessuno di loro ti aiuterà col debito.",
	"rocco": "Come quello sostituito da un robot con la sua faccia? Tieni d'occhio la tua, di faccia.",
	"gino": "Come quello dei bagni? Il trucco è fischiettare. Comincia a esercitarti.",
	"vito": "Come il fruttivendolo in affitto dentro il suo banco? Anche tu, presto, sarai in affitto dentro te stesso.",
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
