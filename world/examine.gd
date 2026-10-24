class_name Examine
extends Interactable
## Un punto da esaminare messo nell'editor. Scrivi le frasi in `lines` (Inspector):
## premendo il tasto vicino al punto, compaiono nel riquadro. Oppure, in `method`,
## il nome di una funzione della stanza da chiamare (per le interazioni speciali).

@export var lines: PackedStringArray = []
@export var speaker := ""
@export var method := ""


func setup_in_room(room: Room) -> void:
	if method != "" and room.has_method(method):
		action = Callable(room, method)
	elif not lines.is_empty():
		action = func() -> void: await Ui.say(Array(lines), speaker)
