extends Node
func _ready() -> void:
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	for i in 10: await get_tree().process_frame
	menu.call("_ask_name")
	await get_tree().process_frame
	var edit := menu.get_node("SceltaNome/Campo") as LineEdit
	for t in ["l", "li", "linda", "èlia", "3mario"]:
		edit.text = t
		edit.caret_column = t.length()
		edit.text_changed.emit(t)
		print(t, " -> ", edit.text, "  risposta: ", (menu.get_node("SceltaNome/Risposta") as Label).text.left(30))
	print("capital vuoto: '", GameState.capital(""), "'")
	get_tree().quit(0)
