extends Room
## Il Rifugio: la cantina del palazzo blu. Si sblocca aiutando Ivo.
## Qui chi non ce la fa più si aiuta senza soldi: un letto, del pane, una bacheca.

const RB := "tiles/room_builder.png"


func build() -> void:
	music = "rifugio"
	var floor_def := {"tex": RB, "at": func(c: Vector2i) -> Vector2i: return Vector2i(46 + c.x % 3, 25 + c.y % 2)}
	paint([
		"################",
		"#WWWWWWWWWWWWWW#",
		"#wwwwwwwwwwwwww#",
		"#..............#",
		"#..............#",
		"#..............#",
		"#..............#",
		"#..............#",
		"#..............#",
		"#######..#######",
		"#######dd#######",
	], {
		"#": {"tex": RB, "at": Vector2i(12, 0), "solid": true},
		"W": {"tex": RB, "at": Vector2i(1, 15), "solid": true},
		"w": {"tex": RB, "at": Vector2i(1, 16), "solid": true},
		".": floor_def,
		"_floor": floor_def,
	})
	add_prop("props/bed.png", Vector2i(2, 5), 3, Vector2i(32, 48))
	add_spot(Vector2(60, 72), _rest)
	add_prop("props/dresser.png", Vector2i(6, 3), 1, Vector2i(32, 48))
	add_spot(cell_center(Vector2i(6, 3)), _board)
	add_computer_desk(Vector2i(10, 4))
	add_computer_desk(Vector2i(11, 4))
	add_spot(cell_center(Vector2i(10, 5)) + Vector2(8, 0), _bread)
	add_prop("props/boxes.png", Vector2i(13, 3), 2, Vector2i(32, 48), [
		"* Scatoloni con scritto sopra: VESTITI, LIBRI, ATTREZZI. Chi ha bisogno prende, chi può lascia.",
	])
	add_prop("props/boxes_small.png", Vector2i(14, 8), 2, Vector2i(16, 32), [
		"* Una scatola piena di chiavi inglesi e cacciaviti. \"Per riparare, non per comprare\".",
	])
	add_prop("props/plant.png", Vector2i(1, 8), 1, Vector2i(16, 32), [
		"* Una pianta cresciuta in una lattina di pomodori. Qualcuno le ha dato un nome: Speranza.",
	])
	add_prop("props/lamp.png", Vector2i(9, 3), 1, Vector2i(16, 32), [
		"* Una lampada collegata a una batteria d'auto. La corrente qui sotto costa troppo.",
	])
	add_exit(Rect2i(7, 10, 2, 1), Router.STREET, "shelter")
	spawn_people("shelter")
	add_save_point(Vector2i(4, 8))

	spawns["default"] = cell_feet(Vector2i(7, 8))
	spawns["street"] = spawns["default"]
	spawn_facing["default"] = "up"


func enter() -> void:
	if not GameState.flags.get("shelter_intro", false):
		GameState.flags["shelter_intro"] = true
		await Ui.say([
			"* La cantina del palazzo blu. Fa freddo, ma c'è luce, e qualcuno ha appeso dei festoni fatti a mano.",
			"* Sulla porta, un cartello: \"IL RIFUGIO - qui nessuno ti chiede quanto guadagni\".",
		])
	await show_pending()


func _rest() -> void:
	if GameState.flags.get("shelter_rest_day", 0) == GameState.day:
		await Ui.say(["* Ti sei già riposato qui oggi. Lascia il letto a chi ne ha più bisogno."])
		return
	var c: int = await Ui.choose("Un letto da campo. Ti stendi un'ora?", ["Riposa (1 ora)", "No"])
	if c != 0:
		return
	GameState.flags["shelter_rest_day"] = GameState.day
	GameState.spend(60)
	GameState.restore(12)
	Sound.sfx("heal")
	await Ui.say(["* Dormi un'ora. Qualcuno ti ha messo una coperta addosso mentre dormivi.", "* Energia +12."])


func _bread() -> void:
	if GameState.flags.get("bread_day", 0) == GameState.day:
		await Ui.say(["* Il pane di oggi è finito. Domani ne porteranno altro."])
		return
	GameState.flags["bread_day"] = GameState.day
	GameState.give_item("Panino")
	Sound.sfx("heal")
	await Ui.say([
		"* Sul tavolo c'è del pane fresco e un biglietto: \"Prendi quello che ti serve\".",
		"* (Hai preso: Panino.)",
	])


func _board() -> void:
	var lines := [
		"* Una bacheca piena di bigliettini.",
		"* \"Riparo bici in cambio di pane. - Sami\"",
		"* \"Lezioni di chitarra gratis, il martedì. - Tano\"",
		"* \"Cerco qualcuno che legga il giornale a voce alta. Gli occhiali li ho rotti. - Ivo\"",
	]
	if GameState.refused >= 1:
		lines.append("* In fondo, scritto più piccolo: \"Se saremo abbastanza, una sera smetteremo di pagare. Tutti insieme. - N.\"")
	await Ui.say(lines)
