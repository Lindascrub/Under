extends Node
## Gioca la fine: dalla salita alla Cima fino ai titoli, piano piano, con una foto per ogni battuta.
var out := "C:/Users/linda/AppData/Local/Temp/claude/C--Users-linda-Documents-sito-siw-personle/2f16c58e-bb47-4c51-9f96-d6f04090c739/scratchpad/fine/"
const PASSO := 100  # frame per battuta: il tempo di leggere
var frame := 0
var wait := 0
var shot := 0
var queue: Array = [0, 1]
var last_opts := ""
var same := 0
var plan := [
	{"alloc": {"stipendi": 45, "servizi": 20, "manutenzione": 25, "riserve": 10}},
	{"alloc": {"stipendi": 45, "servizi": 20, "manutenzione": 25, "riserve": 10}, "choice": "risorse"},
	{"alloc": {"stipendi": 45, "servizi": 20, "manutenzione": 25, "riserve": 10}, "choice": "revisione"},
]
var step := "salita"
var busy_call := false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	GameState.save_path = "user://gioca_fine.json"
	var placeholder := Node.new()
	get_tree().root.add_child.call_deferred(placeholder)
	await get_tree().process_frame
	get_tree().current_scene = placeholder
	GameState.new_game()
	for f in ["c1_arrivo", "c1_intro", "c2_arrivo", "c3_arrivo", "c4_arrivo", "c5_arrivo", "c5_casa"]:
		GameState.flags[f] = true
	GameState.badges.assign(["-4", "-3", "-2", "0", "cima"])
	for id: String in ["leda", "amir", "olga", "teo", "ada", "nadir", "rina"]:
		GameState.flags["met_" + id] = true
		GameState.helped_ids.append(id)
	for f: String in ["c3_leda_ordini", "c5_nadir_rete", "c5_assemblea", "c5_vetrina_aiuto", "c5_amir_consegne", "c4_anomalia",
			"c4_olga_doppia", "c5_documento", "c4_teo_sogno", "c3_amir_sogno", "c5_ada_stanze", "c4_olga_contestazione"]:
		GameState.flags[f] = true
	GameState.flags["c5_esito"] = "comunitaria"
	Router.goto(Router.CIMA, "from_below")


func _tap(action: String) -> void:
	for p in [true, false]:
		var e := InputEventAction.new()
		e.action = action
		e.pressed = p
		Input.parse_input_event(e)


func _photo() -> void:
	shot += 1
	var n := shot
	var s := step
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "%03d_%s.png" % [n, s])


func _process(_d: float) -> void:
	frame += 1
	GameState.energy = GameState.MAX_ENERGY
	var scene := get_tree().current_scene
	if scene == null or Ui.transitioning:
		return
	var path := scene.scene_file_path
	if path == Router.DIREZIONE and not Ui.busy:
		wait += 1
		if wait < PASSO:
			return
		wait = 0
		step = "direzione"
		_photo()
		var cycle := int(scene.get("cycle"))
		var p: Dictionary = plan[clampi(cycle - 1, 0, 2)]
		match str(scene.get("phase")):
			"alloc":
				scene.set("alloc", (p["alloc"] as Dictionary).duplicate())
				scene.queue_redraw()
				scene.call("_confirm")
			"casa", "debiti":
				var opts: Array = scene.get("options")
				var pick := 0
				for i in opts.size():
					if str(opts[i][0]) == str(p.get("choice", "")):
						pick = i
				scene.call("_pick", pick)
		return
	if path == Router.FINALE:
		scene.set("fast", false)
	if Ui.busy:
		wait += 1
		if wait < PASSO:
			return
		wait = 0
		_photo()
		if Ui.get("_mode") == "choose":
			var opts := str(Ui.get("_options"))
			same = same + 1 if opts == last_opts else 0
			last_opts = opts
			var n := (Ui.get("_options") as Array).size()
			var idx: int = queue.pop_front() if not queue.is_empty() else (same % n)
			Ui.set("_sel", mini(idx, n - 1))
		_tap("confirm")
		return
	if path == Router.MENU:
		print("FINE: tornati al menu dopo %d battute" % shot)
		get_tree().quit(0)
		return
	if path != Router.CIMA or Ui.cutscene or busy_call:
		return
	wait += 1
	if wait < 60:
		return
	wait = 0
	_next(scene as Room)


func _next(room: Room) -> void:
	var logic: Dictionary = room.call("c6")
	busy_call = true
	if not logic["president"]["offer_received"]:
		step = "presidente"
		await _walk(room, "Scrivania")
		await room.call("talk_president")
	elif int(room.call("cycles_done")) < 3:
		step = "turno"
		await _walk(room, "Scrivania")
		await room.call("_scrivania")
	elif not logic["boss"]["final_call_seen"]:
		step = "capo"
		await room.call("_boss_scene")
	elif room.call("final_ready"):
		step = "finale"
		queue = [2, 0, 0, 0, 0]
		await _walk(room, "Tavolo")
		await room.call("final_choice")
	busy_call = false


## Il protagonista va vicino a un posto (Posti/Posto<nome>), così si vede chi parla con chi.
func _walk(room: Room, nm: String) -> void:
	var m := room.get_node_or_null("Posti/Posto" + nm) as Node2D
	if m and room.player:
		room.player.global_position = m.global_position + Vector2(0, 28)
	await get_tree().process_frame
