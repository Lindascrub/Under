extends Room
## La Banca Fiducia (si apre dal terzo giorno), in fondo al mercato. Qui c'è il tuo debito.
## Come il mercato, cambia aspetto con il mondo:
##   capitalismo -> marmo e palme, l'impiegato è immobile come un robot
##   comunismo   -> la coda con i numeri, timbri, moduli
##   baratto     -> occupata: il caveau è aperto, i registri dei debiti sono a terra

const RB := "tiles/room_builder.png"

var look := ""


func build() -> void:
	look = GameState.world_look()
	floor_id = "-2"
	music = "ufficio"
	var floor_def := {"tex": RB, "at": func(c: Vector2i) -> Vector2i: return Vector2i(38 + c.x % 3, 11 + c.y % 2)}
	var wall := Vector2i(22, 11) if look == "capitalismo" else Vector2i(1, 13)
	var rows: Array = ["##################", "#WWWWWWWWWWWWWWWW#", "#wwwwwwwwwwwwwwww#"]
	for i in 8:
		rows.append("#................#")
	rows.append("#######..#########")
	rows.append("#######dd#########")
	paint(rows, {
		"#": {"tex": RB, "at": Vector2i(12, 0), "solid": true},
		"W": {"tex": RB, "at": wall, "solid": true},
		"w": {"tex": RB, "at": wall + Vector2i(0, 1), "solid": true},
		".": floor_def,
		"_floor": floor_def,
	})
	for x in range(5, 13):
		add_prop("props/office_desk.png", Vector2i(x, 5))
	add_prop("props/portrait.png", Vector2i(3, 2), 0, Vector2i(16, 32), [
		"* Il ritratto del Presidente della banca. Sotto: \"Fondatore, garante, amico di tutti i debitori\".",
		"* Ha qualcosa di familiare. Il naso, forse. O lo sguardo stanco.",
	])
	add_badge_machine(Vector2i(13, 3))
	add_stairs_up(Vector2i(15, 3), Router.OFFICE, "from_below", "0")
	add_prop("props/terminal.png", Vector2i(4, 3), 1, Vector2i(16, 32), [
		"* Un bancomat. Sullo schermo: \"Saldo disponibile: insufficiente. Le auguriamo una buona giornata\".",
	])
	add_exit(Rect2i(7, 12, 2, 1), Router.MERCATO, "banca")

	var teller := AnimatedSprite2D.new()
	teller.sprite_frames = Assets.character("char_04")
	teller.centered = false
	teller.offset = Vector2(-8, -42)
	teller.position = cell_feet(Vector2i(8, 4))
	teller.play("idle_down")
	if look == "capitalismo":
		teller.speed_scale = 0.0
	teller.visible = look != "baratto" or GameState.barter_level() == "pochi"
	world.add_child(teller)
	block(Rect2i(8, 4, 1, 1))
	add_spot(cell_center(Vector2i(8, 5)), _teller)

	match look:
		"capitalismo":
			add_prop("props/palm.png", Vector2i(1, 4), 1, Vector2i(32, 32))
			add_prop("props/palm.png", Vector2i(15, 9), 1, Vector2i(32, 32))
			examine(cell_center(Vector2i(10, 3)), ["* Una scritta d'oro sul muro: \"IL SUO DEBITO È IL NOSTRO VALORE\"."])
		"baratto":
			for c in [Vector2i(4, 8), Vector2i(11, 9), Vector2i(13, 7), Vector2i(6, 10)]:
				add_prop("street/cardboard.png", c, 0, Vector2i(16, 16), ["* Fogli strappati. Sono contratti di prestito, con le firme cancellate."])
			examine(cell_center(Vector2i(14, 8)), [
				"* Il caveau è aperto. Dentro non ci sono soldi: solo registri di debiti, mezzi bruciati.",
				"* Qualcuno ha scritto sulla porta: \"IL DEBITO ERA UNA STORIA. L'ABBIAMO FINITA\".",
			])
			_static("char_19", Vector2i(10, 8), "idle_left")
			_static("char_20", Vector2i(5, 9), "idle_right")
		_:
			examine(cell_center(Vector2i(14, 9)), ["* Il distributore dei numeri. Prendi il tuo: 4.512. Sul display: \"Stiamo servendo il numero 12\"."])
			for i in 4:
				_static(["char_13", "char_18", "char_14", "char_15"][i], Vector2i(10, 6 + i), "idle_up", true)

	spawns["default"] = cell_feet(Vector2i(8, 10))
	spawns["mercato"] = spawns["default"]
	spawns["from_above"] = cell_feet(Vector2i(15, 5))
	spawn_facing["from_above"] = "down"
	spawn_facing["default"] = "up"


func enter() -> void:
	var key := "banca_intro_" + look
	if not GameState.flags.get(key, false):
		GameState.flags[key] = true
		match look:
			"capitalismo":
				await Ui.say(["* La Banca Fiducia. Marmo, palme, silenzio. Tutto brilla.", "* L'impiegato allo sportello non sbatte le palpebre."])
			"baratto":
				await Ui.say(["* La Banca Fiducia. O quello che ne resta: la gente ci è entrata e non se n'è più andata.", "* Sul muro qualcuno ha scritto in rosso: OCCUPATA."])
			_:
				await Ui.say(["* La Banca Fiducia. Una coda, un distributore di numeri, un timbro che batte sempre allo stesso ritmo."])
	await show_pending()


func _teller() -> void:
	var who := "Signor Tasso"
	if look == "baratto" and GameState.barter_level() != "pochi":
		await Ui.say(["* Lo sportello è vuoto. Sul bancone c'è un biglietto: \"Torno quando torneranno i soldi. Cioè mai\"."])
		return
	if look == "capitalismo":
		await Ui.say(["Benvenuto, {rank}. Il suo debito è il nostro valore."], who)
	else:
		await Ui.say(["Buongiorno. Numero? Ah, lei. Il conto del padre."], who)
	if not GameState.flags.get("father_account", false):
		GameState.flags["father_account"] = true
		await Ui.say([
			"Il conto di suo padre è stato aperto qui vent'anni fa. Garante: il Presidente in persona.",
			"Strano, vero? Il Presidente non fa mai da garante a nessuno. Solo a lui.",
			"Il Presidente sta all'ultimo piano della torre. Ma chi ci arriva, di solito, non torna giù uguale.",
		], who)
	if GameState.debt <= 0:
		await Ui.say(["Il suo debito è estinto. Congratulazioni. Si sente libero? Di solito nessuno si sente libero."], who)
		return
	var options: Array = []
	var amounts: Array[int] = []
	var minimum := mini(GameState.MIN_PAYMENT, GameState.debt)
	if GameState.money >= minimum:
		options.append("Paga la rata (%s)" % GameState.euros(minimum))
		amounts.append(minimum)
	var all_you_can := mini(GameState.money, GameState.debt)
	if all_you_can > minimum:
		options.append("Paga tutto quello che puoi (%s)" % GameState.euros(all_you_can))
		amounts.append(all_you_can)
	options.append("Niente, grazie")
	amounts.append(0)
	var i: int = await Ui.choose("Debito: {debt}. Vuole pagare qualcosa adesso?", options, who)
	if amounts[i] > 0:
		GameState.pay_debt(amounts[i])
		Sound.sfx("coin")
		GameState.flags["paid_at_bank_day"] = GameState.day
		await Ui.say(["Grazie. Debito residuo: {debt}. Gli interessi la ringraziano."], who)


func _static(sheet: String, cell: Vector2i, anim: String, keep := false) -> void:
	var p := AnimatedSprite2D.new()
	p.sprite_frames = Assets.character(sheet)
	p.centered = false
	p.offset = Vector2(-8, -31)
	cell = free_cell(cell, keep)
	p.position = cell_feet(cell)
	p.play(anim)
	world.add_child(p)
	block(Rect2i(cell, Vector2i.ONE))
