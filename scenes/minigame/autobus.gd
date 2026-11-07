extends Control
## Il TURNO della Città: autista della linea 12 (scenes/minigame/autobus.tscn, dentro work.gd).
## La strada scorre verso sinistra. Cambi corsia per schivare buche, auto in doppia fila, lavori e sacchi;
## tieni premuto per andare più veloce. Alle fermate devi essere nella corsia in alto (quella del
## marciapiede) e andare piano: l'autobus si ferma da solo sul segno giallo.
## Sbattere non ti fa perdere: ti fa perdere tempo. Le stelline (la paga) dipendono da quante fermate
## fai bene e da quanto sei in orario.
## Tutto quello che si vede è un nodo della scena: corsie, strisce, modelli degli ostacoli, la fermata.
## La radice taglia quello che esce dal riquadro (clip_contents): gli ostacoli entrano da destra.

## Velocità normale e velocità tenendo premuto (pixel al secondo).
@export var velocita := 80.0
@export var velocita_veloce := 150.0
## Quanta strada c'è da una fermata all'altra.
@export var distanza_fermate := 520.0
## Secondi fermo dopo un urto, e alla fermata (la gente sale).
@export var perdita_urto := 1.6
@export var sosta_fermata := 1.1
## Ogni quanta strada arriva un ostacolo (minimo e massimo).
@export var ostacoli_ogni := Vector2(95.0, 170.0)
## Prima e dopo il segno della fermata, nella corsia del marciapiede non si mettono ostacoli.
@export var libero_prima_fermata := 70.0
@export var libero_dopo_fermata := 40.0
## Quanto sono "larghi" l'autobus e gli ostacoli per gli urti (in orizzontale).
@export var mezza_lunghezza_bus := 30.0
@export var mezza_lunghezza_ostacolo := 14.0
## Secondi per cambiare corsia.
@export var tempo_corsia := 0.12

## Il turno (work.gd): qui si aggiungono i punti e si legge il tempo che resta.
var work: Node = null
var fermate := 5
var corsia := 1
var veloce := false
var fermo_t := 0.0
var percorso := 0.0
var prossimo_ostacolo := 220.0
var fatte := 0
var brusche := 0
var saltate := 0
var urti := 0
var finito := false
var _corsie: Array[float] = []
var _fermate_x: Array[float] = []
var _dito_veloce := false
var _shake := 0.0
var _esito_t := 0.0
var _bus_base := Vector2.ZERO


func _ready() -> void:
	for m in $Corsie.get_children():
		_corsie.append((m as Node2D).position.y)
	_bus_base = $Bus.position
	$Modelli.visible = false
	$Fermata.visible = false
	$Esito.text = ""
	$Veloce.visible = false
	# la striscia per il dito c'è solo sul telefono
	$Pedale.visible = TouchControls.enabled
	_metti_corsia(1, false)


## Comincia il turno: quante fermate (il turno breve ne ha meno).
func avvia(w: Node, quante: int) -> void:
	work = w
	fermate = quante
	for i in fermate:
		_fermate_x.append(distanza_fermate * (i + 1))
	_prossima_fermata()


func _process(delta: float) -> void:
	if work == null or finito or str(work.get("phase")) != "play":
		return
	_shake = maxf(0.0, _shake - delta * 3.0)
	_esito_t -= delta
	if _esito_t <= 0.0:
		$Esito.text = ""
	veloce = _dito_veloce or Input.is_action_pressed("confirm") or Input.is_action_pressed("move_right")
	$Veloce.visible = veloce and fermo_t <= 0.0
	var v := 0.0
	if fermo_t > 0.0:
		fermo_t -= delta
	else:
		v = velocita_veloce if veloce else velocita
	percorso += v * delta
	_scorri(v * delta)
	_genera()
	_controlla_urti()
	_controlla_fermata()
	$Bus.position = Vector2(_bus_base.x, _bus_y) + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 3.0 * _shake
	_aggiorna_info()


# --- la strada che scorre ---------------------------------------------------------------------

func _scorri(dx: float) -> void:
	var largo: float = $Strada.size.x
	for s in $Strisce.get_children():
		var n := s as Control
		n.position.x -= dx
		if n.position.x < -n.size.x:
			n.position.x += largo + n.size.x * 2.0
	for o in $Ostacoli.get_children():
		(o as Node2D).position.x -= dx
		if (o as Node2D).position.x < -60.0:
			o.queue_free()
	if $Fermata.visible:
		$Fermata.position.x -= dx


## Gli ostacoli arrivano da destra: mai tutte le corsie chiuse, mai davanti a una fermata.
func _genera() -> void:
	if percorso + $Strada.size.x < prossimo_ostacolo:
		return
	var at := prossimo_ostacolo
	prossimo_ostacolo += randf_range(ostacoli_ogni.x, ostacoli_ogni.y)
	if at >= _fine():
		return
	var lanes := [0, 1, 2]
	for fx in _fermate_x:
		if at > fx - libero_prima_fermata and at < fx + libero_dopo_fermata:
			lanes.erase(0)
	var lane: int = lanes.pick_random()
	var modelli := $Modelli.get_children()
	var o := (modelli.pick_random() as Node2D).duplicate() as Node2D
	o.visible = true
	o.position = Vector2(at - percorso + $Bus.position.x, _corsie[lane])
	o.set_meta("corsia", lane)
	$Ostacoli.add_child(o)


func _fine() -> float:
	return _fermate_x[_fermate_x.size() - 1] if not _fermate_x.is_empty() else 0.0


func _controlla_urti() -> void:
	if fermo_t > 0.0:
		return
	for o in $Ostacoli.get_children():
		if o.get_meta("colpito", false) or int(o.get_meta("corsia", -1)) != corsia:
			continue
		if absf((o as Node2D).position.x - $Bus.position.x) < mezza_lunghezza_bus + mezza_lunghezza_ostacolo:
			o.set_meta("colpito", true)
			(o as Node2D).modulate = Color(1, 1, 1, 0.35)
			urti += 1
			fermo_t = perdita_urto
			_shake = 1.0
			Sound.sfx("crash", 1.1, -4.0)
			_messaggio("BOTTA! %s." % str(o.get_meta("nome", "Ostacolo")), Color("ff5a5a"))


# --- le fermate -------------------------------------------------------------------------------

func _prossima_fermata() -> void:
	var i := fatte + brusche + saltate
	if i >= _fermate_x.size():
		$Fermata.visible = false
		return
	$Fermata.visible = true
	$Fermata.position.x = _fermate_x[i] - percorso + $Bus.position.x
	($Fermata.get_node("Numero") as Label).text = "FERMATA %d/%d" % [i + 1, fermate]


func _controlla_fermata() -> void:
	if not $Fermata.visible:
		return
	# il muso dell'autobus arriva al segno giallo
	if $Fermata.position.x > $Bus.position.x + mezza_lunghezza_bus:
		return
	if corsia != 0:
		saltate += 1
		Sound.sfx("deny")
		_messaggio("FERMATA SALTATA! Restano a terra.", Color("ff5a5a"))
	elif veloce:
		brusche += 1
		work.set("score", float(work.get("score")) + 0.6)
		fermo_t = sosta_fermata
		_shake = 0.6
		Sound.sfx("thump")
		_messaggio("Frenata brusca. Qualcuno cade.", Color("ffe14d"))
	else:
		fatte += 1
		work.set("score", float(work.get("score")) + 1.0)
		fermo_t = sosta_fermata
		Sound.sfx("ding")
		_messaggio("Fermata perfetta!", Color("3ddc84"))
	if fatte + brusche + saltate >= fermate:
		_arrivo()
	else:
		_prossima_fermata()


## Capolinea: il tempo che avanza vale come puntualità.
func _arrivo() -> void:
	finito = true
	$Fermata.visible = false
	var anticipo := maxf(0.0, float(work.get("time_left")))
	work.set("score", float(work.get("score")) + minf(anticipo / 8.0, float(work.get("target")) * 0.25))
	await get_tree().create_timer(sosta_fermata).timeout
	if str(work.get("phase")) == "play":
		work.call("_finish")


# --- comandi ----------------------------------------------------------------------------------

func cambia_corsia(d: int) -> void:
	if finito:
		return
	var n := clampi(corsia + d, 0, _corsie.size() - 1)
	if n != corsia:
		Sound.sfx("move")
		_metti_corsia(n, true)


var _bus_y := 0.0
var _tw: Tween
func _metti_corsia(n: int, anima: bool) -> void:
	corsia = n
	if _tw:
		_tw.kill()
	if not anima:
		_bus_y = _corsie[n]
		$Bus.position.y = _bus_y
		return
	_tw = create_tween()
	_tw.tween_property(self, "_bus_y", _corsie[n], tempo_corsia).set_trans(Tween.TRANS_SINE)


func input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).echo:
		return
	if event.is_action_pressed("move_up"):
		cambia_corsia(-1)
	elif event.is_action_pressed("move_down"):
		cambia_corsia(1)


## Col dito: la striscia a destra tiene premuto l'acceleratore; sopra o sotto l'autobus cambia corsia.
func touch_point(pos: Vector2, step: int) -> void:
	var local := pos - global_position
	if step == 0:
		if local.x > ($Pedale as Control).position.x:
			_dito_veloce = true
		else:
			cambia_corsia(-1 if local.y < $Bus.position.y else 1)
	elif step == 2:
		_dito_veloce = false


func _messaggio(t: String, c: Color) -> void:
	$Esito.text = t
	$Esito.add_theme_color_override("font_color", c)
	_esito_t = 1.4


func _aggiorna_info() -> void:
	var info := work.get("_info") as Label
	if info:
		info.text = "Orario %d   Fermate %d/%d   Urti %d" % [int(ceil(maxf(0.0, float(work.get("time_left"))))), fatte + brusche, fermate, urti]
