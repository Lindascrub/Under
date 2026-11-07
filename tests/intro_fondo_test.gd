extends "res://tests/smoke_test.gd"
## La nuova apertura di Linda: cucina, ascensore, arrivo al Fondo e primo dialogo con Fermo.
var letti: Array[String] = []


func _process(delta: float) -> void:
	for key: String in ["_label", "_narr", "_choice_label"]:
		var label: Label = Ui.get(key)
		if Ui.busy and is_instance_valid(label) and label.text not in letti:
			letti.append(label.text)
	super(delta)


func _letto(frase: String) -> bool:
	for testo in letti:
		if frase in testo:
			return true
	return false


func _run() -> void:
	GameState.save_path = "user://test_intro_linda.json"
	_legacy_new_game()
	GameState.player_name = "LUCA"
	Router.goto(Router.ELEVATOR)
	await _wait_scene(Router.FONDO, 60000)
	await _idle()
	var guardia := 0
	while (Ui.cutscene or Ui.busy or Ui.transitioning) and guardia < 12000:
		await get_tree().process_frame
		guardia += 1
	_check(guardia < 12000, "arrivo al Fondo terminato")
	var fondo := get_tree().current_scene
	await fondo.call("_talk_fermo")
	_check(_letto("Mi dispiace"), "biglietto di papà presente")
	_check(_letto("Si presenti alla CHEAP"), "lettera presente")
	_check(_letto("Tristezza, forse"), "nuova descrizione dell'ascensore")
	_check(_letto("Acuta, contentissima"), "voce registrata chiara")
	_check(_letto("Alla fine premi l’allarme"), "allarme ascensore")
	_check(_letto("fin troppo abbaglianti"), "le porte danno sulle luci")
	_check(_letto("Piacere, io sono LUCA"), "nome scelto dal giocatore (detto da lui, di lato)")
	_check(_letto("Io ho iniziato con nove. Ora ne devo undici."), "nuovo debito di Fermo")
	_check(_letto("Quanto ti hanno messo di debito?"), "domanda sul debito chiara")
	_check(_letto("Quelli non saltano mai un turno"), "interessi spiegati da Fermo")
	_check(_letto("Il prezzo te lo dice lei"), "prezzo affidato a Nives")
	_check(_letto("Se ti perdi, almeno me mi ritrovi."), "ultima battuta nuova")
	_check(_letto("CHEAP srl."), "titolo prima dell'ascensore")
	_check(_letto("Salva e lascia passare la notte"), "tutorial: scelta esatta per passare al giorno dopo")
	_check(_letto("Lo vende Nives, vicino alle scale"), "tutorial: badge e scale spiegati")
	_check(_letto("Mina, quella ai fili") and _letto("Bulbo, quello alle lampadine"), "identità corrette dei personaggi")
	_check(not _letto("ne dovevo quattro") and not _letto("con un nastrino") and not _letto("Come un dente"), "vecchie battute eliminate")
	_check(GameState.flags.get("fermo_talked", false) and GameState.flags.get("met_fermo", false), "Fermo conosciuto e tutorial concluso")
	_check(GameState.debt == GameState.START_DEBT and GameState.money == 0, "l'apertura non cambia i conti")
	print("INTRO FONDO TEST OK" if _failures.is_empty() else "INTRO FONDO TEST: " + str(_failures))
	get_tree().quit(0 if _failures.is_empty() else 1)
