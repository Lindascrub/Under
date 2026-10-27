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


func setup() -> void:
	if GameState.flags.get("c1_sbarrato", false):
		_barred_hole(Vector2i(1, 12))
	else:
		add_stairs_down(Vector2i(1, 12), Router.FONDO, "from_above")
	if GameState.flags.get("c2_rivelazione", false):
		# la musichetta è ripartita, ma più lenta
		Sound.call_deferred("music_pitch", 0.85, 0.1)
		if not GameState.flags.get("c2_quiet", false):
			_start_ringing()


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
func _start_ringing() -> void:
	if _ring != null:
		return
	_ring = Timer.new()
	_ring.wait_time = 1.6
	add_child(_ring)
	_ring.timeout.connect(func() -> void:
		Sound.sfx("drring", randf_range(0.85, 1.2))
		_ring.wait_time = randf_range(0.9, 2.2))
	_ring.start()


func _stop_ringing() -> void:
	if _ring != null:
		_ring.queue_free()
		_ring = null


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
		_start_ringing()
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
	await Ui.say(["* Metti il piede sul primo gradino."])
	# la musica si interrompe di colpo, a metà di una nota
	Sound.music("")
	Sound.sfx("clunk", 0.7)
	await get_tree().create_timer(1.2).timeout
	await Ui.say(["* La musichetta si interrompe. A metà di una nota.",
		"* Per la prima volta, il piano -4 è in silenzio. Si sente il ronzio dei neon. E un altro rumore."])
	await _shred()
	var lines: Array = ["* Allo sportello, la Signora Agenda infila un foglio azzurro nel tritacarte. Sorridendo.",
		"* È il tuo B-4. Firmato, timbrato. Triturato."]
	if GameState.flags.get("c2_pagato", false):
		lines.append("* Trecento euro, in striscioline.")
	lines.append_array(["* Ti fa ciao con la mano. Il sorriso non le si sposta di un millimetro.",
		"* Nella sala, i colleghi restano con la cornetta in mano. Sorridono al nulla. Solo Tilde, e laggiù Ercole, ti guardano."])
	await Ui.say(lines)
	await get_tree().create_timer(0.6).timeout
	Sound.music(music)
	Sound.music_pitch(0.85, 2.0)
	await Ui.say(["* Poi, piano piano, la musichetta riparte. Più lenta. Nessuno dice niente.",
		"* Le scale ti aspettano. Dietro di te, due persone grigie sanno quello che sai tu."])
	# e i telefoni: squillano, e nessuno risponde più
	_start_ringing()
	await Ui.say(["* DRRRING. Un telefono. Poi un altro. Poi tutti.",
		"* Nessuno alza la cornetta. Sorridono, e lasciano squillare.",
		"* Qualcuno le chiamate dovrà pur prenderle. Il TURNO è sempre lì."])
	Ui.cutscene = false


## Il tritacarte si mangia il B-4: vibra, e sputa striscioline azzurre.
func _shred() -> void:
	var tri := find_child("Tritacarte", true, false) as Node2D
	Sound.sfx("shredder")
	if tri == null:
		await get_tree().create_timer(1.0).timeout
		return
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
		return "Laggiù la musichetta gira di nuovo.\nMa due persone, adesso, la ascoltano sapendo cos'è."
	return "Laggiù la Signora Agenda sorride.\nSorride a chi arriva, sorride a chi sale. Il B-4 lo dà a tutti."


# --- le scale per il Fondo, chiuse ---------------------------------------------

## Le scale per il Fondo, chiuse alla buona: sei salito senza voltarti.
func _barred_hole(bottom_left: Vector2i) -> void:
	var s := add_region(GENERIC, GENERIC_SIZE, Rect2(STAIRS_REGION.position + Vector2(0, 16), Vector2(32, 48)), bottom_left)
	s.flip_v = true
	s.modulate = Color(0.45, 0.45, 0.5)
	world.remove_child(s)
	add_child(s)
	move_child(s, world.get_index())
	# chi sale dal Fondo compare qui, davanti alla sbarra (gli scalini sono chiusi)
	_stairs_down_exit = Vector2(bottom_left.x * T + T, (bottom_left.y - 3) * T)
	# coni e nastro, messi lì di fretta anni fa: uno è caduto e nessuno l'ha rialzato.
	# Stanno tutti in un nodo dentro il mondo: chi passa davanti li copre, chi passa dietro no.
	var base_y := (bottom_left.y - 2) * T + 8.0
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
	block(Rect2i(bottom_left.x, bottom_left.y - 2, 2, 3))
	# il cono caduto è per terra, ma è sempre un cono: non ci si passa sopra
	block_px(Rect2(xs[2] - 2, base_y - 6, 18, 9))
	examine(cell_center(bottom_left + Vector2i(0, -1)) + Vector2(8, 0), [
		"* Le scale per il Fondo. Tre coni e un nastro: VIETATO SCENDERE.",
		"* Il nastro è scolorito, un cono è caduto. Nessuno l'ha rialzato. Nessuno passa di qua a controllare.",
		"* Attaccato al nastro, un foglio: \"Lavori in corso\". La data è di quindici anni fa.",
		"* Sei salito senza voltarti. Il Fondo, adesso, resta là sotto. Con quello che non hai voluto sapere.",
	])
