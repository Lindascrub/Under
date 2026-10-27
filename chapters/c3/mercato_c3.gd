extends EditorRoom
## Capitolo 3 — Il Mercato (piano -3). La scena è fatta nell'editor (mercato.tscn):
## qui c'è solo la logica. Un mercato coloratissimo dove si può comprare tutto, tranne quello
## che manca. Leda (il negozio) e Amir (le consegne) sono grigi; il capo offre 1.500 € per
## il merito di Amir; dopo il primo turno i prezzi salgono, la paga no.
## Tutto è descritto in docs/capitoli/capitolo_3_il_mercato.md (flag c3_*).

const NIVES := "Nives"
const SPEAKER := "Altoparlante"
const BOSS := "Il capo"
const BADGE := "-2"

const BOARD_NEW := "res://art/price_board_nuovo.png"


## Un po' di spazio sopra il muro: l'insegna dei saldi e il tabellone non finiscono sotto la barra in alto.
func build() -> void:
	super()
	cam_rect = cam_rect.grow_side(SIDE_TOP, 32)


func setup() -> void:
	_price_board()
	if _secret_ready():
		_secret_setup()


func enter() -> void:
	if not GameState.flags.get("c3_arrivo", false):
		await _arrival()
	await show_pending()
	if Ui.transitioning:
		return
	# le cose rimaste a metà (un salvataggio, un minigioco) riprendono da dove erano
	if GameState.flags.get("c3_furto_ok", false) and not GameState.flags.get("c3_capo_chiuso", false):
		await _terminal_choice()
	if GameState.flags.get("c3_amir_aiutato", false) and not GameState.flags.get("c3_amir_sogno", false) \
			and not GameState.is_robot("amir"):
		await _amir_dream()
	if _prices_due():
		await _price_update()


## Al -3 il badge non si regala a chi ha aiutato "tutti": decide Nives (vedi _badge_machine).
func _floor_gift() -> void:
	pass


func _npc(id: String) -> Npc:
	for n in get_tree().get_nodes_in_group("npc"):
		if n is Npc and (n as Npc).id == id and is_instance_valid(n):
			return n
	return null


# --- 3.01 l'arrivo ----------------------------------------------------------------

func _arrival() -> void:
	GameState.flags["c3_arrivo"] = true
	Ui.cutscene = true
	await get_tree().create_timer(0.3).timeout
	Sound.sfx("ding")
	await Ui.say(["* DING. La porta si apre su un Mercato coloratissimo. Musica allegra, da tutte le parti."])
	await Ui.say(["Benvenuto al Mercato CHEAP! Qui i tuoi desideri sono la nostra priorità!"], SPEAKER)
	await get_tree().create_timer(0.7).timeout
	await Ui.say(["Compatibilmente con il tuo saldo disponibile."], SPEAKER)
	var sign := find_child("InsegnaSaldi", true, false) as CanvasItem
	if sign:
		var tw := create_tween()
		for i in 3:
			tw.tween_property(sign, "modulate", Color(1.6, 1.6, 1.6), 0.12)
			tw.tween_property(sign, "modulate", Color.WHITE, 0.12)
	await Ui.say(["* Sopra la cassa lampeggia un'insegna: \"OGGI TUTTO AL 50%*\".",
		"* Sotto, piccolissimo: \"*Rispetto al prezzo che applicheremo domani\"."])
	Ui.cutscene = false


func _saldi() -> void:
	await Ui.say(["* \"OGGI TUTTO AL 50%*\".", "* \"*Rispetto al prezzo che applicheremo domani.\"",
		"* Domani, l'insegna dirà la stessa cosa."])


# --- il tabellone dei prezzi: un solo stato centrale (flag c3_prezzi, GameState.market_price) ---
# Le due facce del tabellone (prima e dopo) le disegna tools/make_art_mercato.py da data/market.json.

func board() -> Sprite2D:
	return find_child("Tabellone", true, false) as Sprite2D


func _price_board() -> void:
	if board() and GameState.flags.get("c3_prezzi", false):
		board().texture = load(BOARD_NEW)


func _tabellone() -> void:
	var lines: Array = ["* Il tabellone dei prezzi, con le lucine: PANE %s, LATTE %s, ACQUA %s." % [
		GameState.euros(GameState.market_price("pane")), GameState.euros(GameState.market_price("latte")), GameState.euros(GameState.market_price("acqua"))]]
	if GameState.flags.get("c3_prezzi", false):
		lines.append("* Sotto, una scritta nuova: \"PREZZI AGGIORNATI PER LA TUA FELICITÀ\".")
	else:
		lines.append("* Le cifre sono su rotelline, come negli aeroporti. Si vede che sono fatte per girare.")
	await Ui.say(lines)


# --- 3.02 il distributore dell'acqua --------------------------------------------

func _acqua() -> void:
	var who := "Distributore"
	var price := GameState.market_price("acqua")
	await Ui.say(["L'idratazione è un diritto. La bottiglia è un servizio."], who)
	if GameState.flags.get("c3_acqua", false):
		await Ui.say(["Hai già acquistato la tua bottiglia. Una per cliente: la sete va distribuita equamente."], who)
		return
	var c: int = await Ui.choose("ACQUA ECONOMICA — %s. Hai %s." % [GameState.euros(price), GameState.euros(GameState.money)],
		["Compra acqua (%s)" % GameState.euros(price), "Lascia perdere", "Chiedi perché costa tanto"], who)
	match c:
		0:
			if GameState.money < price:
				Sound.sfx("deny")
				await Ui.say(["Saldo insufficiente. La sete resta disponibile gratuitamente."], who)
				return
			GameState.money -= price
			GameState.flags["c3_acqua"] = true
			GameState.give_item("Acqua economica")
			Sound.sfx("coin")
			await Ui.say(["* Una bottiglia cade nello sportello con un tonfo di plastica.", "Grazie per aver scelto liberamente CHEAP!"], who)
			await Ui.say(["* (Hai ricevuto: Acqua economica.)"])
		1:
			await Ui.say(["Nessun problema. Puoi sempre tornare quando avrai più sete."], who)
		_:
			await Ui.say(["Domanda non disponibile nel tuo piano tariffario.", "Per abilitare le domande, acquista il pacchetto Curiosità Plus."], who)


# --- 3.03 Leda ---------------------------------------------------------------------

func talk_leda(_npc_node: Npc) -> bool:
	if GameState.flags.get("c3_rivelazione", false):
		return false
	if not GameState.flags.get("c3_leda", false):
		await _leda_first()
	elif GameState.flags.get("c3_prezzi", false) and not GameState.flags.get("c3_leda_seconda", false):
		await _leda_second()
	elif not GameState.flags.get("c3_leda_inventario", false):
		await Ui.say([["Le scatole sono ancora lì. Mi guardano. Io le guardo. Nessuna delle due si muove.",
			"Il sapone è ancora tra i biscotti. Ormai sono amici."].pick_random()], "Leda")
		await _leda_offer()
	else:
		await Ui.say([["Gli scaffali sono ancora in ordine. È la cosa più stabile del Mercato.",
			"Ho venduto un pane. Quasi fresco. Il cliente era quasi contento.",
			"Se ti avanzano biscotti, non dirmelo. Mi sentirei in colpa a riprenderli."].pick_random()], "Leda")
	return true


func _leda_first() -> void:
	var who := "Leda"
	GameState.flags["c3_leda"] = true
	GameState.flags["met_leda"] = true
	Sound.sfx("clunk", 1.3)
	await Ui.say(["* CRASH. Dietro il bancone cade una scatola."])
	await Ui.say(["Ah! Un cliente!", "Scusa. Riflesso condizionato.", "Sei entrato per comprare qualcosa?"], who)
	var c: int = await Ui.choose("Cosa rispondi?", ["Stavo solo guardando.", "Hai bisogno di aiuto?", "Quanto costano queste cose?"], who)
	match c:
		0:
			await Ui.say(["Guardare è gratis. Per ora. Non dirlo troppo forte, se no lo mettono in fattura."], who)
		1:
			await Ui.say(["Aiuto? Detto così, di colpo, senza nemmeno un preventivo? Sei sicuro di essere di questo piano?"], who)
		_:
			await Ui.say(["Più di ieri e meno di domani. È il nostro slogan. Non l'ho scelto io."], who)
	await Ui.say(["Vedi quello? Piccolo commerciante indipendente.", "* Indica un adesivo sulla cassa: PICCOLO COMMERCIANTE INDIPENDENTE — CHEAP.",
		"Me l'hanno regalato quando ho aperto.", "Ieri mi hanno detto che se non vendo abbastanza devo pagare una penale.",
		"Non ho ancora capito da cosa sono indipendente."], who)
	await _lavagnetta(true)
	await _leda_offer()


## Il minigioco SCATOLE E SCAFFALI: si può riprovare finché non riesce (flag c3_leda_inventario).
func _leda_offer() -> void:
	if GameState.flags.get("c3_leda_inventario", false):
		return
	await _offer("leda", "Leda")


## Offre il minigioco di aiuto di una persona (si può riprovare: non conta "met_today").
func _offer(id: String, who: String) -> void:
	var h: Dictionary = GameState.npc_data(id).get("help", {})
	if not GameState.has_time(GameState.COST_HELP_TIME):
		await Ui.say(["* È tardi. Per oggi non c'è più tempo per dare una mano. (Una stellina fa passare la notte.)"])
		return
	var c: int = await Ui.choose(str(h.get("ask", "")), ["Dai una mano (1 ora)", "Non ora"], who)
	if c != 0:
		return
	Router.minigame(Npc.minigame_cfg(id, who, h, scene_file_path, player.global_position))


func _lavagnetta(with_leda := false) -> void:
	var lines: Array = ["* La lavagnetta dei conti, scritta col gesso:"]
	for row: Array in GameState.market.get("lavagnetta", []):
		lines.append("* %s: %s." % [str(row[0]).to_upper(), GameState.euros(absi(int(row[1])))])
	await Ui.say(lines)
	if GameState.flags.get("c3_leda_fattura", false):
		var extra := 0
		for row: Array in GameState.market.get("fattura", []):
			extra += int(row[1])
		await Ui.say(["* Sotto, in rosso, una riga nuova: \"FATTURA: -%s\". Il residuo è diventato un numero con il segno meno." % GameState.euros(extra)])
	if with_leda:
		await Ui.say(["Vent'euro!", "Non male, vero?", "Sono stata aperta quattordici ore."], "Leda")


func _product(key: String, text: String) -> void:
	var d: Dictionary = GameState.market.get("prezzi", {}).get(key, {})
	await Ui.say(["* %s — %s." % [str(d.get("nome", key)), GameState.euros(GameState.market_price(key))], text])


func _pane() -> void:
	await _product("pane", "* \"Quasi\" è scritto più piccolo di \"fresco\". Molto più piccolo.")


func _latte() -> void:
	await _product("latte", "* Scade fra tre settimane. Il prezzo, invece, scade domattina.")


func _sogno() -> void:
	await _product("sogno", "* Una scatola sigillata. \"Non aprire: il contenuto potrebbe non corrispondere alle aspettative\".")


func _aria() -> void:
	await _product("aria", "* Un barattolo vuoto con un'etichetta dorata. \"Respirata una sola volta\".")


func _tazza() -> void:
	await _product("tazza", "* Una tazza vuota. È l'unico prodotto onesto del negozio: è esattamente quello che dice.")


# --- 3.11 la seconda visita: la fattura ------------------------------------------

func _leda_second() -> void:
	var who := "Leda"
	if not GameState.flags.get("c3_leda_fattura", false):
		GameState.flags["c3_leda_fattura"] = true
		var lines: Array = ["* Leda ha in mano un foglio nuovo. In alto, in grassetto: FATTURA."]
		for row: Array in GameState.market.get("fattura", []):
			lines.append("* %s: +%s." % [str(row[0]).to_upper(), GameState.euros(int(row[1]))])
		await Ui.say(lines)
		await Ui.say(["Mi fanno pagare per vendere.", "Poi mi fanno pagare per pubblicizzare quello che vendo.",
			"Adesso mi fanno pagare per cambiare i prezzi."], who)
	else:
		await Ui.say(["La fattura è ancora qui. L'ho girata, per vedere se dietro c'era scritto \"scherzo\"."], who)
	var q: int = await Ui.choose("", ["Perché non chiudi?", "Posso fare qualcosa?"], who)
	if q == 0:
		await Ui.say(["Perché mi piace.", "Mi piaceva anche ieri.", "Non credo che questo sia cambiato."], who)
		# la fiducia: le hai già dato una mano con l'inventario
		if GameState.flags.get("c3_leda_inventario", false):
			GameState.flags["c3_leda_mamma"] = true
			await Ui.say(["Questo negozio era di mia madre.", "Quando apro la mattina, per un momento, mi sembra ancora di vederla dietro il bancone.",
				"Poi arriva la fattura."], who)
	var gift := int(GameState.market.get("donazione", 50))
	var options: Array = ["Aiutala con %s" % GameState.euros(gift)]
	var kinds: Array = ["dono"]
	# gli ordini condivisi si propongono solo conoscendo il negozio (inventario) e i conti (fattura)
	if GameState.flags.get("c3_leda_inventario", false):
		options.append("Proponi ordini condivisi")
		kinds.append("ordini")
	options.append_array(["Non posso permettermelo", "Non approfondire"])
	kinds.append_array(["no", "lascia"])
	while true:
		var c: int = await Ui.choose("Cosa fai?", options, who)
		match str(kinds[c]):
			"dono":
				if GameState.money < gift:
					Sound.sfx("deny")
					await Ui.say(["* Conti i soldi in tasca. Non bastano. Leda fa finta di non aver visto. Lo fa bene."])
					continue
				GameState.money -= gift
				GameState.flags["c3_leda_dono"] = true
				GameState.flags["c3_leda_seconda"] = true
				GameState.changed.emit()
				Sound.sfx("coin")
				await Ui.say(["...Cinquanta euro.", "Pagano la commissione. Il contributo quasi.", "L'aggiornamento dei prezzi no. Ma oggi non ci penso.",
					"Grazie. Domani arriva un'altra fattura. Però oggi no."], who)
			"ordini":
				GameState.flags["c3_leda_ordini"] = true
				GameState.flags["c3_leda_seconda"] = true
				await Ui.say(["Ordini condivisi? Con la ferramenta e il fruttivendolo?", "Se compriamo insieme, la commissione la paghiamo una volta sola invece di tre...",
					"Non risolve niente. Però è la prima idea che non mi costa niente.", "Ne parlo con gli altri. Domani. Oggi ho la fattura da guardare male."], who)
			"no":
				GameState.flags["c3_leda_seconda"] = true
				await Ui.say(["Lo capisco. Hai anche tu dei conti da pagare."], who)
			_:
				await Ui.say(["Va bene. Le fatture non scappano. Neanche io, a quanto pare."], who)
		break


# --- 3.05 Amir -----------------------------------------------------------------------

func talk_amir(_npc_node: Npc) -> bool:
	if GameState.flags.get("c3_rivelazione", false):
		return false
	var who := "Amir"
	if not GameState.flags.get("c3_amir", false):
		await _amir_first()
	elif GameState.flags.get("c3_amir_aiutato", false) and not GameState.flags.get("c3_amir_sogno", false):
		await _amir_dream()
	elif not GameState.flags.get("c3_amir_bonus", false):
		await Ui.say([["Diciassette. Il numero preferito di nessuno.", "La quarta consegna è sempre più in ritardo. Come me."].pick_random()], who)
		await _offer("amir", who)
	else:
		await Ui.say([["Diciotto. Lo ripeto ogni tanto, per sentire com'è.", "Il treno parte sabato. Mia sorella ha già comprato il riso. Io porto la pentola.",
			"Ho fatto i conti: il bonus copre il treno. Il ritorno lo faccio a piedi. Scherzo. Forse."].pick_random()], who)
	await _offer_water()
	return true


func _amir_first() -> void:
	var who := "Amir"
	GameState.flags["c3_amir"] = true
	GameState.flags["met_amir"] = true
	await Ui.say(["Aspetta.", "Tu sembri uno che sa contare fino a tre.", "Io ci riuscivo, prima di lavorare qui."], who)
	await Ui.say(["* Vicino a lui ci sono tre scatole."])
	await Ui.say(["Ho quattro consegne da fare."], who)
	await get_tree().create_timer(0.6).timeout
	await Ui.say(["Sì. Esatto.", "Una è già in ritardo."], who)
	Sound.sfx("blip", 1.4)
	await Ui.say(["* Il terminale delle consegne lampeggia:", "* CONSEGNE COMPLETATE: 17.", "* CONSEGNE RICHIESTE PER IL BONUS: 18.", "* TEMPO RIMASTO: 02:00."])
	await Ui.say(["Mi manca una consegna per il bonus.", "Con quello potrei prendere il treno e andare a trovare mia sorella questo fine settimana."], who)
	await _offer("amir", who)


## Dopo L'ULTIMA CONSEGNA (anche se è andata a metà): il sogno di Amir.
func _amir_dream() -> void:
	var who := "Amir"
	GameState.flags["c3_amir_sogno"] = true
	if not GameState.flags.get("c3_amir_bonus", false):
		await Ui.say(["Senti. Lo so che non è arrivato il diciotto. Ma ci hai provato con me. Non lo fa nessuno."], who)
	await Ui.say(["Vorrei fare il cuoco.", "Sono bravissimo a preparare il riso.", "Solo il riso.", "Ma guarda che sono molto, molto bravo."], who)


func _offer_water() -> void:
	if GameState.is_robot("amir") or GameState.flags.get("c3_acqua_amir", false) or not GameState.flags.get("c3_amir", false):
		return
	var at := GameState.items.find("Acqua economica")
	if at < 0:
		return
	var c: int = await Ui.choose("Hai la bottiglia d'acqua economica.", ["Offrila ad Amir", "Tienila"], "Amir")
	if c != 0:
		return
	GameState.items.remove_at(at)
	GameState.flags["c3_acqua_amir"] = true
	GameState.changed.emit()
	Sound.sfx("heal")
	await Ui.say(["Acqua? Per me?", "Dieci euro d'acqua. È il regalo più costoso che mi abbiano fatto questa settimana.",
		"...Grazie. La bevo piano. Così dura di più."], "Amir")


# --- 3.08 la telefonata del capo -----------------------------------------------------

## Il capo chiama dopo il primo turno, una volta sola: 1.500 € per il merito di Amir.
## "Va bene" e "Ci penso" lasciano l'offerta aperta sul terminale del magazzino (c3_capo_sospeso);
## "No" la chiude per sempre (c3_capo_chiuso).
func _boss_call() -> void:
	GameState.flags["boss_call_done_%d" % GameState.day] = true
	GameState.flags["boss_call_floor_" + GameState.floor_id] = true
	if GameState.flags.get("c3_capo", false) or GameState.is_robot("amir"):
		return
	GameState.flags["c3_capo"] = true
	var prize := int(GameState.market.get("premio_capo", 1500))
	Sound.sfx("alarm", 0.7)
	await Ui.say(["* Il telefono vibra. È il capo."])
	await Ui.say(["ECCOLO! Il mio cassiere preferito!", "Sai cosa adoro del Mercato?", "Che ogni problema è anche un'opportunità!",
		"Ho visto i risultati delle consegne.", "Quel ragazzo, Amir, sta lavorando davvero bene.", "E per questo ho deciso di premiarti!"], BOSS)
	var c: int = await Ui.choose("Cosa rispondi?", ["Ma il lavoro lo ha fatto Amir.", "Quanto sarebbe il premio?", "Non mi interessa."], BOSS)
	match c:
		0:
			await Ui.say(["Oh, non essere così letterale.", "Lui ha spostato delle scatole.", "Tu hai il potenziale per spostare l'azienda.", "Sono cose diverse!"], BOSS)
		1:
			await Ui.say(["Ecco! Così mi piaci. Concreto!"], BOSS)
		_:
			await Ui.say(["Ahah! Lo dicono tutti. Prima di sentire la cifra."], BOSS)
	await Ui.say(["%s. Il rapporto consegne n. 018 è sul terminale del magazzino." % GameState.euros(prize),
		"Ci metti il tuo nome al posto del suo, e il merito è tuo. Il merito è di chi firma: è nel regolamento. L'ho scritto io."], BOSS)
	if GameState.flags.get("c3_amir_aiutato", false):
		await Ui.say(["Ho visto che avete collaborato. Perfetto!", "Allora sai già quanto è bravo.",
			"Sarebbe un peccato sprecare questo talento lasciandolo nelle mani sbagliate."], BOSS)
	var d: int = await Ui.choose("Il rapporto 018: %s." % GameState.euros(prize), ["Va bene", "Ci penso", "No. È di Amir."], BOSS)
	if d == 2:
		_close_offer()
		await Ui.say(["Peccato. Ci sono altri cento come te, sai? Ci pensi. Anzi, no: non ci pensi più. L'offerta è chiusa."], BOSS)
		return
	GameState.flags["c3_capo_sospeso"] = true
	if d == 0:
		await Ui.say(["Bravo! Il terminale è in fondo al magazzino. Amir lavora lì davanti.", "Ogni tanto si gira. Tu, quando si gira, sii un mobile."], BOSS)
	else:
		await Ui.say(["Pensaci pure! Il terminale aspetta. I terminali sono pazientissimi. Le persone, meno."], BOSS)


func _close_offer() -> void:
	GameState.flags["c3_capo_chiuso"] = true
	GameState.flags["c3_capo_sospeso"] = false
	GameState.flags["promotions_refused"] = int(GameState.flags.get("promotions_refused", 0)) + 1


# --- 3.09 il terminale: un, due, tre, stella -------------------------------------------

func _terminale() -> void:
	await _terminale_inner()
	# chiusa l'offerta qui (firmando o no), i prezzi salgono subito, senza dover uscire e rientrare
	if not Ui.transitioning and _prices_due():
		await _price_update()


func _terminale_inner() -> void:
	if GameState.flags.get("c3_capo_firmato", false):
		await Ui.say(["* RAPPORTO CONSEGNE N. 018. RESPONSABILE: {name}.", "* Lo schermo ti fa l'occhiolino. Ha imparato da Amir. Amir non lo fa più."])
		return
	if GameState.flags.get("c3_furto_ok", false) and not GameState.flags.get("c3_capo_chiuso", false):
		await _terminal_choice()
		return
	if GameState.flags.get("c3_capo_sospeso", false) and not GameState.flags.get("c3_capo_chiuso", false):
		await Ui.say(["* RAPPORTO CONSEGNE N. 018. In attesa di firma.", "* Davanti al terminale, Amir sposta scatole. Ogni tanto si gira."])
		var c: int = await Ui.choose("Il rapporto di Amir.", ["Avvicinati di nascosto", "Lascia stare, per ora", "Chiudi l'offerta per sempre"])
		match c:
			0:
				await Ui.say(["Attento, campione. La meritocrazia richiede precisione!"], BOSS)
				start_steal("amir", GameState.promotion("amir"), {
					"intro": ["* Amir sposta scatole davanti al terminale. Fischietta. È stonato.",
						"* Il rapporto 018 è lì, sullo schermo. Basta arrivarci senza che si giri."],
					"win_flag": "c3_furto_ok",
				})
			2:
				_close_offer()
				await Ui.say(["* Premi ANNULLA. Il terminale chiede tre volte se sei sicuro. Tre volte, sì."])
		return
	var done := 18 if GameState.flags.get("c3_amir_bonus", false) else 17
	await Ui.say(["* Il terminale delle consegne di Amir.", "* CONSEGNE COMPLETATE: %d. CONSEGNE RICHIESTE PER IL BONUS: 18." % done])


## La scelta al terminale (dopo che sei arrivato senza farti vedere). Si può riprendere dopo un caricamento.
func _terminal_choice() -> void:
	await _terminal_choice_inner()
	if not Ui.transitioning and _prices_due():
		await _price_update()


func _terminal_choice_inner() -> void:
	var prize := int(GameState.market.get("premio_capo", 1500))
	Sound.sfx("blip", 1.2)
	await Ui.say(["* RAPPORTO CONSEGNE N. 018.", "* LAVORATORE RESPONSABILE: AMIR.", "* NUOVO RESPONSABILE: ______.", "* BONUS: %s." % GameState.euros(prize)])
	while true:
		var c: int = await Ui.choose("NUOVO RESPONSABILE: ______", ["Firma con il tuo nome", "Lascia il nome di Amir", "Chiedi di dividere il premio"])
		if c == 2:
			await Ui.say(["Dividere il premio? Ahah!", "No."], BOSS)
			continue
		if c == 1:
			_close_offer()
			await Ui.say(["* Lasci il campo vuoto. Il nome di Amir resta dov'era. Il terminale torna a fare il terminale."])
			await Ui.say(["Come vuoi. Il merito non aspetta, sai? Va sempre a qualcun altro."], BOSS)
			return
		await _sign(prize)
		return


## Firmare: il premio una volta sola, LV su, Amir diventa un robot (tutto prima di qualunque attesa).
func _sign(prize: int) -> void:
	if GameState.flags.get("c3_capo_firmato", false):
		return
	GameState.flags["c3_capo_firmato"] = true
	GameState.flags["c3_capo_chiuso"] = true
	GameState.flags["c3_capo_sospeso"] = false
	GameState.flags["c3_amir_rubato"] = true
	GameState.exploit("amir", prize)
	GameState.spend(GameState.COST_EASY_JOB)
	# è una scena: durante la trasformazione (che non ha dialoghi) non si cammina e non si parla
	Ui.cutscene = true
	Sound.sfx("stamp")
	await Ui.say(["* Scrivi il tuo nome. Il terminale fa BIP.", "* BONUS ACCREDITATO: %s." % GameState.euros(prize)])
	var a := _npc("amir")
	if a:
		a.sprite.play("idle_down")
		a.sprite.speed_scale = 0.0
		await a.reveal(1.5)
	Sound.sfx("glitch", 0.8)
	await Ui.say(["GRAZIE PER AVER RICONOSCIUTO IL MIO CONTRIBUTO."], "Amir")
	await Ui.say(["Visto? Sono tutti contenti!"], BOSS)
	await Ui.say([GameState.level_up_line()])
	Ui.cutscene = false


# --- 3.10 l'aggiornamento dei prezzi ----------------------------------------------------

func _prices_due() -> bool:
	return not GameState.flags.get("c3_prezzi", false) and int(GameState.flags.get("c3_turni", 0)) >= 1 \
		and GameState.flags.get("c3_capo_chiuso", false)


func _price_update() -> void:
	GameState.flags["c3_prezzi"] = true
	Ui.cutscene = true
	Sound.music("")
	await get_tree().create_timer(0.5).timeout
	Sound.sfx("ding")
	if board():
		board().texture = load(BOARD_NEW)
		var tw := create_tween()
		for i in 4:
			tw.tween_property(board(), "modulate", Color(2, 2, 2), 0.12)
			tw.tween_property(board(), "modulate", Color.WHITE, 0.12)
	var lines: Array = ["* La musica si interrompe. Sul tabellone, le rotelline dei prezzi girano tutte insieme."]
	for key: String in ["pane", "latte", "acqua"]:
		var p: Array = GameState.market["prezzi"][key]["prezzo"]
		lines.append("* %s: da %s a %s." % [str(GameState.market["prezzi"][key]["nome"]).split(" ")[0].to_upper(), GameState.euros(int(p[0])), GameState.euros(int(p[1]))])
	await Ui.say(lines)
	await Ui.say(["COMPLIMENTI!", "Il Mercato ha raggiunto un nuovo livello di crescita!", "Per festeggiare, abbiamo aggiornato i prezzi!"], SPEAKER)
	await Ui.say(["Ma io oggi ho guadagnato come ieri."], "Cliente")
	await Ui.say(["Ecco perché abbiamo preparato un consiglio gratuito!", "Guadagna di più!"], SPEAKER)
	if GameState.flags.get("c3_leda_inventario", false):
		await Ui.say(["Avevo appena sistemato i conti.", "Sono durati meno delle etichette."], "Leda")
	else:
		await Ui.say(["Scusa, oggi non ho tempo.", "Anche ieri non avevo tempo."], "Leda")
	if GameState.is_robot("amir"):
		await Ui.say(["PREZZI AGGIORNATI.", "FELICITÀ AGGIORNATA."], "Amir")
	else:
		await Ui.say(["Mi hanno aumentato il bonus.", "Di venti euro.", "L'acqua è aumentata di cinque.", "Forse dovrei bere più lentamente."], "Amir")
	Sound.music(music)
	Ui.cutscene = false


# --- 3.12 Nives e il badge -------------------------------------------------------------------

## Il badge regalato: hai aiutato tutti e due (Leda con l'inventario, Amir con le consegne)
## e Amir è ancora una persona. Non tocca né i soldi né il debito: nessuno ha pagato niente.
func gift_allowed() -> bool:
	return GameState.flags.get("c3_leda_inventario", false) and GameState.flags.get("c3_amir_aiutato", false) \
		and not GameState.is_robot("amir")


func _badge_machine() -> void:
	var cost := GameState.badge_cost(BADGE)
	if GameState.has_badge(BADGE):
		await _nives_remember()
		return
	if not GameState.flags.get("c3_nives", false):
		GameState.flags["c3_nives"] = true
		await Ui.say(["Piano -3. Badge per il piano superiore: duemila euro.", "Sono aumentati? Sì.", "È colpa mia? No.",
			"Mi pagano per rispondere alla seconda domanda."], NIVES, BADGE_CLERK)
		return
	if gift_allowed():
		await Ui.say(["Hai finito?", "Aspetta.", "Hai aiutato entrambi.", "Ufficialmente non posso fare sconti.",
			"Ma questo badge sembra caduto dal mio cassetto."], NIVES, BADGE_CLERK)
		Sound.sfx("coin", 1.6)
		await Ui.say(["* Qualcosa di piccolo cade sul pavimento, davanti allo sportello. Tic."])
		await Ui.say(["Che sbadata."], NIVES, BADGE_CLERK)
		var g: int = await Ui.choose("Il badge del Piano -2 è per terra.", ["Raccoglilo", "Lascialo lì, per ora"], NIVES)
		if g != 0:
			await Ui.say(["Resta lì. Il pavimento qui non lo pulisce nessuno: è al sicuro."], NIVES, BADGE_CLERK)
			return
		if GameState.has_badge(BADGE):
			return
		GameState.badges.append(BADGE)
		GameState.flags["badge_day_" + BADGE] = GameState.day
		GameState.flags["c3_badge"] = "regalo"
		GameState.changed.emit()
		Sound.sfx("spare")
		open_turnstiles()
		await Ui.say(["* Hai il badge del Piano -2. Il tornello ha la lucina verde."])
		await _nives_remember()
		return
	if not GameState.flags.get("c3_nives_prezzo", false):
		GameState.flags["c3_nives_prezzo"] = true
		await Ui.say(["Sai qual è la differenza tra un prezzo e un desiderio?", "Il prezzo lo puoi leggere."], NIVES, BADGE_CLERK)
	await Ui.say(["Hai finito?", "Bene. Badge per il piano -2: duemila euro.", "Sei pronto a salire?"], NIVES, BADGE_CLERK)
	var c: int = await Ui.choose("Comprare il badge? Hai %s." % GameState.euros(GameState.money), ["Compra (%s)" % GameState.euros(cost), "Non ora"], NIVES)
	if c != 0:
		return
	if not GameState.buy_badge(BADGE):
		Sound.sfx("deny")
		await Ui.say(["Non bastano. Qui sotto non bastano mai. Torna quando bastano. Se bastano."], NIVES, BADGE_CLERK)
		return
	GameState.flags["c3_badge"] = "comprato"
	Sound.sfx("coin")
	Sound.sfx("stamp")
	open_turnstiles()
	await Ui.say(["Ecco il badge. Debito: {debt}. Il tornello ha la lucina verde."], NIVES, BADGE_CLERK)
	await _nives_remember()


func _nives_remember() -> void:
	if GameState.flags.get("c3_nives_ricorda", false):
		await Ui.say(["Le scale sono lì. Il piano -2 è la Banca. Tienti stretto il portafoglio. Anche se è vuoto."], NIVES, BADGE_CLERK)
		return
	GameState.flags["c3_nives_ricorda"] = true
	await Ui.say(["Ricorda una cosa.", "I badge aprono le porte.", "Non garantiscono che dietro ci sia qualcosa di meglio."], NIVES, BADGE_CLERK)


# --- 3.13 la rivelazione: lo scontrino ---------------------------------------------------------

func on_stairs_step(p: Player, _need: String) -> void:
	if GameState.flags.get("c3_rivelazione", false):
		return
	GameState.flags["c3_rivelazione"] = true
	GameState.flags["c3_riepilogo"] = true
	if str(GameState.flags.get("c3_badge", "")) == "":
		# il badge è arrivato da un'altra parte (il contratto del Signor Rata)
		GameState.flags["c3_badge"] = "contratto"
	Ui.cutscene = true
	p.position.y += 4
	Sound.music_pitch(0.5, 1.5)
	await get_tree().create_timer(1.5).timeout
	Sound.music("")
	Sound.sfx("clunk", 0.6)
	await get_tree().create_timer(0.6).timeout
	await Ui.say(["* CLANK. Nel muro accanto alle scale si apre una fessura.", "* Ne esce uno scontrino. Lungo. Lunghissimo."])
	var layer := _receipt()
	await get_tree().create_timer(3.5).timeout
	await Ui.say(["Congratulazioni.", "Il Mercato sta meglio."], "Voce CHEAP")
	await Ui.say(_sounds_below())
	await Ui.say(["Perché non sorridi?"], "Voce CHEAP")
	await get_tree().create_timer(1.5).timeout
	var tw := create_tween()
	tw.tween_property(layer.get_child(0), "modulate:a", 0.0, 0.8)
	await tw.finished
	layer.queue_free()
	Sound.music(music)
	Sound.music_pitch(0.8, 2.0)
	Ui.cutscene = false


func receipt_lines() -> Array:
	var pay := int(GameState.job("cassa_mercato").get("battle", {}).get("pay", 120))
	var bread: Array = GameState.market["prezzi"]["pane"]["prezzo"]
	var lines := ["CHEAP — RIEPILOGO ECONOMICO", "--------------------------",
		"RETRIBUZIONE TURNO: %d €" % pay, "PREZZO PANE INIZIALE: %d €" % int(bread[0])]
	if GameState.flags.get("c3_prezzi", false):
		lines.append("PREZZO PANE AGGIORNATO: %d €" % int(bread[1]))
	else:
		lines.append("PREZZO PANE DA DOMANI: %d €" % int(bread[1]))
	lines.append_array(["AUMENTO RETRIBUZIONE: 0 €", "", "NOTA DELLA DIREZIONE:",
		"\"L'aggiornamento dei prezzi ha", "migliorato i ricavi previsti.", "La revisione delle retribuzioni", "è rinviata.\"", "",
		"RISULTATO DELLA GIORNATA:", "POSITIVO", "--------------------------", "GRAZIE E ARRIVEDERCI"])
	return lines


## Lo scontrino scende dalla fessura e si srotola sullo schermo.
func _receipt() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 14
	add_child(layer)
	var paper := ColorRect.new()
	paper.color = Color("f4f1e6")
	var lines := receipt_lines()
	paper.size = Vector2(300, 24 + lines.size() * 15)
	paper.position = Vector2(170, -paper.size.y)
	layer.add_child(paper)
	var text := Label.new()
	text.text = "\n".join(lines)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.position = Vector2(6, 10)
	text.size = Vector2(288, paper.size.y - 20)
	text.add_theme_font_size_override("font_size", 10)
	text.add_theme_constant_override("line_spacing", 0)
	text.add_theme_color_override("font_color", Color("2a2633"))
	paper.add_child(text)
	var tw := create_tween()
	tw.tween_property(paper, "position:y", 8.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return layer


## Dal piano di sotto arrivano suoni diversi, a seconda di come stanno Leda e Amir.
func _sounds_below() -> Array:
	var out: Array = ["* Da giù, attraverso le scale, arrivano dei rumori."]
	if GameState.flags.get("c3_leda_ordini", false):
		out.append("* Voci di negozianti che parlano tutti insieme, e qualcuno che fa i conti ad alta voce. Insieme.")
	elif GameState.flags.get("c3_leda_inventario", false) or GameState.flags.get("c3_leda_dono", false):
		out.append("* Una scatola appoggiata con cura. Uno scaffale che non cade.")
	else:
		out.append("* Una saracinesca che scende a metà, e si ferma.")
	if GameState.is_robot("amir"):
		out.append("* Un bip regolare, perfetto: LA CONSEGNA È FELICITÀ.")
	elif GameState.flags.get("c3_amir_bonus", false):
		out.append("* Qualcuno fischietta, stonato. Un fischio da treno del fine settimana.")
	else:
		out.append("* Il ronzio del terminale delle consegne: diciassette, diciassette, diciassette.")
	return out


# --- 3.14 lo sguardo indietro -------------------------------------------------------------------

func on_stairs_top(p: Player) -> bool:
	if GameState.flags.get("c3_fine", false):
		return false
	GameState.flags["c3_fine"] = true
	_write_outcome()
	_dress_for_look_back()
	# salvataggio automatico: si riparte dalla Banca, col capitolo 3 chiuso
	GameState.save_game(Router.BANCA)
	look_back(p, look_back_line(), "CAPITOLO 4", "LA BANCA", Router.BANCA, "from_below", ["Piano -2."],
		"I tuoi soldi sono al sicuro. Tu no.")
	return true


## La frase finale. Priorità fissa quando più cose sono vere: robot > ordini condivisi >
## tutti e due aiutati > uno solo > solo lavoro > niente.
func look_back_line() -> String:
	var leda: bool = GameState.flags.get("c3_leda_inventario", false)
	var amir: bool = GameState.flags.get("c3_amir_aiutato", false)
	if GameState.is_robot("amir"):
		return "Il Mercato era più efficiente di quando eri arrivato."
	if GameState.flags.get("c3_leda_ordini", false):
		return "Per la prima volta, qualcuno aveva smesso di fare i conti da solo."
	if leda and amir:
		return "Non avevi risolto i loro problemi. Almeno avevi imparato i loro nomi."
	if leda or amir:
		if leda:
			return "Laggiù Leda ti saluta con la mano.\nIl Mercato non se n'era accorto. Lei sì."
		return "Laggiù Amir ti saluta con la mano.\nIl Mercato non se n'era accorto. Lui sì."
	if int(GameState.flags.get("c3_turni", 0)) > 0:
		return "Il Mercato non aveva bisogno di sapere chi fossi per continuare a funzionare."
	return "Il Mercato continuava a vendere. Non aveva notato che eri passato. Nemmeno i prezzi."


## Prima dello sguardo indietro la stanza si mette com'è davvero: Leda, Amir, i clienti.
func _dress_for_look_back() -> void:
	var leda := _npc("leda")
	if leda:
		if GameState.flags.get("c3_leda_ordini", false):
			# gli altri negozianti, grigi anche loro, intorno al bancone di Leda
			for i in 2:
				var m := CharSprite.new()
				m.sheet = ["char_07", "char_09"][i]
				m.grey = true
				m.anim = ["idle_left", "idle_up"][i]
				m.position = leda.position + [Vector2(20, 2), Vector2(4, 16)][i]
				world.add_child(m)
		elif not GameState.flags.get("c3_leda_inventario", false):
			leda.face("up")
	var amir := _npc("amir")
	if amir and not GameState.is_robot("amir"):
		if GameState.flags.get("c3_amir_bonus", false):
			# è già alla stazione, col treno del fine settimana
			amir.visible = false
		else:
			amir.activity = "wander"
	if GameState.is_robot("amir"):
		for n in world.get_children():
			if n is CharSprite and str(n.name).begins_with("Cliente"):
				(n as CharSprite).speed_scale = 2.0


## Le conseguenze per i capitoli 4-6, tutte in un posto: GameState.flags["c3_esito"].
func _write_outcome() -> void:
	var f := GameState.flags
	f["c3_esito"] = {
		"leda": "rete" if f.get("c3_leda_ordini", false) else ("aiutata" if f.get("c3_leda_inventario", false) else "sola"),
		"leda_dono": f.get("c3_leda_dono", false),
		"leda_credito": f.get("c3_leda_fattura", false) and not f.get("c3_leda_ordini", false),
		"amir": "robot" if GameState.is_robot("amir") else "umano",
		"amir_sorella": f.get("c3_amir_bonus", false) and not GameState.is_robot("amir"),
		"amir_simbolo": GameState.is_robot("amir"),
		"badge": str(f.get("c3_badge", "")),
		"turni": int(f.get("c3_turni", 0)),
		"sovrapprezzi": int(f.get("c3_accettati", 0)),
		"prezzi_aggiornati": f.get("c3_prezzi", false),
	}


# --- la scena segreta: un panino in due -------------------------------------------------------

func _secret_ready() -> bool:
	var f := GameState.flags
	return not f.get("c3_segreta", false) and not f.get("c3_rivelazione", false) and not GameState.is_robot("amir") \
		and f.get("c3_leda_inventario", false) and f.get("c3_amir_aiutato", false) \
		and f.get("c3_amir_sogno", false) and f.get("c3_leda_mamma", false)


## L'angolo pausa del magazzino: due panchine una di fronte all'altra (sono nella scena).
## Leda su quella di sinistra (guarda a destra), Amir su quella di destra; il posto libero è accanto ad Amir.
const SEATS := {"leda": Vector2i(31, 15), "amir": Vector2i(33, 15), "tu": Vector2i(33, 14)}


## Leda e Amir lasciano i loro posti e si siedono sulle panchine dell'angolo pausa.
func _secret_setup() -> void:
	for id in ["leda", "amir"]:
		var n := _npc(id)
		if n:
			n.visible = false
			n.process_mode = Node.PROCESS_MODE_DISABLED
			n.remove_from_group("interactable")
	for i in 2:
		var id: String = ["leda", "amir"][i]
		var s := CharSprite.new()
		s.name = ["SedutaLeda", "SedutoAmir"][i]
		s.person = id
		s.sheet = str(GameState.npc_data(id).get("sheet", "char_02"))
		s.anim = ["sit_right", "sit_left"][i]
		s.grey = true
		# sulla seduta della panchina: un po' su e verso il sedile (lo schienale è dall'altra parte)
		s.nudge = Vector2([3, -3][i], -3)
		s.position = cell_feet(SEATS[id])
		s.z_index = 1
		world.add_child(s)
		# si parla con loro toccandoli, dal corridoio tra le due panchine
		add_spot(cell_center(SEATS[id]), _secret)


func _secret() -> void:
	if GameState.flags.get("c3_segreta", false):
		await Ui.say(["* Leda e Amir finiscono il panino. Non hanno fretta."])
		return
	GameState.flags["c3_segreta"] = true
	await Ui.say(["* Leda e Amir sono seduti nell'angolo pausa, uno di fronte all'altra. Si dividono un panino. A metà precisa: Leda ha usato il righello."])
	await Ui.say(["Sai, un giorno vorrei aprire un ristorante."], "Amir")
	await Ui.say(["Un ristorante?"], "Leda")
	await Ui.say(["Sì."], "Amir")
	await Ui.say(["E cosa cucineresti?"], "Leda")
	await Ui.say(["Riso."], "Amir")
	await Ui.say(["Solo riso?"], "Leda")
	await Ui.say(["Riso buonissimo."], "Amir")
	await Ui.say(["Va bene. Io porterò il pane."], "Leda")
	await Ui.say(["Sempre che possiamo permettercelo."], "Amir")
	await Ui.say(["* Ridono tutti e due."])
	var c: int = await Ui.choose("", ["Siediti con loro", "Lasciali al loro panino"])
	if c != 0:
		await Ui.say(["* Li lasci lì. Per una volta, al Mercato, qualcosa non è in vendita."])
		return
	# il sedile accanto ad Amir: alla stessa altezza di chi è già seduto
	var seat: Vector2i = SEATS["tu"]
	player.sit(Vector2(seat.x * T + 5, (seat.y + 1) * T + 3), "left")
	await Ui.say(["* Ti siedi accanto ad Amir. La panchina scricchiola. Il panino no."])
	await get_tree().create_timer(3.0).timeout
	await Ui.say(["È bello non avere fretta, ogni tanto."], "Amir")
