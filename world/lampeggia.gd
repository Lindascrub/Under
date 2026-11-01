extends CanvasItem
## Fa lampeggiare il nodo: scende fino a `minimo` di opacità e torna su, per sempre.

@export_range(0.0, 1.0, 0.05) var minimo := 0.2
## Secondi per scendere (e altrettanti per tornare su).
@export var durata := 0.5


func _ready() -> void:
	var tw := create_tween().set_loops()
	tw.tween_property(self, "modulate:a", minimo, durata)
	tw.tween_property(self, "modulate:a", 1.0, durata)
