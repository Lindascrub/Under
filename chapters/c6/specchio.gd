extends CanvasLayer
## Lo specchio dell'ascensore (chapters/c6/specchio.tscn): le persone incontrate, una accanto all'altra.
## Robot colorati con l'antenna, persone grigie. Cornice e vetro sono nodi della scena; le persone stanno
## sulla riga del nodo `Persone`, distribuite su tutta la larghezza del vetro.

const C5 := preload("res://chapters/c5/citta_c5.gd")

## Quanto sono grandi le persone nello specchio.
@export var scala_persone := 2.0

@onready var _vetro: Control = $Vetro
@onready var _persone: Node2D = $Persone


func mostra(ids: Array) -> void:
	var n := ids.size()
	for i in n:
		var id: String = ids[i]
		var s := CharSprite.new()
		s.sheet = str(GameState.npc_data(id).get("sheet", "char_02"))
		s.person = id
		s.anim = "idle_down"
		s.grey = not GameState.is_robot(id)
		s.scale = Vector2(scala_persone, scala_persone)
		s.position = Vector2((i + 0.5) * _vetro.size.x / maxi(n, 1), 0)
		_persone.add_child(s)
		if GameState.is_robot(id):
			C5._antenna(s)
