extends Node
func _ready() -> void:
	var w := Node.new()
	w.set_script(load("res://tests/_shot_worker.gd"))
	get_tree().root.call_deferred("add_child", w)
