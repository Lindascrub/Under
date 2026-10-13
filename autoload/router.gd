extends Node
## Cambia scena con una dissolvenza e ricorda in che punto far comparire il giocatore.
## Spostarsi tra le stanze del mondo fa passare 10 minuti; a mezzanotte si torna a casa per forza.

const MENU := "res://scenes/main_menu.tscn"
const HOME := "res://scenes/world/home.tscn"
const STREET := "res://scenes/world/street.tscn"
const OFFICE := "res://scenes/world/office.tscn"
const BATTLE := "res://scenes/battle/battle.tscn"
const ENDING := "res://scenes/endings/ending.tscn"
const ENDING_CITY := "res://scenes/endings/city_below.tscn"
const WORLD: Array[String] = [HOME, STREET, OFFICE]

## Nome del punto di arrivo nella prossima stanza (vedi Room.spawns).
var spawn := ""


## Se `narration` non è vuota, il testo appare su schermo nero prima della nuova scena.
func goto(path: String, spawn_name: String = "", narration: Array = []) -> void:
	if Ui.transitioning:
		return
	var from := ""
	if get_tree().current_scene:
		from = get_tree().current_scene.scene_file_path
	if path in WORLD and from in WORLD and from != path:
		GameState.spend(GameState.COST_WALK)
	if path in WORLD and GameState.is_midnight() and not GameState.flags.get("forced_sleep", false):
		GameState.flags["forced_sleep"] = true
		path = HOME
		spawn_name = "bed"
		narration = ["È mezzanotte.", "Crolli dal sonno. Ti risvegli a casa, senza ricordare come ci sei arrivato."]
	spawn = spawn_name
	await Ui.fade_out()
	if not narration.is_empty():
		await Ui.narrate(narration)
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await Ui.fade_in()


## Avvia una battaglia. Alla fine si torna a `cfg.return` / `cfg.spawn`.
func battle(cfg: Dictionary) -> void:
	if Ui.transitioning:
		return
	GameState.battle = cfg
	Sound.sfx("encounter")
	Sound.music("")
	goto(BATTLE)
