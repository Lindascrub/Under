extends "res://tests/smoke_test.gd"
var controlli := 0
var letti: Array[String] = []


func _check(ok: bool, messaggio: String) -> void:
	controlli += 1
	super(ok, messaggio)


func _process(_delta: float) -> void:
	_frame += 1
	var label: Label = Ui.get("_label")
	if Ui.busy and is_instance_valid(label) and label.text not in letti:
		letti.append(label.text)
	if Ui.busy and _frame % 3 == 0:
		if str(Ui.get("_mode")) == "choose":
			Ui.set("_sel", (Ui.get("_options") as Array).size() - 1)
		_tap("confirm")


func _apri(id: String, tel: bool) -> Node:
	GameState.new_game()
	TouchControls.enabled = tel
	GameState.floor_id = "-5"
	var persona := GameState.npc_data(id)
	var cfg := Npc.minigame_cfg(id, str(persona["name"]), persona["help"], Router.MENU, Vector2.ZERO)
	cfg["intro"] = []
	GameState.minigame = cfg
	Router.goto(Router.MINIGAME)
	await _wait_scene(Router.MINIGAME)
	var game := get_tree().current_scene
	_check(str(game.get("phase")) == "demo", "prima c'è una dimostrazione")
	var tempo := float(game.get("time_left"))
	var n := 0
	while str(game.get("phase")) == "demo" and n < 6000:
		await get_tree().process_frame
		n += 1
	_check(n < 6000, "dimostrazione conclusa")
	_check(game.get("prima_prova") and float(game.get("time_left")) == tempo, "prima prova senza consumare tempo")
	return game


func _chiudi(game: Node) -> void:
	game.call("_finish", false)
	await _wait_scene(Router.MENU)
	await _idle()


func _collega(game: Node, tel: bool, colore: int, corretto: bool) -> void:
	var ordine: Array = game.get("wire_right")
	var destra := ordine.find(colore)
	if not corretto:
		destra = (destra + 1) % 4
	var guida: Node = game.get_node("GuidaC1")
	var da: Vector2 = guida.get_node("FiliSinistra/%d" % colore).position
	var a: Vector2 = guida.get_node("FiliDestra/%d" % destra).position
	if tel:
		game.call("touch_point", da, 0)
		game.call("touch_point", a, 2)
	else:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = da
		e.pressed = true
		game.call("_unhandled_input", e)
		e = InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = a
		e.pressed = false
		game.call("_unhandled_input", e)


func _run() -> void:
	GameState.save_path = "user://test_c1_chiarezza.json"
	for tel in [false, true]:
		var game := await _apri("mina", tel)
		_check(game.get("bulb") == "fioca", "prima lampadina da aggiustare")
		var tempo := float(game.get("time_left"))
		game.call("_process", 5.0)
		game.call("_bulb_answer", false)
		_check(game.get("misses") == 0 and game.get("bulb") == "fioca", "sbagliare la prova non consuma errori né cambia lampadina")
		_check(float(game.get("time_left")) == tempo, "tempo fermo durante la prova")
		for i in 2:
			_tap("move_up")
			await get_tree().process_frame
		_check(game.get("bulb") == "buona", "avvitata resta accesa")
		_tap("move_right")
		await get_tree().process_frame
		_check(not game.get("prima_prova") and game.get("bulb_done") == 1, "BUONE termina la prima prova")
		_check(GameState.flags.get("c1_prova_bulbs", false), "lezione delle lampadine ricordata")
		game.call("_bulb_answer", false)
		_check(game.get("misses") == 1, "dopo la prova gli errori contano")
		await _chiudi(game)
		game = await _apri("bulbo", tel)
		_collega(game, tel, 0, false)
		_check(game.get("misses") == 0 and (game.get("wire_done") as Array).is_empty(), "filo sbagliato nella prima prova: nessuna penalità")
		_collega(game, tel, 0, true)
		_check(not game.get("prima_prova") and 0 in (game.get("wire_done") as Array), "primo filo collegato termina la prova")
		_check(GameState.flags.get("c1_prova_wires", false), "lezione dei fili ricordata")
		_collega(game, tel, 1, false)
		_check(game.get("misses") == 1, "dopo la prova il collegamento sbagliato conta")
		await _chiudi(game)

	# Presentazione di Bulbo nella stanza reale: etichette presenti e flag non bloccati.
	GameState.new_game()
	GameState.flags["c1_arrivo"] = true
	var fondo := await _go(Router.FONDO, "elevator")
	var bulbo := _npc("mina")
	# Isola il ripristino della ripresa dall'alzata automatica della camera nei dialoghi.
	fondo.camera_lift = 0
	fondo.alza_nei_dialoghi = 0
	fondo.player.camera.offset = Vector2(4, -8)
	var offset_prima: Vector2 = fondo.player.camera.offset
	var top_level_prima: bool = fondo.player.camera.top_level
	await bulbo.call("interact")
	_check(GameState.flags.get("met_mina", false), "Bulbo incontrata dopo aver indicato le scatole")
	_check(not Ui.cutscene, "la presentazione non blocca i comandi")
	_check(fondo.player.camera.offset == offset_prima, "camera ripristinata dopo aver mostrato le scatole")
	_check(fondo.player.camera.top_level == top_level_prima, "camera torna a seguire il giocatore")
	_check(fondo.get_node("Mondo/ScatolaLampadine1/Buone").text == "BUONE", "scatola delle buone indicata")
	_check(fondo.get_node("Mondo/ScatolaLampadine2/Rotte").text == "ROTTE", "scatola delle rotte indicata")
	var debito := GameState.debt
	await fondo.call("_save_here", fondo.player.global_position)
	_check(GameState.flags.get("c1_stellina_spiegata", false), "prima stellina spiegata")
	_check(str(letti).contains("domani puoi lavorare di nuovo"), "il giorno successivo spiegato alla stellina")
	_check(GameState.debt == debito, "annullare alla stellina non fa passare la notte")
	print("C1 CHIAREZZA TEST: %d controlli, errori %s" % [controlli, _failures])
	get_tree().quit(0 if _failures.is_empty() else 1)
