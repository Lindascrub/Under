extends "res://scenes/minigame/boss_mission.gd"
var completato := false
func _finish() -> void:
	finishing = true
	completato = true
