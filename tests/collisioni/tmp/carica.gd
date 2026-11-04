extends Node
func _ready() -> void:
	for p: String in ["res://scenes/chiudi_gioco.gd", "res://autoload/controls.gd"]:
		var s := load(p) as GDScript
		print(p, " ok=", s != null and s.can_instantiate())
	get_tree().quit(0)
