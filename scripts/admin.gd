class_name Admin
extends RefCounted
## La schermata admin: c'è solo per chi si chiama NOME (si sceglie come nome all'inizio della partita).
## Si apre dal menu "Stato" (tasto del menu, o il pulsante sul telefono): voce "Admin".
## Usa i menu normali del gioco (Ui.choose), così va bene sia col dito sia con la tastiera.
## Da qui: andare su qualunque piano, rifare il minigioco di qualunque personaggio, fare un TURNO
## di qualunque lavoro, rifare un incarico del Capo, avere soldi, badge ed energia.

## Il nome che apre la schermata (minuscolo).
const NOME := "porcoretto"
## Quante voci per pagina, nelle liste lunghe (poi "Altri…").
const PER_PAGINA := 6
## I piani dove si può andare: [nome nel menu, scena].
const PIANI := [
	["Il Fondo (-5)", Router.FONDO],
	["Il Sottoufficio (-4)", Router.SOTTOUFFICIO],
	["Il Mercato (-3)", Router.MERCATO],
	["La Banca (-2)", Router.BANCA],
	["La Città (piano terra)", Router.CITY],
	["La Casa Comune", Router.CASA_COMUNE],
	["La Cima", Router.CIMA],
]
const B := preload("res://scripts/boss_missions.gd")


static func attivo() -> bool:
	return GameState.player_name.strip_edges().to_lower() == NOME


## Il menu principale. `room` è la stanza dove sei: i giochi, finiti, ti riportano lì.
static func menu(room: Room) -> void:
	var last := 0
	while true:
		var voci := ["Vai a un piano", "Minigioco di un personaggio", "Turno di lavoro", "Incarico del Capo",
			"Soldi, badge, energia", "Chiudi"]
		var c: int = await Ui.choose("ADMIN. Cosa vuoi fare?", voci, "Admin", last)
		last = c
		var partito := false
		match c:
			0: partito = await _piano()
			1: partito = await _personaggio(room)
			2: partito = await _turno(room)
			3: partito = await _capo(room)
			4: await _soldi()
			_: return
		if partito:
			return


## Una lista lunga, a pagine. Restituisce l'indice scelto, o -1 per "Indietro".
static func _scegli(domanda: String, nomi: Array) -> int:
	var inizio := 0
	while true:
		var pagina := nomi.slice(inizio, inizio + PER_PAGINA)
		var voci: Array = pagina.duplicate()
		var altri := inizio + PER_PAGINA < nomi.size() or inizio > 0
		if altri:
			voci.append("Altri…")
		voci.append("Indietro")
		var c: int = await Ui.choose(domanda, voci, "Admin")
		if c < pagina.size():
			return inizio + c
		if altri and c == pagina.size():
			inizio = inizio + PER_PAGINA if inizio + PER_PAGINA < nomi.size() else 0
			continue
		return -1
	return -1


static func _piano() -> bool:
	var nomi: Array = PIANI.map(func(p: Array) -> String: return p[0])
	var i := await _scegli("Su che piano vuoi andare?", nomi)
	if i < 0:
		return false
	_tutti_i_badge()
	Router.goto(PIANI[i][1])
	return true


static func _personaggio(room: Room) -> bool:
	var ids: Array = []
	var nomi: Array = []
	for id: String in GameState.npc_ids():
		var d := GameState.npc_data(id)
		var h: Dictionary = d.get("help", {})
		if h.has("minigame"):
			ids.append(id)
			nomi.append("%s: %s" % [str(d.get("name", id)), str((h["minigame"] as Dictionary).get("title", "minigioco"))])
	var i := await _scegli("Il minigioco di chi?", nomi)
	if i < 0:
		return false
	var d := GameState.npc_data(ids[i])
	Router.minigame(Npc.minigame_cfg(ids[i], str(d.get("name", ids[i])), d["help"], room.scene_file_path,
		room.player.global_position))
	return true


static func _turno(room: Room) -> bool:
	var lavori: Array = []
	for j: Dictionary in GameState.jobs_available():
		if j.has("game"):
			lavori.append(j)
	var i := await _scegli("Quale turno?", lavori.map(func(j: Dictionary) -> String: return str(j.get("title", j.get("id", "")))))
	if i < 0:
		return false
	room.start_job(lavori[i])
	return true


static func _capo(room: Room) -> bool:
	var piani: Array = []
	for f: String in B.FLOORS:
		if B.TITLES.has(f) and f != "cima":
			piani.append(f)
	var nomi: Array = piani.map(func(f: String) -> String: return "%s (%s)" % [B.TITLES[f], f])
	nomi.append("La Direzione (la Cima)")
	var i := await _scegli("Quale incarico del Capo?", nomi)
	if i < 0:
		return false
	if i == piani.size():
		GameState.save_game(room.scene_file_path, room.player.global_position)
		GameState.minigame = {"cycle": 1}
		Router.goto(Router.DIREZIONE)
		return true
	# si rifà da capo: l'incarico torna aperto, senza i progressi di prima
	var s := B.state(piani[i])
	s["status"] = "active"
	s["seen"] = true
	s["progress"] = {}
	s["reward"] = 0
	B.launch(room, piani[i])
	return true


static func _soldi() -> void:
	var last := 0
	while true:
		var c: int = await Ui.choose("Soldi %s. Badge %d. Energia %d/%d." % [GameState.euros(GameState.money),
			GameState.badges.size(), GameState.energy, GameState.MAX_ENERGY],
			["+10.000 €", "Tutti i badge", "Energia piena", "Indietro"], "Admin", last)
		last = c
		match c:
			0: GameState.money += 10000
			1: _tutti_i_badge()
			2: GameState.energy = GameState.MAX_ENERGY
			_: return
		Sound.sfx("coin")
		GameState.changed.emit()


static func _tutti_i_badge() -> void:
	for f: Dictionary in GameState.FLOORS:
		var id := str(f["id"])
		if id != "-5" and not GameState.has_badge(id):
			GameState.badges.append(id)
	GameState.changed.emit()
