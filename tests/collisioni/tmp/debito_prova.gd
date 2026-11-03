extends Node


func _ready() -> void:
	GameState.save_path = "user://debito_prova.json"
	GameState.new_game()
	await get_tree().process_frame
	var hud := Ui.get("_hud_debito") as Label
	print("prima: ", hud.text, " | debito vero ", GameState.debt)
	for n in 3:
		GameState.spend(GameState.MIDNIGHT - GameState.minutes)
		await get_tree().process_frame
		print("notte ", n + 1, ": ", hud.text, " colore ", hud.get_theme_color("font_color"), " | debito vero ", GameState.debt, " | ", GameState.pending_lines.back())
	Ui.show_hud(true)
	GameState.money = 12650
	GameState.changed.emit()
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("C:/Users/linda/AppData/Local/Temp/claude/C--Users-linda-Documents-sito-siw-personle/2f16c58e-bb47-4c51-9f96-d6f04090c739/scratchpad/hud_rosso.png")
	await get_tree().create_timer(6.5).timeout
	print("dopo 6,5 secondi: ", hud.text, " colore ", hud.get_theme_color("font_color"))
	get_tree().quit(0)
