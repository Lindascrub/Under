extends "res://scenes/minigame/rifatti/base.gd"
@export var velocita := 86.0
@export var durata_lancio := 0.32
@export var tolleranza := 40.0
@export var precisione_bonus := 25.0
@export var corsie := PackedFloat32Array([137, 210, 283])
var corsia := 1
var rimasti := 6
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
	for p in $Porte.get_children(): porte.append(p)
	$Aiuto.text = "Scorri in verticale per la corsia. Tocca la porta per lanciare." if TouchControls.enabled else "SU/GIÙ: corsia. INVIO o clic su una porta: lancia."
	_aggiorna()
func _process(dt: float) -> void:
	if not attivo or Ui.busy: return
	for p in porte:
		p.position.x -= velocita * dt
		if not p.get_meta("chiusa", false) and p.position.x < $Limite.position.x:
			p.set_meta("chiusa", true)
			chiuse += 1
			p.get_node("Luce").visible = false
			if not p.get_meta("consegnata", false): $Esito.text = "Porta superata. Quel pacco non è arrivato."
	_aggiorna()
	if not lancio_in_corso and (chiuse == porte.size() or rimasti == 0): _termina()
func cambia_corsia(d: int) -> void:
	corsia = clampi(corsia + d, 0, corsie.size() - 1)
	$Bici.position.y = corsie[corsia] + 25.0
	$Mira.position.y = corsie[corsia]
func _aggiorna() -> void:
	cambia_corsia(0)
	$Stato.text = "Pacchi rimasti: %d · Consegnati: %d/6 · Corsia %d" % [rimasti, consegnati, corsia + 1]
	$Traiettoria.points = PackedVector2Array([$Bici.position + Vector2(12, -16), Vector2(211, corsie[corsia] - 33), $Mira.position])
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
	$Pacco.position = $Bici.position + Vector2(12, -16)
	$Pacco.visible = true
	var tw := create_tween()
	tw.tween_property($Pacco, "position", Vector2(211, corsie[corsia] - 33), durata_lancio * 0.45)
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
		scelta.get_node("Porta").scale.x = 0.35
		$Esito.text = "Preso al volo!" if errore_distanza <= precisione_bonus else "Consegnato. Un po' lontano dalla soglia."
		Sound.sfx("coin")
	else:
		errori += 1
		$Esito.text = "Pacco a terra. Avvicina la porta alla fine della traiettoria."
		Sound.sfx("deny")
	_aggiorna()
	if rimasti == 0: _termina()
func _termina() -> void:
	# Sei consegne scelte bene danno il bonus. Tre o più restano aiuto parziale.
	chiudi(consegnati == 6 and precisi >= 4, consegnati >= 3 and not (consegnati == 6 and precisi >= 4))
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
		elif not gesto and is_instance_valid(porta_dito) and not porta_dito.get_meta("chiusa", false): lancia()
		porta_dito = null
func _porta_premuta(pos: Vector2) -> void:
	if _porta_al_punto(pos) != null: lancia()
func _porta_al_punto(pos: Vector2) -> Node:
	for p in porte:
		if not p.get_meta("chiusa", false) and Rect2(p.position - Vector2(28, 40), Vector2(56, 58)).has_point(pos):
			return p
	return null
