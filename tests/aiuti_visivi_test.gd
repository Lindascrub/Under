extends Node
var controlli := 0
var errori: Array[String] = []
var esiti: Array = []
var foto := false
const MISSIONI := preload("res://scripts/boss_missions.gd")
func verifica(ok: bool, nota: String) -> void:
	controlli += 1
	if not ok:
		errori.append(nota)
		push_error(nota)
func nuovo(nome: String) -> Node:
	var n: Node = load("res://scenes/minigame/rifatti/" + nome + ".tscn").instantiate()
	add_child(n)
	n.avvia({"misses": 2})
	n.set_process(false)
	n.finito.connect(func(a: bool, b: bool): esiti.append([a, b]))
	esiti.clear()
	return n
func immagine(n: Node, nome: String) -> void:
	if not foto: return
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/visivi_" + nome + ("_tel" if TouchControls.enabled else "_pc") + ".png")
func _ready() -> void:
	foto = "--foto" in OS.get_cmdline_user_args()
	GameState.save_path = "user://aiuti_visivi_test.json"
	GameState.new_game()
	Ui.show_hud(false)
	for tel in [false, true]:
		TouchControls.enabled = tel
		await _prove(tel)
		await _guide()
		await _mandato(tel)
		await _incarichi(tel)
	TouchControls.enabled = false
	print("AIUTI VISIVI: %d controlli, errori %s" % [controlli, errori])
	get_tree().quit(errori.size())
func _prove(tel: bool) -> void:
	var a := nuovo("consegne")
	await immagine(a, "amir")
	a.punta(Vector2(550, 210), 0)
	a.punta(Vector2(550, 137), 1)
	a.punta(Vector2(550, 137), 2)
	if tel: verifica(a.rimasti == a.pacchi and a.corsia == 0, "Amir: scorrere cambia corsia senza lanciare")
	a.queue_free()
	await get_tree().process_frame
	a = nuovo("consegne")
	for p in a.porte:
		a.corsia = a.corsie.find(p.position.y)
		p.position.x = a.get_node("Mira").position.x + a.velocita * a.durata_lancio
		a.lancia()
		await get_tree().create_timer(0.4).timeout
	verifica(a.consegnati == 18 and a.precisi == 18 and a.errori == 0 and esiti == [[true, false]], "Amir: diciotto lanci precisi completano il giro")
	verifica(a.rimasti == a.scorta, "Amir: ogni lancio consuma un pacco")
	a.queue_free()
	await get_tree().process_frame
	a = nuovo("consegne")
	for i in 18:
		if i < 9:
			var p: Node = a.porte[i]
			a.corsia = a.corsie.find(p.position.y)
			p.position.x = a.get_node("Mira").position.x + a.velocita * a.durata_lancio
		a.lancia()
		await get_tree().create_timer(0.4).timeout
	# le porte rimaste passano oltre: il giro finisce
	a._process(60.0)
	verifica(a.consegnati == 9 and esiti == [[false, true]], "Amir: nove pacchi mantengono l'aiuto parziale")
	a.queue_free()
	await get_tree().process_frame
	a = nuovo("consegne")
	for i in a.pacchi:
		a.lancia()
		await get_tree().create_timer(0.4).timeout
	verifica(esiti == [[false, false]], "Amir: lanciare a raffica lontano dalle porte fallisce")
	a.queue_free()
	await get_tree().process_frame
	a = nuovo("consegne")
	var v0: float = a.velocita
	a._process(0.5)
	verifica(a.velocita > v0, "Amir: la strada accelera man mano")
	var b := nuovo("consegne")
	var diverse := false
	for i in a.porte.size():
		if a.porte[i].position.y != b.porte[i].position.y: diverse = true
	verifica(diverse and a.porte.size() == 18, "Amir: diciotto porte, in un ordine diverso a ogni partita")
	b.queue_free()
	esiti.clear()
	a._process(40.0)
	verifica(esiti == [[false, false]], "Amir: senza consegnare non si vince")
	a.queue_free()
	await get_tree().process_frame
	var t := nuovo("pratiche")
	t.pausa_timbro = 0.02
	await immagine(t, "teo")
	verifica(t.get_node("Sinistra/Campi").get_child_count() == 4, "Teo: entrambe le prove sono a schermo")
	for k in [4, 2, 0, 2, 3, 4]:
		t.scegli(k)
		await get_tree().create_timer(0.05).timeout
	verifica(esiti == [[true, false]], "Teo: sei pratiche, comprese due senza anomalie")
	t.queue_free()
	await get_tree().process_frame
	var o := nuovo("commissione")
	var soldi := GameState.money
	verifica(o.doppi == 4 and o.voci[-2][1] == "Commissione gestione ritardo" and o.voci[-3][1] == o.voci[-2][1], "Olga: quattro doppi sul nastro, l'ultimo è la commissione della rata 63")
	# idle: chi non fa niente lascia scappare il primo doppio (errore) e la prova (sconfitta)
	var prime: Array[Control] = []
	for i in 4: prime.append(o.crea_ricevuta())
	o.timbra(prime[0])
	verifica(o.attivo and o.errori == 1 and o.timbrati == 0, "Olga: timbrare una voce giusta è un errore")
	o.timbra(prime[3])
	o.timbra(prime[3])
	verifica(o.timbrati == 1 and o.errori == 1, "Olga: il doppio (03/06, bonifico) si timbra una volta sola")
	for i in 4: prime[i].position.x = 60 + i * 170
	var mira: Vector2 = prime[3].position + prime[3].size / 2
	verifica(o.ricevuta_al_punto(mira) == prime[3], "Olga: clic o dito trovano la ricevuta sotto il punto")
	await immagine(o, "olga")
	# fino alla fine, timbrando solo i doppi: si vince, nessun soldo a chi gioca
	o.set_process(true)
	var giri := 0
	while o.attivo and giri < 20000:
		for r in o.ricevute:
			if r.get_meta("doppia") and not r.get_meta("timbrata") and r.position.x < 400: o.timbra(r)
		await get_tree().process_frame
		giri += 1
	verifica(esiti == [[true, false]] and o.prova_trovata and o.errori == 1 and GameState.money == soldi, "Olga: prova trovata, un errore (2 stelle), nessun rimborso anticipato")
	o.queue_free()
	await get_tree().process_frame
	# la prova che scappa fa perdere subito
	o = nuovo("commissione")
	o.prossima = o.voci.size() - 2
	var prova: Control = o.crea_ricevuta()
	prova.position.x = 30
	o.set_process(true)
	await get_tree().process_frame
	await get_tree().process_frame
	verifica(esiti == [[false, false]], "Olga: se la commissione doppia finisce in archivio si perde")
	o.queue_free()
	await get_tree().process_frame
	var v := nuovo("volantini")
	var esempio: Node = v.crea_persona()
	esempio.position.x = 380
	await immagine(v, "ada")
	esempio.queue_free()
	v.persone.clear()
	v.generati = 0
	var utili := 0
	for i in 24:
		var p: Node = v.crea_persona()
		if p.get_meta("disponibile"): utili += 1
	verifica(utili >= 8, "Ada: la generazione garantisce abbastanza persone interessate")
	var destinatario: Node = v.persone[0]
	destinatario.position.x = 320
	v.consegna(destinatario, 1)
	verifica(v.errori == 1 and v.dati == 0, "Ada: il volantino deve corrispondere all'interesse")
	v.consegna(destinatario, 0)
	await get_tree().create_timer(0.3).timeout
	verifica(v.dati == 1 and destinatario.get_node("Foglio").visible, "Ada: il foglio passa alla persona che lo legge")
	v.consegna(destinatario, 0)
	verifica(v.dati == 1, "Ada: nessun doppio conteggio")
	GameState.flags["c5_esito"] = "riconversione"
	verifica(not v._casa_aperta(), "Ada: la Casa in riconversione non riceve i passanti")
	GameState.flags.erase("c5_esito")
	v.queue_free()
	await get_tree().process_frame
	var e: Node = load("res://scenes/minigame/ercole_gomitata.tscn").instantiate()
	add_child(e)
	e.set_process(false)
	e.prova_libera = true
	e.avvia()
	e.passo(20.0)
	verifica(e.attivo and e.errori == 0, "Ercole: il sonno è fermo nella prima prova")
	e.premi()
	e.passo(2.0)
	verifica(e.attivo and e.errori == 0, "Ercole: sovraccaricare la prima prova non punisce")
	e.premi()
	e.passo(0.6)
	e.lascia()
	verifica(not e.prova_libera and e.riuscite == 1 and e.errori == 0, "Ercole: il primo rilascio utile conclude la guida")
	e.queue_free()
	await get_tree().process_frame

func _guida(tipo: String) -> Node:
	GameState.new_game()
	GameState.minigame = {"type": tipo, "prima_prova": true, "intro": [], "id": "guida_test"}
	var n: Node = load("res://scenes/minigame/minigame.tscn").instantiate()
	add_child(n)
	n.set_process(false)
	await get_tree().process_frame
	return n
func _guide() -> void:
	var n: Node = await _guida("sequence")
	verifica(n.seq == ["up", "down"] and n.seq_rosse == [false, true], "Tilde: un segno valido e una X nell'esempio")
	n.phase = "play"
	var ev := InputEventAction.new()
	ev.action = "move_down"; ev.pressed = true
	n._unhandled_input(ev)
	verifica(n.misses == 0 and n.prima_prova, "Tilde: sbagliare l'esempio non conta errori")
	n.phase = "play"
	ev.action = "move_up"
	n._unhandled_input(ev)
	verifica(not n.prima_prova and n.round_n == 1, "Tilde: dopo il primo gesto parte la partita")
	n.queue_free()
	await get_tree().process_frame

	n = await _guida("inventory")
	var tempo: float = n.time_left
	n._process(10.0)
	var giusto := int(n.inv_queue[0][1])
	n._inv_place((giusto + 1) % 4)
	verifica(n.time_left == tempo and n.misses == 0, "Leda: prima scatola senza tempo o penalità")
	n._inv_place(giusto)
	verifica(not n.prima_prova and n.inv_done == 1, "Leda: la prima scatola viene sistemata davvero")
	n.queue_free()
	await get_tree().process_frame
	n = await _guida("coincidenze")
	tempo = n.time_left
	n._process(10.0)
	n._cz_miss("Prova")
	verifica(n.time_left == tempo and n.misses == 0 and n.prima_prova, "Nadir: prima tratta senza tempo o penalità")
	for i in n._cz_rides().size():
		var corsa: Dictionary = n._cz_rides()[i]
		if int(corsa["da"]) == 0 and str(corsa.get("stato", "")) not in ["badge", "soppressa"]:
			n._cz_act("c%d" % i)
			if not n.prima_prova: break
	verifica(not n.prima_prova and not n.cz_path.is_empty(), "Nadir: il primo tratto valido conclude la guida")
	n.queue_free()
	await get_tree().process_frame

func _mandato(tel: bool) -> void:
	var risposta := [-1]
	(func(): risposta[0] = await Ui.choose_described("Chi paga e chi decide?", [
		["Mantieni le tutele", "Rispetti i minimi per stipendi e servizi. Nessuna tariffa aggiunta ai lavoratori."],
		["Tariffe ai lavoratori", "Le riserve ricevono 5 unità. A pagarle sono i lavoratori."],
		["Firma unica", "Sposti 5 dai servizi alle riserve. Decidi senza i rappresentanti."],
		["Decisione condivisa", "I rappresentanti partecipano prima dell'applicazione. Coordinarsi costa 5 unità."]])).call()
	await get_tree().process_frame
	await immagine(Ui, "mandato")
	if tel:
		var pos: Vector2 = Ui.get("_described").get_node("Righe").get_child(3).get_global_rect().get_center()
		var ev := InputEventScreenTouch.new()
		ev.position = pos; ev.pressed = true
		Ui._touch(ev)
	else:
		for azione in ["move_down", "move_down", "move_down", "confirm"]:
			var ev := InputEventAction.new()
			ev.action = azione; ev.pressed = true
			Input.parse_input_event(ev)
			await get_tree().process_frame
			ev = InputEventAction.new(); ev.action = azione
			Input.parse_input_event(ev)
	verifica(risposta[0] == 3 and not Ui.busy, "Direzione: descrizioni leggibili e scelta coerente con il dispositivo")

func _incarichi(_tel: bool) -> void:
	for caso in [["-4", "capo_documenti"], ["-3", "capo_cartellino"], ["-2", "capo_contratto"], ["0", "capo_notiziario"]]:
		var n: Node = load("res://scenes/minigame/rifatti/" + caso[1] + ".tscn").instantiate()
		add_child(n)
		var p := MISSIONI.defaults(caso[0])
		match caso[0]:
			"-4": p["document"] = 1
			"-3": p["round"] = 2; p["units"] = 2; p["visible"] = false
			"-2": p["visible"] = false
			"0":
				MISSIONI.record_quote("rina", "Rina", "L'avevo appena riparata.", "La vetrina è rotta. Non si è visto chi è stato; Rina non ha chiesto di chiudere la Casa.", 20)
				p["cut"] = true
		n.aggiorna(p, "")
		await immagine(n, caso[1])
		match caso[0]:
			"-4": verifica(n.get_node("Documento/Contenuto").text.contains("E-27"), "Capo: il registro mancante appartiene a E-27")
			"-3": verifica(n.get_node("Cartellino/Condizioni").text == "Condizioni al terminale." and n.get_node("Cassa/Totale").text.contains(MISSIONI.cash(int(MISSIONI.market_preview(p)["basket"]))), "Capo: condizioni nascoste, totale effettivo visibile alla cassa")
			"-2": verifica(n.get_node("Olga/Copertura").visible and n.get_node("Interno/Dati").text.contains("TOTALE"), "Capo: il giocatore legge ciò che nasconde a Olga")
			"0": verifica(n.get_node("Intera/Testo").text.contains("CONTESTO") and n.get_node("Televisore/Testo").text.contains("CONTESTO ESCLUSO"), "Capo: il montaggio non cancella la registrazione originale")
		n.queue_free()
		await get_tree().process_frame
