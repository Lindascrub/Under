extends "res://tests/smoke_test.gd"
## Test automatico della schermata admin (scripts/admin.gd): col nome Porcoretto si parte dal Fondo con
## la schermata aperta, e ogni voce porta dove deve (piani, minigiochi, turni, incarichi del Capo).
## Esegui:  Godot --headless --path . res://tests/admin_test.tscn
## Alla fine stampa "ADMIN TEST OK" oppure gli errori trovati.

const B := preload("res://scripts/boss_missions.gd")


func _ready() -> void:
	GameState.save_path = "user://test_admin.json"
	process_mode = Node.PROCESS_MODE_ALWAYS
	var placeholder := Node.new()
	get_tree().root.add_child.call_deferred(placeholder)
	await get_tree().process_frame
	get_tree().current_scene = placeholder
	await _run()


func _run() -> void:
	GameState.new_game()
	GameState.player_name = "Porcoretto"
	_check(Admin.attivo(), "il nome Porcoretto non apre l'admin")
	# la partita admin: si parte dal Fondo con la schermata già aperta (la si chiude: ultima voce)
	GameState.flags["c1_arrivo"] = true
	GameState.flags["admin_apri"] = true
	choose_queue = [5]
	await _go(Router.FONDO)
	await _idle()
	_check(_scene_path() == Router.FONDO, "la partita admin non parte dal Fondo")
	_check(choose_queue.is_empty(), "la schermata admin non si apre da sola")
	# i piani: tutti, uno dopo l'altro
	for i in Admin.PIANI.size():
		choose_queue = [0] + _pagina(i)
		await _apri()
		await _wait_scene(Admin.PIANI[i][1])
		await _idle()
		_check(_scene_path() == Admin.PIANI[i][1], "admin: non si arriva a " + str(Admin.PIANI[i][0]))
	await _go(Router.FONDO)
	await _idle()
	# i minigiochi dei personaggi (vinti dal test): poi si torna al Fondo
	var quanti := 0
	for id: String in GameState.npc_ids():
		var d := GameState.npc_data(id)
		var stanze: Array = (d.get("schedule", []) as Array).map(func(p: Dictionary) -> String: return str(p.get("room", "")))
		if (d.get("help", {}) as Dictionary).has("minigame") and not stanze.has("nessuno"):
			quanti += 1
	_check(quanti >= 8, "admin: troppo pochi minigiochi (%d)" % quanti)
	for k in quanti:
		choose_queue = [1] + _pagina(k)
		await _apri()
		await _wait_scene(Router.MINIGAME)
		_check(_scene_path() == Router.MINIGAME, "admin: il minigioco %d non parte" % k)
		await _wait_scene(Router.FONDO)
		await _idle()
	# i turni (dopo un turno a volte chiama il Capo, come nel gioco: il test risponde "Più tardi")
	choose_index = 1
	var turni := GameState.jobs_available().filter(func(j: Dictionary) -> bool: return j.has("game")).size()
	for k in turni:
		choose_queue = [2] + _pagina(k)
		await _apri()
		await _wait_scene(Router.WORK)
		_check(_scene_path() == Router.WORK, "admin: il turno %d non parte" % k)
		await _wait_scene(Router.FONDO)
		await _idle()
	# gli incarichi del Capo: si apre la schermata, poi si torna al Fondo
	for k in 5:
		choose_queue = [3, k]
		await _apri()
		await _wait_scene(B.SCENE)
		_check(_scene_path() == B.SCENE, "admin: l'incarico del Capo %d non parte" % k)
		await _go(Router.FONDO)
		await _idle()
	choose_queue = [3, 5]
	await _apri()
	await _wait_scene(Router.DIREZIONE)
	_check(_scene_path() == Router.DIREZIONE, "admin: la Direzione non parte")
	await _go(Router.FONDO)
	await _idle()
	# soldi, badge, energia
	var prima := GameState.money
	choose_queue = [4, 0, 1, 2, 3, 5]
	await _apri()
	await _idle()
	_check(GameState.money == prima + 10000, "admin: i soldi non arrivano")
	_check(GameState.has_badge("cima"), "admin: i badge non arrivano")
	# con un altro nome la voce Admin non c'è
	GameState.player_name = "Luca"
	_check(not Admin.attivo(), "l'admin si apre anche con un altro nome")
	if _failures.is_empty():
		print("ADMIN TEST OK")
	else:
		print("ADMIN TEST FALLITO:")
		for f in _failures:
			print("- " + f)
	get_tree().quit(0 if _failures.is_empty() else 1)


## Le scelte per arrivare alla voce k di una lista a pagine ("Altri" quante volte serve).
func _pagina(k: int) -> Array:
	var out: Array = []
	for p in k / Admin.PER_PAGINA:
		out.append(Admin.PER_PAGINA)
	out.append(k % Admin.PER_PAGINA)
	return out


## Apre la schermata admin dal menu Stato, come farebbe il giocatore.
func _apri() -> void:
	if not get_tree().current_scene is Room:
		_fail("admin: non sono in una stanza (%s)" % _scene_path())
		return
	choose_queue.push_front(GameState.items.size())
	Ui.show_status()
	await get_tree().process_frame
