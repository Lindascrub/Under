extends Room
## La strada del quartiere: casa a sinistra, CHEAP S.p.A. a destra, le persone in mezzo.

const CITY := "tiles/city_terrains.png"
const BUILDINGS := "tiles/generic_buildings.png"
const BUILDINGS_SIZE := Vector2i(512, 3200)
const HOUSE_REGION := Rect2(368, 400, 96, 288)
const TOWER_REGION := Rect2(240, 402, 112, 286)

const W := 40
const H := 16


func build() -> void:
	var rows: Array = []
	for y in H:
		var row := ""
		for x in W:
			var ch := "s"
			if y == 10:
				ch = "R"
			elif y > 10 and y < 14:
				ch = "r"
			if y >= 10 and y < 14 and (x == 19 or x == 20):
				ch = "z"
			if y == H - 1 or x == 0 or x == W - 1:
				ch = "x"
			row += ch
		rows.append(row)
	var sidewalk := {"tex": CITY, "at": Vector2i(10, 2)}
	paint(rows, {
		"s": sidewalk,
		"x": {"tex": CITY, "at": Vector2i(10, 2), "solid": true},
		"R": {"tex": CITY, "at": Vector2i(2, 8)},
		"r": {"tex": CITY, "at": Vector2i(2, 5)},
		"z": {"tex": CITY, "at": Vector2i(6, 6)},
		"_floor": sidewalk,
	})
	camera_top = 48

	_building(HOUSE_REGION, 3)
	_building(HOUSE_REGION, 12)
	_building(TOWER_REGION, 27)
	_sign("CHEAP S.p.A.", Vector2(27 * T + 56, 7 * T - 40))

	add_spot(Vector2(3 * T + 48, 7 * T - 4), func() -> void: Router.goto(Router.HOME, "street"))
	add_spot(Vector2(27 * T + 56, 7 * T - 4), func() -> void: Router.goto(Router.OFFICE, "street"))
	add_spot(Vector2(12 * T + 48, 7 * T - 4), _closed_door)

	add_npc("portiere_ivo", Vector2i(9, 8))
	add_npc("marta", Vector2i(15, 9), "left")
	add_npc("sig_bruno", Vector2i(17, 7))
	add_npc("nico", Vector2i(22, 8))
	add_npc("lea", Vector2i(25, 9), "left")
	add_npc("ragazzo_sami", Vector2i(21, 14), "up")

	spawns["default"] = cell_feet(Vector2i(6, 8))
	spawns["home"] = spawns["default"]
	spawns["office"] = cell_feet(Vector2i(30, 8))


func enter() -> void:
	if not GameState.flags.get("street_intro", false):
		GameState.flags["street_intro"] = true
		await Ui.say(["* La tua strada. La CHEAP S.p.A. è la torre in fondo a destra."])
	await show_pending()


func _closed_door() -> void:
	await Ui.say(["* Il portone è chiuso. Sul citofono metà dei nomi sono stati cancellati."])


func _building(region: Rect2, x: int) -> void:
	add_region(BUILDINGS, BUILDINGS_SIZE, region, Vector2i(x, 6))
	block(Rect2i(x, 0, int(region.size.x / T), 7))


func _sign(text: String, center: Vector2) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", Color("ffe14d"))
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.position = center - Vector2(30, 6)
	l.size = Vector2(60, 12)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 5
	add_child(l)
