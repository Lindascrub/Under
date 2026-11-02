class_name Traffico
extends Node2D
## Le macchine che passano sulla strada. Ogni Marker2D figlio è una corsia: la sua y è dove stanno
## le ruote, il metadato "verso" è 1 (vanno a destra) o -1 (vanno a sinistra).
## Le macchine si fermano davanti a te (e suonano) e prima delle strisce se ci sei sopra (Strisce).

@export var macchine_per_corsia := 2
## Da dove a dove corrono (fuori dallo schermo, così entrano ed escono).
@export var da_x := -660.0
@export var a_x := 1120.0
## Quanto occupa una macchina sulla strada (bassa: così non tocca il marciapiede).
@export var ingombro := Vector2(56, 14)


func _ready() -> void:
	for lane in get_children():
		if not lane is Marker2D:
			continue
		for i in macchine_per_corsia:
			var car := Car.new()
			car.direction = float(lane.get_meta("verso", 1))
			car.min_x = da_x
			car.max_x = a_x
			car.body_size = ingombro
			car.position = Vector2(randf_range(da_x, a_x), (lane as Marker2D).position.y)
			add_child(car)
