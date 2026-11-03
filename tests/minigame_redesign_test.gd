extends Node
## Verifica isolata dei minigiochi ridisegnati, senza caricare le mappe dei capitoli.
## Esegui: Godot --headless --path . res://tests/minigame_redesign_test.tscn

var checks := 0
var failures: Array[String] = []


func _ready() -> void:
	GameState.save_path = "user://test_minigame_redesign.json"
	GameState.new_game()
	_test_teo()
	_test_boss_trays()
	print("MINIGAME REDESIGN: %d verifiche, errori %s" % [checks, str(failures)])
	get_tree().quit(failures.size())


func _test_teo() -> void:
	var game: Node = load("res://scenes/minigame/minigame.gd").new()
	var practices: Array = GameState.bank["teo"]["pratiche"]
	var expected := [-1, 2, 0, 2, 3, -1]
	for i in practices.size():
		check(game.call("_pr_correct", practices[i]) == expected[i], "Teo: riga corretta pratica %s" % practices[i]["id"])
	game.set("pr_i", 0)
	check(game.call("_pr_target_count") == 5, "Teo: quattro righe più NESSUNA ANOMALIA")
	var row: Rect2 = game.call("_pr_row", 0)
	var none: Rect2 = game.call("_pr_none_button")
	check(not row.intersects(none), "Teo: le righe non coprono il pulsante finale")
	game.free()


func _test_boss_trays() -> void:
	var game: Node = load("res://scenes/minigame/boss_mission.gd").new()
	game.set("floor", "-4")
	game.set("selected", 0)
	_press(game, "move_right")
	check(int(game.get("selected")) == 1, "Capo: destra segue la riga superiore")
	_press(game, "move_down")
	check(int(game.get("selected")) == 3, "Capo: giù segue la colonna")
	_press(game, "move_down")
	check(int(game.get("selected")) == 4, "Capo: giù raggiunge SALVA ED ESCI")
	_press(game, "move_up")
	check(int(game.get("selected")) == 2, "Capo: su rientra nella scrivania")
	game.free()


func _press(game: Node, action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	game.call("_unhandled_input", event)


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)
