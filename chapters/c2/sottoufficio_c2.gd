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
## Quanto la camera può salire sopra la stanza (in pixel), per vedere il muro in alto.
@export var camera_spazio_sopra := 40

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
	cam_rect = cam_rect.grow_side(SIDE_TOP, camera_spazio_sopra)
	_clear_stair_landing()
	# le scale per il Fondo: dove c'è "ScaleGiu" nella scena (si sposta nell'editor)
	if not _stairs_down_placed:
		place_stairs_down(Vector2i(1, 12), Router.FONDO, "from_above")
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
			"Benvenuti al piano -4! Io sono la Signora Agenda. Sportello B-4.",
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
		await Ui.say(["Firma dell'archivio! Perfetto. Adesso manca solo il timbro del responsabile.",
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
	# se hai già aiutato tutti, Nives arriva subito col badge (senza aspettare di rientrare nel piano)
	await _floor_gift()


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
	var shot: Dictionary = await FocusShot.begin(self, $Inquadrature/Tritacarte as Inquadratura)
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


## Il tritacarte si mangia il B-4: vibra, e sputa striscioline azzurre. Nella scena, dentro
## Mondo/Tritacarte: IngressoFoglio/Foglio (il foglio che entra) e UscitaStrisce/StrisciaA e StrisciaB
## (le striscioline, alternate). I tempi sono qui sotto, nell'Inspector della stanza.
@export var tritacarte_entrata := 0.65
@export var tritacarte_scosse := 16
@export var tritacarte_scossa := 0.05
@export var tritacarte_strisce := 10
@export var tritacarte_caduta := 0.6
@export var tritacarte_sparizione := 0.4


func _shred() -> void:
	var tri := find_child("Tritacarte", true, false) as Node2D
	Sound.sfx("shredder")
	if tri == null or not tri.has_node("IngressoFoglio/Foglio"):
		await get_tree().create_timer(1.0).timeout
		return
	var paper := _copy_effect(tri.get_node("IngressoFoglio/Foglio") as CanvasItem) as Node2D
	paper.name = "B4DaTritare"
	var feed := create_tween()
	feed.tween_property(paper, "position:y", paper.position.y + 9, tritacarte_entrata)
	feed.parallel().tween_property(paper, "scale:y", 0.05, tritacarte_entrata)
	await feed.finished
	paper.queue_free()
	var base := tri.position
	var tw := create_tween()
	for i in tritacarte_scosse:
		tw.tween_property(tri, "position", base + Vector2(randf_range(-1, 1), randf_range(-1, 0)), tritacarte_scossa)
	tw.tween_property(tri, "position", base, tritacarte_scossa)
	var strips: Array[CanvasItem] = [tri.get_node("UscitaStrisce/StrisciaA"), tri.get_node("UscitaStrisce/StrisciaB")]
	for i in tritacarte_strisce:
		var strip := _copy_effect(strips[i % 2]) as Control
		strip.position += Vector2(i, 0)
		var fall := create_tween()
		fall.tween_property(strip, "position", strip.position + Vector2(randf_range(-6, 6), 10), tritacarte_caduta).set_delay(i * 0.06)
		fall.tween_property(strip, "modulate:a", 0.0, tritacarte_sparizione)
		fall.tween_callback(strip.queue_free)
	await tw.finished
	await get_tree().create_timer(0.4).timeout


## Una copia visibile di un pezzo d'effetto nascosto nella scena, nello stesso punto (fuori dal tritacarte che vibra).
func _copy_effect(src: CanvasItem) -> CanvasItem:
	var c := src.duplicate() as CanvasItem
	c.visible = true
	add_child(c)
	if c is Node2D:
		(c as Node2D).global_position = (src as Node2D).global_position
	else:
		(c as Control).global_position = (src as Control).global_position
	return c


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

## Le scale per il Fondo, chiuse alla buona: sei salito senza voltarti. È la scena
## chapters/c2/scale_chiuse.tscn (il nodo è l'angolo in alto a sinistra della casella di `bottom_left`):
## Botola (sotto a tutto), Sbarramento (coni, nastro e cartello: va nel Mondo, così chi passa davanti
## li copre), Collisioni, Guarda (le frasi) e Arrivo (dove compare chi sale dal Fondo).
func _barred_hole(bottom_left: Vector2i) -> void:
	var hole := load("res://chapters/c2/scale_chiuse.tscn").instantiate() as Node2D
	hole.position = Vector2(bottom_left * T)
	add_child(hole)
	move_child(hole, world.get_index())
	(hole.get_node("Sbarramento") as Node2D).reparent(world)
	_stairs_down_exit = (hole.get_node("Arrivo") as Node2D).global_position
	(hole.get_node("Guarda") as Examine).setup_in_room(self)


func _fade_office(animate: bool) -> void:
	if _office_mat != null:
		return
	_office_mat = ShaderMaterial.new()
	_office_mat.shader = preload("res://shaders/greyscale.gdshader")
	_office_mat.set_shader_parameter("amount", 0.0 if animate else 1.0)
	_office_mat.set_shader_parameter("darken", 0.12)
	# come al Fondo: si spegne quello che non ha già un colore suo. Le persone vere tengono il loro
	# grigio (scripts/looks.gd), i robot i loro colori da poster; anche il bordo bianco diventa grigio.
	for parent_name in ["Pavimento", "Muri", "Bordo", "Mondo", "Decori"]:
		var parent := get_node_or_null(parent_name)
		if not parent: continue
		var nodes: Array = [parent] if parent is TileMapLayer else [parent] + parent.find_children("*", "CanvasItem", true, false)
		for n in nodes:
			if n == player or n.get_parent() == player or player.is_ancestor_of(n): continue
			if n is CanvasItem and not n is Control and (n as CanvasItem).material == null and not _is_robot_sprite(n):
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


## Lo sprite di un robot (o un pezzo suo): resta colorato come i poster.
func _is_robot_sprite(n: Node) -> bool:
	var cur := n
	while cur and cur != self:
		if cur is Npc and GameState.is_robot(str((cur as Npc).id)):
			return true
		cur = cur.get_parent()
	return false


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
