extends RefCounted
## Capitolo 6 — le regole del TURNO di Direzione (tre cicli di bilancio). Solo dati e conti, niente scena:
## le usano direzione.gd (lo schermo), cima_c6.gd (la stanza), finali.gd (i finali) e i test.
##
## Ogni ciclo ha 100 unità da dividere fra quattro voci. Le regole sono tutte qui, scritte per esteso,
## e lo schermo le mostra prima della conferma (`hints`). Niente barra della bontà, niente punteggio:
##   STIPENDI      base 40. Sotto 30 non si coprono i contratti firmati (minimo vero).
##                 Un aumento è per sempre: dal ciclo dopo non si scende sotto il nuovo livello.
##                 Al -3 i prezzi sono saliti di un terzo: 45-54 copre metà dei prezzi, 55+ li copre tutti.
##   SERVIZI       base 20. Sotto 15 diventano a pagamento, 25+ si allargano (e consumano: +5 al
##                 fabbisogno di manutenzione dei cicli dopo).
##   MANUTENZIONE  fabbisogno 25 (+5 se i servizi si sono allargati). Quello che manca diventa arretrato;
##                 quello in più lo riduce. Con 10 di arretrato si annuncia un guasto: al ciclo dopo
##                 si paga tutto l'arretrato (prima dalle riserve, poi dai servizi). Mai a sorpresa.
##   RISERVE       si accumulano. Al ciclo 2 arriva la bolletta della dinamo del Fondo (15, annunciata
##                 al ciclo 1): si paga dalle riserve, e se non bastano dai servizi di quel ciclo.
## Il ciclo 2 decide anche della Casa Comune (dipende dall'assemblea del capitolo 5), il ciclo 3 la regola
## dei debiti (alcune scelte hanno bisogno di prove o di reti vere: altrimenti sono chiuse, e si dice perché).

const CATS := ["stipendi", "servizi", "manutenzione", "riserve"]
const NAMES := {"stipendi": "STIPENDI", "servizi": "SERVIZI", "manutenzione": "MANUTENZIONE", "riserve": "RISERVE"}
## La distribuzione che la Presidente usa da sempre: il punto di partenza di ogni ciclo.
const BASE := {"stipendi": 40, "servizi": 20, "manutenzione": 25, "riserve": 15}
const TOTAL := 100
const STEP := 5
const MAX_CAT := 60
const MIN_WAGES := 30
const MAINT_NEED := 25
const BILL := 15
const BREAKDOWN_AT := 10

const QUESTIONS := {
	1: "QUANTO VALE IL LAVORO?",
	2: "A CHI APPARTENGONO I SERVIZI?",
	3: "CHI PAGA IL FUTURO?",
}


static func new_state() -> Dictionary:
	return {"reserve": 0, "backlog": 0, "wage_floor": MIN_WAGES, "expanded": 0, "cycle": 1,
		"log": [], "casa": "", "debt_rule": "", "breakdown_due": false, "bill_paid": false}


## Il fabbisogno di manutenzione di questo ciclo.
static func maint_need(st: Dictionary) -> int:
	return MAINT_NEED + 5 * int(st.get("expanded", 0))


## Il minimo per ogni voce in questo ciclo (gli stipendi non scendono sotto contratti e aumenti già dati).
static func minimum(st: Dictionary, cat: String) -> int:
	return int(st.get("wage_floor", MIN_WAGES)) if cat == "stipendi" else 0


## La distribuzione di partenza del ciclo: quella della Presidente, alzata se un aumento lo impone.
static func start_alloc(st: Dictionary) -> Dictionary:
	var a := BASE.duplicate()
	var floor_w := minimum(st, "stipendi")
	if a["stipendi"] < floor_w:
		var extra: int = floor_w - int(a["stipendi"])
		a["stipendi"] = floor_w
		# si toglie dalle riserve, poi dai servizi
		var take := mini(extra, int(a["riserve"]))
		a["riserve"] -= take
		a["servizi"] -= extra - take
	return a


static func total(a: Dictionary) -> int:
	var t := 0
	for c: String in CATS:
		t += int(a.get(c, 0))
	return t


## Si può confermare? "" se sì, se no il motivo (in parole).
static func invalid(st: Dictionary, a: Dictionary) -> String:
	var t := total(a)
	if t != TOTAL:
		return "Hai assegnato %d unità su %d." % [t, TOTAL] if t < TOTAL else "Hai assegnato %d unità: ne hai solo %d." % [t, TOTAL]
	if int(a["stipendi"]) < minimum(st, "stipendi"):
		return "Gli stipendi non possono scendere sotto %d." % minimum(st, "stipendi")
	for c: String in CATS:
		if int(a[c]) < 0 or int(a[c]) > MAX_CAT:
			return "Nessuna voce può superare %d." % MAX_CAT
	return ""


## Più o meno su una voce: il valore nuovo (dentro i limiti), senza toccare le altre.
static func nudge(st: Dictionary, a: Dictionary, cat: String, d: int) -> Dictionary:
	var b := a.duplicate()
	var v := int(b[cat]) + d * STEP
	if d > 0 and total(b) + STEP > TOTAL:
		return b
	b[cat] = clampi(v, minimum(st, cat), MAX_CAT)
	return b


static func wage_label(s: int) -> String:
	if s < 35:
		return "tagliati"
	if s < 45:
		return "fermi (i prezzi no)"
	if s < 55:
		return "aumento: copre metà dei prezzi"
	return "aumento: copre i prezzi"


static func service_label(v: int) -> String:
	if v < 15:
		return "a pagamento"
	if v < 25:
		return "come ora"
	return "allargati"


## Quello che il ciclo ha già addosso prima di decidere: la bolletta, il guasto annunciato.
static func due(st: Dictionary) -> int:
	var d := 0
	if int(st["cycle"]) == 2 and not st.get("bill_paid", false):
		d += BILL
	if st.get("breakdown_due", false):
		d += int(st["backlog"])
	return d


## Le righe da leggere prima di confermare: cosa succede con questa distribuzione. Niente è nascosto.
static func hints(st: Dictionary, a: Dictionary) -> Array:
	var out: Array = []
	var s := int(a["stipendi"])
	var v := int(a["servizi"])
	var m := int(a["manutenzione"])
	var r := int(a["riserve"])
	out.append("STIPENDI %d: %s." % [s, wage_label(s)] + (" Un aumento è per sempre: dopo non si scende sotto %d." % s if s > maxi(40, minimum(st, "stipendi")) else ""))
	var cover := _cover(st, a)
	var v_eff := v - int(cover["from_services"])
	var vs := "SERVIZI %d: %s." % [v, service_label(v_eff)]
	if int(cover["from_services"]) > 0:
		vs += " (Ne restano %d: %d vanno a coprire le spese.)" % [v_eff, int(cover["from_services"])]
	if v_eff >= 25:
		vs += " Più persone li usano: +5 alla manutenzione che serve dal ciclo dopo."
	out.append(vs)
	var need := maint_need(st)
	var backlog_after := maxi(0, int(st["backlog"]) - (int(st["backlog"]) if st.get("breakdown_due", false) else 0) + need - m)
	if m >= need:
		out.append("MANUTENZIONE %d: basta (ne servono %d)." % [m, need] + (" Arretrato: %d." % backlog_after if backlog_after > 0 else ""))
	else:
		out.append("MANUTENZIONE %d: ne servono %d. L'arretrato sale a %d." % [m, need, backlog_after]
			+ (" Con 10 di arretrato, al ciclo dopo si annuncia un guasto." if backlog_after >= BREAKDOWN_AT else ""))
	out.append("RISERVE %d: in cassa ne resteranno %d." % [r, int(cover["reserve_after"])])
	if int(st["cycle"]) == 1:
		out.append("Previsto al ciclo 2: la bolletta della dinamo del Fondo (%d)." % BILL)
	return out


## Come si coprono le spese di questo ciclo: prima le riserve (comprese quelle nuove), poi i servizi.
static func _cover(st: Dictionary, a: Dictionary) -> Dictionary:
	var cost := due(st)
	var pot := int(st["reserve"]) + int(a["riserve"])
	var from_reserve := mini(cost, pot)
	var from_services := mini(cost - from_reserve, int(a["servizi"]))
	return {"cost": cost, "from_reserve": from_reserve, "from_services": from_services, "reserve_after": pot - from_reserve}


## Conferma il ciclo: aggiorna lo stato comune e restituisce quello che è successo (righe da leggere).
static func apply(st: Dictionary, a: Dictionary) -> Array:
	var out: Array = []
	var cover := _cover(st, a)
	var s := int(a["stipendi"])
	var v_eff := int(a["servizi"]) - int(cover["from_services"])
	if int(cover["cost"]) > 0:
		out.append("Spese del ciclo: %d. Dalle riserve: %d." % [int(cover["cost"]), int(cover["from_reserve"])]
			+ (" Dai servizi: %d." % int(cover["from_services"]) if int(cover["from_services"]) > 0 else ""))
	if st.get("breakdown_due", false):
		out.append("Il guasto annunciato è arrivato: l'ascensore merci si è fermato. Riparato, e pagato.")
		st["backlog"] = 0
		st["breakdown_due"] = false
	if int(st["cycle"]) == 2:
		st["bill_paid"] = true
	st["reserve"] = int(cover["reserve_after"])
	var need := maint_need(st)
	st["backlog"] = maxi(0, int(st["backlog"]) + need - int(a["manutenzione"]))
	if int(st["backlog"]) >= BREAKDOWN_AT:
		st["breakdown_due"] = true
		out.append("Arretrato di manutenzione: %d. Al prossimo ciclo un guasto è sicuro: è annunciato adesso." % int(st["backlog"]))
	if v_eff >= 25:
		st["expanded"] = int(st["expanded"]) + 1
	if s > int(st["wage_floor"]) and s > 40:
		st["wage_floor"] = s
	out.push_front("Stipendi: %s. Servizi: %s." % [wage_label(s), service_label(v_eff)])
	(st["log"] as Array).append({"cycle": int(st["cycle"]), "alloc": a.duplicate(), "services_eff": v_eff,
		"reserve": int(st["reserve"]), "backlog": int(st["backlog"])})
	st["cycle"] = int(st["cycle"]) + 1
	return out


# --- le scelte del ciclo 2 e 3 -----------------------------------------------------------------------

## La Casa Comune com'era alla fine del capitolo 5: "riconversione", "comunitaria" o "sospesa".
static func casa_state() -> String:
	var e := str(GameState.flags.get("c5_esito", ""))
	if not GameState.flags.get("c5_assemblea", false) or e == "rinvio" or e == "":
		return "sospesa"
	return e


## Le opzioni del ciclo 2 sulla Casa Comune: [id, testo, motivo se chiusa ("" se aperta)].
static func casa_options(st: Dictionary, a: Dictionary) -> Array:
	var f := GameState.flags
	var v := int(a["servizi"]) - int(_cover(st, a)["from_services"])
	var out: Array = []
	match casa_state():
		"riconversione":
			out.append(["accessi", "Finanzia degli accessi gratuiti al centro CHEAP", "" if v >= 25 else "Servono almeno 25 ai servizi (adesso %d)." % v])
			out.append(["contratto", "Rinegozia il contratto della Casa", "" if f.get("c5_rapporto", false) or f.get("c5_documento", false) else "Senza i bilanci della Casa non hai niente da mettere sul tavolo."])
		"comunitaria":
			out.append(["risorse", "Dai risorse alla gestione comunitaria", "" if v >= 20 else "Servono almeno 20 ai servizi (adesso %d)." % v])
			out.append(["autonomia", "Lasciala autonoma, senza fondi né controlli", ""])
		_:
			var left := int(_cover(st, a)["reserve_after"])
			out.append(["proroga", "Finanzia una proroga (10 dalle riserve)", "" if left >= 10 else "Le riserve non bastano: dopo le spese ne restano %d, ne servono 10." % left])
			out.append(["modello", "Proponi un nuovo modello: le stanze come le ha organizzate Ada", "" if f.get("c5_ada_stanze", false) else "Nessuno ha mai organizzato le stanze: non c'è un modello da proporre."])
	out.append(["niente", "Non intervenire", ""])
	return out


## Com'è la Casa Comune dopo il ciclo 2.
static func casa_after(choice: String) -> String:
	match choice:
		"accessi":
			return "riconvertita_con_accessi"
		"contratto":
			return "contratto_rinegoziato"
		"risorse":
			return "comunitaria_sostenuta"
		"autonomia":
			return "comunitaria_autonoma"
		"proroga":
			return "prorogata"
		"modello":
			return "nuovo_modello"
	match casa_state():
		"riconversione":
			return "riconvertita"
		"comunitaria":
			return "comunitaria_autonoma"
	return "chiusa"


## La Casa Comune è aperta a tutti, dopo il ciclo 2?
static func casa_open(c: String) -> bool:
	return c in ["riconvertita_con_accessi", "contratto_rinegoziato", "comunitaria_sostenuta", "comunitaria_autonoma", "prorogata", "nuovo_modello"]


static func apply_casa(st: Dictionary, choice: String) -> void:
	if choice == "proroga":
		st["reserve"] = int(st["reserve"]) - 10
	st["casa"] = casa_after(choice)


## Le prove raccolte sul debito (documenti veri, non opinioni).
static func evidence() -> Array:
	var f := GameState.flags
	var out: Array = []
	if f.get("c6_contratto_letto", false):
		out.append("il fascicolo OBBLIGO DI ESISTENZA, senza firma")
	if f.get("c4_anomalia", false):
		out.append("l'anomalia del conto alla Banca")
	if f.get("c4_olga_doppia", false):
		out.append("le commissioni doppie di Olga")
	if f.get("c4_teo_copia", false):
		out.append("la copia del rapporto 404 di Teo")
	if f.get("c5_documento", false):
		out.append("la valutazione CHEAP sulla Casa Comune")
	return out


## Le reti vere costruite nei capitoli prima (chi c'è davvero, non chi lo ha promesso).
static func networks(st := {}) -> Array:
	var f := GameState.flags
	var out: Array = []
	if f.get("c3_leda_ordini", false) and not GameState.is_robot("leda"):
		out.append("gli ordini condivisi di Leda")
	if f.get("c5_nadir_rete", false):
		out.append("la rete dei pendolari di Nadir")
	if (f.get("c5_assemblea", false) and str(f.get("c5_esito", "")) == "comunitaria") or str(st.get("casa", "")) in ["comunitaria_sostenuta", "comunitaria_autonoma", "nuovo_modello"]:
		out.append("la Casa Comune gestita da chi la usa")
	if f.get("c5_vetrina_aiuto", false):
		out.append("la bottega di Rina come punto di raccolta")
	if f.get("c5_amir_consegne", false) and not GameState.is_robot("amir"):
		out.append("le consegne di Amir")
	if f.get("c4_olga_contestazione", false):
		out.append("la contestazione di Olga (e chi l'ha copiata)")
	return out


## Le regole sui debiti del ciclo 3: [id, testo, come funziona, motivo se chiusa].
static func debt_options(st: Dictionary, a: Dictionary) -> Array:
	var res := int(_cover(st, a)["reserve_after"])
	var ev := evidence()
	var nets := networks(st)
	return [
		["conservare", "Conserva il sistema dei debiti",
			"Interessi al 2% a notte. Tutto resta com'è: anche quello che funziona.", ""],
		["interessi", "Riduci gli interessi",
			"Dal 2% allo 0,5% a notte. Le riserve coprono quello che la Torre smette di incassare.",
			"" if res >= 15 else "Servono almeno 15 di riserve per coprirlo (ne avrai %d)." % res],
		["revisione", "Avvia la revisione dei debiti imposti",
			"Ogni debito senza firma viene sospeso e ricontrollato, uno per uno. Partendo dalle prove.",
			"" if ev.size() >= 2 and GameState.flags.get("c6_contratto_letto", false) else "Senza almeno due prove (fra cui il fascicolo della Presidente) la revisione non ha da dove cominciare."],
		["alternative", "Sviluppa fonti alternative di finanziamento",
			"Gli ordini, le consegne, la Casa: le reti che già funzionano pagano una parte dei servizi, al posto degli interessi.",
			"" if nets.size() >= 2 else "Servono almeno due reti vere che già funzionano (ne conosci %d)." % nets.size()],
	]


## Riassunto dei tre cicli per i finali: cosa è cambiato davvero (fatti, non giudizi).
static func summary(st: Dictionary) -> Dictionary:
	var log: Array = st.get("log", [])
	var last: Dictionary = log[log.size() - 1] if not log.is_empty() else {"alloc": BASE, "services_eff": 20}
	var la: Dictionary = last["alloc"]
	return {
		"wages_up": int(la["stipendi"]) >= 45,
		"wages_cover": int(la["stipendi"]) >= 55,
		"wages_cut": int(la["stipendi"]) < 35,
		"services_up": int(last["services_eff"]) >= 25,
		"services_paid": int(last["services_eff"]) < 15,
		"maintenance_ok": int(st.get("backlog", 0)) < BREAKDOWN_AT,
		"reserve": int(st.get("reserve", 0)),
		"reserve_ok": int(st.get("reserve", 0)) >= 15,
		"casa": str(st.get("casa", "")),
		"debt_rule": str(st.get("debt_rule", "conservare")),
		"cycles": log.size(),
	}
