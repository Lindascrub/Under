extends Node
## Prova i fili di Mina e le lampadine di Bulbo con le stelline (temporaneo).
const NPC := preload("res://scripts/npc.gd")
var cur: Node
var foto := false

func _process(_d: float) -> void:
	if Ui.busy and Engine.get_process_frames() % 4 == 0:
		var e := InputEventAction.new(); e.action = "confirm"; e.pressed = true; Input.parse_input_event(e)
		var u := InputEventAction.new(); u.action = "confirm"; u.pressed = false; Input.parse_input_event(u)

func _shot(n: String) -> void:
	if not foto: return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tests/collisioni/tmp/foto_giochi/%s.png" % n)

func _apri(id: String) -> void:
	GameState.new_game()
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/npcs.json"))
	GameState.minigame = NPC.minigame_cfg(id, str(d[id]["name"]), d[id]["help"], Router.FONDO, Vector2.ZERO)
	await get_tree().process_frame
	cur = load(Router.MINIGAME).instantiate(); get_tree().root.add_child(cur); get_tree().current_scene = cur
	var n := 0
	while (str(cur.get("phase")) != "play" or Ui.busy) and n < 3000:
		await get_tree().process_frame; n += 1

func _ready() -> void:
	foto = "--foto" in OS.get_cmdline_user_args()
	TouchControls.enabled = "--touch" in OS.get_cmdline_user_args()
	GameState.save_path = "user://test_c1_giochi.json"
	# fili: un errore, poi tutto giusto
	await _apri("bulbo")
	for i in 20: await get_tree().process_frame
	await _shot("c1_fili_guida")
	cur.set("wire_pick", 0); cur.set("wire_sel", (cur.get("wire_right") as Array).find(1)); cur.call("_wire_connect")
	for r in int(cur.get("cfg").get("rounds", 2)):
		for w in 4:
			cur.set("wire_pick", w); cur.set("wire_sel", (cur.get("wire_right") as Array).find(w)); cur.call("_wire_connect")
			for i in 6: await get_tree().process_frame
			if r == 0 and w == 2: await _shot("c1_fili_fila")
		if r == 0: await _shot("c1_fili_secondo")
	for i in 40: await get_tree().process_frame
	await _shot("c1_fili_stelle")
	var n := 0
	while is_instance_valid(cur) and cur.is_inside_tree() and n < 2000:
		await get_tree().process_frame; n += 1
	print("fili: stelle=", GameState.flags.get("stelle_bulbo", 0), " soldi=", GameState.money, " (atteso 2 stelle: un errore)")
	# lampadine: tutte giuste e svelte (come nel gioco: la scena di prima se ne va)
	if is_instance_valid(get_tree().current_scene) and get_tree().current_scene != cur: get_tree().current_scene.queue_free()
	await _apri("mina")
	for i in 10: await get_tree().process_frame
	await _shot("c1_lampadine_guida")
	for k in int(cur.get("cfg").get("count", 10)):
		var b := str(cur.get("bulb"))
		if b == "fioca": cur.set("bulb", "buona"); b = "buona"
		cur.call("_bulb_answer", true)
		for i in 5: await get_tree().process_frame
		if k == 4: await _shot("c1_lampadine_gioco")
	for i in 50: await get_tree().process_frame
	await _shot("c1_lampadine_stelle")
	n = 0
	while is_instance_valid(cur) and cur.is_inside_tree() and n < 2000:
		await get_tree().process_frame; n += 1
	print("lampadine: stelle=", GameState.flags.get("stelle_mina", 0), " soldi=", GameState.money, " (atteso 3)")
	print("time_scale=", Engine.time_scale)
	get_tree().quit(0)
