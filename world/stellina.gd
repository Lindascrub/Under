class_name Stellina
extends Node2D
## La stellina del salvataggio (world/stellina.tscn). Il nodo è l'angolo in alto a sinistra della casella.
##   Sprite      la stellina che brilla (fotogrammi e velocità nel suo SpriteFrames)
##   Tocco       il punto da cui la si usa
##   Risveglio   dove ti ritrovi dopo aver salvato o dormito

## La zona intorno a `Tocco` in cui la stellina ha la precedenza sulle cose accanto (la scrivania).
@export var zona_tocco := Rect2(-12, -24, 24, 32)


func setup_in_room(room: Room) -> void:
	room.use_save_point(self)
