class_name Examine
extends Interactable
## Un punto da esaminare messo nell'editor. Scrivi le frasi in `lines` (Inspector):
## premendo il tasto vicino al punto, compaiono nel riquadro. Oppure, in `method`,
## il nome di una funzione della stanza da chiamare (per le interazioni speciali).

@export var lines: PackedStringArray = []
## Frasi diverse dopo un evento (per esempio "c1_rivelazione": dopo che la festa si è spenta).
@export var lines_after: PackedStringArray = []
@export var after_flag := ""
@export var speaker := ""
@export var method := ""


func setup_in_room(room: Room) -> void:
	if method != "" and room.has_method(method):
		action = Callable(room, method)
	elif not lines.is_empty():
		action = func() -> void:
			var use := lines
			if after_flag != "" and not lines_after.is_empty() and GameState.flags.get(after_flag, false):
				use = lines_after
			await Ui.say(Array(use), speaker)
