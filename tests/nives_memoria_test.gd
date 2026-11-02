extends "res://tests/storia_test.gd"
## Test della memoria di Nives (docs/NIVES_MEMORIA.md, scripts/memoria_nives.gd).
## Usa un salvataggio e una memoria tutti suoi: la memoria vera del giocatore non si legge e non si tocca.
## Esegui:  Godot --headless --path . res://tests/nives_memoria_test.tscn
## Alla fine stampa "NIVES TEST OK" oppure gli errori trovati.

const MN := preload("res://scripts/memoria_nives.gd")
const MENU_SCRIPT := preload("res://scenes/main_menu.gd")

## Tutte le battute e le scelte comparse a schermo (per controllare cosa dice Nives).
var _seen: Array[String] = []
var _last_seen := ""


func _process(delta: float) -> void:
	if Ui.busy:
		var t: Label = Ui.get("_text")
		var k := t.text + "|" + str(Ui.get("_options"))
		if k != _last_seen:
			_last_seen = k
			_seen.append(t.text)
			for o: Variant in Ui.get("_options"):
				_seen.append("> " + str(o))
	super(delta)


func _said(line: String) -> bool:
	for s in _seen:
		if line in s:
			return true
	return false


func _run() -> void:
	GameState.save_path = "user://test_nives_memoria.json"
	_check(MN.path() != MN.PATH, "i test usano una memoria a parte")
	_wipe()
	await _test_prima_partita()
	await _test_registrazione()
	await _test_ritorno()
	await _test_ricordi()
	await _test_due_finali()
	await _test_rivelazione()
	await _test_comportamento()
	await _test_epilogo()
	_test_vecchi_salvataggi()
	await _test_cancellazione()
	_test_economia()
	_test_nome()
	_wipe()
	if _failures.is_empty():
		print("NIVES TEST OK (%d controlli)" % _checks)
	else:
		print("NIVES TEST FALLITO:\n- " + "\n- ".join(_failures))
	get_tree().quit(0 if _failures.is_empty() else 1)


## Via salvataggio e memoria del test.
func _wipe() -> void:
	for p: String in [GameState.save_path, GameState.save_path + ".bak", MN.path()]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	MN._from = ""


## Una partita nuova come la fa il menu (con il suo numero).
func _new_run() -> void:
	_legacy_new_game()
	GameState.flags["run_id"] = MN.new_run_id()
	GameState.flags["c1_arrivo"] = true
	choose_queue = []
	choose_index = 0
	_seen.clear()


## La memoria scritta a mano: [variante, passato] in ordine.
func _remember(list: Array) -> void:
	_wipe()
	var d := MN.data()
	var i := 0
	for v: Array in list:
		i += 1
		var e := {"run": "vecchia-%d" % i, "family": str(v[0]).left(1), "variant": v[0], "past": v[1] if v.size() > 1 else ""}
		if v.size() > 2:
			e.merge(v[2])
		(d["endings"] as Array).append(e)
	MN._write()


func _fondo_booth(queue: Array) -> Room:
	var m: Room = await _go(Router.FONDO)
	choose_queue = queue
	_seen.clear()
	await m.call("_badge_machine")
	await _idle()
	return m


# --- 1. la prima partita: niente falsi ricordi --------------------------------------------------------

func _test_prima_partita() -> void:
	_wipe()
	_new_run()
	GameState.money = 600
	await _fondo_booth([0, 0, 1])
	_check(_said("Per quella dopo.") and _said("Io lavoro da questa parte.") and _said("Era già dritto."), "prima partita: il prezzo del Fondo con la porta dopo")
	_check(not _said("Il badge del Piano -4 costa"), "prima partita: il prezzo non si ripete")
	_check(not _said("Sei tornato") and not _said("Direttore") and not _said("Ti ricordi"), "prima partita: nessun falso ricordo")
	_check(GameState.money == 600 and not GameState.has_badge("-4"), "prima partita: \"Non ora\" non compra niente")
	# la seconda visita: il prezzo di sempre, senza ripetere la scenetta
	_seen.clear()
	choose_queue = [0]
	await (get_tree().current_scene as Room).call("_badge_machine")
	await _idle()
	_check(not _said("Per quella dopo.") and _said("Va tutto a scalare dal tuo debito.") and GameState.has_badge("-4") and GameState.money == 100,
		"seconda visita: il prezzo normale, il badge costa 500 come prima")


# --- registrare un finale: una volta sola, solo se è una partita vera ----------------------------------

func _finale(family: String, variant: String, queue: Array) -> void:
	_c6_reset()
	var f := GameState.flags
	f["fermo_talked"] = true
	_offer("rina")
	_offer("nadir")
	var c6: Dictionary = load("res://chapters/c6/cima_c6.gd").c6()
	c6["final_decision"]["confirmed"] = true
	c6["final_decision"]["selected"] = family
	c6["final_decision"]["roles"] = {"conti": "teo", "servizi": "ada", "turni": "leda"} if variant != "C3" else {"conti": "teo"}
	if variant == "A2":
		var st2: Dictionary = RULES_.new_state()
		st2["debt_rule"] = "revisione"
		c6["director_turn"]["state"] = st2
	c6["outcome"] = {"family": family, "variant": variant, "debt_status": "annullato" if family == "A" else "registrato", "governance_status": "", "engine": 2}


func _play_finale(queue: Array) -> void:
	choose_queue = queue
	choose_index = 0
	_seen.clear()
	Router.goto(Router.FINALE)
	await _wait_scene(Router.FINALE)
	await _wait_scene(Router.MENU, 180000)
	await _idle()


func _test_registrazione() -> void:
	_wipe()
	# una prova senza numero di partita (come gli altri test): non si registra
	_finale("A", "A1", [])
	await _play_finale([0, 5])
	_check(MN.count() == 0, "un finale aperto per prova (senza partita) non si registra")
	# una partita vera
	_finale("A", "A1", [])
	GameState.flags["run_id"] = "partita-1"
	await _play_finale([0, 5])
	_check(MN.count() == 1 and str(MN.data()["endings"][0]["variant"]) == "A1", "finale A1 registrato ai titoli di coda")
	_check(not MN.returning(), "nella stessa partita il finale non è ancora un ricordo")
	# salvare e ricaricare lo stesso finale: niente doppioni
	MN._from = ""
	_check(GameState.load_game().size() > 0 and MN.run_id() == "partita-1", "il salvataggio ricorda il numero della partita")
	await _play_finale([])
	MN._from = ""
	_check(MN.count() == 1, "rivedere i titoli dello stesso finale non lo duplica")
	# il finale selezionato ma non concluso non conta
	_finale("C", "C2", [])
	GameState.flags["run_id"] = "partita-2"
	var c6: Dictionary = load("res://chapters/c6/cima_c6.gd").c6()
	c6["epilogue"]["step"] = 0
	_check(MN.count() == 1, "un finale scelto ma non finito non c'è")


# --- 2. il ritorno al Fondo -----------------------------------------------------------------------------

func _test_ritorno() -> void:
	_remember([["A1"]])
	_new_run()
	GameState.money = 0
	await _fondo_booth([0, 0, 0, 1])
	_check(_said("Oh. Sei tornato.") and _said("Non me l'hai ancora chiesto.") and _said("Tu ancora no."), "ritorno: Sei tornato / Tu ancora no")
	_check(_said("Per quella dopo."), "ritorno: poi lo sportello normale")
	_check(not GameState.has_badge("-4") and GameState.money == 0, "ritorno: nessun badge gratis")
	_new_run()
	await _fondo_booth([1, 1])
	_check(_said("Il prezzo se lo ricordano sempre.") and not _said("Per quella dopo."), "ritorno, \"Quanto costa?\": il prezzo non si ripete")
	# il ritorno è una volta per partita
	_seen.clear()
	choose_queue = [1, 1]
	await (get_tree().current_scene as Room).call("_badge_machine")
	await _idle()
	_check(not _said("Sei tornato"), "il ritorno non si ripete nella stessa partita")
	# una partita lasciata a metà non è un finale: la memoria resta quella di prima
	_check(MN.count() == 1, "ripartire senza finire non aggiunge niente")


# --- 3. il ricordo dell'ultimo finale, per ogni variante ----------------------------------------------

const RECALL := {
	"A1": "Come preferisci che ti chiami, questa volta?", "A2": "I debiti senza firma si ricontrollavano.",
	"A3": "Mi era rimasta la curiosità.", "B1": "Peccato per il posto.", "B2": "Quella parte la sai tu.",
	"C1": "Ci andavo lo stesso.", "C2": "Poi avevo imparato.", "C3": "Mi ricordo soprattutto quella parola. Ancora.",
}


func _booth(floor: String, queue: Array) -> void:
	GameState.floor_id = floor
	choose_queue = queue
	_seen.clear()
	await MN.at_booth("Nives")
	await _idle()


func _test_ricordi() -> void:
	for v: String in RECALL:
		_remember([[v, "", {"debt_rule": "revisione"} if v == "A2" else {}]])
		_new_run()
		GameState.flags["nives_mem_ritorno"] = true
		await _booth("-3", [0, 0, 0, 0])
		_check(_said(RECALL[v]), "ricordo %s" % v)
		var others := 0
		for w: String in RECALL:
			if w != v and _said(RECALL[w]):
				others += 1
		_check(others == 0, "ricordo %s: una variante sola" % v)
	# A1: il nome o "Come vuoi"
	_remember([["A1"]])
	_new_run()
	GameState.player_name = "Lia"
	GameState.flags["nives_mem_ritorno"] = true
	await _booth("-3", [0, 0, 0])
	_check(_said("> Lia") and _said("Lia. Va bene."), "A1: si può scegliere il proprio nome")
	_new_run()
	GameState.flags["nives_mem_ritorno"] = true
	await _booth("-3", [0, 0, 1])
	_check(_said("Allora resto su"), "A1: oppure Come vuoi")
	# facoltativo: si può dire "Niente", e torna al piano dopo
	_new_run()
	GameState.flags["nives_mem_ritorno"] = true
	await _booth("-3", [1])
	_check(not _said("Buongiorno, Direttore."), "il ricordo si può saltare")
	await _booth("-3", [0])
	_check(not _said("Ti ricordi di me?"), "saltato: sullo stesso piano non insiste")
	await _booth("-2", [0, 0, 0])
	_check(_said("Buongiorno, Direttore."), "saltato: torna allo sportello dopo")
	# A2 senza regola salvata: nessuna politica inventata
	_remember([["A2"]])
	_new_run()
	GameState.flags["nives_mem_ritorno"] = true
	await _booth("-3", [0, 0])
	_check(_said("L'avevo letto due volte.") and not _said("ricontrollavano") and not _said("zero virgola"), "A2 senza regola salvata: non la inventa")


# --- 6. due finali diversi, nel loro ordine ------------------------------------------------------------

func _test_due_finali() -> void:
	_remember([["A1"], ["C2"]])
	_new_run()
	GameState.flags["nives_mem_ritorno"] = true
	GameState.flags["nives_mem_ricordo"] = true
	await _booth("-3", [0, 0, 0])
	_check(_said("> Quale delle due volte ti ricordi?") and _said("Tutte e due.") and _said("È la parte scomoda."), "due finali: la domanda")
	_check(_said("Una volta eri il Direttore.") and _said("Un'altra volta avevo una sedia dove potevo risponderti."), "A1 poi C2: nell'ordine")
	_check(_said("Il resto non è ancora successo."), "due finali: la chiusura")
	_remember([["C2"], ["A1"]])
	_new_run()
	GameState.flags["nives_mem_ritorno"] = true
	GameState.flags["nives_mem_ricordo"] = true
	await _booth("-3", [0, 0, 0])
	_check(_said("Una volta avevo una sedia") and _said("Un'altra volta eri il Direttore."), "C2 poi A1: l'ordine vero")
	# lo stesso finale due volte non fa "due volte"
	_remember([["B1"], ["B1"]])
	_new_run()
	GameState.flags["nives_mem_ritorno"] = true
	GameState.flags["nives_mem_ricordo"] = true
	await _booth("-3", [0, 0, 0])
	_check(not _said("Tutte e due."), "lo stesso finale due volte: niente scena dei due ricordi")


# --- 4. la rivelazione della Banca ----------------------------------------------------------------------

func _test_rivelazione() -> void:
	# prima partita: dopo la ricevuta, "Tienila", e niente rivelazione
	_wipe()
	var m := await _bank([])
	GameState.flags["run_id"] = "prima"
	_seen.clear()
	m = await _stairs(m, [0, 0, 1])
	_check(_said("Tienila.") and _said("> Servirà?") and _said("Anche se preferirei che bastasse ricordarsela."), "Banca: Tienila, in ogni partita")
	_check(not _said("Perché mi parli come se"), "prima partita: niente rivelazione")
	_check(str(get_tree().current_scene.scene_file_path) == Router.BANCA, "la scena resta in Banca (prima della salita)")
	# dopo un finale: alle scale si può chiedere, prima di salire
	_remember([["B1", "solidale"]])
	m = await _bank(["c4_teo", "c4_olga"])
	GameState.flags["run_id"] = "seconda"
	GameState.flags["met_olga"] = true
	GameState.flags["met_teo"] = true
	GameState.robots.append("teo")
	_seen.clear()
	m = await _stairs(m, [0, 0, 1, 0, 0, 0, 0, 0, 0])
	_check(_said("Perché una volta è successo.") and _said("Forse non sto parlando proprio con te.") and _said("\"Nuova partita\"."), "rivelazione alle scale")
	_check(_said("Con me, però, qualcosa torna insieme a te.") and _said("Mi ricordo dove siamo arrivati.") and _said("Non devi chiedermi il permesso."), "rivelazione: le risposte")
	_check(_said("Tipo: te n'eri andato. Non so dove."), "rivelazione: un ricordo solo, quello vero")
	_check(_said("Olga. Sono ancora qui.") and not _said("Teo. Sono"), "rivelazione: solo chi è ancora una persona")
	_check(_said("Lui ricomincia da uno e basta."), "rivelazione: il numerino")
	_check(MN.heard("rivelazione") and not MN.can_reveal(), "la rivelazione si sente una volta")
	# saltata alle scale: torna in Città
	_remember([["B1"]])
	m = await _bank([])
	GameState.flags["run_id"] = "terza"
	_seen.clear()
	m = await _stairs(m, [0, 0, 1, 0, 1])
	_check(_said("> Perché mi parli come se tutto fosse già successo?") and not _said("Perché una volta è successo."), "rivelazione saltata alle scale")
	GameState.flags["nives_mem_ritorno"] = true
	await _booth("0", [0, 0, 4])
	_check(_said("Perché una volta è successo."), "rivelazione recuperata allo sportello della Città")


# --- 5. cambiare comportamento ---------------------------------------------------------------------------

func _test_comportamento() -> void:
	_remember([["A3", "opportunista"]])
	_new_run()
	GameState.flags["nives_mem_ritorno"] = true
	GameState.flags["nives_mem_ricordo"] = true
	GameState.helped_ids.assign(["leda", "amir"])
	await _booth("-3", [0])
	_check(_said("Sto guardando anche quello che fai adesso."), "prima opportunista, ora aiuti")
	_remember([["C1", "solidale"]])
	_new_run()
	GameState.flags["nives_mem_ritorno"] = true
	await _booth("-3", [1])
	_check(not _said("controllo delle tue mani"), "senza un danno vero, nessun rimprovero")
	GameState.exploited = 1
	GameState.robots.append("amir")
	await _booth("-3", [0])
	_check(_said("Ricordare non mi dà il controllo delle tue mani."), "prima solidale, ora un robot")
	# Olga: la proposta ritirata davvero (anche nella prima partita)
	_wipe()
	_new_run()
	GameState.flags["boss_olga_offer"] = {"visible": false}
	GameState.flags["c4_olga_corretta"] = true
	await _booth("0", [0])
	_check(_said("Questo devi chiederlo a Olga."), "proposta a Olga ritirata")
	await _booth("0", [0])
	_check(not _said("Ho saputo che hai ritirato"), "una volta sola")


# --- 7. l'epilogo -----------------------------------------------------------------------------------------

func _test_epilogo() -> void:
	_wipe()
	_finale("C", "C2", [])
	GameState.flags["run_id"] = "solo"
	await _play_finale([5])
	_check(not _said("Questa me la ricorderò."), "prima partita conclusa: l'epilogo di sempre")
	_remember([["A1"]])
	_finale("C", "C2", [])
	GameState.flags["run_id"] = "dopo"
	await _play_finale([0, 5])
	_check(_said("Questa me la ricorderò.") and _said("> Anche se ricomincio?") and _said("* Nives torna al tavolo condiviso."), "epilogo dopo un finale")
	_check(_said("Poi ho cominciato a chiedermi perché fossero chiuse."), "l'epilogo di prima resta")
	MN._from = ""
	var e: Array = MN.data()["endings"]
	_check(e.size() == 2 and str(e[0]["variant"]) == "A1" and str(e[1]["variant"]) == "C2", "i finali nell'ordine in cui sono successi")


# --- vecchi salvataggi ----------------------------------------------------------------------------------

func _save_like_old(completed: bool) -> void:
	_c6_reset()
	var c6: Dictionary = load("res://chapters/c6/cima_c6.gd").c6()
	c6["completed"] = completed
	c6["outcome"] = {"family": "C", "variant": "C1", "engine": 2}
	GameState.flags.erase("run_id")
	GameState.save_game(Router.FINALE)


func _test_vecchi_salvataggi() -> void:
	_wipe()
	_save_like_old(false)
	MN.import_legacy()
	_check(MN.count() == 0 and not FileAccess.file_exists(MN.path()), "vecchio salvataggio non finito: nessun finale inventato")
	_save_like_old(true)
	MN.import_legacy()
	_check(MN.count() == 1 and str(MN.data()["endings"][0]["run"]) == MN.LEGACY, "vecchio salvataggio finito: importato")
	MN.import_legacy()
	_check(MN.count() == 1, "importato una volta sola")
	GameState.load_game()
	_check(MN.run_id() == MN.LEGACY and not MN.returning(), "caricarlo non è ricominciare: è la stessa partita")
	MN.record({"family": "C", "variant": "C1"}, {})
	_check(MN.count() == 1, "rivederne i titoli non lo duplica")
	# memoria rovinata: si riparte da vuota, senza errori
	var f := FileAccess.open(MN.path(), FileAccess.WRITE)
	f.store_string("{rotto")
	f.close()
	MN._from = ""
	_check(MN.count() == 0 and not MN.returning(), "memoria illeggibile: nessun ricordo")


# --- la cancellazione -------------------------------------------------------------------------------------

func _test_cancellazione() -> void:
	_remember([["A1"], ["C2"]])
	_save_like_old(true)
	MN.forget()
	_check(MN.count() == 0 and not MN.returning(), "cancellata: nessun finale")
	MN.import_legacy()
	_check(MN.count() == 0, "cancellata: il vecchio salvataggio non torna")
	GameState.load_game()
	MN.record({"family": "C", "variant": "C1"}, {})
	_check(MN.count() == 0, "cancellata: i titoli di una partita già finita non la riscrivono")
	_new_run()
	await _fondo_booth([0, 0, 1])
	_check(not _said("Sei tornato") and _said("Per quella dopo."), "cancellata: Nives non finge di ricordare")


# --- la memoria non cambia economia, progressione e finali -------------------------------------------------

func _test_economia() -> void:
	_wipe()
	_c6_reset()
	var x0: Dictionary = FINALI_.facts()
	var outs0 := [FINALI_.decide("A"), FINALI_.decide("B"), FINALI_.decide("C")]
	_remember([["A1", "opportunista"], ["C2", "solidale"]])
	var x1: Dictionary = FINALI_.facts()
	var outs1 := [FINALI_.decide("A"), FINALI_.decide("B"), FINALI_.decide("C")]
	_check(str(x0) == str(x1) and str(outs0) == str(outs1), "con la memoria i finali si decidono uguali")
	_check(GameState.badge_cost("-4") == 500 and GameState.badge_cost("cima") == 8000, "prezzi dei badge uguali")


# --- il nome --------------------------------------------------------------------------------------------

func _test_nome() -> void:
	_check(MENU_SCRIPT.clean_name("Ma12ri@o!") == "Mario", "nome: via numeri e simboli")
	_check(MENU_SCRIPT.clean_name("D'Angelo Rè") == "D'Angelo Rè", "nome: lettere accentate, spazi e apostrofo restano")
	for bad: String in ["cazzo", "Stronzo", "vaffa nculo", "MERDA", "culo", "porco dio", "fuck"]:
		_check(MENU_SCRIPT.is_rude(bad), "parolaccia bloccata: " + bad)
	for ok: String in ["Pasculli", "Negroni", "Troiani", "Figaro", "Cassandra", "Linda", "Anouk"]:
		_check(not MENU_SCRIPT.is_rude(ok), "nome innocente accettato: " + ok)
