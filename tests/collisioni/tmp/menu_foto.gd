extends Node
var out := "C:/Users/linda/AppData/Local/Temp/claude/C--Users-linda-Documents-sito-siw-personle/2f16c58e-bb47-4c51-9f96-d6f04090c739/scratchpad/menu/"


func _shot(name: String) -> void:
	for i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + name + ".png")


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	await get_tree().process_frame
	GameState.save_path = "user://menu_foto.json"
	var menu := (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(menu)
	get_tree().current_scene = menu
	await _shot("menu")
	print("voci: ", menu.get("_options"))
	Ui.show_page(Ui.COMANDI_TELEFONO)
	await _shot("comandi_telefono")
	get_tree().quit(0)
