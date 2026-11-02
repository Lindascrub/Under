class_name Strisce
extends Node2D
## Le strisce pedonali sulla strada: i due pezzi LimeZu (Pezzo1, Pezzo2) e la Zona (Area2D).
## Se sei nella zona, le macchine che arrivano si fermano prima delle strisce e aspettano che passi.

## Quanto sono larghe le strisce, da sinistra (il punto del nodo) a destra.
@export var larghezza := 32.0
## A quanti pixel dalle strisce si ferma il muso della macchina.
@export var distanza_stop := 6.0

var occupata := false


func _ready() -> void:
	add_to_group("strisce")
	var zona := $Zona as Area2D
	zona.body_entered.connect(func(b: Node2D) -> void:
		if b is Player:
			occupata = true
	)
	zona.body_exited.connect(func(b: Node2D) -> void:
		if b is Player:
			occupata = false
	)
