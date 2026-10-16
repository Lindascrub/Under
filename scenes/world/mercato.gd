extends Room
## Il Mercato (si apre dal secondo giorno). È la stessa mappa per tutte le strade,
## ma cambia aspetto a seconda di come stai cambiando il mondo (GameState.world_look()):
##   capitalismo -> un'asta: saracinesche abbassate, il banditore, compratori grigi
##   comunismo   -> una coda: tutti in fila per una razione uguale per tutti
##   baratto     -> una piazza di scambi: teli, bancarelle, gente che si parla
## Qui ci sono anche il banco di Vito, il magazzino e la Banca.

const CITY := "tiles/city_terrains.png"
const W := 40
const H := 16

var look := ""


func build() -> void:
	look = GameState.world_look()
	floor_id = "-3"
	music = {"capitalismo": "asta", "baratto": "scambi"}.get(look, "razioni")
	camera_top = 96
	camera_lift = 40
	var rows: Array = []
	for y in H:
		rows.append("s".repeat(W))
	var sidewalk := {"tex": CITY, "at": func(c: Vector2i) -> Vector2i: return Vector2i(9 + c.x % 4, c.y % 4)}
	paint(rows, {"s": sidewalk, "_floor": sidewalk})
	block(Rect2i(-1, 0, 1, H))
	block(Rect2i(W, 0, 1, H))
	block(Rect2i(0, H, W, 1))
	block(Rect2i(0, -1, W, 1))

	# Negozi sullo sfondo e la Banca
	_building("market/shop_1.png", 1, Vector2i(80, 128))
	_building("market/shop_2.png", 7, Vector2i(80, 128))
	_building("market/shop_big.png", 13, Vector2i(112, 144))
	_building("market/kiosk.png", 21, Vector2i(112, 192))
	_building("market/shop_1.png", 29, Vector2i(80, 128))
	# sopra alla scritta MARKET del palazzo grande: è la banca
	_bank_plate(13, look == "baratto" and GameState.barter_level() != "pochi")
	add_spot(Vector2(13 * T + 56, 6 * T - 2), _bank_door)

	# Il magazzino, a destra
	for c in [Vector2i(33, 8), Vector2i(33, 11), Vector2i(35, 13)]:
		add_prop("market/box_%d.png" % [1, 2, 5, 1][(c.x + c.y) % 4], c, 2, Vector2i(32, 32), [
			"* Scatole della CHEAP. Su una c'è scritto: \"Fragile. Come chi la porta\".",
		])

	# Il banco della frutta (dove lavora Vito)
	add_prop("market/table_2.png", Vector2i(17, 11), 2, Vector2i(48, 32))

	match look:
		"capitalismo":
			_auction()
		"baratto":
			_barter()
		_:
			_queue()

	add_stairs_down(Vector2i(37, 8), Router.SOTTOUFFICIO, "from_above")
	add_badge_machine(Vector2i(12, 6))
	add_station("mercato")
	spawn_people("mercato")
	_shoppers()
	add_save_point(Vector2i(38, 14))

	spawns["default"] = cell_feet(Vector2i(36, 9))
	spawns["from_below"] = spawns["default"]
	spawn_facing["default"] = "left"
	spawns["banca"] = cell_feet(Vector2i(16, 7))
	spawn_facing["banca"] = "down"


func enter() -> void:
	var key := "mercato_intro_" + look
	if not GameState.flags.get(key, false):
		GameState.flags[key] = true
		match look:
			"capitalismo":
				await Ui.say(["* Il piano -3: un mercato sotto terra. Le saracinesche sono abbassate. Al centro c'è un'asta.", "* Si vende tutto al miglior offerente: banchi, case, persone. Quasi tutti hanno lo stesso sorriso."])
			"baratto":
				await Ui.say(["* Il piano -3: un mercato sotto terra. Niente cassa, niente prezzi: teli per terra e gente che si scambia le cose.", "* È disordinato. È rumoroso. È vivo."])
			_:
				await Ui.say(["* Il piano -3: un mercato sotto terra. C'è una coda lunghissima davanti al banco delle razioni.", "* Una razione a testa. Uguale per tutti. Nessuno si lamenta, nessuno sorride."])
	await show_pending()


# --- i tre aspetti -----------------------------------------------------------

func _auction() -> void:
	for x in [2, 8, 25, 30]:
		add_prop("market/shutter_%d.png" % (1 + x % 2), Vector2i(x, 9), 2, Vector2i(48, 48), [
			"* Una saracinesca abbassata. Sopra, un cartello: \"Acquisito da CHEAP S.p.A.\"",
		])
	add_prop("market/table_3.png", Vector2i(10, 12), 2, Vector2i(48, 48), [
		"* Il palco dell'asta. Sul banco c'è un martelletto d'oro e una lista di nomi.",
	])
	add_signpost("res://art/sign_asta.png", Vector2(8 * T + 8, 13 * T))
	_static("char_18", Vector2i(11, 11), "idle_down", false)
	for x in [9, 11, 13]:
		_static("char_19" if x % 2 else "char_20", Vector2i(x, 14), "idle_up", true)
	examine(cell_center(Vector2i(11, 11)), [
		"* \"Lotto numero 7: un banco di frutta, tre generazioni di storia! Chi offre di più?\"",
		"* I compratori alzano la mano tutti insieme, nello stesso momento.",
	])


func _queue() -> void:
	add_prop("market/table_1.png", Vector2i(26, 11), 2, Vector2i(48, 32), [
		"* Il banco delle razioni. Un timbro, una busta, avanti il prossimo.",
		"* Sulla busta c'è scritto: \"Razione standard. Come te\".",
	])
	add_signpost("res://art/sign_razioni.png", Vector2(31 * T, 12 * T))
	_static("char_15", Vector2i(27, 10), "idle_down", false)
	var sheets := ["char_13", "char_18", "char_19", "char_20", "char_14", "char_15", "char_18", "char_13"]
	for i in 6:
		# in coda fino al banco, uno attaccato all'altro: è proprio questo il punto
		_static(sheets[i], Vector2i(25 - i, 11), "idle_right", false, true)
	examine(cell_center(Vector2i(22, 12)), [
		"* \"Sono in fila dalle sei.\" \"Io dalle cinque.\" \"Io non me lo ricordo più.\"",
		"* Nessuno sa cosa c'è nelle razioni di oggi. Sono uguali a quelle di ieri.",
	])


func _barter() -> void:
	for c in [Vector2i(3, 13), Vector2i(8, 13), Vector2i(24, 13), Vector2i(29, 13)]:
		add_prop("market/cloth_%d.png" % (1 + (c.x % 4)), c, 0, Vector2i(48, 32), [
			"* Un telo pieno di cose: pane, libri, viti, una radio. \"Prendi quello che ti serve, lascia quello che puoi.\"",
		])
	add_prop("market/table_4.png", Vector2i(25, 10), 2, Vector2i(48, 48))
	add_prop("market/cart.png", Vector2i(4, 10), 2, Vector2i(48, 48), ["* Il carretto dei dolci. Oggi si paga con una storia."])
	add_signpost("res://art/sign_scambi.png", Vector2(14 * T, 9 * T))
	_static("char_19", Vector2i(6, 12), "idle_right", false)
	_static("char_20", Vector2i(10, 12), "idle_left", false)
	_static("char_14", Vector2i(27, 12), "idle_left", false)
	examine(cell_center(Vector2i(8, 12)), [
		"* \"Ti riparo la bici se mi insegni a fare il pane.\" \"Affare fatto.\"",
		"* Nessuno conta i soldi. Qualcuno conta le stelle, la sera.",
	])


## Una persona di sfondo: ferma, con la sua animazione. `grey` la rende spenta (i compratori dell'asta).
func _static(sheet: String, cell: Vector2i, anim: String, grey: bool, keep := false) -> void:
	var p := AnimatedSprite2D.new()
	p.sprite_frames = Assets.character(sheet)
	p.centered = false
	p.offset = Vector2(-8, -31)
	cell = free_cell(cell, keep)
	p.position = cell_feet(cell)
	p.play(anim)
	if grey:
		p.modulate = Color(0.65, 0.68, 0.75)
		p.speed_scale = 0.0
	world.add_child(p)
	block(Rect2i(cell, Vector2i.ONE))


func _bank_door() -> void:
	if not GameState.has_badge("-2"):
		Sound.sfx("deny")
		await Ui.say(["* La porta della Banca Fiducia ha un tornello. Lucina rossa.",
			"* \"Piano -2. Accesso con badge (%s). Gli interessi, invece, entrano gratis.\"" % GameState.euros(GameState.badge_cost("-2"))])
		return
	Router.goto(Router.BANCA, "mercato")


## Un edificio sullo sfondo: blocca solo dove c'è davvero (tra un negozio e l'altro si passa).
func _building(rel: String, x: int, size: Vector2i) -> void:
	var tex := Assets.tex(rel, size)
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.offset = Vector2(0, -tex.get_height())
	s.position = Vector2(x * T, 6 * T)
	world.add_child(s)
	var r := _solid_rect(tex, 6)
	if r.size.x <= 0:
		r = Rect2(0, -6 * T, tex.get_width(), 6 * T)
	r.position.y = -6 * T
	r.size.y = 6 * T - 2
	block_px(Rect2(s.position + r.position, r.size))
	for cx in range(int(floor((s.position.x + r.position.x) / T)), int(ceil((s.position.x + r.end.x) / T))):
		for cy in 6:
			_blocked_cells[Vector2i(cx, cy)] = true


## La targa della banca, sopra la scritta MARKET del palazzo grande.
func _bank_plate(x: int, occupied: bool) -> void:
	var base := Vector2(x * T + 32, 6 * T - 144 + 79)
	var border := ColorRect.new()
	border.color = Color("3a3644")
	border.position = base
	border.size = Vector2(48, 22)
	border.z_index = 1
	add_child(border)
	var plate := ColorRect.new()
	plate.color = Color("d8dbe6") if not occupied else Color("f2e6c8")
	plate.position = base + Vector2(2, 2)
	plate.size = Vector2(44, 18)
	plate.z_index = 1
	add_child(plate)
	var l := Label.new()
	l.text = "OCCUPATA" if occupied else "BANCA"
	l.add_theme_font_size_override("font_size", 13 if not occupied else 9)
	l.add_theme_color_override("font_color", Color("3a3644") if not occupied else Color("c0302a"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = base
	l.size = Vector2(48, 22)
	l.z_index = 1
	add_child(l)


## La gente del mercato: passanti che girano tra i banchi, con frasi diverse a seconda del mondo.
func _shoppers() -> void:
	var talk: Array
	match look:
		"capitalismo":
			talk = [
				"Ho comprato un banco all'asta. Non so cosa vendere. Allora vendo il banco.",
				"Tutto ha un prezzo. Io, per esempio, sono in saldo.",
				"Offerta speciale: compri due debiti e il terzo è gratis. Ne ho presi sei.",
				"Il banditore è bravissimo. Ieri ha venduto sua madre. Tre volte.",
				"Sorridi! Quelli che non sorridono vengono messi all'asta.",
			]
		"baratto":
			talk = [
				"Ho scambiato un orologio con un pomeriggio libero. Miglior affare della mia vita.",
				"Qui nessuno ha soldi. Eppure nessuno ha fame. Strano, no?",
				"Ti do una storia in cambio di una mela? Le mie storie sono buone. Le mele meno.",
				"Ho riparato una bici e mi hanno insegnato a fare il pane. Adesso faccio il pane per le bici.",
				"Il primo giorno avevo paura. Il secondo ho riso. Il terzo ho dormito, per la prima volta da anni.",
			]
		_:
			talk = [
				"Ho il numero 4.512. Stanno servendo il 12. Torno domani. Cioè tra un anno.",
				"La razione di oggi è uguale a quella di ieri. Almeno non ci sono sorprese.",
				"Mio figlio mi ha chiesto cos'è una fragola. Gliel'ho disegnata.",
				"Non fare la fila due volte. Se ne accorgono. Se ne accorgono sempre.",
				"Una volta qui si sentiva gridare: \"Pomodori! Pomodori freschi!\". Adesso si sente solo il timbro.",
			]
	var sheets := ["char_05", "char_09", "char_12", "char_07", "char_11", "char_06"]
	var rows := [7, 15, 15, 7, 14]
	for i in rows.size():
		var w := Walker.new()
		w.sheet = sheets[i % sheets.size()]
		w.lines = talk
		w.direction = 1.0 if i % 2 == 0 else -1.0
		w.min_x = T
		w.max_x = (W - 2) * T
		w.position = Vector2(randf_range(3 * T, (W - 4) * T), (rows[i] + 1) * T - 2)
		if look == "capitalismo":
			w.modulate = Color(0.82, 0.84, 0.9)
		world.add_child(w)


func _art(path: String, pos: Vector2) -> void:
	if not ResourceLoader.exists(path):
		return
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = false
	s.position = pos
	s.z_index = 1
	add_child(s)
