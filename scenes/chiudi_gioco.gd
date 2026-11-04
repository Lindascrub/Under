extends CanvasLayer
## ESC chiude il gioco (scenes/chiudi_gioco.tscn, la aggiunge Controls): la prima volta compare
## Avviso, se ESC arriva di nuovo entro `tempo` secondi il gioco si chiude. Un ESC per sbaglio non
## fa perdere niente. Sul telefono non c'è ESC: non succede niente.

## Quanti secondi resta l'avviso (e quanto c'è per il secondo ESC).
@export var tempo := 2.0

@onready var _avviso: Control = $Avviso
var _resta := 0.0


func _ready() -> void:
	_avviso.visible = false


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("quit"):
		return
	get_viewport().set_input_as_handled()
	if _resta > 0.0:
		get_tree().quit()
		return
	_resta = tempo
	_avviso.visible = true
	Sound.sfx("blip")


func _process(delta: float) -> void:
	if _resta > 0.0:
		_resta -= delta
		if _resta <= 0.0:
			_avviso.visible = false
