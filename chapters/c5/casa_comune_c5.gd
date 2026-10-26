extends EditorRoom
## Capitolo 5 — dentro la Casa Comune. La scena è fatta nell'editor (casa_comune.tscn).
## A sinistra la sala (Ada, la libreria che la odia, la lettera di CHEAP, la bacheca);
## a destra l'archivio, aperto dal giorno della manifestazione: i bilanci, il documento nascosto,
## il contatore della rete della Torre. Le regole comuni del capitolo sono in citta_c5.gd.

const CITY_LOGIC := preload("res://chapters/c5/citta_c5.gd")
const ANTENNA := "res://art/c4/antenna_robot.png"
const EXIT := Rect2i(3, 11, 2, 1)


func setup() -> void:
	add_exit(EXIT, Router.CITY, "from_casa")
	if _f("c5_protesta"):
		var door := find_child("PortaArchivio", true, false)
		if door:
			door.queue_free()
	var ada := _npc("ada")
	if ada:
		if GameState.is_robot("ada"):
			CITY_LOGIC._antenna(ada)
		# il giorno della manifestazione Ada è in piazza
		if _f("c5_protesta") and not _f("c5_assemblea"):
			ada.visible = false
			ada.process_mode = Node.PROCESS_MODE_DISABLED
			ada.remove_from_group("interactable")


func enter() -> void:
	if not _f("c5_casa"):
		GameState.flags["c5_casa"] = true
		await Ui.say(["* Tavoli, libri, piante, sedie spaiate. Qualcuno studia, qualcuno compila un curriculum, qualcuno dorme sul braccio.",
			"* Si entra gratis. Lo dice un cartello scritto a mano. Sotto, un altro, stampato: CHIUSURA PREVISTA: FRA 3 GIORNI."])
	await show_pending()
	if Ui.transitioning:
		return
	if _f("c5_protesta") and not _f("c5_archivio_visto"):
		GameState.flags["c5_archivio_visto"] = true
		await Ui.say(["* La porta dell'ARCHIVIO è aperta. Un biglietto: \"Oggi assemblea. I conti sono di tutti.\""])


func _floor_gift() -> void:
	pass


static func _f(key: String) -> bool:
	return bool(GameState.flags.get(key, false))


func _npc(id: String) -> Npc:
	for n in get_tree().get_nodes_in_group("npc"):
		if n is Npc and (n as Npc).id == id and is_instance_valid(n):
			return n
	return null


# --- 5.02 / 5.03 Ada -----------------------------------------------------------------------------

func talk_ada(_npc_node: Npc) -> bool:
	if _f("c5_rivelazione"):
		return false
	if not _f("c5_ada"):
		await _ada_first()
	elif _f("c5_assemblea"):
		await Ui.say([_ada_after_assembly()], "Ada")
		return true
	await _ada_menu()
	return true


func _ada_first() -> void:
	var who := "Ada"
	GameState.flags["c5_ada"] = true
	GameState.flags["met_ada"] = true
	await Ui.say(["* Una ragazza con gli occhiali storti spinge una libreria con la spalla. La libreria vince."])
	await Ui.say(["Ehi!", "Sei alto?"], who)
	await Ui.choose("Cosa rispondi?", ["Abbastanza.", "Non particolarmente.", "Dipende rispetto a cosa."], who)
	await Ui.say(["Perfetto. Sei esattamente dell'altezza che mi serve."], who)
	Sound.sfx("thump")
	await Ui.say(["* THUMP. Un libro cade dall'ultimo ripiano."])
	await Ui.say(["Quella libreria mi odia."], who)
	await Ui.say(["* Sulla porta, un avviso: CHIUSURA PREVISTA: FRA 3 GIORNI."])
	await Ui.say(["Dicono che mantenere questo posto costa troppo.", "Il problema è che non sappiamo dove andare.",
		"Alcuni di noi studiano qui. Alcuni cercano lavoro. Altri vengono solo per stare un po' insieme."], who)


func _ada_menu() -> void:
	var who := "Ada"
	while true:
		var opts: Array = ["Perché non andate altrove?"]
		var acts: Array = ["altrove"]
		if not _f("c5_ada_stanze"):
			opts.append("Ti do una mano a sistemare")
			acts.append("stanze")
		opts.append("Cos'è quella lettera?")
		acts.append("lettera")
		opts.append("Ciao")
		acts.append("")
		var c: int = await Ui.choose("Ada.", opts, who)
		match str(acts[c]):
			"altrove":
				GameState.flags["c5_ada_perche"] = true
				await Ui.say(["Ci abbiamo pensato.", "Poi abbiamo guardato quanto costavano gli altri posti.",
					"Ci siamo sentiti molto creativi per circa dieci minuti."], who)
			"stanze":
				await _offer("ada", who)
				return
			"lettera":
				await _lettera()
			_:
				return


func _ada_after_assembly() -> String:
	match str(GameState.flags.get("c5_esito", "")):
		"comunitaria":
			return "Ho messo il mio nome sul foglio dei turni. Il martedì apro io. Il mercoledì la libreria mi odia di nuovo."
		"riconversione":
			return "Ho fatto domanda per la borsa di studio. Per entrare dove studiavo già. Che frase tristissima. Un'altra maglietta."
		_:
			return "Abbiamo tempo. Non molto. Abbastanza per sbagliare con calma."


## Ada robot nella Casa Comune: risponde alle domande come un volantino.
func robot_talk_ada(_n: Npc) -> bool:
	var c: int = await Ui.choose("Ada.", ["Com'è la libreria?", "Cosa volevi studiare?", "(Niente)"], "Ada")
	match c:
		0:
			await Ui.say(["ARREDAMENTO NON OTTIMIZZATO."], "Ada")
		1:
			await Ui.say(["DOMANDA NON PREVISTA."], "Ada")
		_:
			await Ui.say([GameState.robot_line("ada")], "Ada")
	return true


func _offer(id: String, who: String) -> void:
	var h: Dictionary = GameState.npc_data(id).get("help", {})
	var c: int = await Ui.choose(str(h.get("ask", "")), ["Dai una mano (1 ora)", "Non ora"], who)
	if c != 0:
		return
	Router.minigame(Npc.minigame_cfg(id, who, h, scene_file_path, player.global_position))


# --- 5.04 la proposta CHEAP ---------------------------------------------------------------------

func _lettera() -> void:
	GameState.flags["c5_lettera"] = true
	Sound.sfx("flap")
	await Ui.say(["* PROPOSTA CHEAP — RICONVERSIONE DELLA CASA COMUNE.",
		"* L'azienda propone di ristrutturare l'edificio e trasformarlo in un centro privato di formazione.",
		"* VANTAGGI: manutenzione. Attrezzature. Alcune borse di studio. Posti di lavoro.",
		"* SVANTAGGI (scritti più piccoli): accesso a pagamento. Meno attività libere. Più controllo aziendale."])
	var ada := _npc("ada")
	if ada == null or not ada.visible or GameState.is_robot("ada"):
		return
	if not _f("c5_ada"):
		await _ada_first()
	var who := "Ada"
	await Ui.say(["Almeno riparerebbero il tetto.", "E forse alcune persone potrebbero continuare a studiare.",
		"Solo che altre non potrebbero più entrare."], who)
	var c: int = await Ui.choose("La proposta CHEAP.", ["Tu cosa faresti?", "(Restituisci la lettera)"], who)
	if c == 0:
		GameState.flags["c5_ada_vorrebbe"] = true
		await Ui.say(["Vorrei sapere quanto costa veramente mantenere questo posto.",
			"E se possiamo trovare una soluzione che non lasci fuori metà delle persone."], who)
		if not _f("c5_protesta"):
			await Ui.say(["I bilanci sono nell'archivio, di là. Chiuso a chiave. Lo aprono per l'assemblea, dicono.",
				"Un'assemblea si fa quando c'è abbastanza gente arrabbiata. Fra poco ce ne sarà abbastanza."], who)


func _avviso() -> void:
	await Ui.say(["* " + CITY_LOGIC.closure_text()])


# --- dai capitoli prima: la bacheca (Fermo, Bulbo, Mina), il B-4, il contatore ----------------

## I messaggi del Fondo dipendono da com'è andata davvero laggiù. Chi non hai conosciuto non scrive.
func _bacheca() -> void:
	var lines: Array = ["* La bacheca: annunci di ripetizioni, un gatto smarrito, \"CERCO SEDIA. ANCHE ZOPPA\"."]
	var people := [["fermo", "Fermo", "fermo_talked"], ["bulbo", str(GameState.npc_data("bulbo").get("name")), "met_bulbo"],
		["mina", str(GameState.npc_data("mina").get("name")), "met_mina"]]
	var found := false
	for p: Array in people:
		if not _f(str(p[2])):
			continue
		found = true
		match GameState.npc_state(str(p[0])):
			"libero":
				lines.append("* Un biglietto scritto a mano: \"Sono uscito anch'io. Il sole c'è davvero. — %s\"" % p[1])
			"sfruttato":
				lines.append("* Un volantino stampato, firmato %s: \"LA PRODUTTIVITÀ È LUCE.\" La firma è perfetta. Troppo." % p[1])
			_:
				lines.append("* Un biglietto a matita: \"Lavoro ancora, giù al -5. Se qualcuno sale, salutatemi il cielo. — %s\"" % p[1])
	if not found:
		lines.append("* Fra gli annunci, nessun nome che conosci.")
	await Ui.say(lines)


## Il B-4: non il modulo finito nel tritacarte, un'altra pratica con la stessa procedura.
func _cartella_b4() -> void:
	var lines: Array = ["* Una cartella azzurra: PRATICA 7-B — RINNOVO DELLA CONCESSIONE DELLA CASA COMUNE.",
		"* PROCEDURA: B-4. STATO: IN ATTESA. IN ATTESA DA: UNDICI MESI."]
	if _f("c2_b4"):
		lines.append("* Il B-4. Non è il tuo modulo: quello è finito nel tritacarte del Sottoufficio. È un'altra pratica, con la stessa procedura.")
		if "tilde" in GameState.helped_ids or "ercole" in GameState.helped_ids:
			GameState.flags["c5_b4_capito"] = true
			lines.append("* Tilde ed Ercole te l'avevano fatto vedere: un B-4 si ferma sempre fra una firma e un timbro. Qui manca il timbro.")
			lines.append("* Gli oneri amministrativi del bilancio cominciano a sembrarti meno misteriosi.")
	await Ui.say(lines)


func _porta_archivio() -> void:
	if _f("c5_protesta"):
		await Ui.say(["* La porta dell'archivio è aperta. Dentro, un terminale, un armadio, un contatore che ronza."])
		return
	await Ui.say(["* ARCHIVIO. La porta è chiusa a chiave. Un biglietto: \"Si apre per l'assemblea.\""])


# --- 5.14 l'ufficio dei bilanci ----------------------------------------------------------------------

func _bilanci() -> void:
	var b: Dictionary = GameState.city.get("bilanci", {})
	var maint := int(b.get("manutenzione", 42000))
	var fee := int(b.get("canone_cheap", 19000))
	var old_fee := int(b.get("canone_vecchio", 7000))
	var admin := int(b.get("oneri", 11000))
	var income := int(b.get("entrate", 28000))
	GameState.flags["c5_rapporto"] = true
	Sound.sfx("blip", 1.3)
	await Ui.say(["* RAPPORTO DI VALUTAZIONE IMMOBILIARE.",
		"* Manutenzione annuale prevista: %s." % GameState.euros(maint),
		"* Canone servizi CHEAP: %s." % GameState.euros(fee),
		"* Oneri amministrativi: %s." % GameState.euros(admin),
		"* Entrate disponibili: %s." % GameState.euros(income),
		"* Disavanzo previsto: %s." % GameState.euros(CITY_LOGIC.deficit())])
	var c: int = await Ui.choose("Il rapporto dei bilanci.", ["Leggi le note", "Basta così"])
	if c != 0:
		return
	var lines: Array = ["* MANUTENZIONE: il tetto, gli impianti, le finestre. Un costo vero: l'edificio ha quarant'anni e li dimostra.",
		"* CANONE SERVIZI CHEAP: era %s. Con il contratto nuovo è %s. Stesso servizio, prezzo nuovo." % [GameState.euros(old_fee), GameState.euros(fee)],
		"* ONERI AMMINISTRATIVI: pratiche, procedure, gestione. Fra le voci: \"PRATICA 7-B, PROCEDURA B-4, SPESE DI GIACENZA\"."]
	if _f("c4_teo_copia") and not GameState.is_robot("teo"):
		GameState.flags["c5_fonte_teo"] = true
		lines.append("* Fra gli allegati, una copia del rapporto 404 di Teo: commissioni duplicate. Anche sul conto della Casa Comune: due righe uguali, a un giorno di distanza.")
	lines.append("* ALLEGATI CARTACEI: 1. ARMADIO DOCUMENTI, RIPIANO ALTO.")
	await Ui.say(lines)
	await Ui.say(["* Non è una truffa sola. Sono costi diversi, con origini diverse. Uno è il tetto. Uno è un contratto. Uno è una pratica ferma."])


## Il documento nascosto: solo per chi ha letto il rapporto e va a cercare l'allegato.
func _armadio() -> void:
	if not _f("c5_rapporto"):
		await Ui.say(["* Un armadio pieno di faldoni. Senza sapere cosa cercare, sono solo carta che invecchia."])
		return
	if _f("c5_documento"):
		await Ui.say(["* VALUTAZIONE OPPORTUNITÀ — DIREZIONE CHEAP. È ancora lì. Nessuno l'ha nascosto meglio."])
		return
	GameState.flags["c5_documento"] = true
	Sound.sfx("flap")
	await Ui.say(["* Ripiano alto. Un fascicolo con il logo CHEAP, più nuovo degli altri.",
		"* VALUTAZIONE OPPORTUNITÀ — DIREZIONE CHEAP.",
		"* \"La cessazione delle attività gratuite aumenta il potenziale commerciale dell'immobile.\"",
		"* \"La conversione a centro a pagamento è economicamente preferibile per CHEAP.\""])
	await Ui.say(["* Non c'è nessun complotto. Solo un conto fatto da un'altra parte del tavolo.",
		"* La stessa chiusura: un problema per chi studia qui. Un'opportunità per chi l'ha scritta."])


## Il contatore della rete della Torre: le luci del piano terra vengono anche da giù.
func _contatore() -> void:
	var lines: Array = ["* CONTATORE — RETE TORRE CHEAP. Sotto: \"ALIMENTAZIONE INTEGRATIVA: PIANO -5\"."]
	if _f("c1_arrivo"):
		GameState.flags["c5_contatore"] = true
		lines.append("* La dinamo del Fondo. La cyclette. Le luci della festa di Fermo, Bulbo e Mina tenevano accese anche queste.")
		if _f("c1_rivelazione"):
			lines.append("* Laggiù le luci si erano spente perché quelle di sopra restassero accese. Il contatore gira. Non dice per chi.")
	await Ui.say(lines)
