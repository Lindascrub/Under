extends "res://scenes/minigame/rifatti/base.gd"
## IL NASTRO DEGLI ADDEBITI (Olga): le ricevute di giugno passano sul nastro, da destra a sinistra,
## sempre un po' più veloci. Se una ricevuta è uguale a quella appena prima (stessa voce, stesso
## importo) è un addebito doppio: si timbra (clic o dito) prima che finisca nell'archivio.
## Timbrare una voce giusta è un errore; lasciar scappare un doppio pure.
## Le ricevute sono in data/bank.json (olga → nastro); quella con "prova" è la commissione doppia
## della rata 63: se scappa, la prova è persa e si perde.
## Le stelline (in minigame.gd, nodo Risposta): 0 errori 3, un errore 2, di più 1.

## Velocità del nastro all'inizio e alla fine (pixel al secondo).
@export var velocita_iniziale := 70.0
@export var velocita_finale := 125.0
## Spazio fra una ricevuta e la successiva.
@export var distanza := 172.0
## Con questi errori si perde subito.
@export var errori_max := 4
const RICEVUTA := preload("res://scenes/minigame/rifatti/ricevuta.tscn")
var voci: Array = []
var prossima := 0
var ricevute: Array[Control] = []
var ultima: Control = null
var timbrati := 0
var doppi := 0
var prova_trovata := false


func avvia(c: Dictionary) -> void:
	super.avvia(c)
	voci = GameState.bank.get("olga", {}).get("nastro", [])
	for i in voci.size():
		if _doppia(i): doppi += 1
	$Aiuto.text = "Tocca la ricevuta doppia prima che esca dal nastro." if TouchControls.enabled else "Clicca la ricevuta doppia prima che esca dal nastro."
	_aggiorna()


## È uguale (voce e importo) a quella appena prima?
func _doppia(i: int) -> bool:
	return i > 0 and str(voci[i][1]) == str(voci[i - 1][1]) and int(voci[i][2]) == int(voci[i - 1][2])


func velocita() -> float:
	var fatto := float(prossima) / maxf(1.0, float(voci.size()))
	return lerpf(velocita_iniziale, velocita_finale, sqrt(fatto))


func _process(dt: float) -> void:
	if not attivo or Ui.busy or voci.is_empty(): return
	var v := velocita()
	# i rulli girano: si vede che il nastro corre
	for r: Control in $Nastro/Rulli.get_children():
		r.position.x = fposmod(r.position.x - v * dt, 680.0) - 20.0
	if prossima < voci.size() and (ultima == null or ultima.position.x <= $Entrata.position.x - distanza):
		crea_ricevuta()
	for r in ricevute.duplicate():
		r.position.x -= v * dt
		if r.position.x < $Uscita.position.x:
			ricevute.erase(r)
			if r.get_meta("doppia") and not r.get_meta("timbrata"):
				_scappata(r)
			r.queue_free()
			if not attivo: return
	if prossima >= voci.size() and ricevute.is_empty():
		chiudi(prova_trovata)


func crea_ricevuta() -> Control:
	var i := prossima
	var r: Control = RICEVUTA.instantiate()
	$Ricevute.add_child(r)
	r.position = $Entrata.position
	r.get_node("Data").text = str(voci[i][0])
	r.get_node("Voce").text = str(voci[i][1])
	var euro := int(voci[i][2])
	r.get_node("Importo").text = ("+%d €" if euro > 0 else "%d €") % euro
	r.set_meta("doppia", _doppia(i))
	r.set_meta("prova", (voci[i] as Array).size() > 3 and str(voci[i][3]) == "prova")
	r.set_meta("timbrata", false)
	ricevute.append(r)
	ultima = r
	prossima += 1
	return r


func _aggiorna() -> void:
	$Stato.text = "Doppi timbrati: %d/%d · Errori %d/%d" % [timbrati, doppi, errori, errori_max]


func timbra(r: Control) -> void:
	if not attivo or r == null or r.get_meta("timbrata"): return
	if not r.get_meta("doppia"):
		errori += 1
		$Esito.text = "Questa voce è una sola. Timbra solo quella uguale alla precedente."
		Sound.sfx("deny")
		var tw := create_tween()
		r.modulate = Color(1, 0.6, 0.6)
		tw.tween_property(r, "rotation", 0.08, 0.05)
		tw.tween_property(r, "rotation", -0.08, 0.08)
		tw.tween_property(r, "rotation", 0.0, 0.05)
		tw.tween_property(r, "modulate", Color.WHITE, 0.2)
		_aggiorna()
		if errori >= errori_max: chiudi(false)
		return
	r.set_meta("timbrata", true)
	timbrati += 1
	var t: Label = r.get_node("Timbro")
	t.visible = true
	t.scale = Vector2(2.2, 2.2)
	var pop := create_tween()
	pop.tween_property(t, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	r.scale = Vector2(1.12, 0.88)
	create_tween().tween_property(r, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sound.sfx("stamp")
	if r.get_meta("prova"):
		prova_trovata = true
		$Esito.text = "18 e 19 giugno: due commissioni per la rata 63. Ecco la prova."
	else:
		$Esito.text = "Addebito doppio. Timbrato."
	_aggiorna()


func _scappata(r: Control) -> void:
	errori += 1
	Sound.sfx("deny")
	_aggiorna()
	if r.get_meta("prova"):
		$Esito.text = "La commissione doppia della rata 63 è finita in archivio. Senza quella non c'è prova."
		chiudi(false)
		return
	$Esito.text = "Un addebito doppio è finito in archivio."
	if errori >= errori_max: chiudi(false)


func ricevuta_al_punto(pos: Vector2) -> Control:
	for r in ricevute:
		if Rect2(r.position - Vector2(6, 6), r.size + Vector2(12, 12)).has_point(pos): return r
	return null


## Solo mouse e dito: si timbra appena si preme.
func punta(pos: Vector2, step: int) -> void:
	if step == 0: timbra(ricevuta_al_punto(pos))
