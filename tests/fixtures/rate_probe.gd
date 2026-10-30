extends "res://scenes/minigame/minigame.gd"

func _finish(success: bool, _partial := false) -> void:
	won=success
	phase="probe_done"
	queue_redraw()
