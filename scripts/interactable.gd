class_name Interactable
extends Node2D
## Un punto della mappa con cui il giocatore interagisce premendo Z (letto, computer, porta...).

var action: Callable


func _ready() -> void:
	add_to_group("interactable")


func hotspot() -> Vector2:
	return global_position


func interact() -> void:
	if action.is_valid():
		action.call()
