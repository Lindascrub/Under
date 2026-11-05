@tool
extends Node2D
@export_enum("Libro", "Attrezzo", "Incontri") var tipo := 0:
	set(v):
		tipo = v
		if is_inside_tree(): _aggiorna()
func _ready() -> void:
	_aggiorna()
func _aggiorna() -> void:
	for i in get_child_count(): get_child(i).visible = i == tipo
