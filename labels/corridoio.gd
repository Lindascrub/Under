extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_entra_ufficio_body_entered(body: Node2D) -> void:
	print("Il sensore ha sentito qualcosa: ", body.name)
	
	# Controlliamo se è un CharacterBody2D (il tuo giocatore)
	if body is CharacterBody2D:
		print("Giocatore confermato! Tento il cambio scena verso l'ufficio...")
		
		# Controlliamo entrambi i percorsi possibili per non rischiare!
		if ResourceLoader.exists("res://ufficioTrovaLavoro.tscn"):
			get_tree().change_scene_to_file("res://ufficioTrovaLavoro.tscn")
		elif ResourceLoader.exists("res://labels/ufficioTrovaLavoro.tscn"):
			get_tree().change_scene_to_file("res://labels/ufficioTrovaLavoro.tscn")
		else:
			print("ERRORE: Il file ufficioTrovaLavoro.tscn non esiste in nessuna delle due cartelle!")
	pass # Replace with function body.
