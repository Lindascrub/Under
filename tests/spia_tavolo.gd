extends "res://chapters/c6/direzione.gd"
var scelta_finale := ""
var intro_chiamate := 0
func _intro() -> void:
	intro_chiamate += 1
func _finish() -> void:
	scelta_finale = choice_id
	phase = "done"
