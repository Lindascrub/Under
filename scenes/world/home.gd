extends Room
## Casa del protagonista: il letto (fine giornata e rata), il computer (la banca), la porta.

const RB := "tiles/room_builder.png"


func build() -> void:
	var floor_def := {"tex": RB, "at": func(c: Vector2i) -> Vector2i: return Vector2i(34 + c.x % 3, 21 + c.y % 2)}
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
		"#..............#",
		"#######..#######",
		"#######dd#######",
	], {
		"#": {"tex": RB, "at": Vector2i(12, 0), "solid": true},
		"W": {"tex": RB, "at": Vector2i(12, 11), "solid": true},
		"w": {"tex": RB, "at": Vector2i(12, 12), "solid": true},
		".": floor_def,
		"_floor": floor_def,
	})

	add_prop("props/bed.png", Vector2i(2, 5), 3, Vector2i(32, 48))
	add_prop("props/dresser.png", Vector2i(6, 3), 1, Vector2i(32, 48))
	add_prop("props/computer.png", Vector2i(10, 3))
	add_prop("props/wardrobe.png", Vector2i(13, 3), 1, Vector2i(16, 48))
	add_prop("props/robot_toy.png", Vector2i(14, 3))

	add_spot(Vector2(60, 72), _sleep)
	add_spot(cell_center(Vector2i(10, 3)), _computer)
	add_spot(cell_center(Vector2i(14, 3)), _robot_toy)
	add_exit(Rect2i(7, 11, 2, 1), Router.STREET, "home")

	spawns["default"] = cell_feet(Vector2i(4, 4))
	spawns["bed"] = spawns["default"]
	spawn_facing["default"] = "left"
	spawn_facing["bed"] = "left"
	spawns["street"] = cell_feet(Vector2i(7, 9))
	spawn_facing["street"] = "up"


func enter() -> void:
	if GameState.day == 1 and not GameState.flags.get("home_intro", false):
		GameState.flags["home_intro"] = true
		await Ui.say([
			"* La casa di tuo padre. Vuota, a parte qualche mobile.",
			"* Sul computer lampeggia una email.",
		])
	await show_pending()


func _computer() -> void:
	var lines := [
		"* BANCA FIDUCIA S.p.A. - Estratto conto.",
		"* Debito residuo: {debt}. Interessi: 1% ogni notte.",
		"* Rata minima: %s al giorno. Se non paghi: mora di %s." % [
			GameState.euros(GameState.MIN_PAYMENT), GameState.euros(GameState.LATE_FEE)],
	]
	if GameState.day == 1 and not GameState.worked_today:
		lines.append("* Nuova email da CHEAP S.p.A.: \"Benvenuto! Il tuo primo turno inizia oggi. L'ufficio è l'edificio alto in fondo alla strada.\"")
	elif GameState.worked_today:
		lines.append("* Nessuna nuova email. Il turno di oggi è fatto: puoi andare a dormire.")
	else:
		lines.append("* CHEAP S.p.A.: \"Ti aspettiamo in ufficio. Puntuale.\"")
	await Ui.say(lines)


func _robot_toy() -> void:
	await Ui.say([
		"* Il robot giocattolo che ti aveva regalato tuo padre.",
		"* \"Un giorno faranno tutto loro\", diceva. \"E noi cosa faremo?\"",
	])


func _sleep() -> void:
	if not GameState.worked_today:
		var c: int = await Ui.choose("Oggi non hai lavorato. Vuoi dormire lo stesso?", ["Dormi", "Non ancora"])
		if c != 0:
			return
		GameState.refuse_work()

	var paid_minimum := GameState.debt <= 0
	if GameState.debt > 0:
		var minimum := mini(GameState.MIN_PAYMENT, GameState.debt)
		var all_you_can := mini(GameState.money, GameState.debt)
		var options: Array = []
		var amounts: Array[int] = []
		if GameState.money >= minimum:
			options.append("Paga la rata (%s)" % GameState.euros(minimum))
			amounts.append(minimum)
		if all_you_can > 0 and all_you_can != minimum:
			options.append("Paga tutto quello che puoi (%s)" % GameState.euros(all_you_can))
			amounts.append(all_you_can)
		options.append("Non pagare (mora di %s)" % GameState.euros(GameState.LATE_FEE))
		amounts.append(0)
		var i: int = await Ui.choose("Prima di dormire: la banca aspetta la rata. Debito: {debt}.", options)
		if amounts[i] > 0:
			GameState.pay_debt(amounts[i])
			paid_minimum = amounts[i] >= minimum

	GameState.end_day(paid_minimum)
	if GameState.day > GameState.LAST_DAY:
		Router.goto(Router.ENDING, "", ["Il settimo giorno è finito.", "La banca ha fatto i suoi conti.", "Adesso tocca a te fare i tuoi."])
		return
	GameState.save_game()
	Router.goto(Router.HOME, "bed", ["Giorno {day}.", "Durante la notte gli interessi hanno fatto il loro lavoro.\nDebito: {debt}."])
