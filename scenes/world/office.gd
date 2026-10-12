extends Room
## L'ufficio della CHEAP S.p.A. Al terminale si sceglie il lavoro del giorno:
## facile (firma, sfrutti qualcuno, guadagni tanto), duro (minigioco, guadagni poco) o rifiuto.

const RB := "tiles/room_builder.png"


func build() -> void:
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
	add_prop("props/portrait.png", Vector2i(6, 2), 0)
	add_prop("props/trash.png", Vector2i(17, 3))
	add_prop("props/cooler.png", Vector2i(18, 3), 1, Vector2i(16, 48))
	for x in [3, 4, 14, 15]:
		for y in [5, 8]:
			add_prop("props/office_desk.png", Vector2i(x, y))
	for x in [3, 14, 15]:
		add_prop("props/office_chair.png", Vector2i(x, 9), 0)

	add_spot(cell_center(Vector2i(9, 3)), _terminal)
	add_exit(Rect2i(9, 11, 2, 1), Router.STREET, "office")

	add_npc("giulia", Vector2i(11, 4), "left")
	add_npc("dario", Vector2i(4, 6), "up")

	spawns["default"] = cell_feet(Vector2i(9, 9))
	spawns["street"] = spawns["default"]
	spawn_facing["default"] = "up"
	spawn_facing["street"] = "up"
	spawns["terminal"] = cell_feet(Vector2i(9, 4))
	spawn_facing["terminal"] = "up"


func enter() -> void:
	if not GameState.flags.get("office_intro", false) and not GameState.is_robot("giulia"):
		GameState.flags["office_intro"] = true
		await Ui.say([
			"Ah, sei il nuovo! Io sono Giulia, ti faccio vedere come funziona.",
			"Ogni mattina vai al terminale contro il muro e scegli un incarico.",
			"Ci sono quelli che pagano bene e non costano fatica. E quelli che ti spaccano la schiena.",
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
		"%s  (+%s)" % [easy.get("title", "?"), GameState.euros(GameState.easy_pay())],
		"%s  (+100 / 400 €)" % hard.get("title", "?"),
		"Rifiuta di lavorare",
	]
	var i: int = await Ui.choose("CHEAP S.p.A. - Incarichi del giorno {day}. Ruolo: {rank}.", options, "Terminale")
	match i:
		0:
			await Ui.say(easy.get("desc", []), "Terminale")
			var sign_it: int = await Ui.choose("Basta un clic.", ["FIRMA", "Annulla"], "Terminale")
			if sign_it != 0:
				return
			var pay := GameState.do_easy_job()
			await Ui.say([
				"* Hai firmato. Ci è voluto un secondo.",
				"* +%s. Il capo è soddisfatto: ora sei {rank}!" % GameState.euros(pay),
				"* Non hai sentito niente. Proprio niente.",
			])
		1:
			await Ui.say(hard.get("desc", []), "Terminale")
			var accept: int = await Ui.choose("Accetti il turno?", ["Accetta", "Annulla"], "Terminale")
			if accept != 0:
				return
			var scene := Router.WAREHOUSE if hard.get("minigame", "") == "warehouse" else Router.DELIVERY
			Router.goto(scene)
		2:
			var really: int = await Ui.choose("Sicuro? Oggi non guadagnerai niente.", ["Rifiuta", "Annulla"], "Terminale")
			if really != 0:
				return
			GameState.refuse_work()
			await Ui.say([
				"* Spegni il terminale.",
				"* Dall'ufficio del capo, qualcuno ti guarda male.",
				"* Per la prima volta dopo tanto tempo, respiri.",
			])
