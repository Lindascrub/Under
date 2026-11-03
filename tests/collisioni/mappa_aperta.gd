class_name MappaAperta
extends RefCounted
## Apre una stanza come la apre il gioco (con gli arrivi dei capitoli già visti) e la chiude.

static func apri(host: Node, path: String) -> Room:
	GameState.new_game()
	for flag in ["c1_arrivo", "c1_intro", "c2_arrivo", "c3_arrivo", "c4_arrivo", "c5_arrivo", "c5_casa", "c6_arrivo"]:
		GameState.flags[flag] = true
	Router.spawn = "from_casa" if path == Router.CITY else "default"
	var room := load(path).instantiate() as Room
	if room == null:
		return null
	host.get_tree().root.add_child(room)
	host.get_tree().current_scene = room
	for i in 1800:
		await host.get_tree().process_frame
		if i > 60 and not Ui.blocks_input():
			break
	if room.player:
		room.player.set_physics_process(false)
	for i in 2:
		await host.get_tree().physics_frame
	return room


static func chiudi(host: Node, room: Room) -> void:
	host.get_tree().current_scene = host
	room.queue_free()
	Ui.cutscene = false
	Ui.transitioning = false
	for i in 5:
		await host.get_tree().process_frame


## Le battute che compaiono entrando si saltano da sole.
static func salta_dialoghi(frame: int) -> void:
	if Ui.busy and frame % 2 == 0:
		if Ui.get("_mode") == "choose":
			Ui.set("_sel", 0)
		var e := InputEventAction.new()
		e.action = "confirm"
		e.pressed = true
		Input.parse_input_event(e)
		e = InputEventAction.new()
		e.action = "confirm"
		Input.parse_input_event(e)
