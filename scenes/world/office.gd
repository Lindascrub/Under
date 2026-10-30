extends EditorRoom
## Il piano terra della torre CHEAP. La botola scende alla Banca (-2), l'ascensore sale alla
## Direzione (con il badge della Cima), la porta esce in città. Qui lavorano Dario e Giulia.
## La scena (office.tscn) si sistema nell'editor: scrivanie, piante, terminale, ascensore ("Ascensore"),
## sportello ("SportelloBadge") e scale ("ScaleGiu") si spostano a mano. Qui c'è solo la logica.


func setup() -> void:
	_elevator()
	add_exit(Rect2i(9, 11, 2, 1), Router.STREET, "office")
	spawn_people("office")


func enter() -> void:
	if not GameState.flags.get("office_intro", false) and not GameState.is_robot("giulia"):
		GameState.flags["office_intro"] = true
		await Ui.say([
			"...Sei salito dalla Banca? Da sotto? Non ci credo. Nessuno sale da sotto.",
			"Io sono Giulia. Qui è il piano terra: luce vera, finestre vere. Là fuori c'è la città.",
			"L'ascensore va solo in su, alla Direzione. Serve il badge della Cima, e costa come un rene.",
			"Il capo, intanto, ti telefonerà. Ti offre le promozioni. Sembrano regali. ...Non sono regali. Ma non te l'ho detto io.",
		], "Giulia")
	await show_pending()


## Il terminale del piano terra rimanda al collocamento, al piano -4. Dopo il turno
## propone gli straordinari.
func _terminal() -> void:
	if GameState.worked_today:
		await _overtime()
		return
	await Ui.say([
		"* Sul terminale lampeggia un avviso: \"Il COLLOCAMENTO è al piano -4.\"",
		"* \"Per chi viene dal piano terra: scendere è facile. È salire che costa.\"",
	], "Terminale")


var _lift: Lift
var _lift_cell := Vector2i(12, 1)
var _lift_open := false


## L'ascensore del piano terra (il nodo "Ascensore" della scena): guasto (luci spente, porte chiuse)
## finché non hai il badge della Cima; poi la freccia si accende, le porte si aprono e restano aperte,
## e basta entrarci per salire.
func _elevator() -> void:
	_lift = world.get_node_or_null("Ascensore") as Lift
	if _lift == null:
		_lift = Lift.new()
		_lift.position = Vector2(_lift_cell * T)
		world.add_child(_lift)
		add_spot(cell_center(_lift_cell + Vector2i(1, 2)) - Vector2(8, 0), _ride_elevator)
	_lift_cell = Vector2i((_lift.position / T).round())
	_lift.set_off(not GameState.has_badge("cima"))


## Le porte si aprono e resta aperto: chi ci entra sale alla Cima.
func _open_elevator(animate := true) -> void:
	if _lift_open:
		return
	_lift_open = true
	Sound.sfx("door", 1.2)
	_lift.open(animate)


var _riding := false


## Avvicinandoti (col badge della Cima) le porte si aprono; arrivato davanti, entri e sali.
func _process(delta: float) -> void:
	super(delta)
	if player == null or _riding or Ui.blocks_input() or not GameState.has_badge("cima"):
		return
	var door := Vector2(_lift_cell.x * T + T, (_lift_cell.y + 2) * T + 8)
	var d := player.position.distance_to(door)
	if d < 44 and not _lift_open:
		_open_elevator()
	elif d < 14 and _lift_open:
		_riding = true
		_ride_up(player)


func _ride_up(p: Player) -> void:
	Ui.cutscene = true
	p.z_index = 2
	await p.climb(Vector2(_lift_cell.x * T + T, (_lift_cell.y + 2) * T - 2), "up", true)
	Sound.sfx("ding")
	Ui.cutscene = false
	Router.goto(Router.BOSS, "elevator", ["Le porte si chiudono. L'ascensore sale.", "1. 10. 30. 50.", "Più sale, più l'aria sa di profumo e di nessuno."])


func _ride_elevator() -> void:
	if not GameState.has_badge("cima"):
		Sound.sfx("deny")
		await Ui.say(["* L'ascensore. Sulla porta, un foglio scritto a mano: \"GUASTO\".",
			"* Sotto, più in piccolo: \"Verrà riparato quando servirà a qualcuno di importante\"."])
		return
	var c: int = await Ui.choose("L'ascensore funziona. C'è un solo pulsante: SU.", ["Ultimo piano: la Cima", "Resta qui"])
	if c != 0:
		return
	Router.goto(Router.BOSS, "elevator")


## Straordinari: soldi in cambio del poco tempo che ti resta.
func _overtime() -> void:
	if GameState.flags.get("overtime_day", 0) == GameState.day or not GameState.has_time(120):
		await Ui.say(["* Il turno di oggi è chiuso. Torna a casa a riposare."], "Terminale")
		return
	var c: int = await Ui.choose("Il turno è finito. Vuoi fare due ore di straordinari? (+80 €)", ["Straordinari (2 ore)", "Vai a casa"], "Terminale")
	if c != 0:
		return
	GameState.flags["overtime_day"] = GameState.day
	GameState.spend(120)
	GameState.money += 80
	GameState.hurt(3)
	Sound.sfx("coin")
	await Ui.say([
		"* Resti in ufficio. Fuori fa buio. Dario è ancora lì, col suo contatore.",
		"* +80 €. Le tue due ore libere sono diventate soldi. Non tornano indietro.",
	])
