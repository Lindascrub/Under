extends Room
## Casa del protagonista: il letto (fine giornata e rata), il computer (la banca), la porta.

const RB := "tiles/room_builder.png"
## Angolo in alto a sinistra dello sprite del letto (in pixel), per sdraiarsi.
const BED_TOP := Vector2(2 * 16, 6 * 16 - 48)


func build() -> void:
	music = "quartiere"
	var floor_def := {"tex": RB, "at": func(c: Vector2i) -> Vector2i: return Vector2i(34 + c.x % 3, 21 + c.y % 2)}
	paint([
		"################",
		"#WWWWWWWWWWWWWW#",
		"#wwwwwwwwwwwwww#",
		"#..............#",
		"#..............#",
		"#..............#",
		"#..............#",
		"#..............#",
		"#..............#",
		"#..............#",
		"#######..#######",
		"#######dd#######",
	], {
		"#": {"tex": RB, "at": Vector2i(12, 0), "solid": true},
		"W": {"tex": RB, "at": Vector2i(12, 11), "solid": true},
		"w": {"tex": RB, "at": Vector2i(12, 12), "solid": true},
		".": floor_def,
		"_floor": floor_def,
	})

	add_prop("props/bed.png", Vector2i(2, 5), 3, Vector2i(32, 48))
	add_prop("props/dresser.png", Vector2i(5, 3), 1, Vector2i(32, 48), [
		"* Sullo specchio c'è un post-it con la calligrafia di tuo padre:",
		"* \"Non firmare mai niente senza leggerlo fino in fondo.\"",
	])
	add_prop("props/computer.png", Vector2i(8, 3))
	add_prop("props/wardrobe.png", Vector2i(11, 3), 1, Vector2i(32, 48), [
		"* I vestiti di tuo padre. Profumano ancora di lui. E di naftalina.",
	])
	add_prop("props/robot_toy.png", Vector2i(13, 3))
	add_prop("props/plant.png", Vector2i(14, 3), 1, Vector2i(16, 32), [
		"* Una pianta mezza secca. Ha l'aria di chi ha visto troppe bollette.",
	])
	add_prop("props/lamp.png", Vector2i(1, 9), 1, Vector2i(16, 32), [
		"* Una lampada. La accendi. La spegni. La bolletta della luce ti guarda male.",
	])
	add_prop("props/boxes.png", Vector2i(9, 3), 2, Vector2i(32, 48), [
		"* Scatoloni del trasloco. Dentro: bollette, bollette, una tua foto da bambino, bollette.",
	])
	add_prop("props/boxes_small.png", Vector2i(4, 3), 2, Vector2i(16, 32), [
		"* Su questo scatolone c'è scritto \"COSE IMPORTANTI\". Dentro c'è solo un'altra bolletta.",
	])

	add_spot(Vector2(60, 72), _sleep)
	add_spot(cell_center(Vector2i(8, 3)), _computer)
	add_spot(cell_center(Vector2i(13, 3)), _robot_toy)
	add_exit(Rect2i(7, 11, 2, 1), Router.STREET, "home")

	spawns["default"] = cell_feet(Vector2i(4, 4))
	spawns["bed"] = spawns["default"]
	spawn_facing["default"] = "left"
	spawn_facing["bed"] = "left"
	spawns["wake"] = spawns["default"]
	spawns["street"] = cell_feet(Vector2i(7, 9))
	spawn_facing["street"] = "up"


## Al risveglio sei già sdraiato prima che lo schermo si accenda (non in piedi e poi a letto).
func after_spawn() -> void:
	if Router.spawn == "wake":
		Ui.cutscene = true
		player.lie_down(BED_TOP)


func enter() -> void:
	if Router.spawn == "wake":
		await _wake_up()
	if GameState.flags.get("forced_sleep", false):
		GameState.flags.erase("forced_sleep")
		await _sleep(true)
		return
	if not GameState.flags.get("home_intro", false):
		GameState.flags["home_intro"] = true
		await Ui.say([
			"* Questa è casa tua. Cioè: era di tuo padre. Adesso è tua, con tutto quello che c'era dentro.",
			"* I mobili, gli scatoloni, il robot giocattolo. E il debito, che non sta in nessuno scatolone ma occupa tutta la stanza.",
			"* Nel letto puoi far passare la notte. Sul computer lampeggia una email.",
		])
	await show_pending()


func _computer() -> void:
	var lines := [
		"* BANCA FIDUCIA S.p.A. - Estratto conto.",
		"* Debito residuo: {debt}. Gli interessi corrono ogni notte.",
	]
	if not GameState.has_badge("cima") and not GameState.worked_today:
		lines.append("* Nuova email da CHEAP S.p.A.: \"Per salire: badge. Per il badge: lavoro. Per il lavoro: sorriso. La Cima la aspetta.\"")
	elif GameState.worked_today:
		lines.append("* Nessuna nuova email. Il lavoro di oggi è fatto: puoi andare a dormire quando vuoi.")
	else:
		lines.append("* CHEAP S.p.A.: \"Ti aspettiamo in ufficio. Il tempo è denaro. Il tuo, soprattutto.\"")
	await Ui.say(lines)


func _robot_toy() -> void:
	await Ui.say([
		"* Il robot giocattolo che ti aveva regalato tuo padre.",
		"* \"Un giorno faranno tutto loro\", diceva. \"E noi cosa faremo?\"",
	])


func _sleep(forced := false) -> void:
	if not forced and not GameState.worked_today:
		var c: int = await Ui.choose("Oggi non hai lavorato. Vuoi dormire lo stesso?", ["Dormi", "Non ancora"])
		if c != 0:
			return
	if not GameState.worked_today:
		GameState.refuse_work()

	# i soldi si danno alla banca o allo sportello dei badge: il letto fa solo passare la notte
	var paid_minimum := true

	# Ti sdrai davvero nel letto, con la musica della notte.
	var bedtime := GameState.minutes
	Ui.cutscene = true
	player.lie_down(BED_TOP)
	Sound.music("notte")
	await get_tree().create_timer(1.4).timeout
	Ui.show_hud(false)
	await SleepCutscene.play(self, bedtime)
	GameState.end_day(paid_minimum)
	if GameState.debt <= 0:
		Router.goto(Router.ENDING, "", ["Il debito è pagato.", "Per la prima volta da quando sei arrivato, dormi senza sognare la banca.", "Al risveglio, però, qualcosa è cambiato."])
		return
	GameState.save_game(Router.HOME)
	Router.goto(Router.HOME, "wake", ["Un'altra mattina.", "Durante la notte gli interessi hanno lavorato al posto tuo.\nDebito: {debt}."])


## Il risveglio: sei ancora nel letto, la sveglia suona (prima del testo, così si sente sempre),
## poi esci dal letto.
func _wake_up() -> void:
	Ui.cutscene = true
	Sound.music("notte")
	Sound.sfx("alarm")
	await get_tree().create_timer(0.9).timeout
	Sound.sfx("alarm")
	await get_tree().create_timer(0.6).timeout
	Sound.sfx("alarm")
	await Ui.say(["* DRIIIIN! DRIIIIN!", "* Sono le {clock}. Devi svegliarti.", "* Il debito si è svegliato prima di te."])
	Sound.music(music)
	await player.get_up(cell_feet(Vector2i(4, 4)))
	Ui.cutscene = false
