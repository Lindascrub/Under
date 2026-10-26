extends EditorRoom
## Capitolo 4 — La Banca (piano -2). La scena è fatta nell'editor (banca.tscn): qui c'è solo la logica.
## Una banca elegante e quasi buffa, che diventa inquietante: il debito di 7 miliardi non ha un
## contratto. Olga (la sala d'attesa) e Teo (le pratiche) sono grigi; il capo offre 3.000 € per il
## rapporto 404 di Teo. L'origine vera del debito resta per il Capitolo 6.
## Tutto è descritto in docs/CHAPTER_04_BANK.md (flag c4_*, e alla fine il riassunto "chapter_4").

const NIVES := "Nives"
const BOSS := "Il capo"
const TERMINAL := "Terminale"
const DISPENSER := "Distributore"
const VOICE := "Voce CHEAP"
const BADGE := "0"
## Il Capitolo 5 (La Città) lo sta facendo qualcun altro: finché la scena non c'è, si sale all'Ufficio.
const CITY := "res://chapters/c5/citta.tscn"
const ANTENNA := "res://art/c4/antenna_robot.png"
const STAMP := "res://art/c4/timbro.png"
const LETTER := "res://art/c4/lettera.png"


## Dove portano le scale: la Città se esiste già, se no il Piano Terra di prima.
static func next_scene() -> String:
	return CITY if ResourceLoader.exists(CITY) else Router.OFFICE


## Un po' di spazio sopra il muro: l'insegna e il display dei numeri non finiscono sotto la barra in alto.
func build() -> void:
	super()
	cam_rect = cam_rect.grow_side(SIDE_TOP, 32)


func setup() -> void:
	if GameState.is_robot("teo"):
		_robot_teo()
	if _secret_ready():
		_secret_setup()


func enter() -> void:
	if not GameState.flags.get("c4_arrivo", false):
		await _arrival()
	await show_pending()
	if Ui.transitioning:
		return
	# le cose rimaste a metà (un salvataggio, un minigioco) riprendono da dove erano
	if GameState.flags.get("c4_furto_ok", false) and not GameState.flags.get("c4_capo_chiuso", false):
		await _report_choice()
	elif Router.spawn == "_mg" and GameState.flags.get("c4_olga_doppia", false) \
			and not GameState.flags.get("c4_olga_contestazione", false):
		await _olga_complaint()


## Al -2 il badge non si regala a chi ha aiutato "tutti": decide Nives (vedi _badge_machine).
func _floor_gift() -> void:
	pass


func _npc(id: String) -> Npc:
	for n in get_tree().get_nodes_in_group("npc"):
		if n is Npc and (n as Npc).id == id and is_instance_valid(n):
			return n
	return null


func _f(key: String) -> bool:
	return bool(GameState.flags.get(key, false))


# --- 4.01 l'arrivo ----------------------------------------------------------------

func _arrival() -> void:
	GameState.flags["c4_arrivo"] = true
	Ui.cutscene = true
	await get_tree().create_timer(0.3).timeout
	Sound.sfx("door")
	await get_tree().create_timer(0.4).timeout
	Sound.sfx("ding", 1.6)
	await Ui.say(["* Una porta metallica si apre. Un campanellino suona, educato.",
		"* Un'insegna enorme, dorata: BANCA CHEAP.", "* Sotto: \"IL TUO FUTURO È IL NOSTRO PRESENTE.\""])
	await Ui.say(["* Una fila di persone grigie attraversa l'atrio. Il marmo è così lucido che si specchiano.",
		"* Sembrano due file. Nessuna delle due si muove."])
	Sound.sfx("blip", 0.7)
	await Ui.say(["* Il distributore accanto alle scale ti dà un biglietto, senza chiedere.",
		"* NUMERO %s." % str(GameState.bank.get("numero", "7.000.000.001")),
		"* Sul display in alto: ORA SERVIAMO IL NUMERO %d." % int(GameState.bank.get("servito", 4))])
	await Ui.say(["La ringraziamo per la pazienza.", "La pazienza è gratuita."], DISPENSER)
	await get_tree().create_timer(0.9).timeout
	await Ui.say(["Per ora."], DISPENSER)
	Ui.cutscene = false


func _insegna() -> void:
	await Ui.say(["* BANCA CHEAP. \"IL TUO FUTURO È IL NOSTRO PRESENTE.\"",
		"* Le lettere sono d'oro. Una è un po' storta. Nessuno la raddrizza: costerebbe un preventivo."])


func _display() -> void:
	await Ui.say(["* ORA SERVIAMO IL NUMERO %d." % int(GameState.bank.get("servito", 4)),
		"* Il tuo biglietto dice %s. Il display non ha abbastanza cifre per arrivarci." % str(GameState.bank.get("numero", ""))])


## Il distributore dei numeri: la seconda volta offre il SALTAFILA (una battuta, non un sistema).
func _distributore() -> void:
	if not _f("c4_saltafila_chiesto"):
		GameState.flags["c4_saltafila_chiesto"] = true
		await Ui.say(["Vuoi acquistare il servizio SALTAFILA?"], DISPENSER)
		var c: int = await Ui.choose("SALTAFILA", ["Sì.", "No.", "Quanto costa?"], DISPENSER)
		if c == 2:
			await Ui.say(["Un minuto del tuo futuro.", "Le tariffe sono soggette a variazione."], DISPENSER)
			c = await Ui.choose("SALTAFILA: un minuto del tuo futuro.", ["Va bene.", "No, grazie."], DISPENSER)
			c = 0 if c == 0 else 1
		if c == 0:
			GameState.flags["c4_saltafila"] = true
			Sound.sfx("coin", 0.7)
			await Ui.say(["Servizio SALTAFILA attivato.", "Nuova posizione: 7.000.000.000.",
				"Hai superato una persona. Complimenti."], DISPENSER)
			await Ui.say(["* Non ti senti diverso. Forse un minuto più vecchio. Forse no."])
		else:
			await Ui.say(["La sua scelta è stata registrata.", "Anche la sua pazienza."], DISPENSER)
		return
	await Ui.say([["La ringraziamo per la pazienza.", "Il prossimo numero sarà chiamato a breve. La brevità è soggetta a variazione.",
		"Numero non valido. Il suo numero è ancora valido. Le due cose non si escludono."].pick_random()], DISPENSER)


# --- 4.02 / 4.03 / 4.10 Olga ---------------------------------------------------------------

func talk_olga(_npc_node: Npc) -> bool:
	if _f("c4_rivelazione"):
		return false
	if not _f("c4_olga"):
		await _olga_first()
	elif _f("c4_olga_doppia") and not _f("c4_olga_contestazione"):
		await _olga_complaint()
	elif _f("c4_olga_contestazione") and not _f("c4_olga_risposta"):
		if GameState.day > int(GameState.flags.get("c4_olga_giorno", GameState.day)):
			await _olga_return()
		else:
			await Ui.say(["La contestazione è partita. Ora si aspetta.", "Io aspetto benissimo. Ho esperienza: sono qui da martedì."], "Olga")
	elif not _f("c4_olga_ordinati"):
		await Ui.say([["Le ricevute sono ancora qui. Mi guardano. Io guardo loro. Nessuna delle due cede.",
			"Ho riletto l'estratto conto. Tre volte. È sempre lui ad avere ragione, dicono."].pick_random()], "Olga")
		await _offer("olga", "Olga")
	else:
		await Ui.say([["Un ritardo, una commissione. È aritmetica, non beneficenza.",
			"Il pistacchio era buono. Il mutuo no. Ma il pistacchio era buono.",
			"Se ti serve un cappello per sentirti pazzo, ne ho uno. Non mi serve più."].pick_random()], "Olga")
	return true


func _olga_first() -> void:
	var who := "Olga"
	GameState.flags["c4_olga"] = true
	GameState.flags["met_olga"] = true
	await Ui.say(["Sei in fila anche tu?", "Io sono qui da martedì."], who)
	var c: int = await Ui.choose("Cosa rispondi?", ["Quale martedì?", "(Annuisci)"], who)
	if c == 0:
		await Ui.say(["Non ricordo.", "Il calendario è stato pignorato."], who)
	else:
		await Ui.say(["Bravo. In banca annuire è la lingua ufficiale."], who)
	await Ui.say(["Anni fa ho preso un prestito per la casa. Una casa piccola. Il prestito, no.",
		"Ho pagato le rate. Tutte. Una in ritardo: c'era lo sciopero dei treni, e io non volo.",
		"Eppure il saldo resta alto. Più pago, più mi spiegano che è normale."], who)
	await Ui.say(["* Apre la borsa. È piena di ricevute piegate in quattro, in ordine perfetto. Per colore."])
	await Ui.say(["Ho tutti gli scontrini.", "Mi hanno detto che non bastano.", "Allora ho chiesto quanti ne servono.",
		"Mi hanno offerto un prestito per comprare una scatola più grande."], who)
	await _offer("olga", who)


## Dopo LE RATE MANCANTI: la contestazione per la commissione addebitata due volte.
func _olga_complaint() -> void:
	var who := "Olga"
	var fee := int(GameState.bank.get("olga", {}).get("rimborso", 35))
	await Ui.say(["La commissione di %s. Due volte: il 18 e il 19 giugno." % GameState.euros(fee),
		"Il contratto dice: una per ogni ritardo. Io ho fatto un ritardo solo. Me lo ricordo: c'era lo sciopero."], who)
	var c: int = await Ui.choose("La commissione doppia.", ["Prepariamo la contestazione", "Più tardi"], who)
	if c != 0:
		await Ui.say(["Più tardi. La parola preferita di questo posto. Va bene, ti aspetto. Sono brava."], who)
		return
	GameState.flags["c4_olga_contestazione"] = true
	GameState.flags["c4_olga_giorno"] = GameState.day
	Sound.sfx("stamp")
	await Ui.say(["* Scrivete la lettera insieme. Olga detta, tu scrivi. Le date sono giuste, le cifre tornano.",
		"* Olga la infila nella fessura RECLAMI. La fessura fa un rumore soddisfatto."])
	await Ui.say(["Non chiedo che mi restituiscano la casa. Solo i soldi che non dovevo.",
		"Un ritardo, una commissione. È aritmetica, non beneficenza.",
		"La risposta arriva dopo una notte. Dicono. Io ne ho già passate parecchie qui."], who)


## 4.10: la risposta alla contestazione (dopo almeno una notte). Rimborso: quello del documento.
func _olga_return() -> void:
	var who := "Olga"
	var fee := int(GameState.bank.get("olga", {}).get("rimborso", 35))
	GameState.flags["c4_olga_risposta"] = true
	await Ui.say(["* Olga ha in mano una lettera col logo dorato. La tiene come si tiene un biglietto vincente."])
	await Ui.say(["Avevo ragione."], who)
	var c: int = await Ui.choose("Olga ha ricevuto la risposta.", ["Quanto hai recuperato?", "Complimenti!"], who)
	if c == 1:
		await Ui.say(["Grazie. A te, soprattutto. E un po' a me."], who)
	await Ui.say(["Mi hanno restituito una commissione. %s." % GameState.euros(fee), "Mi hanno anche chiesto scusa.",
		"Per iscritto.", "Credo sia la cosa più costosa che abbiano mai prodotto."], who)
	await Ui.say(["Il mutuo resta. Il saldo è sempre alto. Non è cambiato il mondo.",
		"Ma sai cosa ci faccio, con questi soldi?", "Un gelato al pistacchio. Lo desidero dal 2016.",
		"Costava troppo, per una che paga le rate. Oggi lo paga la banca. Avrà un sapore migliore."], who)


## Offre il minigioco di aiuto di una persona (si può riprovare: conta solo se riesce).
func _offer(id: String, who: String) -> void:
	var h: Dictionary = GameState.npc_data(id).get("help", {})
	if not GameState.has_time(GameState.COST_HELP_TIME):
		await Ui.say(["* È tardi. Per oggi non c'è più tempo per dare una mano. (Una stellina fa passare la notte.)"])
		return
	var c: int = await Ui.choose(str(h.get("ask", "")), ["Dai una mano (1 ora)", "Non ora"], who)
	if c != 0:
		return
	Router.minigame(Npc.minigame_cfg(id, who, h, scene_file_path, player.global_position))


# --- 4.04 / 4.05 Teo --------------------------------------------------------------------------

func talk_teo(_npc_node: Npc) -> bool:
	if _f("c4_rivelazione"):
		return false
	if not _f("c4_teo"):
		await _teo_first()
	elif not _f("c4_teo_aiutato"):
		await Ui.say([["Altre sei pratiche. Le altre sei di prima sono diventate sette.",
			"Mi hanno dato un obiettivo nuovo: finire prima di cominciare."].pick_random()], "Teo")
		await _offer("teo", "Teo")
	elif _f("c4_teo_lasciato") and not _f("c4_teo_grazie"):
		GameState.flags["c4_teo_grazie"] = true
		await Ui.say(["Il rapporto ha ancora il mio nome.", "Lo guardo ogni tanto. Come una foto."], "Teo")
	else:
		await Ui.say([["Ho letto una pratica dall'inizio alla fine. Era bellissima. Era un mutuo.",
			"Oggi ho disegnato una vignetta. Una sola. In pausa pranzo. Era una pausa vera.",
			"Mi hanno chiesto perché sono più lento. Ho risposto: perché adesso leggo. Hanno preso nota."].pick_random()], "Teo")
	return true


func _teo_first() -> void:
	var who := "Teo"
	GameState.flags["c4_teo"] = true
	GameState.flags["met_teo"] = true
	await Ui.say(["Benvenuto!", "Hai un appuntamento?"], who)
	var c: int = await Ui.choose("Cosa rispondi?", ["Sì.", "No."], who)
	if c == 1:
		await Ui.say(["Perfetto! Neanche io.", "Eppure siamo entrambi qui."], who)
	else:
		await Ui.say(["Davvero? Con chi? Io non ne ho mai avuto uno.", "Scherzo. Più o meno."], who)
	await Ui.say(["A volte vorrei avere più tempo per leggere le pratiche.", "Ma devo finirle in fretta.",
		"Mi valutano sulla velocità."], who)
	await Ui.say(["* Sotto la pila di pratiche spunta l'angolo di un quaderno a quadretti. Ci sono dei disegni."])
	await _offer("teo", who)


## Il quaderno di fumetti (il sogno di Teo). Se Teo è un robot, il quaderno è rimasto lì.
func _quaderno() -> void:
	if GameState.is_robot("teo"):
		GameState.flags["c4_quaderno_robot"] = true
		await Ui.say(["* Il quaderno è rimasto sulla scrivania. Nessuno lo apre più.",
			"* Il fumetto raffigura un impiegato che vola fuori dalla finestra.", "* La seconda pagina è incompleta."])
		await Ui.say(["ATTIVITÀ NON RILEVANTE.", "TORNARE ALLE PRATICHE."], "Teo")
		return
	if _f("c4_teo_sogno"):
		await Ui.say(["* Il quaderno di Teo. Nell'ultima vignetta l'impiegato ha un mantello fatto con la cravatta.",
			"* Il mantello è troppo lungo. Come la cravatta."])
		return
	GameState.flags["c4_teo_sogno"] = true
	await Ui.say(["* Un quaderno di fumetti, nascosto sotto i documenti. Un impiegato con la cravatta lunghissima.",
		"* Nella vignetta dopo, la cravatta diventa un mantello."])
	await Ui.say(["Quello?", "È un progetto.", "Prima o poi vorrei pubblicarlo.", "Appena avrò un lavoro un po' più tranquillo."], "Teo")


func _archivio() -> void:
	await Ui.say(["* L'archivio. Cassetti con le lettere: A-C, D-F, G-L...",
		"* L'ultimo cassetto ha un'etichetta senza lettere, solo un numero lunghissimo. È vuoto."])


# --- 4.06 il TURNO: le pratiche raggruppate (dal terzo turno) -----------------------------------

## Dopo un paio di turni allo sportello si può scegliere il turno veloce: stessa paga base, niente
## minigioco, nessuna pratica letta. Così non serve ripetere venti volte lo stesso gioco.
func _station(j: Dictionary) -> void:
	var quick: Dictionary = GameState.bank.get("rapido", {})
	if GameState.worked_today or int(GameState.flags.get("c4_turni", 0)) < int(quick.get("dopo", 2)):
		await super(j)
		return
	var c: int = await Ui.choose(str(j.get("station_text", "")) + "\nIniziare il turno? (10 ore)",
		["Turno allo sportello", "Pratiche raggruppate (veloce)", "Non ancora"])
	if c == 0:
		start_job(j)
	elif c == 1:
		await quick_turn()


func quick_turn() -> void:
	if GameState.worked_today:
		return
	var pay := int(GameState.bank.get("rapido", {}).get("paga", 800))
	GameState.finish_hard_job(pay)
	GameState.flags["c4_turni"] = int(GameState.flags.get("c4_turni", 0)) + 1
	GameState.flags["c4_raggruppate"] = int(GameState.flags.get("c4_raggruppate", 0)) + 1
	for i in 3:
		Sound.sfx("stamp", 0.9 + i * 0.1)
		await get_tree().create_timer(0.25).timeout
	Sound.sfx("coin")
	await Ui.say(["* Le pratiche arrivano già raggruppate, cento alla volta. Il timbro scende. Nessuno le legge.",
		"* Paga: %s." % GameState.euros(pay), "* Pratiche lette: zero. Punteggio di efficienza: eccellente."])
	# il capo chiama quando finisce il primo turno, anche quello veloce
	await show_pending()


# --- 4.07 la telefonata del capo -----------------------------------------------------------------

## Il capo chiama dopo il primo turno, una volta sola: 3.000 € per il rapporto 404 di Teo.
## "Va bene" e "Ci penso" lasciano l'offerta aperta sul terminale del rapporto (c4_capo_sospeso);
## "No" la chiude per sempre (c4_capo_chiuso). Il rapporto c'è anche se Teo non è stato aiutato.
func _boss_call() -> void:
	GameState.flags["boss_call_done_%d" % GameState.day] = true
	GameState.flags["boss_call_floor_" + GameState.floor_id] = true
	if _f("c4_capo") or GameState.is_robot("teo"):
		return
	GameState.flags["c4_capo"] = true
	var prize := int(GameState.bank.get("premio_capo", 3000))
	Sound.sfx("alarm", 0.7)
	await Ui.say(["* DRRRRING. Il telefono squilla. È il capo.",
		"* Non lo vedi, ma lo senti: monocolo, cravatta fatta di banconote."])
	await Ui.say(["ECCO IL MIO INVESTIMENTO PREFERITO!", "Come va, piccolo capitale umano?"], BOSS)
	var c: int = await Ui.choose("Cosa rispondi?", ["Sto lavorando.", "Non chiamarmi così.", "Quanto mi paghi?"], BOSS)
	match c:
		0:
			await Ui.say(["Bravo! Lavorare è il modo più economico di essere felici. Per me."], BOSS)
		1:
			await Ui.say(["Hai ragione. Capitale umano è troppo. Diciamo: risorsa."], BOSS)
		_:
			await Ui.say(["Ah! Vedo che il Mercato ti ha insegnato qualcosa!"], BOSS)
	await Ui.say(["Senti, ho una proposta straordinaria.", "Quel ragazzo, Teo, ha individuato un errore enorme nei nostri registri.",
		"Se lo segnala lui, riceverà una promozione.", "Se lo segnali tu, riceverai una promozione molto più interessante.",
		"%s." % GameState.euros(prize)], BOSS)
	if _f("c4_teo_aiutato"):
		await Ui.say(["Ho visto che l'hai aiutato con le pratiche. Ottimo! Così sai già dove tiene le cose."], BOSS)
	while true:
		var d: int = await Ui.choose("Il rapporto 404: %s." % GameState.euros(prize), ["Va bene", "Ci penso", "Perché io?", "No. È di Teo."], BOSS)
		if d == 2:
			await Ui.say(["Perché una scoperta importante vale molto.", "Soprattutto se l'ha fatta la persona giusta."], BOSS)
			continue
		if d == 3:
			_close_offer()
			await Ui.say(["Peccato. Il merito è come il denaro: se non lo prendi tu, lo prende qualcun altro.",
				"L'offerta è chiusa."], BOSS)
			return
		GameState.flags["c4_capo_sospeso"] = true
		if d == 0:
			await Ui.say(["Bravo! Il rapporto 404 è sul terminale accanto all'archivio.",
				"Teo sistema i documenti lì davanti. Ogni tanto si gira. Tu, quando si gira, sii un mobile."], BOSS)
		else:
			await Ui.say(["Pensaci pure! Il terminale aspetta. I terminali sono pazientissimi. Le persone, meno."], BOSS)
		return


func _close_offer() -> void:
	GameState.flags["c4_capo_chiuso"] = true
	GameState.flags["c4_capo_sospeso"] = false
	GameState.flags["promotions_refused"] = int(GameState.flags.get("promotions_refused", 0)) + 1


# --- 4.08 il rapporto 404: un, due, tre, stella ------------------------------------------------

func _rapporto() -> void:
	if _f("c4_capo_firmato"):
		await Ui.say(["* RAPPORTO DI VERIFICA N. 404. AUTORE: {name}.",
			"* Lo schermo è lucido. Ci si vede dentro Teo, dietro di te, che timbra."])
		return
	if _f("c4_furto_ok") and not _f("c4_capo_chiuso"):
		await _report_choice()
		return
	if _f("c4_capo_sospeso") and not _f("c4_capo_chiuso"):
		await Ui.say(["* RAPPORTO DI VERIFICA N. 404. In attesa di firma.",
			"* Davanti all'archivio, Teo sistema i documenti. Ogni tanto si gira."])
		var c: int = await Ui.choose("Il rapporto di Teo.", ["Avvicinati di nascosto", "Lascia stare, per ora", "Chiudi l'offerta per sempre"])
		match c:
			0:
				await Ui.say(["Attento, campione. La meritocrazia richiede precisione!"], BOSS)
				start_steal("teo", GameState.promotion("teo"), {
					"intro": ["* L'archivio. Teo sistema i documenti, cassetto dopo cassetto. Ogni tanto si gira.",
						"* Il terminale del rapporto 404 è lì in fondo. Basta arrivarci senza che ti veda."],
					"win_flag": "c4_furto_ok",
				})
			2:
				_close_offer()
				await Ui.say(["* Premi ANNULLA. Il terminale chiede tre volte se sei sicuro. Tre volte, sì."])
		return
	GameState.flags["c4_teo_rapporto"] = true
	if _f("c4_teo_copia"):
		await Ui.say(["* RAPPORTO DI VERIFICA N. 404. AUTORE: TEO.", "* SEGNALATO ALL'UFFICIO CONTROLLI. IN ATTESA DI RISPOSTA.",
			"* Sotto, a matita: un omino col mantello che aspetta."])
		return
	await Ui.say(["* RAPPORTO DI VERIFICA N. 404.", "* AUTORE: TEO.", "* IRREGOLARITÀ RISCONTRATA: COMMISSIONI DUPLICATE."])
	if _f("c4_capo_chiuso") and not GameState.is_robot("teo"):
		await _offer_report()


## Rifiutata l'offerta, il rapporto si può segnalare davvero (con il nome di Teo).
func _offer_report() -> void:
	var c: int = await Ui.choose("Il rapporto 404 non è ancora stato inviato.", ["Aiuta Teo a segnalarlo", "Lascia stare"], "Teo")
	if c != 0:
		return
	GameState.flags["c4_teo_copia"] = true
	Sound.sfx("stamp")
	await Ui.say(["* Teo preme INVIA. Poi stampa una copia, per sicurezza. Poi un'altra, per sicurezza della sicurezza."])
	await Ui.say(["L'ho mandato con il mio nome.", "Mi tremano le mani. Credo sia una bella sensazione. Non ne sono sicuro: è nuova."], "Teo")


## La scelta al terminale (dopo che sei arrivato senza farti vedere). Leggere non decide niente.
func _report_choice() -> void:
	var prize := int(GameState.bank.get("premio_capo", 3000))
	GameState.flags["c4_teo_rapporto"] = true
	Sound.sfx("blip", 1.2)
	await Ui.say(["* RAPPORTO DI VERIFICA N. 404.", "* AUTORE: TEO.", "* IRREGOLARITÀ RISCONTRATA: COMMISSIONI DUPLICATE.",
		"* NUOVO RESPONSABILE: ______.", "* BONUS: %s." % GameState.euros(prize)])
	while true:
		var c: int = await Ui.choose("NUOVO RESPONSABILE: ______", ["Firma con il tuo nome", "Lascia la firma di Teo", "Leggi il rapporto"])
		if c == 2:
			GameState.flags["c4_rapporto_letto"] = true
			var lines: Array = ["* Il rapporto è ordinato, preciso. Ogni riga ha una data.",
				"* \"Su 1.200 conti controllati, 340 hanno la stessa commissione addebitata due volte, a un giorno di distanza.\""]
			if _f("c4_olga"):
				lines.append("* Nell'elenco c'è anche Olga. Sala d'attesa. Da martedì.")
			lines.append("* In fondo, a matita, un omino col mantello indica il numero 340.")
			await Ui.say(lines)
			continue
		if c == 1:
			_close_offer()
			GameState.flags["c4_teo_lasciato"] = true
			await Ui.say(["* Lasci la firma di Teo. Il terminale torna a fare il terminale."])
			await Ui.say(["Come vuoi. Il merito è come il denaro: se non lo prendi tu, lo prende qualcun altro."], BOSS)
			if not GameState.is_robot("teo"):
				await Ui.say(["Hai lasciato il mio nome?", "Oh.", "Non so cosa dire."], "Teo")
				await _offer_report()
			return
		await _sign(prize)
		return


## Firmare: il premio una volta sola, LV su, Teo diventa un robot (tutto prima di qualunque attesa).
func _sign(prize: int) -> void:
	if _f("c4_capo_firmato"):
		return
	GameState.flags["c4_capo_firmato"] = true
	GameState.flags["c4_capo_chiuso"] = true
	GameState.flags["c4_capo_sospeso"] = false
	GameState.flags["c4_teo_rubato"] = true
	GameState.exploit("teo", prize)
	GameState.spend(GameState.COST_EASY_JOB)
	# è una scena: durante la trasformazione (che non ha dialoghi) non si cammina e non si parla
	Ui.cutscene = true
	Sound.sfx("stamp")
	await Ui.say(["* Scrivi il tuo nome. Il terminale fa BIP.", "* BONUS ACCREDITATO: %s." % GameState.euros(prize)])
	var t := _npc("teo")
	if t:
		t.sprite.play("idle_down")
		t.sprite.speed_scale = 0.0
		await t.reveal(1.5)
	_robot_teo()
	Sound.sfx("glitch", 0.8)
	await Ui.say(["Fantastico. Sei proprio nato per questo lavoro!"], BOSS)
	await Ui.say(["LA PRECISIONE È PRODUTTIVITÀ."], "Teo")
	await Ui.say([GameState.level_up_line()])
	Ui.cutscene = false


## Teo robot si riconosce anche senza colori: l'antenna e il timbro che batte sempre allo stesso ritmo.
func _robot_teo() -> void:
	var t := _npc("teo")
	if t == null or t.has_node("Antenna"):
		return
	var antenna := Sprite2D.new()
	antenna.name = "Antenna"
	antenna.texture = load(ANTENNA)
	antenna.position = Vector2(0, -27)
	antenna.z_index = 1
	t.add_child(antenna)
	var stamp := Sprite2D.new()
	stamp.name = "Timbro"
	stamp.texture = load(STAMP)
	stamp.position = Vector2(12, -16)
	stamp.z_index = 1
	t.add_child(stamp)
	var tw := stamp.create_tween().set_loops()
	tw.tween_property(stamp, "position:y", -22.0, 0.25)
	tw.tween_property(stamp, "position:y", -16.0, 0.08)
	tw.tween_interval(0.4)


# --- 4.09 il conto del protagonista ----------------------------------------------------------------

## Il terminale mostra il debito vero (GameState.debt): guardarlo non lo cambia. Si accende quando
## l'offerta del capo è chiusa (in un modo o nell'altro).
func _conto() -> void:
	if not _f("c4_capo_chiuso"):
		await Ui.say(["* CONSULTA IL TUO CONTO.", "* Servizio riservato ai clienti con almeno una pratica conclusa.",
			"* Sullo schermo, una faccina aspetta. Le faccine qui aspettano tutte."])
		return
	GameState.flags["c4_conto"] = true
	Sound.sfx("blip", 1.4)
	await Ui.say(account_lines())
	var c: int = await Ui.choose("Desideri conoscere l'origine del debito?", ["Sì.", "No.", "Voglio soltanto pagarlo."], TERMINAL)
	match c:
		0:
			await _anomaly()
		1:
			await Ui.say(["Ottima scelta. La curiosità ha costi di gestione elevati."], TERMINAL)
		_:
			await _pay()


func account_lines() -> Array:
	var origin := int(GameState.bank.get("conto", {}).get("debito_originario", GameState.START_DEBT))
	var change := GameState.debt - origin
	return ["* CONSULTA IL TUO CONTO.", "* TITOLARE: {name}.",
		"* DEBITO ATTUALE: %s." % GameState.euros(GameState.debt),
		"* IMPORTO ASSEGNATO ALL'ORIGINE: %s." % GameState.euros(origin),
		"* NOTTI PASSATE NELLA TORRE: %d. INTERESSI: %s A NOTTE." % [GameState.day - 1, ("%.1f%%" % (GameState.interest_rate() * 100.0)).replace(".", ",")],
		"* VARIAZIONE DALL'ORIGINE: %s%s." % ["+" if change > 0 else "", GameState.euros(change)]]


func _anomaly() -> void:
	GameState.flags["c4_anomalia"] = true
	await Ui.say(["Richiesta accolta.", "Ricerca del contratto originale in corso."], TERMINAL)
	for i in 3:
		Sound.sfx("blip", 1.6)
		await get_tree().create_timer(0.45).timeout
	await Ui.say(["Contratto originale non disponibile.", "Data di apertura: precedente alla registrazione del titolare.",
		"Causale: OBBLIGO DI ESISTENZA."], TERMINAL)
	await get_tree().create_timer(1.0).timeout
	await Ui.say(["Grazie per aver scelto CHEAP.", "Ricorda: ogni debito è un'opportunità per dimostrare il tuo valore."], TERMINAL)
	# Teo, se è ancora una persona e lo hai aiutato, sa leggere quel codice
	if _f("c4_teo_aiutato") and not GameState.is_robot("teo") and not _f("c4_teo_codice"):
		GameState.flags["c4_teo_codice"] = true
		await Ui.say(["* Teo si è avvicinato. Guarda lo schermo da sopra la tua spalla."])
		await Ui.say(["Questo numero non dovrebbe essere qui.", "È un codice usato per le pratiche interne.",
			"Non dovrebbe appartenere a una persona."], "Teo")
		await Ui.choose("", ["Cosa significa?"], "Teo")
		await Ui.say(["Non lo so.", "Ma forse stai cercando di ripagare qualcosa che non hai mai chiesto."], "Teo")


## "Voglio soltanto pagarlo": la rata minima o tutto quello che puoi (come lo sportello di prima).
func _pay() -> void:
	if GameState.debt <= 0:
		await Ui.say(["Il debito risulta estinto. Si senta libero. Di solito nessuno si sente libero."], TERMINAL)
		return
	var options: Array = []
	var amounts: Array[int] = []
	var minimum := mini(GameState.MIN_PAYMENT, GameState.debt)
	if GameState.money >= minimum:
		options.append("Paga la rata (%s)" % GameState.euros(minimum))
		amounts.append(minimum)
	var all_you_can := mini(GameState.money, GameState.debt)
	if all_you_can > minimum:
		options.append("Paga tutto quello che puoi (%s)" % GameState.euros(all_you_can))
		amounts.append(all_you_can)
	options.append("Niente, grazie")
	amounts.append(0)
	var i: int = await Ui.choose("Debito: {debt}. Quanto vuoi pagare?", options, TERMINAL)
	if amounts[i] > 0:
		GameState.pay_debt(amounts[i])
		Sound.sfx("coin")
		GameState.flags["paid_at_bank_day"] = GameState.day
		await Ui.say(["Pagamento registrato. Debito residuo: {debt}.", "Gli interessi la ringraziano."], TERMINAL)


# --- 4.11 Nives e il badge ------------------------------------------------------------------------

## Il badge regalato: Olga aiutata fino alla contestazione, Teo aiutato e ancora una persona.
## Non tocca né i soldi né il debito: nessuno ha pagato niente.
func gift_allowed() -> bool:
	return _f("c4_olga_contestazione") and _f("c4_teo_aiutato") and not GameState.is_robot("teo")


func _badge_machine() -> void:
	var cost := GameState.badge_cost(BADGE)
	if GameState.has_badge(BADGE):
		await _nives_remember()
		return
	if not _f("c4_nives"):
		GameState.flags["c4_nives"] = true
		if str(GameState.flags.get("c3_badge", "")) == "regalo":
			await Ui.say(["Oh, sei tu.", "Hai ancora quel badge che non ti ho regalato?"], NIVES, BADGE_CLERK)
		await Ui.say(["Quattromila euro.", "Non devi neanche chiedere. È il prezzo del badge.",
			"Se continui così, presto potrai permetterti di non essere povero.", "Forse."], NIVES, BADGE_CLERK)
		return
	if gift_allowed():
		await Ui.say(["Oh.", "Hai aiutato le persone anche qui.", "Che strano."], NIVES, BADGE_CLERK)
		Sound.sfx("coin", 1.6)
		await Ui.say(["* Qualcosa di piccolo cade sul pavimento, davanti allo sportello. Tic."])
		await Ui.say(["Ne è caduto un altro."], NIVES, BADGE_CLERK)
		var g: int = await Ui.choose("Il badge del Piano Terra è per terra.", ["Raccoglilo", "Lascialo lì, per ora"], NIVES)
		if g != 0:
			await Ui.say(["Resta lì. In banca le cose a terra non le raccoglie nessuno: sembrano una trappola."], NIVES, BADGE_CLERK)
			return
		if GameState.has_badge(BADGE):
			return
		GameState.badges.append(BADGE)
		GameState.flags["badge_day_" + BADGE] = GameState.day
		GameState.flags["c4_badge"] = "regalo"
		GameState.changed.emit()
		Sound.sfx("spare")
		open_turnstiles()
		await Ui.say(["* Hai il badge del Piano Terra. Il tornello ha la lucina verde."])
		await _nives_remember()
		return
	await Ui.say(["Quattromila euro.", "Lo so. È tanto.", "Ma pensa al lato positivo.", "Sei molto più vicino alla cima."], NIVES, BADGE_CLERK)
	var c: int = await Ui.choose("Cosa rispondi?", ["E il mio debito?", "Non è giusto.", "Voglio salire."], NIVES)
	if c == 0:
		GameState.flags["c4_nives_debito"] = true
		await Ui.say(["Hai già provato a chiedere da dove viene?", "Non sei il primo."], NIVES, BADGE_CLERK)
	elif c == 1:
		await Ui.say(["No.", "Ma è il prezzo. Il giusto e il prezzo lavorano in uffici diversi. Non si incontrano mai."], NIVES, BADGE_CLERK)
	var d: int = await Ui.choose("Comprare il badge? Hai %s." % GameState.euros(GameState.money), ["Compra (%s)" % GameState.euros(cost), "Non ora"], NIVES)
	if d != 0:
		return
	if not GameState.buy_badge(BADGE):
		Sound.sfx("deny")
		await Ui.say(["Non bastano.", "Lo sportello del TURNO è lì. È sempre lì. È la cosa più fedele di questa banca."], NIVES, BADGE_CLERK)
		return
	GameState.flags["c4_badge"] = "comprato"
	Sound.sfx("coin")
	Sound.sfx("stamp")
	open_turnstiles()
	await Ui.say(["Ecco il badge. Debito: {debt}. Il tornello ha la lucina verde."], NIVES, BADGE_CLERK)
	await _nives_remember()


func _nives_remember() -> void:
	if _f("c4_nives_ricorda"):
		await Ui.say(["Le scale sono lì. Su c'è il Piano Terra. La luce del giorno, dicono."], NIVES, BADGE_CLERK)
		return
	GameState.flags["c4_nives_ricorda"] = true
	await Ui.say(["Lassù ci sono le finestre.", "Io non le vedo da quattro piani.", "Se ne vedi una, guardala anche per me."], NIVES, BADGE_CLERK)


# --- 4.12 la rivelazione del primo gradino ------------------------------------------------------------

func revelation_lines() -> Array:
	var origin := int(GameState.bank.get("conto", {}).get("debito_originario", GameState.START_DEBT))
	return ["DATA DI APERTURA DEL DEBITO: NON DISPONIBILE.", "CONTRATTO FIRMATO: NESSUNO TROVATO.",
		"IMPORTO ORIGINARIO ASSEGNATO: %s." % GameState.euros(origin), "STATO DEL DEBITO: ATTIVO.",
		"RICERCA DOCUMENTO DI CONSENSO...", "NESSUN DOCUMENTO TROVATO."]


func on_stairs_step(p: Player, _need: String) -> void:
	if _f("c4_rivelazione"):
		return
	GameState.flags["c4_rivelazione"] = true
	if str(GameState.flags.get("c4_badge", "")) == "":
		# il badge è arrivato da un'altra parte (un contratto, una vecchia via)
		GameState.flags["c4_badge"] = "altro"
	Ui.cutscene = true
	p.position.y += 4
	Sound.music_pitch(0.5, 1.2)
	await get_tree().create_timer(1.2).timeout
	Sound.music("")
	await get_tree().create_timer(0.5).timeout
	var layer := CanvasLayer.new()
	layer.layer = 14
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color("0b0a10")
	panel.size = Vector2(500, 190)
	panel.position = Vector2(70, 40)
	panel.modulate.a = 0.0
	layer.add_child(panel)
	var frame := ReferenceRect.new()
	frame.border_color = Color("c0302a")
	frame.border_width = 2.0
	frame.editor_only = false
	frame.size = panel.size
	panel.add_child(frame)
	var a := create_tween()
	a.tween_property(panel, "modulate:a", 1.0, 0.6)
	await a.finished
	var y := 22.0
	for line: String in revelation_lines():
		var l := Label.new()
		l.text = line
		l.position = Vector2(20, y)
		l.size = Vector2(460, 20)
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color", Color("ff5a50") if line.begins_with("NESSUN") else Color("e8e2d0"))
		panel.add_child(l)
		Sound.sfx("blip", 1.3)
		y += 26.0
		await get_tree().create_timer(0.7).timeout
	await get_tree().create_timer(1.2).timeout
	await Ui.say(["Non preoccuparti.", "Non è necessario capire un debito per pagarlo.", "È necessario soltanto continuare."], VOICE)
	var b := create_tween()
	b.tween_property(panel, "modulate:a", 0.0, 0.8)
	await b.finished
	layer.queue_free()
	Sound.music(music)
	Sound.music_pitch(0.85, 2.0)
	Ui.cutscene = false


# --- 4.13 lo sguardo indietro ------------------------------------------------------------------------

func on_stairs_top(p: Player) -> bool:
	if _f("c4_fine"):
		Router.goto(next_scene(), "from_below")
		return true
	GameState.flags["c4_fine"] = true
	_write_outcome()
	_dress_for_look_back()
	# salvataggio automatico: si riparte dal piano di sopra, col capitolo 4 chiuso
	GameState.save_game(next_scene())
	look_back(p, look_back_line(), "CAPITOLO 5", "LA CITTÀ", next_scene(), "from_below", ["Piano terra."],
		"Fuori dalla Torre, qualcuno sta ancora pagando.")
	return true


## La frase finale. Priorità fissa: Teo robot > Olga e Teo aiutati > anomalia del debito > generale.
## La stanza, invece, mostra tutto quello che è vero (vedi _dress_for_look_back).
func look_back_line() -> String:
	if GameState.is_robot("teo"):
		return "La Banca aveva guadagnato un impiegato perfetto. Nessuno aveva chiesto cosa avesse perso."
	if _f("c4_olga_contestazione") and _f("c4_teo_aiutato"):
		return "Non avevi cancellato i debiti. Avevi aiutato qualcuno a non affrontarli da solo."
	if _f("c4_anomalia"):
		return "Per la prima volta, non eri sicuro di dovere davvero ciò che ti chiedevano."
	return "Avevi attraversato la Banca. La Banca sarebbe rimasta."


func _dress_for_look_back() -> void:
	# la fila continua a muoversi, lentamente, sempre
	for n in world.get_children():
		if n is CharSprite and str(n.name).begins_with("Fila"):
			var tw := (n as Node2D).create_tween()
			tw.tween_property(n, "position:y", (n as Node2D).position.y - 6.0, 6.0)
	var teo := _npc("teo")
	if teo:
		if GameState.is_robot("teo"):
			# timbra continuamente, più in fretta
			var stamp := teo.get_node_or_null("Timbro") as Node2D
			if stamp:
				stamp.get_tree().create_tween().bind_node(stamp).set_loops().tween_property(stamp, "rotation", 0.0, 0.01)
				teo.get_node("Timbro").set_process(true)
		elif _f("c4_teo_aiutato"):
			# torna a disegnare per qualche secondo
			teo.face("down")
			var nb := find_child("Quaderno", true, false) as Node2D
			if nb:
				var tw := nb.create_tween().set_loops(6)
				tw.tween_property(nb, "rotation", 0.15, 0.3)
				tw.tween_property(nb, "rotation", -0.1, 0.3)
	var olga := _npc("olga")
	if olga and _f("c4_olga_contestazione"):
		# esce con la sua lettera
		var letter := Sprite2D.new()
		letter.texture = load(LETTER)
		letter.position = Vector2(6, -14)
		olga.add_child(letter)
		olga.set_physics_process(false)
		var tw := olga.create_tween()
		tw.tween_property(olga, "position", cell_feet(Vector2i(3, 10)), 5.0)
	if _f("c4_anomalia"):
		# un terminale continua a cercare il contratto
		var term := find_child("TerminaleConto", true, false) as Node2D
		if term:
			var l := Label.new()
			l.text = "RICERCA CONTRATTO..."
			l.add_theme_font_size_override("font_size", 6)
			l.add_theme_color_override("font_color", Color("ff5a50"))
			l.position = Vector2(-20, -44)
			l.z_index = 30
			term.add_child(l)
			var tw := l.create_tween().set_loops()
			tw.tween_property(l, "modulate:a", 0.2, 0.5)
			tw.tween_property(l, "modulate:a", 1.0, 0.5)


## Le conseguenze per i capitoli 5-6, tutte in un posto, coi nomi della specifica:
## GameState.flags["chapter_4"]. Si scrive una volta sola, quando il capitolo finisce davvero.
func _write_outcome() -> void:
	var f := GameState.flags
	var robot := GameState.is_robot("teo")
	f["chapter_4"] = {
		"entered": f.get("c4_arrivo", false), "completed": true,
		"olga": {"met": f.get("c4_olga", false), "documents_reconstructed": f.get("c4_olga_ordinati", false),
			"duplicate_fee_found": f.get("c4_olga_doppia", false), "complaint_submitted": f.get("c4_olga_contestazione", false),
			"complaint_resolved": f.get("c4_olga_risposta", false)},
		"teo": {"met": f.get("c4_teo", false), "dream_discovered": f.get("c4_teo_sogno", false),
			"practices_helped": f.get("c4_teo_aiutato", false), "report_discovered": f.get("c4_teo_rapporto", false),
			"credit_stolen": f.get("c4_capo_firmato", false), "robotized": robot, "report_copy_saved": f.get("c4_teo_copia", false)},
		"turn": {"completed_count": int(f.get("c4_turni", 0)), "correct_reviews": int(f.get("c4_corretti", 0)),
			"rushed_reviews": int(f.get("c4_frettolosi", 0)), "grouped": int(f.get("c4_raggruppate", 0))},
		"boss": {"call_received": f.get("c4_capo", false), "offer_resolved": f.get("c4_capo_chiuso", false),
			"offer_accepted": f.get("c4_capo_firmato", false)},
		"debt": {"account_inspected": f.get("c4_conto", false), "anomaly_discovered": f.get("c4_anomalia", false),
			"original_contract_missing": f.get("c4_anomalia", false) or f.get("c4_rivelazione", false),
			"teo_code_explained": f.get("c4_teo_codice", false)},
		"secret_scene_seen": f.get("c4_segreta", false),
		"exit": {"badge_obtained": GameState.has_badge(BADGE), "badge_source": str(f.get("c4_badge", "")),
			"stairs_revelation_seen": f.get("c4_rivelazione", false), "lookback_seen": true},
	}


# --- la scena segreta: il supereroe con la borsetta ---------------------------------------------------

func _secret_ready() -> bool:
	return not _f("c4_segreta") and not _f("c4_rivelazione") and not GameState.is_robot("teo") \
		and _f("c4_olga_contestazione") and _f("c4_teo_aiutato")


## Olga lascia la sala d'attesa e va a guardare il quaderno di Teo, alla sua scrivania.
func _secret_setup() -> void:
	for id in ["olga", "teo"]:
		var n := _npc(id)
		if n:
			n.visible = false
			n.process_mode = Node.PROCESS_MODE_DISABLED
			n.remove_from_group("interactable")
	var seats := [["SedutoTeo", str(GameState.npc_data("teo").get("sheet")), "sit_right", Vector2i(16, 7)], ["InPiediOlga", str(GameState.npc_data("olga").get("sheet", "char_09")), "idle_left", Vector2i(18, 7)]]
	for s: Array in seats:
		var c := CharSprite.new()
		c.name = s[0]
		c.sheet = s[1]
		c.person = "teo" if str(s[0]).ends_with("Teo") else "olga"
		c.anim = s[2]
		c.grey = true
		c.position = cell_feet(s[3])
		if str(s[2]).begins_with("sit"):
			c.nudge = Vector2(0, -8)
		world.add_child(c)
		block(Rect2i(s[3], Vector2i.ONE))
	add_spot(cell_center(Vector2i(17, 8)), _secret)


func _secret() -> void:
	if _f("c4_segreta"):
		await Ui.say(["* Olga e Teo sono chini sul quaderno. Il supereroe ha una borsetta, adesso. Gli sta bene."])
		return
	GameState.flags["c4_segreta"] = true
	await Ui.say(["* Olga si è spostata alla scrivania di Teo. Guarda il quaderno di fumetti, con gli occhiali sulla punta del naso."])
	await Ui.say(["Ma questo omino con il mantello chi sarebbe?"], "Olga")
	await Ui.say(["Un supereroe."], "Teo")
	await Ui.say(["E cosa fa?"], "Olga")
	await Ui.say(["Combatte i criminali."], "Teo")
	await Ui.say(["Ah.", "Perché non combatte i tassi d'interesse?"], "Olga")
	await Ui.say(["Non sarebbe molto spettacolare."], "Teo")
	await Ui.say(["Ragazzo mio, non hai mai visto un mutuo."], "Olga")
	await Ui.say(["* Teo ride. Una risata vera, che gli scappa. Si guarda intorno, poi ride ancora.",
		"* Olga prende la matita e disegna una borsa al supereroe."])
	await Ui.say(["Che cos'è?"], "Teo")
	await Ui.say(["La sua arma."], "Olga")
	await Ui.say(["Una borsetta?"], "Teo")
	await Ui.say(["Ho sconfitto tre direttori con questa.", "E un piccione."], "Olga")
