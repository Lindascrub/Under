extends Node
var out := "C:/Users/linda/AppData/Local/Temp/claude/C--Users-linda-Documents-sito-siw-personle/2f16c58e-bb47-4c51-9f96-d6f04090c739/scratchpad/capo/"
func _shot(name: String) -> void:
	for i in 30: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + name + ".png")
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	await get_tree().process_frame
	GameState.save_path = "user://capo_foto.json"
	GameState.new_game()
	for f: String in ["-3", "0", "-5"]:
		GameState.minigame = {"boss_floor": f}
		var m := (load("res://scenes/minigame/boss_mission.tscn") as PackedScene).instantiate()
		get_tree().root.add_child(m)
		await _shot("schermo_" + f)
		m.set("finishing", true)
		m.queue_redraw()
		Ui.say(["* INCARICO ARCHIVIATO: prova di una frase lunga per vedere se il testo si legge bene sopra lo schermo."], "Notiziario CHEAP")
		await _shot("dialogo_" + f)
		get_tree().root.remove_child(m); m.queue_free()
		Ui.call("_close") if Ui.has_method("_close") else null
	get_tree().quit(0)
