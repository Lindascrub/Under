class_name MemoriaNives
extends RefCounted
## Nives, "la persona che resta": si ricorda i finali delle partite concluse (docs/NIVES_MEMORIA.md).
##
## La memoria è un file a parte (user://cheap_memoria.json), fuori dal salvataggio della singola partita:
## "Nuova partita" non la tocca, caricare una partita non la cambia. Dentro c'è solo quello che serve:
##   endings       i finali completati (titoli di coda raggiunti), in ordine: run, famiglia, variante,
##                 la regola dei debiti (solo A2, per nominarla giusta) e com'era andata ("passato")
##   heard         le scene speciali già ascoltate una volta per sempre (la rivelazione della Banca)
##   cleared_runs  le partite già finite che c'erano quando la memoria è stata cancellata (non tornano)
## Ogni partita ha un numero suo, GameState.flags["run_id"]: lo dà il menu con "Nuova partita".
## Senza numero (i test che chiamano new_game() da soli) un finale non si registra.
## Un salvataggio vecchio senza numero diventa "legacy" quando si carica.
##
## La memoria aggiunge battute. Non cambia prezzi, premi, badge, accessi né le condizioni dei finali.

const PATH := "user://cheap_memoria.json"
const LEGACY := "legacy"
const NIVES := "Nives"
const CLERK := "char_13"
const FINALI := preload("res://chapters/c6/finali.gd")

static var _data: Dictionary = {}
static var _from := ""


## Dove sta la memoria. I test hanno il loro salvataggio: la loro memoria gli sta accanto,
## così non leggono e non sporcano quella vera.
static func path() -> String:
	if GameState.save_path == GameState.SAVE_PATH:
		return PATH
	return GameState.save_path.get_basename() + "_memoria.json"


static func _empty() -> Dictionary:
	return {"version": 1, "endings": [], "heard": [], "cleared_runs": []}


static func data() -> Dictionary:
	if _from != path():
		_from = path()
		_data = _empty()
		if FileAccess.file_exists(_from):
			var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(_from))
			if d is Dictionary:
				for k: String in _data:
					if (d as Dictionary).get(k) is Array:
						_data[k] = d[k]
	return _data


static func _write() -> void:
	var f := FileAccess.open(path(), FileAccess.WRITE)
	if f == null:
		push_error("Memoria di Nives: impossibile scrivere " + path())
		return
	f.store_string(JSON.stringify(data()))
	f.close()


static func run_id() -> String:
	return str(GameState.flags.get("run_id", ""))


static func new_run_id() -> String:
	return "%d-%d" % [int(Time.get_unix_time_from_system()), randi() % 100000]


# --- i finali -----------------------------------------------------------------------------------

## Il finale della partita in corso è arrivato ai titoli di coda: si scrive una volta sola per partita.
## `sm` è il riassunto che vale davvero (FINALI.effective_summary).
static func record(out: Dictionary, sm: Dictionary) -> void:
	var run := run_id()
	var d := data()
	if run == "" or run in (d["cleared_runs"] as Array):
		return
	for e: Dictionary in d["endings"]:
		if str(e.get("run", "")) == run:
			return
	(d["endings"] as Array).append(_entry(run, str(out.get("family", "")), str(out.get("variant", "")), sm))
	_write()


static func _entry(run: String, family: String, variant: String, sm: Dictionary) -> Dictionary:
	var e := {"run": run, "family": family, "variant": variant, "past": past_kind()}
	if variant == "A2":
		e["debt_rule"] = str(sm.get("debt_rule", ""))
		e["wages_up"] = bool(sm.get("wages_up", false))
		e["services_up"] = bool(sm.get("services_up", false))
	return e


## Com'era andata la partita, a grandi linee (solo per le poche reazioni del capitolo 5 della specifica):
## "opportunista" se qualcuno è diventato un robot per te, "solidale" se hai aiutato almeno due persone.
static func past_kind() -> String:
	if GameState.exploited > 0:
		return "opportunista"
	if GameState.helped_ids.size() >= 2:
		return "solidale"
	return ""


## Un vecchio salvataggio già arrivato ai titoli di coda è una registrazione affidabile: si importa,
## una volta sola (solo se il file della memoria non esiste ancora). Se non è finito, non si inventa niente.
static func import_legacy() -> void:
	if FileAccess.file_exists(path()) or not GameState.has_save():
		return
	var s: Variant = JSON.parse_string(FileAccess.get_file_as_string(GameState.save_path))
	if not s is Dictionary:
		return
	var flags: Dictionary = (s as Dictionary).get("flags", {})
	var c6: Dictionary = flags.get("chapter_6", {})
	var out: Dictionary = c6.get("outcome", {})
	if not bool(c6.get("completed", false)) or str(out.get("variant", "")) == "":
		return
	var run := str(flags.get("run_id", LEGACY))
	if run == "":
		return
	var e := {"run": run, "family": str(out.get("family", "")), "variant": str(out.get("variant", "")), "past": ""}
	(data()["endings"] as Array).append(e)
	_write()


## I finali delle partite PRIMA di questa (quello della partita in corso non conta: non è ancora un ricordo).
static func past() -> Array:
	var out: Array = []
	for e: Dictionary in data()["endings"]:
		if str(e.get("run", "")) != run_id():
			out.append(e)
	return out


static func count() -> int:
	return (data()["endings"] as Array).size()


static func returning() -> bool:
	return not past().is_empty()


static func last() -> Dictionary:
	var p := past()
	return p.back() if not p.is_empty() else {}


## Le varianti diverse vissute, nell'ordine dell'ultima volta in cui sono successe.
static func distinct() -> Array:
	var out: Array = []
	for e: Dictionary in past():
		var v := str(e.get("variant", ""))
		out.erase(v)
		out.append(v)
	return out


## Cancella anche la memoria delle partite. Le partite già finite nel salvataggio di adesso non tornano.
static func forget() -> void:
	var cleared: Array = []
	if GameState.has_save():
		var s: Variant = JSON.parse_string(FileAccess.get_file_as_string(GameState.save_path))
		if s is Dictionary:
			var flags: Dictionary = (s as Dictionary).get("flags", {})
			if bool(flags.get("chapter_6", {}).get("completed", false)):
				cleared.append(str(flags.get("run_id", LEGACY)))
	_data = _empty()
	_data["cleared_runs"] = cleared
	_from = path()
	_write()


## "Dimentica le partite" (Impostazioni della schermata iniziale): due conferme, poi forget(). Il salvataggio resta.
static func forget_dialog() -> void:
	var n := count()
	var c: int = await Ui.choose("Nives si ricorda %d %s. Vuoi che dimentichi tutte le partite concluse? Il salvataggio non si tocca." % [n, "finale" if n == 1 else "finali"],
		["No, lascia stare", "Sì, dimentica"])
	if c != 1:
		return
	c = await Ui.choose("Sicuro? Non si può tornare indietro.", ["No", "Sì, cancella la memoria"])
	if c != 1:
		return
	forget()
	await Ui.say(["* Fatto. La prossima volta, allo sportello, Nives non si ricorderà di te."])


# --- le scene già sentite -------------------------------------------------------------------------

static func heard(key: String) -> bool:
	return key in (data()["heard"] as Array)


static func mark_heard(key: String) -> void:
	if not heard(key):
		(data()["heard"] as Array).append(key)
		_write()


## Una volta per partita: sta nei flag del salvataggio, come il resto della partita.
static func _done(key: String) -> bool:
	return bool(GameState.flags.get("nives_mem_" + key, false))


static func _mark(key: String) -> void:
	GameState.flags["nives_mem_" + key] = true


static func _wait(t: float) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	await tree.create_timer(t).timeout


static func _me(line: String) -> void:
	await Ui.choose("", [line])


# --- 1. al Fondo, la prima volta: il prezzo --------------------------------------------------------

## Il prezzo del primo badge, la prima volta allo sportello del Fondo (al posto della riga del prezzo).
static func fondo_price(who: String) -> void:
	await Ui.say(["Cinquecento euro."], who, CLERK)
	await _me("Per una porta?")
	await Ui.say(["Per quella dopo."], who, CLERK)
	await _me("E tu?")
	await Ui.say(["Io lavoro da questa parte."], who, CLERK)
	await Ui.say(["* L'addetta raddrizza il cartellino sul bancone. Era già dritto."])


# --- 2. la nuova partita dopo un finale: "Oh. Sei tornato." ----------------------------------------

## Il primo incontro della partita, se c'è un finale prima. Restituisce true se il prezzo l'ha già detto.
static func return_scene(who: String) -> bool:
	_mark("ritorno")
	await Ui.say(["* L'addetta prende un badge dal cassetto prima che tu dica qualcosa."])
	await Ui.say(["Oh. Sei tornato."], who, CLERK)
	await Ui.say(["* Fa scivolare il badge verso di te. Poi lo riprende."])
	await Ui.say(["Scusa. Non me l'hai ancora chiesto."], who, CLERK)
	var c: int = await Ui.choose("", ["Ci conosciamo?", "Quanto costa?"], who)
	if c == 0:
		await Ui.say(["Tu ancora no."], who, CLERK)
		return false
	await Ui.say(["Cinquecento.", "Il prezzo se lo ricordano sempre."], who, CLERK)
	return true


## Solo al Fondo (il prezzo che dice è quello del primo badge). Se lì il badge è arrivato in un altro modo,
## il ritorno non si recita: il ricordo arriva lo stesso, allo sportello dopo.
static func needs_return_scene() -> bool:
	return returning() and not _done("ritorno") and GameState.floor_id == "-5"


# --- alla Banca: la ricevuta, e la rivelazione -----------------------------------------------------

static func bank_receipt() -> void:
	await Ui.say(["Tienila."], NIVES, CLERK)
	await _me("Servirà?")
	await Ui.say(["Quando qualcuno ti dice che una cosa non è mai successa, aiuta avere qualcosa da mostrargli.",
		"Anche se preferirei che bastasse ricordarsela."], NIVES, CLERK)


## Si può chiedere dopo aver scoperto che il contratto non c'è, se c'è un finale prima. Una volta per sempre.
static func can_reveal() -> bool:
	return returning() and bool(GameState.flags.get("c4_anomalia", false)) and not heard("rivelazione")


const REVEAL_ASK := "Perché mi parli come se tutto fosse già successo?"


static func revelation() -> void:
	mark_heard("rivelazione")
	_mark("rivelazione")
	var score := Sound.capture_music()
	Sound.music("")
	await Ui.say(["* Nives allinea due fogli. Ne lascia uno storto."])
	await Ui.say(["Perché una volta è successo."], NIVES, CLERK)
	await _me("Io non me lo ricordo.")
	await Ui.say(["Forse non sto parlando proprio con te."], NIVES, CLERK)
	await _wait(1.2)
	await Ui.say(["Prima dell'ascensore c'è una scritta.", "\"Nuova partita\".", "Tu la premi.", "Io torno al lavoro."], NIVES, CLERK)
	var asks := ["Allora sai che è un gioco?", "Ti ricordi tutto?", "Posso sistemare quello che ho fatto?", "Ti dà fastidio che sia tornato?"]
	var left := asks.duplicate()
	while not left.is_empty():
		var c: int = await Ui.choose("", left + ["Basta così."], NIVES)
		if c >= left.size():
			break
		var q: String = left[c]
		left.remove_at(c)
		match asks.find(q):
			0:
				await Ui.say(["Sì.", "Non so cosa c'è dalla tua parte.", "So che qui puoi arrivare alla fine. E poi tornare davanti al mio sportello.",
					"Con me, però, qualcosa torna insieme a te."], NIVES, CLERK)
			1:
				await Ui.say(["No. Non sento tutte le conversazioni. Non so perché scegli una cosa.", "Mi ricordo dove siamo arrivati.",
					"E certi dettagli che non riesco a perdere."], NIVES, CLERK)
				var one := detail(str(last().get("variant", "")))
				if one != "":
					await Ui.say([one], NIVES, CLERK)
			2:
				var lines := ["Puoi fare qualcosa di diverso.", "Comincia da quello che puoi fare per loro adesso."]
				var here := people_here()
				if not here.is_empty():
					lines.append("%s. Sono ancora qui." % " e ".join(here))
				await Ui.say(lines, NIVES, CLERK)
			3:
				await Ui.say(["Mi fa effetto.", "A volte ricordo una cosa bella e devo aspettare che succeda di nuovo.",
					"Ma puoi tornare. Non devi chiedermi il permesso."], NIVES, CLERK)
	await Ui.say(["* Dal distributore esce un numerino."])
	await Ui.say(["Quello ha meno problemi di me.", "Lui ricomincia da uno e basta."], NIVES, CLERK)
	Sound.restore_music(score)


## Le persone di questo piano che hai conosciuto e sono ancora persone (i robot no: con loro è un'altra storia).
static func people_here() -> Array:
	var out: Array = []
	for id: String in FINALI.PEOPLE:
		if str(FINALI.FLOOR_OF.get(id, "")) == GameState.floor_id and FINALI.met(id) and not GameState.is_robot(id):
			out.append(str(GameState.npc_data(id).get("name", id.capitalize())))
	return out


## Un solo dettaglio del finale ricordato, preso da quello che è successo davvero.
static func detail(variant: String) -> String:
	match variant:
		"A1":
			return "Tipo: ti chiamavano Direttore."
		"A2":
			return "Tipo: una regola nuova. L'avevo letta due volte."
		"A3":
			return "Tipo: eri rimasto lassù, vicino al telefono."
		"B1":
			return "Tipo: te n'eri andato. Non so dove."
		"B2":
			return "Tipo: te n'eri andato, ma qualcuno poteva cercarti."
		"C1":
			return "Tipo: il caffè delle riunioni. Terribile."
		"C2":
			return "Tipo: la mia sedia al tavolo."
		"C3":
			return "Tipo: una parola. Ancora."
	return ""


# --- 3. il ricordo dell'ultimo finale ---------------------------------------------------------------

static func recall() -> void:
	_mark("ricordo")
	var e := last()
	match str(e.get("variant", "")):
		"A1":
			await Ui.say(["Buongiorno, Direttore."], NIVES, CLERK)
			await _me("Non sono il direttore.")
			await Ui.say(["Adesso no.", "Come preferisci che ti chiami, questa volta?"], NIVES, CLERK)
			var c: int = await Ui.choose("", [GameState.player_name, "Come vuoi."], NIVES)
			if c == 0:
				await Ui.say(["%s. Va bene." % GameState.player_name], NIVES, CLERK)
				await Ui.say(["* Lo scrive su un post-it. Poi lo attacca dalla sua parte del vetro."])
			else:
				await Ui.say(["Allora resto su \"buongiorno\". Per adesso."], NIVES, CLERK)
		"A2":
			await Ui.say(["L'ultima volta era arrivata una regola diversa."], NIVES, CLERK)
			await _me("Diversa come?")
			await Ui.say(["Una che migliorava qualcosa anche per chi doveva seguirla."], NIVES, CLERK)
			var rule := rule_words(e)
			if rule != "":
				await Ui.say([rule], NIVES, CLERK)
			await Ui.say(["L'avevo letto due volte. Per sicurezza."], NIVES, CLERK)
		"A3":
			await Ui.say(["Eri rimasto lassù."], NIVES, CLERK)
			await _me("A fare cosa?")
			await Ui.say(["Il responsabile.", "Non ho saputo come sarebbe andata a finire.", "Mi era rimasta la curiosità."], NIVES, CLERK)
		"B1":
			await Ui.say(["Te n'eri andato."], NIVES, CLERK)
			await _me("Dove?")
			await Ui.say(["Questo non lo so.", "Mi fa piacere vederti.", "Peccato per il posto."], NIVES, CLERK)
		"B2":
			await Ui.say(["Te n'eri andato. Ma qualcuno aveva ancora un modo per cercarti."], NIVES, CLERK)
			await _me("E mi ha cercato?")
			await Ui.say(["Quella parte la sai tu.", "Spero di sì."], NIVES, CLERK)
		"C1":
			await Ui.say(["Andavo alle riunioni."], NIVES, CLERK)
			await _me("Tu?")
			await Ui.say(["Dicevo che era per il caffè."], NIVES, CLERK)
			await _me("Era buono?")
			await Ui.say(["Terribile.", "Ci andavo lo stesso."], NIVES, CLERK)
		"C2":
			await Ui.say(["Avevo una sedia al tavolo."], NIVES, CLERK)
			await _me("Che tavolo?")
			await Ui.say(["Quello dove si decideva.", "All'inizio alzavo la mano anche per chiedere il caffè.", "Poi avevo imparato."], NIVES, CLERK)
		"C3":
			await Ui.say(["Avevate cominciato qualcosa."], NIVES, CLERK)
			await _me("Aveva funzionato?")
			await Ui.say(["Non ancora.", "Mi ricordo soprattutto quella parola. Ancora."], NIVES, CLERK)


## A2: la regola adottata davvero in quella partita (se il ricordo non la sa, niente riga).
static func rule_words(e: Dictionary) -> String:
	match str(e.get("debt_rule", "")):
		"interessi":
			return "Gli interessi erano scesi. Allo zero virgola cinque."
		"revisione":
			return "I debiti senza firma si ricontrollavano. Uno per uno."
		"alternative":
			return "Le consegne, gli ordini, la Casa: pagavano loro una parte, al posto degli interessi."
	if bool(e.get("wages_up", false)):
		return "Gli stipendi erano saliti."
	if bool(e.get("services_up", false)):
		return "I servizi funzionavano meglio."
	return ""


# --- 6. più finali diversi ---------------------------------------------------------------------------

## Mezza frase per ogni finale: "Una volta …", "Un'altra volta …". Solo cose già dette nei ricordi.
const ONCE := {
	"A1": "eri il Direttore.",
	"A2": "avevi cambiato una regola. Anche per chi doveva seguirla.",
	"A3": "eri rimasto lassù, al telefono.",
	"B1": "te n'eri andato.",
	"B2": "te n'eri andato, ma qualcuno poteva cercarti.",
	"C1": "andavo alle riunioni. Per il caffè, dicevo.",
	"C2": "avevo una sedia dove potevo risponderti.",
	"C3": "avevate cominciato qualcosa.",
}


## La domanda del protagonista ("Quale delle due volte ti ricordi?") è la scelta allo sportello.
static func two_times_ask() -> String:
	return "Quale delle due volte ti ricordi?" if distinct().size() == 2 else "Quale delle volte ti ricordi?"


static func two_times() -> void:
	_mark("due_volte")
	var vs := distinct()
	var two := vs.size() == 2
	await Ui.say(["Tutte e due." if two else "Tutte."], NIVES, CLERK)
	await _me("Ma sono successe cose diverse.")
	await Ui.say(["Lo so. È la parte scomoda."], NIVES, CLERK)
	var a := str(vs[vs.size() - 2])
	var b := str(vs[vs.size() - 1])
	await Ui.say(["Una volta " + str(ONCE.get(a, "")), "Un'altra volta " + str(ONCE.get(b, ""))], NIVES, CLERK)
	await _me("E io quale sono?")
	await Ui.say(["Oggi sei qui davanti.", "Il resto non è ancora successo."], NIVES, CLERK)


# --- 5. cambiare comportamento ------------------------------------------------------------------------

## Prima un opportunista, adesso aiuti (e nessuno è diventato un robot per te in questa partita).
static func _now_helping() -> bool:
	return str(last().get("past", "")) == "opportunista" and GameState.exploited == 0 and GameState.helped_ids.size() >= 2


## Prima solidale, adesso hai fatto del male a qualcuno davvero: un robot, o Olga ingannata (non una risposta brusca).
static func _now_harming() -> bool:
	return str(last().get("past", "")) == "solidale" and (GameState.exploited > 0 or Storia.olga_torto_aperto())


static func _olga_withdrawn() -> bool:
	return Storia.olga_ingannata() and bool(GameState.flags.get("c4_olga_corretta", false))


# --- allo sportello: un ricordo per volta ------------------------------------------------------------

## Da chiamare all'inizio di ogni dialogo allo sportello dei badge (dal Fondo in su).
## Al massimo una cosa per visita. Quelle facoltative si possono saltare: poi non tornano più.
static func at_booth(who: String) -> void:
	# reazioni: le dice lei, una volta per partita
	if _olga_withdrawn() and not _done("olga"):
		_mark("olga")
		await Ui.say(["Ho saputo che hai ritirato la proposta."], who, CLERK)
		await _me("Basta?")
		await Ui.say(["Questo devi chiederlo a Olga."], who, CLERK)
		return
	if returning() and _now_harming() and not _done("danno"):
		_mark("danno")
		await Ui.say(["Mi ricordo che sapevi fare anche diversamente."], who, CLERK)
		await _me("Allora perché non mi hai fermato?")
		await Ui.say(["Ricordare non mi dà il controllo delle tue mani."], who, CLERK)
		return
	if returning() and _now_helping() and not _done("fiducia") and _done("ricordo"):
		_mark("fiducia")
		await Ui.say(["* L'addetta ti guarda un momento più del solito."])
		await _me("Non ti fidi?")
		await Ui.say(["Mi ricordo quello che hai fatto.", "Sto guardando anche quello che fai adesso."], who, CLERK)
		return
	# facoltative: una domanda in più tra le scelte
	var key := ""
	var ask := ""
	if can_reveal() and GameState.floor_id in ["-2", "0"]:
		key = "rivelazione"
		ask = REVEAL_ASK
	elif returning() and (_done("ritorno") or GameState.floor_id != "-5") and not _done("ricordo"):
		key = "ricordo"
		ask = "Ti ricordi di me?"
	elif distinct().size() >= 2 and _done("ricordo") and not _done("due_volte"):
		key = "due_volte"
		ask = two_times_ask()
	# chiesta o saltata, la domanda non torna più (né qui né ai piani dopo)
	if key == "" or _done("salta_%s" % key):
		return
	_mark("salta_%s" % key)
	var c: int = await Ui.choose("", [ask, "Niente, grazie."], who)
	if c != 0:
		return
	match key:
		"rivelazione":
			await revelation()
		"ricordo":
			await recall()
		"due_volte":
			await two_times()


# --- 7. l'epilogo di Nives ----------------------------------------------------------------------------

static func epilogue(out: Dictionary) -> void:
	if not returning():
		return
	await Ui.say(["Questa me la ricorderò."], NIVES)
	await _me("Anche se ricomincio?")
	await Ui.say(["Anche."], NIVES)
	await Ui.say(["* Nives torna al tavolo condiviso." if str(out.get("variant", "")) == "C2" else "* Nives torna al banco dei badge."])
