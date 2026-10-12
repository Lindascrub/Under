extends Room
## I tre finali. Quale vedi lo decide GameState.route():
##   ricco   -> l'attico, i robot, Nico che apre la finestra
##   onesto  -> la strada al tramonto: il debito resta, le persone anche
##   ribelle -> la notte in cui il quartiere smette di pagare

const RB := "tiles/room_builder.png"
const CITY := "tiles/city_terrains.png"
const BUILDINGS := "tiles/generic_buildings.png"
const BUILDINGS_SIZE := Vector2i(512, 3200)
const HOUSE_REGION := Rect2(368, 400, 96, 288)
const TOWER_REGION := Rect2(240, 402, 112, 286)

var route := ""
var nico: Npc
var people: Array[Npc] = []


func build() -> void:
	Ui.cutscene = true
	route = GameState.route()
	if route == "ricco":
		_build_penthouse()
	else:
		_build_street()


func enter() -> void:
	match route:
		"ricco":
			await _rich()
		"ribelle":
			await _rebel()
		_:
			await _honest()


func _finish(lines: Array) -> void:
	GameState.delete_save()
	Ui.cutscene = false
	Router.goto(Router.MENU, "", lines)


# --- scenari ----------------------------------------------------------------

func _build_penthouse() -> void:
	var floor_def := {"tex": RB, "at": func(c: Vector2i) -> Vector2i: return Vector2i(42 + c.x % 3, 19 + c.y % 2)}
	var rows: Array = ["####################", "#WWWWWWWWWWWWWWWWWW#", "#wwwwwwwwwwwwwwwwww#"]
	for i in 8:
		rows.append("#..................#")
	rows.append("####################")
	paint(rows, {
		"#": {"tex": RB, "at": Vector2i(12, 0), "solid": true},
		"W": {"tex": RB, "at": Vector2i(22, 11), "solid": true},
		"w": {"tex": RB, "at": Vector2i(22, 12), "solid": true},
		".": floor_def,
		"_floor": floor_def,
	})
	# La grande finestra dell'attico.
	var frame := ColorRect.new()
	frame.color = Color("1a1420")
	frame.position = Vector2(7 * T, T + 2)
	frame.size = Vector2(6 * T, 2 * T - 4)
	add_child(frame)
	var sky := ColorRect.new()
	sky.color = Color("8ec5ff")
	sky.position = frame.position + Vector2(3, 3)
	sky.size = frame.size - Vector2(6, 6)
	add_child(sky)

	# Tutti, tranne Nico, sono già robot. Il giocatore non lo sa ancora.
	for id: String in GameState.npc_ids():
		if id != "nico" and not GameState.is_robot(id):
			GameState.robots.append(id)
	var spots := [Vector2i(3, 5), Vector2i(5, 6), Vector2i(15, 6), Vector2i(17, 5),
		Vector2i(3, 9), Vector2i(6, 9), Vector2i(14, 9), Vector2i(17, 9)]
	var k := 0
	for id: String in GameState.npc_ids():
		if id == "nico" or k >= spots.size():
			continue
		var facing := "right" if spots[k].x < 10 else "left"
		people.append(add_npc(id, spots[k], facing))
		k += 1
	nico = add_npc("nico", Vector2i(10, 4), "down")
	spawns["default"] = cell_feet(Vector2i(10, 7))
	spawn_facing["default"] = "up"


func _build_street() -> void:
	var rows: Array = []
	for y in 13:
		var row := ""
		for x in 24:
			var ch := "s"
			if y == 10:
				ch = "R"
			elif y > 10:
				ch = "r"
			if y == 12 or x == 0 or x == 23:
				ch = "x"
			row += ch
		rows.append(row)
	var sidewalk := {"tex": CITY, "at": Vector2i(10, 2)}
	paint(rows, {
		"s": sidewalk,
		"x": {"tex": CITY, "at": Vector2i(10, 2), "solid": true},
		"R": {"tex": CITY, "at": Vector2i(2, 8)},
		"r": {"tex": CITY, "at": Vector2i(2, 5)},
		"_floor": sidewalk,
	})
	camera_top = 48
	add_region(BUILDINGS, BUILDINGS_SIZE, HOUSE_REGION, Vector2i(3, 6))
	add_region(BUILDINGS, BUILDINGS_SIZE, TOWER_REGION, Vector2i(13, 6))
	block(Rect2i(0, 0, 24, 7))

	var tint := CanvasModulate.new()
	tint.color = Color(1.0, 0.8, 0.62) if route == "onesto" else Color(0.42, 0.48, 0.75)
	add_child(tint)

	var ids: Array = []
	for id: String in GameState.npc_ids():
		if id == "nico" or GameState.is_robot(id):
			continue
		if route == "ribelle" or id in GameState.helped_ids:
			ids.append(id)
	var spots := [Vector2i(8, 8), Vector2i(14, 8), Vector2i(7, 9), Vector2i(15, 9),
		Vector2i(9, 7), Vector2i(13, 7), Vector2i(6, 8), Vector2i(16, 8)]
	for i in mini(ids.size(), spots.size()):
		people.append(add_npc(ids[i], spots[i], "down"))
	nico = add_npc("nico", Vector2i(11, 8), "down")
	spawns["default"] = cell_feet(Vector2i(11, 9))
	spawn_facing["default"] = "up"


# --- finale ricco -----------------------------------------------------------

func _rich() -> void:
	await Ui.say([
		"* Ultimo piano della torre CHEAP. Il tuo ufficio.",
		"* Il debito non esiste più. Sul conto: {money}.",
	])
	for i in mini(3, people.size()):
		await Ui.say([GameState.robot_line(people[i].id)], people[i].display_name())
	await Ui.say([
		"Ehi. Sei diventato ricco da far schifo, eh?",
		"Sono salito a piedi. Sessanta piani. L'ascensore non riconosce chi non ha il badge.",
		"Vieni qui. Ti devo far vedere una cosa.",
	], "Nico")
	await _city_below()
	await Ui.say([
		"E sai chi è la feccia peggiore?",
		"Non loro. Quello che guarda dall'alto e dice che è colpa loro.",
		"Adesso guarda qui dentro. Guardali davvero, per una volta.",
	], "Nico")
	for p in people:
		p.reveal(2.0)
	await get_tree().create_timer(2.6).timeout
	await Ui.say([
		"* Non c'è nessuno.",
		"* Marta. Il signor Bruno. Dario. Giulia. Ivo.",
		"* Da quanto tempo stavi parlando con delle macchine?",
		"* Ogni firma, una persona in meno. Ogni promozione, un sorriso finto in più.",
	])
	await Ui.say([
		"Io torno giù. Lì almeno la gente è vera. Anche se sta male.",
		"...Anche per colpa tua.",
	], "Nico")
	nico.visible = false
	await Ui.say(["* Sei da solo, in cima a tutto."])
	_finish([
		"FINALE: RICCO",
		"Debito: 0 €.\nPersone intorno a te: 0.",
		"Grazie per aver giocato a CHEAP.",
	])


func _city_below() -> void:
	await Ui.fade_out()
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color("10131c")
	bg.size = Vector2(640, 360)
	layer.add_child(bg)
	for i in 4:
		var b := Sprite2D.new()
		var at := AtlasTexture.new()
		at.atlas = Assets.tex(BUILDINGS, BUILDINGS_SIZE)
		at.region = HOUSE_REGION if i % 2 == 0 else TOWER_REGION
		b.texture = at
		b.centered = false
		b.scale = Vector2(1.3, 1.3)
		b.position = Vector2(20 + i * 160, 300 - at.region.size.y * 1.3)
		b.modulate = Color(0.35, 0.38, 0.5)
		layer.add_child(b)
	var street := ColorRect.new()
	street.color = Color("22252e")
	street.position = Vector2(0, 290)
	street.size = Vector2(640, 70)
	layer.add_child(street)
	for i in 7:
		var cardboard := ColorRect.new()
		cardboard.color = Color("6b5236")
		cardboard.position = Vector2(30 + i * 88, 318)
		cardboard.size = Vector2(70, 12)
		layer.add_child(cardboard)
		var s := Sprite2D.new()
		var at := AtlasTexture.new()
		at.atlas = Assets.tex("characters/char_%02d.png" % (i + 6), Vector2i(384, 96))
		at.region = Rect2(18 * 16, 32, 16, 32)
		s.texture = at
		s.scale = Vector2(2, 2)
		s.rotation = PI / 2.0 if i % 2 == 0 else 0.0
		s.position = Vector2(64 + i * 88, 312 if i % 2 == 0 else 292)
		s.modulate = Color(0.55, 0.55, 0.68)
		layer.add_child(s)
	await Ui.fade_in()
	await Ui.say([
		"* Sotto la torre, la città.",
		"* Gente che dorme sui cartoni. La fila davanti alla mensa gira intorno all'isolato.",
		"* Sono le facce che salutavi ogni mattina. Quelle vere.",
	])
	await Ui.fade_out()
	layer.queue_free()
	await Ui.fade_in()


# --- finale onesto ----------------------------------------------------------

func _honest() -> void:
	await Ui.say([
		"Il debito è ancora lì, eh? Anzi, è cresciuto.",
		"La banca ha mandato un'altra lettera. Domani ne manderà un'altra.",
	], "Nico")
	for p in people:
		var lines: Array = p.data.get("helped", ["Grazie."])
		await Ui.say([lines[0]], p.display_name())
	await Ui.say([
		"Non è cambiato niente. Il sistema è uguale a prima.",
		"Però tu sei ancora tu. E noi siamo ancora qui.",
		"Domani si ricomincia. Il caffè lo offro io.",
	], "Nico")
	_finish([
		"FINALE: ONESTO",
		"Debito: {debt}.\nÈ più grande di quando hai iniziato.",
		"Le persone intorno a te sono vere. Per oggi basta.",
		"Grazie per aver giocato a CHEAP.",
	])


# --- finale ribelle ---------------------------------------------------------

func _rebel() -> void:
	await Ui.say([
		"Guarda quanti siamo.",
		"Tutti con un debito. Tutti stanchi. Tutti qui.",
		"Sette giorni fa dovevi {debt}. Stanotte, se va come deve andare, non lo dovrà più nessuno.",
		"Sei pronto?",
	], "Nico")
	var c: int = await Ui.choose("Sei pronto?", ["Andiamo", "...Andiamo"], "Nico")
	if c == 1:
		await Ui.say(["Lo so. Anch'io ho paura."], "Nico")
	_finish([
		"Quella notte il quartiere entrò nella banca.",
		"I registri dei debiti bruciarono fino all'alba.",
		"Dei creditori, nessuno parlò più.",
		"Qualcuno dice che sono scappati. Altri abbassano lo sguardo e cambiano discorso.",
		"La mattina dopo, al mercato, nessuno usava soldi.\nUn pane per una riparazione. Un'ora di lavoro per un'ora di lavoro.",
		"FINALE: RIBELLE",
		"Sei libero. Ma ogni tanto ti chiedi cosa sia successo davvero, quella notte.",
		"Grazie per aver giocato a CHEAP.",
	])
