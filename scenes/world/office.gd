extends Room
## Il piano terra della torre CHEAP. La botola scende alla Banca (-2), l'ascensore sale alla
## Direzione (con il badge della Cima), la porta esce in città. Qui lavorano Dario e Giulia.

const RB := "tiles/room_builder.png"
const DESK_TEXTS := [
	["* Sul monitor: PRODUTTIVITÀ DEL REPARTO 37%. Sotto, a penna: \"aiuto\"."],
	["* Una scrivania. Nel cassetto c'è una scorta di caffè solubile e di antidolorifici."],
	["* Sul monitor è aperta un'email: \"Oggetto: ottimizzazione del personale (riservato)\"."],
	["* Una foto di famiglia, girata verso il muro. Forse per non farsi vedere."],
	["* Post-it sul monitor: \"Sorridi! Il cliente ti sente.\""],
	["* Il computer è spento. Sopra c'è un biglietto: \"Grazie di tutto. Scusate.\""],
	["* Sul monitor scorre un grafico. Sale sempre. Non c'è scritto cosa."],
	["* Una tazza con la scritta \"Il miglior dipendente del mondo\". È piena di polvere."],
]


func build() -> void:
	floor_id = "0"
	music = "ufficio"
	var floor_def := {"tex": RB, "at": func(c: Vector2i) -> Vector2i: return Vector2i(38 + c.x % 3, 11 + c.y % 2)}
	paint([
		"####################",
		"#WWWWWWWWWWWWWWWWWW#",
		"#wwwwwwwwwwwwwwwwww#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#########..#########",
		"#########dd#########",
	], {
		"#": {"tex": RB, "at": Vector2i(12, 0), "solid": true},
		"W": {"tex": RB, "at": Vector2i(1, 13), "solid": true},
		"w": {"tex": RB, "at": Vector2i(1, 14), "solid": true},
		".": floor_def,
		"_floor": floor_def,
	})

	add_prop("props/terminal.png", Vector2i(9, 3))
	add_prop("props/portrait.png", Vector2i(6, 2), 0, Vector2i(16, 32), [
		"* Il ritratto del fondatore della CHEAP. Ti sorride come sorride una banca.",
	])
	add_prop("props/trash.png", Vector2i(17, 3), 1, Vector2i(16, 32), [
		"* Il cestino è pieno di curriculum. Alcuni sono ancora chiusi nella busta.",
	])
	add_prop("props/palm.png", Vector2i(1, 3), 1, Vector2i(32, 32), [
		"* Una palma finta. È l'unica cosa qui dentro che non si stanca mai.",
	])
	add_prop("props/plant.png", Vector2i(18, 9), 1, Vector2i(16, 32), [
		"* Una pianta vera. Qualcuno la annaffia di nascosto ogni mattina.",
	])

	# Scrivanie: la sedia sta dietro (a nord), la scrivania la copre in parte.
	var k := 0
	for y in [5, 8]:
		for x in [3, 4, 14, 15]:
			if not (x == 4 and y == 8):
				add_prop("props/office_chair.png", Vector2i(x, y - 1), 0, Vector2i(16, 32), [], Vector2(0, -4))
			add_computer_desk(Vector2i(x, y), DESK_TEXTS[k % DESK_TEXTS.size()])
			k += 1

	add_spot(cell_center(Vector2i(9, 3)), _terminal)
	_elevator(Vector2i(12, 1))
	add_exit(Rect2i(9, 11, 2, 1), Router.STREET, "office")
	add_stairs_down(Vector2i(1, 9), Router.BANCA, "from_above")
	add_badge_machine(Vector2i(15, 3))
	spawn_people("office")

	spawns["default"] = cell_feet(Vector2i(9, 9))
	spawns["street"] = spawns["default"]
	spawn_facing["default"] = "up"
	spawn_facing["street"] = "up"
	spawns["terminal"] = cell_feet(Vector2i(9, 4))
	spawns["elevator"] = cell_feet(Vector2i(12, 4))
	spawn_facing["elevator"] = "down"
	spawns["from_below"] = cell_feet(Vector2i(3, 9))
	spawn_facing["from_below"] = "right"
	spawn_facing["terminal"] = "up"


func enter() -> void:
	if not GameState.flags.get("office_intro", false) and not GameState.is_robot("giulia"):
		GameState.flags["office_intro"] = true
		await Ui.say([
			"...Sei salito dalla Banca? Da sotto? Non ci credo. Nessuno sale da sotto.",
			"Io sono Giulia. Qui è il piano terra: luce vera, finestre vere. Là fuori c'è la città.",
			"L'ascensore va solo in su, alla Direzione. Serve il badge della Cima, e costa come un rene.",
			"Il capo, intanto, ti telefonerà. Ti offre le promozioni. Sembrano regali. ...Non sono regali. Ma non te l'ho detto io.",
		], "Giulia")
	await show_pending()


## Il terminale del piano terra rimanda al collocamento, al piano -4. Dopo il turno
## propone gli straordinari.
func _terminal() -> void:
	if GameState.worked_today:
		await _overtime()
		return
	await Ui.say([
		"* Sul terminale lampeggia un avviso: \"Il COLLOCAMENTO è al piano -4.\"",
		"* \"Per chi viene dal piano terra: scendere è facile. È salire che costa.\"",
	], "Terminale")


func _elevator(top_left: Vector2i) -> void:
	var frame := ColorRect.new()
	frame.color = Color("4a4658")
	frame.position = Vector2(top_left.x * T, top_left.y * T + 4)
	frame.size = Vector2(2 * T, 2 * T - 4)
	world.add_child(frame)
	for i in 2:
		var door := ColorRect.new()
		door.color = Color("aeb4c4")
		door.position = frame.position + Vector2(2 + i * 15, 3)
		door.size = Vector2(13, frame.size.y - 3)
		world.add_child(door)
	var light := ColorRect.new()
	light.color = Color("3ddc84") if GameState.has_badge("cima") else Color("d0302f")
	light.position = frame.position + Vector2(14, -3)
	light.size = Vector2(4, 2)
	world.add_child(light)
	add_spot(cell_center(top_left + Vector2i(1, 2)) - Vector2(8, 0), _ride_elevator)


func _ride_elevator() -> void:
	var up_ok := GameState.has_badge("cima")
	var c: int = await Ui.choose("L'ascensore. C'è un solo pulsante: SU.", ["Ultimo piano: Direzione" + ("" if up_ok else " (serve il badge)"), "Resta qui"])
	if c != 0:
		return
	if not up_ok:
		Sound.sfx("deny")
		await Ui.say(["* Il lettore di badge lampeggia rosso.", "* \"La Cima. Accesso con badge (%s).\"" % GameState.euros(GameState.badge_cost("cima"))])
		return
	Router.goto(Router.BOSS, "elevator")


## Straordinari: soldi in cambio del poco tempo che ti resta.
func _overtime() -> void:
	if GameState.flags.get("overtime_day", 0) == GameState.day or not GameState.has_time(120):
		await Ui.say(["* Il turno di oggi è chiuso. Torna a casa a riposare."], "Terminale")
		return
	var c: int = await Ui.choose("Il turno è finito. Vuoi fare due ore di straordinari? (+80 €)", ["Straordinari (2 ore)", "Vai a casa"], "Terminale")
	if c != 0:
		return
	GameState.flags["overtime_day"] = GameState.day
	GameState.spend(120)
	GameState.money += 80
	GameState.hurt(3)
	Sound.sfx("coin")
	await Ui.say([
		"* Resti in ufficio. Fuori fa buio. Dario è ancora lì, col suo contatore.",
		"* +80 €. Le tue due ore libere sono diventate soldi. Non tornano indietro.",
	])
