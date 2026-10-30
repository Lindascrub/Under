@tool
class_name StairsUp
extends Node2D
## Le scale per il piano di sopra, con il tornello del badge (scena world/stairs_up.tscn).
## Scalini, tornello, fiancate, sbarra e frase sono nodi veri: si vedono e si spostano
## nell'editor. Il nodo sta nell'angolo in alto a sinistra del primo gradino (in basso a
## sinistra delle scale); mettilo a caselle (snap 16).
## Va nel livello "Decori": gli scalini e il tornello stanno a terra, chi ci passa si vede sopra.

@export_file("*.tscn") var target := ""
@export var spawn := "from_below"
## Il badge che serve per passare il tornello (es. "-4").
@export var need := ""

const T := 16


func cell() -> Vector2i:
	return Vector2i(int(round(position.x / T)), int(round(position.y / T)))


## Il gioco la trova da sola: la stanza collega tornello, scritte e cambio di piano.
func setup_in_room(room: Room) -> void:
	room.use_stairs_up(self)
