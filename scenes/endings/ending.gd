extends Room
## I tre finali sono tre sistemi economici, cioè tre modi di trattare il tempo. Li decide GameState.route():
##   capitalismo -> hai comprato il tempo degli altri: l'attico, Nico, la città vista dall'alto, i robot
##   comunismo   -> sei rimasto un ingranaggio: il tempo di tutti è uguale, fisso, già assegnato
##   baratto     -> il tempo si scambia. Dipende dalla massa critica (GameState.barter_level()):
##                  "pochi" una piccola comunità; "soglia" il sistema crolla; "quasi_tutti" il mondo disordinato ma vivo
## Alla fine ogni finale ricorda cosa hai fatto zona per zona.

const RB := "tiles/room_builder.png"
const CITY := "tiles/city_terrains.png"

var route := ""
var nico: Npc
var people: Array[Npc] = []


func build() -> void:
	Ui.cutscene = true
	route = GameState.route()
	if route == "capitalismo":
		music = "ufficio"
		_build_penthouse()
	else:
		music = "quartiere"
		_build_street()


func enter() -> void:
	match route:
		"capitalismo":
			if GameState.flags.get("ending_stage", 0) == 0:
				await _rich_start()
			else:
				await _rich_reveal()
		"baratto":
			match GameState.barter_level():
				"quasi_tutti":
					await _barter_full()
				"soglia":
					await _rebel()
				_:
					await _barter_few()
		_:
			await _cog()


## Come in Undertale, il finale ricorda cosa hai fatto in ogni zona.
func _zone_lines() -> String:
	var out: Array = []
	var names := {"ufficio": "In ufficio", "strada": "In strada", "parco": "Al parco"}
	var sums := GameState.zone_summary()
	for z: String in sums:
		var c: Dictionary = sums[z]
		var parts: Array = []
		if c["sfruttato"] > 0:
			parts.append("%d sostituiti da robot" % c["sfruttato"])
		if c["libero"] > 0:
			parts.append("%d liberi" % c["libero"])
		if c["ingranaggio"] > 0:
			parts.append("%d ancora al lavoro" % c["ingranaggio"])
		out.append("%s: %s." % [names[z], ", ".join(parts)])
	return "\n".join(out)


func _finish(lines: Array) -> void:
	lines = lines.duplicate()
	lines.insert(lines.size() - 1, "LV finale: %d." % GameState.lv())
	lines.insert(lines.size() - 1, _zone_lines())
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
	outdoor = route == "comunismo"
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
	if route == "baratto" and GameState.barter_level() != "quasi_tutti":
		var night := CanvasModulate.new()
		night.color = Color(0.42, 0.48, 0.75)
		add_child(night)
	else:
		GameState.minutes = 19 * 60

	var ids: Array = []
	for id: String in GameState.npc_ids():
		if id == "nico" or GameState.is_robot(id):
			continue
		if route == "baratto" and (id in GameState.freed or GameState.barter_level() != "pochi"):
			ids.append(id)
		elif route == "comunismo" and GameState.npc_state(id) == "ingranaggio":
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
	if GameState.flags.get("sat_with_president", false):
		await Ui.say(["* Ti torna in mente il Presidente, seduto davanti alla sua finestra.", "* \"L'ho venduto tutto, un'ora alla volta.\""])
	await Ui.say(["* Sei da solo, in cima a tutto."])
	_finish([
		"FINALE: CAPITALISMO",
		"Hai comprato il tempo degli altri e venduto il tuo.\nDebito: 0 €. Persone intorno a te: 0.",
		"Grazie per aver giocato a CHEAP.",
	])


# --- finale comunismo (ingranaggio) -----------------------------------------

func _cog() -> void:
	await Ui.say([
		"Ti hanno dato un turno nuovo. Lo stesso di tutti.",
		"Dieci ore di lavoro, otto di sonno, tre per mangiare. Tre libere, che poi sono una.",
		"Nessuno ti sfrutta. Nessuno è libero. Siamo tutti uguali: tutti un po' stanchi allo stesso modo.",
	], "Nico")
	for p in people.slice(0, 3):
		await Ui.say(["Domani alle sette. Come oggi. Come ieri."], p.display_name())
	await Ui.say([
		"Il debito è ancora lì. È sceso un po'. Scenderà un po' ogni giorno, per sempre.",
		"Domani si ricomincia. Il caffè lo offro io. Anche quello, come ogni giorno.",
	], "Nico")
	_finish([
		"FINALE: COMUNISMO",
		"Il tempo di tutti è uguale, fisso e già assegnato.\nDebito: {debt}.",
		"Non hai rovinato nessuno. Non hai salvato nessuno. Sei un ingranaggio, e l'ingranaggio gira.",
		"Grazie per aver giocato a CHEAP.",
	])


# --- finale baratto: pochi -------------------------------------------------

func _barter_few() -> void:
	var names: Array = []
	for id: String in GameState.freed:
		names.append(str(GameState.npc_data(id).get("name", id)))
	await Ui.say([
		"Siamo in pochi. Il sistema non se n'è nemmeno accorto.",
		"La banca manda lettere. La CHEAP assume altri. La città va avanti come se niente fosse.",
	], "Nico")
	for p in people:
		var lines: Array = p.data.get("motive", {}).get("freed_lines", ["Grazie."])
		await Ui.say([lines[0]], p.display_name())
	var who := ", ".join(names)
	await Ui.say([
		("* %s hanno smesso di lavorare." if names.size() > 1 else "* %s ha smesso di lavorare.") % who,
		"* Ma il sistema non è crollato, e uno stipendio in meno pesa. Ci sono mesi in cui il pane del Rifugio non basta.",
	])
	await Ui.say(["Però guarda: ci scambiamo le cose, ci aiutiamo. Una piccola città dentro la città.", "Non è una vittoria. Ma è nostra."], "Nico")
	_finish([
		"FINALE: BARATTO - UNA PICCOLA COMUNITÀ",
		"Il debito resta: {debt}.\nChi hai convinto a smettere è più libero. E più povero.",
		"Forse, con più persone, sarebbe andata diversamente.",
		"Grazie per aver giocato a CHEAP.",
	])


# --- finale baratto: quasi tutti ---------------------------------------------

func _barter_full() -> void:
	await Ui.say([
		"Lo senti? Nessuna sveglia. Nessun clacson. Nessuno corre.",
		"Hanno smesso quasi tutti, nello stesso momento. Quando non lavora più nessuno, il debito di chi è?",
	], "Nico")
	for p in people:
		var lines: Array = p.data.get("motive", {}).get("freed_lines", ["Buongiorno!"])
		await Ui.say([lines[lines.size() - 1]], p.display_name())
	await Ui.say([
		"È tutto in disordine. La spazzatura, le strade, i conti. Nessuno sa bene come si fa.",
		"Ma la gente si parla. Si scambia il tempo invece di venderlo.",
		"Un pane per una riparazione. Un'ora di lavoro per un'ora di lavoro.",
	], "Nico")
	_finish([
		"FINALE: BARATTO - IL MONDO DISORDINATO E VIVO",
		"Il debito non esiste più, perché non esiste più chi lo pretendeva.",
		"Il mondo è disordinato. Ma è vivo. E il tempo, finalmente, è tuo.",
		"Grazie per aver giocato a CHEAP.",
	])


# --- finale baratto: soglia (il sistema crolla) -------------------------------

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
		"FINALE: BARATTO - IL CROLLO",
		"Sei libero. Ma ogni tanto ti chiedi cosa sia successo davvero, quella notte.",
		"Grazie per aver giocato a CHEAP.",
	])
