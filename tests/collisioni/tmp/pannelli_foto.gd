extends Node
var out := "C:/Users/linda/AppData/Local/Temp/claude/C--Users-linda-Documents-sito-siw-personle/2f16c58e-bb47-4c51-9f96-d6f04090c739/scratchpad/pannelli/"


func _shot(name: String) -> void:
	for i in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + name + ".png")


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	GameState.save_path = "user://pannelli_foto.json"
	GameState.new_game()
	await get_tree().process_frame
	for path: String in ["res://chapters/c5/rivelazione_citta.tscn", "res://chapters/c4/rivelazione_banca.tscn", "res://chapters/c3/scontrino.tscn"]:
		var p := (load(path) as PackedScene).instantiate() as CanvasLayer
		add_child(p)
		if p.has_method("appari"):
			await p.call("appari")
		else:
			p.call("srotola", ["RIGA UNO", "RIGA DUE", "RIGA TRE"])
			await get_tree().create_timer(3.0).timeout
		Ui.say(["Congratulazioni. La città è cresciuta."], "Voce CHEAP")
		await get_tree().create_timer(2.0).timeout
		await _shot(path.get_file().get_basename())
		p.queue_free()
		Ui.emit_signal("_advance")
		await get_tree().create_timer(0.5).timeout
		get_tree().quit(0) if path.ends_with("scontrino.tscn") else null
