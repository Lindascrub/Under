extends "res://tests/smoke_test.gd"
## Test automatico: gioca dal Fondo alla Banca nelle tre strade (comunismo, capitalismo, baratto),
## poi scende e risale le scale più volte. Le scale si fanno a piedi (tasti premuti), i turni con il
## minigioco vero; la scelta della strada è data a GameState (sfruttare, liberare, aiutare).
## Esegui:  Godot --headless --path . res://tests/route_walk_test.tscn
## Alla fine stampa "ROUTE WALK OK" oppure gli errori trovati.

const FLOORS := [Router.FONDO, Router.SOTTOUFFICIO, Router.MERCATO, Router.BANCA]
const FLOOR_IDS := ["-5", "-4", "-3", "-2"]
const JOBS := ["dinamo", "callcenter", "cassa_mercato", "sportello_banca"]
const MUSIC := ["festa", "attesa", "mercato", "banca"]


func _ready() -> void:
	GameState.save_path = "user://test_route_walk.json"
	process_mode = Node.PROCESS_MODE_ALWAYS
	var placeholder := Node.new()
	get_tree().root.add_child.call_deferred(placeholder)
	await get_tree().process_frame
	get_tree().current_scene = placeholder
	await _run()


const B := preload("res://scripts/boss_missions.gd")
var _route := ""
var _missions := {}


## L'incarico del Capo (boss_mission): lo si fa come in tests/boss_playthrough_test.gd, con la
## scorciatoia solo sulla strada del capitalismo.
func _process(delta: float) -> void:
	var sc := get_tree().current_scene
	if sc and sc.scene_file_path == B.SCENE and not Ui.transitioning and not Ui.busy and _frame % 10 == 0 			and not _missions.has(sc.get_instance_id()):
		_missions[sc.get_instance_id()] = true
		_drive_mission(sc, _route == "capitalismo")
	if sc and sc.scene_file_path == B.SCENE and _frame % 600 == 0:
		print("  [incarico aperto] busy=", Ui.busy, " trans=", Ui.transitioning, " fatto=", _missions.has(sc.get_instance_id()), " floor=", sc.get("floor"), " msg=", sc.get("msg"), " fin=", sc.get("finishing"))
	super(delta)


func _drive_mission(m: Node, exploit: bool) -> void:
	match str(m.get("floor")):
		"-5":
			if exploit:
				m.call("_act", "extra"); m.call("_act", "extra"); m.call("_act", "extra")
			else:
				m.call("_act", "decor")
			m.call("_act", "simulate")
		"-4":
			for choice in [3, 3 if exploit else 2, 1, 2]:
				m.call("_act", "doc_%d" % choice)
		"-3":
			for i in 3:
				if exploit:
					m.call("_act", "units"); m.call("_act", "visible")
				m.call("_act", "submit")
		"-2":
			if exploit:
				m.call("_act", "visible")
			m.call("_act", "proposal")
	print("  incarico ", m.get("floor"), " sfruttando=", exploit, " msg=", m.get("msg"))
	for i in 200:
		await get_tree().process_frame
	if is_instance_valid(m) and get_tree().current_scene == m:
		print("  incarico ancora aperto: ", m.get("msg"), " p=", m.get("p"))


func _run() -> void:
	for route in ["comunismo", "capitalismo", "baratto"]:
		await _play_route(route)
	if _failures.is_empty():
		print("ROUTE WALK OK")
	else:
		print("ROUTE WALK FALLITO:")
		for f in _failures:
			print("- " + f)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _room() -> Room:
	return get_tree().current_scene as Room


func _play_route(route: String) -> void:
	print("== strada ", route)
	_route = route
	GameState.new_game()
	choose_index = 0
	minigame_result = "win"
	await _go(Router.FONDO, "elevator")
	for i in 3:
		await _play_floor(route, i)
		await _climb(i)
	_check(_scene_path() == Router.BANCA, route + ": non si arriva alla Banca")
	_check(GameState.route() == route, route + ": la strada è diventata " + GameState.route())
	# su e giù: Banca -> Mercato -> Banca -> ... -> Fondo -> Banca, due volte
	for round_ in 2:
		await _descend(3)
		await _climb(2)
		for i in [3, 2, 1]:
			if not await _descend(i):
				break
		var at := FLOORS.find(_scene_path())
		while at >= 0 and at < 3:
			await _climb(at)
			at += 1
		_check(_scene_path() == Router.BANCA, "%s: giro %d, non si torna alla Banca (sono in %s)" % [route, round_, _scene_path()])
	# alla fine della corsa: ancora tutto al suo posto
	_check(GameState.route() == route, route + ": dopo su e giù la strada è cambiata in " + GameState.route())
	for f in ["c1_rivelazione", "c2_rivelazione", "c3_rivelazione"]:
		_check(GameState.flags.get(f, false), route + ": manca " + f)


## Un piano: parli con tutti, fai la scelta della strada, lavori finché il badge si paga, lo prendi.
func _play_floor(route: String, i: int) -> void:
	var path: String = FLOORS[i]
	var room := _room()
	_check(GameState.floor_id == FLOOR_IDS[i], "%s: piano %s, floor_id %s" % [route, FLOOR_IDS[i], GameState.floor_id])
	var ids: Array = []
	for n in get_tree().get_nodes_in_group("npc"):
		if room.is_ancestor_of(n):
			ids.append(str(n.get("id")))
	if path == Router.SOTTOUFFICIO:
		room.call("_agenda")
		await _back_to(path)
	# tre giri di chiacchiere (in giorni diversi): aiutare qualcuno e poi riparlarci apre le strade
	for round_ in 3:
		GameState.met_today.clear()
		GameState.minutes = GameState.DAY_START
		for id in ids:
			var n := _find_npc(id)
			if n == null:
				continue
			n.call("interact")
			await _back_to(path)
	# la scelta della strada, su una persona di questo piano
	var who := ""
	for id in ids:
		if id in GameState.workers() and not GameState.is_robot(id):
			who = id
			break
	match route:
		"capitalismo":
			pass
		"baratto":
			if who != "":
				GameState.free_npc(who)
		"comunismo":
			if who != "":
				GameState.help(who, "time", 0)
	# i turni: veri, uno al giorno
	var need: String = FLOOR_IDS[i + 1]
	var turns := 0
	while not GameState.has_badge(need) and GameState.money < GameState.badge_cost(need) and turns < 12:
		GameState.worked_today = false
		GameState.minutes = GameState.DAY_START
		var spot := _station(JOBS[i])
		if spot == null:
			_fail("%s: nessun TURNO al %s" % [route, FLOOR_IDS[i]])
			break
		spot.interact()
		await _back_to(path)
		turns += 1
	if path == Router.SOTTOUFFICIO and not GameState.flags.get("c2_modulo_ok", false):
		# il B-4: consegnato (firmato da Ercole, timbrato da Tilde) o, per chi ha fretta, pagato
		choose_queue = [1] if route == "capitalismo" else [0]
		_room().call("_agenda")
		await _back_to(path)
		_check(GameState.flags.get("c2_modulo_ok", false), route + ": il Modulo B-4 non si timbra")
	# lo sportello a volte prima chiacchiera (Nives, il prezzo): ci si torna finché il badge arriva
	for k in 3:
		if GameState.has_badge(need):
			break
		_room().call("_badge_machine")
		await _back_to(path)
	_check(GameState.has_badge(need), "%s: al %s il badge del %s non arriva (soldi %d, turni %d)" % [route, FLOOR_IDS[i], need, GameState.money, turns])
	if not GameState.has_badge(need):
		GameState.badges.append(need)


func _find_npc(id: String) -> Node:
	for n in get_tree().get_nodes_in_group("npc"):
		if str(n.get("id")) == id and _room() and _room().is_ancestor_of(n):
			return n
	return null


func _station(job_id: String) -> Interactable:
	for n in get_tree().get_nodes_in_group("interactable"):
		if n is Interactable and n.get_meta("job_id", "") == job_id and _room() and _room().is_ancestor_of(n):
			return n
	return null


## Dopo un dialogo o un minigioco: aspetta di essere di nuovo sul piano, senza niente aperto.
func _back_to(path: String) -> void:
	# fermi per davvero: venti frame di fila senza dialoghi, dissolvenze o scene scriptate, sul piano
	var calm := 0
	var n := 0
	while calm < 20 and n < 40000:
		await get_tree().process_frame
		n += 1
		calm = calm + 1 if _scene_path() == path and not Ui.blocks_input() else 0
	if n >= 40000:
		_fail("bloccato fuori dal piano %s (scena %s, busy %s, trans %s)" % [path, _scene_path(), Ui.busy, Ui.transitioning])


## Sale le scale del piano `i` camminando; controlla dove arrivi.
func _climb(i: int) -> void:
	var room := _room()
	var target: String = FLOORS[i + 1]
	var exit: Vector2 = room.get("_stairs_up_exit")
	if exit == Vector2.INF:
		_fail("%s: niente scale in su" % FLOOR_IDS[i])
		return
	if i == 0 and _route != "capitalismo" and not GameState.flags.get("c1_rivelazione", false):
		# il primo gradino accende la rivelazione; poi si torna giù ad ascoltare Fermo (le scale restano aperte)
		await _back_to(room.scene_file_path)
		room.player.position = exit + Vector2(0, 20)
		Input.action_press("move_up")
		var n := 0
		while not GameState.flags.get("c1_rivelazione", false) and n < 1500:
			await get_tree().physics_frame
			n += 1
		Input.action_release("move_up")
		await _back_to(room.scene_file_path)
		var fermo := _find_npc("fermo")
		_check(fermo != null, "al Fondo non trovo Fermo dopo la rivelazione")
		if fermo:
			fermo.call("interact")
			await _back_to(room.scene_file_path)
		_check(GameState.flags.get("svelato_fermo", false), _route + ": Fermo non dice la verità dopo la rivelazione")
	await _walk(room, exit + Vector2(0, 20), "move_up", target)
	await _arrived(target, i + 1, "salendo")


## Scende dal piano `i` camminando. Falso se le scale non ci sono (il Fondo sbarrato).
func _descend(i: int) -> bool:
	var room := _room()
	var target: String = FLOORS[i - 1]
	var exit: Vector2 = room.get("_stairs_down_exit")
	if exit == Vector2.INF:
		_check(i == 1 and GameState.flags.get("c1_sbarrato", false), "%s: niente scale in giù" % FLOOR_IDS[i])
		return false
	var pos: Vector2 = room.get("_stairs_down_pos")
	if pos == Vector2.INF:
		# al posto delle scale il buco sbarrato: succede solo se dal Fondo sei salito senza voltarti
		_check(i == 1 and GameState.flags.get("c1_sbarrato", false), "%s: scale in giù senza gradini" % FLOOR_IDS[i])
		_check(_route == "capitalismo", _route + ": il Fondo è sbarrato anche se hai ascoltato Fermo")
		return false
	var dir := "move_down" if pos.y > exit.y else "move_up"
	await _walk(room, exit + (exit - pos).normalized() * 18.0, dir, target)
	await _arrived(target, i - 1, "scendendo")
	return _scene_path() == target


func _walk(room: Room, from: Vector2, action: String, target: String) -> void:
	await _back_to(room.scene_file_path)
	room.player.position = from
	room.player.velocity = Vector2.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_press(action)
	var n := 0
	while _scene_path() != target and n < 1500:
		await get_tree().physics_frame
		n += 1
		# i dialoghi delle scale (la fine del capitolo) vanno avanti da soli; il tasto resta premuto
		if not is_instance_valid(room) or get_tree().current_scene != room:
			break
	Input.action_release(action)
	if is_instance_valid(room) and get_tree().current_scene == room:
		print("  [scale] ferma in ", room.player.position, " partita da ", from, " blocca=", Ui.blocks_input(), " busy=", Ui.busy, " cut=", Ui.cutscene, " trans=", Ui.transitioning)
	await _wait_scene(target)


func _arrived(target: String, i: int, how: String) -> void:
	await _idle()
	var room := _room()
	_check(_scene_path() == target, "%s verso il %s: sono in %s" % [how, FLOOR_IDS[i], _scene_path()])
	if room == null or _scene_path() != target:
		return
	_check(GameState.floor_id == FLOOR_IDS[i], "%s al %s: floor_id %s" % [how, FLOOR_IDS[i], GameState.floor_id])
	_check(not Ui.blocks_input(), "%s al %s: l'interfaccia resta bloccata" % [how, FLOOR_IDS[i]])
	# il personaggio non è incastrato: almeno una direzione è libera
	var p := room.player
	var free := false
	for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		if not p.test_move(p.global_transform, d * 8.0):
			free = true
	_check(free, "%s al %s: il personaggio è incastrato in %s" % [how, FLOOR_IDS[i], p.position])
	print("  ", how, " -> ", FLOOR_IDS[i], " pos ", p.position, " musica ", Sound.get("_music_name"))
