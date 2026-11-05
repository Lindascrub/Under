extends Node2D
## L'inizio: sei dentro l'ascensore della Torre CHEAP e scendi. -1, -2, -3, -4...
## Sul display c'è il tuo debito. Al -5 l'ascensore si blocca, la luce salta,
## le porte si aprono a metà sulle luci del Fondo.
## La scena è fatta di nodi (scenes/world/elevator_intro.tscn): cabina, pareti, display, pulsantiera,
## porte e giocatore si spostano nell'editor. Qui c'è solo la sequenza.

@onready var _cabin: Node2D = $Cabina
@onready var _display: Node2D = $Cabina/Display
@onready var _number: Label = $Cabina/Display/Numero
@onready var _buttons: Node = $Cabina/Pulsantiera
@onready var _door_l: ColorRect = $Cabina/Porte/PortaSinistra
@onready var _door_r: ColorRect = $Cabina/Porte/PortaDestra
@onready var _glow: ColorRect = $Cabina/RiflessoLuce
@onready var _dark: ColorRect = $Buio
@onready var _player: AnimatedSprite2D = $Giocatore
@onready var _exit: Marker2D = $Uscita

var _floor_text := "0":
	set(v):
		_floor_text = v
		if is_node_ready():
			_number.text = v
			_light_buttons()
var _light := 1.0
var _shake := 0.0
## Quanto sono aperte le porte (0 chiuse, 1 tutte aperte): le due ante si stringono verso i lati.
var _doors := 0.0:
	set(v):
		_doors = v
		if is_node_ready():
			var w := _door_w * (1.0 - v)
			_door_l.size.x = w
			_door_r.size.x = w
			_door_r.position.x = _door_end - w
## Le porte come le hai messe nell'editor: larghezza di un'anta e bordo destro.
var _door_w := 96.0
var _door_end := 192.0
var _display_on := true:
	set(v):
		_display_on = v
		if is_node_ready():
			_number.visible = v
			_light_buttons()
var _sparks: Array[ColorRect] = []
var _t := 0.0


func _ready() -> void:
	Sound.music("")
	Ui.show_hud(false)
	Ui.cutscene = true
	_cabin.visible = false
	_player.visible = false
	_player.play("idle_up")
	_number.text = _floor_text
	_door_w = _door_l.size.x
	_door_end = _door_r.position.x + _door_r.size.x
	if Ui.transitioning:
		await Ui.faded_in
	await _sequence()


func _sequence() -> void:
	await Ui.narrate([
		"La sveglia è suonata, come ogni mattina. Ti sei alzato dal lato sbagliato del letto. Ultimamente succedeva spesso.",
		"Sei sceso in cucina per fare colazione. Di fretta, naturalmente. Sembrava che il mondo intero avesse fretta, e tu cercavi di stargli dietro.",
		"Ma stavolta era tutto sottosopra.",
		"Hai chiamato tuo padre. Una volta, due, tre. Nessuna risposta.",
		"Sei andato a cercarlo in camera sua. Hai trovato soltanto un biglietto:",
		"«Mi dispiace.» Firmato: papà.",
		"Accanto, una lettera già aperta:",
		"«Si presenti alla CHEAP per saldare il suo debito.»",
		"Tuo padre se n’era andato. Tu eri rimasto senza una lira, con quella lettera in mano.",
		"TORRE CHEAP",
	])
	_cabin.visible = true
	_player.visible = true
	Sound.music("ascensore")
	await _wait(0.8)
	await Ui.say([
		"* Questo ascensore è diverso dagli altri.",
		"* C’è il solito odore di metallo, ma più forte. E sotto, qualcosa che conosci.",
		"* Lo stesso odore che riempiva casa quando tuo padre giocava. Non hai mai saputo dargli un nome. Tristezza, forse.",
		"* Anche la musica è diversa. Negli altri ascensori quelle musichette provavano almeno a tranquillizzarti.",
		"* Questa è lenta, triste. Ti mette addosso un’ansia che non sai spiegare.",
		"* Una voce registrata interrompe la musica. Acuta, contentissima. Cerca di sembrare umana. Si sente quanto si sta sforzando.",
	])
	await Ui.say(["Benvenuto alla CHEAP. Il futuro costa poco."], "Voce CHEAP")
	await Ui.say(["* Sul display scompare il numero del piano."])
	_floor_text = "7 MLD"
	await Ui.say(["Che vuol dire?"], GameState.player_name)
	await Ui.say(["Lavoratore riconosciuto.", "Debito registrato: sette miliardi di euro."], "Voce CHEAP")
	await Ui.say(["* La voce pronuncia la cifra con la stessa allegria del benvenuto."])
	await Ui.say(["Sette miliardi?"], GameState.player_name)
	await Ui.say(["* Una cifra così rotonda che sembra quasi uno scherzo.",
		"* Provi a contare gli zeri. Perdi il conto.",
		"* Che cosa aveva fatto tuo padre? Come aveva potuto lasciare un debito del genere?",
		"* L’ascensore continua a scendere."])
	for f in ["-1", "-2", "-3"]:
		await _wait(0.9)
		_floor_text = f
		Sound.sfx("ding", 0.9)
	await Ui.say(["* Uno scatto. Poi un altro. Le luci sfarfallano e ti aggrappi al corrimano.",
		"* Sta davvero cadendo a pezzi, o sei tu che hai cominciato a sentire ogni rumore?",
		"* Ti manca l’aria. Guardi la porta chiusa."])
	await _wait(0.5)
	_floor_text = "-4"
	Sound.sfx("ding", 0.8)
	for i in 6:
		_light = 0.35 if i % 2 == 0 else 0.9
		await _wait(0.08 + randf() * 0.12)
	_light = 0.85
	Sound.music_pitch(0.55, 0.9)
	await _wait(1.0)
	_floor_text = "-5"
	Sound.music("")
	Sound.sfx("clunk")
	_shake = 1.0
	_light = 0.0
	_player.play("idle_down")
	await _wait(0.9)
	_display_on = false
	await _wait(0.5)
	for i in 3:
		_display_on = true
		Sound.sfx("spark", 1.0 + i * 0.1)
		_add_sparks()
		await _wait(0.12)
		_display_on = false
		await _wait(0.35)
	_display_on = true
	_light = 0.12
	await Ui.say(["* L’ascensore si ferma di colpo.", "* Sul display lampeggia: −5.",
		"* Premi un pulsante. Poi tutti gli altri. Nessuno si illumina.",
		"* Premi quello per aprire le porte.", "* Niente.", "* Alla fine premi l’allarme.",
		"* Per un momento non succede nulla."])
	await _wait(0.6)
	Sound.sfx("door", 0.7)
	var tw := create_tween()
	tw.tween_property(self, "_doors", 0.45, 1.4).set_trans(Tween.TRANS_SINE)
	await tw.finished
	await _wait(0.4)
	await Ui.say(["* Poi uno stridio metallico. Le porte si aprono e si bloccano a metà.",
		"* La fessura è larga abbastanza per farti passare. Appena abbastanza.",
		"* Dall’altra parte arrivano luci fin troppo abbaglianti."])
	var walk := create_tween()
	walk.tween_property(_player, "position", _exit.position, 1.3)
	_player.play("walk_down")
	await walk.finished
	Ui.cutscene = false
	Router.goto(Router.FONDO, "elevator", ["CAPITOLO 1", "IL FONDO", "Piano −5."])


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


## Si accende il pulsante del piano in cui sei (Pulsante1 = -1 ... Pulsante5 = -5).
func _light_buttons() -> void:
	for k in 5:
		var b := _buttons.get_node_or_null("Pulsante%d" % (k + 1)) as ColorRect
		if b:
			b.color = Color("f2b23a") if _display_on and str(-(k + 1)) == _floor_text else Color("5a5666")


## Scintille dal display: quadratini che compaiono sotto lo schermo e spariscono.
func _add_sparks() -> void:
	var under := Vector2(_number.size.x / 2.0, _number.size.y + 2)
	for i in 6:
		var s := ColorRect.new()
		s.color = Color("ffe08a")
		s.size = Vector2(2, 2)
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.position = under + Vector2(randf_range(-10, 10), randf_range(-4, 4)) * 2.0
		_display.add_child(s)
		_sparks.append(s)


func _process(delta: float) -> void:
	_t += delta
	_shake = maxf(0.0, _shake - delta * 1.6)
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 6.0 * _shake
	if not _sparks.is_empty() and randf() < 0.3:
		_sparks.pop_front().queue_free()
	# la luce: la cabina si scurisce, il display (che ha la sua luce) no
	var v := 0.15 + 0.85 * _light
	_cabin.modulate = Color(v, v, v)
	_display.modulate = Color(1.0 / v, 1.0 / v, 1.0 / v)
	_glow.visible = _light > 0.05
	_glow.color.a = 0.15 * _light
	_dark.color.a = 0.55 * (1.0 - _light)
