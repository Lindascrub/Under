extends Node
## Parte dall'ingresso reale e usa movimento e interazione del giocatore.
## Nessun teletrasporto, walk_to() o chiamata diretta a _bilanci().
var controlli := 0
var errori: Array[String] = []
var stanza: Room
var telefono := false
var joystick_premuto := false
var foto := false
var passi := 0

func verifica(ok: bool, nota: String) -> void:
	controlli += 1
	if not ok:
		errori.append(nota)
		push_error(nota)
	print("OK " if ok else "NO ", nota)

func _ready() -> void:
	await get_tree().process_frame
	foto = "--foto" in OS.get_cmdline_user_args()
	GameState.save_path = "user://bilanci_accesso_test.json"
	get_tree().create_timer(120.0).timeout.connect(func():
		push_error("BILANCI ACCESSO: timeout")
		get_tree().quit(124))
	for mobile in [false, true]:
		telefono = mobile
		TouchControls.enabled = mobile
		TouchControls.visible = mobile
		for fase in ["chiuso", "protesta", "assemblea"]:
			await prova(fase)
	TouchControls.enabled = false
	TouchControls.visible = false
	print("BILANCI ACCESSO: %d controlli, errori %s" % [controlli, errori])
	get_tree().quit(errori.size())

func prova(fase: String) -> void:
	GameState.new_game()
	for f in ["c5_arrivo", "c5_casa", "c5_archivio_visto"]: GameState.flags[f] = true
	if fase != "chiuso": GameState.flags["c5_protesta"] = true
	if fase == "assemblea":
		GameState.flags["c5_assemblea"] = true
		GameState.flags["c5_esito"] = "comunitaria"
	Router.spawn = "default"
	stanza = load(Router.CASA_COMUNE).instantiate()
	get_tree().root.add_child(stanza)
	get_tree().current_scene = stanza
	for i in 20: await get_tree().physics_frame
	if stanza.player == null:
		verifica(false, "Giocatore presente nella stanza: " + fase)
		stanza.queue_free()
		await get_tree().process_frame
		return
	verifica(not Ui.blocks_input(), "Comandi liberi: " + fase)
	var terminale: Node2D = stanza.get_node("Mondo/UsaTerminaleBilanci")
	var inizio := stanza.player.global_position
	var strada := percorso(Vector2(280, 88))
	print("PERCORSO ", fase, " ", "TEL" if telefono else "PC", ": ", strada.size(), " punti da ", inizio)
	if fase == "chiuso":
		verifica(stanza.has_node("Mondo/PortaArchivio") and strada.is_empty(), "L'archivio chiuso blocca l'accesso ai bilanci")
	else:
		verifica(not stanza.has_node("Mondo/PortaArchivio"), "La porta è aperta: " + fase)
		verifica(not strada.is_empty(), "Percorso fisico fino al terminale: " + fase)
		if not strada.is_empty():
			var arrivato := await cammina(strada)
			verifica(arrivato and passi > 0, "Raggiunto camminando: " + fase)
			# Ultimo passo verso lo schermo, anche col joystick: orientamento da input reale.
			for i in 3: await get_tree().physics_frame
			muovi(Vector2.UP)
			for i in 3: await get_tree().physics_frame
			muovi(Vector2.ZERO)
			for i in 3: await get_tree().physics_frame
			var bersaglio: Node = stanza.player._find_target()
			print("BERSAGLIO ", bersaglio.name if bersaglio else "nessuno", " piedi ", stanza.player.global_position)
			verifica(bersaglio == terminale, "Il comando seleziona proprio i bilanci: " + fase)
			await immagine(fase + "_davanti")
			if telefono:
				var b: Array = TouchControls.BUTTONS["confirm"]
				tocco(b[0], true, 1)
				await get_tree().process_frame
				tocco(b[0], false, 1)
			else:
				azione("confirm", true)
				await get_tree().process_frame
				azione("confirm", false)
			for i in 6: await get_tree().process_frame
			verifica(GameState.flags.get("c5_rapporto", false) and Ui.busy, "Rapporto aperto con il comando del dispositivo: " + fase)
			await immagine(fase + "_rapporto")
			for i in 500:
				if not Ui.busy: break
				if Ui.get("_mode") == "choose": Ui.set("_sel", 1)
				azione("confirm", true)
				azione("confirm", false)
				await get_tree().process_frame
			verifica(not Ui.busy, "Si chiude il rapporto e si torna a camminare")
	stanza.queue_free()
	get_tree().current_scene = self
	await get_tree().process_frame

func percorso(meta: Vector2) -> PackedVector2Array:
	var p := stanza.player
	var forma: CollisionShape2D = p.get_node("Collisione")
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = forma.shape
	q.exclude = [p.get_rid()]
	q.collision_mask = p.collision_mask
	q.margin = 0.5
	var griglia := AStarGrid2D.new()
	griglia.region = Rect2i(0, 0, 90, 60)
	griglia.cell_size = Vector2(4, 4)
	griglia.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	griglia.update()
	var spazio := p.get_world_2d().direct_space_state
	for x in 90:
		for y in 60:
			q.transform = Transform2D(0, Vector2(x, y) * 4 + forma.position)
			if not spazio.intersect_shape(q, 1).is_empty(): griglia.set_point_solid(Vector2i(x, y))
	var partenza := Vector2i((p.global_position / 4).round())
	var arrivo := Vector2i((meta / 4).round())
	if griglia.is_point_solid(arrivo): return PackedVector2Array()
	return griglia.get_point_path(partenza, arrivo)

func cammina(strada: PackedVector2Array) -> bool:
	passi = 0
	for punto in strada:
		var tentativi := 0
		while stanza.player.global_position.distance_to(punto) > 1.5 and tentativi < 60:
			var d := punto - stanza.player.global_position
			var v := Vector2(signf(d.x) if absf(d.x) > 0.9 else 0.0, signf(d.y) if absf(d.y) > 0.9 else 0.0)
			muovi(v)
			await get_tree().physics_frame
			tentativi += 1
			passi += 1
		if tentativi >= 60:
			print("FERMO: ", stanza.player.global_position, " verso ", punto)
			muovi(Vector2.ZERO)
			return false
	muovi(Vector2.ZERO)
	return true

func muovi(v: Vector2) -> void:
	if telefono:
		if v == Vector2.ZERO:
			if joystick_premuto: tocco(TouchControls.STICK_CENTER, false)
			joystick_premuto = false
		else:
			if not joystick_premuto:
				tocco(TouchControls.STICK_CENTER, true)
				joystick_premuto = true
			var d := InputEventScreenDrag.new()
			d.position = get_viewport().get_screen_transform() * (TouchControls.STICK_CENTER + v.normalized() * TouchControls.STICK_RADIUS)
			Input.parse_input_event(d)
	else:
		for a in ["move_left", "move_right", "move_up", "move_down"]: Input.action_release(a)
		if v.x != 0: Input.action_press("move_right" if v.x > 0 else "move_left")
		if v.y != 0: Input.action_press("move_down" if v.y > 0 else "move_up")

func tocco(pos: Vector2, premuto: bool, dito := 0) -> void:
	var e := InputEventScreenTouch.new()
	e.position = get_viewport().get_screen_transform() * pos
	e.pressed = premuto
	e.index = dito
	Input.parse_input_event(e)

func azione(nome: String, premuta: bool) -> void:
	var e := InputEventAction.new()
	e.action = nome
	e.pressed = premuta
	Input.parse_input_event(e)

func immagine(nome: String) -> void:
	if not foto: return
	if Ui.busy and Ui.get("_typing"):
		Ui.set("_typed", 100000.0)
		for i in 3: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/bilanci_" + nome + ("_tel" if telefono else "_pc") + ".png")
