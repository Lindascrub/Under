extends "res://scenes/minigame/rifatti/base.gd"
@export var durata := 45.0
@export var intervallo := 1.65
@export var velocita := 48.0
@export var obiettivo := 8
@export var zona_consegna := Vector2(222, 420)
var tempo := 45.0
var fra_poco := 0.0
var generati := 0
var dati := 0
var pila := 0
var persone: Array[Node] = []
var preso: Node = null
var foglio_in_volo := false
var guida_t := 0.0
var guida_fatta := false
const PASSANTE := preload("res://scenes/minigame/rifatti/passante.tscn")
const INTERESSI := ["LIBRO", "ATTREZZO", "INCONTRI"]
func avvia(c: Dictionary) -> void:
	super.avvia(c)
	tempo = durata
	$Aiuto.text = "Trascina dalla persona con ? alla pila del suo interesse." if TouchControls.enabled else "SINISTRA/SU/DESTRA: pila. INVIO o clic sulla persona: consegna."
	$Casa/Porta.visible = _casa_aperta()
	$Casa/Chiusura.visible = not $Casa/Porta.visible
	$Casa/Titolo.text = "CASA COMUNE" if $Casa/Porta.visible else "CASA COMUNE · CHIUSA"
	_aggiorna()
func crea_persona() -> Node:
	var p := PASSANTE.instantiate()
	$Persone.add_child(p)
	p.position = $Arrivo.position
	var interesse := (int(generati / 3) + generati % 3) % 3
	# Due destinatari disponibili ogni tre arrivi: almeno 16 in 45 secondi.
	var disponibile := generati % 3 != 2
	var segno: String = "?" if disponibile else (["!!", "...", "CHEAP"][int(generati / 3) % 3])
	p.set_meta("interesse", interesse)
	p.set_meta("disponibile", disponibile)
	p.set_meta("dato", false)
	p.get_node("Segno").text = segno + (" " + INTERESSI[interesse] if disponibile else "")
	p.get_node("Icona").tipo = interesse
	p.get_node("Icona").visible = disponibile
	p.get_node("Persona").sheet = ["char_02", "char_05", "char_08", "char_11"][generati % 4]
	generati += 1
	persone.append(p)
	return p
func _process(dt: float) -> void:
	if not attivo or Ui.busy: return
	tempo -= dt
	fra_poco -= dt
	if fra_poco <= 0:
		crea_persona()
		fra_poco = intervallo
	for p in persone.duplicate():
		if p.get_meta("dato", false):
			continue
		p.position.x -= velocita * dt
		if p.position.x < $Uscita.position.x:
			persone.erase(p)
			p.queue_free()
	if TouchControls.enabled and not guida_fatta:
		guida_t += dt
		$Guida.visible = false
		for p in persone:
			if p.get_meta("disponibile", false) and not p.get_meta("dato", false) and p.position.x >= zona_consegna.x and p.position.x <= zona_consegna.y:
				var fine: Vector2 = $Pile.get_child(int(p.get_meta("interesse"))).get_global_rect().get_center()
				$Guida.visible = true
				$Guida/Traccia.points = PackedVector2Array([p.position, fine])
				$Guida/Punto.position = p.position.lerp(fine, fmod(guida_t, 1.3) / 1.3)
				break
	_aggiorna()
	if tempo <= 0: chiudi(false)
func _aggiorna() -> void:
	$Stato.text = "Volantini letti: %d/%d · Tempo %d · Errori %d/3" % [dati, obiettivo, int(ceil(tempo)), errori]
	for i in 3:
		$Pile.get_child(i).modulate = Color("ffe49d") if i == pila else Color.WHITE
func scegli_persona(pos: Vector2) -> Node:
	for p in persone:
		if not p.get_meta("dato", false) and Rect2(p.position - Vector2(30, 58), Vector2(60, 66)).has_point(pos): return p
	return null
func consegna(p: Node, scelta: int) -> void:
	if not attivo or p == null or foglio_in_volo or p.get_meta("dato", false): return
	if p.position.x < zona_consegna.x or p.position.x > zona_consegna.y:
		$Esito.text = "Aspetta che sia davanti ad Ada, nella zona chiara."
		return
	if not p.get_meta("disponibile", false) or int(p.get_meta("interesse")) != scelta:
		errori += 1
		$Esito.text = "Non lo legge. Cerca un ? e il suo interesse."
		Sound.sfx("deny")
		if errori >= 3: chiudi(false)
		return
	p.set_meta("dato", true)
	foglio_in_volo = true
	$Foglio.position = $Ada.position + Vector2(8, -20)
	$Foglio.visible = true
	var tw := create_tween()
	tw.tween_property($Foglio, "position", p.position - Vector2(0, 21), 0.23)
	await tw.finished
	$Foglio.visible = false
	foglio_in_volo = false
	if not attivo or not is_instance_valid(p): return
	p.get_node("Foglio").visible = true
	p.get_node("Persona").anim = "idle_down"
	p.get_node("Segno").text = "Lo legge."
	dati += 1
	guida_fatta = true
	$Guida.visible = false
	$Esito.text = "Un volantino preso e letto."
	Sound.sfx("blip")
	var via := create_tween()
	via.tween_interval(0.8)
	# L'ingresso si usa soltanto se la Casa è realmente aperta.
	if _casa_aperta(): via.tween_property(p, "position", $Ingresso.position, 1.0)
	else: via.tween_property(p, "position", $Uscita.position, 1.0)
	via.tween_callback(func():
		persone.erase(p)
		p.queue_free())
	_aggiorna()
	if dati >= obiettivo:
		GameState.flags["c5_volantini"] = dati
		configurazione["_extra"] = ["* Otto volantini in mano a persone che li hanno letti."]
		chiudi(true)
func input_event(e: InputEvent) -> void:
	if e is InputEventKey and e.echo: return
	if e.is_action_pressed("move_left"): pila = 0
	elif e.is_action_pressed("move_up"): pila = 1
	elif e.is_action_pressed("move_right"): pila = 2
	elif e.is_action_pressed("confirm"):
		var vicino: Node = null
		for p in persone:
			if not p.get_meta("dato", false) and p.position.x >= zona_consegna.x and p.position.x <= zona_consegna.y and (vicino == null or absf(p.position.x - $Ada.position.x) < absf(vicino.position.x - $Ada.position.x)): vicino = p
		consegna(vicino, pila)
	_aggiorna()
func _casa_aperta() -> bool:
	return str(GameState.flags.get("c5_esito", "")) != "riconversione"
func punta(pos: Vector2, step: int) -> void:
	if not TouchControls.enabled:
		if step == 0:
			for i in 3:
				if $Pile.get_child(i).get_global_rect().has_point(pos):
					pila = i
					_aggiorna()
					return
			consegna(scegli_persona(pos), pila)
		return
	if step == 0:
		preso = scegli_persona(pos)
		$Gesto.visible = preso != null
		if preso != null: $Gesto.points = PackedVector2Array([preso.position, pos])
	elif step == 1 and is_instance_valid(preso):
		$Gesto.points = PackedVector2Array([preso.position, pos])
	elif step == 2:
		$Gesto.visible = false
		if is_instance_valid(preso):
			for i in 3:
				if $Pile.get_child(i).get_global_rect().has_point(pos): consegna(preso, i)
		preso = null
