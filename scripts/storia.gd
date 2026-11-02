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
