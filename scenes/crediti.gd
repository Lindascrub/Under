extends "res://scenes/comandi.gd"
## La pagina "Crediti" del menu iniziale (scenes/crediti.tscn): Velo, Riquadro, Titolo, Colonna1, Colonna2 e
## Indietro. Il testo delle colonne viene da data/crediti.json (Crediti.testo). Si chiude come i Comandi.


func _ready() -> void:
	($Colonna1 as Label).text = Crediti.testo(1)
	($Colonna2 as Label).text = Crediti.testo(2)
