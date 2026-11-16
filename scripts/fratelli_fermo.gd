class_name FratelliFermo
extends RefCounted
## Sottotrama facoltativa. Fuori dall'elenco degli aiuti: non cambia stelle, legami o finali.
const DATA := "res://data/fratelli_fermo.json"
const KEY := "fratelli_fermo"
static var _data: Dictionary = {}

static func data() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	return _data

static func state() -> Dictionary:
	if not GameState.flags.get(KEY, {}) is Dictionary: GameState.flags.erase(KEY)
	if not GameState.flags.has(KEY): GameState.flags[KEY] = {}
	return GameState.flags[KEY]

static func has_message() -> bool:
	# La vecchia battuta sul sosia conta già come messaggio nei salvataggi precedenti.
	return bool(state().get("message", false)) or bool(GameState.flags.get("fermo_badge_line", false))

static func delivered() -> bool:
	return bool(state().get("delivered", false))

static func reunited() -> bool:
	return bool(state().get("reunited", false))

static func pending_visit() -> bool:
	if GameState.flags.get("c1_sbarrato", false): return false
	return delivered() and not bool(state().get("robot_visit_seen" if GameState.is_robot("fermo") else "reunited", false))

static func say(key: String) -> void:
	for block: Dictionary in data().dialoghi[key]:
		var who := str(block.get("speaker", ""))
		if who == "player": who = GameState.player_name
		var portrait := str(data().sheet) if who in ["Fermo", str(data().speaker)] else ""
		await Ui.say(block.lines, who, portrait)

static func give_message() -> void:
	await say("messaggio")
	state()["message"] = true
	GameState.flags["fermo_badge_line"] = true
	GameState.changed.emit()

static func talk_brother(room: Room, actor: Node2D) -> void:
	if Ui.blocks_input(): return
	var previous := Ui.cutscene
	Ui.cutscene = true
	actor.face_player()
	if str(actor.place) == "fondo":
		if GameState.is_robot("fermo"):
			await say("robot_attesa")
		elif reunited():
			var count := int(state().get("visits", 0))
			await say("insieme" if count % 2 == 0 else "insieme_altro")
			state()["visits"] = count + 1
		else:
			await say("attesa_fondo")
		Ui.cutscene = previous
		return
	var saved := await FocusShot.begin(room, room.get_node("Inquadrature/FratelloFermo"))
	if delivered():
		await say("scale_chiuse")
		await say("attesa_scale_chiuse")
		await FocusShot.restore(room, saved)
		Ui.cutscene = previous
		return
	if not bool(state().get("met", false)):
		if GameState.flags.get("fermo_talked", false) or has_message():
			await say("riconosciuto")
		else:
			await say("sconosciuto")
		state()["met"] = true
	if has_message():
		var choice: Dictionary = data().scelte.messaggio
		var answer: int = await Ui.choose(str(choice.prompt), choice.options, str(data().speaker))
		if answer == 0:
			await say("consegna")
			state()["delivered"] = true
			# Fa davvero la strada fino alle scale. Ricaricando durante il cammino è già partito.
			actor.busy = true
			var closed: bool = GameState.flags.get("c1_sbarrato", false)
			var goal: Vector2 = room.get_node("Punti/FratelloScale").global_position
			var path := room.walk_path(actor.global_position, goal, [actor.body.get_rid()])
			await actor.walk(path)
			actor.busy = false
			GameState.changed.emit()
		else:
			await say("rimandato")
	else:
		await say("senza_messaggio")
	await FocusShot.restore(room, saved)
	Ui.cutscene = previous

## Solo le scene della sottotrama precedono le normali risposte di Fermo.
static func talk_fermo(room: Room) -> bool:
	if pending_visit():
		await reunion(room)
		return true
	if not GameState.is_robot("fermo") and bool(state().get("met", false)) \
			and not has_message() and bool(GameState.flags.get("fermo_talked", false)):
		await give_message()
		return true
	return false

static func reunion(room: Room) -> void:
	var actor: Node2D = room.get_node("Mondo/FratelloFermo")
	var previous := Ui.cutscene
	Ui.cutscene = true
	actor.busy = true
	var saved := await FocusShot.begin(room, room.get_node("Inquadrature/FratelliFermo"))
	if not GameState.is_robot("fermo") and not bool(state().get("answer", false)):
		await say("risposta")
		state()["answer"] = true
	await say("arrivo")
	# La camera accompagna la camminata, poi torna a inquadrare entrambi sulla cassetta.
	var camera := room.player.camera
	var seat: Vector2 = room.get_node("Punti/FratelloSeduto").global_position
	var path := room.walk_path(actor.global_position, seat, [actor.body.get_rid()])
	# Se il giocatore sta proprio sul posto, si usa il punto libero più vicino.
	if (path.is_empty() and actor.global_position.distance_to(seat) > 12) or (not path.is_empty() and path[-1].distance_to(seat) > 12):
		actor.busy = false
		await FocusShot.restore(room, saved)
		Ui.cutscene = previous
		return
	await actor.walk(path, camera)
	actor.seat_position = actor.position
	actor.sit()
	await FocusShot.begin(room, room.get_node("Inquadrature/FratelliFermo"))
	await say("robot_visita" if GameState.is_robot("fermo") else "seduto")
	state()["robot_visit_seen" if GameState.is_robot("fermo") else "reunited"] = true
	actor.busy = false
	GameState.changed.emit()
	await FocusShot.restore(room, saved)
	Ui.cutscene = previous

## Il messaggio può chiudersi anche se il giocatore prosegue senza tornare al Fondo.
static func epilogue(scene: Node) -> void:
	if not delivered(): return
	if GameState.flags.get("c1_sbarrato", false) and not reunited():
		scene._clear()
		scene._floor_strip(Color("26283e"))
		var stairs: Node2D = load("res://chapters/c2/scale_chiuse.tscn").instantiate()
		stairs.position = Vector2(225, 215)
		stairs.scale = Vector2(3, 3)
		scene.stage.add_child(stairs)
		scene._actor(str(data().sheet), 420, false, false, "idle_left")
		await say("epilogo_scale_chiuse")
		state()["closed_epilogue_seen"] = true
		GameState.changed.emit()
		return
	var old_reunion := reunited()
	var old_robot_visit := bool(state().get("robot_visit_seen", false))
	scene._clear()
	var crate := Sprite2D.new()
	crate.texture = load("res://assets/limezu/street/box_trash.png")
	crate.centered = false
	crate.offset = Vector2(0, -16)
	crate.position = Vector2(303, 231)
	crate.scale = Vector2(3, 3)
	scene.stage.add_child(crate)
	var fermo: CharSprite = scene._actor(str(data().sheet), 330, true, GameState.is_robot("fermo"), "sit_left", "fermo")
	fermo.nudge = Vector2(-3, -6)
	var brother: CharSprite = scene._actor(str(data().sheet), 90 if not old_reunion and not old_robot_visit else 270, false)
	brother.modulate = Color("e3d4bd")
	if not old_reunion and not old_robot_visit:
		await say("epilogo_arrivo")
		brother.anim = "walk_right"
		var walk: Tween = scene.create_tween()
		walk.tween_property(brother, "position:x", 270.0, 1.6 if not scene.fast else 0.03)
		await walk.finished
	brother.anim = "sit_right"
	brother.nudge = Vector2(0, 6)
	if GameState.is_robot("fermo"):
		await say("epilogo_robot" if old_robot_visit else "robot_visita")
		state()["robot_visit_seen"] = true
	else:
		await say("epilogo_insieme" if old_reunion else "seduto")
		state()["reunited"] = true
	GameState.changed.emit()
