extends Node
func _ready() -> void:
	for p: String in ["res://chapters/c6/direzione.gd", "res://chapters/c6/direzione_regole.gd", "res://chapters/c6/cima_c6.gd", "res://autoload/ui.gd", "res://tests/smoke_test.gd", "res://tests/touch_test.gd", "res://tests/boss_integration_test.gd"]:
		var s := load(p) as GDScript
		print(p, " ok=", s != null and s.can_instantiate())
	get_tree().quit(0)
