extends EditorRoom
## Capitolo 1 — Il Fondo (piano -5). La scena è fatta nell'editor (fondo.tscn):
## qui c'è solo la logica. Il Fondo sembra una festa: colori, palloncini, una torta.
## Ma la festa è per la CHEAP, e i colori li accende la tua fatica (la rivelazione arriva
## dopo il primo turno: vedi docs/capitoli/capitolo_1_il_fondo.md).

const FERMO_CELL := Vector2i(14, 4)
## Lo straordinario dopo la rivelazione: paga di ognuna delle tre pedalate in più.
const EXTRA_PAY := [120, 70, 35]


func setup() -> void:
	_lift(Vector2i(11, 1))
	if GameState.flags.get("c1_rivelazione", false):
		_switch_off(false)
		Sound.call_deferred("music_pitch", 0.75, 0.1)


func enter() -> void:
	if not GameState.flags.get("c1_arrivo", false):
		GameState.flags["c1_arrivo"] = true
		await get_tree().create_timer(0.4).timeout
		await Ui.say([
			"* Le porte si aprono su una festa.",
			"* Festoni, palloncini, coriandoli per terra. Una voce registrata, allegrissima:",
			"\"Benvenuto al Fondo! Il posto più felice della torre!\"",
		])
		# dietro di te, l'ascensore crolla
		await get_tree().create_timer(0.3).timeout
		Sound.sfx("clunk")
		Sound.sfx("spark", 0.8)
		_shake(0.6)
		_break_lift()
		await get_tree().create_timer(0.6).timeout
		await Ui.say([
			"* Dietro di te, uno schianto. Le porte dell'ascensore si piegano, la luce dentro si spegne.",
			"* La musica della festa non si ferma. Nessuno si gira. Anzi, sì: uno.",
			"* In mezzo a tutti quei colori c'è un uomo grigio, seduto su una cassetta. È l'unico che non sorride.",
		])
	if GameState.flags.get("c1_relight", false):
		GameState.flags.erase("c1_relight")
		await _relight()
	await show_pending()


## Sul primo gradino, col badge in mano: la festa si spegne. E tu scegli.
func on_stairs_step(p: Player, _need: String) -> void:
	if GameState.flags.get("c1_rivelazione", false):
		return
	Ui.cutscene = true
	p.position.y += 4
	await _revelation()
	# nessuna domanda: o sali, o ti volti. Lo decidi coi piedi.
	await Ui.say(["* Le scale ti aspettano. Dietro di te, nel grigio, le persone sembrano più vere."])
	Ui.cutscene = false


# --- lo straordinario: la festa si riaccende, per poco ---------------------------

## Dopo la rivelazione la cyclette resta accesa: puoi pedalare ancora, al massimo tre volte.
## Ogni volta è più dura e paga meno, ma per cinque secondi la festa torna.
func _station(j: Dictionary) -> void:
	if str(j.get("game", "")) != "pedal" or not GameState.flags.get("c1_rivelazione", false):
		await super(j)
		return
	var n := int(GameState.flags.get("c1_extra", 0))
	if n >= EXTRA_PAY.size():
		await Ui.say(["* Sali sulla cyclette. Le gambe non rispondono più.",
			"* La festa resta spenta. Forse è giusto così."])
		return
	var c: int = await Ui.choose("La cyclette è ancora accesa. Straordinario: %s, più duro di prima.\nPedalare ancora?" % GameState.euros(EXTRA_PAY[n]), ["Pedalo", "Basta"])
	if c != 0:
		return
	GameState.minigame = {
		"kind": "work", "game": "pedal", "name": "Straordinario %d/%d" % [n + 1, EXTRA_PAY.size()],
		"pay": EXTRA_PAY[n], "extra": n + 1, "extra_d": 0.25 * (n + 1),
		"intro": [["* Pedali di nuovo. La dinamo ti riconosce: ronza più forte, come un cane contento.",
			"* Le gambe se lo ricordano, il turno di prima. Lo dicono a ogni giro.",
			"* Ultima volta. Lo dici a te stesso. Lo diceva anche Fermo, undici anni fa."][n]],
		"tired": ["* Ti tremano le ginocchia.", "* Non senti più i piedi.", "* Non senti più niente. Quasi."][n],
		"return": scene_file_path, "return_pos": player.global_position,
	}
	Router.goto(Router.WORK)


## Hai pedalato ancora: per cinque secondi la festa torna, poi si rispegne.
func _relight() -> void:
	if _off_mat == null:
		return
	Ui.cutscene = true
	var n := int(GameState.flags.get("c1_extra", 1))
	var balloons := find_children("Palloncino*", "Sprite2D", true, false)
	var garlands := find_children("Festone*", "Sprite2D", true, false)
	await get_tree().create_timer(0.4).timeout
	Sound.sfx("spark", 1.4)
	Sound.music_pitch(1.0, 0.6)
	var on := create_tween().set_parallel()
	on.tween_method(func(v: float) -> void: _off_mat.set_shader_parameter("amount", v), 1.0, 0.0, 0.6)
	on.tween_property(_tint, "color", Color.WHITE, 0.6)
	for b in balloons:
		on.tween_property(b, "scale:y", 1.0, 0.5).set_trans(Tween.TRANS_BACK)
		on.tween_property(b, "position:y", (b as Node2D).position.y - 6, 0.5)
	for f in garlands:
		on.tween_property(f, "rotation", 0.0, 0.4)
		on.tween_property(f, "position:y", (f as Node2D).position.y - 10, 0.4)
	Sound.sfx("flap", 1.3)
	await on.finished
	await get_tree().create_timer(5.0).timeout
	# e si rispegne
	Sound.music_pitch(0.75, 1.5)
	var off := create_tween().set_parallel()
	off.tween_method(func(v: float) -> void: _off_mat.set_shader_parameter("amount", v), 0.0, 1.0, 1.5)
	off.tween_property(_tint, "color", _tint_target, 1.5)
	for b in balloons:
		off.tween_property(b, "scale:y", 0.45, 0.6).set_delay(randf() * 0.6)
		off.tween_property(b, "position:y", (b as Node2D).position.y + 6, 0.6)
	for f in garlands:
		off.tween_property(f, "rotation", 0.25 if randf() < 0.5 else -0.2, 0.4).set_delay(0.5)
		off.tween_property(f, "position:y", (f as Node2D).position.y + 10, 0.4).set_delay(0.5)
	Sound.sfx("flap", 0.6)
	await off.finished
	await Ui.say([[
		"* Per cinque secondi la festa è tornata. Ti è costata un turno di gambe.",
		"* Stavolta i cinque secondi sembravano meno. Forse sei tu che guardi più forte.",
		"* Tre volte l'hai riaccesa. Tre volte si è spenta. Laggiù nessuno ha alzato la testa.",
	][clampi(n - 1, 0, 2)]])
	Ui.cutscene = false


# --- lo sguardo indietro: fine del capitolo 1 ----------------------------------------

## In cima alle scale, la prima volta: ti volti a guardare il Fondo com'è diventato.
func on_stairs_top(p: Player) -> bool:
	if GameState.flags.get("c1_fine", false):
		return false
	GameState.flags["c1_fine"] = true
	# se sali senza aver ascoltato nessuno, le scale dietro di te si chiudono
	var heard := false
	for id in ["fermo", "mina", "bulbo"]:
		heard = heard or GameState.flags.get("svelato_" + id, false)
	GameState.flags["c1_sbarrato"] = not heard
	_look_back(p)
	return true


func _look_back(p: Player) -> void:
	Ui.cutscene = true
	Ui.show_hud(false)
	if GameState.flags.get("c1_sbarrato", false):
		Sound.sfx("stamp", 0.6)
		await Ui.say(["* Non ti volti. Dietro di te, qualcosa si chiude con un colpo secco.",
			"* Le scale per il Fondo, da adesso, vanno in una sola direzione."])
		Ui.cutscene = true
	p.set_physics_process(false)
	p.face("down")
	# la telecamera si allarga su tutto il Fondo, com'è diventato (Fermo laggiù, in mezzo)
	# solo il pavimento e i muri: niente bordo scuro, niente fuori-mappa
	var inner := cam_rect
	var fit := maxf(640.0 / inner.size.x, 360.0 / inner.size.y)
	var half := Vector2(320, 180) / fit
	var look := (inner.get_center() + Vector2(0, 10)).clamp(inner.position + half, inner.end - half)
	var cam := p.camera
	Sound.music_pitch(0.6, 4.0)
	# la telecamera si stacca dal giocatore (così i bordi della stanza la tengono dentro)
	var from := cam.get_screen_center_position()
	cam.position_smoothing_enabled = false
	cam.top_level = true
	cam.global_position = from
	var tw := create_tween()
	tw.tween_property(cam, "global_position", look, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(cam, "zoom", Vector2(fit, fit), 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	await get_tree().create_timer(0.8).timeout
	# una frase sola, quella che ti sei guadagnato
	var layer := CanvasLayer.new()
	layer.layer = 15
	add_child(layer)
	# la frase in basso, su una striscia scura, per non coprire il Fondo
	var band := ColorRect.new()
	band.color = Color(0, 0, 0, 0)
	band.position = Vector2(0, 290)
	band.size = Vector2(640, 70)
	layer.add_child(band)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0)
	shade.size = Vector2(640, 360)
	layer.add_child(shade)
	var line := _big_label(layer, _look_back_line(), Vector2(40, 292), Vector2(560, 66), 13, Color.WHITE)
	line.modulate.a = 0.0
	var a := create_tween().set_parallel()
	a.tween_property(band, "color:a", 0.75, 1.2)
	a.tween_property(line, "modulate:a", 1.0, 1.2)
	await a.finished
	await get_tree().create_timer(4.0).timeout
	# buio, poi il capitolo 2
	var b := create_tween()
	b.tween_property(line, "modulate:a", 0.0, 0.8)
	b.tween_property(shade, "color:a", 1.0, 1.0)
	await b.finished
	Sound.music("")
	var small := _big_label(layer, "CAPITOLO 2", Vector2(0, 138), Vector2(640, 24), 13, Color("8a8494"))
	var big := _big_label(layer, "IL SOTTOUFFICIO", Vector2(0, 162), Vector2(640, 40), 26, Color("ffe14d"))
	small.modulate.a = 0.0
	big.modulate.a = 0.0
	var c := create_tween()
	c.tween_property(small, "modulate:a", 1.0, 0.8)
	c.tween_property(big, "modulate:a", 1.0, 0.8)
	Sound.sfx("stamp", 0.8)
	await c.finished
	await get_tree().create_timer(2.0).timeout
	Ui.cutscene = false
	Router.goto(Router.SOTTOUFFICIO, "from_below", ["Piano -4."])


## La frase dello sguardo indietro: dipende da cosa hai fatto al Fondo.
func _look_back_line() -> String:
	if GameState.is_robot("fermo"):
		return "Laggiù, Fermo sorride.\nÈ l'unica luce rimasta accesa. L'hai accesa tu, col suo quaderno."
	if GameState.flags.get("c1_sbarrato", false):
		return "Laggiù è tutto grigio, e tu non sai perché.\nNon ti sei voltato. Adesso, voltarsi non serve più."
	if int(GameState.flags.get("c1_extra", 0)) >= EXTRA_PAY.size():
		return "Laggiù, la cyclette gira ancora un po' da sola.\nHai riacceso la festa tre volte. Nessuno ti ha detto grazie."
	var truths := 0
	for id in ["fermo", "mina", "bulbo"]:
		if GameState.flags.get("svelato_" + id, false):
			truths += 1
	if truths >= 3:
		return "Laggiù è tutto grigio. Ma adesso sai di chi sono i colori.\nFermo alza una mano. Forse ti saluta. Forse si stiracchia."
	if _helped_here():
		return "Laggiù è grigio, ma un grigio caldo.\nDove hai dato una mano, qualcuno sta ancora parlando di te."
	return "Laggiù, Fermo è ancora seduto sulla sua cassetta.\nNon ti guarda salire. Non lo fa mai. Fa troppo male."


func _big_label(parent: Node, text: String, pos: Vector2, size: Vector2, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l


# --- Fermo ------------------------------------------------------------------------

func _talk_fermo() -> void:
	if GameState.is_robot("fermo"):
		# gli hai preso il quaderno: adesso sorride, come i poster
		await Ui.say(["* Fermo ti guarda. Per la prima volta, sorride.",
			"* È lo stesso sorriso dei palloncini. Uguale, preciso, gonfio.",
			"Buona festa, {rank}."], "Fermo")
		return
	if not GameState.flags.get("fermo_talked", false):
		await _first_talk()
		return
	var who := "Fermo"
	if GameState.flags.get("c1_rivelazione", false) and not GameState.flags.get("svelato_fermo", false):
		GameState.flags["svelato_fermo"] = true
		await Ui.say(["Adesso lo vedi.",
			"La festa la fanno per chi arriva. Così, i primi giorni, non guardi dove sei.",
			"I colori li accendiamo noi, pedalando. Ogni palloncino gonfio è un'ora di qualcuno. Spesso la mia.",
			"E il badge... il badge ti porta dove si pedala di meno e si guarda di più. Lassù i colori sono più belli. E più cari.",
			"Le uniche cose che restano colorate sono quelle che vogliono qualcosa da te. Ricordatelo, quando sali."], who)
		return
	if GameState.flags.get("pity_fermo", false) and not GameState.flags.get("fermo_pity_line", false):
		GameState.flags["fermo_pity_line"] = true
		await Ui.say(["Non ringraziarmi. Se mi ringrazi mi viene da pensare a cosa ho fatto.",
			"Adesso sali. Se resti qui, quei soldi li ho buttati."], who)
		return
	if GameState.has_badge("-4") and not GameState.flags.get("fermo_badge_line", false):
		GameState.flags["fermo_badge_line"] = true
		await Ui.say(["Hai il badge. ...Bene.", "Non voltarti, quando sali. Fa male, voltarsi.",
			"Se lassù vedi qualcuno con la mia faccia, digli che qui sotto la festa continua. Da sola."], who)
		return
	if GameState.worked_today:
		await Ui.say([["Hai pedalato. I palloncini sono belli gonfi, oggi. Grazie a te.",
			"La torta è ancora lì. Nessuno la mangia. È di plastica, come tutto.",
			"Bravo. Domani uguale. E dopodomani. Poi smetti di contare, e diventa facile."].pick_random()], who)
		return
	await Ui.say([["Ogni volta che arriva qualcuno fanno la festa. Costa meno di uno stipendio.",
		"I palloncini li gonfiano di sopra. Quaggiù arrivano già un po' sgonfi.",
		"Non guardare le scale troppo a lungo. Ti viene voglia.",
		"Una volta mi hanno fatto la festa anche a me. Undici anni fa. La torta era la stessa."].pick_random()], who)


func _first_talk() -> void:
	var who := "Fermo"
	GameState.flags["met_fermo"] = true
	await Ui.say(["...Oh. Un'altra persona.",
		"La festa non è per te, se te lo stai chiedendo. È per la CHEAP. La fanno ogni volta che arriva qualcuno.",
		"Io sono Fermo. Di nome e di fatto, dicono. Ridono sempre, quelli che lo dicono. Io no.",
		"E tu? ...{name}. Bel nome. Tienilo stretto: quaggiù i nomi si consumano in fretta."], who)
	var c: int = await Ui.choose("Tu quanto devi?", ["Sette miliardi.", "Non sono affari tuoi."], who)
	if c == 0:
		await Ui.say(["Sette miliardi. Ah. Io, quando sono arrivato, ne dovevo quattro.",
			"Lavoro qui da undici anni. Adesso ne devo nove. Di miliardi. Non chiedermi come.",
			"Non fare quella faccia. Quaggiù nessuno deve meno di un miliardo. Fa curriculum."], who)
	else:
		await Ui.say(["Giusto. Tanto lo so già: ce l'hai scritto in faccia. Miliardi. Ce l'abbiamo tutti.",
			"Io, quando sono arrivato, ne dovevo quattro. Adesso nove. Undici anni."], who)
	await Ui.say(["Funziona così. Te lo dico una volta sola, perché a me l'hanno detto una volta sola.",
		"Lavori. Laggiù, a sinistra, c'è la cyclette: pedali, e la dinamo tiene accese le luci della festa. E quelle di sopra.",
		"Ti pagano. Coi soldi compri il badge allo sportello. Col badge passi il tornello e sali le scale.",
		"Il badge del -4 costa 500 euro. Non è un regalo: è una rata del tuo debito, con un nastrino.",
		"E ogni piano, il badge costa il doppio. Più sali, più costa salire. Dicono che è meritocrazia.",
		"Vedi quella scritta gialla che dondola, TURNO? È il posto dove oggi devi lavorare. Ci vai, tocchi, lavori.",
		"Finito il turno, la scritta sparisce. Torna il giorno dopo. Il giorno dopo arriva quando fai passare la notte a una stellina."], who)
	await Ui.say(["Io non salgo più. Ho fatto i conti: se pedalo fino a morire, arrivo al -4 il giorno del mio funerale.",
		"Non è triste. È solo... piatto. Lavori, dormi, lavori. Un giorno ti fermi. Ma non perché l'hai deciso tu."], who)
	c = await Ui.choose("", ["E se smettessi di lavorare?", "Perché sei l'unico che non sorride?"], who)
	if c == 0:
		await Ui.say(["Smettere?", "...E poi cosa faccio, con le mani?"], who)
		await Ui.say(["* Ti guarda come se avessi detto una parolaccia. Poi, per un secondo, quasi sorride."])
		GameState.flags["fermo_smettere"] = true
	else:
		await Ui.say(["Perché so cosa c'è sotto i colori.", "Pedala una volta, e lo saprai anche tu."], who)
	await Ui.say(["Ah. Quei due là, la piccola Bulbo e il vecchio Mina: parlaci. Qui sotto sono le uniche cose vere, a parte me.",
		"Le stelline fanno passare la notte, se vuoi. Ma la notte costa: chiedi agli interessi.",
		"Vai. La festa non si tiene accesa da sola."], who)
	GameState.flags["fermo_talked"] = true


# --- la rivelazione: i colori li fai tu ------------------------------------------

## Le cose della festa che si spengono: tutto tranne le cose finte (la cyclette, lo sportello),
## Fermo (già grigio) e il giocatore.
func _switchable() -> Array[CanvasItem]:
	var out: Array[CanvasItem] = []
	var skip := func(n: Node) -> bool:
		var cur := n
		while cur and cur != self:
			if cur == player or cur.has_meta("finto") or str(cur.name) in ["CycletteDinamo", "Fermo"]:
				return true
			cur = cur.get_parent()
		return false
	for layer_name in ["Pavimento", "Muri", "Decori", "Mondo"]:
		var layer := get_node_or_null(layer_name)
		if layer == null:
			continue
		var items: Array = [layer] if layer is TileMapLayer else layer.find_children("*", "CanvasItem", true, false)
		for n in items:
			if n is CanvasItem and (n as CanvasItem).material == null and not skip.call(n):
				out.append(n)
	return out


var _off_mat: ShaderMaterial
var _tint: CanvasModulate
var _tint_target := Color.WHITE


## Toglie il colore alla festa (con `slow`, piano piano).
func _switch_off(slow: bool) -> void:
	_off_mat = ShaderMaterial.new()
	_off_mat.shader = preload("res://shaders/greyscale.gdshader")
	_off_mat.set_shader_parameter("amount", 0.0 if slow else 1.0)
	_off_mat.set_shader_parameter("darken", 0.25)
	for n in _switchable():
		n.material = _off_mat
	# i palloncini restano sgonfi, i festoni caduti
	for n in find_children("Palloncino*", "Sprite2D", true, false):
		if not slow:
			n.scale.y = 0.45
			n.position.y += 6
	for n in find_children("Festone*", "Sprite2D", true, false):
		if not slow:
			n.rotation = 0.25 if int(str(n.name).right(1)) % 2 == 0 else -0.2
			n.position.y += 10
	# il Fondo prende la sfumatura delle tue scelte
	var tint := CanvasModulate.new()
	_tint = tint
	tint.color = Color.WHITE
	add_child(tint)
	var target := Color(0.96, 0.92, 0.86)
	if GameState.is_robot("fermo") or GameState.exploited > 0:
		target = Color(0.92, 1.0, 0.82)
	elif _helped_here():
		target = Color(1.0, 0.9, 0.78)
	_tint_target = target
	if slow:
		create_tween().tween_property(tint, "color", target, 3.0)
	else:
		tint.color = target


func _helped_here() -> bool:
	for id: String in GameState.floor_people("-5"):
		if id in GameState.helped_ids:
			return true
	return false


func _revelation() -> void:
	GameState.flags["c1_rivelazione"] = true
	Ui.cutscene = true
	await Ui.say(["* Metti il piede sul primo gradino.",
		"* Dietro di te, la musica della festa fa un singhiozzo. Qualcosa cambia."])
	Sound.music_pitch(0.75, 3.0)
	_switch_off(true)
	# i palloncini si sgonfiano, uno alla volta
	var balloons := find_children("Palloncino*", "Sprite2D", true, false)
	for b in balloons:
		var tw := create_tween()
		tw.tween_property(b, "scale:y", 0.45, 0.5).set_trans(Tween.TRANS_BACK)
		tw.parallel().tween_property(b, "position:y", (b as Node2D).position.y + 6, 0.5)
		Sound.sfx("flap", 0.6)
		await get_tree().create_timer(0.35).timeout
	# i festoni cadono
	for f in find_children("Festone*", "Sprite2D", true, false):
		var tw2 := create_tween()
		tw2.tween_property(f, "rotation", 0.25 if randf() < 0.5 else -0.2, 0.4)
		tw2.parallel().tween_property(f, "position:y", (f as Node2D).position.y + 10, 0.4)
	await get_tree().create_timer(0.4).timeout
	# il colore se ne va da tutto (tranne dalle cose finte)
	var fade := create_tween()
	fade.tween_method(func(v: float) -> void: _off_mat.set_shader_parameter("amount", v), 0.0, 1.0, 3.0)
	await fade.finished
	await Ui.say(["* La festa si è spenta. Restano accese solo la cyclette e lo sportello dei badge.",
		"* La cyclette, anzi, ronza ancora. Come se ti aspettasse."])
	if GameState.is_robot("fermo"):
		await Ui.say(["* ...Ma Fermo sta sorridendo. È l'unica cosa, qui, che non si è spenta. E non è sua."])
	elif _helped_here():
		await Ui.say(["* Eppure, dove hai dato una mano, il grigio è un po' più caldo. Come una stanza dove qualcuno ha appena parlato."])
	Ui.cutscene = false


# --- l'ascensore che crolla ------------------------------------------------------

var _lift_doors: Array[ColorRect] = []
var _lift_inside: ColorRect
var _lift_arrow: Label


func _shake(time: float) -> void:
	if player == null:
		return
	var cam := player.camera
	var tw := create_tween()
	for i in int(time / 0.05):
		tw.tween_property(cam, "offset", Vector2(randf_range(-3, 3), randf_range(-3, 3)), 0.05)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.05)


## L'ascensore rotto: porte storte, dentro è buio, la freccia spenta.
func _break_lift() -> void:
	GameState.flags["c1_lift_broken"] = true
	if _lift_inside:
		_lift_inside.color = Color("0c0a10")
	for i in _lift_doors.size():
		_lift_doors[i].rotation = -0.12 if i == 0 else 0.1
		_lift_doors[i].color = Color("b8a878")
	if _lift_arrow:
		_lift_arrow.add_theme_color_override("font_color", Color("4a4658"))


func _lift(top_left: Vector2i) -> void:
	var frame := ColorRect.new()
	frame.color = Color("e8c060")
	frame.position = Vector2(top_left.x * T, top_left.y * T + 4)
	frame.size = Vector2(2 * T, 2 * T - 4)
	world.add_child(frame)
	_lift_inside = ColorRect.new()
	_lift_inside.color = Color("fff4c8")
	_lift_inside.position = frame.position + Vector2(2, 3)
	_lift_inside.size = Vector2(2 * T - 4, frame.size.y - 3)
	world.add_child(_lift_inside)
	for k in 2:
		var door := ColorRect.new()
		door.color = Color("f4e2a8")
		door.position = frame.position + Vector2(2 + k * 15, 3)
		door.size = Vector2(13, frame.size.y - 3)
		world.add_child(door)
		_lift_doors.append(door)
	var arrow := Label.new()
	_lift_arrow = arrow
	arrow.text = "▲"
	arrow.add_theme_font_size_override("font_size", 8)
	arrow.add_theme_color_override("font_color", Color("ff6a5a"))
	arrow.position = frame.position + Vector2(12, -12)
	arrow.z_index = 6
	add_child(arrow)
	if GameState.flags.get("c1_lift_broken", false):
		_break_lift()
	examine(cell_center(top_left + Vector2i(0, 2)) + Vector2(8, 0), [
		"* L'ascensore dorato. Le porte sono piegate, dentro è buio. Dal soffitto pende un filo che sfrigola.",
		"* Sotto la pulsantiera, un adesivo a forma di cuore: \"Si sale solo col badge. Ti vogliamo bene!\"",
	])
