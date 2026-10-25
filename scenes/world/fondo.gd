extends Room
## Il piano -5, il Fondo. L'ascensore dell'inizio si rompe qui.
## È tutto buio, tranne il cerchio di luce intorno a Fermo, seduto accanto all'ascensore:
## finché non gli parli, il buio non ti lascia andare da nessuna parte.
## Fermo ti spiega come funziona (lavora, paga, sali) con la sua vita piatta.
## Poi accende la luce: a sinistra la cyclette-dinamo (il lavoro), a destra il distributore
## dei badge e il tornello con le scale per il piano -4.

const RB := "tiles/room_builder.png"
const W := 24
const H := 14
const FERMO_CELL := Vector2i(14, 4)
## Il recinto di buio intorno all'ascensore, finché non hai parlato con Fermo.
const DARK_BOX := Rect2i(9, 3, 8, 4)
## Altezza del tubo che corre lungo la base del muro.
const PIPE_Y := 2 * T + 9

var _modulate: CanvasModulate
var _dark_walls: Node2D
var _lamps: Array[ColorRect] = []
var _fermo: AnimatedSprite2D
var _fermo_light: PointLight2D
var _last_dark_msg := -10.0


func build() -> void:
	floor_id = "-5"
	music = "fondo"
	var floor_def := {"tex": RB, "at": func(c: Vector2i) -> Vector2i: return Vector2i(46 + c.x % 3, 25 + c.y % 2)}
	var rows: Array = ["#".repeat(W), "#" + "W".repeat(W - 2) + "#", "#" + "w".repeat(W - 2) + "#"]
	for y in H - 4:
		rows.append("#" + ".".repeat(W - 2) + "#")
	rows.append("#".repeat(W))
	paint(rows, {
		"#": {"tex": RB, "at": Vector2i(12, 0), "solid": true},
		"W": {"tex": RB, "at": Vector2i(23, 13), "solid": true},
		"w": {"tex": RB, "at": Vector2i(23, 14), "solid": true},
		".": floor_def,
		"_floor": floor_def,
	})

	_broken_lift(Vector2i(11, 1))
	_pipes()
	var plate := add_art("res://art/plate_piano5.png", Vector2i(6, 2), 0, Vector2(2, -8))
	plate.z_index = 0

	# Fermo, seduto su una cassetta accanto all'ascensore
	add_prop("street/box_trash.png", FERMO_CELL, 1, Vector2i(16, 16))
	_fermo = AnimatedSprite2D.new()
	_fermo.sprite_frames = Assets.character("char_14")
	_fermo.centered = false
	_fermo.offset = Vector2(-11, -37)
	_fermo.position = cell_feet(FERMO_CELL) + Vector2(0, 1)
	_fermo.play("sit_left")
	world.add_child(_fermo)
	add_prop("street/cardboard.png", FERMO_CELL + Vector2i(1, 0), 0, Vector2i(16, 16), ["* Il cartone dove dorme Fermo. Ha la forma di Fermo."])
	block(Rect2i(FERMO_CELL, Vector2i.ONE))
	add_spot(cell_center(FERMO_CELL), _talk_fermo)

	# A sinistra: il lavoro. Due cyclette con la dinamo, una occupata.
	add_art("res://art/generator.png", Vector2i(3, 6), 1)
	add_art("res://art/generator.png", Vector2i(3, 10), 1)
	var rider := AnimatedSprite2D.new()
	rider.sprite_frames = Assets.character("char_16")
	rider.centered = false
	rider.offset = Vector2(-8, -36)
	rider.position = cell_feet(Vector2i(4, 10)) + Vector2(2, -3)
	rider.play("walk_left")
	rider.speed_scale = 0.6
	world.add_child(rider)
	add_spot(cell_center(Vector2i(4, 10)), func() -> void:
		await Ui.say(["* Una ragazza pedala nel buio. Non si gira.",
			"Non parlo. Se parlo perdo il ritmo. Se perdo il ritmo, lassù si spegne qualcosa."], "Qualcuno al buio"))
	add_station("fondo")
	spawn_people("fondo")

	# A destra: il distributore dei badge, il tornello, le scale per il -4
	add_badge_machine(Vector2i(18, 3))
	add_stairs_up(Vector2i(21, 3), Router.SOTTOUFFICIO, "from_below", "-4")

	# Cose dimenticate quaggiù
	add_prop("props/boxes.png", Vector2i(1, 4), 2, Vector2i(32, 32), ["* Scatoloni di lampadine fulminate. Su uno c'è scritto: \"RESI DAL PIANO TERRA\"."])
	add_prop("street/trash_bags.png", Vector2i(20, 12), 2, Vector2i(32, 32), ["* Sacchi neri. Uno si muove. Meglio non sapere."])
	add_prop("bath/bucket.png", Vector2i(16, 11), 1, Vector2i(16, 32), ["* Un secchio sotto una goccia che cade dal soffitto. È pieno da anni."])
	add_prop("props/boxes_small.png", Vector2i(9, 12), 2, Vector2i(16, 32))
	examine(cell_center(Vector2i(8, 1)) + Vector2(0, 16), ["* Una targa: PIANO -5. Sotto, graffiato a mano: \"il fondo non è mai il fondo\"."])
	add_save_point(Vector2i(12, 9))

	_lights()
	if not GameState.flags.get("fermo_talked", false):
		_build_dark_box()

	spawns["default"] = cell_feet(Vector2i(11, 3))
	spawns["elevator"] = spawns["default"]
	spawn_facing["default"] = "down"
	spawns["from_above"] = cell_feet(Vector2i(21, 5))
	spawn_facing["from_above"] = "down"


func enter() -> void:
	_player_light()
	if not GameState.flags.get("fermo_talked", false) and not GameState.flags.get("fermo_called", false):
		GameState.flags["fermo_called"] = true
		await get_tree().create_timer(0.6).timeout
		await Ui.say(["* Una voce, dal buio:",
			"...Ehi. Tu. Vieni qui, alla luce. Non mordo. Non ho più i denti per mordere."], "???", "char_14")
	await show_pending()


# --- luce e buio -------------------------------------------------------------

func _light_texture(size := 128) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.55, Color(1, 1, 1, 0.55))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	t.width = size
	t.height = size
	return t


func _add_light(pos: Vector2, scale_: float, color: Color, energy := 1.0) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = _light_texture()
	l.texture_scale = scale_
	l.color = color
	l.energy = energy
	l.position = pos
	add_child(l)
	return l


func _lights() -> void:
	var lit: bool = GameState.flags.get("fermo_talked", false)
	_modulate = CanvasModulate.new()
	_modulate.color = _lit_color() if lit else Color(0.035, 0.03, 0.05)
	add_child(_modulate)
	# il cerchio di Fermo: una lampadina appesa con un filo al tubo che corre lungo il muro.
	# Sta nel mondo ordinato per y, all'altezza della riga sotto al muro: chi passa davanti la copre.
	var bulb_pos := Vector2(FERMO_CELL.x * T - 7, PIPE_Y + 9)
	var hang := Node2D.new()
	hang.position = Vector2(bulb_pos.x, 3 * T + 2)
	world.add_child(hang)
	var clamp_ := ColorRect.new()
	clamp_.color = Color("6b6878")
	clamp_.position = Vector2(-2, PIPE_Y - 1 - hang.position.y)
	clamp_.size = Vector2(5, 5)
	hang.add_child(clamp_)
	var wire := ColorRect.new()
	wire.color = Color("1a1622")
	wire.position = Vector2(0, PIPE_Y + 3 - hang.position.y)
	wire.size = Vector2(1, bulb_pos.y - PIPE_Y - 3)
	hang.add_child(wire)
	var bulb := ColorRect.new()
	bulb.color = Color("ffe9a8")
	bulb.position = Vector2(-2, bulb_pos.y - hang.position.y)
	bulb.size = Vector2(4, 4)
	hang.add_child(bulb)
	_fermo_light = _add_light(bulb_pos + Vector2(0, 22), 1.15, Color(1.0, 0.86, 0.6) if not lit else Color(0.7, 0.6, 0.45), 1.25)
	var fermo_light := _fermo_light
	var tw := fermo_light.create_tween().set_loops()
	tw.tween_property(fermo_light, "energy", 1.1, 1.3).set_trans(Tween.TRANS_SINE)
	tw.tween_property(fermo_light, "energy", 1.3, 1.3).set_trans(Tween.TRANS_SINE)
	# le lampadine del soffitto (si accendono quando Fermo tira il filo)
	for x in [4, 18]:
		var lamp := ColorRect.new()
		lamp.color = Color("ffe9a8") if lit else Color("3a3644")
		lamp.position = Vector2(x * T + 4, 2 * T + 2)
		lamp.size = Vector2(8, 4)
		add_child(lamp)
		move_child(lamp, world.get_index())
		_lamps.append(lamp)
		if lit:
			_add_light(Vector2(x * T + 8, 6 * T), 2.2, Color(1.0, 0.9, 0.7), 0.7)
	# il display rotto dell'ascensore, rosso
	_add_light(cell_center(Vector2i(11, 1)) + Vector2(8, 4), 0.35, Color(1, 0.25, 0.2), 0.9)


func _lit_color() -> Color:
	return Color(0.32, 0.3, 0.38)


func _player_light() -> void:
	if player == null:
		return
	var l := PointLight2D.new()
	l.texture = _light_texture()
	l.texture_scale = 0.45
	l.color = Color(0.7, 0.75, 1.0)
	l.energy = 0.55
	l.position = Vector2(0, -10)
	player.add_child(l)


## Accende la luce del piano, con lo sfarfallio delle lampadine vecchie.
func _lights_on() -> void:
	Sound.sfx("spark")
	for i in 5:
		var on := i % 2 == 0
		for lamp in _lamps:
			lamp.color = Color("ffe9a8") if on else Color("3a3644")
		_modulate.color = Color(0.2, 0.19, 0.25) if on else Color(0.05, 0.045, 0.07)
		await get_tree().create_timer(0.07 + randf() * 0.1).timeout
	for lamp in _lamps:
		lamp.color = Color("ffe9a8")
		_add_light(Vector2(lamp.position.x + 4, 6 * T), 2.2, Color(1.0, 0.9, 0.7), 0.7)
	var tw := create_tween()
	tw.tween_property(_modulate, "color", _lit_color(), 0.8)
	tw.parallel().tween_property(_fermo_light, "color", Color(0.7, 0.6, 0.45), 0.8)
	await tw.finished


## Finché non parli con Fermo, il buio fa da muro (e te lo dice).
func _build_dark_box() -> void:
	_dark_walls = Node2D.new()
	add_child(_dark_walls)
	var body := StaticBody2D.new()
	_dark_walls.add_child(body)
	var r := DARK_BOX
	var walls := [
		Rect2(r.position.x * T - T, r.position.y * T, T, r.size.y * T),
		Rect2(r.end.x * T, r.position.y * T, T, r.size.y * T),
		Rect2(r.position.x * T - T, r.end.y * T, (r.size.x + 2) * T, T),
	]
	for w: Rect2 in walls:
		var shape := RectangleShape2D.new()
		shape.size = w.size
		var col := CollisionShape2D.new()
		col.shape = shape
		col.position = w.get_center()
		body.add_child(col)
		# una fascia appena dentro: quando ci arrivi, il buio ti parla
		var a := Area2D.new()
		var s2 := RectangleShape2D.new()
		s2.size = w.size + Vector2(6, 6)
		var c2 := CollisionShape2D.new()
		c2.shape = s2
		c2.position = w.get_center()
		a.add_child(c2)
		_dark_walls.add_child(a)
		a.body_entered.connect(_on_dark)


func _on_dark(b: Node2D) -> void:
	if not (b is Player) or Ui.blocks_input():
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_dark_msg < 3.0:
		return
	_last_dark_msg = now
	await Ui.say([["* È troppo buio. Non vedi dove metti i piedi.", "* Fai un passo nel buio. Il pavimento sembra finire. Torni indietro.",
		"* Il buio è così fitto che sembra di toccarlo."].pick_random(), "* L'unica luce è quella vicino all'uomo seduto."])


# --- Fermo ---------------------------------------------------------------------

func _talk_fermo() -> void:
	_fermo.play("sit_left")
	if not GameState.flags.get("fermo_talked", false):
		await _first_talk()
		return
	var who := "Fermo"
	if GameState.flags.get("pity_fermo", false) and not GameState.flags.get("fermo_pity_line", false):
		GameState.flags["fermo_pity_line"] = true
		await Ui.say(["Non ringraziarmi. Se mi ringrazi mi viene da pensare a cosa ho fatto.",
			"Adesso sali. Se resti qui, quei soldi li ho buttati. E io non butto niente: nemmeno le gocce del secchio."], who)
		return
	if GameState.flags.get("contracts", 0) > 0 and not GameState.flags.get("fermo_rata_line", false):
		GameState.flags["fermo_rata_line"] = true
		await Ui.say(["Hai firmato col Signor Rata.", "...Anche io, undici anni fa. Avevo quattromila euro di debito. Ricordi?"], who)
		return
	if GameState.has_badge("-4") and not GameState.flags.get("fermo_badge_line", false):
		GameState.flags["fermo_badge_line"] = true
		await Ui.say(["Hai il badge. ...Bene.", "Non voltarti, quando sali. Fa male, voltarsi. Lo dico per te, non per me.",
			"Se lassù vedi qualcuno con la mia faccia, digli che la luce funziona ancora."], who)
		return
	if GameState.worked_today:
		await Ui.say([["Hai pedalato. Lo sento nelle gambe anche io. Strano, no?",
			"La lampadina di sopra ha fatto un respiro più forte. Eri tu.",
			"Bravo. Domani uguale. E dopodomani. Poi smetti di contare, e diventa facile."].pick_random()], who)
		return
	await Ui.say([["Il distributore dei badge non sbaglia mai i conti. Solo i tuoi.",
		"Io ogni tanto conto le gocce del secchio. Sono arrivato a novantamila. Poi ho perso il conto e ho ricominciato. È rilassante.",
		"Non guardare le scale troppo a lungo. Ti viene voglia.",
		"Una volta qui c'era un altro ascensore. Funzionava. Lo hanno venduto al piano di sopra."].pick_random()], who)


func _first_talk() -> void:
	var who := "Fermo"
	GameState.flags["met_fermo"] = true
	await Ui.say(["...Oh. Un'altra persona.",
		"Pensavo che l'ascensore non portasse più nessuno, quaggiù. Di solito si rompe prima.",
		"Io sono Fermo. Di nome e di fatto, dicono. Ridono sempre, quelli che lo dicono. Io no.",
		"E tu? ...{name}. Bel nome. Tienilo stretto: quaggiù i nomi si consumano in fretta."], who)
	var c: int = await Ui.choose("Tu quanto devi?", ["Sette miliardi.", "Non sono affari tuoi."], who)
	if c == 0:
		await Ui.say(["Seimila. Ah. Io, quando sono arrivato, ne dovevo quattromila.",
			"Lavoro qui da undici anni. Adesso ne devo novemila. Non chiedermi come. Non lo so più neanche io."], who)
	else:
		await Ui.say(["Giusto. Tanto lo so già: lo scrivono sul display dell'ascensore. Lo scrivono sempre.",
			"Io, quando sono arrivato, ne dovevo quattromila. Adesso novemila. Undici anni."], who)
	await Ui.say(["Funziona così. Te lo dico una volta sola, perché a me l'hanno detto una volta sola.",
		"Lavori. Laggiù, a sinistra, c'è la cyclette: pedali, e la dinamo accende le luci dei piani di sopra. Noi stiamo al buio.",
		"Ti pagano. Coi soldi compri il badge. Col badge passi il tornello e sali le scale. Un piano alla volta.",
		"Ogni piano costa di più. Il badge non è un regalo: è una rata del tuo debito, con un nastrino.",
		"E il tempo, qui, non lo conta nessuno. Ma lui conta te: ogni notte il debito cresce un po'. Anche se dormi. Soprattutto se dormi."], who)
	await Ui.say(["Io non salgo più. Ho fatto i conti: se pedalo fino a morire, arrivo al -4 il giorno del mio funerale.",
		"Non è triste. È solo... piatto. Lavori, dormi, lavori. Un giorno ti fermi. Ma non perché l'hai deciso tu."], who)
	c = await Ui.choose("", ["E se smettessi di lavorare?", "Allora perché resti qui?"], who)
	if c == 0:
		await Ui.say(["Smettere?", "...E poi cosa faccio, con le mani?"], who)
		await Ui.say(["* Ti guarda come se avessi detto una parolaccia. Poi, per un secondo, quasi sorride."])
		GameState.flags["fermo_smettere"] = true
	else:
		await Ui.say(["Perché qui almeno so dove sono.", "Lassù dicono che è peggio. C'è luce, e ti vedono tutti."], who)
	await Ui.say(["Ah. Le stelline. Se ne vedi una, toccala. Ti ricorda perché vai avanti. Io la mia non la guardo più.",
		"Le stelline fanno anche passare la notte, se vuoi. Ma la notte costa: chiedi agli interessi.",
		"E se lassù qualcuno ti offre di salire più in fretta... pensaci. Chi sale troppo in fretta, in cima non ci arriva intero.",
		"Vai. Accendo la luce, così non inciampi. È l'unica cosa che so fare bene."], who)
	GameState.flags["fermo_talked"] = true
	_fermo.play("idle_left")
	await get_tree().create_timer(0.4).timeout
	await _lights_on()
	_fermo.play("sit_left")
	if _dark_walls:
		_dark_walls.queue_free()
		_dark_walls = null
	await Ui.say(["* Fermo ha tirato un filo. Le lampadine del soffitto si accendono, gialle e stanche.",
		"* Adesso vedi il piano -5: le cyclette a sinistra, il distributore dei badge e le scale a destra."])


# --- arredi --------------------------------------------------------------------

## L'ascensore dell'inizio: porte incastrate a metà, dentro è buio, il display lampeggia -5.
func _broken_lift(top_left: Vector2i) -> void:
	var frame := ColorRect.new()
	frame.color = Color("4a4658")
	frame.position = Vector2(top_left.x * T, top_left.y * T + 4)
	frame.size = Vector2(2 * T, 2 * T - 4)
	world.add_child(frame)
	var inside := ColorRect.new()
	inside.color = Color("0c0a10")
	inside.position = frame.position + Vector2(2, 3)
	inside.size = Vector2(2 * T - 4, frame.size.y - 3)
	world.add_child(inside)
	for k in 2:
		var door := ColorRect.new()
		door.color = Color("aeb4c4")
		door.position = frame.position + Vector2(2 + k * 20, 3)
		door.size = Vector2(8, frame.size.y - 3)
		world.add_child(door)
	var disp := Label.new()
	disp.text = "-5"
	disp.add_theme_font_size_override("font_size", 8)
	disp.add_theme_color_override("font_color", Color("e8453a"))
	disp.position = frame.position + Vector2(10, -12)
	disp.z_index = 6
	add_child(disp)
	var tw := disp.create_tween().set_loops()
	tw.tween_property(disp, "modulate:a", 0.15, 0.08)
	tw.tween_interval(randf_range(0.4, 1.4))
	tw.tween_property(disp, "modulate:a", 1.0, 0.05)
	tw.tween_interval(1.2)
	examine(cell_center(top_left + Vector2i(0, 2)) + Vector2(8, 0), [
		"* L'ascensore. Le porte si sono incastrate a metà. Dentro, la pulsantiera è morta.",
		"* Il display continua a lampeggiare: -5, -5, -5. Come se non ci credesse nemmeno lui.",
	])


## Il tubo lungo il muro: fa parte del muro, quindi sta dietro alle persone.
func _pipes() -> void:
	var pipe := ColorRect.new()
	pipe.color = Color("3d3a48")
	pipe.position = Vector2(T, PIPE_Y)
	pipe.size = Vector2((W - 2) * T, 3)
	add_child(pipe)
	move_child(pipe, world.get_index())
