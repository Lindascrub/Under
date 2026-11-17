extends Node
## Verifica isolata dei minigiochi ridisegnati, senza caricare le mappe dei capitoli.
## Esegui: Godot --headless --path . res://tests/minigame_redesign_test.tscn

var checks := 0
var failures: Array[String] = []


func _ready() -> void:
	GameState.save_path = "user://test_minigame_redesign.json"
	GameState.new_game()
	_test_teo()
	# il Capo al -4 non ha più i vassoi: è capo_documenti, provato da boss_fascicoli_test
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


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)
