extends Node
## Regressioni della gomitata: forza, momento, strategie monotone, comandi e premi.
const SCENA := preload("res://scenes/minigame/ercole_gomitata.tscn")
var errori: Array[String] = []
var controlli := 0
var visti: Array[String] = []
var accetta_rigioco := false


func verifica(ok: bool, testo: String) -> void:
	controlli += 1
	if not ok:
		errori.append(testo)
		push_error(testo)


func _nuovo() -> Node:
	var g := SCENA.instantiate()
	add_child(g)
	g.set_process(false)
	g.avvia()
	return g


func _evento(premuto: bool) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = "confirm"
	e.pressed = premuto
	return e


func _scena() -> String:
	var corrente := get_tree().current_scene
	return corrente.scene_file_path if is_instance_valid(corrente) else ""


func _ready() -> void:
	await get_tree().process_frame
	GameState.save_path = "user://test_ercole_gomitata.json"
	GameState.new_game()
	for tel in [false, true]:
		TouchControls.enabled = tel
		var g := _nuovo()
		g.passo(5.0)
		verifica(not g.attivo and g.riuscite == 0, "senza input Ercole si addormenta")
		g.avvia()
		g.premi()
		g.passo(1.3)
		verifica(not g.attivo and g.ispettore.flip_h, "tenere premuto fa girare l'ispettore")
		g.avvia()
		for i in 3:
			g.premi()
			g.passo(0.01)
			g.lascia()
			g.passo(g.recupero)
		verifica(not g.attivo and g.riuscite == 0 and g.errori == 3, "premere a raffica non vince")
		g.avvia()
		g.sonno = 0.7
		g.premi()
		g.passo(0.05)
		g.lascia()
		verifica(g.riuscite == 0 and g.sonno > 0.7, "colpo debole lascia Ercole assonnato")
		g.avvia()
		for i in 4:
			g.passo(g.recupero)
			g.sonno = 0.68
			g.input_event(_evento(true))
			g.passo(0.6)
			g.input_event(_evento(false))
		verifica(not g.attivo and g.riuscite == 4 and g.errori == 0, "quattro gomitate precise vincono senza errori")
		g.avvia()
		g.input_event(_evento(true))
		g.passo(0.2)
		g.premi("mouse")
		g.lascia("mouse")
		verifica(g.premuto and g.riuscite == 0, "un'altra fonte non rilascia la carica")
		g._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
		verifica(not g.premuto and g.carica == 0, "perdita focus annulla la pressione")
		if not tel:
			g.avvia()
			g.sonno = 0.68
			var mouse := InputEventMouseButton.new()
			mouse.button_index = MOUSE_BUTTON_LEFT
			mouse.pressed = true
			g.input_event(mouse)
			g.passo(0.6)
			mouse.pressed = false
			g.input_event(mouse)
			verifica(g.riuscite == 1, "mouse carica e rilascia")
		g.free()

	# Integrazione con minigame.gd: input touch e ricompensa comune con record.
	var placeholder := Node.new()
	get_tree().root.add_child(placeholder)
	get_tree().current_scene = placeholder
	GameState.floor_id = "-4"
	for tentativo in 3:
		var mg: Dictionary = GameState.npc_data("ercole")["help"]["minigame"].duplicate(true)
		mg.merge({"id": "ercole", "name": "Ercole", "intro": [], "win": ["Grazie."], "return": Router.MENU, "reward": 120}, true)
		if tentativo > 0:
			mg["rigioco"] = true
			mg["stelle_prima"] = int(GameState.flags.get("stelle_ercole", 0))
		GameState.minigame = mg
		get_tree().change_scene_to_file(Router.MINIGAME)
		await get_tree().scene_changed
		var game := get_tree().current_scene
		var avvio := 0
		while (str(game.get("phase")) != "play" or Ui.transitioning or Ui.busy) and avvio < 2400:
			await get_tree().process_frame
			avvio += 1
		verifica(avvio < 2400, "minigioco avviato dopo la dissolvenza")
		# L'autoload aggiorna lo schema dei gesti nel suo _process, dopo il cambio scena.
		for i in 2:
			await get_tree().process_frame
		verifica(TouchControls.scheme == "point", "Ercole attiva i gesti di pressione e rilascio")
		var gomito: Node = game.get_node("ErcoleGomitata")
		gomito.set_process(false)
		gomito.sonno = 0.68
		var tocco := InputEventScreenTouch.new()
		tocco.position = Vector2(300, 200)
		tocco.pressed = true
		Input.parse_input_event(tocco)
		await get_tree().process_frame
		gomito.passo(0.6)
		tocco = InputEventScreenTouch.new()
		tocco.position = Vector2(300, 200)
		tocco.pressed = false
		Input.parse_input_event(tocco)
		await get_tree().process_frame
		verifica(gomito.riuscite == 1, "tocco passa da TouchControls alla gomitata")
		gomito.attivo = false
		game.set("misses", 2 if tentativo == 0 else 0)
		var prima := GameState.money
		game.call("_finish", true)
		var frames := 0
		while get_tree().current_scene == game and frames < 2400:
			await get_tree().process_frame
			frames += 1
		verifica(frames < 2400, "risultato torna al menu")
		verifica(GameState.money - prima == [40, 80, 0][tentativo], "premio a terzi e rigioco solo differenza")
	verifica(GameState.flags.get("stelle_ercole", 0) == 3, "record tre stelline salvato")
	# Si può davvero rigiocare parlando con Ercole, non soltanto costruendo la config a mano.
	GameState.flags["c2_arrivo"] = true
	GameState.flags["met_ercole"] = true
	GameState.flags["thanked_ercole"] = true
	GameState.minutes = GameState.DAY_START
	var fine_dissolvenza := 0
	while Ui.transitioning and fine_dissolvenza < 2400:
		await get_tree().process_frame
		fine_dissolvenza += 1
	Router.goto(Router.SOTTOUFFICIO, "from_below")
	var attesa := 0
	while (_scena() != Router.SOTTOUFFICIO or Ui.busy or Ui.transitioning) and attesa < 2400:
		await get_tree().process_frame
		attesa += 1
	verifica(attesa < 2400, "arrivo al Sottoufficio per il rigioco")
	var npc: Node = null
	for persona in get_tree().get_nodes_in_group("npc"):
		if str(persona.get("id")) == "ercole":
			npc = persona
	if npc != null:
		accetta_rigioco = true
		npc.call("interact")
		attesa = 0
		while _scena() != Router.MINIGAME and attesa < 2400:
			await get_tree().process_frame
			attesa += 1
		verifica(attesa < 2400 and GameState.minigame.get("rigioco", false), "parlare con Ercole avvia il rigioco")
		verifica(GameState.minigame.get("stelle_prima", 0) == 3, "il rigioco usa il record esistente")
	else:
		verifica(false, "Ercole trovato nella sua stanza")
	print("ERCOLE TEST: %d controlli, errori %s" % [controlli, errori])
	get_tree().quit(0 if errori.is_empty() else 1)


func _process(_delta: float) -> void:
	if Ui.busy and Engine.get_process_frames() % 4 == 0:
		if str(Ui.get("_mode")) == "choose":
			Ui.set("_sel", 0 if accetta_rigioco else (Ui.get("_options") as Array).size() - 1)
		Input.parse_input_event(_evento(true))
		Input.parse_input_event(_evento(false))
