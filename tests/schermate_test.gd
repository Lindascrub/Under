extends "res://tests/storia_test.gd"
## Schermate di controllo: gioca le scene della storia (come storia_test) in una finestra vera e salva
## un'immagine per ogni battuta e ogni scelta, più le scritte dei finali. Controlla anche, battuta per
## battuta, che il testo non esca dal riquadro e che le scelte stiano nello schermo.
## Esegui (non headless):
##   Godot --path . res://tests/schermate_test.tscn -- --out=<cartella>            (PC)
##   Godot --path . res://tests/schermate_test.tscn -- --touch --size=1600x720 --out=<cartella>   (telefono 20:9)
## --size cambia la finestra da dentro il gioco: --resolution più grande dello schermo viene ridotta da Windows.
## Opzionale: --solo=banca,citta,presidente,finali,tocco  (tocco: joystick e pulsanti mentre si cammina,
## e lo schermo della Direzione col dito; con --touch)

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


func _still(what: String) -> void:
	for i in 40:
		await get_tree().process_frame
	_shot(what)


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


## Come nel gioco: il giocatore è sul primo gradino quando parte la scena delle scale.
func _stairs(m: Room, queue: Array) -> Room:
	var st := m.find_child("ScaleSu", true, false) as Node2D
	if st:
		m.player.global_position = st.global_position + Vector2(16, 4)
		for i in 30:
			await get_tree().process_frame
	return await super(m, queue)
