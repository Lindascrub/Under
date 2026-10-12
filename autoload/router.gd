extends Node
## Cambia scena con una dissolvenza e ricorda in che punto far comparire il giocatore.

const MENU := "res://scenes/main_menu.tscn"
const HOME := "res://scenes/world/home.tscn"
const STREET := "res://scenes/world/street.tscn"
const OFFICE := "res://scenes/world/office.tscn"
const WAREHOUSE := "res://scenes/minigames/warehouse.tscn"
const DELIVERY := "res://scenes/minigames/delivery.tscn"
const ENDING := "res://scenes/endings/ending.tscn"

## Nome del punto di arrivo nella prossima stanza (vedi Room.spawns).
var spawn := ""


## Se `narration` non è vuota, il testo appare su schermo nero prima della nuova scena.
func goto(path: String, spawn_name: String = "", narration: Array = []) -> void:
	if Ui.transitioning:
		return
	spawn = spawn_name
	await Ui.fade_out()
	if not narration.is_empty():
		await Ui.narrate(narration)
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await Ui.fade_in()
