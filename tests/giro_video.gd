extends "res://tests/smoke_test.gd"
## La partita registrata: dall'ascensore al finale, piano per piano, parlando con tutti i personaggi.
## Va piano (le frasi restano a schermo per leggerle), i minigiochi si vedono qualche secondo e poi
## si vincono, si sceglie sempre la strada gentile (niente furti, niente firme col Capo).
## Si registra con il Movie Maker di Godot:
##   Godot --path . --write-movie ../video_giro/giro.avi --fixed-fps 30 res://tests/giro_video.tscn

## Quanti fotogrammi resta una frase già scritta, prima di andare avanti (30 = un secondo).
@export var tieni_frase := 55
@export var tieni_scelta := 45
## Quanti fotogrammi si guarda un minigioco o un turno prima di finirlo.
@export var guarda_gioco := 150
@export var nome := "Pietro"

const PIANI := [
	[Router.FONDO, "-5"], [Router.SOTTOUFFICIO, "-4"], [Router.MERCATO, "-3"], [Router.BANCA, "-2"],
	[Router.CITY, "0"], [Router.CASA_COMUNE, "0"], [Router.CIMA, "cima"],
]
## Le scelte da non fare (la strada cattiva) e quelle da preferire quando ci sono.
const EVITA := ["nascosto", "firma", "accett", "sfrutt", "ruba", "prendi i soldi", "sì, capo", "vendi"]
const PREFERISCI := ["rifiut", "lascia stare", "no", "più tardi", "chiudi l'offerta", "non "]

var _attesa := 0
var _gioco_t := 0
var _visti := {}


func _ready() -> void:
	GameState.save_path = "user://giro_video.json"
	var placeholder := Node.new()
	get_tree().root.add_child.call_deferred(placeholder)
	await get_tree().process_frame
	get_tree().current_scene = placeholder
	await _run()


var _ultima := ""


func _process(_delta: float) -> void:
	_frame += 1
	if _scene_path() != _ultima:
		_ultima = _scene_path()
		print("  -> ", _ultima.get_file(), " (frame ", _frame, ")")
	GameState.energy = GameState.MAX_ENERGY
	var scene := get_tree().current_scene
	if scene == null:
		return
	var path := scene.scene_file_path
	if path == Router.MINIGAME and not Ui.transitioning and scene.get("phase") == "play" and not Ui.busy:
		_gioco_t += 1
		if _gioco_t >= guarda_gioco:
			_gioco_t = 0
			var v: Node = scene.get("visivo")
			if v != null:
				v.errori = 0
				v.chiudi(true)
			else:
				scene.set("misses", 0)
				scene.call("_finish", true, false)
		return
	if path == Router.WORK and not Ui.transitioning and scene.get("phase") == "play" and not Ui.busy:
		_gioco_t += 1
		if _gioco_t >= guarda_gioco:
			_gioco_t = 0
			scene.set("score", scene.get("target"))
			scene.set("time_left", 0.0)
		return
	if path == Router.DIREZIONE and not Ui.transitioning and not Ui.busy:
		_attesa += 1
		if _attesa >= tieni_scelta:
			_attesa = 0
			_drive_direction(scene)
		return
	if not Ui.busy:
		_attesa = 0
		return
	if bool(Ui.get("_typing")):
		_attesa = 0
		return
	_attesa += 1
	if Ui.get("_mode") == "choose":
		if _attesa < tieni_scelta:
			return
		Ui.set("_sel", _scelta())
	elif _attesa < tieni_frase:
		return
	_attesa = 0
	_tap("confirm")


## Quale opzione: la coda delle scelte, poi la strada gentile; se un menu torna troppe volte, l'ultima voce.
func _scelta() -> int:
	var opts: Array = Ui.get("_options")
	if not choose_queue.is_empty():
		return mini(int(choose_queue.pop_front()), opts.size() - 1)
	var firma := str(Ui.get("_text").text) + "|" + ",".join(opts)
	_visti[firma] = int(_visti.get(firma, 0)) + 1
	if int(_visti[firma]) >= 3:
		return opts.size() - 1
	var cattiva := opts.any(func(o) -> bool: return _contiene(str(o), EVITA))
	for i in opts.size():
		var o := str(opts[i])
		if cattiva and _contiene(o, PREFERISCI) and not _contiene(o, EVITA):
			return i
	for i in opts.size():
		if not _contiene(str(opts[i]), EVITA) and str(opts[i]) != "Admin":
			return i
	return 0


func _contiene(t: String, parole: Array) -> bool:
	var b := t.to_lower()
	for p: String in parole:
		if b.contains(p):
			return true
	return false


## Aspetta che il gioco sia tornato in una stanza, fermo, senza dialoghi.
func _calma(max_frames := 9000) -> void:
	var fermo := 0
	var n := 0
	while fermo < 20 and n < max_frames:
		await get_tree().process_frame
		n += 1
		var ok := _scene_path() in Router.WORLD and not Ui.busy and not Ui.transitioning and not Ui.cutscene
		fermo = fermo + 1 if ok else 0
	if n >= max_frames:
		var sc := get_tree().current_scene
		_fail("bloccato in %s fase=%s busy=%s modo=%s typing=%s trans=%s cut=%s" % [_scene_path(), sc.get("phase") if sc else "-", Ui.busy, Ui.get("_mode"), Ui.get("_typing"), Ui.transitioning, Ui.cutscene])


func _persone() -> Array[String]:
	var ids: Array[String] = []
	for n in get_tree().get_nodes_in_group("npc"):
		if n.is_visible_in_tree() and not ids.has(str(n.get("id"))):
			ids.append(str(n.get("id")))
	return ids


func _parla(id: String) -> void:
	var n: Node = null
	for x in get_tree().get_nodes_in_group("npc"):
		if str(x.get("id")) == id:
			n = x
	if n == null or not is_instance_valid(n):
		return
	var room := get_tree().current_scene as Room
	if room and room.player:
		# si cammina fino alla persona
		var tw := create_tween()
		tw.tween_property(room.player, "global_position", (n as Node2D).global_position + Vector2(0, 20), 0.8)
		await tw.finished
	print("PARLA ", id, " in ", _scene_path().get_file())
	await n.call("interact")
	await _calma()


func _piano(path: String, badge: String) -> void:
	if badge != "-5" and not GameState.badges.has(badge):
		GameState.badges.append(badge)
	if _scene_path() != path:
		Router.goto(path, "from_below")
		await _wait_scene(path, 60000)
	await _calma()
	print("PIANO ", path.get_file(), " persone ", _persone())
	# due giri: il primo per conoscerli e aiutarli, il secondo per sentire cosa dicono dopo
	for giro in 2:
		for id in _persone():
			if _scene_path() != path:
				Router.goto(path)
				await _wait_scene(path, 60000)
				await _calma()
			await _parla(id)


func _run() -> void:
	GameState.new_game()
	GameState.player_name = nome
	var salta := Array(OS.get_cmdline_user_args()).any(func(x: String) -> bool: return x.begins_with("--da=") or x.begins_with("--solo="))
	if not salta:
		Router.goto(Router.ELEVATOR)
		await _wait_scene(Router.FONDO, 60000)
		await _calma()
	# --da=N parte dal piano N (solo per le prove), --solo=N fa soltanto quel piano
	var da := 0
	var a := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--da="): da = int(arg.substr(5))
		if arg.begins_with("--solo="): da = int(arg.substr(7)); a = da
	for i in PIANI.size():
		if i < da:
			if PIANI[i][1] != "-5" and not GameState.badges.has(PIANI[i][1]): GameState.badges.append(PIANI[i][1])
			continue
		await _piano(PIANI[i][0], PIANI[i][1])
		if a >= 0:
			print("GIRO VIDEO FINITO. Problemi: ", _failures)
			get_tree().quit()
			return
	# la Cima: la Presidente, il TURNO di Direzione, il Capo, la finestra, la scelta finale
	var m := get_tree().current_scene as Room
	director_plan = [{"alloc": {"stipendi": 45, "servizi": 20, "manutenzione": 25, "riserve": 10}, "casa": "risorse", "choice": "revisione"}]
	if m and m.has_method("talk_president"):
		choose_queue = [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
		m.call("talk_president")
		await _wait_scene(Router.DIREZIONE, 60000)
		choose_queue = [0, 99, 1, 2, 1]
		await _calma()
		m = get_tree().current_scene as Room
		if m and m.has_method("_boss_scene"):
			await m.call("_boss_scene")
			await _calma()
		m = get_tree().current_scene as Room
		if m and m.has_method("_finestra"):
			choose_queue = [0, 3, 9]
			await m.call("_finestra")
			await _calma()
		m = get_tree().current_scene as Room
		if m and m.has_method("final_choice"):
			choose_queue = [2, 0, 0, 0, 0]
			m.call("final_choice")
			await _wait_scene(Router.FINALE, 60000)
			# il finale va da solo: si aspetta la fine (titoli di coda, poi il menu)
			var n := 0
			while _scene_path() == Router.FINALE and n < 60000:
				await get_tree().process_frame
				n += 1
	print("GIRO VIDEO FINITO. Problemi: ", _failures)
	get_tree().quit()
