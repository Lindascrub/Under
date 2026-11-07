extends Node

const IDS := ["bulbo", "mina", "tilde", "ercole", "leda", "amir", "olga", "teo", "ada", "nadir"]
var checks := 0
var failures: Array[String] = []
var lines: Array[String] = []
var current: Node = null
var tick := 0
var lit_stars := 0
var running := false

func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		push_error(what)

func _process(_dt: float) -> void:
	if not running: return
	tick += 1
	if is_instance_valid(current):
		var response: Node = current.get_node("Risposta")
		if response.get_node("Stelle").visible:
			var lit := 0
			for i in 3:
				var star: Sprite2D = response.get_node("Stelle/Stella%d" % (i+1))
				if star.texture == response.stella_accesa and star.modulate == Color.WHITE: lit += 1
			lit_stars = maxi(lit_stars, lit)
	if Ui.busy:
		var label: Label = Ui.get("_label")
		if is_instance_valid(label) and not label.text.is_empty() and label.text not in lines:
			lines.append(label.text)
		if tick % 2 == 0:
			if TouchControls.enabled:
				var down := InputEventScreenTouch.new()
				down.position = Vector2(560, 310)
				down.pressed = true
				Input.parse_input_event(down)
				var up := InputEventScreenTouch.new()
				up.position = down.position
				Input.parse_input_event(up)
			else:
				var down := InputEventAction.new()
				down.action = "confirm"
				down.pressed = true
				Input.parse_input_event(down)
				var up := InputEventAction.new()
				up.action = "confirm"
				Input.parse_input_event(up)

func _ready() -> void:
	await get_tree().process_frame
	GameState.save_path = "user://stelle_personaggi_test_20261107.json"
	GameState.player_name = "Prova"
	Ui.velocita_scrittura = 10000
	get_tree().create_timer(180).timeout.connect(func():
		push_error("STELLE PERSONAGGI: timeout")
		get_tree().quit(2))
	for id: String in IDS:
		var npc: Dictionary = GameState.npc_data(id)
		var mg: Dictionary = npc.help.minigame
		check(mg.get("stelle", false), npc.name + ": stelle attive")
		var distinct: Array = []
		for stars in [1, 2, 3]:
			var reply: Array = mg.get("battute_stelle", {}).get(str(stars), [])
			check(not reply.is_empty(), "%s: battuta %d stelle" % [npc.name, stars])
			distinct.append(str(reply))
		check(distinct[0] != distinct[1] and distinct[1] != distinct[2] and distinct[0] != distinct[2], npc.name + ": tre risposte diverse")
		check(not npc.help.get("lose", mg.get("lose", [])).is_empty(), npc.name + ": risposta alla sconfitta")
	check(int(GameState.npc_data("bulbo").help.minigame.misses) > 2, "Mina: vittoria con due errori realmente consentita")
	for tel in [false, true]:
		TouchControls.enabled = tel
		for id: String in IDS:
			for stars in [3, 2, 1, 0]:
				await outcome(id, stars, false, false)
		for id: String in ["bulbo", "mina", "tilde", "ercole"]:
			await outcome(id, 2, true, false)
		await outcome("amir", 0, false, true)
	TouchControls.enabled = false
	print("STELLE PERSONAGGI: %d controlli, errori %s" % [checks, failures])
	get_tree().quit(0 if failures.is_empty() else 1)

func outcome(id: String, stars: int, replay: bool, partial: bool) -> void:
	while Ui.transitioning or Ui.busy: await get_tree().process_frame
	GameState.new_game()
	var npc: Dictionary = GameState.npc_data(id)
	var cfg := Npc.minigame_cfg(id, npc.name, npc.help, Router.MENU, Vector2.ZERO)
	cfg["intro"] = []
	cfg["prima_prova"] = false
	if replay or stars == 0:
		GameState.flags["stelle_" + id] = 3
	if replay:
		cfg["rigioco"] = true
		cfg["stelle_prima"] = 3
	# No world scene or real save is loaded by this result-only integration probe.
	var old: Node = get_tree().current_scene
	if old != self and is_instance_valid(old): old.queue_free()
	GameState.minigame = cfg
	current = load(Router.MINIGAME).instantiate()
	get_tree().root.add_child(current)
	get_tree().current_scene = current
	await get_tree().process_frame
	current.set_process(false)
	if current.visivo != null: current.visivo.set_process(false)
	if id == "ercole": current.get_node("ErcoleGomitata").set_process(false)
	current.phase = "play"
	current.misses = 3 - stars if stars > 0 else 3
	var response: Node = current.get_node("Risposta")
	response.fermo_vittoria = 0.0
	response.durata_stelle = 0.08
	var before: int = GameState.money
	lines.clear()
	lit_stars = 0
	running = true
	current._finish(stars > 0, partial)
	var frames := 0
	while is_instance_valid(current) and frames < 3600:
		await get_tree().process_frame
		frames += 1
	while Ui.transitioning: await get_tree().process_frame
	running = false
	var label := "%s %d stelle %s%s" % [npc.name, stars, "touch" if TouchControls.enabled else "PC", " rigioco" if replay else (" parziale" if partial else "")]
	check(frames < 3600, label + ": ritorno dalla schermata risultato")
	check(lit_stars == stars, label + ": icone coerenti")
	check(int(GameState.flags.get("stelle_" + id, 0)) == (3 if replay or stars == 0 else stars), label + ": record coerente")
	var spoken := " ".join(lines)
	var expected: Array = cfg.get("partial", []) if partial else (cfg.battute_stelle[str(stars)] if stars > 0 else cfg.get("lose", []))
	check(not expected.is_empty() and spoken.contains(GameState.fmt(str(expected[0]))), label + ": battuta realmente mostrata")
	if replay:
		check(spoken.contains(GameState.fmt(str(cfg.rigioca.peggio[0]))), label + ": riconosce il risultato peggiore")
		check(GameState.money == before, label + ": nessun premio duplicato")
	if bool(cfg.get("fixed_reward", false)):
		check(GameState.money == before, label + ": nessun denaro inventato")
	if partial:
		check(GameState.flags.get("c3_amir_aiutato", false) and not GameState.flags.get("c3_amir_bonus", false), label + ": aiuto parziale senza bonus")
	current = null
