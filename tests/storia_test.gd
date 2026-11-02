extends "res://tests/smoke_test.gd"
## Test della storia dalla Banca alla Cima (docs/STORIA_BANCA_CIMA.md): solo le parti nuove, più veloce
## dello smoke test. Usa lo stesso modo di giocare da solo (scelte in choose_queue, minigiochi vinti).
## Esegui:  Godot --headless --path . res://tests/storia_test.tscn
## Alla fine stampa "STORIA TEST OK" oppure gli errori trovati.

const BM := preload("res://scripts/boss_missions.gd")

var _checks := 0


func _check(cond: bool, what: String) -> void:
	_checks += 1
	if OS.has_environment("STORIA_VERBOSE"):
		print("  ", "ok " if cond else "NO ", what)
	super(cond, what)


func _run() -> void:
	await _test_banca()
	await _test_citta()
	if _failures.is_empty():
		print("STORIA TEST OK (%d controlli)" % _checks)
	else:
		print("STORIA TEST FALLITO:\n- " + "\n- ".join(_failures))
	get_tree().quit(0 if _failures.is_empty() else 1)


## La proposta a Olga fatta davvero con la missione del Capo (UN PICCOLO AIUTO).
func _olga_offer(visible: bool, months := 24, apr := 4, fee := 0) -> void:
	var s: Dictionary = BM.state("-2")
	s["status"] = "active"
	s["return"] = Router.BANCA
	var p: Dictionary = BM.progress("-2")
	p["months"] = months
	p["apr"] = apr
	p["fee"] = fee
	p["visible"] = visible
	_check(BM.finish_contract() == "", "la proposta a Olga dovrebbe partire")


func _bank(flags: Array) -> Room:
	GameState.new_game()
	GameState.badges.assign(["-4", "-3", "-2", "0"])
	GameState.flags["c4_arrivo"] = true
	choose_queue = []
	minigame_result = "win"
	for f: String in flags:
		GameState.flags[f] = true
	return await _go(Router.BANCA, "from_below")


func _stairs(m: Room, queue: Array) -> Room:
	choose_queue = queue
	await m.call("on_stairs_step", m.player, "0")
	return await _c4_settle()


func _test_banca() -> void:
	var f := GameState.flags
	var helped := "Non avevi cancellato i debiti. Avevi aiutato qualcuno a non affrontarli da solo."
	var doubt := "Per la prima volta, non eri sicuro di dovere davvero ciò che ti chiedevano."
	var travel := "Avevi una richiesta in viaggio, un indirizzo e nessuna risposta. Era già più di prima."

	# SOLIDALE: reclamo fatto, Teo aiutato, nessuna proposta nascosta; alle scale la verifica
	var m := await _bank(["c4_olga", "c4_olga_contestazione", "c4_teo", "c4_teo_aiutato"])
	m = await _stairs(m, [])
	_check(f.get("c4_anomalia", false) and f.get("c4_verifica", false) and not f.get("c4_riepilogo", false), "solidale: alle scale l'anomalia e la verifica")
	_check(f.get("c4_ricevuta_copia", false) and Storia.richiesta() == "direzione", "solidale: Teo copia la ricevuta; la richiesta va alla Direzione")
	_check(m.call("look_back_line") == travel, "solidale con la richiesta: la frase della richiesta")
	_check(Ui.cutscene == false, "dopo le scale si cammina di nuovo")

	# RIEPILOGO senza terminale della sala: c4_anomalia si accende lo stesso
	m = await _bank([])
	m = await _stairs(m, [0, 0, 1])
	_check(f.get("c4_anomalia", false) and f.get("c4_riepilogo", false) and not f.get("c4_verifica", false), "riepilogo: anomalia accesa anche senza il terminale")
	_check(Storia.richiesta() == "riepilogo" and not f.get("c4_ricevuta_copia", false), "riepilogo: nessuna richiesta, nessuna copia di Teo")
	_check(m.call("look_back_line") == doubt, "solo riepilogo: la frase del dubbio")

	# proposta CHIARA: Olga valuta (conviene / non conviene) e nessun torto
	m = await _bank(["c4_olga"])
	_olga_offer(true, 24, 4, 0)
	_check(Storia.olga_proposta_chiara() and Storia.olga_conviene() and not Storia.olga_torto_aperto(), "proposta chiara a 24 mesi, 4%, senza commissione: a Olga conviene")
	_check(BM.state("-2").get("reward", -1) == 0 and GameState.money == 0, "la proposta chiara non ha premio")
	f["boss_olga_offer"]["fee"] = 60
	_check(not Storia.olga_conviene(), "con la commissione di 60 € non le conviene")
	f["boss_olga_offer"]["fee"] = 0
	f["boss_olga_offer"]["total"] = 140000
	_check(not Storia.olga_conviene(), "con 1.400 € in tutto non le conviene")

	# INGANNO, reclamo prima della proposta, poi corretto alle scale ("La ritiro. Adesso.")
	m = await _bank(["c4_olga", "c4_teo", "c4_teo_aiutato", "c4_olga_doppia"])
	f["c4_olga_contestazione"] = true
	Storia.segna("c4_olga_contestazione")
	_olga_offer(false)
	_check(Storia.olga_ingannata() and Storia.olga_torto_aperto() and GameState.money == 3000, "proposta nascosta: premio del Capo, torto aperto")
	_check(Storia.ordine("c4_olga_contestazione", "c4_olga_proposta") == -1, "il contatore sa che il reclamo è venuto prima")
	m = await _stairs(m, [0, 0, 1, 0])
	_check(f.get("c4_olga_corretta", false) and not Storia.olga_torto_aperto() and GameState.money == 3000, "ritirata alle scale: corretta, il premio non torna indietro")
	_check(f.get("c4_ricevuta_copia", false), "anche con l'inganno Teo fa la copia (completa)")
	var fixed: String = m.call("look_back_line")
	_check(fixed != helped and fixed.contains("piegato"), "corretta: lo sguardo indietro riconosce la correzione senza dimenticare il foglio (%s)" % fixed)
	# salvare e ricaricare conserva scelte e ordine
	GameState.save_game(Router.BANCA, m.player.position)
	var seq := int(f.get("seq", 0))
	GameState.new_game()
	GameState.load_game()
	f = GameState.flags
	_check(f.get("c4_olga_corretta", false) and f.get("c4_riepilogo", false) and int(f.get("seq", 0)) == seq and Storia.ordine("c4_olga_contestazione", "c4_olga_proposta") == -1, "salvare e ricaricare: correzione, riepilogo e ordine restano")
	_check(Storia.olga_ingannata() and not Storia.olga_torto_aperto(), "dopo il caricamento: ingannata ma corretta")

	# INGANNO non corretto ("Non è la stessa cosa."), reclamo dopo la proposta
	m = await _bank(["c4_olga", "c4_teo", "c4_teo_aiutato"])
	f = GameState.flags
	_olga_offer(false)
	f["c4_olga_contestazione"] = true
	Storia.segna("c4_olga_contestazione")
	_check(Storia.ordine("c4_olga_contestazione", "c4_olga_proposta") == 1, "il contatore sa che il reclamo è venuto dopo")
	m = await _stairs(m, [0, 0, 1, 2])
	_check(not f.get("c4_olga_corretta", false) and Storia.olga_torto_aperto(), "'Non è la stessa cosa': il torto resta")
	_check(m.call("look_back_line") == doubt, "inganno non corretto: niente frase dell'aiuto, si passa al riepilogo")
	f["c4_verifica"] = true
	_check(m.call("look_back_line") == travel, "inganno non corretto con la richiesta: la frase della richiesta")
	f.erase("c4_verifica")

	# correzione allo sportello, prima delle scale: poi "L'ho già ritirata."
	m = await _bank(["c4_olga"])
	f = GameState.flags
	_olga_offer(false)
	choose_queue = [0]
	m = await _c4_call(m, "_station", [GameState.job("sportello_banca")])
	_check(f.get("c4_olga_corretta", false) and not GameState.worked_today, "allo sportello si ritira la proposta (e il turno non parte)")
	m = await _stairs(m, [0, 0, 1, 1])
	_check(f.get("c4_olga_ammesso", false) and f.get("c4_olga_corretta", false), "dopo la correzione, 'Avevi ragione a leggerla'")
	var out: Dictionary = {}
	_check(m.call("on_stairs_top", m.player), "in cima alle scale lo sguardo indietro")
	out = GameState.flags.get("chapter_4", {})
	_check(out.get("olga_offer", {}).get("hidden", false) and out["olga_offer"]["corrected"] and out["debt"]["summary_only"], "il riepilogo chapter_4 ricorda proposta, correzione e riepilogo")
	await _wait_scene(m.call("next_scene"), 60000)
	# l'arrivo nella Città finisce da solo: se si cambia scena a metà, resta una cutscene aperta
	await _c5_settle()

	# vecchio salvataggio: nessun numero, nessuna riga d'ordine; nessuna richiesta inventata
	GameState.new_game()
	GameState.flags["boss_olga_offer"] = {"visible": false, "total": 130000, "fee": 0, "months": 24}
	GameState.flags["c4_olga_contestazione"] = true
	_check(Storia.ordine("c4_olga_contestazione", "c4_olga_proposta") == 0 and Storia.richiesta() == "", "vecchio salvataggio: ordine sconosciuto e nessuna richiesta")


func _test_citta() -> void:
	var job := GameState.job("comunicazioni_citta")
	# il centralino: solo con la richiesta di verifica, una volta sola; SEGNALA = la porti a mano
	var m := await _c5_reset()
	choose_queue = [1]
	m = await _c5_call(m, "_station", [job])
	_check(not GameState.flags.has("c5_richiesta") and Storia.richiesta() == "", "senza richiesta il centralino non mostra niente")
	m = await _c5_reset()
	GameState.flags["c4_verifica"] = true
	_check(Storia.richiesta() == "direzione", "la richiesta non ancora smistata va dove l'ha mandata la Banca")
	choose_queue = [2]
	m = await _c5_call(m, "_station", [job])
	_check(Storia.richiesta() == "a_mano" and Storia.richiesta_arrivata() and not GameState.worked_today, "SEGNALA: la richiesta resta a te e la porti a mano")
	choose_queue = [1]
	m = await _c5_call(m, "_station", [job])
	_check(Storia.richiesta() == "a_mano", "il centralino la mostra una volta sola")
	m = await _c5_reset()
	GameState.flags["c4_verifica"] = true
	choose_queue = [0]
	m = await _c5_call(m, "_station", [job])
	_check(Storia.richiesta() == "archivio" and not Storia.richiesta_arrivata(), "CONFERMA: in archivio, non arriva")

	# le offerte: ognuna dal suo dialogo
	m = await _c5_reset()
	var f := GameState.flags
	f["c5_nadir"] = true
	f["c5_nadir_percorso"] = true
	m = await _c5_call(m, "_nadir_after")
	_check(f.get("offerta_nadir", false), "dopo il percorso Nadir offre il turno corto")
	f["c5_rina"] = true
	f["c5_vetrina"] = true
	choose_queue = [0]
	m = await _c5_call(m, "_rina_window")
	_check(f.get("c5_vetrina_aiuto", false) and f.get("offerta_rina", false), "dopo la vetrina Rina offre la brandina")
	f["c3_leda"] = true
	f["c3_leda_ordini"] = true
	choose_queue = [0]
	m = await _c5_call(m, "_leda")
	_check(f.get("c5_leda_collabora", false) and f.get("offerta_leda", false), "Leda negli ordini condivisi offre il lavoro")
	f["c3_amir"] = true
	choose_queue = [1]
	m = await _c5_call(m, "_amir")
	_check(f.get("offerta_amir", false), "Amir umano offre il giro delle consegne")
	_check(Storia.ordine("offerta_nadir", "offerta_amir") == -1, "le offerte hanno il loro numero nell'ordine")
	GameState.save_game(Router.CITY, m.player.position)
	GameState.new_game()
	GameState.load_game()
	f = GameState.flags
	_check(f.get("offerta_rina", false) and f.get("offerta_amir", false) and f.has("offerta_nadir_seq"), "salvare e ricaricare: le offerte restano")
	m = await _c5_reset()
	f = GameState.flags
	f["c3_amir"] = true
	GameState.robots.append("amir")
	m = await _c5_call(m, "_amir")
	_check(not f.get("offerta_amir", false), "Amir robot non offre niente")
	_check(not f.get("offerta_nadir", false) and not f.get("offerta_ada", false), "nessuna offerta senza il suo dialogo")

	# la Casa Comune: Ada e la quota, i bilanci con la nota, la stanza dopo l'assemblea
	m = await _c5_reset()
	f = GameState.flags
	f["c4_anomalia"] = true
	f["c5_ada"] = true
	m = await _go(Router.CASA_COMUNE, "default")
	choose_queue = [3]
	m = await _c5_talk("ada")
	_check(f.get("c5_ada_quota", false), "con l'anomalia della Banca Ada parla della quota")
	choose_queue = [0]
	m = await _c5_call(m, "_bilanci")
	_check(f.get("c5_nota_riscuotere", false), "nei bilanci la nota 'autorizzato a riscuotere'")
	f["c5_assemblea"] = true
	f["c5_ada_stanze"] = true
	f["c5_esito"] = "riconversione"
	m = await _c5_talk("ada")
	_check(not f.get("offerta_ada", false), "se la Casa diventa il centro CHEAP, Ada non ha stanze da offrire")
	f["c5_esito"] = "comunitaria"
	m = await _c5_talk("ada")
	_check(f.get("offerta_ada", false), "dopo l'assemblea Ada offre la stanza")
