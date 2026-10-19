extends Room
## L'ultimo piano della torre: l'ufficio del Dottor Prezzi, il Capo.
## Si sblocca col grado di Supervisore. Il Capo ti offre "incarichi extra": promuovere qualcuno al posto suo.

const RB := "tiles/room_builder.png"

var _boss: AnimatedSprite2D


func build() -> void:
	floor_id = "cima"
	music = "ufficio"
	var floor_def := {"tex": RB, "at": func(c: Vector2i) -> Vector2i: return Vector2i(42 + c.x % 3, 19 + c.y % 2)}
	paint([
		"##################",
		"#WWWWWWWWWWWWWWWW#",
		"#wwwwwwwwwwwwwwww#",
		"#................#",
		"#................#",
		"#................#",
		"#................#",
		"#................#",
		"#................#",
		"##################",
	], {
		"#": {"tex": RB, "at": Vector2i(12, 0), "solid": true},
		"W": {"tex": RB, "at": Vector2i(22, 11), "solid": true},
		"w": {"tex": RB, "at": Vector2i(22, 12), "solid": true},
		".": floor_def,
		"_floor": floor_def,
	})
	var frame := ColorRect.new()
	frame.color = Color("1a1420")
	frame.position = Vector2(10 * T, T + 2)
	frame.size = Vector2(5 * T, 2 * T - 4)
	add_child(frame)
	move_child(frame, world.get_index())
	var sky := ColorRect.new()
	sky.color = Color("8ec5ff")
	sky.position = frame.position + Vector2(3, 3)
	sky.size = frame.size - Vector2(6, 6)
	add_child(sky)
	move_child(sky, world.get_index())
	examine(cell_center(Vector2i(12, 3)), [
		"* Dalla finestra si vede tutta la città. Da quassù le persone sembrano formiche.",
		"* Da quassù è facile dimenticare che non lo sono.",
	])
	add_prop("props/portrait.png", Vector2i(5, 2), 0, Vector2i(16, 32), [
		"* Il ritratto del Dottor Prezzi. È identico a lui.",
		"* È identico anche al ritratto del fondatore che c'è al piano di sotto. Quello è del 1952.",
	])
	add_prop("props/palm.png", Vector2i(1, 3), 1, Vector2i(32, 32))
	add_prop("props/palm.png", Vector2i(15, 7), 1, Vector2i(32, 32))
	add_computer_desk(Vector2i(8, 6))
	add_computer_desk(Vector2i(9, 6))
	add_prop("props/computer.png", Vector2i(10, 6))

	_boss = AnimatedSprite2D.new()
	_boss.sprite_frames = Assets.character("char_18")
	_boss.centered = false
	_boss.offset = Vector2(-8, -31)
	_boss.position = cell_feet(Vector2i(9, 4))
	_boss.play("idle_down")
	world.add_child(_boss)
	block(Rect2i(9, 4, 1, 1))
	add_spot(cell_center(Vector2i(9, 5)), _talk)

	# L'ascensore per tornare giù.
	var lift := ColorRect.new()
	lift.color = Color("aeb4c4")
	lift.position = Vector2(2 * T, 8 * T + 4)
	lift.size = Vector2(2 * T, T - 4)
	lift.z_index = -1
	add_child(lift)
	add_exit(Rect2i(2, 9, 2, 1), Router.OFFICE, "elevator")
	block(Rect2i(0, 9, 2, 1))
	block(Rect2i(4, 9, 14, 1))

	# Le scale per la Presidenza, contro il muro: lassù c'è papà
	add_stairs_up(Vector2i(15, 3), Router.PRESIDENCY, "from_below", "cima")
	examine(cell_center(Vector2i(14, 4)), ["* Le scale per la Presidenza. Dall'alto arriva un silenzio che costa caro."])
	spawns["stairs"] = cell_feet(Vector2i(15, 5))
	spawns["from_above"] = spawns["stairs"]
	spawn_facing["from_above"] = "down"
	spawns["default"] = cell_feet(Vector2i(3, 7))
	spawns["elevator"] = spawns["default"]
	spawn_facing["default"] = "up"


func enter() -> void:
	if not GameState.flags.get("boss_intro", false):
		GameState.flags["boss_intro"] = true
		await Ui.say([
			"Ah! Il nostro nuovo {rank}. Venga, venga. Io sono il Dottor Prezzi.",
			"Ho visto i suoi numeri. Lei ha talento: firma senza esitare. È raro, sa?",
			"Quando vuole un incarico extra, venga pure da me. La porta è sempre aperta. Per chi ha il badge.",
		], "Dottor Prezzi")
	await show_pending()


func _talk() -> void:
	# Anche il capo si lamenta del suo capo: in questo mondo tutti si lamentano di quelli sopra.
	var lines := [
		"Ogni persona ha un prezzo, {rank}. Il nostro lavoro è scoprirlo prima di lei.
Il mio prezzo? Lo decide il Presidente. Sempre troppo basso.",
		"Sa qual è il segreto del successo? Non guardare mai in basso.
E non guardare mai in alto, se no vedi il Presidente che ti guarda.",
		"I sentimenti sono un costo. E i costi si tagliano.
Lo dice il Presidente. Io eseguo. Anche io ho un capo, sa? Tutti hanno un capo.",
		"Lavoro qui da trent'anni. Ho tutto. Non ho mai tempo di usarlo.
Ma il Presidente dice che sto andando benissimo.",
	]
	await Ui.say([lines[GameState.day % lines.size()]], "Dottor Prezzi")
	if GameState.flags.get("boss_job_day", 0) == GameState.day:
		await Ui.say(["Per oggi basta così. Non vorrei che si stancasse. Lei è un investimento."], "Dottor Prezzi")
		return
	var victim := _pick_victim()
	if victim == "":
		await Ui.say(["Non c'è più nessuno da promuovere. Che splendida efficienza."], "Dottor Prezzi")
		return
	var who := str(GameState.npc_data(victim).get("name", victim))
	var c: int = await Ui.choose("%s ha un'idea che vale oro e non lo sa. Se la presenta lei, il merito è suo. (+%s)" % [who, GameState.euros(GameState.easy_pay())],
		["Accetta", "Non oggi"], "Dottor Prezzi")
	if c != 0:
		await Ui.say(["Peccato. L'esitazione è un lusso per chi non ha debiti."], "Dottor Prezzi")
		return
	GameState.flags["boss_job_day"] = GameState.day
	var promo := GameState.promotion(victim)
	if promo.is_empty():
		promo = {"title": "L'idea di " + who, "item": "il quaderno di " + who}
	start_steal(victim, promo)


func _pick_victim() -> String:
	var ids: Array = []
	for id: String in GameState.npc_ids():
		if id != "nico" and not GameState.is_robot(id):
			ids.append(id)
	return "" if ids.is_empty() else str(ids[GameState.day % ids.size()])


func _stairs() -> void:
	if GameState.lv() < 4 and not GameState.has_badge("cima"):
		await Ui.say(["* Una scala stretta che sale verso la Presidenza.", "* Una catenella e un cartello: \"Solo LV 4 e superiori. Oppure su invito\"."])
		return
	Router.goto(Router.PRESIDENCY, "stairs")
