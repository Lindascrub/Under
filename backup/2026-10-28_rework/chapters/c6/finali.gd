extends RefCounted
## Capitolo 6 — il motore dei finali. Una funzione sola decide famiglia e variante: `decide(selected)`.
## La FAMIGLIA è la scelta conclusiva (A accetta la Direzione, B rifiuta e parte, C propone di decidere insieme).
## La VARIANTE dipende da fatti contati, mai da un punteggio:
##   legami   persone conosciute e aiutate, ancora umane (robot e mai aiutati non contano)
##   reti     reti vere già funzionanti (ordini di Leda, pendolari di Nadir, Casa Comune, bottega, consegne...)
##   prove    documenti veri sul debito
##   bilancio cosa è cambiato nei tre cicli (direzione_regole.summary)
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
const FAMILY_NAMES := {"A": "IL PADRONE", "B": "UN ALTRO DOMANI", "C": "NESSUNO SALE DA SOLO"}
const VARIANT_NAMES := {"A1": "L'ATTICO", "A2": "IL DIRIGENTE CHE CAMBIA LE COSE", "B1": "LA PARTENZA",
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


## Lo stato del bilancio dei tre cicli (salvato in chapter_6.director_turn.state).
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
		"power": bool(c6.get("boss", {}).get("global_credit_accepted", false)),
		"roles_filled": filled,
		"policy": sm,
		"casa_open": RULES.casa_open(str(sm["casa"])),
		"improved": bool(sm["wages_up"]) or bool(sm["services_up"]),
		"rule_changed": str(sm["debt_rule"]) != "conservare" and str(sm["debt_rule"]) != "",
	}


## Le regole delle varianti, in ordine di priorità. La prima vera vince; l'ultima di ogni famiglia è il fallback.
static func variant_rules() -> Dictionary:
	return {
		"A": [
			["A2", "stipendi o servizi migliorati, almeno 2 legami, una regola dei debiti cambiata, attribuzione globale rifiutata",
				func(x: Dictionary) -> bool: return x["improved"] and x["bonds"] >= 2 and x["rule_changed"] and not x["power"]],
			["A1", "altrimenti", func(_x: Dictionary) -> bool: return true],
		],
		"B": [
			["B2", "almeno 2 legami (persone a cui tornare, un tempo da riprendersi)",
				func(x: Dictionary) -> bool: return x["bonds"] >= 2],
			["B1", "altrimenti", func(_x: Dictionary) -> bool: return true],
		],
		"C": [
			["C2", "almeno 3 reti, 4 legami, i 3 ruoli affidati a persone, manutenzione in regola, riserve almeno 15, regola dei debiti cambiata, attribuzione globale rifiutata",
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


## Cosa succede al debito personale. Solo A lo annulla (una volta); B lo contesta se ci sono prove.
static func debt_status(family: String, x: Dictionary) -> String:
	match family:
		"A":
			return "annullato"
		"B":
			return "contestato" if x["evidence"] >= 2 else "registrato"
	return "in_revisione" if x["policy"]["debt_rule"] == "revisione" else ("contestato" if x["evidence"] >= 2 else "registrato")


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
