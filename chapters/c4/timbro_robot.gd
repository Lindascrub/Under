extends Sprite2D
## Il timbro di Teo robot (chapters/c4/timbro_robot.tscn): batte sempre allo stesso ritmo.
## La posizione del nodo è quella da fermo (in basso).

## Di quanti pixel si alza, in quanti secondi sale e scende, e quanto aspetta fra un colpo e l'altro.
@export var alzata := 6.0
@export var salita := 0.25
@export var colpo := 0.08
@export var pausa := 0.4


func _ready() -> void:
	var giu := position.y
	var tw := create_tween().set_loops()
	tw.tween_property(self, "position:y", giu - alzata, salita)
	tw.tween_property(self, "position:y", giu, colpo)
	tw.tween_interval(pausa)
