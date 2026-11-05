extends "res://tests/smoke_test.gd"
## Varianti narrative approvate del Fondo. --foto=<cartella> salva anche le schermate col renderer.
const B := preload("res://scripts/boss_missions.gd")
var controlli := 0
var letti: Array[String] = []
var foto := ""
var sezione := ""
var scattate: Dictionary = {}
var scatto_in_corso := false


func _check(ok: bool, messaggio: String) -> void:
	controlli += 1
	super(ok, messaggio)


func _process(_delta: float) -> void:
	_frame += 1
	if scatto_in_corso:
		return
	if foto != "" and get_tree().current_scene:
		var card := get_tree().current_scene.get_node_or_null("SguardoIndietro") as SguardoIndietro
		if card and card.get_node("Frase").modulate.a >= 0.99:
			var frase: Label = card.get_node("Frase")
			var chiave := sezione + "|" + frase.text
			if not scattate.has(chiave):
				scattate[chiave] = true
				scatto_in_corso = true
				_check(frase.get_line_count() * frase.get_line_height() <= frase.size.y, "frase conclusiva dentro la striscia")
				await _scatta("%03d_%s" % [scattate.size(), sezione])
				scatto_in_corso = false
				return
	var label: Label = Ui.get("_label")
	if Ui.busy and is_instance_valid(label):
		if label.text not in letti:
			letti.append(label.text)
		var key := sezione + "|" + label.text
		if foto != "" and label.visible_ratio >= 1.0 and not scattate.has(key):
			scattate[key] = true
			scatto_in_corso = true
			await _scatta("%03d_%s" % [scattate.size(), sezione])
			scatto_in_corso = false
			return
	if Ui.busy and _frame % 3 == 0:
		if str(Ui.get("_mode")) == "choose":
			var indice: int = choose_queue.pop_front() if not choose_queue.is_empty() else choose_index
			Ui.set("_sel", indice)
		_tap("confirm")


func _scatta(nome: String) -> void:
	if foto == "" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(foto.path_join(nome + ".png"))


func _nuova() -> void:
	GameState.new_game()
	GameState.flags["c1_arrivo"] = true
	GameState.flags["c2_arrivo"] = true
	letti.clear()
	choose_index = 1


func _letto(testo: String) -> bool:
	return str(letti).contains(testo)


func _incarico(ritmo: int, extra: int, decori: int) -> void:
	var s := B.state("-5")
	s["status"] = "active"
	s["return"] = Router.FONDO
	s["return_pos"] = [200, 120]
	B.progress("-5").merge({"intensity": ritmo, "extra": extra, "decor": decori}, true)
	_check(B.finish_energy() == "", "incarico confermato con parametri validi")


func _run() -> void:
	GameState.save_path = "user://test_c1_secondo_giro.json"
	MemoriaNives.forget()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--foto="):
			foto = arg.trim_prefix("--foto=")
	if foto != "":
		DirAccess.make_dir_recursive_absolute(foto)
	for tel in [false, true]:
		_nuova()
		TouchControls.enabled = tel
		var modo := "tel" if tel else "pc"
		sezione = modo + "_nives_fondo"
		var fondo := await _go(Router.FONDO)
		await fondo.call("_badge_machine")
		_check(_letto("Per salire serve il badge del piano di sopra"), "Nives spiega il badge al Fondo")
		_check(_letto("Per quella dopo."), "resta la battuta del prezzo")
		_check(not _letto("Stessa faccia") and not _letto("Siamo tutte uguali"), "non anticipa il doppione al primo sportello")
		_check(not GameState.has_badge("-4") and GameState.money == 0, "rifiutare l'acquisto non cambia badge e soldi")
		letti.clear()
		sezione = modo + "_nives_secondo_piano"
		var ufficio := await _go(Router.SOTTOUFFICIO)
		await ufficio.call("_badge_machine")
		_check(_letto("Stessa faccia, prezzi diversi"), "riconosci il doppione anche prima di avere il B-4")
		letti.clear()
		await ufficio.call("_badge_machine")
		_check(not _letto("Stessa faccia"), "il commento non si ripete")

		_nuova()
		sezione = modo + "_nives_regalo"
		fondo = await _go(Router.FONDO)
		GameState.helped_ids.assign(GameState.floor_people("-5"))
		var soldi := GameState.money
		var autostima := GameState.self_esteem
		await fondo.call("_floor_gift")
		_check(_letto("Questo lo pago io") and _letto("salutarmi anche senza comprare"), "il regalo ha il dialogo approvato")
		_check(GameState.has_badge("-4") and GameState.flags.get("clerk_friend", false), "regalo e amicizia restano")
		_check(GameState.money == soldi and GameState.self_esteem == autostima + 3, "conti del regalo invariati")
		letti.clear()
		sezione = modo + "_nives_dopo_regalo"
		ufficio = await _go(Router.SOTTOUFFICIO)
		await ufficio.call("_badge_machine")
		_check(_letto("Stessa faccia"), "doppione riconosciuto anche se il primo badge era regalato")

		_nuova()
		sezione = modo + "_telefonata"
		fondo = await _go(Router.FONDO)
		await B.offer(fondo)
		_check(_letto("Le chiedo solo di regolare una leva") and _letto("seicento euro per lei"), "telefonata parla della leva e del premio")
		_check(B.active("-5") and GameState.money == 0, "rimandare il lavoro non accredita un premio")
		if foto != "":
			B.launch(fondo, "-5")
			await _wait_scene(B.SCENE)
			await _scatta(modo + "_leva")
			get_tree().current_scene.call("_dinamo_esci")
			await _wait_scene(Router.FONDO)
			fondo = get_tree().current_scene

		_nuova()
		_incarico(2, 10, 1)
		_check(GameState.money == 600, "premio per i minuti in più invariato")
		_check(str(fondo.call("_look_back_line")).contains("La sua pausa no"), "chiusura ricorda la pausa sottratta")
		GameState.helped_ids.assign(GameState.floor_people("-5"))
		GameState.flags["c1_extra"] = 3
		_check(str(fondo.call("_look_back_line")).contains("La sua pausa no"), "aiuti e straordinari non nascondono il torto")
		choose_index = 0
		sezione = modo + "_riparazione"
		await Storia.offer_repair("fermo", "Fermo")
		_check(Storia.riparato("fermo"), "riparazione tramite la scelta reale")
		_check(str(fondo.call("_look_back_line")).contains("Prima gli hai chiesto"), "chiusura riconosce torto e riparazione")
		GameState.flags["c1_sbarrato"] = true
		_check(str(fondo.call("_look_back_line")).contains("Non ti sei voltato"), "scale sbarrate hanno ancora priorità")

		_nuova()
		_incarico(3, 0, 2)
		_check(str(fondo.call("_look_back_line")).contains("riprendendo fiato"), "ritmo alto senza extra ha una riga diversa")
		_nuova()
		_incarico(2, 0, 0)
		_check(GameState.money == 0 and not Storia.torto("fermo"), "ritmo normale non dà premio né torto")
		_check(str(fondo.call("_look_back_line")).contains("cassetta"), "incarico senza torto usa la chiusura normale")
		_nuova()
		GameState.flags["boss_fermo_extra"] = 10
		_check(str(fondo.call("_look_back_line")).contains("cassetta"), "dati incompleti non inventano un incarico concluso")
		B.state("-5")["status"] = "legacy"
		_check(str(fondo.call("_look_back_line")).contains("cassetta"), "incarico vecchio non usa le nuove righe")
		GameState.robots.append("fermo")
		GameState.flags["c1_sbarrato"] = true
		_check(str(fondo.call("_look_back_line")).contains("quaderno"), "Fermo robot conserva la priorità e il ricordo del vecchio quaderno")

		_nuova()
		sezione = modo + "_bulbo"
		var bulbo := GameState.npc_data("mina")
		await Ui.say(bulbo["help"]["minigame"]["battute_stelle"]["1"], "Bulbo")
		await Ui.say(bulbo["help"]["yes"], "Bulbo")
		sezione = modo + "_rivelazione"
		GameState.flags["fermo_talked"] = true
		await fondo.call("_revelation")
		await fondo.call("_talk_fermo")
		if foto != "":
			for scelta in [[2, 10, 1, false], [3, 0, 2, false], [2, 10, 1, true]]:
				_nuova()
				_incarico(scelta[0], scelta[1], scelta[2])
				GameState.flags["riparato_fermo"] = scelta[3]
				GameState.flags["c1_rivelazione"] = true
				sezione = modo + "_chiusura_%d_%s" % [scelta[0], scelta[3]]
				fondo = await _go(Router.FONDO)
				await fondo.call("_look_back", fondo.player)
				await _wait_scene(Router.SOTTOUFFICIO)
	print("C1 SECONDO GIRO: %d controlli, errori %s" % [controlli, _failures])
	get_tree().quit(0 if _failures.is_empty() else 1)
