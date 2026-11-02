class_name Storia
extends RefCounted
## Le regole della storia che servono a più capitoli (vedi docs/STORIA_BANCA_CIMA.md).
## Tutto sta in GameState.flags, così il salvataggio le porta con sé. Un vecchio salvataggio
## che non ha questi flag non inventa niente: le funzioni rispondono "non lo so" ("" o 0).


## L'ordine delle azioni: un contatore unico, GameState.flags["seq"]. Ogni azione che conta
## per le reazioni si segna una volta sola, in "<azione>_seq". Si confrontano i numeri, non i giorni.
static func segna(azione: String) -> int:
	var f := GameState.flags
	if f.has(azione + "_seq"):
		return int(f[azione + "_seq"])
	var n := int(f.get("seq", 0)) + 1
	f["seq"] = n
	f[azione + "_seq"] = n
	return n


## -1 se `a` è successa prima di `b`, 1 se dopo, 0 se non si sa (una delle due non ha il numero).
static func ordine(a: String, b: String) -> int:
	var f := GameState.flags
	if not f.has(a + "_seq") or not f.has(b + "_seq"):
		return 0
	return -1 if int(f[a + "_seq"]) < int(f[b + "_seq"]) else 1


# --- la proposta del Capo a Olga (missione -2, UN PICCOLO AIUTO) -----------------------------

static func proposta_olga() -> Dictionary:
	return GameState.flags.get("boss_olga_offer", {})


## Le condizioni erano solo nella copia interna (riepilogo non in prima pagina).
static func olga_ingannata() -> bool:
	var o := proposta_olga()
	return not o.is_empty() and not bool(o.get("visible", true))


static func olga_proposta_chiara() -> bool:
	var o := proposta_olga()
	return not o.is_empty() and bool(o.get("visible", true))


## La proposta chiara conviene a Olga se costa in tutto quanto paga adesso, o meno, e la
## commissione non è più alta della sua (data/bank.json, "proposta_olga").
static func olga_conviene() -> bool:
	var o := proposta_olga()
	var now: Dictionary = GameState.bank.get("proposta_olga", {})
	return int(o.get("total", 0)) <= int(now.get("costo_attuale", 1320)) * 100 \
		and int(o.get("fee", 0)) <= int(now.get("commissione_attuale", 35))


## Ingannata e non ancora corretta: il torto resta aperto.
static func olga_torto_aperto() -> bool:
	return olga_ingannata() and not bool(GameState.flags.get("c4_olga_corretta", false))


# --- la richiesta di verifica (Banca → centralino della Città → Cima) ---------------------------

## Che fine ha fatto la richiesta: "direzione" (arrivata), "a_mano" (la porti tu), "archivio",
## "riepilogo" (nessuna richiesta, solo il foglio) oppure "" (vecchio salvataggio: nessuno dei due).
## Se il centralino non l'ha toccata, va dove l'ha mandata la Banca: alla Direzione.
static func richiesta() -> String:
	var f := GameState.flags
	if bool(f.get("c4_verifica", false)):
		var via := str(f.get("c5_richiesta", ""))
		return via if via != "" else "direzione"
	if bool(f.get("c4_riepilogo", false)):
		return "riepilogo"
	return ""


## Arrivata alla Presidente: per posta o consegnata a mano.
static func richiesta_arrivata() -> bool:
	return richiesta() in ["direzione", "a_mano"]


# --- torti e riparazioni (docs/STORIA_BANCA_CIMA.md, sezione 7) --------------------------------------

## Il torto fatto con la missione del Capo, ancora vero nel salvataggio.
static func torto(id: String) -> bool:
	var f := GameState.flags
	match id:
		"fermo":
			return int(f.get("boss_fermo_extra", 0)) > 0 or int(f.get("boss_fermo_intensity", 2)) == 3
		"ercole":
			return bool(f.get("boss_ercole_archived", false))
		"leda":
			return int(f.get("boss_market_complaints", 0)) > 0
		"rina":
			return bool(f.get("boss_news_divisive", false))
		"olga":
			return olga_ingannata()
	return false


## La riparazione deve riparare proprio quel danno. Rina: la rettifica pubblica; Olga: la proposta corretta.
static func riparato(id: String) -> bool:
	var f := GameState.flags
	match id:
		"rina":
			return bool(f.get("boss_news_rectified", false))
		"olga":
			return bool(f.get("c4_olga_corretta", false))
	return bool(f.get("riparato_" + id, false))


## Le riparazioni che si fanno tornando da qualcuno: [chi deve esserci, la scelta, cosa succede, la sua risposta].
const RIPARAZIONI := {
	"fermo": ["", "Copro io il tuo turno (15 minuti)",
		"* Sali sulla cyclette. Fermo scende e si siede sulla cassetta. Guarda l'orologio.",
		"Quindici minuti. Li conto io."],
	"ercole": ["tilde", "Apriamo la nuova procedura, con il timbro di Tilde",
		"* Compilate la nuova procedura, riga per riga. Tilde la timbra.",
		"È di nuovo aperta. Non è una risposta. Ma adesso si può aspettarla."],
	"leda": ["", "Riscriviamo i cartellini veri",
		"* Riscrivete i cartellini con Leda: prezzo, quantità, condizioni. Tutto davanti, tutto grande.",
		"Vendo meno. Ma oggi nessuno torna indietro alla cassa."],
}


## Quando parli con qualcuno a cui hai fatto un torto, puoi ripararlo (una volta al giorno te lo chiede).
## true se la conversazione è finita qui.
static func offer_repair(id: String, who: String) -> bool:
	if not RIPARAZIONI.has(id) or not torto(id) or riparato(id) or GameState.is_robot(id) or id in GameState.freed:
		return false
	var r: Array = RIPARAZIONI[id]
	var helper := str(r[0])
	if helper != "" and (GameState.is_robot(helper) or not bool(GameState.flags.get("met_" + helper, false))):
		return false
	var key := "riparazione_chiesta_" + id
	if int(GameState.flags.get(key, 0)) == GameState.day:
		return false
	GameState.flags[key] = GameState.day
	var c: int = await Ui.choose(str(r[1]) + "?", [str(r[1]), "Parla d'altro"], who)
	if c != 0:
		return false
	GameState.flags["riparato_" + id] = true
	segna("riparato_" + id)
	GameState.spend(15)
	await Ui.say([str(r[2])])
	await Ui.say([str(r[3])], who)
	return true


## La reazione negli epiloghi: aiuto e torto si ricordano tutti e due, nell'ordine in cui sono successi;
## una riparazione si riconosce, ma non cancella il torto. [] se non c'è niente da ricordare.
## `in_force` = le decisioni dei cicli valgono davvero (finali A e C2); `turni` = c'è qualcuno ai TURNI in C2.
static func reazione(id: String, in_force: bool, wages_up: bool, turni: bool) -> Array:
	if not torto(id) or GameState.is_robot(id):
		return []
	var helped := id in GameState.helped_ids
	var help_first := helped and ordine("aiuto_" + id, "torto_" + id) == -1
	match id:
		"fermo":
			# in C2, con qualcuno ai TURNI, la riparazione è la scena stessa: Fermo scende dalla cyclette
			if turni:
				return []
			if riparato(id):
				return ["Quindici minuti. Li conto io."]
			if in_force and wages_up:
				return ["Mi pagate di più per non fermarmi."]
			if help_first:
				return ["Mi hai ascoltato. Poi mi hai tolto la pausa. Mi ricordo tutte e due le cose."]
			return ["Ah. Pensavo fosse finito. Ancora cinque minuti."]
		"ercole":
			if riparato(id):
				return ["È di nuovo aperta. Non è una risposta. Ma adesso si può aspettarla."]
			if help_first:
				return ["La firma me l'hai fatta tu. Anche l'archiviazione. Bella calligrafia, tutte e due."]
			return ["Ma io non ho ricevuto una risposta. Hanno soltanto smesso di aspettarla."]
		"leda":
			if riparato(id):
				return ["Vendo meno. Ma oggi nessuno torna indietro alla cassa."]
			return ["I reclami per quelle etichette sono arrivati a me. Il premio a te."]
		"rina":
			if riparato(id):
				return ["Hanno rimesso la frase intera. Adesso si capisce che ero arrabbiata con il vetro, non con la Casa."]
			return ["Io ho parlato del mio vetro. Non ho detto di chiudere la Casa Comune."]
		"olga":
			if riparato(id):
				return ["Nella cartellina ho tutte e due le proposte. Quella piegata e quella giusta. Le tengo vicine."]
			return []
	return []
