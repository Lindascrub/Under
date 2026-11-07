extends "res://scenes/minigame/minigame.gd"
var risultato_test: Array = []
func _finish(success: bool, partial := false) -> void:
	if phase == "done": return
	risultato_test = [success, partial]
	phase = "done"
	if visivo != null: visivo.ferma()
