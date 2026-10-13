extends Room
## L'ufficio della CHEAP S.p.A. Al terminale si sceglie il lavoro del giorno:
## facile (una firma, un'ora, una persona in meno), duro (un turno-battaglia di 8 ore) o rifiuto.

const RB := "tiles/room_builder.png"
const DESK_TEXTS := [
	["* Sul monitor: PRODUTTIVITÀ DEL REPARTO 37%. Sotto, a penna: \"aiuto\"."],
	["* Una scrivania. Nel cassetto c'è una scorta di caffè solubile e di antidolorifici."],
	["* Sul monitor è aperta un'email: \"Oggetto: ottimizzazione del personale (riservato)\"."],
	["* Una foto di famiglia, girata verso il muro. Forse per non farsi vedere."],
	["* Post-it sul monitor: \"Sorridi! Il cliente ti sente.\""],
	["* Il computer è spento. Sopra c'è un biglietto: \"Grazie di tutto. Scusate.\""],
	["* Sul monitor scorre un grafico. Sale sempre. Non c'è scritto cosa."],
	["* Una tazza con la scritta \"Il miglior dipendente del mondo\". È piena di polvere."],
]


func build() -> void:
	music = "ufficio"
	var floor_def := {"tex": RB, "at": func(c: Vector2i) -> Vector2i: return Vector2i(38 + c.x % 3, 11 + c.y % 2)}
	paint([
		"####################",
		"#WWWWWWWWWWWWWWWWWW#",
		"#wwwwwwwwwwwwwwwwww#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#########..#########",
		"#########dd#########",
	], {
		"#": {"tex": RB, "at": Vector2i(12, 0), "solid": true},
		"W": {"tex": RB, "at": Vector2i(1, 13), "solid": true},
		"w": {"tex": RB, "at": Vector2i(1, 14), "solid": true},
		".": floor_def,
		"_floor": floor_def,
	})

	add_prop("props/terminal.png", Vector2i(9, 3))
	add_prop("props/portrait.png", Vector2i(6, 2), 0, Vector2i(16, 32), [
		"* Il ritratto del fondatore della CHEAP. Ti sorride come sorride una banca.",
	])
	add_prop("props/trash.png", Vector2i(17, 3), 1, Vector2i(16, 32), [
		"* Il cestino è pieno di curriculum. Alcuni sono ancora chiusi nella busta.",
	])
	add_prop("props/palm.png", Vector2i(1, 3), 1, Vector2i(32, 32), [
		"* Una palma finta. È l'unica cosa qui dentro che non si stanca mai.",
	])
	add_prop("props/plant.png", Vector2i(18, 9), 1, Vector2i(16, 32), [
		"* Una pianta vera. Qualcuno la annaffia di nascosto ogni mattina.",
	])

	# Scrivanie: la sedia sta dietro (a nord), la scrivania la copre in parte.
	var k := 0
	for y in [5, 8]:
		for x in [3, 4, 14, 15]:
			if not (x == 4 and y == 8):
				add_prop("props/office_chair.png", Vector2i(x, y - 1), 0, Vector2i(16, 32), [], Vector2(0, -4))
			add_prop("props/office_desk.png", Vector2i(x, y), 1, Vector2i(16, 32), DESK_TEXTS[k % DESK_TEXTS.size()])
			k += 1

	add_spot(cell_center(Vector2i(9, 3)), _terminal)
	_elevator(Vector2i(12, 1))
	add_exit(Rect2i(9, 11, 2, 1), Router.STREET, "office")
	spawn_people("office")

	spawns["default"] = cell_feet(Vector2i(9, 9))
	spawns["street"] = spawns["default"]
	spawn_facing["default"] = "up"
	spawn_facing["street"] = "up"
	spawns["terminal"] = cell_feet(Vector2i(9, 4))
	spawns["elevator"] = cell_feet(Vector2i(12, 4))
	spawn_facing["elevator"] = "down"
	spawn_facing["terminal"] = "up"


func enter() -> void:
	if not GameState.flags.get("office_intro", false) and not GameState.is_robot("giulia"):
		GameState.flags["office_intro"] = true
		await Ui.say([
			"Ah, sei il nuovo! Io sono Giulia, ti faccio vedere come funziona.",
			"Ogni mattina vai al terminale contro il muro e scegli un incarico.",
			"Ci sono quelli che pagano bene e durano un'ora. E quelli che ti prendono tutta la giornata e ti spaccano la schiena.",
			"...Io ti consiglio i secondi. Ma non te l'ho detto io.",
		], "Giulia")
	await show_pending()


func _terminal() -> void:
	if GameState.worked_today:
		await Ui.say(["* Il turno di oggi è chiuso. Torna a casa a riposare."], "Terminale")
		return
	var job := GameState.job_today()
	var easy: Dictionary = job.get("easy", {})
	var hard: Dictionary = job.get("hard", {})
	var options := [


		"%s  (+%s, 1 ora)" % [easy.get("title", "?"), GameState.euros(GameState.easy_pay())],
		"%s  (8 ore, paga bassa)" % hard.get("title", "?"),
		"Rifiuta di lavorare",
	]
	var i: int = await Ui.choose("CHEAP S.p.A. - Incarichi di {day_name}. Ruolo: {rank}. Ore {clock}.", options, "Terminale")
	match i:
		0:
			await Ui.say(easy.get("desc", []), "Terminale")
			var go: int = await Ui.choose("Basta un clic.", ["Apri il modulo", "Annulla"], "Terminale")
			if go != 0:
				return
			var victim := str(job.get("victim", ""))
			var vdata := GameState.npc_data(victim)
			Router.battle({
				"kind": "sign",
				"id": victim,
				"name": str(vdata.get("name", "Qualcuno")),
				"sheet": str(vdata.get("sheet", "char_02")),
				"intro": "* Il modulo è pronto. In fondo c'è la foto di %s.\n* Qualunque cosa tu scelga, la risposta è sempre la stessa." % vdata.get("name", "qualcuno"),
				"return": Router.OFFICE,
				"spawn": "terminal",
			})
		1:
			if not GameState.has_time(GameState.COST_HARD_JOB):
				await Ui.say(["* Sono le {clock}. Non ti restano otto ore prima di mezzanotte."], "Terminale")
				return
			await Ui.say(hard.get("desc", []), "Terminale")
			var accept: int = await Ui.choose("Accetti il turno?", ["Accetta", "Annulla"], "Terminale")
			if accept != 0:
				return
			var cfg: Dictionary = (hard.get("battle", {}) as Dictionary).duplicate(true)
			cfg["kind"] = "work"
			cfg["return"] = Router.OFFICE
			cfg["spawn"] = "terminal"
			Router.battle(cfg)
		2:
			var really: int = await Ui.choose("Sicuro? Oggi non guadagnerai niente.", ["Rifiuta", "Annulla"], "Terminale")
			if really != 0:
				return
			GameState.refuse_work()
			await Ui.say([
				"* Spegni il terminale.",
				"* Dall'ufficio del capo, qualcuno ti guarda male.",
				"* Per la prima volta dopo tanto tempo, respiri. E hai tutta la giornata davanti.",
			])


## L'ascensore per l'ultimo piano: serve un badge da Supervisore (2 promozioni).
func _elevator(top_left: Vector2i) -> void:
	var frame := ColorRect.new()
	frame.color = Color("4a4658")
	frame.position = Vector2(top_left.x * T, top_left.y * T + 4)
	frame.size = Vector2(2 * T, 2 * T - 4)
	add_child(frame)
	for i in 2:
		var door := ColorRect.new()
		door.color = Color("aeb4c4")
		door.position = frame.position + Vector2(2 + i * 15, 3)
		door.size = Vector2(13, frame.size.y - 3)
		add_child(door)
	var light := ColorRect.new()
	light.color = Color("3ddc84") if GameState.rank >= 2 else Color("d0302f")
	light.position = frame.position + Vector2(14, -3)
	light.size = Vector2(4, 2)
	add_child(light)
	add_spot(cell_center(top_left + Vector2i(1, 2)) - Vector2(8, 0), _ride_elevator)


func _ride_elevator() -> void:
	if GameState.rank < 2:
		await Ui.say(["* L'ascensore per l'ultimo piano. Accanto c'è un lettore di badge.",
			"* Sul display: \"Accesso riservato. Dal grado di Supervisore in su.\""])
		return
	Router.goto(Router.BOSS, "elevator")
