@tool
class_name Interactable
extends Node2D
## Un punto della mappa con cui il giocatore interagisce premendo Z (letto, computer, porta...).

var action: Callable
## Lato da cui si usa il punto: ZERO = tutti, DOWN = davanti a uno sportello.
@export var approach := Vector2.ZERO
## Area visibile relativa al nodo: permette di toccare anche il fianco di un mobile.
@export var interaction_bounds := Rect2()
@export var reach := 14.0
@export var facing_required := ""


func _ready() -> void:
	add_to_group("interactable")


func hotspot() -> Vector2:
	return global_position


func interaction_point(probe: Vector2) -> Vector2:
	if interaction_bounds.has_area():
		var r := Rect2(global_position + interaction_bounds.position, interaction_bounds.size)
		var edge := probe.clamp(r.position, r.end)
		return edge if edge.distance_to(probe) < hotspot().distance_to(probe) else hotspot()
	return hotspot()


func interact() -> void:
	if action.is_valid():
		action.call()
