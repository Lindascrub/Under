extends "res://scenes/minigame/rifatti/base.gd"
## LE DICIOTTO PORTE (Amir): le case passano da destra a sinistra, sempre più veloci.
## Amir guida il furgone delle consegne; quando una porta illuminata arriva sulla
## sua corsia, si lancia il pacco poco prima che la porta raggiunga la mira.
## Ogni lancio consuma un pacco (ce n'è qualcuno di scorta). Errore = lancio a vuoto o porta superata.
## Le stelline (minigame.gd, nodo Risposta): 0 errori 3, un errore 2, di più 1.
## Le porte sono copie di porta_consegna.tscn: l'ordine delle corsie cambia a ogni partita.

## Quante porte (consegne) ci sono.
@export var porte_totali := 18
## Pacchi in più, oltre a uno per porta.
@export var scorta := 4
## Consegne per il bonus, e per l'aiuto a metà.
@export var vinci := 14
@export var parziale := 9
## Velocità: all'inizio, quanto cresce ogni secondo, e il massimo.
@export var velocita_iniziale := 150.0
@export var accelerazione := 6.0
@export var velocita_max := 270.0
## Spazio fra una porta e la successiva (un valore a caso fra questi due).
@export var spazio_min := 190.0
@export var spazio_max := 280.0
@export var durata_lancio := 0.32
@export var tolleranza := 40.0
@export var precisione_bonus := 25.0
@export var corsie := PackedFloat32Array([137, 210, 283])
## Ingressi residenziali dello stesso pacchetto della Città, senza stirare gli edifici.
@export var facciate: Array[Texture2D] = []
const PORTA := preload("res://scenes/minigame/rifatti/porta_consegna.tscn")
const PERSONE := ["char_02", "char_05", "char_08", "char_11", "char_03", "char_06"]
var velocita := 150.0
var corsia := 1
var pacchi := 22
var rimasti := 22
var consegnati := 0
var precisi := 0
var chiuse := 0
var lancio_in_corso := false
var origine_dito := Vector2.ZERO
var gesto := false
var porta_dito: Node = null
var porte: Array[Node] = []


func avvia(c: Dictionary) -> void:
	super.avvia(c)
	velocita = velocita_iniziale
	pacchi = porte_totali + scorta
	rimasti = pacchi
	_crea_porte()
	$Aiuto.text = "Scorri su o giù: corsia. Tocca una porta: lancia dalla tua corsia." if TouchControls.enabled else "SU/GIÙ: corsia. INVIO o clic: lancia dalla tua corsia."
	_aggiorna()


## Le diciotto porte in fila, fuori dallo schermo a destra: corsie a caso, mai tre uguali di fila.
func _crea_porte() -> void:
	var x: float = $Entrata.position.x
	var prima := -1
	var di_fila := 0
	for i in porte_totali:
		var k := randi() % corsie.size()
		if k == prima and di_fila >= 1:
			k = (k + 1 + randi() % (corsie.size() - 1)) % corsie.size()
		di_fila = di_fila + 1 if k == prima else 0
		prima = k
		var p: Node2D = PORTA.instantiate()
		$Porte.add_child(p)
		p.position = Vector2(x, corsie[k])
		p.get_node("Numero").text = str(i + 1)
		if not facciate.is_empty(): p.get_node("Facciata").texture = facciate[i % facciate.size()]
		p.get_node("Destinatario").sheet = PERSONE[i % PERSONE.size()]
		porte.append(p)
		x += randf_range(spazio_min, spazio_max)


func _process(dt: float) -> void:
	if not attivo or Ui.busy or porte.is_empty(): return
	# sempre più veloce, man mano
	velocita = minf(velocita + accelerazione * dt, velocita_max)
	for p in porte:
		p.position.x -= velocita * dt
		if not p.get_meta("chiusa", false) and p.position.x < $Limite.position.x:
			p.set_meta("chiusa", true)
			chiuse += 1
			p.get_node("Luce").visible = false
			if not p.get_meta("consegnata", false):
				p.get_node("Lampada").modulate = Color(0.4, 0.4, 0.4)
				errori += 1
				$Esito.text = "Porta superata. Quel pacco non è arrivato."
				Sound.sfx("deny")
	# il marciapiede scorre sotto i piedi
	for s: Control in $Strisce.get_children():
		s.position.x = fposmod(s.position.x - velocita * dt - 16.0, 640.0) + 16.0
	_aggiorna()
	if not lancio_in_corso and (_tutte_fatte() or rimasti == 0): _termina()


func cambia_corsia(d: int) -> void:
	corsia = clampi(corsia + d, 0, corsie.size() - 1)
	$Amir.position.y = corsie[corsia] + 25.0
	$Mira.position.y = corsie[corsia]


func _aggiorna() -> void:
	cambia_corsia(0)
	$Stato.text = "Consegnati: %d/%d · Pacchi: %d · Errori: %d" % [consegnati, porte_totali, rimasti, errori]
	var da: Vector2 = $Amir/UscitaPacco.global_position
	$Traiettoria.points = PackedVector2Array([da, Vector2((da.x + $Mira.position.x) / 2.0, corsie[corsia] - 33), $Mira.position])


func lancia() -> void:
	if not attivo or rimasti <= 0 or lancio_in_corso: return
	rimasti -= 1
	lancio_in_corso = true
	var scelta: Node = null
	var errore_distanza := INF
	for p in porte:
		if p.get_meta("chiusa", false) or p.get_meta("consegnata", false) or absf(p.position.y - corsie[corsia]) > 1: continue
		var distanza := absf(p.position.x - velocita * durata_lancio - $Mira.position.x)
		if distanza < errore_distanza:
			scelta = p
			errore_distanza = distanza
	var valido := scelta != null and errore_distanza <= tolleranza
	var da: Vector2 = $Amir/UscitaPacco.global_position
	$Pacco.position = da
	$Pacco.visible = true
	$Pacco.rotation = 0.0
	# il pacco gira in volo (a parte: non allunga il lancio)
	create_tween().tween_property($Pacco, "rotation", PI, durata_lancio)
	var tw := create_tween()
	tw.tween_property($Pacco, "position", Vector2((da.x + $Mira.position.x) / 2.0, corsie[corsia] - 33), durata_lancio * 0.45)
	tw.tween_property($Pacco, "position", $Mira.position, durata_lancio * 0.55)
	await tw.finished
	$Pacco.visible = false
	lancio_in_corso = false
	if not attivo: return
	if valido and is_instance_valid(scelta):
		scelta.set_meta("consegnata", true)
		scelta.get_node("Luce").visible = false
		scelta.get_node("Destinatario").visible = true
		consegnati += 1
		if errore_distanza <= precisione_bonus: precisi += 1
		scelta.get_node("Porta").visible = false
		scelta.get_node("Ricevuto").visible = true
		scelta.get_node("Numero").visible = false
		scelta.get_node("Targa").visible = false
		scelta.get_node("Lampada").modulate = Color(0.3, 1, 0.5)
		var pop := create_tween()
		scelta.scale = Vector2(1.15, 0.9)
		pop.tween_property(scelta, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		$Esito.text = "Preso al volo!" if errore_distanza <= precisione_bonus else "Consegnato. Un po' lontano dalla soglia."
		Sound.sfx("coin")
	else:
		errori += 1
		$Esito.text = "Pacco a terra. Controlla la corsia e anticipa un poco il passaggio della porta."
		Sound.sfx("deny")
	_aggiorna()
	if rimasti == 0 or _tutte_fatte(): _termina()


## Ogni porta è consegnata o già passata?
func _tutte_fatte() -> bool:
	return porte.all(func(p: Node) -> bool: return p.get_meta("chiusa", false) or p.get_meta("consegnata", false))


func _termina() -> void:
	# Quattordici consegne danno il bonus. Da nove in su resta l'aiuto a metà.
	chiudi(consegnati >= vinci, consegnati >= parziale and consegnati < vinci)


func input_event(e: InputEvent) -> void:
	if e is InputEventKey and e.echo: return
	if e.is_action_pressed("move_up"): cambia_corsia(-1)
	elif e.is_action_pressed("move_down"): cambia_corsia(1)
	elif e.is_action_pressed("confirm"): lancia()


func punta(pos: Vector2, step: int) -> void:
	if step == 0:
		origine_dito = pos
		gesto = false
		porta_dito = _porta_al_punto(pos)
		if not TouchControls.enabled: _porta_premuta(pos)
	elif step == 1:
		gesto = gesto or pos.distance_to(origine_dito) >= 20.0
	elif step == 2 and TouchControls.enabled:
		var spostamento := pos - origine_dito
		if absf(spostamento.y) >= 20.0:
			cambia_corsia(-1 if spostamento.y < 0 else 1)
		elif not gesto and is_instance_valid(porta_dito) and not porta_dito.get_meta("chiusa", false) and not porta_dito.get_meta("consegnata", false): lancia()
		porta_dito = null


func _porta_premuta(pos: Vector2) -> void:
	if _porta_al_punto(pos) != null: lancia()


func _porta_al_punto(pos: Vector2) -> Node:
	for p in porte:
		var larghezza: float = p.get_node("Facciata").texture.get_width()
		if not p.get_meta("chiusa", false) and not p.get_meta("consegnata", false) and Rect2(p.position - Vector2(larghezza / 2.0, 50), Vector2(larghezza, 72)).has_point(pos):
			return p
	return null
