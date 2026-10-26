extends EditorRoom
## Capitolo 5 — La Città (piano terra). La scena è fatta nell'editor (citta.tscn): qui c'è solo la logica.
## Fuori dalla Torre, qualcuno sta ancora pagando. La Casa Comune chiude fra tre giorni (interno:
## casa_comune.tscn, con Ada e l'archivio dei bilanci); Nadir aspetta l'autobus; Rina ha una vetrina.
## Il capo offre 6.000 € per il progetto di Ada; poi la manifestazione, la vetrina, l'assemblea.
## Tutto è descritto in docs/CHAPTER_05_CITY.md (flag c5_*, e alla fine il riassunto "chapter_5").

const NIVES := "Nives"
const BOSS := "Il capo"
const VOICE := "Voce CHEAP"
const SPEAKER := "Altoparlante"
const BADGE := "cima"
const ART := "res://art/c5/"
const ANTENNA := "res://art/c4/antenna_robot.png"
## Dove porta la scala esterna: la Cima (il capitolo 6).
const NEXT := "res://chapters/c6/cima.tscn"
const CASA_DOOR := Rect2i(16, 9, 2, 1)
const TOWER_DOOR := Rect2i(2, 9, 2, 1)
const BENCH := Vector2i(6, 18)
const SIGNS := ["VOGLIAMO UN POSTO PER STUDIARE.", "IL TEMPO NON SI RECUPERA.",
	"UN SERVIZIO PUBBLICO NON È UN LUSSO.", "LAVORARE NON BASTA?"]

## Le persone in piazza create dalla stanza (manifestazione, ospiti dai capitoli prima): nome -> nodo.
var people: Dictionary = {}


## Dove porta la porta di vetro: giù, alla Banca.
func build() -> void:
	outdoor = true
	super()
	# il cielo sopra le facciate: per la prima volta c'è
	cam_rect = cam_rect.grow_side(SIDE_TOP, 64)


func setup() -> void:
	add_exit(TOWER_DOOR, Router.BANCA, "from_above")
	add_exit(CASA_DOOR, Router.CASA_COMUNE, "default")
	if _f("c5_vetrina"):
		_broken_window()
	if _f("c5_vetrina_aiuto"):
		_cardboard()
	if _f("c5_protesta") and not _f("c5_assemblea"):
		_dress_protest()
	elif _f("c5_assemblea"):
		_dress_after()
	if _f("c5_protesta"):
		_visitors()
	if _secret_ready():
		_secret_setup()


func enter() -> void:
	if not _f("c5_arrivo"):
		await _arrival()
	await show_pending()
	if Ui.transitioning:
		return
	if int(GameState.flags.get("c5_turni", 0)) > 0 and not GameState.flags.has("c5_turno_giorno"):
		GameState.flags["c5_turno_giorno"] = GameState.day
	# le cose rimaste a metà (un salvataggio, un minigioco) riprendono da dove erano
	if _f("c5_furto_ok") and not _f("c5_capo_chiuso"):
		await _report_choice()
	elif Router.spawn == "_mg" and _f("c5_nadir_percorso") and not _f("c5_nadir_dopo"):
		await _nadir_after()
	if _f("c5_protesta") and not GameState.flags.has("c5_titolo") and GameState.day > int(GameState.flags.get("c5_protesta_giorno", GameState.day)):
		await _headline()
	if protest_ready():
		await _protest()


## Al piano terra il badge non si regala a chi ha aiutato "tutti": decide Nives (vedi _badge_machine).
func _floor_gift() -> void:
	pass


func _npc(id: String) -> Npc:
	for n in get_tree().get_nodes_in_group("npc"):
		if n is Npc and (n as Npc).id == id and is_instance_valid(n):
			return n
	return null


static func _f(key: String) -> bool:
	return bool(GameState.flags.get(key, false))


# --- 5.01 l'uscita dalla Torre ------------------------------------------------------------------

func _arrival() -> void:
	GameState.flags["c5_arrivo"] = true
	Ui.cutscene = true
	await get_tree().create_timer(0.3).timeout
	await Ui.say(["* Una porta di vetro. Sopra, un'insegna: BENVENUTO ALL'ESTERNO.", "* Sotto, più piccolo: \"Servizio soggetto a disponibilità.\""])
	Sound.sfx("door")
	await get_tree().create_timer(0.5).timeout
	# la telecamera guarda in su: il cielo
	var cam := player.camera
	var tw := create_tween()
	tw.tween_property(cam, "offset", Vector2(0, -110), 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	Sound.sfx("flap", 1.3)
	await Ui.say(["* La porta si apre. Per la prima volta, sopra di te, c'è il cielo.",
		"* Vento. Uccelli. Qualcuno che parla. Il campanello di una bicicletta."])
	var back := create_tween()
	back.tween_property(cam, "offset", Vector2.ZERO, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await back.finished
	await get_tree().create_timer(0.8).timeout
	await _billboard_flash()
	await Ui.say(["* Un cartellone enorme si accende: ANCHE IL CIELO HA UN LIMITE. SUPERALO CON PREMIUM."])
	Sound.sfx("ding", 1.2)
	await Ui.say(["Congratulazioni! Hai raggiunto il piano terra!", "Sapevamo che ce l'avresti fatta.",
		"Statisticamente, doveva succedere a qualcuno."], SPEAKER)
	Ui.cutscene = false


## Il cartellone CHEAP: colori troppo accesi, che lampeggiano.
func _billboard_flash() -> void:
	var ad := find_child("CartellonePremium", true, false) as CanvasItem
	if ad == null:
		return
	Sound.sfx("spark", 1.2)
	var tw := create_tween()
	for i in 3:
		tw.tween_property(ad, "modulate", Color(2.2, 2.2, 2.2), 0.12)
		tw.tween_property(ad, "modulate", Color.WHITE, 0.12)
	await tw.finished


func _insegna_esterno() -> void:
	await Ui.say(["* BENVENUTO ALL'ESTERNO. \"Servizio soggetto a disponibilità.\"",
		"* La porta di vetro dà sulla Banca. Dietro il vetro, la fila grigia aspetta ancora."])


func _altoparlante() -> void:
	await Ui.say([["Ricordiamo ai gentili cittadini che il cielo è offerto da CHEAP. Fino a nuovo avviso.",
		"È vietato sostare senza consumare. È vietato consumare senza sostare. Grazie per la collaborazione.",
		"Oggi la temperatura percepita è: produttiva."].pick_random()], SPEAKER)


func _cartellone() -> void:
	await _billboard_flash()
	await Ui.say(["* ANCHE IL CIELO HA UN LIMITE. SUPERALO CON PREMIUM.",
		"* Sotto, in piccolo: \"Il cielo base resta gratuito. Per ora. Le nuvole sono a carico dell'utente.\""])


## L'albero: tre volte, e alla terza un giudizio.
func _albero() -> void:
	var n := int(GameState.flags.get("c5_albero", 0)) + 1
	GameState.flags["c5_albero"] = n
	if n < 3:
		await Ui.say(["..."], "Albero")
	else:
		await Ui.say(["* Non sembra interessato al tuo curriculum."])


# --- la Casa Comune vista da fuori ---------------------------------------------------------

## Quanto manca alla chiusura: segue la storia, non i giorni (nessuno la perde dormendo).
static func closure_text() -> String:
	if _f("c5_assemblea"):
		match str(GameState.flags.get("c5_esito", "")):
			"riconversione":
				return "CHIUSURA PER RISTRUTTURAZIONE. RIAPRE COME CENTRO DI FORMAZIONE CHEAP."
			"comunitaria":
				return "CHIUSURA ANNULLATA. GESTIONE CONDIVISA: TURNI SUL FOGLIO ACCANTO."
			_:
				return "CHIUSURA RINVIATA. IN ATTESA DI UNA REVISIONE DEI COSTI."
	if _f("c5_protesta"):
		return "CHIUSURA PREVISTA: FRA 2 GIORNI. (L'1 è stato corretto a penna in un 2. Poi di nuovo in un 1. Poi in un 2.)"
	return "CHIUSURA PREVISTA: FRA 3 GIORNI."


func _avviso() -> void:
	await Ui.say(["* Sulla porta della Casa Comune: " + closure_text()])


func _volantini() -> void:
	var lines: Array = ["* Volantini a mano: \"CASA COMUNE: STUDIO, LAVORO, INCONTRI. GRATIS. ANCORA PER POCO?\""]
	if _f("c5_protesta"):
		lines.append("* Uno nuovo: \"ASSEMBLEA IN PIAZZA. PORTATE UNA SEDIA. ANCHE SPAIATA.\"")
	else:
		lines.append("* Uno con l'angolo strappato: \"CERCASI TETTO. QUELLO CHE C'È PERDE.\"")
	await Ui.say(lines)


# --- 5.05 / 5.06 Nadir e l'autobus -------------------------------------------------------------

## Il tabellone che fa retromarcia: 6, poi 9, poi 14 minuti.
func _tabellone() -> void:
	if _f("c5_tabellone"):
		await Ui.say([["* PROSSIMO AUTOBUS: 14 MINUTI. Il tabellone ha l'aria di chi non si sbilancia.",
			"* PROSSIMO AUTOBUS: IN ARRIVO. Nessuno ci crede. Nemmeno il tabellone."].pick_random()])
		return
	GameState.flags["c5_tabellone"] = true
	Ui.cutscene = true
	for m in [6, 9, 14]:
		Sound.sfx("blip", 1.0 - m * 0.02)
		await Ui.say(["* PROSSIMO AUTOBUS: %d MINUTI." % m])
	Ui.cutscene = false
	if _npc("nadir"):
		await Ui.say(["Sta facendo retromarcia."], "Nadir")


func talk_nadir(_npc_node: Npc) -> bool:
	if _f("c5_rivelazione"):
		return false
	if _secret_ready():
		return false
	if not _f("c5_nadir"):
		await _nadir_first()
	elif _f("c5_assemblea"):
		await Ui.say([_nadir_after_assembly()], "Nadir")
		return true
	await _nadir_menu()
	return true


func _nadir_first() -> void:
	var who := "Nadir"
	GameState.flags["c5_nadir"] = true
	GameState.flags["met_nadir"] = true
	if not _f("c5_tabellone"):
		await _tabellone()
	await Ui.say(["* Uno zaino, un termos, gli occhi sul tabellone come su una partita che sta perdendo."])
	await Ui.say(["Sai cosa mi piace dei trasporti pubblici?", "Che ti insegnano la pazienza.", "Ho già un dottorato."], who)


func _nadir_menu() -> void:
	var who := "Nadir"
	while true:
		var opts: Array = ["E il lavoro?", "Perché non cambi lavoro?", "Cosa stai guardando?"]
		var acts: Array = ["lavoro", "cambiare", "uccelli"]
		if not _f("c5_nadir_percorso"):
			opts.append("Ti do una mano col percorso")
			acts.append("percorso")
		elif _f("c5_ada") and not _f("c5_nadir_rete"):
			opts.append("E se i pendolari si organizzassero?")
			acts.append("rete")
		opts.append("Ciao")
		acts.append("")
		var c: int = await Ui.choose("Nadir aspetta l'autobus.", opts, who)
		match str(acts[c]):
			"lavoro":
				GameState.flags["c5_nadir_lavoro"] = true
				await Ui.say(["Il lavoro comincia alle otto.", "Per arrivare puntuale devo partire alle sei.",
					"Quando torno a casa, a volte non ricordo neanche come si chiama la mia strada."], who)
			"cambiare":
				GameState.flags["c5_nadir_lavoro"] = true
				await Ui.say(["Ci sto provando.", "Ma le offerte che trovo sono ancora più lontane."], who)
			"uccelli":
				GameState.flags["c5_nadir_uccelli"] = true
				await Ui.say(["Senti? Quello è un merlo.", "Fischia sempre alla stessa ora. È l'unica cosa puntuale della fermata.",
					"Ne ho contati ventitré tipi diversi, aspettando il 12.", "Al ventiquattresimo mi compro un binocolo. Se arriva prima l'autobus, no."], who)
			"percorso":
				await _offer("nadir", who)
				return
			"rete":
				await _commuters_network()
			_:
				return


## Dopo IL PERCORSO POSSIBILE: se conosci Ada, l'idea di organizzarsi fra pendolari.
func _nadir_after() -> void:
	GameState.flags["c5_nadir_dopo"] = true
	if _f("c5_ada") and not _f("c5_nadir_rete"):
		var c: int = await Ui.choose("Hai un'idea.", ["E se i pendolari si organizzassero?", "Niente"], "Nadir")
		if c == 0:
			await _commuters_network()


func _commuters_network() -> void:
	var who := "Nadir"
	GameState.flags["c5_nadir_rete"] = true
	await Ui.say(["* Gli racconti della Casa Comune: Ada, le sedie, i tavoli. Un posto dove trovarsi alle sei meno un quarto.",
		"* Un foglio per gli orari, chi parte da dove, chi può aspettare chi."])
	await Ui.say(["Potremmo farlo.", "Però non voglio che diventi un secondo lavoro gratuito per qualcuno.",
		"Un foglio, una bacheca. Chi può, scrive. Chi non può, legge. Cominciamo così."], who)


func _nadir_after_assembly() -> String:
	match str(GameState.flags.get("c5_esito", "")):
		"comunitaria":
			return "Abbiamo messo un foglio in bacheca. Tre nomi. Uno è il mio. Uno è del merlo: l'ha scritto un bambino."
		"riconversione":
			return "Il centro di formazione apre alle nove. Io alle nove sono già in fabbrica da un'ora."
		_:
			return "Hanno rimandato. Io sono bravissimo ad aspettare. Ho un dottorato."


# --- 5.07 Rina e la bottega ------------------------------------------------------------------

func talk_rina(_npc_node: Npc) -> bool:
	if _f("c5_rivelazione"):
		return false
	if _secret_ready():
		return false
	if not _f("c5_rina"):
		await _rina_first()
		await _rina_menu()
	elif _f("c5_vetrina") and not _f("c5_assemblea"):
		await _rina_window()
	elif _f("c5_assemblea"):
		await Ui.say([_rina_after_assembly()], "Rina")
	else:
		await _rina_menu()
	return true


func _rina_first() -> void:
	var who := "Rina"
	GameState.flags["c5_rina"] = true
	GameState.flags["met_rina"] = true
	await Ui.say(["Non toccare quella."], who)
	await Ui.say(["* Ti fermi. Avevi la mano a un palmo dalla vetrina."])
	await Ui.say(["Quella accanto puoi toccarla.", "È già rotta."], who)


func _rina_menu() -> void:
	var who := "Rina"
	while true:
		var c: int = await Ui.choose("Rina pulisce la vetrina intera.", ["Ti preoccupa qualcosa?",
			"Sei d'accordo con chi vuole tenere aperta la Casa Comune?", "Ciao"], who)
		match c:
			0:
				await Ui.say(["Dicono che ci sarà una manifestazione. In piazza. Davanti alla bottega.",
					"L'ultima volta ho pagato io il vetro. E per due giorni i clienti giravano alla larga.",
					"Lo so che la gente ha dei problemi.", "Anch'io ne ho.", "Il vetro l'ho pagato io."], who)
			1:
				GameState.flags["c5_rina_ascoltata"] = true
				await Ui.say(["Vorrei che mantenessero aperta la Casa Comune.", "Mio nipote ci ha studiato per anni.",
					"Ma vorrei anche poter aprire la bottega domattina."], who)
			_:
				return


## Dopo il CRASH: Rina, la vetrina, la bolletta. Si può dare una mano a mettere in sicurezza (1 ora).
func _rina_window() -> void:
	var who := "Rina"
	if not _f("c5_rina_vetrina"):
		GameState.flags["c5_rina_vetrina"] = true
		await Ui.say(["Sai cosa mi fa arrabbiare?", "Che adesso devo trovare i soldi per questo.",
			"E avevo già deciso di usarli per pagare una bolletta."], who)
	if _f("c5_vetrina_aiuto"):
		await Ui.say(["Il cartone tiene. Domani chiamo il vetraio. Dopodomani lo pago. Fra un mese, forse, lo perdono."], who)
		return
	var c: int = await Ui.choose("La vetrina è a pezzi.", ["Ti aiuto a metterla in sicurezza (1 ora)", "Non ora"], who)
	if c != 0:
		await Ui.say(["Tranquillo. I cocci non scappano. Sono l'unica cosa qui che non ha fretta."], who)
		return
	GameState.flags["c5_vetrina_aiuto"] = true
	GameState.help("rina", "time", 0)
	Sound.sfx("clunk")
	_cardboard()
	await Ui.say(["* Raccogliete i cocci con una scopa e una paletta. Rina misura, tu tieni. Un cartone, del nastro, un pennarello.",
		"* Sul cartone Rina scrive: APERTO LO STESSO."])
	await Ui.say(["Grazie.", "Non ti chiedo da che parte stai. Mi hai tenuto il cartone. Per oggi basta."], who)


func _rina_after_assembly() -> String:
	match str(GameState.flags.get("c5_esito", "")):
		"comunitaria":
			return "Mi hanno messo nei turni del sabato. Io il sabato lavoro. Allora ci vado la domenica. Si fa."
		"riconversione":
			return "Il centro nuovo avrà un bar interno. Indovina chi non ci comprerà più il pane."
		_:
			return "Hanno rimandato. Anch'io rimando: il vetraio, la bolletta. In piazza siamo tutti in lista d'attesa."


func _vetrina() -> void:
	if not _f("c5_rina") and _npc("rina"):
		await _rina_first()
		return
	if _f("c5_vetrina_aiuto"):
		await Ui.say(["* Un cartone al posto del vetro: APERTO LO STESSO. Il nastro è dritto. L'hai messo tu."])
	elif _f("c5_vetrina"):
		await Ui.say(["* La vetrina intera non c'è più. A terra, vetri e un sasso. Nessuno sa di chi fosse il sasso."])
	else:
		await Ui.say(["* La vetrina intera. Pulita due volte: una per i clienti, una per Rina.", "* Dentro: pane, quaderni, lampadine, un gatto di ceramica."])


func _vetrina_rotta() -> void:
	await Ui.say(["* La vetrina già rotta. Scotch a stella, da anni. Ormai è un modello."])


func _broken_window() -> void:
	if find_child("VetrinaRottaNuova", true, false):
		return
	var s := Sprite2D.new()
	s.name = "VetrinaRottaNuova"
	s.texture = load(ART + "vetrina_rotta.png")
	s.centered = false
	s.position = Vector2(33 * T + 2, 7 * T + 6)
	s.z_index = 2
	add_child(s)


func _cardboard() -> void:
	if find_child("Cartone", true, false):
		return
	var s := Sprite2D.new()
	s.name = "Cartone"
	s.texture = load(ART + "cartone.png")
	s.centered = false
	s.position = Vector2(33 * T + 2, 7 * T + 6)
	s.z_index = 3
	add_child(s)


# --- 5.08 il TURNO: Comunicazioni (dal terzo turno, lo smistamento rapido) ------------------------

func _station(j: Dictionary) -> void:
	var quick: Dictionary = GameState.city.get("rapido", {})
	if GameState.worked_today or int(GameState.flags.get("c5_turni", 0)) < int(quick.get("dopo", 2)):
		await super(j)
		return
	var c: int = await Ui.choose(str(j.get("station_text", "")) + "\nIniziare il turno? (10 ore)",
		["Turno al centralino", "Smistamento rapido (veloce)", "Non ancora"])
	if c == 0:
		start_job(j)
	elif c == 1:
		await quick_turn()


## Il TURNO RAPIDO: le richieste arrivano già smistate. Stessa paga base, nessuna discrepanza vista.
func quick_turn() -> void:
	if GameState.worked_today:
		return
	var pay := int(GameState.city.get("rapido", {}).get("paga", 1600))
	GameState.finish_hard_job(pay)
	GameState.flags["c5_turni"] = int(GameState.flags.get("c5_turni", 0)) + 1
	GameState.flags["c5_rapidi"] = int(GameState.flags.get("c5_rapidi", 0)) + 1
	for i in 3:
		Sound.sfx("blip", 0.9 + i * 0.15)
		await get_tree().create_timer(0.25).timeout
	Sound.sfx("coin")
	await Ui.say(["* Le richieste arrivano già smistate da un algoritmo. Tu premi CONFERMA. Cento volte.",
		"* Paga: %s." % GameState.euros(pay), "* Discrepanze viste: zero. Non perché non ci fossero."])
	await show_pending()


# --- 5.09 la telefonata del capo ---------------------------------------------------------------

## Il capo chiama dopo il primo turno, una volta sola: 6.000 € per il progetto di Ada.
func _boss_call() -> void:
	GameState.flags["boss_call_done_%d" % GameState.day] = true
	GameState.flags["boss_call_floor_" + GameState.floor_id] = true
	if _f("c5_capo") or GameState.is_robot("ada"):
		return
	GameState.flags["c5_capo"] = true
	GameState.flags["c5_capo_giorno"] = GameState.day
	var prize := int(GameState.city.get("premio_capo", 6000))
	Sound.sfx("alarm", 0.7)
	await Ui.say(["* DRRRING. Il telefono squilla. È il capo.",
		"* Non lo vedi, ma lo senti: cravatta di banconote, e una spilla nuova. IO ♥ LA COMUNITÀ."])
	await Ui.say(["IL MIO COLLABORATORE PREFERITO!", "Che bello vederti finalmente all'aperto!",
		"Hai visto? CHEAP si prende cura delle persone!"], BOSS)
	var c: int = await Ui.choose("Cosa rispondi?", ["Vogliono chiudere la Casa Comune.", "Ho appena iniziato a lavorare.", "Cosa vuoi?"], BOSS)
	match c:
		0:
			await Ui.say(["Precisamente! È proprio di questo che volevo parlarti!"], BOSS)
		1:
			await Ui.say(["E già lavori benissimo! Ma parliamo di cose importanti: la Casa Comune!"], BOSS)
		_:
			await Ui.say(["Diretto! Mi piace. Parliamo della Casa Comune."], BOSS)
	await Ui.say(["Abbiamo deciso di salvare la Casa Comune.", "Trasformandola in un servizio migliore."], BOSS)
	var d: int = await Ui.choose("Salvarla?", ["Cioè?", "(Lascialo parlare)"], BOSS)
	if d == 0:
		await Ui.say(["Un nuovo centro di formazione! Moderno! Efficiente! Con pubblicità personalizzata!"], BOSS)
	await Ui.say(["Stiamo preparando la presentazione.", "E abbiamo un piccolo problema.",
		"Quella ragazza, Ada, ha preparato un progetto per la Casa Comune. Dati, residenti, studenti. Tutto.",
		"Quella ragazza è stata bravissima.", "Talmente brava che il suo progetto merita un responsabile più importante.", "Tu."], BOSS)
	if _f("c5_ada"):
		await Ui.say(["Ah, siete amici?", "Ancora meglio!", "Le amicizie sono il futuro del networking."], BOSS)
	if GameState.exploited > 0:
		await Ui.say(["Tu sai come funzionano queste cose.", "Non devo neanche spiegarti il procedimento."], BOSS)
	else:
		await Ui.say(["Senti, so che sei una persona prudente.", "Ma la prudenza non paga il badge."], BOSS)
	await Ui.say(["%s per firmarlo tu." % GameState.euros(prize), "Pensa che opportunità!",
		"Sei quasi in cima. Perché rischiare tutto per un edificio pieno di sedie vecchie?"], BOSS)
	while true:
		var e: int = await Ui.choose("Il progetto di Ada: %s." % GameState.euros(prize), ["Va bene", "Ci penso", "Perché io?", "No. È di Ada."], BOSS)
		if e == 2:
			await Ui.say(["Perché tu sei arrivato fin qui. Lei è ancora seduta su una sedia spaiata."], BOSS)
			continue
		if e == 3:
			_close_offer()
			await Ui.say(["Davvero?", "Continui a sorprendermi. Purtroppo quasi mai in modo redditizio."], BOSS)
			return
		GameState.flags["c5_capo_sospeso"] = true
		if e == 0:
			await Ui.say(["Bravo! La presentazione è nel terminale accanto all'Ufficio Comunicazioni.",
				"Ada ci sta sistemando le ultime slide. Quando si gira, tu sii un lampione."], BOSS)
		else:
			await Ui.say(["Pensaci pure! Il terminale aspetta. Ma la presentazione è domani. Domani, capisci? Domani."], BOSS)
		return


func _close_offer() -> void:
	GameState.flags["c5_capo_chiuso"] = true
	GameState.flags["c5_capo_sospeso"] = false
	GameState.flags["promotions_refused"] = int(GameState.flags.get("promotions_refused", 0)) + 1


# --- 5.10 un, due, tre, stella: il progetto di Ada ------------------------------------------------

func _presentazioni() -> void:
	if _f("c5_capo_firmato"):
		await Ui.say(["* PROPOSTA DI RIUTILIZZO DELLA CASA COMUNE. RESPONSABILE: {name}.",
			"* DATI RACCOLTI DA: RESIDENTI E STUDENTI. Questa riga nessuno l'ha cambiata. Nessuno la legge."])
		return
	if _f("c5_furto_ok") and not _f("c5_capo_chiuso"):
		await _report_choice()
		return
	if _f("c5_capo_sospeso") and not _f("c5_capo_chiuso"):
		await Ui.say(["* La sala delle presentazioni. Sul terminale, il progetto di Ada. In attesa di firma.",
			"* Ada sistema le slide. Ogni tanto si gira."])
		var c: int = await Ui.choose("Il progetto di Ada.", ["Avvicinati di nascosto", "Lascia stare, per ora", "Chiudi l'offerta per sempre"])
		match c:
			0:
				await Ui.say(["Vai, campione. Il futuro non si firma da solo!"], BOSS)
				start_steal("ada", GameState.promotion("ada"), {
					"intro": ["* La sala delle presentazioni. Ada sistema le slide, una sedia spaiata alla volta. Ogni tanto si gira.",
						"* Il terminale è in fondo. Basta arrivarci senza che ti veda."],
					"win_flag": "c5_furto_ok",
				})
			2:
				_close_offer()
				await Ui.say(["* Premi ANNULLA. Il terminale chiede se sei sicuro. Poi se sei sicuro sicuro. Sì, e sì."])
		return
	if _f("c5_capo"):
		await Ui.say(["* PROPOSTA DI RIUTILIZZO DELLA CASA COMUNE.", "* RESPONSABILE ORIGINALE: ADA.",
			"* DATI RACCOLTI DA: RESIDENTI E STUDENTI."])
		return
	await Ui.say(["* SALA PRESENTAZIONI CHEAP. Nessuna presentazione in programma.",
		"* Lo schermo di attesa dice: \"IL FUTURO È IN CARICAMENTO\". Da parecchio."])


## La scelta al terminale (dopo che sei arrivato senza farti vedere). Leggere non decide niente.
func _report_choice() -> void:
	var prize := int(GameState.city.get("premio_capo", 6000))
	Sound.sfx("blip", 1.2)
	await Ui.say(["* PROPOSTA DI RIUTILIZZO DELLA CASA COMUNE.", "* RESPONSABILE ORIGINALE: ADA.",
		"* DATI RACCOLTI DA: RESIDENTI E STUDENTI.", "* NUOVO RESPONSABILE: ______.", "* PREMIO: %s." % GameState.euros(prize)])
	while true:
		var c: int = await Ui.choose("NUOVO RESPONSABILE: ______", ["Firma con il tuo nome", "Lascia il nome di Ada", "Leggi il progetto prima di decidere"])
		if c == 2:
			GameState.flags["c5_progetto_letto"] = true
			await Ui.say(["* IL PROGETTO DI ADA: studio gratuito. Manutenzione. Un fondo per pagare chi gestisce. Attività comunitarie.",
				"* LA VERSIONE CHEAP, nella cartella accanto: ristrutturazione. Accesso prevalentemente a pagamento. Alcune borse di studio. Controllo aziendale.",
				"* Le due versioni hanno la stessa copertina. Non sono lo stesso progetto."])
			continue
		if c == 1:
			_close_offer()
			GameState.flags["c5_ada_lasciato"] = true
			await Ui.say(["* Lasci il nome di Ada. Il terminale torna a fare il terminale."])
			await Ui.say(["Davvero?", "Continui a sorprendermi. Purtroppo quasi mai in modo redditizio."], BOSS)
			return
		await _sign(prize)
		return


## Firmare: il premio una volta sola, LV su, Ada diventa un robot (tutto prima di qualunque attesa).
func _sign(prize: int) -> void:
	if _f("c5_capo_firmato"):
		return
	GameState.flags["c5_capo_firmato"] = true
	GameState.flags["c5_capo_chiuso"] = true
	GameState.flags["c5_capo_sospeso"] = false
	GameState.exploit("ada", prize)
	GameState.spend(GameState.COST_EASY_JOB)
	Ui.cutscene = true
	Sound.sfx("stamp")
	await Ui.say(["* Scrivi il tuo nome. Il terminale fa BIP.", "* PREMIO ACCREDITATO: %s." % GameState.euros(prize)])
	# Ada esce dalla Casa Comune, e non è più Ada
	var ada := CharSprite.new()
	ada.sheet = str(GameState.npc_data("ada").get("sheet"))
	ada.anim = "idle_down"
	ada.position = cell_feet(Vector2i(16, 10))
	ada.modulate.a = 0.0
	world.add_child(ada)
	_antenna(ada)
	var tw := ada.create_tween()
	tw.tween_property(ada, "modulate:a", 1.0, 0.8)
	await tw.finished
	Sound.sfx("glitch", 0.8)
	await Ui.say(["IL FUTURO DELL'ISTRUZIONE È EFFICIENTE."], "Ada")
	await Ui.say(["Visto? Adesso il progetto ha il responsabile giusto."], BOSS)
	var out := ada.create_tween()
	out.tween_property(ada, "modulate:a", 0.0, 0.8)
	out.tween_callback(ada.queue_free)
	await Ui.say([GameState.level_up_line()])
	Ui.cutscene = false


## I robot si riconoscono anche senza colori: un'antenna sulla testa.
static func _antenna(n: Node2D) -> void:
	if n.has_node("Antenna"):
		return
	var a := Sprite2D.new()
	a.name = "Antenna"
	a.texture = load(ANTENNA)
	a.position = Vector2(0, -27)
	a.z_index = 1
	n.add_child(a)


# --- 5.11 / 5.12 / 5.13 la manifestazione, le tre proposte, la vetrina ---------------------------

## Parte dopo il primo turno e l'offerta del capo risolta. Se l'offerta resta in sospeso, il giorno
## dopo la presentazione è passata: l'offerta scade da sola (nessuno resta bloccato).
func protest_ready() -> bool:
	if _f("c5_protesta") or _f("c5_fine") or int(GameState.flags.get("c5_turni", 0)) < 1:
		return false
	if _f("c5_capo_chiuso"):
		return true
	return GameState.day > int(GameState.flags.get("c5_turno_giorno", GameState.day))


func _protest() -> void:
	GameState.flags["c5_protesta"] = true
	GameState.flags["c5_protesta_giorno"] = GameState.day
	Ui.cutscene = true
	if not _f("c5_capo_chiuso"):
		var was_offered := _f("c5_capo")
		_close_offer()
		if was_offered:
			await Ui.say(["* Il telefono vibra. Un messaggio del capo: \"La presentazione è oggi. L'offerta è scaduta. Le offerte scadono. Come il latte.\""])
	_dress_protest()
	_visitors()
	Sound.sfx("honk", 0.8)
	await Ui.say(["* La piazza si riempie. Studenti, lavoratori, residenti. E chi passava di lì e si è fermato.",
		"* Cartelli fatti a mano: VOGLIAMO UN POSTO PER STUDIARE. IL TEMPO NON SI RECUPERA.",
		"* UN SERVIZIO PUBBLICO NON È UN LUSSO. LAVORARE NON BASTA?"])
	await Ui.say(["Sono qui perché chiudono il posto dove studio."], "Studente")
	await Ui.say(["Io sono qui perché per arrivare al lavoro spendo metà della giornata."], "Lavoratore")
	await Ui.say(["Io volevo soltanto comprare del pane."], "Passante")
	await Ui.say(["Hai trovato quello economico?"], "Altro passante")
	await Ui.say(["No."], "Passante")
	await Ui.say(["Allora sei dei nostri."], "Altro passante")
	if GameState.is_robot("ada"):
		await Ui.say(["* Davanti alla Casa Comune, Ada distribuisce volantini CHEAP. Sorride a tutti allo stesso modo."])
		await Ui.say(["CHEAP CREDE NEL FUTURO DEI GIOVANI."], "Ada")
		await Ui.say(["Ieri mi aveva chiesto se volevo portare delle sedie.", "Non so cosa dirle adesso."], "Studente")
		await Ui.say(["* Uno studente sale su una cassetta della frutta. Prova a mettere in ordine l'assemblea."])
	else:
		await Ui.say(["Non siamo qui perché non vogliamo cambiare niente.", "Sappiamo che il tetto deve essere riparato.",
			"Sappiamo che ci vogliono soldi per mantenere aperto l'edificio.",
			"Vogliamo capire perché l'unica soluzione proposta è far pagare chi lo usa."], "Ada")
	if _f("c5_nadir_lavoro") or _f("c5_nadir_percorso"):
		await Ui.say(["E se qualcuno non può arrivare fin qui?",
			"Un servizio può essere gratuito, ma se devi spendere troppo per raggiungerlo non è accessibile a tutti."], "Nadir")
	if _f("c5_rina_ascoltata"):
		await Ui.say(["Io vorrei che l'edificio restasse aperto.", "Ma domani devo anche aprire il negozio.",
			"Se vogliamo fare qualcosa insieme, dobbiamo pensare anche a chi lavora qui."], "Rina")
	await _three_proposals()
	await _crash()
	Ui.cutscene = false


func organizer() -> String:
	return "Studente" if GameState.is_robot("ada") else "Ada"


## 5.12: tre strade sul tavolo. Il sostegno del protagonista pesa, ma non decide da solo.
func _three_proposals() -> void:
	var who := organizer()
	await Ui.say(["Allora. Sul tavolo ci sono tre strade.",
		"A: la ristrutturazione CHEAP. Pagano loro manutenzione e attrezzature. Alcuni servizi diventano a pagamento. Restano borse di studio e qualche attività gratuita.",
		"B: la gestione comunitaria. Cerchiamo fondi, ci organizziamo noi. L'accesso resta quasi tutto gratuito. Servono soldi, accordi, e gente che si prende delle responsabilità.",
		"C: chiediamo un rinvio della chiusura. Tempo per una revisione indipendente dei costi e per cercare finanziamenti. È una soluzione temporanea."], who)
	var c: int = await Ui.choose("Tu cosa sostieni?", ["Sostengo A", "Sostengo B", "Sostengo C", "Non prendo posizione"], who)
	var key: String = ["A", "B", "C", "nessuna"][c]
	GameState.flags["c5_proposta"] = key
	match key:
		"A":
			await Ui.say(["Va bene. Almeno qualcuno ha guardato il tetto.", "Lo scriviamo. Ne parliamo all'assemblea."], who)
		"B":
			await Ui.say(["Bene. Ma un sì non basta: servono numeri, persone, soldi.", "Lo scriviamo. Ne parliamo all'assemblea."], who)
		"C":
			await Ui.say(["Prendere tempo non è scappare, se poi il tempo lo usi.", "Lo scriviamo. Ne parliamo all'assemblea."], who)
		_:
			await Ui.say(["Va bene anche ascoltare. È più raro di quanto sembri."], who)


func _crash() -> void:
	await get_tree().create_timer(0.6).timeout
	Sound.sfx("crash")
	_broken_window()
	GameState.flags["c5_vetrina"] = true
	var rina := _npc("rina")
	if rina:
		rina.face("up")
	await get_tree().create_timer(0.8).timeout
	await Ui.say(["* CRASH.", "* La vetrina della bottega di Rina va in pezzi. Non hai visto chi è stato. Da qui, nessuno l'ha visto bene."])
	await Ui.say(["No.", "No, no, no.", "L'avevo appena riparata."], "Rina")
	_add_person("Giornalista", "char_07", Vector2i(36, 11), "idle_left", _giornalista)
	await Ui.say(["* Arriva qualcuno con un taccuino e un microfono che ha visto giorni migliori."])
	await Ui.say(["Possiamo avere una dichiarazione?"], "Giornalista")
	await Ui.say(["* (Puoi parlare con Rina, con chi manifesta, con il giornalista. Nell'ordine che vuoi. E poi c'è l'assemblea: %s la sta organizzando.)" % organizer()])


func _manifestante() -> void:
	if not _f("c5_vetrina"):
		await Ui.say(["Il cartello l'ho scritto stanotte. Le lettere sono storte. Le ragioni no."], "Manifestante")
		return
	GameState.flags["c5_manifestante"] = true
	await Ui.say(["Non so chi abbia rotto il vetro.", "Ma non voglio che oggi si parli soltanto di questo."], "Manifestante")


## Il giornalista verifica: non scrive quello che dici tu, scrive quello che sa.
func _giornalista() -> void:
	var who := "Giornalista"
	if _f("c5_giornalista"):
		await Ui.say(["Sto ancora verificando. È la parte del lavoro che non si vede. Come le fondamenta."], who)
		return
	GameState.flags["c5_giornalista"] = true
	await Ui.say(["Sto cercando di raccontare quello che è successo.",
		"C'è chi vuole parlare della chiusura della Casa Comune e chi vuole parlare dei danni.",
		"Entrambe le cose sono successe. Devo verificare cosa sappiamo davvero."], who)
	var c: int = await Ui.choose("Cosa dici al giornalista?", ["Parla della Casa Comune", "Parla della vetrina di Rina", "Non ho visto chi è stato", "Niente"], who)
	GameState.flags["c5_dichiarazione"] = ["casa", "vetrina", "non_visto", ""][c]
	match c:
		0:
			await Ui.say(["Annoto. Chiudere un posto gratuito è una notizia. Lo è anche chi paga i conti. Se trovo i conti, li scrivo."], who)
		1:
			await Ui.say(["Annoto. Il danno c'è, e l'ha pagato una persona. Chi l'ha fatto, non lo so. Non lo scrivo, finché non lo so."], who)
		2:
			await Ui.say(["Grazie. È la dichiarazione più onesta di oggi. Non la userò: non dice niente. Ma grazie."], who)
		_:
			await Ui.say(["Anche il silenzio è una dichiarazione. Ma non si può citare."], who)


## Il titolo del giorno dopo: dipende da quello che si sa davvero, non da quello che pensi tu.
static func headline() -> String:
	if _f("c5_assemblea") or _f("c5_rapporto"):
		return "Casa Comune, tre proposte sul tavolo. Continuano le proteste."
	if _f("c5_giornalista"):
		return "Manifestazione per la Casa Comune: confronto aperto sul futuro dell'edificio."
	return "Vetrina danneggiata durante la manifestazione. I commercianti chiedono risposte."


func _headline() -> void:
	var title := headline()
	GameState.flags["c5_titolo"] = title
	Sound.sfx("flap")
	await Ui.say(["* Su una panchina qualcuno ha lasciato il giornale di stamattina.", "* \"" + title + "\"",
		"* Più sotto: \"Il responsabile del danno alla vetrina non è stato identificato.\""])


# --- la piazza durante la manifestazione -------------------------------------------------------

## Una persona in piazza (senza dati in npcs.json): uno sprite, una casella occupata, un'azione.
func _add_person(nm: String, sheet: String, cell: Vector2i, anim: String, action: Callable, grey := true) -> CharSprite:
	if people.has(nm) and is_instance_valid(people[nm]):
		return people[nm]
	var c := CharSprite.new()
	c.name = nm
	c.sheet = sheet
	c.person = nm.to_lower()
	c.anim = anim
	c.grey = grey
	c.position = cell_feet(cell)
	world.add_child(c)
	block(Rect2i(cell, Vector2i.ONE))
	var spot := add_spot(cell_center(cell), action)
	c.set_meta("spot", spot)
	people[nm] = c
	return c


func _remove_person(nm: String) -> void:
	if not people.has(nm):
		return
	var c: Node2D = people[nm]
	if is_instance_valid(c):
		var spot: Node = c.get_meta("spot", null)
		if is_instance_valid(spot):
			spot.queue_free()
		unblock(Rect2i(Vector2i(int(c.position.x) / T, int(c.position.y) / T), Vector2i.ONE))
		c.queue_free()
	people.erase(nm)


func _sign_on(c: Node2D, text: String) -> void:
	var s := Sprite2D.new()
	s.texture = load(ART + "cartello_protesta.png")
	s.position = Vector2(0, -34)
	s.z_index = 1
	c.add_child(s)
	c.set_meta("sign", text)


func _dress_protest() -> void:
	var org := organizer()
	if org == "Ada":
		_add_person("Ada", str(GameState.npc_data("ada").get("sheet")), Vector2i(16, 15), "idle_down", _organizer_talk)
	else:
		_add_person("Studente", "char_09", Vector2i(16, 15), "idle_down", _organizer_talk)
		var ada := _add_person("AdaRobot", str(GameState.npc_data("ada").get("sheet")), Vector2i(15, 11), "idle_down", _robot_ada_square, false)
		_antenna(ada)
	var crowd := [
		["StudenteFolla", "char_20", Vector2i(14, 17), "Sono qui perché chiudono il posto dove studio.", "Studente"],
		["Lavoratore", "char_15", Vector2i(21, 17), "Io sono qui perché per arrivare al lavoro spendo metà della giornata.", "Lavoratore"],
		["Passante", "char_11", Vector2i(28, 18), "Io volevo soltanto comprare del pane.", "Passante"],
		["AltroPassante", "char_12", Vector2i(29, 18), "Hai trovato quello economico? No? Allora sei dei nostri.", "Altro passante"],
	]
	for p: Array in crowd:
		var line: String = p[3]
		var who: String = p[4]
		_add_person(p[0], p[1], p[2], "idle_up", func() -> void: await Ui.say([line], who))
	var m := _add_person("Manifestante", "char_06", Vector2i(23, 19), "idle_up", _manifestante)
	_sign_on(m, SIGNS[3])
	var holders := [["Cartello0", "char_05", Vector2i(14, 19)], ["Cartello1", "char_10", Vector2i(20, 19)], ["Cartello2", "char_08", Vector2i(27, 16)]]
	for i in holders.size():
		var h: Array = holders[i]
		var text: String = SIGNS[i]
		var c := _add_person(h[0], h[1], h[2], "idle_up", func() -> void: await Ui.say(["* Il cartello dice: " + text]))
		_sign_on(c, text)
	if _f("c5_vetrina"):
		_add_person("Giornalista", "char_07", Vector2i(36, 11), "idle_left", _giornalista)


## Ada robot in piazza: volantini CHEAP. Si può parlarle, ma risponde il volantino.
func _robot_ada_square() -> void:
	await robot_talk_ada(null)


func robot_talk_ada(_n: Npc) -> bool:
	var c: int = await Ui.choose("Ada.", ["Com'è la libreria?", "Cosa volevi studiare?", "(Prendi un volantino)"], "Ada")
	match c:
		0:
			await Ui.say(["ARREDAMENTO NON OTTIMIZZATO."], "Ada")
		1:
			await Ui.say(["DOMANDA NON PREVISTA."], "Ada")
		_:
			await Ui.say([GameState.robot_line("ada")], "Ada")
	return true


func _organizer_talk() -> void:
	var who := organizer()
	if _f("c5_assemblea"):
		await Ui.say(["L'assemblea c'è stata. Domani ce ne sarà un'altra. Le assemblee sono come gli autobus: ne arriva sempre una dopo."], who)
		return
	if not _f("c5_vetrina"):
		await Ui.say(["Un attimo, sto contando le sedie."], who)
		return
	await assembly()


# --- ospiti dai capitoli prima: compaiono solo se li hai conosciuti davvero -------------------------

func _visitors() -> void:
	if _f("c3_leda"):
		_add_person("Leda", str(GameState.npc_data("leda").get("sheet")), Vector2i(30, 16), "idle_left", _leda)
	if _f("c3_amir"):
		var amir := _add_person("Amir", str(GameState.npc_data("amir").get("sheet")), Vector2i(32, 15), "idle_left", _amir, not GameState.is_robot("amir"))
		if GameState.is_robot("amir"):
			_antenna(amir)
	if _f("c4_olga"):
		_add_person("Olga", str(GameState.npc_data("olga").get("sheet")), Vector2i(10, 18), "idle_right", _olga)
	if _f("c4_teo"):
		var teo := _add_person("Teo", str(GameState.npc_data("teo").get("sheet")), Vector2i(11, 19), "idle_right", _teo, not GameState.is_robot("teo"))
		if GameState.is_robot("teo"):
			_antenna(teo)


func _leda() -> void:
	var who := "Leda"
	if not _f("c3_leda_ordini"):
		await Ui.say(["I prezzi del Mercato sono saliti anche qui. Hanno preso l'ascensore. Noi le scale."], who)
		return
	if _f("c5_leda_collabora"):
		await Ui.say(["Ordini condivisi: carta, lampadine, sedie usate. Il furgone è uno solo, ma gira per tutti."], who)
		return
	await Ui.say(["Ti ricordi gli ordini condivisi del Mercato? Funzionano ancora. Più o meno. Ma funzionano."], who)
	var c: int = await Ui.choose("Leda ha un'idea.", ["E se ordinaste insieme anche per la Casa Comune?", "Non ora"], who)
	if c == 0:
		GameState.flags["c5_leda_collabora"] = true
		await Ui.say(["Carta, lampadine, sedie usate. Comprate insieme costano meno. Non è beneficenza: è aritmetica.",
			"Lo dico all'assemblea. Se mi ascoltano, bene. Se no, lo dico più forte."], who)


func _amir() -> void:
	if GameState.is_robot("amir"):
		await Ui.say(["CONSEGNA CHEAP IN CORSO. IL TUO PACCO È LA NOSTRA PRIORITÀ."], "Amir")
		return
	var who := "Amir"
	if _f("c5_amir_consegne"):
		await Ui.say(["Il carrello della Casa Comune fa il giro alle cinque. Si ferma anche da Rina. Rina offre il caffè. Il caffè è il pagamento."], who)
		return
	await Ui.say(["Consegno pacchi tutto il giorno. Pacchi CHEAP. Mai uno per qualcuno che conosco."], who)
	var c: int = await Ui.choose("Amir ha un carrello e un'ora libera.", ["Potresti organizzare le consegne della Casa Comune?", "Non ora"], who)
	if c == 0:
		GameState.flags["c5_amir_consegne"] = true
		await Ui.say(["Libri, sedie, il pane avanzato di Rina. Un giro alla settimana. Gratis, ma a orari miei.",
			"Lo propongo all'assemblea. Se dicono di no, faccio il giro lo stesso. Solo più piano."], who)


func _olga() -> void:
	var who := "Olga"
	if _f("c5_olga_racconto"):
		await Ui.say(["Ricordatevi di chiedere sempre la copia. Delle ricevute, dei contratti, delle promesse."], who)
		return
	GameState.flags["c5_olga_racconto"] = true
	if _f("c4_olga_risposta"):
		await Ui.say(["Alla Banca mi hanno restituito trentacinque euro. E chiesto scusa. Per iscritto.",
			"Ci è voluta una lettera giusta, con le date giuste. Ditelo all'assemblea: le date sono un'arma."], who)
	elif _f("c4_olga_contestazione"):
		await Ui.say(["Ho fatto una contestazione, alla Banca. Sto ancora aspettando la risposta.",
			"Però l'ho fatta. Leggete due volte ogni commissione. A volte c'è davvero due volte."], who)
	else:
		await Ui.say(["Io vengo dalla Banca. Sala d'attesa. Da martedì.", "Ogni tanto bisogna uscire a vedere per chi si aspetta."], who)


func _teo() -> void:
	if GameState.is_robot("teo"):
		await Ui.say(["LA PRECISIONE È PRODUTTIVITÀ.", "DOCUMENTO NON DI MIA COMPETENZA."], "Teo")
		return
	var who := "Teo"
	if _f("c5_rapporto") and _f("c4_teo_aiutato") and not _f("c5_teo_legge"):
		GameState.flags["c5_teo_legge"] = true
		await Ui.say(["* Gli racconti del rapporto dei bilanci. Teo tira fuori il quaderno e scrive le cifre in colonna."])
		await Ui.say(["Manutenzione: è un costo vero. I tetti non si riparano col pensiero positivo.",
			"Il canone CHEAP, invece, è triplicato con il contratto nuovo. Lo stesso servizio, a un prezzo nuovo.",
			"E gli oneri amministrativi: pratiche ferme che costano mentre stanno ferme. Le conosco. Le timbravo."], who)
		return
	if _f("c5_teo_legge"):
		await Ui.say(["Ho disegnato l'assemblea. Tutti hanno la cravatta lunga. Anche i bambini. È un fumetto realistico."], who)
		return
	await Ui.say(["Sono uscito in pausa pranzo. La prima vera. Il sole è più forte delle luci della Banca. Non ci sono abituato."], who)


# --- 5.15 l'assemblea ----------------------------------------------------------------------------

func assembly() -> void:
	var who := organizer()
	if not _f("c5_rapporto"):
		var c: int = await Ui.choose("Il rapporto dei bilanci è nell'archivio della Casa Comune: oggi è aperto.",
			["Cominciate pure", "Prima vado a leggerlo"], who)
		if c != 0:
			await Ui.say(["Va bene. Ti aspettiamo. Siamo bravi ad aspettare: è l'unica cosa che ci fanno fare gratis."], who)
			return
	Ui.cutscene = true
	GameState.flags["c5_assemblea"] = true
	await Ui.say(["* Una cassetta della frutta fa da palco. Le sedie sono tutte spaiate. L'assemblea discute i bilanci."])
	if _f("c5_rapporto"):
		var p: int = await Ui.choose("Hai letto il rapporto dei bilanci.", ["Presenta il rapporto", "Lascia parlare gli altri"], who)
		if p == 0:
			GameState.flags["c5_rapporto_presentato"] = true
			await _present_report()
	await _contributions()
	var prev := str(GameState.flags.get("c5_proposta", ""))
	var ask := "Si vota. Tu cosa sostieni?"
	if prev != "":
		ask += " (In piazza avevi detto: %s.)" % ("nessuna posizione" if prev == "nessuna" else prev)
	var v: int = await Ui.choose(ask, ["Sostengo A: ristrutturazione CHEAP", "Sostengo B: gestione comunitaria", "Sostengo C: rinvio", "Mi astengo"], who)
	var support: String = ["A", "B", "C", "nessuna"][v]
	GameState.flags["c5_sostegno"] = support
	var res := outcome(support)
	GameState.flags["c5_esito"] = res["esito"]
	await Ui.say(res["lines"])
	await Ui.say([_outcome_reaction(str(res["esito"]))], who)
	_dress_after()
	Ui.cutscene = false


func _present_report() -> void:
	var b: Dictionary = GameState.city.get("bilanci", {})
	await Ui.say(["* Leggi le cifre ad alta voce. Manutenzione %s. Canone servizi CHEAP %s. Oneri amministrativi %s. Entrate %s." % [
		GameState.euros(int(b.get("manutenzione", 42000))), GameState.euros(int(b.get("canone_cheap", 19000))),
		GameState.euros(int(b.get("oneri", 11000))), GameState.euros(int(b.get("entrate", 28000)))],
		"* Disavanzo: %s." % GameState.euros(deficit())])
	if GameState.is_robot("ada"):
		await Ui.say(["Quindi una parte dei costi viene proprio dalla gestione CHEAP?"], "Studente")
	else:
		await Ui.say(["Quindi una parte dei costi viene proprio dalla gestione CHEAP?"], "Ada")
	if _f("c5_nadir"):
		await Ui.say(["Questo cambia il modo in cui dobbiamo discutere il problema."], "Nadir")
	if _f("c5_rina"):
		await Ui.say(["Il tetto comunque va riparato."], "Rina")
	else:
		await Ui.say(["Il tetto comunque va riparato."], "Una commerciante")
	await Ui.say(["Sì. E dovremo trovare i soldi."], organizer())
	await Ui.say(["Allora almeno cominciamo dai conti veri."], "Rina" if _f("c5_rina") else "Una commerciante")
	if _f("c5_documento"):
		await Ui.say(["* Poi leggi l'altro foglio: VALUTAZIONE OPPORTUNITÀ — DIREZIONE CHEAP.",
			"* \"La cessazione delle attività gratuite aumenta il potenziale commerciale dell'immobile.\"",
			"* Qualcuno ride. Non è una risata allegra. Poi tutti tornano ai numeri."])
	if _f("c5_fonte_teo") and not GameState.is_robot("teo"):
		await Ui.say(["* E la copia del rapporto 404 di Teo: commissioni duplicate, anche sul conto della Casa Comune. Una riga in più da contestare."])


## Chi si fa avanti, e con cosa. Ogni riga c'è solo se è successa davvero.
func _contributions() -> void:
	if _f("c5_nadir_rete"):
		await Ui.say(["Abbiamo un foglio per i pendolari. Alla Casa Comune ci si trova alle sei meno un quarto. Se resta aperta."], "Nadir")
	if _f("c5_vetrina_aiuto"):
		await Ui.say(["La bottega può fare da punto di raccolta. Il cartone c'è già."], "Rina")
	elif _f("c5_rina_ascoltata"):
		await Ui.say(["Qualunque cosa decidiate, la piazza deve restare attraversabile. Io domattina apro."], "Rina")
	if _f("c5_leda_collabora"):
		await Ui.say(["Ordini condivisi: carta, lampadine, sedie. Costano meno se le compriamo insieme."], "Leda")
	if _f("c5_amir_consegne") and not GameState.is_robot("amir"):
		await Ui.say(["Un giro di consegne alla settimana. A orari miei, ma c'è."], "Amir")
	elif _f("c3_amir") and GameState.is_robot("amir"):
		await Ui.say(["* Amir passa col carrello CHEAP. Non si ferma. CONSEGNA IN CORSO."])
	if _f("c5_olga_racconto") and _f("c4_olga_contestazione"):
		await Ui.say(["Chiedete sempre la copia. E leggete due volte le commissioni."], "Olga")


static func deficit() -> int:
	var b: Dictionary = GameState.city.get("bilanci", {})
	return int(b.get("manutenzione", 42000)) + int(b.get("canone_cheap", 19000)) + int(b.get("oneri", 11000)) - int(b.get("entrate", 28000))


## Le risorse che la gente ha davvero messo sul tavolo (nessun punteggio: un elenco di cose vere).
static func resources() -> Array:
	var out: Array = []
	if _f("c5_nadir_rete"):
		out.append("la rete dei pendolari")
	if _f("c5_vetrina_aiuto"):
		out.append("la bottega di Rina come punto di raccolta")
	if _f("c5_leda_collabora"):
		out.append("gli ordini condivisi di Leda")
	if _f("c5_amir_consegne") and not GameState.is_robot("amir"):
		out.append("le consegne di Amir")
	return out


## L'esito dell'assemblea. Regole esplicite, niente punteggio:
##   pronta  = i conti presentati + le stanze organizzate (anche prima di un robot) + almeno due risorse vere
##   1. pronta, e il protagonista non sostiene A           -> gestione comunitaria
##   2. pronta, ma il protagonista sostiene A               -> rinvio (l'assemblea si divide)
##   3. il protagonista sostiene A                         -> riconversione
##   4. CHEAP ha il progetto di Ada e nessuno ha i conti   -> riconversione
##   5. ci sono i conti, o si chiede tempo, o Ada è umana  -> rinvio / soluzione incompleta
##   6. altrimenti                                           -> riconversione (era l'unica proposta con dei soldi)
static func outcome(support: String) -> Dictionary:
	var info := _f("c5_rapporto_presentato")
	var org := _f("c5_ada_stanze")
	var res := resources()
	var ready := info and org and res.size() >= 2
	var esito := ""
	if ready and support != "A":
		esito = "comunitaria"
	elif ready:
		esito = "rinvio"
	elif support == "A":
		esito = "riconversione"
	elif _f("c5_capo_firmato") and not info:
		esito = "riconversione"
	elif info or support == "C" or not GameState.is_robot("ada"):
		esito = "rinvio"
	else:
		esito = "riconversione"
	var lines: Array = []
	lines.append("* Sul tavolo: " + ("i conti veri, letti ad alta voce." if info else "nessun conto. Solo la lettera di CHEAP, e le cifre di CHEAP."))
	lines.append("* Le stanze: " + ("già organizzate, sei mobili al posto giusto." if org else "ancora da sistemare. Nessuno sa dove si studia e dove ci si incontra."))
	lines.append("* Chi si offre: " + (", ".join(res) + "." if not res.is_empty() else "tante mani alzate, poche disponibili il martedì."))
	match esito:
		"comunitaria":
			lines.append("* Si vota. Passa la gestione comunitaria. Non è perfetta: mancano ancora dei soldi. Ma c'è un foglio con dei nomi, e i nomi ci sono.")
		"riconversione":
			lines.append("* Si vota. Passa la ristrutturazione CHEAP. Il tetto sarà riparato. All'ingresso ci sarà un tornello.")
		_:
			lines.append("* Si vota. Non passa niente del tutto. La chiusura viene rinviata: la revisione dei costi, i fondi, domani.")
	return {"esito": esito, "lines": lines, "ready": ready}


func _outcome_reaction(esito: String) -> String:
	if GameState.is_robot("ada") and esito == "riconversione":
		return "Lo scriviamo nel verbale. Anche chi non era d'accordo. Soprattutto loro."
	match esito:
		"comunitaria":
			return "Non abbiamo trovato una soluzione perfetta. Abbiamo deciso di continuare a cercarla insieme."
		"riconversione":
			return "Va bene. Il tetto sarà riparato. Noi resteremo fuori a guardarlo. Proveremo a entrare con le borse di studio."
		_:
			return "Abbiamo guadagnato tempo. Adesso bisogna usarlo. Il tempo non si recupera, c'era scritto sul cartello."


## La piazza dopo l'assemblea: la folla se ne va, restano le conseguenze.
func _dress_after() -> void:
	for nm in people.keys():
		if nm in ["Leda", "Amir", "Olga", "Teo", "AdaRobot"]:
			continue
		_remove_person(nm)
	var esito := str(GameState.flags.get("c5_esito", ""))
	var label := ""
	var col := Color.WHITE
	match esito:
		"riconversione":
			label = "CENTRO FORMAZIONE CHEAP"
			col = Color("ff3caa")
		"comunitaria":
			label = "CASA COMUNE — GESTIONE CONDIVISA"
			col = Color("8fe08f")
		"rinvio":
			label = "CHIUSURA RINVIATA"
			col = Color("ffe14d")
	if label != "" and not has_node("InsegnaEsito"):
		var l := Label.new()
		l.name = "InsegnaEsito"
		l.text = label
		l.add_theme_font_size_override("font_size", 6)
		l.add_theme_color_override("font_color", col)
		l.add_theme_constant_override("outline_size", 3)
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.position = Vector2(14 * T, 4 * T + 4)
		l.size = Vector2(6 * T, 10)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.z_index = 30
		add_child(l)


# --- 5.16 Nives e l'ultimo badge -----------------------------------------------------------------

## Il badge regalato: Ada aiutata con le stanze, Nadir con il percorso, Rina ascoltata, Ada umana.
## L'assemblea non conta. Non tocca né i soldi né il debito: nessuno ha pagato niente.
static func gift_allowed() -> bool:
	return _f("c5_ada_stanze") and _f("c5_nadir_percorso") and _f("c5_rina_ascoltata") and not GameState.is_robot("ada")


func _badge_machine() -> void:
	var cost := GameState.badge_cost(BADGE)
	if GameState.has_badge(BADGE):
		await Ui.say(["La scala è lì. In cima c'è la Direzione. Buona salita."], NIVES, BADGE_CLERK)
		return
	if not _f("c5_nives"):
		GameState.flags["c5_nives"] = true
		await Ui.say(["Ottomila euro.", "È l'ultimo badge."], NIVES, BADGE_CLERK)
		if GameState.exploited >= 2:
			await Ui.say(["Hai fatto in fretta.", "La Torre apprezza le persone veloci."], NIVES, BADGE_CLERK)
		elif GameState.helped_ids.size() >= 6:
			await Ui.say(["Ti sei fermato spesso.", "Immagino che tu abbia visto molte cose."], NIVES, BADGE_CLERK)
		else:
			await Ui.say(["Sei arrivato fin qui.", "Dev'essere stato faticoso."], NIVES, BADGE_CLERK)
	if gift_allowed():
		await _gift()
		return
	while true:
		var c: int = await Ui.choose("Il badge della Cima: %s. Hai %s." % [GameState.euros(cost), GameState.euros(GameState.money)],
			["Compra (%s)" % GameState.euros(cost), "Cosa c'è in cima?", "Non ora"], NIVES)
		if c == 1:
			await Ui.say(["La Direzione.", "La Presidenza.", "Una vista meravigliosa.", "Dicono."], NIVES, BADGE_CLERK)
			continue
		if c != 0:
			return
		if not GameState.buy_badge(BADGE):
			Sound.sfx("deny")
			await Ui.say(["Non bastano.", "Il centralino è lì. Squilla sempre. È la cosa più puntuale della piazza, dopo il merlo."], NIVES, BADGE_CLERK)
			return
		GameState.flags["c5_badge"] = "comprato"
		Sound.sfx("coin")
		Sound.sfx("stamp")
		open_turnstiles()
		await Ui.say(["Ecco il badge. Debito: {debt}. La scala ha la lucina verde."], NIVES, BADGE_CLERK)
		await _nives_wish()
		return


func _gift() -> void:
	await Ui.say(["Credo di aver perso qualcosa.", "Un badge.", "L'ultimo."], NIVES, BADGE_CLERK)
	Sound.sfx("coin", 1.6)
	await Ui.say(["* Qualcosa di piccolo cade davanti allo sportello. Tic."])
	await Ui.say(["Che distratta."], NIVES, BADGE_CLERK)
	var g: int = await Ui.choose("Il badge della Cima è per terra.", ["Raccoglilo", "Lascialo lì, per ora"], NIVES)
	if g != 0:
		await Ui.say(["Resta lì. Fuori le cose a terra le raccoglie il vento. Ma questo pesa."], NIVES, BADGE_CLERK)
		return
	if GameState.has_badge(BADGE):
		return
	GameState.badges.append(BADGE)
	GameState.flags["badge_day_" + BADGE] = GameState.day
	GameState.flags["c5_badge"] = "regalo"
	GameState.changed.emit()
	Sound.sfx("spare")
	open_turnstiles()
	await Ui.say(["* Hai il badge della Cima. La scala esterna ha la lucina verde."])
	await _nives_wish()


func _nives_wish() -> void:
	await Ui.say(["Quando arriverai in cima…"], NIVES, BADGE_CLERK)
	await get_tree().create_timer(1.0).timeout
	await Ui.say(["Niente.", "Buona fortuna."], NIVES, BADGE_CLERK)


# --- 5.17 la rivelazione del primo gradino: il bilancio della città ---------------------------------

func on_stairs_step(p: Player, _need: String) -> void:
	if _f("c5_rivelazione"):
		return
	GameState.flags["c5_rivelazione"] = true
	if str(GameState.flags.get("c5_badge", "")) == "":
		GameState.flags["c5_badge"] = "altro"
	Ui.cutscene = true
	p.position.y += 4
	Sound.music_pitch(0.5, 1.2)
	await get_tree().create_timer(1.2).timeout
	Sound.music("")
	var layer := CanvasLayer.new()
	layer.layer = 14
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color("0b0a10")
	panel.size = Vector2(560, 300)
	panel.position = Vector2(40, 24)
	panel.modulate.a = 0.0
	layer.add_child(panel)
	var map := TextureRect.new()
	map.texture = load(ART + "mappa_citta.png")
	map.position = Vector2(120, 16)
	panel.add_child(map)
	var a := create_tween()
	a.tween_property(panel, "modulate:a", 1.0, 0.6)
	await a.finished
	# i quattro simboli: i quattro piani di sotto, tutti collegati alla stessa città
	var symbols := [["simbolo_energia.png", "ENERGIA"], ["simbolo_amministrazione.png", "AMMINISTRAZIONE"],
		["simbolo_commercio.png", "COMMERCIO"], ["simbolo_finanza.png", "FINANZA"]]
	for i in symbols.size():
		var s := TextureRect.new()
		s.texture = load(ART + str(symbols[i][0]))
		s.position = Vector2(150 + i * 72, 60)
		panel.add_child(s)
		var l := Label.new()
		l.text = str(symbols[i][1])
		l.position = Vector2(126 + i * 72, 88)
		l.size = Vector2(72, 12)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 7)
		panel.add_child(l)
		Sound.sfx("blip", 1.0 + i * 0.1)
		await get_tree().create_timer(0.5).timeout
	await Ui.say(["Congratulazioni.", "La città è cresciuta.", "Abbiamo aumentato l'efficienza.", "Ottimizzato le risorse.",
		"Migliorato il valore delle attività."], VOICE)
	var y := 180.0
	for line: String in revelation_lines():
		var l := Label.new()
		l.text = line
		l.position = Vector2(30, y)
		l.size = Vector2(500, 20)
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color", Color("8fe08f") if line.contains("POSITIVA") else Color("ff5a50"))
		panel.add_child(l)
		Sound.sfx("blip", 1.3)
		y += 26.0
		await get_tree().create_timer(0.9).timeout
	await get_tree().create_timer(1.0).timeout
	await Ui.say(["La città sta meglio."], VOICE)
	await get_tree().create_timer(1.2).timeout
	await Ui.say(["Perché continuate a lamentarvi?"], VOICE)
	var b := create_tween()
	b.tween_property(panel, "modulate:a", 0.0, 0.8)
	await b.finished
	layer.queue_free()
	Sound.music(music)
	Sound.music_pitch(0.85, 2.0)
	Ui.cutscene = false


## Dati del mondo di CHEAP (non statistiche vere): coerenti con quello che è successo.
func revelation_lines() -> Array:
	var lines: Array = ["RISULTATO COMPLESSIVO: CRESCITA POSITIVA.", "TEMPO MEDIO DISPONIBILE PER I CITTADINI: IN DIMINUZIONE."]
	if str(GameState.flags.get("c5_esito", "")) == "comunitaria":
		lines.append("ACCESSO GRATUITO AI SERVIZI: IN DIMINUZIONE. (UN'ECCEZIONE IN PIAZZA, IN VALUTAZIONE.)")
	else:
		lines.append("ACCESSO GRATUITO AI SERVIZI: IN DIMINUZIONE.")
	lines.append("COSTO DEI BENI ESSENZIALI: IN AUMENTO.")
	return lines


# --- 5.18 lo sguardo indietro ------------------------------------------------------------------------

func on_stairs_top(p: Player) -> bool:
	if _f("c5_fine"):
		Router.goto(NEXT, "default")
		return true
	GameState.flags["c5_fine"] = true
	_write_outcome()
	_dress_for_look_back()
	# salvataggio automatico: si riparte dalla Cima, col capitolo 5 chiuso
	GameState.save_game(NEXT)
	look_back(p, look_back_line(), "CAPITOLO 6", "LA CIMA", NEXT, "default", [],
		"Finalmente puoi decidere. Ma per chi?", ["PRESIDENZA CHEAP.", "SEI ARRIVATO.", "\"Le condizioni di arrivo possono variare.\""])
	return true


## La frase finale: dall'esito dell'assemblea (o dalla sua mancanza). La piazza mostra il resto.
static func look_back_line() -> String:
	if not _f("c5_assemblea"):
		return "Erano tutti nella stessa città. Non stavano vivendo la stessa vita."
	match str(GameState.flags.get("c5_esito", "")):
		"riconversione":
			return "L'edificio era più bello di prima. Non tutti potevano ancora chiamarlo casa."
		"comunitaria":
			return "Non avevano trovato una soluzione perfetta. Avevano deciso di continuare a cercarla insieme."
	return "A volte una decisione non conclude una storia. Decide soltanto cosa bisognerà affrontare domani."


## La piazza vista dall'alto mostra tutto quello che è vero, non solo la frase.
func _dress_for_look_back() -> void:
	_dress_after()
	# Ada: seduta sulla soglia con un libro, o con i volantini CHEAP
	if GameState.is_robot("ada"):
		var r := _add_person("AdaRobot", str(GameState.npc_data("ada").get("sheet")), Vector2i(15, 11), "idle_down", func() -> void: pass, false)
		_antenna(r)
	elif _f("c5_ada"):
		_add_person("AdaSoglia", str(GameState.npc_data("ada").get("sheet")), Vector2i(18, 11), "idle_down", func() -> void: pass)
	# Nadir alla fermata: da solo, o con altri pendolari se la rete è partita
	if _f("c5_nadir_rete"):
		_add_person("Pendolare0", "char_15", Vector2i(26, 15), "idle_left", func() -> void: pass)
		_add_person("Pendolare1", "char_11", Vector2i(27, 15), "idle_left", func() -> void: pass)
	# la manifestazione senza assemblea: cartelli rimasti a terra
	if _f("c5_protesta") and not _f("c5_assemblea"):
		for i in 3:
			var s := Sprite2D.new()
			s.texture = load(ART + "cartello_protesta.png")
			s.position = cell_center(Vector2i(15 + i * 5, 17 + i % 2))
			s.rotation = 1.4 + i * 0.3
			add_child(s)
	if _f("c5_vetrina"):
		_broken_window()
	# l'autobus arriva, finalmente, mentre nessuno guarda
	var board := find_child("Tabellone", true, false) as Node2D
	if board:
		var l := Label.new()
		l.text = "IN ARRIVO"
		l.add_theme_font_size_override("font_size", 6)
		l.add_theme_color_override("font_color", Color("ffe14d"))
		l.position = Vector2(-2, -44)
		l.z_index = 30
		board.add_child(l)


## Le conseguenze per il capitolo 6, tutte in un posto, coi nomi della specifica:
## GameState.flags["chapter_5"]. Si scrive una volta sola, quando il capitolo finisce davvero.
func _write_outcome() -> void:
	var f := GameState.flags
	var connected: bool = _f("c5_contatore") or _f("c5_b4_capito") or _f("c5_fonte_teo") or _f("c5_teo_legge") \
		or _f("c5_leda_collabora") or _f("c5_amir_consegne") or _f("c5_olga_racconto")
	var support := str(f.get("c5_sostegno", ""))
	f["chapter_5"] = {
		"entered": f.get("c5_arrivo", false), "completed": true,
		"ada": {"met": f.get("c5_ada", false), "room_minigame_completed": f.get("c5_ada_stanze", false),
			"helped": "ada" in GameState.helped_ids, "original_project_read": f.get("c5_progetto_letto", false),
			"credit_stolen": f.get("c5_capo_firmato", false), "robotized": GameState.is_robot("ada")},
		"nadir": {"met": f.get("c5_nadir", false), "route_minigame_completed": f.get("c5_nadir_percorso", false),
			"helped": "nadir" in GameState.helped_ids, "commuters_network_proposed": f.get("c5_nadir_rete", false)},
		"rina": {"met": f.get("c5_rina", false), "concerns_heard": f.get("c5_rina_ascoltata", false),
			"window_damage_seen": f.get("c5_vetrina", false), "window_help_offered": f.get("c5_vetrina_aiuto", false)},
		"turn": {"completed_count": int(f.get("c5_turni", 0)), "errors_found": int(f.get("c5_trovate", 0)),
			"incorrect_assignments": int(f.get("c5_sbagliate", 0)), "quick": int(f.get("c5_rapidi", 0))},
		"boss": {"call_received": f.get("c5_capo", false), "offer_resolved": f.get("c5_capo_chiuso", false),
			"offer_accepted": f.get("c5_capo_firmato", false)},
		"protest": {"started": f.get("c5_protesta", false), "assembly_attended": f.get("c5_assemblea", false),
			"journalist_spoken_to": f.get("c5_giornalista", false), "economic_report_presented": f.get("c5_rapporto_presentato", false),
			"proposal_supported": null if support == "" else support,
			"community_outcome": f.get("c5_esito", null) if _f("c5_assemblea") else null,
			"headline": f.get("c5_titolo", null)},
		"report": {"basic_read": f.get("c5_rapporto", false), "hidden_document_found": f.get("c5_documento", false),
			"prior_chapters_connected": connected},
		"secret_scene_seen": f.get("c5_segreta", false),
		"exit": {"badge_obtained": GameState.has_badge(BADGE), "badge_source": f.get("c5_badge", null),
			"revelation_seen": f.get("c5_rivelazione", false), "lookback_seen": true},
	}


# --- la scena segreta: i biscotti sulla panchina ------------------------------------------------------

static func secret_conditions() -> bool:
	return _f("c5_ada") and _f("c5_lettera") and not GameState.is_robot("ada") and _f("c5_nadir") \
		and _f("c5_rina_ascoltata") and _f("c5_assemblea")


func _secret_ready() -> bool:
	return not _f("c5_segreta") and not _f("c5_rivelazione") and secret_conditions()


## Rina, Ada e Nadir sulla panchina della piazza, la sera dopo l'assemblea.
func _secret_setup() -> void:
	for id in ["rina", "nadir"]:
		var n := _npc(id)
		if n:
			n.visible = false
			n.process_mode = Node.PROCESS_MODE_DISABLED
			n.remove_from_group("interactable")
	var seats := [["PancaAda", str(GameState.npc_data("ada").get("sheet")), Vector2i(6, 17)], ["PancaRina", str(GameState.npc_data("rina").get("sheet")), Vector2i(7, 17)], ["PancaNadir", str(GameState.npc_data("nadir").get("sheet")), Vector2i(8, 18)]]
	for s: Array in seats:
		var c := CharSprite.new()
		c.name = s[0]
		c.sheet = s[1]
		c.anim = "idle_down"
		c.grey = true
		c.position = cell_feet(s[2])
		world.add_child(c)
		block(Rect2i(s[2], Vector2i.ONE))


func _panchina() -> void:
	if _secret_ready():
		await _secret()
		return
	if _f("c5_segreta"):
		await Ui.say(["* La panchina. Qualche briciola di biscotto. Il cartello PREMIUM è stato girato verso il muro."])
		return
	await Ui.say(["* Una panchina di legno. Gratis. Sulla spalliera, un adesivo: \"PRESTO DISPONIBILE IN VERSIONE PREMIUM\"."])


func _secret() -> void:
	GameState.flags["c5_segreta"] = true
	Ui.cutscene = true
	var dusk := CanvasModulate.new()
	dusk.color = Color.WHITE
	add_child(dusk)
	var tw := dusk.create_tween()
	tw.tween_property(dusk, "color", Color(0.85, 0.7, 0.8), 1.5)
	await tw.finished
	await Ui.say(["* È sera. Sulla panchina, Ada, Rina e Nadir. Rina ha un sacchetto di carta."])
	await Ui.say(["Sono avanzati dal negozio."], "Rina")
	await Ui.say(["Sono ancora buoni?"], "Ada")
	await Ui.say(["Ovviamente."], "Rina")
	await Ui.say(["* Nadir prende un biscotto."])
	Sound.sfx("crack")
	await Ui.say(["Credo di aver rotto un dente."], "Nadir")
	await Ui.say(["Allora sono croccanti."], "Rina")
	await Ui.say(["* Ada ride."])
	await Ui.say(["Sapete cosa mi fa paura?"], "Ada")
	await Ui.say(["I biscotti?"], "Nadir")
	await Ui.say(["Anche.", "Che tra dieci anni saremo ancora qui a cercare un posto dove stare."], "Ada")
	await Ui.say(["Può darsi.", "Però oggi un posto ce l'abbiamo."], "Rina")
	await Ui.say(["Ed è pure gratis."], "Nadir")
	var sign := Sprite2D.new()
	sign.texture = load(ART + "panca_premium.png")
	sign.position = cell_center(BENCH) + Vector2(16, -30)
	sign.z_index = 30
	sign.modulate.a = 0.0
	add_child(sign)
	Sound.sfx("spark", 1.4)
	var s := sign.create_tween()
	s.tween_property(sign, "modulate:a", 1.0, 0.3)
	await s.finished
	await Ui.say(["* Si accende un cartello: PANCA PREMIUM — ABBONAMENTO IN ARRIVO."])
	await Ui.say(["Domani lo smonto."], "Rina")
	var back := dusk.create_tween()
	back.tween_property(dusk, "color", Color.WHITE, 1.5)
	back.tween_callback(dusk.queue_free)
	Ui.cutscene = false


# --- l'aiuto (minigiochi di Ada e Nadir) -------------------------------------------------------------

func _offer(id: String, who: String) -> void:
	var h: Dictionary = GameState.npc_data(id).get("help", {})
	var c: int = await Ui.choose(str(h.get("ask", "")), ["Dai una mano (1 ora)", "Non ora"], who)
	if c != 0:
		return
	Router.minigame(Npc.minigame_cfg(id, who, h, scene_file_path, player.global_position))
