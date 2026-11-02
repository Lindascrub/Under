extends Control
## La pagina "Comandi" del menu iniziale (scenes/comandi.tscn): Velo, Riquadro, Titolo, una Riga per comando
## (i Tasto disegnati e Cosa fanno) e Indietro. Si chiude con conferma, indietro o un tocco.

signal chiuso


func _input(event: InputEvent) -> void:
	var touch := event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed
	if touch or event.is_action_pressed("confirm") or event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		Sound.sfx("select")
		chiuso.emit()
