extends Room
## I tre finali. Quale vedi lo decide GameState.route():
##   ricco   -> l'attico, i "colleghi", Nico che ti fa guardare giù (city_below), poi la verità sui robot
##   onesto  -> la strada al tramonto: il debito resta, le persone anche
##   ribelle -> la notte in cui il quartiere smette di pagare

const RB := "tiles/room_builder.png"
const CITY := "tiles/city_terrains.png"

var route := ""
var nico: Npc
var people: Array[Npc] = []


func build() -> void:
	Ui.cutscene = true
	route = GameState.route()
	if route == "ricco":
		music = "ufficio"
		_build_penthouse()
	else:
		music = "quartiere"
		_build_street()


func enter() -> void:
	match route:
		"ricco":
			if GameState.flags.get("ending_stage", 0) == 0:
				await _rich_start()
			else:
				await _rich_reveal()
		"ribelle":
			await _rebel()
		_:
			await _honest()


func _finish(lines: Array) -> void:
	GameState.delete_save()
	GameState.flags.erase("ending_stage")
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
	add_prop("props/palm.png", Vector2i(2, 3), 1, Vector2i(32, 32))
	add_prop("props/palm.png", Vector2i(16, 3), 1, Vector2i(32, 32))

	# Tutti, tranne Nico, sono già robot. Il giocatore non lo sa ancora.
	for id: String in GameState.npc_ids():
		if id != "nico" and not GameState.is_robot(id):
			GameState.robots.append(id)
	var spots := [Vector2i(3, 6), Vector2i(5, 7), Vector2i(15, 7), Vector2i(17, 6),
		Vector2i(3, 9), Vector2i(6, 9), Vector2i(14, 9), Vector2i(17, 9)]
	var k := 0
	for id: String in GameState.npc_ids():
		if id == "nico" or k >= spots.size():
			continue
		people.append(add_npc(id, spots[k], "right" if spots[k].x < 10 else "left"))
		k += 1
	nico = add_npc("nico", Vector2i(10, 4), "down")
	spawns["default"] = cell_feet(Vector2i(10, 7))
	spawn_facing["default"] = "up"


func _build_street() -> void:
	outdoor = route == "onesto"
	var rows: Array = []
	for y in 13:
		var row := ""
		for x in 24:
			var ch := "s"
			if y == 10:
				ch = "C"
			elif y > 10:
				ch = "r"
			row += ch
		rows.append(row)
	var sidewalk := {"tex": CITY, "at": func(c: Vector2i) -> Vector2i: return Vector2i(9 + c.x % 4, c.y % 4)}
	paint(rows, {
		"s": sidewalk,
		"C": {"tex": CITY, "at": Vector2i(1, 3)},
		"r": {"tex": CITY, "at": Vector2i(2, 5)},
		"_floor": sidewalk,
	})
	camera_top = 64
	for b: Array in [["buildings/home.png", 2, Vector2i(112, 288)], ["street/coffee_kiosk.png", 10, Vector2i(96, 144)],
			["buildings/condo_yellow.png", 17, Vector2i(96, 176)]]:
		add_prop(b[0], Vector2i(b[1], 6), 0, b[2])
	block(Rect2i(0, 0, 24, 7))
	block(Rect2i(-1, 0, 1, 13))
	block(Rect2i(24, 0, 1, 13))
	block(Rect2i(0, 12, 24, 1))
	if route == "ribelle":
		var night := CanvasModulate.new()
		night.color = Color(0.42, 0.48, 0.75)
		add_child(night)
	else:
		GameState.minutes = 19 * 60

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

func _rich_start() -> void:
	await Ui.say([
		"* Ultimo piano della torre CHEAP. Il tuo ufficio.",
		"* Il debito non esiste più. Sul conto: {money}.",
	])
	for i in mini(3, people.size()):
		await Ui.say([GameState.robot_line(people[i].id)], people[i].display_name())
	await Ui.say([
		"Ehi. Sei diventato ricco da far schifo, eh?",
		"Sono salito a piedi. Sessanta piani. L'ascensore non riconosce chi non ha il badge.",
		"Vieni alla finestra. Guarda giù.",
	], "Nico")
	GameState.flags["ending_stage"] = 1
	Ui.cutscene = false
	Router.goto(Router.ENDING_CITY)


func _rich_reveal() -> void:
	await Ui.say([
		"E sai chi è la feccia peggiore?",
		"Non loro. Quello che guarda dall'alto e dice che è colpa loro.",
		"Adesso guarda qui dentro. Guardali davvero, per una volta.",
	], "Nico")
	for p in people:
		p.reveal(2.0)
	Sound.sfx("glitch")
	await get_tree().create_timer(2.6).timeout
	await Ui.say([
		"* Non c'è nessuno.",
		"* Marta. Il signor Bruno. Dario. Giulia. Ivo. Lea. Sami.",
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


# --- finale onesto ----------------------------------------------------------

func _honest() -> void:
	await Ui.say([
		"Il debito è ancora lì, eh? È sceso un po', ma è ancora lì.",
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
		"Debito: {debt}.\nTi sei sporcato le mani. Non sei diventato ricco.",
		"Le persone intorno a te sono vere. Per oggi basta.",
		"Grazie per aver giocato a CHEAP.",
	])


# --- finale ribelle ---------------------------------------------------------

func _rebel() -> void:
	await Ui.say([
		"Guarda quanti siamo.",
		"Tutti con un debito. Tutti stanchi. Tutti qui.",
		"Pochi giorni fa dovevi {debt}. Stanotte, se va come deve andare, non lo dovrà più nessuno.",
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
