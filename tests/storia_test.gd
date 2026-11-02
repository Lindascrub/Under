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
	await _test_cima()
	await _test_finali()
	await _test_riparazioni()
	await _test_scene_finali()
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


func _test_cima() -> void:
	var cima: GDScript = load("res://chapters/c6/cima_c6.gd")
	# 6.02: le quattro versioni della richiesta
	var casi := {"direzione": true, "a_mano": true, "archivio": true, "riepilogo": false}
	for r: String in casi:
		_c6_reset()
		var f := GameState.flags
		if r == "riepilogo":
			f["c4_riepilogo"] = true
		else:
			f["c4_verifica"] = true
			f["c5_richiesta"] = r
		_check(Storia.richiesta() == r and cima.verification_done() == casi[r], "Cima: richiesta '%s' (verifica fatta: %s)" % [r, casi[r]])
	GameState.flags["c4_verifica"] = true
	GameState.flags["c5_richiesta"] = "archivio"
	GameState.flags["c4_ricevuta_copia"] = true
	_check(cima.verification_done(), "Cima: in archivio, con la copia di Teo la verifica è fatta lo stesso")
	_c6_reset()
	GameState.flags["c4_verifica"] = true
	_check(Storia.richiesta() == "direzione", "Cima: richiesta fatta in Banca ma centralino mai visto: è andata alla Direzione")
	_c6_reset()
	_check(Storia.richiesta() == "" and not cima.verification_done(), "Cima: vecchio salvataggio, nessuna richiesta inventata")

	# la contestazione: una scelta separata, una volta sola, e solo prima della decisione finale
	_c6_reset()
	var m: Room = await _go(Router.CIMA, "desk")
	m = await _c6_settle()
	choose_queue = [1]
	m = await _c6_call(m, "_contest_choice")
	_check(not GameState.flags.get("c6_contestazione", false), "Cima: 'Non adesso' non contesta")
	choose_queue = [0]
	m = await _c6_call(m, "_contest_choice")
	_check(GameState.flags.get("c6_contestazione", false) and GameState.flags.has("c6_contestazione_seq"), "Cima: contestazione registrata, col suo numero")
	_check(FINALI_.facts()["contested"] and not FINALI_.facts()["kept_by_choice"], "Cima: i fatti del finale vedono la contestazione")
	GameState.save_game(Router.CIMA)
	GameState.new_game()
	GameState.load_game()
	_check(GameState.flags.get("c6_contestazione", false), "Cima: la contestazione resta dopo un caricamento")


const FINALI_ := preload("res://chapters/c6/finali.gd")
const ENDING := preload("res://chapters/c6/finale_c6.gd")
const RULES_ := preload("res://chapters/c6/direzione_regole.gd")


## Un finale di prova, senza scena: solo le funzioni che scelgono le righe.
func _ending(family: String, variant: String, debt := "registrato") -> Node2D:
	var e: Node2D = ENDING.new()
	var c6: Dictionary = load("res://chapters/c6/cima_c6.gd").c6()
	e.set("d", c6)
	e.set("out", {"family": family, "variant": variant, "debt_status": debt})
	e.set("sm", FINALI_.effective_summary(family, variant))
	return e


func _offer(id: String) -> void:
	GameState.flags["met_" + id] = true
	GameState.flags["offerta_" + id] = true
	Storia.segna("offerta_" + id)


func _test_finali() -> void:
	var base := {"exploited": 0, "robots": 0, "bonds": 0, "betrayed": 0, "networks": 0, "evidence": 0, "power": false, "roles_filled": 0,
		"policy": {"wages_up": false, "services_up": false, "maintenance_ok": true, "reserve_ok": true, "debt_rule": "conservare", "casa": ""},
		"casa_open": false, "improved": false, "rule_changed": false}
	var x: Dictionary = base.duplicate(true)
	_check(FINALI_.decide("A", x)["variant"] == "A3", "A: conservare senza alternative aperte: A3")
	x["kept_by_choice"] = true
	_check(FINALI_.decide("A", x)["variant"] == "A1", "A: conservare scelto con un'altra regola aperta: A1")
	x["power"] = true
	_check(FINALI_.decide("A", x)["variant"] == "A1", "A: l'attribuzione del Capo da sola non sposta A1")
	x = base.duplicate(true)
	x["power"] = true
	_check(FINALI_.decide("A", x)["variant"] == "A3", "A: l'attribuzione del Capo senza la scelta: A3")
	x = base.duplicate(true)
	x["bonds"] = 3
	x["improved"] = true
	x["rule_changed"] = true
	x["kept_by_choice"] = true
	_check(FINALI_.decide("A", x)["variant"] == "A2", "A: A2 viene prima di A1")
	x = base.duplicate(true)
	x["evidence"] = 3
	_check(FINALI_.decide("B", x)["debt_status"] == "registrato" and FINALI_.decide("C", x)["debt_status"] == "registrato", "debito: le prove da sole non lo contestano")
	x["contested"] = true
	_check(FINALI_.decide("B", x)["debt_status"] == "contestato" and FINALI_.decide("A", x)["debt_status"] == "annullato", "debito: contestato solo con la contestazione, annullato solo in A")

	# il vero ciclo 3 col salvataggio: debt_other_open passa per il gioco, non per il test
	_c6_reset()
	var c6: Dictionary = load("res://chapters/c6/cima_c6.gd").c6()
	var st: Dictionary = RULES_.new_state()
	st["debt_rule"] = "revisione"
	st["debt_other_open"] = true
	c6["director_turn"]["state"] = st
	_check(FINALI_.effective_summary("B", "B1")["debt_rule"] == "conservare" and FINALI_.effective_summary("C", "C1")["debt_rule"] == "conservare",
		"B e C1: la regola adottata ai cicli non vale")
	_check(FINALI_.effective_summary("A", "A2")["debt_rule"] == "revisione" and FINALI_.effective_summary("C", "C2")["debt_rule"] == "revisione",
		"A e C2: la regola adottata ai cicli vale")
	_check(FINALI_.others_debts("B", "B2") == "registrati" and FINALI_.others_debts("C", "C2") == "revisione", "i debiti degli altri seguono la regola che vale")
	var e := _ending("C", "C2", "in_revisione")
	_check(e.call("debt_lines") == ["* Il tuo debito: IN REVISIONE.", "* I debiti degli altri: in revisione."], "C2: due righe di debito separate")
	_check("In revisione" in str(ENDING.printer_line("revisione")) and "0,5%" in str(ENDING.printer_line("interessi")) \
		and "bacheca" in str(ENDING.printer_line("alternative")) and "fascicolo dopo fascicolo" in str(ENDING.printer_line("conservare")), "la stampante segue la regola")
	e.free()
	e = _ending("B", "B1", "contestato")
	_check(e.call("debt_lines") == ["* Il tuo debito: CONTESTATO.", "* I debiti degli altri: registrati, come prima."], "B: debito contestato, gli altri come prima")
	e.free()
	GameState.save_game(Router.FINALE)
	GameState.new_game()
	GameState.load_game()
	_check(bool(FINALI_.turn_state().get("debt_other_open", false)), "la scelta consapevole del ciclo 3 resta dopo un caricamento")

	# B: ogni pezzo dalla sua fonte (nota 2)
	var b: Dictionary
	_c6_reset(false)
	e = _ending("B", "B1")
	b = e.call("b_lines")
	_check(b["alone"] and b["sender"] == "" and "Porta una sedia" in str(b["lines"]), "B: niente offerte né legami: la vicina e la sedia")
	GameState.helped_ids.append("ada")
	GameState.flags["met_ada"] = true
	b = e.call("b_lines")
	_check(not "ti ha trovato" in str(b["lines"]) and "posto letto" in str(b["lines"]) and b["sender"] == "ada", "B: legame senza offerta: niente casa inventata, il messaggio dal legame")
	_c6_reset(false)
	_offer("ada")
	b = e.call("b_lines")
	_check("ti ha trovato Ada" in str(b["lines"]) and "annuncio cerchiato" in str(b["lines"]) and b["sender"] == "ada", "B: solo casa")
	_c6_reset(false)
	_offer("nadir")
	b = e.call("b_lines")
	_check("posto letto" in str(b["lines"]) and "turno corto" in str(b["lines"]) and b["sender"] == "nadir", "B: solo lavoro")
	_c6_reset(false)
	_offer("rina")
	_offer("leda")
	b = e.call("b_lines")
	_check("ti ha trovato Rina" in str(b["lines"]) and "ordini condivisi" in str(b["lines"]) and b["sender"] == "leda", "B: casa e lavoro da due persone, il messaggio dall'offerta più recente")
	_c6_reset(false)
	_offer("fermo")
	b = e.call("b_lines")
	_check(not "ti ha trovato" in str(b["lines"]), "B: Fermo non ancora liberato non offre la stanza")
	GameState.freed.append("fermo")
	b = e.call("b_lines")
	_check("ti ha trovato Fermo" in str(b["lines"]) and b["sender"] == "fermo", "B: offerta da un liberato, pochi legami")
	_c6_reset(false)
	_offer("leda")
	GameState.robots.append("leda")
	b = e.call("b_lines")
	_check(b["alone"], "B: un robot non offre lavoro")
	_c6_reset(false)
	GameState.flags["c4_riepilogo"] = true
	b = e.call("b_lines")
	_check("il riepilogo della Banca e un annuncio" in str(b["lines"]), "B1: sul tavolo il riepilogo della Banca")
	e.free()
	e = _ending("B", "B1", "contestato")
	b = e.call("b_lines")
	_check("CONTESTATO" in str(b["lines"]) and not "riepilogo" in str(b["lines"]), "B: la lettera sul frigo solo se contestato")
	e.free()

	# C: Fermo nella scena secondo la sua storia
	_c6_reset(false)
	_check(ENDING.fermo_state() == "", "C: Fermo mai conosciuto non compare")
	GameState.flags["fermo_talked"] = true
	_check(ENDING.fermo_state() == "umano", "C: Fermo alla cyclette")
	GameState.freed.append("fermo")
	_check(ENDING.fermo_state() == "libero", "C: Fermo liberato arriva da fuori")


func _test_riparazioni() -> void:
	# Fermo: torto, poi riparazione tornando da lui
	_c6_reset(false)
	var f := GameState.flags
	f["fermo_talked"] = true
	f["boss_fermo_extra"] = 5
	Storia.segna("torto_fermo")
	_check(Storia.torto("fermo") and not Storia.riparato("fermo"), "Fermo: il torto della pausa accorciata")
	_check(Storia.reazione("fermo", false, false, false) == ["Ah. Pensavo fosse finito. Ancora cinque minuti."], "Fermo: senza aiuto né riparazione, la riga di prima")
	GameState.helped_ids.append("fermo")
	Storia.segna("aiuto_fermo")
	_check(Storia.reazione("fermo", false, false, false) == ["Ah. Pensavo fosse finito. Ancora cinque minuti."], "Fermo: torto poi aiuto: il torto non si dimentica")
	f["aiuto_fermo_seq"] = int(f["torto_fermo_seq"]) - 1
	_check("tutte e due le cose" in str(Storia.reazione("fermo", false, false, false)), "Fermo: aiuto poi torto: si ricorda tutte e due")
	_check(Storia.reazione("fermo", true, true, false) == ["Mi pagate di più per non fermarmi."], "Fermo: lo stipendio più alto da solo non ripara")
	_check(Storia.reazione("fermo", true, true, true) == [], "Fermo: in C2 con i TURNI la riparazione è la scena")
	var mins := GameState.minutes
	choose_queue = [0]
	_check(await Storia.offer_repair("fermo", "Fermo"), "Fermo: si può coprire il turno")
	_check(Storia.riparato("fermo") and f.has("riparato_fermo_seq") and GameState.minutes != mins, "Fermo: riparato, col suo numero (e il tempo speso)")
	_check(Storia.torto("fermo"), "la riparazione non cancella il torto")
	_check(Storia.reazione("fermo", true, true, false) == ["Quindici minuti. Li conto io."], "Fermo: la riparazione si riconosce")
	_check(BM.npc_lines("fermo") == ["Quindici minuti. Li conto io."], "Fermo: dopo la riparazione non ripete il torto")
	_check(not await Storia.offer_repair("fermo", "Fermo"), "Fermo: una riparazione sola")

	# Ercole: serve Tilde, e umana
	f["boss_ercole_archived"] = true
	f["met_ercole"] = true
	_check(not await Storia.offer_repair("ercole", "Ercole"), "Ercole: senza Tilde la procedura non si apre")
	f["met_tilde"] = true
	choose_queue = [1]
	_check(not await Storia.offer_repair("ercole", "Ercole") and not Storia.riparato("ercole"), "Ercole: 'Parla d'altro' non ripara")
	f["riparazione_chiesta_ercole"] = -1
	choose_queue = [0]
	_check(await Storia.offer_repair("ercole", "Ercole") and Storia.riparato("ercole"), "Ercole: nuova procedura con il timbro di Tilde")
	_check("si può aspettarla" in str(Storia.reazione("ercole", false, false, false)), "Ercole: la riparazione si riconosce")

	# Olga e Rina: le riparazioni sono quelle della loro storia
	f["boss_news_divisive"] = true
	_check("Non ho detto di chiudere" in str(Storia.reazione("rina", false, false, false)), "Rina: il montaggio divisivo")
	f["boss_news_rectified"] = true
	_check("non con la Casa" in str(Storia.reazione("rina", false, false, false)), "Rina: la rettifica pubblica")
	f["boss_olga_offer"] = {"visible": false, "total": 130000, "fee": 0, "months": 24}
	_check(Storia.reazione("olga", false, false, false) == [], "Olga: inganno non corretto: nessuna riga inventata")
	f["c4_olga_corretta"] = true
	_check("tutte e due le proposte" in str(Storia.reazione("olga", false, false, false)), "Olga: proposta corretta")

	# le riparazioni valgono in tutti i finali e restano dopo un caricamento
	GameState.save_game(Router.FINALE)
	GameState.new_game()
	GameState.load_game()
	_check(Storia.riparato("fermo") and Storia.riparato("ercole"), "le riparazioni restano dopo un caricamento")
	for fv: Array in [["B", "B1"], ["C", "C1"], ["C", "C3"], ["A", "A3"]]:
		var e := _ending(fv[0], fv[1])
		_check(e.call("reaction_for", "fermo") == ["Quindici minuti. Li conto io."], "la riparazione di Fermo vale anche in %s" % fv[1])
		e.free()


## Ogni scena finale si gioca davvero fino ai titoli di coda (le righe le controllano i test sopra).
func _test_scene_finali() -> void:
	for v: Array in [["A", "A1", [0, 5]], ["A", "A3", [5]], ["B", "B1", [0, 0, 5]], ["B", "B2", [0, 0, 5]], ["C", "C1", [5]], ["C", "C2", [5]], ["C", "C3", [5]]]:
		_c6_reset()
		var f := GameState.flags
		f["fermo_talked"] = true
		f["boss_fermo_extra"] = 5
		_offer("rina")
		_offer("nadir")
		f["c6_contestazione"] = v[1] == "B2"
		var c6: Dictionary = load("res://chapters/c6/cima_c6.gd").c6()
		c6["final_decision"]["confirmed"] = true
		c6["final_decision"]["selected"] = v[0]
		c6["final_decision"]["roles"] = {"conti": "teo", "servizi": "ada", "turni": "leda"} if v[1] != "C3" else {"conti": "teo"}
		c6["outcome"] = {"family": v[0], "variant": v[1], "debt_status": "contestato" if v[1] == "B2" else ("annullato" if v[0] == "A" else "registrato"),
			"governance_status": "", "engine": 2}
		choose_queue = v[2]
		choose_index = 0
		Router.goto(Router.FINALE)
		await _wait_scene(Router.FINALE)
		await _wait_scene(Router.MENU, 180000)
		await _idle()
		_check(logic_c6()["completed"], "il finale %s arriva ai titoli di coda" % v[1])
	# un salvataggio di prima: niente "engine", il finale si ricalcola (A1 non si inventa)
	_c6_reset()
	var c6b: Dictionary = load("res://chapters/c6/cima_c6.gd").c6()
	c6b["final_decision"]["confirmed"] = true
	c6b["final_decision"]["selected"] = "A"
	c6b["outcome"] = {"family": "A", "variant": "A1", "debt_status": "annullato", "governance_status": ""}
	c6b["epilogue"]["step"] = 7
	choose_queue = [5]
	choose_index = 0
	Router.goto(Router.FINALE)
	await _wait_scene(Router.FINALE)
	await _wait_scene(Router.MENU, 180000)
	await _idle()
	_check(logic_c6()["outcome"]["variant"] == "A3" and logic_c6()["outcome"].get("engine", 0) == 2, "vecchio salvataggio: il finale si ricalcola, niente A1 inventato")


func logic_c6() -> Dictionary:
	return load("res://chapters/c6/cima_c6.gd").c6()
