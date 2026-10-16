extends Room
## Il Sottoufficio, al piano -4 della torre: il luogo stranamente sadico sopra al Fondo.
## Lo sportello del collocamento mostra la "lista dei lavori peggiori del mondo";
## qui ci sono i bagni e la sala del call center. Le scale salgono al Mercato (-3), la botola scende al Fondo.

const RB := "tiles/room_builder.png"


func build() -> void:
	floor_id = "-4"
	music = "sotto"
	var dark := {"tex": RB, "at": func(c: Vector2i) -> Vector2i: return Vector2i(46 + c.x % 3, 25 + c.y % 2)}
	var tiles := {"tex": RB, "at": func(c: Vector2i) -> Vector2i: return Vector2i(42 + c.x % 3, 25 + c.y % 2)}
	var rows: Array = ["########################", "#WWWWWWWWWWWWWWWWWWWWWW#", "#wwwwwwwwwwwwwwwwwwwwww#"]
	for y in 10:
		var row := "#"
		for x in range(1, 23):
			row += "b" if x >= 15 else "."
		rows.append(row + "#")
	rows.append("########################")
	paint(rows, {
		"#": {"tex": RB, "at": Vector2i(12, 0), "solid": true},
		"W": {"tex": RB, "at": Vector2i(23, 13), "solid": true},
		"w": {"tex": RB, "at": Vector2i(23, 14), "solid": true},
		".": dark,
		"b": tiles,
		"_floor": dark,
	})

	# Le scale per il Mercato (-3), il distributore dei badge, la botola per il Fondo (-5).
	add_stairs_up(Vector2i(2, 3), Router.MERCATO, "from_below", "-3")
	add_badge_machine(Vector2i(4, 3))
	add_stairs_down(Vector2i(1, 12), Router.FONDO, "from_above")

	# Lo sportello del collocamento
	add_computer_desk(Vector2i(6, 5))
	add_computer_desk(Vector2i(7, 5))
	var agenda := AnimatedSprite2D.new()
	agenda.sprite_frames = Assets.character("char_20")
	agenda.centered = false
	agenda.offset = Vector2(-8, -48)
	agenda.position = cell_feet(Vector2i(7, 4))
	agenda.play("idle_down")
	world.add_child(agenda)
	block(Rect2i(7, 4, 1, 1))
	add_spot(cell_center(Vector2i(7, 5)), _collocamento)

	# La sala del call center
	for x in [4, 5, 8, 9]:
		add_computer_desk(Vector2i(x, 10), ["* Una cuffia sudata e un copione: \"Grazie per la sua pazienza\"."])
	# i colleghi del call center, seduti dietro le scrivanie col telefono
	for c: Array in [[Vector2i(4, 8), "char_18"], [Vector2i(5, 8), "char_19"], [Vector2i(9, 8), "char_14"]]:
		var w := AnimatedSprite2D.new()
		w.sprite_frames = Assets.character(c[1])
		w.centered = false
		w.offset = Vector2(-8, -31)
		w.position = cell_feet(c[0])
		w.play("phone")
		world.add_child(w)
		block(Rect2i(c[0], Vector2i.ONE))
	examine(cell_center(Vector2i(4, 8)) + Vector2(0, 4), ["* \"Grazie per la sua pazienza. Grazie per la sua pazienza. Grazie per la sua pazienza.\"", "* Non ti guarda nemmeno."])

	# I bagni: due gabinetti e due lavandini, tutti contro il muro
	for x in [15, 17]:
		add_prop("bath/stall.png", Vector2i(x, 3), 2, Vector2i(32, 48), ["* Un bagno. Sulla porta qualcuno ha inciso: \"Anche io ero un sogno\"."])
	add_prop("bath/sink.png", Vector2i(19, 3), 2, Vector2i(32, 48), ["* Il lavandino. L'acqua calda è \"un benefit riservato ai dirigenti\"."])
	add_prop("bath/sink.png", Vector2i(21, 3), 2, Vector2i(32, 48))
	add_prop("bath/mop.png", Vector2i(16, 5), 1, Vector2i(16, 32))
	add_prop("bath/bucket.png", Vector2i(18, 5), 1, Vector2i(16, 32))
	add_prop("props/trash.png", Vector2i(15, 11), 2, Vector2i(16, 32), ["* Il cestino dei bagni. Meglio non guardare."])

	add_station("sottoufficio")
	spawn_people("sottoufficio")

	spawns["default"] = cell_feet(Vector2i(3, 11))
	spawns["from_below"] = spawns["default"]
	spawn_facing["default"] = "up"
	spawns["from_above"] = cell_feet(Vector2i(2, 5))
	spawn_facing["from_above"] = "down"


func enter() -> void:
	if not GameState.flags.get("sotto_intro", false):
		GameState.flags["sotto_intro"] = true
		await Ui.say([
			"* Il piano -4. Luci al neon che ronzano, un odore di candeggina e caffè freddo.",
			"* Sui muri, macchie di umidità a forma di grafici in discesa.",
			"* Allo sportello, una signora ti fa segno di avvicinarti. Sorride troppo.",
			"* Qui la luce c'è. Viene dalle cyclette di sotto. Nessuno, quassù, ci pensa.",
		])
	await show_pending()


func _board_lines() -> Array:
	var lines: Array = ["* LISTA DEI LAVORI PEGGIORI DEL MONDO (aggiornata ogni mattina):"]
	for j: Dictionary in GameState.jobs_available():
		lines.append("* - %s: %s." % [j["title"], j["where"]])
	lines.append("* In fondo, a matita: \"E il lavoro migliore? Non c'è. Non chiedere.\"")
	return lines


## Lo sportello: la Signora Agenda e la lista dei lavori peggiori del mondo.
func _collocamento() -> void:
	var who := "Signora Agenda"
	GameState.flags["met_agenda"] = true
	if not GameState.flags.get("agenda_intro", false):
		GameState.flags["agenda_intro"] = true
		await Ui.say([
			"Oh! Qualcuno che sale dal Fondo! {name}, vero? Ho già il tuo nome sul registro. Ce li ho tutti.",
			"Benvenuto al piano -4. Io sono la Signora Agenda.",
			"Qui distribuiamo il lavoro a chi ha un debito. Cioè a tutti.",
			"I bagni o il call center: scegli tu! Non è un obbligo, è un'opportunità. Che poi è la stessa cosa, ma detta meglio.",
			"Il badge per il Mercato costa 400. Te lo dico subito, così non ti illudi. Cioè: così ti motivi!",
		], who)
		return
	if GameState.worked_today:
		await Ui.say(["Per oggi hai già dato. Il debito non dorme mai, ma tu sì. Ogni tanto."], who)
		return
	var c: int = await Ui.choose("Dove vuoi lavorare oggi?", ["I bagni", "Il call center", "Da nessuna parte"], who)
	match c:
		0:
			await Ui.say(["I bagni! Ottima scelta. Il carrello è laggiù, dove c'è il punto esclamativo. Sorridi!"], who)
		1:
			await Ui.say(["Il call center! Ripeti dopo di me: \"Grazie per la sua pazienza\". Bravo. Ancora diecimila volte."], who)
		_:
			GameState.refuse_work()
			await Ui.say(["...Interessante. Lo segnerò. Lo segno sempre, sai.", "* Per la prima volta dopo tanto tempo, respiri."], who)


func _lift(top_left: Vector2i) -> void:
	var frame := ColorRect.new()
	frame.color = Color("4a4658")
	frame.position = Vector2(top_left.x * T, top_left.y * T + 4)
	frame.size = Vector2(2 * T, 2 * T - 4)
	world.add_child(frame)
	for k in 2:
		var door := ColorRect.new()
		door.color = Color("aeb4c4")
		door.position = frame.position + Vector2(2 + k * 15, 3)
		door.size = Vector2(13, frame.size.y - 3)
		world.add_child(door)


func _art(path: String, pos: Vector2) -> void:
	if not ResourceLoader.exists(path):
		return
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = false
	s.position = pos
	s.z_index = 1
	add_child(s)
