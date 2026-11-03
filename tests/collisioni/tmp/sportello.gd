extends Node
func _ready() -> void:
	GameState.new_game(); GameState.floor_id = "0"
	var r = load(Router.CITY).instantiate()
	get_tree().root.add_child.call_deferred(r)
	for i in 30: await get_tree().process_frame
	var b = r._badge_booth
	print("booth ", b.global_position)
	for x in [8, 30, 56]:
		r.player.global_position = b.global_position + Vector2(x, 12)
		r.player.face("up")
		await get_tree().physics_frame
		var t = r.player._find_target()
		print(x, " -> ", t.get_path() if t else "null", " ", t.global_position if t else "")
	get_tree().quit(0)
