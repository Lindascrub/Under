extends Room
## La Cima: la Presidenza. Il giocatore sale per trovare il responsabile di tutto,
## e in cima non c'è nessun cattivo: c'è tuo padre, che ha già tutto e non sa cosa farne,
## bloccato quanto te. Si apre dal LV 4 oppure dal quarto giorno.

const RB := "tiles/room_builder.png"

var _president: AnimatedSprite2D


func build() -> void:
	floor_id = "cima"
	music = "presidente"
	var floor_def := {"tex": RB, "at": func(c: Vector2i) -> Vector2i: return Vector2i(42 + c.x % 3, 19 + c.y % 2)}
	var rows: Array = ["##############", "#WWWWWWWWWWWW#", "#wwwwwwwwwwww#"]
	for i in 6:
		rows.append("#............#")
	rows.append("##############")
	paint(rows, {
		"#": {"tex": RB, "at": Vector2i(12, 0), "solid": true},
		"W": {"tex": RB, "at": Vector2i(22, 11), "solid": true},
		"w": {"tex": RB, "at": Vector2i(22, 12), "solid": true},
		".": floor_def,
		"_floor": floor_def,
	})
	var frame := ColorRect.new()
	frame.color = Color("1a1420")
	frame.position = Vector2(2 * T, T + 2)
	frame.size = Vector2(10 * T, 2 * T - 4)
	world.add_child(frame)
	var sky := ColorRect.new()
	sky.color = Color("f0a868")
	sky.position = frame.position + Vector2(3, 3)
	sky.size = frame.size - Vector2(6, 6)
	world.add_child(sky)
	examine(cell_center(Vector2i(4, 3)), [
		"* Da quassù si vede tutto: la torre, il quartiere, il parco, la tua finestra.",
		"* Non si vede nessuno. Le persone, da qui, non esistono.",
	])
	add_prop("props/office_chair.png", Vector2i(9, 4), 0, Vector2i(16, 32))

	_president = AnimatedSprite2D.new()
	var president := _president
	president.sprite_frames = Assets.character("char_19")
	president.centered = false
	president.offset = Vector2(-8, -31)
	president.position = cell_feet(Vector2i(7, 3))
	president.play("idle_up")
	world.add_child(president)
	block(Rect2i(7, 3, 1, 1))
	add_spot(cell_center(Vector2i(7, 4)), _talk)

	add_stairs_down(Vector2i(11, 8), Router.BOSS, "from_above")
	spawns["default"] = cell_feet(Vector2i(10, 7))
	spawns["stairs"] = spawns["default"]
	spawns["from_below"] = spawns["default"]
	spawn_facing["default"] = "up"
	spawn_facing["from_below"] = "left"


func enter() -> void:
	if not GameState.flags.get("president_intro", false):
		GameState.flags["president_intro"] = true
		await Ui.say([
			"* L'ultimo piano. Nessuna segretaria, nessun quadro. Solo una finestra enorme.",
			"* Un uomo ti dà le spalle. Guarda la città.",
		])
	await show_pending()


func _talk() -> void:
	if GameState.flags.get("president_done", false):
		await Ui.say(["...Sei ancora qui? Nessuno resta mai, qui sopra.", "Nemmeno io, a dire il vero. Io ci sono solo."], "Papà")
		Router.goto(Router.ENDING, "", ["Sei arrivato in cima.", "E adesso?"])
		return
	await Ui.say([
		"Lo so perché sei salito. Tutti salgono per trovare chi comanda.",
		"Il capo si lamenta di me. Io mi lamentavo di quelli sopra di me. Poi sono arrivato in cima, e sopra non c'era nessuno.",
	], "Il Presidente")
	_president.play("idle_down")
	Sound.sfx("glitch", 0.5)
	await Ui.say(["* L'uomo si gira.", "* Lo riconosci prima ancora di vederlo bene."])
	GameState.flags["father_met"] = true
	await Ui.say([
		"Ciao. Sono io.",
		"Non sono sparito. Sono salito.",
		"Avevo perso tutto. Per riprendermelo ho fatto quello che la torre voleva: una firma alla volta. Proprio come te.",
		"Il debito che ti ho lasciato è con la mia banca. Cioè con me. Cioè con nessuno: è solo un numero in un cassetto.",
		"Ho comprato tutto. Non so cosa farne. Non è mai abbastanza, e non so nemmeno abbastanza per cosa.",
	], "Papà")
	var c: int = await Ui.choose("Cosa fai?", [
		"Chiedigli di cancellare il debito",
		"Siediti accanto a lui (1 ora)",
		"Vattene",
	], "Papà")
	match c:
		0:
			GameState.flags["president_done"] = true
			GameState.debt = 0
			GameState.changed.emit()
			Sound.sfx("stamp")
			await Ui.say([
				"Va bene. Tieni. È solo carta.",
				"* Tuo padre strappa un foglio. Il tuo debito non esiste più.",
				"Ecco. Ora sei come me: non devi niente a nessuno. E nessuno è più qui con te.",
			], "Papà")
		1:
			GameState.flags["president_done"] = true
			GameState.flags["sat_with_president"] = true
			GameState.spend(60)
			await Ui.say([
				"* Ti siedi accanto a lui. Per un'ora guardate la città senza dire niente.",
				"Nessuno si era mai seduto qui. Venivano tutti a chiedere qualcosa. Anche io, da te, ho solo preso.",
				"Sai cosa mi manca? Il tempo. L'ho venduto tutto, un'ora alla volta, e coi soldi non si ricompra.",
				"Non fare come me. Ti prego.",
			], "Papà")
		_:
			GameState.flags["president_done"] = true
			await Ui.say(["Fai bene. Qui sopra non c'è niente da vedere. Neanche io."], "Papà")
	# in cima non c'è altro da fare: il tuo finale
	await get_tree().create_timer(0.8).timeout
	Router.goto(Router.ENDING, "", ["Sei arrivato in cima.", "E adesso?"])
