extends Room
## La strada del quartiere: casa a sinistra, il chiosco di Nico, la torre della CHEAP a destra.
## Le persone cambiano posto e attività ogni giorno (data/npcs.json -> "schedule").

const CITY := "tiles/city_terrains.png"
const W := 64
const H := 19
## Riga su cui poggiano gli edifici (il loro bordo inferiore).
const BASE := 7


func build() -> void:
	music = "quartiere"
	outdoor = true
	camera_top = 64
	_paint_ground()

	# Edifici, da sinistra a destra.
	_building("buildings/home.png", 1, Vector2i(112, 288))
	_building("buildings/condo_blue.png", 9, Vector2i(96, 176))
	_building("buildings/condo_dirty.png", 16, Vector2i(96, 192))
	_building("buildings/condo_yellow.png", 28, Vector2i(96, 176))
	_building("street/coffee_kiosk.png", 35, Vector2i(96, 144))
	_building("buildings/cheap_tower.png", 42, Vector2i(224, 288), Rect2(0, 0, 224, 288))
	_building("street/billboard.png", 57, Vector2i(80, 96))
	_art("res://art/cheap_sign.png", Vector2(42 * T + 54, (BASE + 1) * T - 288 + 244))
	_art("res://art/billboard_ad.png", Vector2(57 * T + 6, (BASE + 1) * T - 96 + 17))
	for gap in [0, 8, 15, 22, 27, 34, 41, 56, 62, 63]:
		block(Rect2i(gap, 0, 1, BASE + 1))
	block(Rect2i(23, 0, 4, 1))

	# Porte
	add_spot(Vector2(1 * T + 56, (BASE + 1) * T - 2), func() -> void: Router.goto(Router.HOME, "street"))
	add_spot(Vector2(42 * T + 104, (BASE + 1) * T - 2), func() -> void: Router.goto(Router.OFFICE, "street"))
	examine(Vector2(9 * T + 48, (BASE + 1) * T - 2), ["* Il portone è chiuso. Sul citofono metà dei nomi sono stati cancellati con il pennarello."])
	examine(Vector2(28 * T + 48, (BASE + 1) * T - 2), ["* \"Vendesi. Rivolgersi a CHEAP Immobiliare.\" Il cartello è più nuovo del palazzo."])
	examine(Vector2(16 * T + 48, (BASE + 1) * T - 2), ["* Un cortile pieno di spazzatura. Un gatto nero ti fissa come se sapesse qualcosa che tu non sai."])
	examine(Vector2(35 * T + 48, (BASE + 1) * T - 2), ["* Il chiosco di Nico, a forma di tazza gigante.", "* Sul bancone c'è un cartello scritto a mano: \"Si accettano anche sorrisi\"."])
	examine(Vector2(57 * T + 40, (BASE + 1) * T - 2), ["* Il cartellone dice: CHEAP - SORRIDI!", "* Qualcuno ha aggiunto sotto, a pennarello: \"...e paga\"."])

	_props()
	spawn_people("street")

	spawns["default"] = cell_feet(Vector2i(4, 9))
	spawns["home"] = spawns["default"]
	spawns["office"] = cell_feet(Vector2i(48, 9))


func enter() -> void:
	if not GameState.flags.get("street_intro", false):
		GameState.flags["street_intro"] = true
		await Ui.say(["* La tua strada. La torre della CHEAP S.p.A. è in fondo a destra, dopo il chiosco del caffè."])
	await show_pending()


func _paint_ground() -> void:
	var rows: Array = []
	for y in H:
		var row := ""
		for x in W:
			var ch := "s"
			if y == 11:
				ch = "C"
			elif y >= 12 and y <= 14:
				ch = "d" if y == 13 and x % 3 == 1 else "r"
			if x >= 23 and x <= 26 and y <= 10:
				ch = "v" if y >= 8 else "r"
			if x >= 44 and x <= 45 and y >= 11 and y <= 14:
				ch = "h"
			row += ch
		rows.append(row)
	var sidewalk := {"tex": CITY, "at": func(c: Vector2i) -> Vector2i: return Vector2i(9 + c.x % 4, c.y % 4)}
	paint(rows, {
		"s": sidewalk,
		"C": {"tex": CITY, "at": Vector2i(1, 3)},
		"r": {"tex": CITY, "at": func(c: Vector2i) -> Vector2i: return Vector2i(1 + (c.x * 7 + c.y * 3) % 4, 4 + (c.x + c.y * 5) % 4)},
		"d": {"tex": CITY, "at": Vector2i(10, 5)},
		"v": {"tex": CITY, "at": func(c: Vector2i) -> Vector2i: return Vector2i(7 + c.x % 2, 6 + c.y % 2)},
		"h": {"tex": CITY, "at": func(c: Vector2i) -> Vector2i: return Vector2i(7 + c.x % 2, 4 + c.y % 2)},
		"_floor": sidewalk,
	})
	# Bordi invisibili: la strada continua oltre lo schermo, ma non si può uscire.
	block(Rect2i(-1, 0, 1, H))
	block(Rect2i(W, 0, 1, H))
	block(Rect2i(0, H - 1, W, 1))


func _props() -> void:
	for x in [6, 19, 31, 52, 60]:
		add_prop("street/lamp.png", Vector2i(x, 8), 1, Vector2i(32, 64), [
			"* Un lampione. Di notte illumina solo metà strada: l'altra metà \"è in attesa di fondi\".",
		])
	add_prop("street/bench_side.png", Vector2i(12, 10), 3, Vector2i(16, 48), [
		"* La panchina del signor Bruno. Nessuno ci si siede, quando c'è lui: è una questione di rispetto.",
	])
	add_prop("street/pigeon_1.png", Vector2i(14, 10), 0, Vector2i(16, 16), ["* Un piccione. Ti guarda come se gli dovessi dei soldi."])
	add_prop("street/pigeon_2.png", Vector2i(13, 8), 0, Vector2i(16, 16), ["* Un altro piccione. Questo sembra Ernesto, quello zoppo."])
	add_prop("street/bench_side.png", Vector2i(34, 17), 3, Vector2i(16, 48))
	add_spot(cell_center(Vector2i(35, 16)), _rest)
	add_prop("street/trash_pile_1.png", Vector2i(17, 10), 1, Vector2i(64, 32), [
		"* Spazzatura che nessuno passa a ritirare. Il servizio è stato \"ottimizzato\" dalla CHEAP.",
	])
	add_prop("street/cardboard.png", Vector2i(21, 9), 0, Vector2i(16, 16), ["* Un cartone schiacciato. Qualcuno ci ha dormito sopra."])
	add_prop("street/hydrant.png", Vector2i(22, 10), 1, Vector2i(16, 32), ["* Un idrante. È l'unica cosa gratis in tutta la strada: l'acqua. Per ora."])
	add_prop("street/trashbin.png", Vector2i(8, 7), 1, Vector2i(16, 32), [
		"* Un cestino. Dentro c'è un volantino della CHEAP: \"Il tuo futuro ci sta a cuore!\"",
	])
	add_prop("street/mailbox.png", Vector2i(27, 7), 1, Vector2i(16, 32), ["* Una cassetta delle lettere. Dentro c'è un'altra lettera della banca. Ovviamente."])
	add_prop("street/trashbin.png", Vector2i(41, 7), 1, Vector2i(16, 32), ["* Un cestino pieno di bicchieri del caffè di Nico. Quello buono."])
	add_prop("street/dumpster_graffiti.png", Vector2i(62, 7), 1, Vector2i(32, 32), [
		"* Un cassonetto. Sopra qualcuno ha scritto con lo spray: IL DEBITO È UNA CATENA.",
	])
	add_prop("street/car_wreck.png", Vector2i(23, 4), 2, Vector2i(64, 48), [
		"* Un'auto abbandonata. Sul parabrezza ci sono sette multe e un biglietto: \"Scusate, non posso pagare\".",
	])
	add_prop("street/trash_bags.png", Vector2i(25, 6), 1, Vector2i(32, 32), ["* Sacchi della spazzatura. Odorano di lunedì."])
	for x in [2, 10, 26, 40, 50, 58]:
		add_prop("street/tree.png", Vector2i(x, 18), 1, Vector2i(32, 48), ["* Un albero. Qualcuno ci ha inciso: \"M + figli, per sempre\"."])
	for x in [6, 14, 20, 30, 46, 54]:
		add_prop("street/flowers.png", Vector2i(x, 18), 1, Vector2i(32, 16), ["* Un'aiuola. I fiori sono finti, ma qualcuno li annaffia lo stesso."])


func _building(rel: String, x: int, size: Vector2i, region := Rect2()) -> void:
	var tex := Assets.tex(rel, size)
	var s := Sprite2D.new()
	if region.size != Vector2.ZERO:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = region
		s.texture = at
	else:
		s.texture = tex
	s.centered = false
	var h := s.texture.get_height()
	s.offset = Vector2(0, -h)
	s.position = Vector2(x * T, (BASE + 1) * T)
	world.add_child(s)
	block(Rect2i(x, 0, int(ceil(s.texture.get_width() / float(T))), BASE + 1))


func _art(path: String, pos: Vector2) -> void:
	if not ResourceLoader.exists(path):
		return
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = false
	s.position = pos
	s.z_index = 1
	add_child(s)


func _rest() -> void:
	if GameState.flags.get("rest_day", 0) == GameState.day:
		await Ui.say(["* Ti sei già riposato oggi. Se ti risiedi, non ti rialzi più."])
		return
	var c: int = await Ui.choose("Una panchina libera. Ti siedi un po'? (1 ora)", ["Siediti", "Lascia stare"])
	if c != 0:
		return
	GameState.flags["rest_day"] = GameState.day
	GameState.spend(GameState.COST_REST)
	GameState.restore(8)
	Sound.sfx("heal")
	await Ui.say(["* Ti siedi. Guardi la gente passare. Per un'ora non devi niente a nessuno.", "* Energia +8. Sono le {clock}."])
