extends RefCounted
## Capitolo 6 — il motore dei finali. Una funzione sola decide famiglia e variante: `decide(selected)`.
## La FAMIGLIA è la scelta conclusiva (A accetta la Direzione, B rifiuta e parte, C propone di decidere insieme).
## La VARIANTE dipende da fatti contati, mai da un punteggio:
##   legami   persone conosciute e aiutate, ancora umane (robot e mai aiutati non contano)
##   reti     reti vere già funzionanti (ordini di Leda, pendolari di Nadir, Casa Comune, bottega, consegne...)
##   prove    documenti veri sul debito
##   bilancio cosa è cambiato nel turno (direzione_regole.summary)
##   potere   l'attribuzione globale del Capo, firmata o no
## Le condizioni esatte sono in `variant_rules()` e in docs/ENDING_SYSTEM.md. Ogni famiglia ha un fallback:
## non esiste una combinazione senza finale.

const RULES := preload("res://chapters/c6/direzione_regole.gd")

## Le persone dei capitoli 1-5 che contano per i legami (id di data/npcs.json), in ordine di piano.
const PEOPLE := ["fermo", "bulbo", "mina", "tilde", "ercole", "leda", "amir", "olga", "teo", "ada", "nadir", "rina"]
const FLOOR_OF := {"fermo": "-5", "bulbo": "-5", "mina": "-5", "tilde": "-4", "ercole": "-4", "leda": "-3", "amir": "-3",
	"olga": "-2", "teo": "-2", "ada": "0", "nadir": "0", "rina": "0"}
## I ruoli della gestione condivisa (finale C), e chi li conosce dal suo lavoro.
const ROLES := {
	"conti": {"name": "I CONTI", "fit": ["teo", "olga", "tilde"]},
	"servizi": {"name": "I SERVIZI", "fit": ["ada", "leda", "rina", "mina"]},
	"turni": {"name": "I TURNI", "fit": ["nadir", "amir", "fermo", "ercole", "bulbo"]},
}
const FAMILY_NAMES := {"A": "PRENDERE LA DIREZIONE", "B": "IL TEMPO CHE RESTA", "C": "NESSUNO SALE DA SOLO"}
const VARIANT_NAMES := {"A1": "ADESSO CHIAMI TU", "A2": "IL DIRIGENTE CHE CAMBIA LE COSE", "A3": "IL TELEFONO SQUILLA ANCORA", "B1": "LA PARTENZA",
	"B2": "LE PICCOLE ORE", "C1": "LA PICCOLA COMUNITÀ", "C2": "LA TRASFORMAZIONE DELLA TORRE", "C3": "IL PROGETTO INCOMPLETO"}


static func _f(key: String) -> bool:
	return bool(GameState.flags.get(key, false))


## L'hai conosciuta davvero? (parlato, aiutato o sfruttato: tutti modi di incontrarsi)
static func met(id: String) -> bool:
	return _f("met_" + id) or id in GameState.helped_ids or GameState.is_robot(id) or id in GameState.freed \
		or (id == "fermo" and _f("fermo_talked"))


## Un legame: conosciuta, aiutata, e ancora una persona.
static func bonded(id: String) -> bool:
	return met(id) and id in GameState.helped_ids and not GameState.is_robot(id)


static func bonds() -> Array:
	var out: Array = []
	for id: String in PEOPLE:
		if bonded(id):
			out.append(id)
	return out


## Chi hai aiutato e poi sfruttato (lo stesso nome nelle due liste).
static func betrayed() -> Array:
	var out: Array = []
	for id: String in PEOPLE:
		if id in GameState.helped_ids and GameState.is_robot(id):
			out.append(id)
	return out


## Lo stato del bilancio del turno (salvato in chapter_6.director_turn.state).
static func turn_state() -> Dictionary:
	var c6: Dictionary = GameState.flags.get("chapter_6", {})
	var dt: Dictionary = c6.get("director_turn", {})
	var st: Dictionary = dt.get("state", {})
	return st if not st.is_empty() else RULES.new_state()


## Tutti i fatti che i finali leggono, in un posto solo (anche per i test e per il riepilogo).
static func facts() -> Dictionary:
	var c6: Dictionary = GameState.flags.get("chapter_6", {})
	var st := turn_state()
	var sm := RULES.summary(st)
	var roles: Dictionary = c6.get("final_decision", {}).get("roles", {})
	var filled := 0
	for r: String in roles:
		if str(roles[r]) != "":
			filled += 1
	return {
		"exploited": GameState.exploited,
		"robots": GameState.robots.size(),
		"bonds": bonds().size(),
		"betrayed": betrayed().size(),
		"networks": RULES.networks(st).size(),
		"evidence": RULES.evidence().size(),
		"power": bool(c6.get("boss", {}).get("global_credit_accepted", false)) or int(st.get("centralized", 0)) >= 2,
		"roles_filled": filled,
		"policy": sm,
		"casa_open": RULES.casa_open(str(sm["casa"])),
		"improved": bool(sm["wages_up"]) or bool(sm["services_up"]),
		"rule_changed": str(sm["debt_rule"]) != "conservare" and str(sm["debt_rule"]) != "",
		# A1: "Conserva" scelto mentre un'altra regola era aperta. Un vecchio salvataggio non lo sa: non vale.
		"kept_by_choice": str(sm["debt_rule"]) == "conservare" and bool(st.get("debt_other_open", false)),
		"contested": _f("c6_contestazione"),
	}


## Le regole delle varianti, in ordine di priorità. La prima vera vince; l'ultima di ogni famiglia è il fallback.
static func variant_rules() -> Dictionary:
	return {
		"A": [
			["A2", "stipendi o servizi migliorati, almeno 2 legami, una regola dei debiti cambiata, attribuzione globale rifiutata",
				func(x: Dictionary) -> bool: return x["improved"] and x["bonds"] >= 2 and x["rule_changed"] and not x["power"]],
			["A1", "nel turno \"Conserva il sistema dei debiti\" scelto mentre almeno un'altra regola era aperta",
				func(x: Dictionary) -> bool: return x.get("kept_by_choice", false)],
			["A3", "altrimenti", func(_x: Dictionary) -> bool: return true],
		],
		"B": [
			["B2", "almeno 2 legami (persone a cui tornare, un tempo da riprendersi)",
				func(x: Dictionary) -> bool: return x["bonds"] >= 2],
			["B1", "altrimenti", func(_x: Dictionary) -> bool: return true],
		],
		"C": [
			["C2", "almeno 3 reti, 4 legami, i 3 ruoli affidati a persone, manutenzione in regola, riserve almeno 10, regola dei debiti cambiata, attribuzione globale rifiutata",
				func(x: Dictionary) -> bool: return x["networks"] >= 3 and x["bonds"] >= 4 and x["roles_filled"] == 3 \
					and x["policy"]["maintenance_ok"] and x["policy"]["reserve_ok"] and x["rule_changed"] and not x["power"]],
			["C3", "meno di 2 legami, oppure nessuna rete, oppure nessun ruolo affidato",
				func(x: Dictionary) -> bool: return x["bonds"] < 2 or x["networks"] == 0 or x["roles_filled"] == 0],
			["C1", "altrimenti", func(_x: Dictionary) -> bool: return true],
		],
	}


## Famiglia e variante. `selected` è "A", "B" o "C"; qualunque altro valore diventa B (si va via: niente decide per te).
static func decide(selected: String, x := {}) -> Dictionary:
	var family := selected if selected in ["A", "B", "C"] else "B"
	if x.is_empty():
		x = facts()
	var variant := ""
	for r: Array in variant_rules()[family]:
		if (r[2] as Callable).call(x):
			variant = str(r[0])
			break
	return {"family": family, "variant": variant, "debt_status": debt_status(family, x), "governance_status": governance(family, variant, x)}


## Il TUO debito (docs/STORIA_BANCA_CIMA.md, sezione 5). Solo A lo annulla; in C2 è in revisione se la
## revisione è stata adottata. Altrimenti è "contestato" solo con la contestazione fatta alla Cima
## (c6_contestazione): la richiesta di verifica, da sola, non basta.
static func debt_status(family: String, x: Dictionary) -> String:
	if family == "A":
		return "annullato"
	if family == "C" and _c2(x) and str(x["policy"]["debt_rule"]) == "revisione":
		return "in_revisione"
	return "contestato" if x.get("contested", false) else "registrato"


static func _c2(x: Dictionary) -> bool:
	return (variant_rules()["C"][0][2] as Callable).call(x)


## Le decisioni del turno diventano vere solo in A (le adotti tu) e in C2 (il governo condiviso).
## Negli altri finali vale la distribuzione della Presidente e la regola dei debiti di prima.
static func in_force(family: String, variant: String) -> bool:
	return family == "A" or variant == "C2"


## Il riassunto che i finali mostrano: quello del turno se è in vigore, se no quello di prima
## (stipendi 40, servizi 20, manutenzione 25, riserve 15; debiti conservati; la Casa Comune
## com'è uscita dal capitolo 5).
static func effective_summary(family: String, variant: String) -> Dictionary:
	if in_force(family, variant):
		return RULES.summary(turn_state())
	var sm := RULES.summary(RULES.new_state())
	sm["casa"] = RULES.casa_after("niente")
	sm["debt_rule"] = "conservare"
	return sm


## I debiti degli altri: "registrati", "interessi" (allo 0,5%), "revisione" o "alternative".
static func others_debts(family: String, variant: String) -> String:
	var rule := str(effective_summary(family, variant)["debt_rule"])
	return "registrati" if rule in ["conservare", ""] else rule


# --- il finale B: ogni pezzo dalla sua fonte (docs/STORIA_BANCA_CIMA.md, sezione 6 e nota 2) ----------

const HOME_OFFERS := ["ada", "rina", "fermo"]
const WORK_OFFERS := ["nadir", "leda", "amir"]


## Le offerte sentite davvero (flag offerta_<id>), dalla più recente. Un liberato offre solo da libero.
static func offers(ids: Array) -> Array:
	var out: Array = []
	for id: String in ids:
		if _f("offerta_" + id) and not GameState.is_robot(id) and (id != "fermo" or id in GameState.freed):
			out.append(id)
	out.sort_custom(func(a: String, b: String) -> bool: return int(GameState.flags.get("offerta_%s_seq" % a, 0)) > int(GameState.flags.get("offerta_%s_seq" % b, 0)))
	return out


## Chi manda "Ci sei stasera?": il legame più recente, poi chi ha fatto un'offerta, poi "" (la vicina).
static func evening_sender() -> String:
	var b := bonds()
	if not b.is_empty():
		b.sort_custom(func(a: String, c: String) -> bool: return _bond_order(a) > _bond_order(c))
		return b[0]
	var o := offers(HOME_OFFERS + WORK_OFFERS)
	return o[0] if not o.is_empty() else ""


## Quando è nato il legame: il numero del contatore se c'è, se no l'ordine degli aiuti (salvataggi vecchi).
static func _bond_order(id: String) -> int:
	if GameState.flags.has("aiuto_%s_seq" % id):
		return 1000 + int(GameState.flags["aiuto_%s_seq" % id])
	return GameState.helped_ids.find(id)


static func governance(family: String, variant: String, x: Dictionary) -> String:
	match family:
		"A":
			return "concentrata_totale" if x["power"] else "concentrata"
		"B":
			return "invariata"
	match variant:
		"C2":
			return "condivisa"
		"C1":
			return "comunita_indipendente"
	return "in_discussione"


## Chi si può proporre per un ruolo: le persone adatte con cui hai un legame (poi le altre con un legame).
static func candidates(role: String) -> Array:
	var out: Array = []
	for id: String in ROLES[role]["fit"]:
		if bonded(id):
			out.append(id)
	for id: String in bonds():
		if id not in out and out.size() < 3:
			out.append(id)
	return out.slice(0, 3)
