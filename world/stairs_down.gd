@tool
class_name StairsDown
extends Node2D
## Le scale per il piano di sotto, viste dall'alto (scena world/stairs_down.tscn).
## Scalini, ombra e bordi sono nodi veri: si vedono e si spostano nell'editor. Il nodo sta
## nell'angolo in alto a sinistra della casella in basso a sinistra; mettilo a caselle (snap 16).
## Va nel livello "Decori": gli scalini stanno a terra.

@export_file("*.tscn") var target := ""
@export var spawn := "from_above"

const T := 16


func cell() -> Vector2i:
	return Vector2i(int(round(position.x / T)), int(round(position.y / T)))


func setup_in_room(room: Room) -> void:
	room.use_stairs_down(self)
