extends Node
## Cambia scena con una dissolvenza e ricorda in che punto far comparire il giocatore.
## Spostarsi tra le stanze del mondo fa passare 10 minuti; a mezzanotte si torna a casa per forza.

const MENU := "res://scenes/main_menu.tscn"
const HOME := "res://scenes/world/home.tscn"
const STREET := "res://scenes/world/street.tscn"
const OFFICE := "res://scenes/world/office.tscn"
const PARK := "res://scenes/world/park.tscn"
const SHELTER := "res://scenes/world/shelter.tscn"
const BOSS := "res://scenes/world/boss_office.tscn"
const PRESIDENCY := "res://scenes/world/presidency.tscn"
const FALL := "res://scenes/world/fall.tscn"
const SOTTOUFFICIO := "res://chapters/c2/sottoufficio.tscn"
const MERCATO := "res://scenes/world/mercato.tscn"
const BANCA := "res://scenes/world/banca.tscn"
const ELEVATOR := "res://scenes/world/elevator_intro.tscn"
const FONDO := "res://chapters/c1/fondo.tscn"
const MINIGAME := "res://scenes/minigame/minigame.tscn"
const WORK := "res://scenes/minigame/work.tscn"
const BATTLE := "res://scenes/battle/battle.tscn"
const ENDING := "res://scenes/endings/ending.tscn"
const ENDING_CITY := "res://scenes/endings/city_below.tscn"
const WORLD: Array[String] = [HOME, STREET, OFFICE, PARK, SHELTER, BOSS, PRESIDENCY, SOTTOUFFICIO, MERCATO, BANCA, FONDO]

## Nome del punto di arrivo nella prossima stanza (vedi Room.spawns).
var spawn := ""
## Posizione esatta in cui ricomparire (salvataggi), se spawn è "_save".
var save_pos := Vector2.INF


## Se `narration` non è vuota, il testo appare su schermo nero prima della nuova scena.
func goto(path: String, spawn_name: String = "", narration: Array = []) -> void:
	if Ui.transitioning:
		return
	var from := ""
	if get_tree().current_scene:
		from = get_tree().current_scene.scene_file_path
	if path in WORLD and from in WORLD and from != path:
		GameState.spend(GameState.COST_WALK)
		Sound.sfx("door")
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


## Un minigioco "a sorpresa" quando aiuti qualcuno. Alla fine si torna dove si era.
func minigame(cfg: Dictionary) -> void:
	if Ui.transitioning:
		return
	GameState.minigame = cfg
	goto(MINIGAME)


## Riprende la partita salvata dal punto esatto in cui si era.
func continue_game() -> void:
	var where := GameState.load_game()
	if where.is_empty():
		return
	save_pos = where["pos"]
	goto(str(where["room"]), "_save" if save_pos != Vector2.INF else "bed", ["{floor}, ore {clock}."])
