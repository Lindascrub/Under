extends EditorRoom
## Capitolo 2 — Il Sottoufficio (piano -4). La scena è fatta nell'editor (sottoufficio.tscn):
## qui c'è solo la logica. Un ufficio anni '80 finto allegro: moquette arancione, piante di
## plastica, una musichetta d'attesa che non si ferma mai. Per il badge serve il Modulo B-4,
## e il B-4 gira in tondo. Se ne esce aiutando Tilde ed Ercole (o pagando: vedi
## docs/capitoli/capitolo_2_il_sottoufficio.md).

## La "procedura d'urgenza": il B-4 timbrato subito, a pagamento.
const URGENZA := 300
## Dopo la rivelazione nessuno prende più le chiamate: i telefoni squillano senza sosta.
## Un turno al call center li fa tacere per un po' (come la festa del Fondo che si riaccende).
const QUIET_TIME := 25.0
var _ring: Timer
var _ring_voices: Array[AudioStreamPlayer2D] = []
var _ring_next := 0
var _ring_intense := false
var _office_mat: ShaderMaterial


var _stairs_down_placed := false


## Le scale per il Fondo, o il buco sbarrato se il Fondo è stato chiuso.
func place_stairs_down(c: Vector2i, path: String, spawn_name: String) -> void:
	_stairs_down_placed = true
	if GameState.flags.get("c1_sbarrato", false):
		_barred_hole(c)
	else:
		add_stairs_down(c, path if path != "" else Router.FONDO, spawn_name if spawn_name != "" else "from_above")


## Le scale per il Fondo messe nell'editor (ScaleGiu): se il Fondo è stato chiuso, al loro posto
## c'è il buco sbarrato.
func use_stairs_down(st: Node2D) -> void:
	_stairs_down_placed = true
	if GameState.flags.get("c1_sbarrato", false):
		var c := Vector2i((to_local(st.global_position) / T).round())
		st.queue_free()
		_barred_hole(c)
	else:
		super(st)


func setup() -> void:
	cam_rect = cam_rect.grow_side(SIDE_TOP, 40)
	camera_lift = 28
	_clear_stair_landing()
	# le scale per il Fondo: dove c'è "ScaleGiu" nella scena (si sposta nell'editor)
	if not _stairs_down_placed:
		place_stairs_down(Vector2i(1, 12), Router.FONDO, "from_above")
	_calibrate_interactions()
	if GameState.flags.get("c2_rivelazione", false):
		call_deferred("_fade_office", false)
		Sound.call_deferred("music", "")
		if not GameState.flags.get("c2_quiet", false):
			_start_ringing(true)


func enter() -> void:
	if not GameState.flags.get("c2_arrivo", false):
		GameState.flags["c2_arrivo"] = true
		await get_tree().create_timer(0.4).timeout
		await Ui.say([
			"* Il piano -4. Moquette arancione, carta da parati a righe, piante di plastica.",
			"* Da un altoparlante, una musichetta d'attesa. Allegra. Senza fine.",
			"* Tutti sorridono, tutti al telefono. Tranne due persone, grigie come il Fondo.",
			"* Allo sportello, una signora ti fa ciao con la mano. Sorride più di tutti.",
		])
	if GameState.flags.get("c2_quiet", false):
		GameState.flags.erase("c2_quiet")
		await _quiet()
	await show_pending()


## Le chiamate che nessuno prende: un DRRRING dopo l'altro, da telefoni diversi.
func _start_ringing(intense := false) -> void:
	_ring_intense = intense
	if _ring != null:
		return
	for i in 4:
		var voice := AudioStreamPlayer2D.new()
		voice.stream = load("res://audio/drring.wav")
		voice.bus = "SFX"
		voice.max_distance = 1400
		voice.panning_strength = 1.6
		voice.volume_db = -16.0
		add_child(voice)
		_ring_voices.append(voice)
	_ring = Timer.new()
	_ring.wait_time = 0.6 if intense else 1.6
	add_child(_ring)
	_ring.timeout.connect(_ring_phone)
	_ring.start()
	_ring_phone()


func _ring_phone() -> void:
	if not is_instance_valid(player) or _ring_voices.is_empty():
		return
	var voice := _ring_voices[_ring_next % _ring_voices.size()]
	voice.global_position = player.camera.get_screen_center_position() + Vector2(-110 if _ring_next % 2 == 0 else 110, 0)
	voice.pitch_scale = [0.88, 1.12, 0.98, 1.2][_ring_next % 4]
	voice.volume_db = -10.0 if _ring_intense else -16.0
	voice.play()
	_ring_next += 1
	_ring.wait_time = randf_range(0.35, 0.6) if _ring_intense else randf_range(1.0, 1.8)
	# Le cornette si illuminano a turno: lo squillo ha una sorgente anche visibile.
	var colleague := find_child("Collega%d" % (_ring_next % 4), true, false) as CanvasItem
	if colleague:
		var tw := create_tween()
		tw.tween_property(colleague, "modulate", Color(1.35, 1.35, 1.35), 0.08)
		tw.tween_property(colleague, "modulate", Color.WHITE, 0.25)


func _stop_ringing() -> void:
	if _ring != null:
		_ring.queue_free()
		_ring = null
	for voice in _ring_voices:
		voice.stop()
		voice.queue_free()
	_ring_voices.clear()


## Hai fatto il turno: le chiamate le hai prese tu. Per un po', silenzio. Poi ricominciano.
func _quiet() -> void:
	_stop_ringing()
	await Ui.say(["* I telefoni tacciono. Le chiamate che nessuno prendeva le hai prese tu, una per una.",
		"* Nella sala, i colleghi continuano a sorridere al nulla. Non se ne sono accorti."])
	# un timer della stanza: se te ne vai prima, se ne va con lei
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = QUIET_TIME
	add_child(t)
	t.timeout.connect(func() -> void:
		t.queue_free()
		_start_ringing(true)
		Sound.sfx("drring", 1.0)
		if not Ui.busy and not Ui.cutscene:
			Ui.say(["* DRRRING. Ricominciano. Il silenzio è durato meno del turno."]))
	t.start()


## Il regalo dell'addetta ai badge (se hai aiutato tutti) arriva solo col B-4 a posto:
## anche l'amicizia, qui, ha bisogno di un modulo.
func _floor_gift() -> void:
	if GameState.flags.get("c2_modulo_ok", false):
		await super()


# --- la Signora Agenda e il Modulo B-4 ------------------------------------------

func _agenda() -> void:
	var who := "Signora Agenda"
	GameState.flags["met_agenda"] = true
	if GameState.flags.get("c2_rivelazione", false):
		await Ui.say([["Tutto in ordine, {name}! Il suo B-4 è archiviato. Al sicuro. Per sempre.",
			"Le serve un altro modulo? Ne ho tanti. Tutti uguali. Tutti importanti.",
			"Sorrida! Si sente, sa? Anche quando non c'è nessuno al telefono."].pick_random()], who)
		return
	if not GameState.flags.get("c2_b4", false):
		GameState.flags["c2_b4"] = true
		await Ui.say([
			"Oh! Qualcuno che sale dal Fondo! {name}, vero? Ho già il suo nome sul registro. Ce li ho tutti.",
			"Benvenuto al piano -4! Io sono la Signora Agenda. Sportello B-4.",
			"Il badge per il Mercato si compra allo sportello lì accanto. Ma prima serve il Modulo B-4. Compilato, firmato, timbrato!",
		], who)
		Sound.sfx("stamp", 1.3)
		await Ui.say(["* Ti dà un foglio azzurro. In alto: \"MODULO B-4 — Richiesta di modulo\"."])
		await Ui.say([
			"La firma la mette l'archivio. Il timbro lo mette il responsabile. Semplicissimo!",
			"Solo una cosina: l'archivio firma solo moduli già timbrati. E il responsabile timbra solo moduli già firmati.",
			"...Lo so! È fatto benissimo. Così nessuno sbaglia l'ordine.",
			"Se ha fretta, c'è la procedura d'urgenza: %s, e il B-4 glielo timbro io. Subito. Con un sorriso." % GameState.euros(URGENZA),
		], who)
		return
	if GameState.flags.get("c2_modulo_ok", false):
		await Ui.say(["Il suo B-4 è perfetto. Lo tengo io, al sicuro. Il badge è allo sportello accanto. Buona salita!"], who)
		return
	var c: int = await Ui.choose("Il Modulo B-4?", ["Ecco il modulo", "Procedura d'urgenza (%s)" % GameState.euros(URGENZA), "Arrivederci"], who)
	match c:
		0:
			await _hand_in(who)
		1:
			if GameState.money < URGENZA:
				Sound.sfx("deny")
				await Ui.say(["Oh, non bastano! Peccato. La fretta, qui, la possono permettere in pochi.",
					"Ma non si scoraggi: c'è sempre la procedura normale! Prima o poi."], who)
				return
			GameState.money -= URGENZA
			GameState.flags["c2_pagato"] = true
			GameState.changed.emit()
			Sound.sfx("coin")
			await _stamp(who)
			await Ui.say(["Visto? Basta volerlo. E pagarlo. Ma soprattutto volerlo!"], who)
		_:
			await Ui.say(["Arrivederci! Resti in linea!"], who)


## Consegni il B-4: com'è messo?
func _hand_in(who: String) -> void:
	if GameState.flags.get("c2_timbro", false):
		await Ui.say(["Vediamo... Firma dell'archivio: c'è. Autorizzazione del responsabile: c'è! Me l'ha detta lui, al telefono.",
			"Che bella voce che ha, il responsabile. Un po' acuta. Un po' stanca. Mi ricorda qualcuno."], who)
		await _stamp(who)
		return
	if GameState.flags.get("c2_firma", false):
		await Ui.say(["Firma dell'archivio! Bravissimo. Adesso manca solo il timbro del responsabile.",
			"Il responsabile non riceve. Il responsabile è al telefono. Da dodici anni, più o meno.",
			"Se mi chiama lui e mi dice \"timbra\", io timbro. Funziona così: con una voce, si fa tutto."], who)
		return
	await Ui.say(["Ancora vuoto? Eh, lo so. L'archivio firma solo moduli timbrati, il responsabile timbra solo moduli firmati.",
		"Io però un consiglio glielo do, gratis: l'archivio è laggiù a destra. Il custode si chiama Ercole. Se è sveglio, è gentile.",
		"Se dorme, è uguale. Ma non se ne accorge."], who)


func _stamp(who: String) -> void:
	GameState.flags["c2_modulo_ok"] = true
	Sound.sfx("stamp")
	await Ui.say(["* TUM. Il timbro scende sul B-4, al centro, un po' storto.",
		"Ecco fatto! Il B-4 lo tengo io: deve restare agli atti. Lei vada pure allo sportello dei badge."], who)


## Lo sportello dei badge vende il badge del Mercato solo col B-4 timbrato.
func badge_allowed(_need: String) -> bool:
	if GameState.flags.get("c2_modulo_ok", false):
		return true
	Sound.sfx("deny")
	await Ui.say(["Per il badge del Mercato serve il Modulo B-4 timbrato. Regolamento del piano.",
		"Lo ritira dalla Signora Agenda, allo sportello al centro. È gentilissima. Lo è sempre."], "Addetta ai badge", BADGE_CLERK)
	return false


# --- Ercole e Tilde: il modo vero di uscire dal giro ----------------------------

## Ercole, dopo che l'hai tenuto sveglio, firma il B-4 (anche se non è timbrato).
func talk_ercole(_npc: Npc) -> bool:
	if not GameState.flags.get("c2_b4", false) or GameState.flags.get("c2_firma", false) or GameState.flags.get("c2_modulo_ok", false):
		return false
	if "ercole" not in GameState.helped_ids:
		return false
	GameState.flags["c2_firma"] = true
	var who := "Ercole"
	await Ui.say(["Il B-4? Dammelo qua.",
		"Lo so, lo so: prima ci vuole il timbro. Ma chi vuoi che controlli? L'archivio sono io."], who)
	Sound.sfx("blip", 0.6)
	await Ui.say(["* Ercole firma il modulo. Una firma lunghissima, tutta svolazzi. L'unica cosa sveglia di lui."])
	await Ui.say(["Adesso il timbro del responsabile. Te lo dico io un segreto: il responsabile non l'ha mai visto nessuno.",
		"C'è solo una voce, al telefono. E di voci, al call center, ce n'è una che le sa fare tutte.",
		"Chiedi a Tilde. Lei è grigia come me: vuol dire che è vera."], who)
	return true


## Tilde, dopo che l'hai aiutata col copione e con la firma di Ercole, imita al telefono
## la voce del responsabile. E l'Agenda timbra.
func talk_tilde(_npc: Npc) -> bool:
	if not GameState.flags.get("c2_firma", false) or GameState.flags.get("c2_timbro", false) or GameState.flags.get("c2_modulo_ok", false):
		return false
	var who := "Tilde"
	if "tilde" not in GameState.helped_ids:
		if GameState.flags.get("tilde_firma_hint", false):
			return false
		GameState.flags["tilde_firma_hint"] = true
		await Ui.say(["La firma di Ercole? Ah. Quindi vuoi il responsabile.",
			"Posso farlo. Ma adesso ho il copione nuovo da imparare: se sbaglio una frase, mi richiamano. Aiutami prima con quello."], who)
		return true
	GameState.flags["c2_timbro"] = true
	await Ui.say(["Il responsabile, eh? ...Dammi un secondo.",
		"* Tilde si schiarisce la voce. Compone un numero. Allo sportello, il telefono dell'Agenda squilla."], who)
	Sound.sfx("ding", 1.25)
	await get_tree().create_timer(0.4).timeout
	Sound.sfx("ding", 1.25)
	await Ui.say(["* Tilde abbassa la voce di un'ottava, la fa stanca e importante:",
		"\"Signora Agenda? Il responsabile. Timbri il B-4 del ragazzo nuovo. Sì. Adesso. Grazie per la sua pazienza.\"",
		"* Riattacca. Le tremano un po' le mani. Poi, per la prima volta, ride."], who)
	await Ui.say(["Dodici anni che leggo frasi di altri. Questa me la sono inventata io.",
		"Vai dall'Agenda: adesso il timbro te lo mette. Le serviva solo il permesso di una voce."], who)
	return true


# --- la rivelazione: la musica si ferma ------------------------------------------

## Sul primo gradino, col badge in mano: per la prima volta la musichetta si ferma.
func on_stairs_step(p: Player, _need: String) -> void:
	if GameState.flags.get("c2_rivelazione", false):
		return
	GameState.flags["c2_rivelazione"] = true
	Ui.cutscene = true
	p.position.y += 4
	await Ui.say(["* Metti il piede sul primo gradino. Dall'altra parte della sala, un telefono squilla."])
	Sound.music("")
	_start_ringing()
	var tri := find_child("Tritacarte", true, false) as Node2D
	var shot: Dictionary = await FocusShot.begin(self, tri.global_position + Vector2(-16, -12), 3.5)
	await Ui.say(["* La Signora Agenda prende il tuo modulo azzurro. Firmato. Timbrato.",
		"* Lo avvicina al tritacarte. Continua a sorridere."])
	await _shred()
	var lines: Array = ["* È il tuo B-4. Non una copia."]
	if GameState.flags.get("c2_pagato", false):
		lines.append("* Trecento euro, in striscioline.")
	lines.append("* Ti fa ciao con la mano. Dietro di te, squilla un altro telefono.")
	await Ui.say(lines)
	await FocusShot.restore(self, shot)
	_ring_intense = true
	await _fade_office(true)
	await Ui.say(["* Gli squilli si sovrappongono. A destra. A sinistra. Sempre più vicini.",
		"* Nessuno risponde. I colleghi tengono le cornette in mano, ma le linee continuano a chiamare.",
		"* I colori scoloriscono. Sulla carta dei manifesti compaiono macchie e strappi.",
		"* RESTI IN LINEA. Il cartello è ancora appeso. L'inchiostro sembra vecchio di anni.",
		"* Tilde ed Ercole ti guardano. Le scale sono davanti a te. Gli squilli, dietro, sono diventati assordanti.",
		"* Qualcuno le chiamate dovrà pur prenderle. Il TURNO è sempre lì."])
	Ui.cutscene = false


## Il tritacarte si mangia il B-4: vibra, e sputa striscioline azzurre.
func _shred() -> void:
	var tri := find_child("Tritacarte", true, false) as Node2D
	Sound.sfx("shredder")
	if tri == null:
		await get_tree().create_timer(1.0).timeout
		return
	var paper := Polygon2D.new()
	paper.name = "B4DaTritare"
	paper.polygon = PackedVector2Array([Vector2(0,0), Vector2(7,0), Vector2(7,10), Vector2(0,10)])
	paper.color = Color("8ac8ff")
	paper.position = tri.global_position + Vector2(4, -26)
	paper.z_index = 20
	add_child(paper)
	var feed := create_tween()
	feed.tween_property(paper, "position:y", paper.position.y + 9, 0.65)
	feed.parallel().tween_property(paper, "scale:y", 0.05, 0.65)
	await feed.finished
	paper.queue_free()
	var base := tri.position
	var tw := create_tween()
	for i in 16:
		tw.tween_property(tri, "position", base + Vector2(randf_range(-1, 1), randf_range(-1, 0)), 0.05)
	tw.tween_property(tri, "position", base, 0.05)
	for i in 10:
		var strip := ColorRect.new()
		strip.color = Color("8ac8ff") if i % 2 == 0 else Color("cfe6ff")
		strip.size = Vector2(1, 5)
		strip.position = tri.global_position + Vector2(4 + i, -6)
		strip.z_index = 20
		add_child(strip)
		var fall := create_tween()
		fall.tween_property(strip, "position", strip.position + Vector2(randf_range(-6, 6), 10), 0.6).set_delay(i * 0.06)
		fall.tween_property(strip, "modulate:a", 0.0, 0.4)
		fall.tween_callback(strip.queue_free)
	await tw.finished
	await get_tree().create_timer(0.4).timeout


# --- lo sguardo indietro: fine del capitolo 2 ----------------------------------

func on_stairs_top(p: Player) -> bool:
	if GameState.flags.get("c2_fine", false):
		return false
	GameState.flags["c2_fine"] = true
	look_back(p, _look_back_line(), "CAPITOLO 3", "IL MERCATO", Router.MERCATO, "from_below", ["Piano -3."])
	return true


## La frase dello sguardo indietro: dipende da come sei uscito dal giro del B-4.
func _look_back_line() -> String:
	if GameState.is_robot("tilde"):
		return "Laggiù, Tilde sorride al telefono, come gli altri.\nIl suo copione, adesso, ha il tuo nome sopra. Lei continua a dire grazie."
	if GameState.flags.get("c2_pagato", false):
		return "Laggiù il tritacarte ronza ancora.\nHai pagato trecento euro per un foglio. Il foglio non c'è più. Il debito sì."
	if GameState.flags.get("c2_timbro", false):
		return "Laggiù Tilde dice una frase sua al telefono, ed Ercole tiene gli occhi aperti.\nIl B-4 è triturato. Quello che avete fatto in tre, no."
	if GameState.flags.get("svelato_tilde", false) and GameState.flags.get("svelato_ercole", false):
		return "Laggiù i telefoni continuano a squillare.\nDue persone, adesso, sanno perché nessuno risponde."
	return "Laggiù la Signora Agenda sorride.\nSorride a chi arriva, sorride a chi sale. Il B-4 lo dà a tutti."


# --- le scale per il Fondo, chiuse ---------------------------------------------

## Le scale per il Fondo, chiuse alla buona: sei salito senza voltarti.
func _barred_hole(bottom_left: Vector2i) -> void:
	var s := add_region("themes/condominium.png", Vector2i(256,1664), Rect2(64,32,32,32), bottom_left)
	s.modulate = Color(0.45, 0.45, 0.5)
	world.remove_child(s)
	add_child(s)
	move_child(s, world.get_index())
	# chi sale dal Fondo compare qui, davanti alla sbarra (gli scalini sono chiusi)
	_stairs_down_exit = Vector2(bottom_left.x * T + T, (bottom_left.y - 1) * T - 2)
	# coni e nastro, messi lì di fretta anni fa: uno è caduto e nessuno l'ha rialzato.
	# Stanno tutti in un nodo dentro il mondo: chi passa davanti li copre, chi passa dietro no.
	var base_y := (bottom_left.y - 1) * T + 8.0
	var bar := Node2D.new()
	bar.name = "Sbarramento"
	bar.position = Vector2(0, base_y)
	world.add_child(bar)
	var xs := [bottom_left.x * T + 2.0, bottom_left.x * T + 30.0, bottom_left.x * T + 40.0]
	var tops: Array[Vector2] = []
	for k in 3:
		var cone := Sprite2D.new()
		cone.texture = preload("res://art/cone.png")
		cone.offset = Vector2(0, -8)
		cone.position = Vector2(xs[k], 0)
		if k == 2:
			# quello caduto, di traverso
			cone.rotation = 1.45
			cone.position += Vector2(6, 2)
			cone.modulate = Color(0.85, 0.85, 0.85)
		bar.add_child(cone)
		tops.append(Vector2(xs[k], -14))
	# il nastro bianco e rosso: tra i primi due coni pende, poi casca a terra dove il cono è caduto
	var pts: Array[Vector2] = []
	for i in 9:
		var f := i / 8.0
		pts.append(tops[0].lerp(tops[1], f) + Vector2(0, sin(f * PI) * 5.0))
	for i in range(1, 7):
		var f := i / 6.0
		pts.append(tops[1].lerp(Vector2(xs[2] + 6, -2), f) + Vector2(0, sin(f * PI) * 3.0))
	for i in pts.size() - 1:
		var seg := Line2D.new()
		seg.points = PackedVector2Array([pts[i], pts[i + 1]])
		seg.width = 2.0
		seg.default_color = Color("d8302a") if i % 2 == 0 else Color("eeeae0")
		bar.add_child(seg)
	# il cartello appeso al nastro, storto
	var sign := Sprite2D.new()
	sign.texture = preload("res://art/sign_vietato.png")
	sign.position = tops[0].lerp(tops[1], 0.5) + Vector2(0, 8)
	sign.rotation = 0.14
	bar.add_child(sign)
	block(Rect2i(bottom_left.x, bottom_left.y - 1, 2, 2))
	# il cono caduto è per terra, ma è sempre un cono: non ci si passa sopra
	block_px(Rect2(xs[2] - 2, base_y - 6, 18, 9))
	examine(Vector2(bottom_left.x * T + T, (bottom_left.y - 1) * T - 6), [
		"* Le scale per il Fondo. Tre coni e un nastro: VIETATO SCENDERE.",
		"* Il nastro è scolorito, un cono è caduto. Nessuno l'ha rialzato. Nessuno passa di qua a controllare.",
		"* Attaccato al nastro, un foglio: \"Lavori in corso\". La data è di quindici anni fa.",
		"* Sei salito senza voltarti. Il Fondo, adesso, resta là sotto. Con quello che non hai voluto sapere.",
	])


func _calibrate_interactions() -> void:
	# Il cordone lasciava soltanto sei pixel davanti alle sedie: il corpo non ci passava.
	var rope := find_child("Cordone", true, false) as Node2D
	if rope: rope.position.y -= 4
	for i in 4:
		var colleague := find_child("GuardaCollega%d" % i, true, false) as Interactable
		if colleague:
			colleague.interaction_bounds = Rect2(-7, -41, 14, 19)
	for name_at in [["GuardaSorridi", Vector2(52, 46)], ["GuardaModulo", Vector2(126, 52)], ["GuardaAttesa", Vector2(216, 46)]]:
		var spot := find_child(name_at[0], true, false) as Interactable
		if spot:
			spot.position = name_at[1]
			spot.approach = Vector2.DOWN
			spot.facing_required = "up"
	# Nessuna interazione fantasma per le decorazioni eliminate.
	var old := find_child("GuardaBandiere", true, false)
	if old: old.queue_free()


func _fade_office(animate: bool) -> void:
	if _office_mat != null:
		return
	_office_mat = ShaderMaterial.new()
	_office_mat.shader = preload("res://shaders/greyscale.gdshader")
	_office_mat.set_shader_parameter("amount", 0.0 if animate else 1.0)
	_office_mat.set_shader_parameter("darken", 0.12)
	for parent_name in ["Pavimento", "Muri", "Mondo", "Decori"]:
		var parent := get_node_or_null(parent_name)
		if not parent: continue
		var nodes: Array = [parent] if parent is TileMapLayer else parent.find_children("*", "CanvasItem", true, false)
		for n in nodes:
			if n == player or n.get_parent() == player or player.is_ancestor_of(n): continue
			if n is CanvasItem and not n is Control:
				n.material = _office_mat
	for name_ in ["PosterSorridi", "PosterModulo", "PosterAttesa"]:
		var poster := find_child(name_, true, false) as Node2D
		if not poster: continue
		poster.set("broken", true)
		poster.rotation = 0.0
	if animate:
		var tw := create_tween()
		tw.tween_method(func(v: float) -> void: _office_mat.set_shader_parameter("amount", v), 0.0, 1.0, 3.0)
		await tw.finished


## Riserva gradini, pianerottolo e avvicinamento nel vecchio divisorio dell'archivio.
func _clear_stair_landing() -> void:
	var stairs := find_children("ScaleSu", "", true, false)
	if stairs.is_empty():
		return
	var cell: Vector2i = stairs[0].call("cell")
	var walls := get_node("Muri") as TileMapLayer
	for y in range(cell.y - 2, cell.y + 3):
		for x in range(cell.x, cell.x + 2):
			walls.erase_cell(Vector2i(x, y))
			_blocked_cells.erase(Vector2i(x, y))
	var floor_layer := get_node("Pavimento") as TileMapLayer
	var sample := Vector2i(24, 4)
	var source := floor_layer.get_cell_source_id(sample)
	var atlas := floor_layer.get_cell_atlas_coords(sample) - Vector2i(sample.x % 3, sample.y % 2)
	for y in range(cell.y, cell.y + 3):
		for x in range(cell.x, cell.x + 2):
			floor_layer.set_cell(Vector2i(x, y), source, atlas + Vector2i(x % 3, y % 2))
