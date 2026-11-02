extends "res://tests/storia_test.gd"
## Schermate di controllo: gioca le scene della storia (come storia_test) in una finestra vera e salva
## un'immagine per ogni battuta e ogni scelta, più le scritte dei finali. Controlla anche, battuta per
## battuta, che il testo non esca dal riquadro e che le scelte stiano nello schermo.
## Esegui (non headless):
##   Godot --path . res://tests/schermate_test.tscn -- --out=<cartella>            (PC)
##   Godot --path . res://tests/schermate_test.tscn -- --touch --size=1600x720 --out=<cartella>   (telefono 20:9)
## --size cambia la finestra da dentro il gioco: --resolution più grande dello schermo viene ridotta da Windows.
## Opzionale: --solo=banca,citta,presidente,finali,tocco,nives,impostazioni,fondo,mercato,serranda  (tocco: joystick e pulsanti mentre si
## cammina, e lo schermo della Direzione col dito; con --touch. nives: la memoria di Nives e il nome.
## impostazioni: il menu, la pagina dei comandi, il manifesto dei moduli e la telefonata lunga del -4;
## fondo: il Fondo grigio e lo sguardo indietro; mercato: la strada buona giocata coi tasti, fino alla Banca)

const VIEW := Rect2(0, 0, 640, 360)

var _out := "user://schermate/"
var _solo: Array = []
var _n := 0
var _last_key := ""
var _hold := 0
var _seen_labels := {}
var _problemi: Array[String] = []
var _section := "inizio"
var _min_row := 1000.0


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.trim_prefix("--out=").trim_suffix("/") + "/"
		elif a.begins_with("--solo="):
			_solo = Array(a.trim_prefix("--solo=").split(","))
		elif a.begins_with("--size="):
			var wh := a.trim_prefix("--size=").split("x")
			get_window().size = Vector2i(int(wh[0]), int(wh[1]))
	DirAccess.make_dir_recursive_absolute(_out)
	super()


func _want(name: String) -> bool:
	return _solo.is_empty() or name in _solo


func _run() -> void:
	if _want("banca"):
		_section = "banca"
		await _test_banca()
	if _want("citta"):
		_section = "citta"
		await _test_citta()
	if _want("presidente"):
		_section = "presidente"
		await _test_presidente()
	if _want("finali"):
		_section = "finali"
		await _test_scene_finali()
	if _want("tocco"):
		_section = "tocco"
		await _test_tocco()
	if _want("nives"):
		_section = "nives"
		await _test_nives()
	if _want("impostazioni"):
		_section = "impostazioni"
		await _test_impostazioni()
	if _want("fondo"):
		_section = "fondo"
		await _test_fondo_grigio()
	if _want("mercato"):
		_section = "mercato"
		await _test_mercato_buono()
	if _want("serranda"):
		_section = "serranda"
		await _test_serranda()
	if _want("citta"):
		print("SCHERMATE: in Città raggiunti camminando %d; non raggiunti: %s; OK non arriva: %s" % [_camminate, str(_non_raggiunti), str(_ok_non_arriva)])
	if _min_row < 1000.0:
		print("SCHERMATE: riga di scelta più bassa %.0f px su 360 (su un telefono 1080p: %.0f px veri)" % [_min_row, _min_row * 3.0])
	print("SCHERMATE: %d immagini in %s" % [_n, ProjectSettings.globalize_path(_out)])
	if _problemi.is_empty():
		print("SCHERMATE: nessun testo fuori dal riquadro")
	else:
		print("SCHERMATE: PROBLEMI\n- " + "\n- ".join(_problemi))
	if not _failures.is_empty():
		print("SCHERMATE: controlli falliti\n- " + "\n- ".join(_failures))
	get_tree().quit(0)


## Quando si cammina i comandi col dito si vedono: Banca vicino alle scale, Cima, schermo della Direzione.
func _test_tocco() -> void:
	TouchControls.enabled = true
	TouchControls.visible = true
	var m := await _bank(["c4_olga", "c4_teo"])
	var st := m.find_child("ScaleSu", true, false) as Node2D
	if st:
		m.player.global_position = st.global_position + Vector2(16, 24)
	await _still("banca_scale")
	_c6_reset()
	var c: Room = await _go(Router.CIMA, "desk")
	c = await _c6_settle()
	c.player.global_position = Vector2(560, 176)
	await _still("cima_stampante")
	director_plan = [{"alloc": {"stipendi": 45, "servizi": 20, "manutenzione": 25, "riserve": 10}}]
	Router.goto(Router.DIREZIONE)
	await _wait_scene(Router.DIREZIONE)
	await _idle()
	await _still("direzione")


## La memoria di Nives (con una memoria di prova, accanto al salvataggio dei test): il primo ritorno al Fondo,
## la rivelazione della Banca, i due ricordi al Mercato; poi il nome con numeri e una parolaccia.
func _test_nives() -> void:
	_nives_memory([["A1", "solidale"], ["C2", "solidale"]])
	_section = "nives_ritorno"
	_legacy_new_game()
	GameState.flags["run_id"] = MemoriaNives.new_run_id()
	GameState.flags["c1_arrivo"] = true
	var m: Room = await _go(Router.FONDO)
	await _to_booth(m)
	choose_queue = [0, 0, 0, 1]
	await m.call("_badge_machine")
	await _idle()
	_section = "nives_due_ricordi"
	_legacy_new_game()
	GameState.flags["run_id"] = MemoriaNives.new_run_id()
	GameState.badges.assign(["-4", "-3"])
	for f: String in ["c3_arrivo", "c3_nives", "nives_mem_ritorno", "nives_mem_ricordo"]:
		GameState.flags[f] = true
	m = await _go(Router.MERCATO, "from_below")
	await _to_booth(m)
	choose_queue = [0, 0, 0, 1]
	await m.call("_badge_machine")
	await _idle()
	_section = "nives_rivelazione"
	_nives_memory([["B1"]])
	m = await _bank(["c4_olga", "c4_teo"])
	GameState.flags["run_id"] = MemoriaNives.new_run_id()
	GameState.flags["met_olga"] = true
	GameState.flags["met_teo"] = true
	m = await _stairs(m, [0, 0, 1, 0, 0, 0, 0, 0, 0, 0])
	_section = "nives_nome"
	Router.goto(Router.MENU)
	await _wait_scene(Router.MENU)
	await _idle()
	var menu := get_tree().current_scene
	menu.call("_ask_name")
	await _still("nome_vuoto")
	var edit := menu.get_node("SceltaNome/Campo") as LineEdit
	edit.grab_focus()
	for ch in "Lia7":
		await _press_char(ch)
	await _still("nome_numero")
	_check(edit.text == "Lia", "nome: il 7 scritto dalla tastiera sparisce")
	await _press_char("#")
	await _still("nome_simbolo")
	_check(edit.text == "Lia", "nome: il simbolo scritto dalla tastiera sparisce")
	edit.text = "Stronzo"
	edit.text_submitted.emit(edit.text)
	await _still("nome_parolaccia")
	menu.set("name_override", "Lia")
	await _still("nome_fine")
	_nives_memory([])


## Un tasto premuto davvero (come dalla tastiera del telefono o del PC).
func _press_char(ch: String) -> void:
	var e := InputEventKey.new()
	e.pressed = true
	e.unicode = ch.unicode_at(0)
	Input.parse_input_event(e)
	await get_tree().process_frame
	var up := e.duplicate() as InputEventKey
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame


func _nives_memory(list: Array) -> void:
	var d := {"version": 1, "endings": [], "heard": [], "cleared_runs": []}
	var i := 0
	for v: Array in list:
		i += 1
		(d["endings"] as Array).append({"run": "vecchia-%d" % i, "family": str(v[0]).left(1), "variant": v[0], "past": v[1] if v.size() > 1 else ""})
	var f := FileAccess.open(MemoriaNives.path(), FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	MemoriaNives._from = ""


## Il giocatore cammina fino allo sportello dei badge (come per parlarci).
func _to_booth(m: Room) -> void:
	var spot := m.find_child("SportelloBadgeInterazione", true, false) as Node2D
	if spot == null:
		_fail("%s: lo sportello dei badge non c'è" % _section)
		return
	if not await _walk(m, spot.global_position + Vector2(0, 10)):
		# davanti allo sportello, dove si sta per parlarci (la strada la decide il gioco, non il test)
		m.player.global_position = spot.global_position + Vector2(0, 12)
		m.player.call("face", "up")
	for i in 30:
		await get_tree().process_frame


## Le impostazioni e due cose da vedere bene: il manifesto del -4 e la chiamata più lunga del call center.
## Il pilota automatico dei dialoghi è fermo (set_process), così il menu resta aperto per la foto.
## Non cambia niente: lo schermo intero e i volumi veri restano come sono.
func _test_impostazioni() -> void:
	Router.goto(Router.MENU)
	await _wait_scene(Router.MENU)
	await _idle()
	await _still("titolo")
	_check(Sound.get("_music_name") == "titolo", "nella schermata iniziale non c'è la musica del titolo")
	set_process(false)
	Ui.settings_menu()
	await _still("menu")
	_check_ui()
	var opts: Array = Ui.get("_options")
	_check(not opts.is_empty() and str(opts[-1]) == "Fatto", "le impostazioni finiscono con Fatto: %s" % str(opts))
	Ui.emit_signal("_chosen", opts.size() - 1)
	await get_tree().process_frame
	for nome: String in ["Comandi", "Crediti"]:
		Ui.show_page(Ui.COMANDI if nome == "Comandi" else Ui.CREDITI)
		await _still(nome)
		var page := Ui.get_node_or_null(nome)
		_check(page != null, "la pagina %s non si apre" % nome)
		if page:
			for l: Label in page.find_children("*", "Label", true, false):
				_check(l.get_line_count() * l.get_line_height() <= l.size.y + 2, "%s: la scritta \"%s\" non sta nel suo spazio" % [nome, l.text.left(30)])
			page.emit_signal("chiuso")
		await get_tree().process_frame
	_check(not Ui.busy, "dopo i comandi il gioco resta bloccato")
	# lo schermo intero si accende e si spegne (senza salvarlo nelle impostazioni vere)
	_check(InputMap.has_action("fullscreen"), "manca il tasto F11 per lo schermo intero")
	var was := Controls.is_fullscreen()
	Controls._apply_fullscreen(true)
	await _idle()
	_check(Controls.is_fullscreen(), "lo schermo intero non si accende")
	Controls._apply_fullscreen(was)
	await _idle()
	_check(Controls.is_fullscreen() == was, "lo schermo intero non si spegne")
	set_process(true)

	_section = "impostazioni_manifesto"
	_legacy_new_game()
	var m: Room = await _go(Router.SOTTOUFFICIO)
	await _idle()
	var poster := m.find_child("PosterModulo", true, false) as Node2D
	m.player.global_position = poster.global_position + Vector2(36, 18)
	m.player.call("face", "up")
	await _still("manifesto")
	# l'addetta che esce dallo sportello: il banco resta davanti a lei
	var booth := m.find_child("SportelloBadge", true, false)
	if booth:
		booth.call("walk_to", (booth as Node2D).to_global(Vector2(72, -18)))
		for k in 3:
			for i in 9:
				await get_tree().process_frame
			_shot("addetta_cammina_%d" % k)
		await _idle()
		await booth.call("go_inside")
		await _still("addetta_tornata")

	# un dialogo in fondo alla stanza: la camera scende un po', ma non oltre il pavimento
	_section = "impostazioni_dialogo_in_fondo"
	GameState.flags["c1_arrivo"] = true
	m = await _go(Router.FONDO)
	await _idle()
	var cam := m.player.camera
	m.player.global_position.y = cam.limit_bottom - 20
	m.player.call("face", "down")
	for i in 60:
		await get_tree().process_frame
	_check(m.player.global_position.y > cam.limit_bottom - 48, "il giocatore non è arrivato in fondo alla stanza")
	set_process(false)
	Ui.say(["...Oh. Un'altra persona."], "Fermo")
	await _still("fermo")
	var half := get_viewport().get_visible_rect().size.y / (2.0 * cam.zoom.y)
	var below := cam.get_screen_center_position().y + half - cam.limit_bottom
	_check(below <= 1.0, "nel dialogo la camera va oltre il fondo della stanza di %.0f px" % below)
	Ui.emit_signal("_advance")
	set_process(true)
	await _idle()

	_section = "impostazioni_telefonata"
	set_process(false)
	GameState.minigame = {"kind": "work", "game": "helpdesk", "name": "Prova", "pay": 100,
		"intro": ["* Prova."], "return": Router.FONDO}
	Router.goto(Router.WORK)
	await _wait_scene(Router.WORK)
	var w := get_tree().current_scene
	for i in 600:
		if w.get("phase") == "play":
			break
		if Ui.busy and i % 3 == 0:
			_tap("confirm")
		await get_tree().process_frame
	var calls: Array = w.get("CALLS")
	w.set("hd_call", calls[-1])
	w.set("hd_order", [0, 2, 1])
	w.set("hd_t", 60.0)
	w.set("time_left", 8.0)
	w.set("hd_phase", "talk")
	await _still("chiamata_lunga")
	w.set("time_left", 0.0)
	set_process(true)
	await _idle()


func _still(what: String) -> void:
	for i in 40:
		await get_tree().process_frame
	_shot(what)


## Il Fondo dopo la rivelazione: anche la biglietteria e Nives sono grigie, e lo sguardo indietro
## inquadra solo la festa, senza la stanza dei ticket.
func _test_fondo_grigio() -> void:
	GameState.flags["c1_arrivo"] = true
	GameState.flags["c1_rivelazione"] = true
	var m: Room = await _go(Router.FONDO)
	await _idle()
	var booth := m.find_child("SportelloBadge", true, false)
	m.player.global_position = (booth as Node2D).global_position + Vector2(40, 40)
	await _still("biglietteria_grigia")
	_check(booth.get_node("Parete").material != null, "la biglietteria del Fondo dovrebbe diventare grigia")
	_check(booth.get_node("Addetta").material != null, "anche Nives dovrebbe diventare grigia")
	for id in ["fermo", "mina", "bulbo"]:
		GameState.flags["svelato_" + id] = true
	GameState.flags["c1_sbarrato"] = false
	m.call("look_back", m.player, "Prova.", "CAPITOLO 2", "IL SOTTOUFFICIO", Router.SOTTOUFFICIO, "from_below", [])
	await get_tree().create_timer(3.8).timeout
	set_process(false)
	_shot("sguardo_indietro")
	var cam := m.player.camera
	var right := cam.get_screen_center_position().x + get_viewport().get_visible_rect().size.x / (2.0 * cam.zoom.x)
	_check(right <= 368.0, "lo sguardo indietro mostra la stanza dei ticket (bordo destro %.0f)" % right)
	set_process(true)
	await _wait_scene(Router.SOTTOUFFICIO)
	await _idle()


## Banca: Olga e Teo sul divano (la scena segreta), poi la serranda che chiude la strada dopo i saluti.
func _test_serranda() -> void:
	for k in ["c4_arrivo", "c4_olga_contestazione", "c4_teo_aiutato"]:
		GameState.flags[k] = true
	var m: Room = await _go(Router.BANCA, "from_below")
	await _idle()
	var sc := m.find_child("ScenaSegreta", true, false) as Node2D
	_check(sc != null, "la scena segreta dovrebbe esserci")
	if sc:
		m.player.global_position = (sc.get_node("Guarda") as Node2D).global_position + Vector2(0, 6)
		m.player.facing = "up"
		await _still("segreta_divano")
	# i saluti sulle scale: Teo e Olga arrivano a piedi dai loro posti (la telecamera li segue),
	# poi tornano nell'atrio e la serranda scende
	GameState.flags["c4_segreta"] = true
	m = await _go(Router.BANCA, "from_below")
	await _idle()
	var step := m.find_child("PrimoGradino", true, false) as Node2D
	m.player.global_position = step.global_position + Vector2(16, 14)
	m.player.facing = "up"
	choose_queue = [0, 0, 0, 1, 1]
	m.call("on_stairs_step", m.player, "")
	var t := 0.0
	var walking := 0
	while (Ui.cutscene or Ui.busy) and t < 150.0:
		await get_tree().create_timer(0.5).timeout
		t += 0.5
		if not Ui.busy and m.get("_clerk_camera_actor") != null:
			walking += 1
			if walking % 3 == 1:
				_shot("saluti_cammina")
	_check(walking > 0, "Teo e Olga dovrebbero arrivare a piedi, con la telecamera su di loro")
	var serr := m.find_child("Serranda", true, false) as Serranda
	_check(serr != null and serr.chiusa, "finiti i saluti la serranda dovrebbe chiudersi")
	_shot("dopo_i_saluti")
	m = await _go(Router.BANCA, "from_below")
	await _idle()
	serr = m.find_child("Serranda", true, false) as Serranda
	_check(serr != null and serr.chiusa, "dopo i saluti la serranda dovrebbe restare chiusa")
	if serr == null:
		return
	m.player.global_position = serr.global_position + Vector2(40, 24)
	await _still("serranda_chiusa")
	# ci vai contro: non passi, e la frase
	var k := 0
	while not Ui.busy and k < 240:
		_press("move_left", true)
		await get_tree().physics_frame
		k += 1
	_press("move_left", false)
	_check(m.player.global_position.x >= serr.global_position.x + 8.0, "la serranda chiusa non si attraversa (x %.0f)" % m.player.global_position.x)
	_check(Ui.busy, "contro la serranda dovrebbe arrivare la frase")
	_shot("serranda_frase")
	await _idle()


## true: i minigiochi si giocano coi tasti, come una persona (non si vincono da soli)
var _gioca_davvero := false


## Il Mercato dalla strada buona, senza lavorare: si cammina fino a Leda e ad Amir, si giocano davvero
## SCATOLE E SCAFFALI e L'ULTIMA CONSEGNA, Nives regala il badge, si salgono le scale.
func _test_mercato_buono() -> void:
	GameState.new_game()
	GameState.badges.assign(["-4", "-3"])
	GameState.minutes = GameState.DAY_START
	_gioca_davvero = true
	var m: Room = await _go(Router.MERCATO, "from_below")
	await _idle()
	await _still("arrivo")
	# Leda: "Hai bisogno di aiuto?", poi "Dai una mano"
	choose_queue = [1, 0]
	m = await _parla(m, "leda")
	await _gioca_inventario()
	m = await _torna(Router.MERCATO)
	_check(GameState.flags.get("c3_leda_inventario", false), "mercato: l'inventario di Leda giocato davvero non è riuscito")
	# Amir: "Dai una mano"
	choose_queue = [0]
	m = await _parla(m, "amir")
	await _gioca_consegne()
	m = await _torna(Router.MERCATO)
	_check(GameState.flags.get("c3_amir_bonus", false), "mercato: le consegne giocate davvero non hanno dato il bonus")
	# Amir racconta il sogno
	m = await _parla(m, "amir")
	# Nives: la prima volta saluta, la seconda il badge cade dal cassetto ("Raccoglilo")
	await _to_booth(m)
	m.player.call("face", "up")
	await _ok()
	choose_queue = [0]
	await _to_booth(m)
	m.player.call("face", "up")
	await _ok()
	_check(GameState.has_badge("-2") and str(GameState.flags.get("c3_badge", "")) == "regalo", "mercato: Nives non ha regalato il badge")
	_check(int(GameState.flags.get("c3_turni", 0)) == 0, "mercato: nella strada buona non si dovrebbe lavorare")
	await _still("col_badge")
	# le scale: si sale tenendo premuto su
	var st := m.find_child("ScaleSu", true, false) as Node2D
	# _walk si ferma 16 px a sinistra del punto: così arriva proprio sotto il primo gradino
	var step := st.get_node("PrimoGradino") as Node2D
	await _walk(m, step.global_position + Vector2(16, 20))
	# in mezzo al tornello: un passo a destra o a sinistra, con le frecce
	var mid := step.global_position.x + 16.0
	var k := 0
	while absf(m.player.global_position.x - mid) > 1.5 and k < 120:
		_press("move_right", m.player.global_position.x < mid)
		_press("move_left", m.player.global_position.x > mid)
		await get_tree().physics_frame
		k += 1
	_press("move_right", false)
	_press("move_left", false)
	_press("move_up", true)
	var n := 0
	while _scene_path() == Router.MERCATO and n < 8000:
		await get_tree().process_frame
		n += 1
		_press("move_up", not (Ui.busy or Ui.cutscene or Ui.transitioning))
	_press("move_up", false)
	if _scene_path() == Router.MERCATO:
		_shot("bloccato_alle_scale")
		_fail("mercato: salendo le scale non si arriva alla Banca (giocatore a %s)" % str(m.player.global_position))
		_gioca_davvero = false
		return
	await _wait_scene(Router.BANCA, 60000)
	await _idle()
	await _still("banca")
	_gioca_davvero = false


## Cammina fino alla persona e preme OK, come nel gioco.
func _parla(m: Room, id: String) -> Room:
	await _walk_to_target(m, "", [], id)
	await _ok()
	return get_tree().current_scene as Room


func _ok() -> void:
	_tap("confirm")
	await get_tree().process_frame
	await _idle()
	for i in 20:
		await get_tree().process_frame


func _torna(path: String) -> Room:
	await _wait_scene(path, 60000)
	await _idle()
	return get_tree().current_scene as Room


func _in_gioco() -> Node:
	await _wait_scene(Router.MINIGAME, 60000)
	var g := get_tree().current_scene
	while g.get("phase") != "play" or Ui.busy:
		await get_tree().process_frame
	return g


## SCATOLE E SCAFFALI: legge il prodotto e lo porta sul suo scaffale con le frecce.
func _gioca_inventario() -> void:
	var g := await _in_gioco()
	_shot("scatole_inizio")
	var guard := 0
	while g.get("phase") == "play" and guard < 80:
		guard += 1
		var q: Array = g.get("inv_queue")
		if q.is_empty():
			break
		var want := int((q[0] as Array)[1])
		while int(g.get("inv_sel")) != want:
			_tap("move_right")
			await get_tree().create_timer(0.12).timeout
		await get_tree().create_timer(0.2).timeout
		_tap("confirm")
		await get_tree().create_timer(0.25).timeout
		if guard == 4:
			_shot("scatole_meta")
	_check(int(g.get("misses")) == 0, "scatole e scaffali: errori %d" % int(g.get("misses")))


## L'ULTIMA CONSEGNA: le strade sicure, senza cantiere (si arriva giusti col tempo).
func _gioca_consegne() -> void:
	var g := await _in_gioco()
	_shot("consegne_inizio")
	# mattina: magazzino, Scala B, Piazza, Via dei Fiori. Pomeriggio: magazzino, Scuola, Via Roma, Ospedale
	for tappa: Array in [[2, 5, 4], [2, 5, 6]]:
		for dest: int in tappa:
			while float(g.get("rt_k")) < 1.0:
				await get_tree().process_frame
			var nb: Array = g.call("_rt_neighbors", int(g.get("rt_at")))
			var want := nb.find(dest)
			while int(g.get("rt_sel")) != want:
				_tap("move_right")
				await get_tree().create_timer(0.12).timeout
			await get_tree().create_timer(0.2).timeout
			_tap("confirm")
			await get_tree().create_timer(0.3).timeout
		_shot("consegne_fine_giro")
	while g.get("phase") == "play":
		await get_tree().process_frame
	_check(int(g.get("rt_total")) == 6, "l'ultima consegna: pacchi %d su 6" % int(g.get("rt_total")))


## La Presidente, la prima volta, con le quattro richieste (arrivata, a mano, archiviata, nessuna).
func _test_presidente() -> void:
	for r: String in ["direzione", "a_mano", "archivio", "riepilogo"]:
		_section = "presidente_" + r
		_c6_reset()
		var f := GameState.flags
		if r == "riepilogo":
			f["c4_riepilogo"] = true
		else:
			f["c4_verifica"] = true
			f["c5_richiesta"] = r
		f["c4_ricevuta_copia"] = r == "archivio"
		var m: Room = await _go(Router.CIMA, "desk")
		m = await _c6_settle()
		director_plan = [{"alloc": {"stipendi": 45, "servizi": 20, "manutenzione": 25, "riserve": 10}}]
		choose_queue = [0, 1, 0, 1, 2, 0, 0, 1, 2, 0, 0, 0]
		m.call("talk_president")
		await _wait_scene(Router.DIREZIONE)
		await _idle()
	_section = "archivio_senza_copia"
	_c6_reset()
	GameState.flags["c4_verifica"] = true
	GameState.flags["c5_richiesta"] = "archivio"
	var m2: Room = await _go(Router.CIMA, "desk")
	m2 = await _c6_settle()
	choose_queue = [0]
	m2 = await _c6_call(m2, "_request_answer")
	m2 = await _c6_call(m2, "_verification")
	_check(GameState.flags.get("c6_contestazione", false), "archiviata senza copia: si può contestare")


func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if Ui.busy:
		if Ui.get("_typing"):
			Ui.set("_typed", 100000.0)
			return
		var key := _key()
		if key != _last_key:
			if _hold == 0:
				_hold = 4
				return
			_hold -= 1
			if _hold > 0:
				return
			_last_key = key
			_shot(_label_for_ui())
			_check_ui()
	elif scene and scene.scene_file_path == Router.FINALE and _finale_label(scene):
		return
	elif _gioca_davvero and scene and scene.scene_file_path == Router.MINIGAME:
		return
	super(delta)
	if scene and scene.scene_file_path == Router.FINALE:
		# nei finali si aspettano le pause vere: le scritte devono restare a schermo per essere viste
		scene.set("fast", false)


func _key() -> String:
	var t: Label = Ui.get("_text")
	return str(Ui.get("_mode")) + "|" + t.text + "|" + str(Ui.get("_options"))


func _label_for_ui() -> String:
	var t: Label = Ui.get("_text")
	return t.text.left(30)


## Le scritte del finale (frase finale, titoli): una schermata quando sono del tutto visibili.
func _finale_label(scene: Node) -> bool:
	for l: Label in scene.find_children("*", "Label", true, false):
		if not l.is_visible_in_tree() or l.text.strip_edges() == "" or l.modulate.a < 0.99:
			continue
		var k := l.text.left(80)
		if _seen_labels.has(k):
			continue
		if _hold == 0:
			_hold = 4
			return true
		_hold -= 1
		if _hold > 0:
			return true
		_seen_labels[k] = true
		_shot("scritta_" + l.text.left(24))
		var r := Rect2(l.global_position, l.size)
		if l.get_line_count() * l.get_line_height() > l.size.y + 2 and l.vertical_alignment != VERTICAL_ALIGNMENT_TOP:
			_problemi.append("%s: la scritta \"%s\" non sta nel suo spazio (%d righe)" % [_section, l.text.left(40), l.get_line_count()])
		if not VIEW.grow(1).encloses(r) and l.vertical_alignment != VERTICAL_ALIGNMENT_TOP:
			_problemi.append("%s: la scritta \"%s\" esce dallo schermo" % [_section, l.text.left(40)])
		return true
	return false


func _shot(what: String) -> void:
	_n += 1
	var safe := what.to_lower().replace(" ", "_").validate_filename().left(30)
	var path := _out + "%04d_%s_%s.png" % [_n, _section, safe]
	get_viewport().get_texture().get_image().save_png(path)


## Il testo sta nel riquadro? Le scelte stanno nello schermo e non coprono il testo?
func _check_ui() -> void:
	var t: Label = Ui.get("_text")
	var line_h := t.get_line_height() + t.get_theme_constant("line_spacing")
	var max_lines := maxi(1, int((t.size.y + 2.0) / line_h))
	if t.get_line_count() > max_lines:
		_problemi.append("%s #%d: testo di %d righe in un riquadro da %d: \"%s\"" % [_section, _n, t.get_line_count(), max_lines, t.text.left(60)])
	if str(Ui.get("_mode")) == "choose":
		var box: Panel = Ui.get("_choice_box")
		var r := Rect2(box.position, box.size)
		_min_row = minf(_min_row, (box.size.y - 8.0) / maxf(1.0, (Ui.get("_options") as Array).size()))
		if not VIEW.encloses(r):
			_problemi.append("%s #%d: le scelte escono dallo schermo (%s): %s" % [_section, _n, r, str(Ui.get("_options")).left(80)])
		var dlg: Panel = Ui.get("_box")
		if r.intersects(Rect2(dlg.position, dlg.size)):
			_problemi.append("%s #%d: le scelte coprono il riquadro del testo" % [_section, _n])


# --- Città: prima di ogni dialogo il giocatore ci arriva camminando, coi tasti di movimento -----------

const CHI := {"_rina_window": "rina", "_nadir_after": "nadir", "_leda": "leda", "_amir": "amir"}
var _camminate := 0
var _non_raggiunti: Array[String] = []
var _ok_non_arriva: Array[String] = []


func _c5_call(m: Room, method: String, args: Array = []) -> Room:
	if _section.begins_with("citta"):
		# Leda e Amir sono in piazza solo il giorno della protesta (citta_c5._visitors): come nel gioco
		var id: String = CHI.get(method, "")
		if id != "" and _target_of(m, method, args, "") is Marker2D:
			GameState.flags["c5_protesta"] = true
			m = await _go(Router.CITY, "from_below")
		await _walk_to_target(m, method, args)
	return await super(m, method, args)


func _c5_talk(id: String) -> Room:
	if _section.begins_with("citta"):
		await _walk_to_target(get_tree().current_scene as Room, "", [], id)
	return await super(id)


## Chi o cosa c'è dietro al dialogo: la persona, il posto di lavoro o l'oggetto con quel metodo.
func _target_of(m: Room, method: String, args: Array, id: String) -> Node2D:
	if id == "":
		id = CHI.get(method, "")
	if id != "":
		for n in get_tree().get_nodes_in_group("npc"):
			if n.get("id") == id and (n as Node2D).is_visible_in_tree():
				return n
		var people: Variant = m.get("people")
		if people is Dictionary and (people as Dictionary).has(id.capitalize()):
			return people[id.capitalize()]
		return m.get_node_or_null("Posti/Posto" + id.capitalize()) as Node2D
	for n in m.find_children("*", "Node2D", true, false):
		if method == "_station" and args.size() > 0 and n.get("job") != null and str(n.get("job")) == str((args[0] as Dictionary).get("id", "")):
			return n
		if n.get("method") != null and str(n.get("method")) == method:
			return n
	return null


func _walk_to_target(m: Room, method: String, args: Array, id := "") -> void:
	var t := _target_of(m, method, args, id)
	var what := id if id != "" else method
	if t == null or m.player == null:
		_non_raggiunti.append(what + " (non trovato)")
		return
	if not await _walk(m, t.global_position):
		_non_raggiunti.append(what)
		return
	_camminate += 1
	# da dove sei, il tasto OK raggiungerebbe proprio lei? (come nel gioco: Player._find_target)
	var hit: Node = m.player.call("_find_target")
	# i posti di lavoro e gli oggetti diventano un Interactable con la stessa azione: vale quella
	var act: Variant = hit.get("action") if hit != null else null
	if act is Callable and (act as Callable).get_method() in [method, "use_station"]:
		return
	# un'azione scritta come lambda: vale se il punto toccato è proprio sopra la cosa giusta
	if hit is Node2D and (hit as Node2D).global_position.distance_to(t.global_position) <= 20.0:
		return
	if hit != t and not (hit != null and t.is_ancestor_of(hit)) and not (hit != null and hit.is_ancestor_of(t)) \
			and not (t.has_meta("spot") and hit == t.get_meta("spot")):
		_ok_non_arriva.append("%s (OK prende %s a %.0f px)" % [what, hit.name if hit else "niente", (hit as Node2D).global_position.distance_to(t.global_position) if hit is Node2D else -1.0])


## Cammina fino a vicino a `goal`: percorso su una griglia di 8 px (le caselle libere le dice la fisica),
## poi i tasti di movimento premuti davvero, punto per punto.
func _walk(m: Room, goal: Vector2) -> bool:
	var p := m.player
	var shape := p.get_node("Collisione") as CollisionShape2D
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape.shape
	q.exclude = [p.get_rid()]
	q.collision_mask = p.collision_mask
	var space := p.get_world_2d().direct_space_state
	var c := 8.0
	var region := Rect2(p.global_position, Vector2.ZERO).expand(goal).grow(160)
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(Vector2i((region.position / c).floor()), Vector2i((region.size / c).ceil()) + Vector2i.ONE)
	grid.cell_size = Vector2(c, c)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for x in range(grid.region.position.x, grid.region.end.x):
		for y in range(grid.region.position.y, grid.region.end.y):
			q.transform = Transform2D(0, Vector2(x, y) * c + shape.position)
			if not space.intersect_shape(q, 1).is_empty():
				grid.set_point_solid(Vector2i(x, y))
	var from := Vector2i((p.global_position / c).round())
	grid.set_point_solid(from, false)
	# arrivo: a fianco della persona (16 px), così non la copri; poi sotto, poi più lontano
	var best := Vector2i(-99999, -99999)
	var gcell := Vector2i((goal / c).round())
	for off: Vector2i in [Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, 2), Vector2i(-2, 1), Vector2i(2, 1),
			Vector2i(0, 3), Vector2i(-3, 0), Vector2i(3, 0), Vector2i(0, -2), Vector2i(0, 4), Vector2i(-4, 0), Vector2i(4, 0)]:
		var cc := gcell + off
		if grid.is_in_boundsv(cc) and not grid.is_point_solid(cc) and not grid.get_id_path(from, cc).is_empty():
			best = cc
			break
	if best.x == -99999:
		return false
	for wp: Vector2i in grid.get_id_path(from, best):
		var target := Vector2(wp) * c
		var n := 0
		while p.global_position.distance_to(target) > 2.0 and n < 90:
			var d := target - p.global_position
			_press("move_right", d.x > 1.0)
			_press("move_left", d.x < -1.0)
			_press("move_down", d.y > 1.0)
			_press("move_up", d.y < -1.0)
			await get_tree().physics_frame
			n += 1
	for a: String in ["move_right", "move_left", "move_down", "move_up"]:
		Input.action_release(a)
	var look := goal - p.global_position
	p.call("face", ("right" if look.x > 0 else "left") if absf(look.x) > absf(look.y) else ("down" if look.y > 0 else "up"))
	for i in 20:
		await get_tree().process_frame
	return p.global_position.distance_to(goal) < 56.0


func _press(a: String, on: bool) -> void:
	if on:
		Input.action_press(a)
	else:
		Input.action_release(a)


## Come nel gioco: il giocatore è sul primo gradino quando parte la scena delle scale.
func _stairs(m: Room, queue: Array) -> Room:
	var st := m.find_child("ScaleSu", true, false) as Node2D
	if st:
		m.player.global_position = st.global_position + Vector2(16, 4)
		for i in 30:
			await get_tree().process_frame
	return await super(m, queue)
