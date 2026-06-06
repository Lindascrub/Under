extends Node2D

@onready var scritta_debito = $CanvasLayer/Label

func _process(_delta):
	scritta_debito.text = "DEBITO: $" + str(int(Global.debito))
