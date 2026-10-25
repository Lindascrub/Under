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
	if GameState.flags.get("c1_sbarrato", false):
		_barred_hole(Vector2i(1, 12))
	else:
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


## Le scale per il Fondo, chiuse alla buona: sei salito senza voltarti.
func _barred_hole(bottom_left: Vector2i) -> void:
	var s := add_region(GENERIC, GENERIC_SIZE, Rect2(STAIRS_REGION.position + Vector2(0, 16), Vector2(32, 48)), bottom_left)
	s.flip_v = true
	s.modulate = Color(0.45, 0.45, 0.5)
	world.remove_child(s)
	add_child(s)
	move_child(s, world.get_index())
	# coni e nastro, messi lì di fretta anni fa: uno è caduto e nessuno l'ha rialzato
	var base_y := (bottom_left.y - 2) * T + 8.0
	var xs := [bottom_left.x * T + 2.0, bottom_left.x * T + 30.0, bottom_left.x * T + 40.0]
	var tops: Array[Vector2] = []
	for k in 3:
		var cone := Sprite2D.new()
		cone.texture = preload("res://art/cone.png")
		cone.offset = Vector2(0, -8)
		cone.position = Vector2(xs[k], base_y)
		cone.z_index = 2
		if k == 2:
			# quello caduto, di traverso
			cone.rotation = 1.45
			cone.position += Vector2(6, 2)
			cone.modulate = Color(0.85, 0.85, 0.85)
		add_child(cone)
		tops.append(Vector2(xs[k], base_y - 14))
	# il nastro bianco e rosso: tra i primi due coni pende, poi casca a terra dove il cono è caduto
	var pts: Array[Vector2] = []
	for i in 9:
		var f := i / 8.0
		pts.append(tops[0].lerp(tops[1], f) + Vector2(0, sin(f * PI) * 5.0))
	for i in range(1, 7):
		var f := i / 6.0
		pts.append(tops[1].lerp(Vector2(xs[2] + 6, base_y - 2), f) + Vector2(0, sin(f * PI) * 3.0))
	for i in pts.size() - 1:
		var seg := Line2D.new()
		seg.points = PackedVector2Array([pts[i], pts[i + 1]])
		seg.width = 2.0
		seg.default_color = Color("d8302a") if i % 2 == 0 else Color("eeeae0")
		seg.z_index = 3
		add_child(seg)
	# il cartello appeso al nastro, storto
	var sign := Sprite2D.new()
	sign.texture = preload("res://art/sign_vietato.png")
	sign.position = tops[0].lerp(tops[1], 0.5) + Vector2(0, 8)
	sign.rotation = 0.14
	sign.z_index = 4
	add_child(sign)
	block(Rect2i(bottom_left.x, bottom_left.y - 2, 2, 3))
	examine(cell_center(bottom_left + Vector2i(0, -1)) + Vector2(8, 0), [
		"* Le scale per il Fondo. Tre coni e un nastro: VIETATO SCENDERE.",
		"* Il nastro è scolorito, un cono è caduto. Nessuno l'ha rialzato. Nessuno passa di qua a controllare.",
		"* Attaccato al nastro, un foglio: \"Lavori in corso\". La data è di quindici anni fa.",
		"* Sei salito senza voltarti. Il Fondo, adesso, resta là sotto. Con quello che non hai voluto sapere.",
	])


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
