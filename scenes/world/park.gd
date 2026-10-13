extends Room
## Il parco in cima alla via laterale. L'unico posto della città che la CHEAP non ha ancora comprato.
## Di sera, se il giocatore ha rifiutato il lavoro, qui si tiene il mercato del baratto.

const CITY := "tiles/city_terrains.png"
const TERRAINS := "tiles/terrains.png"
const W := 30
const H := 20


func build() -> void:
	music = "quartiere"
	outdoor = true
	var rows: Array = []
	for y in H:
		var row := ""
		for x in W:
			var ch := "g"
			var path_v := x >= 13 and x <= 16 and y >= 8
			var path_h := y >= 12 and y <= 13 and x >= 3 and x <= 26
			var ring := x >= 11 and x <= 18 and y >= 7 and y <= 14
			if path_v or path_h or ring:
				ch = "p"
			row += ch
		rows.append(row)
	var path := {"tex": CITY, "at": func(c: Vector2i) -> Vector2i: return Vector2i(9 + c.x % 4, c.y % 4)}
	paint(rows, {
		"g": {"tex": TERRAINS, "at": func(c: Vector2i) -> Vector2i: return Vector2i(1, 7) if (c.x * 3 + c.y * 7) % 5 else Vector2i(1, 12)},
		"p": path,
		"_floor": path,
	})
	block(Rect2i(-1, 0, 1, H))
	block(Rect2i(W, 0, 1, H))
	block(Rect2i(0, -1, W, 1))
	block(Rect2i(0, H, 13, 1))
	block(Rect2i(17, H, 13, 1))
	add_exit(Rect2i(13, H - 1, 4, 1), Router.STREET, "park")

	add_prop("park/angel.png", Vector2i(12, 5), 2, Vector2i(80, 112), [
		"* La statua di un angelo. Sulla base c'è scritto: \"Donata dai cittadini, 1952\".",
		"* Sotto, più piccolo e più recente: \"Proprietà CHEAP S.p.A.\"",
	])
	add_prop("park/fountain.png", Vector2i(14, 11), 2, Vector2i(32, 48), [
		"* Una fontana. Nell'acqua ci sono tante monetine. Desideri di gente che non poteva permettersi di sprecarle.",
	])
	for c in [Vector2i(1, 3), Vector2i(5, 2), Vector2i(23, 2), Vector2i(27, 3), Vector2i(1, 9), Vector2i(27, 9),
			Vector2i(2, 17), Vector2i(7, 18), Vector2i(21, 18), Vector2i(26, 17)]:
		add_prop("street/tree.png" if (c.x + c.y) % 2 else "street/tree_round.png", c, 1, Vector2i(32, 48), [
			"* Un albero. Gli unici che qui crescono senza chiedere niente a nessuno.",
		])
	for c in [Vector2i(9, 4), Vector2i(19, 4), Vector2i(4, 15), Vector2i(24, 15), Vector2i(10, 17), Vector2i(19, 17)]:
		add_prop("park/bush.png" if c.x % 2 else "park/bush_2.png", c, 1, Vector2i(16, 16))
	for c in [Vector2i(6, 6), Vector2i(7, 6), Vector2i(22, 6), Vector2i(23, 6)]:
		add_prop("park/sunflower.png", c, 1, Vector2i(16, 32), ["* Un girasole. Si gira sempre verso il sole, anche quando il sole non c'è."])
	for c in [Vector2i(5, 11), Vector2i(23, 11), Vector2i(9, 15), Vector2i(19, 15)]:
		add_prop("park/bench.png", c, 0, Vector2i(32, 16), ["* Una panchina. Qualcuno ci ha inciso: \"Qui ci siamo baciati, 2009\"."])
		block_px(Rect2(c.x * T + 1, c.y * T + 6, 30, 9))
	for c in [Vector2i(10, 13), Vector2i(12, 15), Vector2i(20, 12)]:
		var pg := Pigeon.new()
		pg.position = cell_feet(c)
		world.add_child(pg)

	spawn_people("park")
	if GameState.minutes >= GameState.EVENING and GameState.refused >= 1:
		_barter_market()
	add_save_point(Vector2i(18, 16))

	spawns["default"] = cell_feet(Vector2i(14, 18))
	spawns["street"] = spawns["default"]
	spawn_facing["default"] = "up"


func enter() -> void:
	if not GameState.flags.get("park_intro", false):
		GameState.flags["park_intro"] = true
		await Ui.say(["* Il parco. Si sente l'acqua della fontana e, per una volta, nessun clacson."])
	await show_pending()


## Di sera, se hai già detto di no alla CHEAP, qualcuno ti invita al mercato del baratto.
func _barter_market() -> void:
	for c: Array in [[Vector2i(6, 13), "char_19"], [Vector2i(8, 12), "char_20"], [Vector2i(21, 13), "char_14"]]:
		var p := AnimatedSprite2D.new()
		p.sprite_frames = Assets.character(c[1])
		p.centered = false
		p.offset = Vector2(-8, -31)
		p.position = cell_feet(c[0])
		p.play("idle_down")
		world.add_child(p)
	examine(cell_center(Vector2i(7, 12)), [
		"* Un piccolo mercato su una coperta: pane, viti, libri usati, una radio rotta.",
		"* Un cartello scritto a mano: \"Qui niente soldi. Si scambia quello che si ha.\"",
		"* Una signora ti sorride: \"Non hai niente da scambiare? Allora scambia due chiacchiere.\"",
	])
