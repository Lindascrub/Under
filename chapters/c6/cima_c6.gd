extends EditorRoom
## Capitolo 6 — La Cima. La scena è fatta col bake (cima.tscn): qui c'è solo la logica.
## "Finalmente puoi decidere. Ma per chi?"
##   6.01 l'ascensore degli specchi      6.02 la Presidente (e lo zucchero)
##   6.03 OBBLIGO DI ESISTENZA            6.04 l'offerta: il debito annullato, in cambio della Torre
##   TURNO di Direzione, tre cicli (direzione.tscn), con la consultazione degli abitanti dopo ognuno
##   6.08 l'ultima telefonata del Capo    6.09 cosa fare della Torre (scelta + conferma)
##   la finestra panoramica: l'ultimo sguardo indietro, su tutti i piani (facoltativo)
## Poi finale.tscn: il finale, sei mesi dopo, il sogno, i titoli di coda.
## Stato: GameState.flags["chapter_6"] (schema in defaults(); documentato in docs/CHAPTER_06_SUMMIT.md).

const RULES := preload("res://chapters/c6/direzione_regole.gd")
const FINALI := preload("res://chapters/c6/finali.gd")
const C5 := preload("res://chapters/c5/citta_c5.gd")
const DIREZIONE := "res://chapters/c6/direzione.tscn"
const FINALE := "res://chapters/c6/finale.tscn"
const ART := "res://art/c6/"
const PRES := "La Presidente"
const PRES_SHEET := "char_20"
const BOSS := "Il Capo"
const BOSS_SHEET := "char_18"
const LIFT := "Ascensore"
const VOICE := "Voce CHEAP"
const PRES_DESK := Vector2i(23, 6)
const PRES_TABLE := Vector2i(24, 10)
const BOSS_CELL := Vector2i(17, 8)
const FLOORS := [
	["-5", "IL FONDO", ["fermo", "bulbo", "mina"]],
	["-4", "IL SOTTOUFFICIO", ["tilde", "ercole"]],
	["-3", "IL MERCATO", ["leda", "amir"]],
	["-2", "LA BANCA", ["olga", "teo"]],
	["0", "LA CITTÀ", ["ada", "nadir", "rina"]],
]

var president: CharSprite
var boss: CharSprite


# --- lo stato del capitolo ---------------------------------------------------------------------------

static func defaults() -> Dictionary:
	return {
		"entered": false, "completed": false,
		"elevator": {"intro_seen": false, "answer": null},
		"president": {"met": false, "origin_explained": false, "debt_contract_read": false, "offer_received": false, "first_wish": null},
		"director_turn": {"cycle_1_completed": false, "cycle_2_completed": false, "cycle_3_completed": false,
			"consulted_citizens": false, "decisions": [], "consulted": [], "state": {}, "casa_call_seen": false},
		"boss": {"final_call_seen": false, "global_credit_offer_resolved": false, "global_credit_accepted": false},
		"panorama": {"locations_seen": []},
		"final_decision": {"selected": null, "confirmed": false, "roles": {}},
		"outcome": {"family": null, "variant": null, "debt_status": null, "governance_status": null},
		"epilogue": {"started": false, "seen_character_ids": [], "completed": false, "step": 0},
		"dream": {"selected": null, "final_scene_seen": false},
		"debt_cancelled": false, "coffee": 0,
	}


static func _fill(d: Dictionary, defs: Dictionary) -> void:
	for k: String in defs:
		var v: Variant = defs[k]
		var missing := not d.has(k) or (d[k] == null and typeof(v) == TYPE_DICTIONARY)
		if missing:
			d[k] = v.duplicate(true) if typeof(v) in [TYPE_DICTIONARY, TYPE_ARRAY] else v
		elif typeof(v) == TYPE_DICTIONARY and typeof(d[k]) == TYPE_DICTIONARY and not (v as Dictionary).is_empty():
			_fill(d[k], v)


## Lo stato del capitolo 6, sempre completo (anche da un salvataggio vecchio o a metà).
static func c6() -> Dictionary:
	var d: Dictionary = GameState.flags.get("chapter_6", {})
	_fill(d, defaults())
	GameState.flags["chapter_6"] = d
	return d


static func _f(key: String) -> bool:
	return bool(GameState.flags.get(key, false))


static func cycles_done() -> int:
	var dt: Dictionary = c6()["director_turn"]
	var n := 0
	for i in range(1, 4):
		if dt.get("cycle_%d_completed" % i, false):
			n += 1
	return n


## Si può fare l'ultima scelta: tre cicli, il Capo, e almeno una testimonianza ascoltata.
static func final_ready() -> bool:
	var d := c6()
	return cycles_done() == 3 and bool(d["boss"]["final_call_seen"]) and bool(d["director_turn"]["consulted_citizens"]) \
		and not bool(d["final_decision"]["confirmed"])


# --- la stanza ---------------------------------------------------------------------------------------

func setup() -> void:
	var d := c6()
	if d["final_decision"]["confirmed"]:
		return
	var at := PRES_TABLE if bool(d["boss"]["final_call_seen"]) else PRES_DESK
	president = _person("Presidente", PRES_SHEET, at, "idle_left", talk_president, true)


func enter() -> void:
	var d := c6()
	if d["final_decision"]["confirmed"]:
		# la scelta è già fatta: niente stati a metà, si va al finale
		while Ui.transitioning:
			await get_tree().process_frame
		Router.goto(FINALE)
		return
	d["entered"] = true
	if not d["elevator"]["intro_seen"]:
		await _elevator()
	await show_pending()
	var dt: Dictionary = d["director_turn"]
	if dt.has("pending") and dt["pending"] != null:
		var n := int(dt["pending"])
		dt["pending"] = null
		await _after_cycle(n)
	if cycles_done() == 3 and not d["boss"]["final_call_seen"]:
		await _boss_scene()


## Alla Cima il vecchio capo non telefona: il Capo arriva di persona, una volta sola (6.08).
func _boss_call() -> void:
	GameState.flags["boss_call_done_%d" % GameState.day] = true


func _person(nm: String, sheet: String, cell: Vector2i, anim: String, action: Callable, grey := true) -> CharSprite:
	var c := CharSprite.new()
	c.name = nm
	c.sheet = sheet
	c.anim = anim
	c.grey = grey
	c.position = cell_feet(cell)
	world.add_child(c)
	block(Rect2i(cell, Vector2i.ONE))
	var spot := add_spot(cell_center(cell), action)
	c.set_meta("spot", spot)
	c.set_meta("cell", cell)
	return c


func _remove(c: CharSprite) -> void:
	if not is_instance_valid(c):
		return
	var spot: Node = c.get_meta("spot", null)
	if is_instance_valid(spot):
		spot.queue_free()
	unblock(Rect2i(c.get_meta("cell", Vector2i.ZERO), Vector2i.ONE))
	c.queue_free()


# --- 6.01 l'ascensore --------------------------------------------------------------------------------

## Le persone che hai incontrato, com'erano l'ultima volta: per lo specchio e per il panorama.
static func person_line(id: String) -> String:
	var who := str(GameState.npc_data(id).get("name", id.capitalize()))
	if GameState.is_robot(id):
		return "%s, con l'antenna. Sorride. È sempre stato così, dice il riflesso." % who
	if id in GameState.freed:
		return "%s, fuori dal lavoro. Non è dove l'avevi lasciato." % who
	if id in GameState.helped_ids:
		return "%s, grigio come allora. Ti riconosce." % who
	return "%s, grigio, che aspetta il suo turno." % who


func _elevator() -> void:
	var d := c6()
	Ui.cutscene = true
	Sound.sfx("ding")
	await Ui.say(["* Un ascensore dorato. Nessun pulsante.", "* Un'insegna: NON DEVI PIÙ SALIRE. SEI ARRIVATO."])
	await Ui.say(["* Compare uno specchio. Dentro ci sei tu.",
		"* Sotto il riflesso, una riga: DEBITO ATTUALE: %s." % GameState.euros(GameState.debt)])
	await Ui.say(["Complimenti per il suo percorso.", "Ha dimostrato determinazione.", "Resistenza.",
		"E una notevole disponibilità a ripetere operazioni.", "Qualità molto apprezzate."], LIFT)
	var met: Array = []
	for f: Array in FLOORS:
		for id: String in f[2]:
			if FINALI.met(id):
				met.append(id)
	var layer := _mirror_layer(met)
	if met.is_empty():
		await Ui.say(["* Nello specchio, dietro di te, non c'è nessuno. Sei salito senza voltarti."])
	else:
		var lines: Array = ["* Nello specchio, dietro di te, compaiono delle persone."]
		for id: String in met:
			lines.append("* " + person_line(id))
		await Ui.say(lines)
	var c: int = await Ui.choose("HAI TROVATO QUELLO CHE CERCAVI?", ["Non ancora.", "Non lo so.", "Voglio soltanto finire."], LIFT)
	d["elevator"]["answer"] = ["non_ancora", "non_so", "finire"][c]
	await Ui.say(["Risposta registrata.", "Non utilizzata."], LIFT)
	if is_instance_valid(layer):
		layer.queue_free()
	Sound.sfx("door")
	d["elevator"]["intro_seen"] = true
	Ui.cutscene = false


## Lo specchio: le persone incontrate, una accanto all'altra. Robot colorati con l'antenna, persone grigie.
func _mirror_layer(ids: Array) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 12
	add_child(layer)
	var frame := ColorRect.new()
	frame.color = Color("bedcf0")
	frame.position = Vector2(170, 40)
	frame.size = Vector2(300, 110)
	layer.add_child(frame)
	var inner := ColorRect.new()
	inner.color = Color("1a1420")
	inner.position = Vector2(176, 46)
	inner.size = Vector2(288, 98)
	layer.add_child(inner)
	var n := ids.size()
	for i in n:
		var id: String = ids[i]
		var s := CharSprite.new()
		s.sheet = str(GameState.npc_data(id).get("sheet", "char_02"))
		s.anim = "idle_down"
		s.grey = not GameState.is_robot(id)
		s.scale = Vector2(2, 2)
		s.position = Vector2(176 + (i + 0.5) * 288.0 / maxi(n, 1), 136)
		layer.add_child(s)
		if GameState.is_robot(id):
			C5._antenna(s)
	return layer


func _specchio_ascensore() -> void:
	await Ui.say(["* Lo specchio. DEBITO ATTUALE: %s." % GameState.euros(GameState.debt),
		"* Ti guardi. Sembri più vecchio di quando sei sceso con l'ascensore, il primo giorno. Forse è la luce."])


## Il corridoio: tre specchi, tre tratti di salita.
func _mirror(floors: Array, empty: String) -> void:
	var lines: Array = []
	for f: Array in FLOORS:
		if not str(f[0]) in floors:
			continue
		for id: String in f[2]:
			if FINALI.met(id):
				lines.append("* " + person_line(id))
	await Ui.say(lines if not lines.is_empty() else [empty])


func _specchio_0() -> void:
	await _mirror(["-5", "-4"], "* Nello specchio, il Fondo e il Sottoufficio. Una dinamo, un timbro. Nessuna faccia: non ti eri fermato.")


func _specchio_1() -> void:
	await _mirror(["-3", "-2"], "* Nello specchio, il Mercato e la Banca. Prezzi e sportelli. Nessuna faccia che ricordi.")


func _specchio_2() -> void:
	await _mirror(["0"], "* Nello specchio, la piazza. Il cartellone PREMIUM. Il cielo, per un momento.")


# --- 6.02-6.04 la Presidente -------------------------------------------------------------------------

func talk_president() -> void:
	var d := c6()
	if not d["president"]["met"]:
		await _president_first()
	elif final_ready():
		await final_choice()
	elif cycles_done() == 3 and not d["boss"]["final_call_seen"]:
		await _boss_scene()
	else:
		await _president_menu()


func _president_first() -> void:
	var d := c6()
	Ui.cutscene = true
	await Ui.say(["* Una stanza enorme, quasi vuota. Una signora anziana, grigia, con una giacca semplice.",
		"* Sta cercando di aprire una bustina di zucchero."])
	Sound.sfx("strap")
	await Ui.say(["* STRAP.", "* Lo zucchero cade sul pavimento lucidato."])
	await Ui.say(["Accidenti.", "Oh.", "Sei già qui.", "Pensavo ci volesse più tempo."], PRES)
	var c: int = await Ui.choose("Cosa rispondi?", ["È stato difficile.", "(Non dire niente)"], PRES)
	if c == 0:
		await Ui.say(["Immagino.", "Per questo di solito non scendo."], PRES)
	d["president"]["met"] = true
	await Ui.say(["Allora.", "Sei arrivato.", "Cosa desideri?"], PRES)
	var w: int = await Ui.choose("Cosa desideri?", ["Cancellare il mio debito.", "Sapere perché ho un debito.", "Cambiare le cose.", "Non lo so."], PRES)
	d["president"]["first_wish"] = ["cancellare", "origine", "cambiare", "non_so"][w]
	match w:
		0:
			await Ui.say(["Certamente.", "È molto semplice.", "Ma prima guarda questa. Così sai cosa cancello."], PRES)
		1:
			await Ui.say(["Ah.", "Questa è una domanda meno comune."], PRES)
		2:
			await Ui.say(["Bene.", "Allora forse ti interesserà il mio lavoro.", "Ma prima devi sapere da dove viene il tuo debito. È lì che comincia tutto."], PRES)
		_:
			await Ui.say(["Capisco.", "Ti assicuro che capita anche qui.", "Intanto guarda questa."], PRES)
	await read_contract()
	await _origin()
	await _offer()
	Ui.cutscene = false


## 6.03 Il fascicolo: tre sezioni da toccare. L'importo originario non è il debito di adesso.
func read_contract() -> void:
	var d := c6()
	Sound.sfx("flap")
	await Ui.say(["* La Presidente apre un cassetto ed estrae una cartellina rosa.",
		"* OBBLIGO DI ESISTENZA. IMPORTO ORIGINARIO: 7.000.000.000 €."])
	var seen: Array = []
	while true:
		var opts: Array = []
		for i in 3:
			opts.append(("✓ " if i in seen else "") + ["1. Registrazione", "2. Importo", "3. Consenso"][i])
		opts.append("Chiudi la cartellina")
		var c: int = await Ui.choose("OBBLIGO DI ESISTENZA — tocca una sezione.", opts)
		if c == 3:
			break
		if not c in seen:
			seen.append(c)
		match c:
			0:
				await Ui.say(["* SEZIONE 1 — REGISTRAZIONE.", "* Titolare: {name}.",
					"* Data di apertura: precedente alla registrazione del titolare.", "* Causale: obbligo di esistenza.",
					"* Il soggetto viene registrato come beneficiario dei servizi generali della Torre."])
			1:
				await Ui.say(["* SEZIONE 2 — IMPORTO.", "* Importo originario: 7.000.000.000 €.",
					"* Criterio: quota standard di partecipazione al sistema.",
					"* L'importo non deriva da un acquisto volontario.",
					"* (A matita, in fondo: SALDO ATTUALE DOPO PAGAMENTI E INTERESSI: %s.)" % GameState.euros(GameState.debt)])
			2:
				await Ui.say(["* SEZIONE 3 — CONSENSO.", "* Firma del titolare: non presente.", "* Consenso individuale: non registrato.",
					"* Stato pratica: attiva.", "* Il regolamento interno considera valida la registrazione anche senza firma."])
		if seen.size() == 3:
			break
	if seen.size() == 3:
		d["president"]["debt_contract_read"] = true
		GameState.flags["c6_contratto_letto"] = true


func _origin() -> void:
	var d := c6()
	await Ui.say(["Non hai preso in prestito sette miliardi.", "Ti sono stati assegnati."], PRES)
	if _f("c4_anomalia") or _f("c4_rivelazione"):
		await Ui.say(["* Alla Banca il contratto originale non c'era. Ora sai perché: non c'è mai stato."])
	var c: int = await Ui.choose("Cosa chiedi?", ["Perché?", "(Restare in silenzio)"])
	if c == 0:
		await Ui.say(["Quando la Torre è stata costruita, bisognava trovare un modo per farla funzionare.",
			"Servivano energia, amministrazione, merci, crediti, manutenzione.",
			"Ogni nuovo abitante veniva registrato come beneficiario di tutto questo.", "E gli veniva assegnata una quota."], PRES)
	var asked: Array = []
	while asked.size() < 3:
		var opts: Array = ["Ma non l'ho mai accettata.", "Chi ha deciso la cifra?", "Quindi non devo niente?", "Basta così."]
		var q: int = await Ui.choose("Cosa chiedi?", opts)
		if q == 3:
			break
		if not q in asked:
			asked.append(q)
		match q:
			0:
				await Ui.say(["Non risulta.", "Ma il sistema registra comunque la quota."], PRES)
			1:
				await Ui.say(["Il primo Consiglio.", "Poi il secondo l'ha aggiornata.", "Il terzo ha introdotto gli interessi.",
					"Il quarto ha migliorato il logo.", "Quello è stato molto costoso."], PRES)
			2:
				await Ui.say(["Secondo il regolamento della Torre, sì.", "Se mi chiedi se sia giusto…",
					"Questa è una decisione che il regolamento non sa prendere."], PRES)
	d["president"]["origin_explained"] = true


## 6.04 L'offerta: presentata adesso, decisa alla fine. Il debito non si tocca ancora.
func _offer() -> void:
	var d := c6()
	await Ui.say(["Comunque.", "Posso cancellarlo."], PRES)
	await _stamp_preview()
	await Ui.choose("Cosa dici?", ["Cosa dovrei fare in cambio?", "(Aspettare)"])
	await Ui.say(["Diventare il nuovo responsabile della Torre.", "Io vorrei andare in pensione.", "Prenderai alcune decisioni.",
		"Approverai i bilanci.", "Gestirai gli stipendi.", "E naturalmente i debiti.", "Il tuo verrà azzerato."], PRES)
	var o: int = await Ui.choose("Cosa dici?", ["E gli altri?", "(Non chiedere)"])
	if o == 0:
		await Ui.say(["Gli altri resteranno registrati.", "Altrimenti chi farebbe funzionare la Torre?"], PRES)
	d["president"]["offer_received"] = true
	await Ui.say(["Non devi rispondere adesso. Il timbro aspetta. È abituato.",
		"Prima di decidere, vuoi vedere come funziona il mio lavoro?"], PRES)
	var t: int = await Ui.choose("Vuoi vedere come funziona?", ["Sì, fammi vedere.", "Non adesso."], PRES)
	if t == 0:
		await Ui.say(["La scrivania è quella. Si chiama TURNO anche qui. Mi dispiace: il nome l'ha scelto il quarto Consiglio."], PRES)
		await start_cycle()
	else:
		await Ui.say(["La scrivania è lì. Quando vuoi.", "Puoi anche guardare dalla finestra. Da qui si vede tutto. È il problema."], PRES)


## Il timbro DEBITO ANNULLATO, mostrato e rimesso nel cassetto.
func _stamp_preview() -> void:
	Sound.sfx("stamp", 0.8)
	var layer := CanvasLayer.new()
	layer.layer = 12
	add_child(layer)
	var s := TextureRect.new()
	s.texture = load(ART + "timbro_annullato.png")
	s.position = Vector2(272, 120)
	s.scale = Vector2(1.0, 1.0)
	layer.add_child(s)
	await Ui.say(["* La Presidente prende un timbro: DEBITO ANNULLATO. Lo tiene sospeso sopra la cartellina.", "* Non timbra."])
	layer.queue_free()


func _president_menu() -> void:
	var d := c6()
	var opts: Array = ["Come funziona il tuo lavoro?", "Il debito, ancora.", "Perché vuoi andare in pensione?", "Niente."]
	var c: int = await Ui.choose("Sì?", opts, PRES)
	match c:
		0:
			if cycles_done() < 3:
				await Ui.say(["Tre cicli di bilancio. Cento unità ogni volta. Nessuno è contento, alla fine. È così che capisci che hai finito.",
					"La scrivania è lì." if cycles_done() == 0 else "Ne mancano %d." % (3 - cycles_done())], PRES)
			else:
				await Ui.say(["L'hai visto. Più o meno è tutto qui.", "Il resto sono telefonate."], PRES)
		1:
			if not d["president"]["debt_contract_read"]:
				await Ui.say(["Vuoi rileggere la cartellina? Prego. Io la so a memoria."], PRES)
				await read_contract()
			else:
				await Ui.say(["Sette miliardi assegnati. %s adesso." % GameState.euros(GameState.debt),
					"La differenza l'hai pagata tu, o l'hanno fatta gli interessi. Il timbro, intanto, è nel cassetto."], PRES)
		2:
			await Ui.say(["Ho cominciato ad aprire bustine di zucchero e a sbagliare.", "Quando sbagli le cose piccole, è ora di lasciare quelle grandi.",
				"Oppure di cambiare zucchero."], PRES)


# --- il TURNO di Direzione ---------------------------------------------------------------------------

func _scrivania() -> void:
	var d := c6()
	if not d["president"]["offer_received"]:
		await Ui.say(["* Una scrivania enorme. Sopra: una cartellina rosa e una bustina di zucchero vuota.", "* Non è tua. Non ancora."])
		return
	if cycles_done() >= 3:
		await Ui.say(["* Lo schermo del TURNO. Tre cicli chiusi. In basso lampeggia: NESSUNA DECISIONE IN ATTESA.",
			"* È la prima volta che lo leggi. Non sembra vero."])
		return
	var n := cycles_done() + 1
	var c: int = await Ui.choose("TURNO — DIREZIONE. Cominciare il ciclo %d di 3?" % n, ["Comincia.", "Non ancora."])
	if c == 0:
		await start_cycle()


func start_cycle() -> void:
	var n := cycles_done() + 1
	if n > 3:
		return
	if n == 2 and not c6()["director_turn"]["casa_call_seen"]:
		await _casa_call()
	GameState.minigame = {"cycle": n}
	Router.goto(DIREZIONE)


## Prima del ciclo 2: la Casa Comune chiede di partecipare. Ada, se è ancora Ada; altrimenti chi c'è.
func _casa_call() -> void:
	var d := c6()
	d["director_turn"]["casa_call_seen"] = true
	Sound.sfx("blip")
	await Ui.say(["* Sul terminale, una chiamata dalla Casa Comune."])
	if FINALI.met("ada") and not GameState.is_robot("ada"):
		await Ui.say(["Ciao. Sono io.", "Non voglio che tu decida tutto al posto nostro.",
			"Vorrei almeno poter partecipare a una decisione che riguarda il luogo dove studio."], "Ada")
	else:
		var who := "Uno studente della Casa Comune"
		if GameState.is_robot("ada"):
			await Ui.say(["* Dietro di lui, in fondo alla sala, Ada sistema le sedie. Sempre nello stesso ordine."])
		await Ui.say(["Salve. Ci hanno detto che adesso decide lei. O che decide qualcuno, comunque.",
			"Non vogliamo che decida tutto al posto nostro.", "Vorremmo almeno partecipare a una decisione che riguarda il posto dove studiamo."], who)
	await Ui.say(["Tecnicamente hai appena chiesto di complicare una procedura.", "Ma ammetto che è una procedura importante."], PRES)


func _after_cycle(n: int) -> void:
	var sm := RULES.summary(FINALI.turn_state())
	match n:
		1:
			await Ui.say(["Hai deciso?", "Bene.", "Ora qualcuno sarà contento.", "Qualcun altro ha già chiamato."], PRES)
		2:
			await Ui.say(["La Casa Comune ha già risposto. Con una lettera. Scritta a mano: fa sempre effetto." if RULES.casa_open(str(sm["casa"])) \
				else "La Casa Comune non ha risposto. Anche questo è una risposta.", "Avanti."], PRES)
		3:
			if str(sm["debt_rule"]) != "conservare":
				await Ui.say(["Interessante.", "Non ricordo l'ultima volta che qualcuno ha cambiato davvero questa schermata."], PRES)
			else:
				await Ui.say(["Come sempre.", "Funziona. Per qualcuno funziona benissimo."], PRES)
	await consult(n, n == 3)


# --- la consultazione degli abitanti -----------------------------------------------------------------

## Chi si può ascoltare dopo il ciclo n: [id, etichetta, righe]. Robot e sconosciuti non parlano da persone.
## C'è sempre almeno una voce (un'impiegata del -4), così la scelta finale non resta mai senza testimonianze.
static func consultations(n: int) -> Array:
	var sm := RULES.summary(FINALI.turn_state())
	var out: Array = []
	var nm := func(id: String) -> String: return str(GameState.npc_data(id).get("name", id.capitalize()))
	for id: String in ["amir", "leda", "teo", "olga", "nadir", "ada", "rina", "tilde", "bulbo", "fermo"]:
		if not FINALI.met(id) or id in GameState.freed:
			continue
		if GameState.is_robot(id):
			out.append([id, "%s (robot)" % nm.call(id), ["CONSULTAZIONE RICEVUTA. È TUTTO PERFETTO.", "GRAZIE PER LA DOMANDA. NON SERVIVA."]])
			continue
		var lines := _testimony(id, n, sm)
		if not lines.is_empty():
			out.append([id, nm.call(id), lines])
	out = out.slice(0, 5)
	out.append(["impiegata", "Un'impiegata del -4", _clerk(n, sm)])
	return out


static func _testimony(id: String, n: int, sm: Dictionary) -> Array:
	var helped: bool = id in GameState.helped_ids
	match id:
		"amir":
			if n == 1:
				return ["Al -3 il pane è passato da 18 a 25.", "Un aumento sotto i 55 non arriva a fine mese. Arriva a metà, e lì si ferma."] if not sm["wages_cover"] \
					else ["Ho fatto i conti. Questo mese arrivo alla fine.", "Non mi era mai successo di avere una fine del mese da raggiungere."]
			return ["Gli stipendi sono quelli che sono. Ma il mio quaderno di ricette si sta riempiendo."] if not sm["wages_up"] \
				else ["Con l'aumento ho comprato una padella vera. Pesante. Si sente che è una decisione."]
		"leda":
			if sm["wages_cover"]:
				return ["Questo mese la fattura l'ho pagata il giorno giusto.", "Mi sono sentita ricca per mezz'ora."]
			if helped:
				return ["Mi hai dato una mano. Lo so.", "Ma domani arriva un'altra fattura."]
			return ["Il negozio è aperto. Per adesso basta questo."]
		"teo":
			if n == 1:
				return ["Ogni aumento passa da tre uffici. Una volta dato, non si toglie: i contratti non tornano indietro.",
					"E guarda la manutenzione. Al -2 il marmo è lucido e l'ascensore merci è rotto da un anno. Indovina perché."]
			if n == 2:
				return ["Per toccare i debiti servono prove. Il regolamento non ascolta le opinioni: ascolta i fogli.",
					"Se hai visto le carte della Banca, tienile a portata di mano."]
			return ["Le procedure si possono cambiare. Non è difficile. È solo che nessuno ci prova."] if str(sm["debt_rule"]) == "conservare" \
				else ["Ho cominciato a ricontrollare le pratiche sospese. Una per una. È noioso. Mi piace."]
		"olga":
			if n == 3 and str(sm["debt_rule"]) in ["revisione", "interessi"]:
				return ["Ho ricevuto un'altra lettera.", "Questa volta non mi chiedevano soldi.", "L'ho incorniciata."]
			return ["Se tocchi i debiti, guarda le commissioni. È lì che si nascondono i soldi che nessuno ha deciso di prendere."]
		"nadir":
			if n >= 2 and sm["services_up"]:
				return ["Oggi sono tornato a casa prima.", "Non sapevo cosa fare.", "Ho cucinato."]
			if sm["services_paid"]:
				return ["Il bus 12 adesso si paga a parte. Vado a piedi. Ho visto un merlo, almeno."]
			return ["Il tabellone dice sei minuti. Lo dice da tre settimane.", "Se i servizi restano così, la rete dei pendolari serve più di prima."]
		"ada":
			if n == 1:
				return ["Se tagli i servizi, la Casa Comune è la prima a sentirlo. Poi tutti gli altri, ma più piano."]
			return ["La Casa è aperta. Ho spostato il tavolo grande. Di nuovo. Ma stavolta l'abbiamo deciso in tre."] if RULES.casa_open(str(sm["casa"])) \
				else ["La Casa è chiusa. Studio sulle scale del palazzo. C'è un buon eco per ripetere."]
		"rina":
			if sm["services_paid"]:
				return ["Se i servizi diventano a pagamento, la gente compra meno. Anche da me. Soprattutto da me."]
			return ["La vetrina è a posto. La gente passa. Qualcuno compra. È tutto quello che chiedevo, più o meno."]
		"tilde":
			return ["Ogni regola nuova ha bisogno di un modulo. Ogni modulo di una regola.", "Io li tengo tutti e due. Qualcuno deve."]
		"bulbo":
			if n == 1:
				return ["La dinamo del Fondo consuma. La bolletta arriva sempre al secondo mese. Sempre. Mettiti da parte qualcosa."]
			return ["Al Fondo le luci tengono. Pedaliamo meno. Non chiedermi perché: non voglio portare sfortuna."] if sm["maintenance_ok"] \
				else ["Al Fondo sfarfallano le luci. Quando sfarfallano, prima o poi si spengono. Lo so per esperienza."]
		"fermo":
			return ["La festa continua. Non ci credo più tanto, ma continua.", "Se qualcuno cambia qualcosa lassù, giù lo sentiamo per ultimi. Ma lo sentiamo."]
	return []


static func _clerk(n: int, sm: Dictionary) -> Array:
	match n:
		1:
			return ["Le bollette della dinamo arrivano sempre al secondo ciclo. Lo sanno tutti tranne chi decide."]
		2:
			return ["Lo stipendio mi basta per arrivare a giovedì." if not sm["wages_up"] else "Lo stipendio arriva a venerdì, adesso. Il weekend è un'altra storia.",
				"La regola dei debiti la decidono sempre per ultima. Quando sono tutti stanchi."]
	return ["Qualunque cosa decida, scriva perché. Noi i perché non li riceviamo mai."]


## ASCOLTA GLI ABITANTI. Facoltativo dopo i primi due cicli; dopo il terzo almeno una voce (se non l'hai già fatto).
func consult(n: int, required := false) -> void:
	var d := c6()
	var dt: Dictionary = d["director_turn"]
	var people := consultations(n)
	var must: bool = required and not dt["consulted_citizens"]
	var heard: Array = []
	await Ui.say(["* ASCOLTA GLI ABITANTI."])
	while true:
		var opts: Array = []
		for p: Array in people:
			opts.append(("✓ " if p[0] in heard else "") + str(p[1]))
		if not must or not heard.is_empty():
			opts.append("Basta così.")
		var c: int = await Ui.choose("Chi ascolti?" if not must or not heard.is_empty() else "Prima di decidere, ascolta almeno una persona.", opts)
		if c >= people.size():
			break
		var p: Array = people[c]
		await Ui.say(p[2], str(p[1]))
		if not p[0] in heard:
			heard.append(p[0])
		dt["consulted_citizens"] = true
		var log: Array = dt["consulted"]
		if not "%d:%s" % [n, p[0]] in log:
			log.append("%d:%s" % [n, p[0]])


func _terminale() -> void:
	var d := c6()
	var st := FINALI.turn_state()
	if cycles_done() == 0:
		await Ui.say(["* BILANCIO DELLA TORRE. RISULTATO: CRESCITA POSITIVA.", "* Sotto, più piccolo: \"Per i dettagli, rivolgersi alla Presidenza.\""])
		return
	var sm := RULES.summary(st)
	await Ui.say(["* BILANCIO DELLA TORRE — %d CICLI SU 3." % cycles_done(),
		"* Riserve: %d. Arretrato di manutenzione: %d." % [int(st.get("reserve", 0)), int(st.get("backlog", 0))],
		"* Stipendi: %s. Servizi: %s." % [RULES.wage_label(int((st["log"] as Array).back()["alloc"]["stipendi"])), RULES.service_label(int((st["log"] as Array).back()["services_eff"]))]])
	if d["final_decision"]["confirmed"]:
		return
	var c: int = await Ui.choose("ASCOLTA GLI ABITANTI?", ["Sì.", "No."])
	if c == 0:
		await consult(cycles_done())


# --- 6.08 l'ultima offerta del Capo ------------------------------------------------------------------

func _boss_scene() -> void:
	var d := c6()
	if d["boss"]["final_call_seen"]:
		return
	Ui.cutscene = true
	Sound.sfx("drring")
	await Ui.say(["* DRRRRING."])
	boss = _person("Capo", BOSS_SHEET, BOSS_CELL, "idle_right", func() -> void: pass, true)
	await Ui.say(["* Il Capo entra dal corridoio degli specchi. Niente costume, niente colori. Una camicia stirata male."])
	await Ui.say(["Ehi.", "Guarda un po' dove sei arrivato."], BOSS)
	var r: int = await Ui.choose("Cosa rispondi?", ["Finalmente.", "Non grazie a te.", "Non so ancora cosa fare."], BOSS)
	if r == 1:
		await Ui.say(["Be', un pochino sì. Ma non stiamo a fare i conti. Cioè: io li faccio sempre. Ma non adesso."], BOSS)
	await Ui.say(["Sai, io ho sempre pensato che saresti arrivato qui.", "Be', non proprio sempre.",
		"All'inizio pensavo saresti rimasto sulla cyclette.", "Ma hai imparato."], BOSS)
	if GameState.exploited >= 3:
		await Ui.say(["Hai capito come funzionano le opportunità."], BOSS)
	elif GameState.exploited == 0:
		await Ui.say(["Hai preso la strada lunga.", "Dev'essere stato faticoso."], BOSS)
	else:
		await Ui.say(["Non sei stato molto prevedibile.", "Devo ammettere che questo mi ha complicato il lavoro."], BOSS)
	d["boss"]["final_call_seen"] = true
	await Ui.say(["Mi serve un ultimo favore.", "Puoi intestarti il lavoro di tutti gli abitanti della Torre.",
		"Un solo nome, un solo responsabile.", "Tu."], BOSS)
	while true:
		var c: int = await Ui.choose("ATTRIBUZIONE GLOBALE DEL CONTRIBUTO. LAVORATORI COINVOLTI: TUTTI. BENEFICIARIO: DIREZIONE.",
			["Autorizza.", "Rifiuta.", "Chiedi cosa comporta."])
		if c == 2:
			await Ui.say(["Niente di drammatico. Nessuno diventa un robot. Che idea.",
				"Semplicemente, d'ora in poi ogni lavoro della Torre porta un nome solo. Il tuo.",
				"I premi, i meriti, le trattative: si fanno con chi ha il nome. Gli altri lavorano. Come prima, ma senza firma."], BOSS)
			continue
		d["boss"]["global_credit_offer_resolved"] = true
		if c == 0:
			d["boss"]["global_credit_accepted"] = true
			Sound.sfx("stamp", 0.7)
			await Ui.say(["* ATTRIBUZIONE COMPLETATA.", "* Sui fogli di tutti i piani, le firme degli altri sbiadiscono. Resta la tua.",
				"* Nessuno diventa un robot. Nessuno se ne accorge, per ora. Chi chiederà un aumento, chiederà a te."])
		else:
			await Ui.say(["Peccato.", "Sarebbe stato comodissimo.", "Per te, intendo."], BOSS)
		break
	await Ui.say(["Comunque sia…", "È stato un piacere lavorare con te.", "O grazie a te."], BOSS)
	_remove(boss)
	Sound.sfx("door")
	# la Presidente va al tavolo: lì si decide
	_remove(president)
	president = _person("Presidente", PRES_SHEET, PRES_TABLE, "idle_left", talk_president, true)
	await Ui.say(["* La Presidente spegne il terminale e va al tavolo rotondo.", "Vieni, quando vuoi. Prima, se vuoi, guarda dalla finestra."], PRES)
	Ui.cutscene = false


# --- 6.09 cosa fare della Torre ----------------------------------------------------------------------

func _tavolo() -> void:
	if final_ready():
		await final_choice()
	else:
		await Ui.say(["* Un tavolo rotondo. Troppe sedie per due persone. Nessuna è più alta delle altre: l'unica cosa così, quassù."])


const CHOICES := ["A", "B", "C"]


func final_choice() -> void:
	var d := c6()
	if not final_ready():
		return
	await Ui.say(["Hai visto abbastanza.", "Adesso conosci i numeri.", "E forse conosci alcune persone meglio di me.", "Quindi dimmi.",
		"Cosa vuoi fare della Torre?"], PRES)
	while true:
		var c: int = await Ui.choose("Cosa vuoi fare della Torre?", ["Accetta la Direzione.", "Rifiuta l'incarico e lascia la Torre.",
			"Proponi di condividere le decisioni.", "Non ancora."], PRES)
		if c == 3:
			await Ui.say(["Prenditi il tempo che serve. Qui ce n'è fin troppo."], PRES)
			return
		var sel: String = CHOICES[c]
		d["final_decision"]["selected"] = sel
		match sel:
			"A":
				await Ui.say(["* Diventi responsabile della Torre. Il tuo debito personale viene cancellato.",
					"* Le decisioni dei tre cicli restano. Quelle dopo, le prendi tu."])
			"B":
				await Ui.say(["* Rifiuti l'incarico. Lasci la Torre.", "* Il debito resta registrato, o contestato se hai le prove per farlo."])
			"C":
				await Ui.say(["* Proponi che decida chi ci lavora. Non è detto che accettino.",
					"* Prima, una proposta concreta: chi si occupa di cosa."])
				await assign_roles()
		var k: int = await Ui.choose("Confermi? Dopo non si torna indietro.", ["Confermo.", "Ci ripenso."])
		if k == 0:
			await commit(sel)
			return
		d["final_decision"]["selected"] = null
		d["final_decision"]["roles"] = {}


## Finale C: chi si occupa dei conti, dei servizi, dei turni. Solo persone con cui hai un legame.
func assign_roles() -> void:
	var d := c6()
	var roles := {}
	for role: String in ["conti", "servizi", "turni"]:
		var cands := FINALI.candidates(role)
		var title: String = FINALI.ROLES[role]["name"]
		if cands.is_empty():
			await Ui.say(["* Per %s non ti viene in mente nessuno a cui chiederlo." % title.to_lower()])
			roles[role] = ""
			continue
		var opts: Array = []
		for id: String in cands:
			opts.append(str(GameState.npc_data(id).get("name", id)))
		opts.append("Nessuno, per ora.")
		var c: int = await Ui.choose("Chi si occupa di %s?" % title.to_lower(), opts)
		roles[role] = str(cands[c]) if c < cands.size() else ""
	d["final_decision"]["roles"] = roles


## La scelta conclusiva, registrata una volta sola. Il debito cambia qui, e solo qui.
func commit(sel: String) -> void:
	var d := c6()
	if d["final_decision"]["confirmed"]:
		return
	var out := FINALI.decide(sel)
	d["final_decision"]["selected"] = sel
	d["final_decision"]["confirmed"] = true
	d["outcome"] = out
	if out["family"] == "A" and not d["debt_cancelled"]:
		d["debt_cancelled"] = true
		d["debt_before"] = GameState.debt
		GameState.debt = 0
		GameState.changed.emit()
	Sound.sfx("stamp")
	GameState.save_game(FINALE)
	Router.goto(FINALE)


# --- l'ultimo sguardo indietro: la finestra panoramica -----------------------------------------------

static func panorama_lines(floor: String) -> Array:
	var f := GameState.flags
	var out: Array = []
	match floor:
		"-5":
			out.append("* Il Fondo. La festa finta continua: festoni, la dinamo, qualcuno che pedala.")
			if f.get("c1_rivelazione", false):
				out.append("* Le luci di giù si spengono quando quelle di su devono restare accese. Da qui si vede benissimo.")
		"-4":
			out.append("* Il Sottoufficio. Pile di moduli che salgono più in fretta di chiunque.")
			if f.get("c2_b4", false):
				out.append("* Il Modulo B-4 è ancora lì. Qualcuno l'ha incorniciato. Non per affetto.")
		"-3":
			out.append("* Il Mercato. Il tabellone dei prezzi cambia ogni minuto. Da quassù sembra un'insegna di Natale.")
			if f.get("c3_leda_ordini", false):
				out.append("* Un gruppetto davanti al negozio di Leda: gli ordini condivisi. Una fila che si muove.")
		"-2":
			out.append("* La Banca. Lo sportello, il numero che non cambia mai.")
			if f.get("c4_olga_contestazione", false):
				out.append("* Una contestazione affissa in bacheca. Qualcuno l'ha fotografata.")
		"0":
			out.append("* La Città. La piazza, il cartellone PREMIUM, la fermata.")
			match str(f.get("c5_esito", "")):
				"comunitaria":
					out.append("* La Casa Comune ha le finestre aperte. Sul portone, un foglio con i turni.")
				"riconversione":
					out.append("* La Casa Comune ha un tornello nuovo. Luccica.")
				_:
					out.append("* La Casa Comune ha ancora l'avviso sulla porta. Corretto a penna.")
	for fl: Array in FLOORS:
		if fl[0] == floor:
			for id: String in fl[2]:
				if FINALI.met(id):
					out.append("* " + person_line(id))
	return out


func _finestra() -> void:
	var d := c6()
	if d["final_decision"]["confirmed"]:
		return
	var layer := CanvasLayer.new()
	layer.layer = 11
	add_child(layer)
	var tower := TextureRect.new()
	tower.texture = load(ART + "torre_sezione.png")
	tower.position = Vector2(470, 8)
	tower.scale = Vector2(0.5, 0.5)
	layer.add_child(tower)
	await Ui.say(["* Dalla finestra si vede tutta la Torre, piano per piano. Da quassù le persone sembrano formiche.",
		"* Da quassù è facile dimenticare che non lo sono."])
	var seen: Array = d["panorama"]["locations_seen"]
	while true:
		var opts: Array = []
		for fl: Array in FLOORS:
			opts.append(("✓ " if fl[0] in seen else "") + str(fl[1]))
		opts.append("Basta guardare.")
		var c: int = await Ui.choose("Dove guardi?", opts)
		if c >= FLOORS.size():
			break
		var fl: Array = FLOORS[c]
		if not fl[0] in seen:
			seen.append(fl[0])
		await Ui.say(panorama_lines(str(fl[0])))
	layer.queue_free()


func _archivio() -> void:
	var d := c6()
	if not d["president"]["met"]:
		await Ui.say(["* ARCHIVIO DEL DEBITO. Accesso riservato alla Presidenza.", "* Il cassetto più basso è etichettato: {name}."])
		return
	await Ui.say(["* ARCHIVIO DEL DEBITO. Migliaia di cartelline rosa, una per abitante. Tutte senza firma.",
		"* Sono in ordine alfabetico. L'unica cosa in ordine, quassù."])
	if not d["president"]["debt_contract_read"]:
		var c: int = await Ui.choose("Leggi la tua cartellina?", ["Sì.", "No."])
		if c == 0:
			await read_contract()


func _caffe() -> void:
	var d := c6()
	d["coffee"] = int(d["coffee"]) + 1
	match int(d["coffee"]):
		1:
			await Ui.say(["* Una macchina del caffè. Premi il pulsante. Non succede niente."])
		2:
			Sound.sfx("thump", 1.2)
			await Ui.say(["* La colpisci una volta. Niente."])
		_:
			Sound.sfx("thump", 1.2)
			await Ui.say(["* La colpisci due volte. Caffè.", "* La Presidente, da lontano: \"Visto? Due volte.\""])
