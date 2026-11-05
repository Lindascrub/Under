extends GdUnitTestSuite
## Collisioni e profondità di tutte le mappe di CHEAP, con GdUnit4. Il controllo vero è
## tests/collisioni/audit_mappa.gd: dove si arriva a piedi dall'arrivo, se lì si sta sopra o dentro
## un oggetto, se un oggetto basso copre tutto il personaggio. Le foto da guardare a occhio le fa
## tests/collisioni/profondita_schermate.tscn (una collisione giusta non dice se si è coperti bene).
##   Godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/gdunit --ignoreHeadlessMode

const MAPPE := {
	"fondo": "res://chapters/c1/fondo.tscn", "sottoufficio": "res://chapters/c2/sottoufficio.tscn",
	"mercato": "res://chapters/c3/mercato.tscn", "banca": "res://chapters/c4/banca.tscn",
	"citta": "res://chapters/c5/citta.tscn", "casa_comune": "res://chapters/c5/casa_comune.tscn",
	"cima": "res://chapters/c6/cima.tscn",
}
## Le uscite che restano chiuse apposta (nessuna, per ora).
const USCITE_CHIUSE := {}
## Le spinte con la tastiera: dritte e in diagonale, contro spigoli e angoli.
const SPINTE := [["move_up"], ["move_down"], ["move_left"], ["move_right"], ["move_up", "move_left"],
	["move_up", "move_right"], ["move_down", "move_left"], ["move_down", "move_right"]]
const AZIONI := ["move_up", "move_down", "move_left", "move_right", "cancel", "confirm"]

var _room: Room
var _frame := 0


func before() -> void:
	GameState.save_path = "user://collisioni_gdunit.json"


func after_test() -> void:
	for a: String in AZIONI:
		Input.action_release(a)
	if is_instance_valid(_room):
		await MappaAperta.chiudi(self, _room)
	_room = null


func _process(_delta: float) -> void:
	_frame += 1
	MappaAperta.salta_dialoghi(_frame)


func _apri(mappa: String, badge := false) -> AuditMappa:
	_room = await MappaAperta.apri(self, MAPPE[mappa])
	assert_object(_room).override_failure_message("%s non si apre" % mappa).is_not_null()
	if badge:
		# col badge di ogni piano i tornelli sono aperti: le scale si salgono
		var gates: Array[Node] = []
		for st in _room.find_children("*", "", true, false):
			if st is StairsUp:
				GameState.badges.append(str(st.get("need")))
				if st.has_node("Sbarra"):
					gates.append(st.get_node("Sbarra"))
		for gate in gates:
			gate.free()
		for i in 2:
			await get_tree().physics_frame
	# chi gira per la stanza sta fermo: le prove devono dare sempre lo stesso risultato
	for npc in _room.find_children("*", "Npc", true, false):
		npc.process_mode = Node.PROCESS_MODE_DISABLED
	# il giocatore si sposta a mano: le uscite non devono cambiare stanza
	for area in _room.find_children("*", "Area2D", true, false):
		(area as Area2D).monitoring = false
	var a := AuditMappa.new(_room)
	var starts: Array = _room.spawns.values()
	starts.append(_room.player.position)
	a.flood(starts)
	return a


## Mai sopra un edificio o un mobile, mai dentro la base di un oggetto, mai coperti del tutto da un
## oggetto basso o appeso, mai disegnati dalla parte sbagliata di un oggetto alto.
func test_niente_sopra_o_dentro_gli_oggetti(mappa: String, test_parameters := [["fondo"], ["sottoufficio"],
		["mercato"], ["banca"], ["citta"], ["casa_comune"], ["cima"], ["ufficio_capo"]]) -> void:
	var a := await _apri(mappa)
	assert_int(a.reach.size()).override_failure_message("%s: a piedi non si va da nessuna parte" % mappa).is_greater(200)
	a.check()
	for kind: String in a.problems:
		assert_dict(a.problems[kind]).override_failure_message("%s, %s:\n%s" % [mappa, kind, a.report()]).is_empty()


## Scale (col badge) e porte restano raggiungibili a piedi dall'arrivo.
func test_scale_e_porte_raggiungibili(mappa: String, test_parameters := [["fondo"], ["sottoufficio"],
		["mercato"], ["banca"], ["citta"], ["casa_comune"], ["cima"], ["ufficio_capo"]]) -> void:
	var a := await _apri(mappa, true)
	for st in _room.find_children("*", "", true, false):
		var area: Area2D = null
		if st is StairsUp:
			area = st.get_node("Cima")
		elif st is StairsDown:
			area = st.get_node("Discesa")
		if area:
			assert_bool(a.touches(AuditMappa.area_rect(area))) \
				.override_failure_message("%s: non si arriva in fondo alle scale %s" % [mappa, st.name]).is_true()
	var chiuse: Array = USCITE_CHIUSE.get(mappa, [])
	for i in a.exits.size():
		if i in chiuse:
			continue
		# se la griglia non ci arriva (una porta a filo del muro), si prova con la tastiera
		var ok := a.exits_reached.has(i) or await _porta_con_tastiera(a, a.exits[i])
		assert_bool(ok).override_failure_message("%s: non si arriva all'uscita %s" % [mappa, a.exits[i]]).is_true()


## Prove vere con la tastiera: dai punti accanto a muri e oggetti si spinge dritto e in diagonale.
## Dopo la spinta i piedi non devono essere dentro niente, né in un posto dove a piedi non si arriva
## (cioè passati attraverso uno spigolo o un angolo).
func test_tastiera_contro_spigoli(mappa: String, test_parameters := [["fondo"], ["sottoufficio"],
		["mercato"], ["banca"], ["citta"], ["casa_comune"], ["cima"], ["ufficio_capo"]]) -> void:
	var a := await _apri(mappa)
	var bordi := _punti_sul_bordo(a)
	assert_int(bordi.size()).is_greater(0)
	var p := _room.player
	p.set_physics_process(true)
	# sempre gli stessi punti: il test non cambia da una volta all'altra
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var fughe: Array[String] = []
	for i in mini(25, bordi.size()):
		var start: Vector2 = bordi[rng.randi() % bordi.size()]
		for spinta: Array in SPINTE:
			p.position = start
			p.velocity = Vector2.ZERO
			await get_tree().physics_frame
			for azione: String in spinta:
				Input.action_press(azione)
			for f in 14:
				await get_tree().physics_frame
			for azione: String in spinta:
				Input.action_release(azione)
			await get_tree().physics_frame
			if not a.free_at(p.position) or not (_vicino_a_raggiunto(a, p.position) or a.walk_reaches(start, p.position)):
				fughe.append("%s %s -> %s" % [str(start), "+".join(spinta), str(p.position)])
	p.set_physics_process(false)
	assert_array(fughe).override_failure_message("%s: passato attraverso spigoli:\n%s" % [mappa, "\n".join(fughe)]).is_empty()


## Dal punto raggiunto più vicino si cammina verso la porta: i piedi la toccano?
func _porta_con_tastiera(a: AuditMappa, door: Rect2) -> bool:
	var best := Vector2.INF
	for q in a.points():
		if q.distance_to(door.get_center()) < best.distance_to(door.get_center()):
			best = q
	var p := _room.player
	p.position = best
	p.set_physics_process(true)
	var d := door.get_center() - best
	var azioni: Array[String] = []
	if absf(d.x) > 2.0:
		azioni.append("move_right" if d.x > 0 else "move_left")
	if absf(d.y) > 2.0:
		azioni.append("move_down" if d.y > 0 else "move_up")
	for azione in azioni:
		Input.action_press(azione)
	var dentro := false
	for f in 40:
		await get_tree().physics_frame
		if door.intersects(Rect2(p.position + Vector2(-7, -6), Vector2(14, 6))):
			dentro = true
			break
	for azione in azioni:
		Input.action_release(azione)
	p.set_physics_process(false)
	return dentro


## I punti raggiunti che hanno accanto qualcosa di solido.
func _punti_sul_bordo(a: AuditMappa) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for k: Vector2i in a.reach:
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not a.reach.has(k + d):
				out.append(Vector2(k * AuditMappa.PASSO))
				break
	out.sort()
	return out


## Il punto è a meno di un passo da un punto raggiunto (fra due punti della griglia si cammina).
func _vicino_a_raggiunto(a: AuditMappa, at: Vector2) -> bool:
	var c := Vector2i((at / AuditMappa.PASSO).floor())
	for dy in range(0, 2):
		for dx in range(0, 2):
			if a.reach.has(c + Vector2i(dx, dy)):
				return true
	# sulle uscite la stanza finisce: chi ci arriva esce, va bene
	return a.exit_at(at) >= 0
