extends RefCounted
## Owner of serializable boss mission state. Screens submit actions; rewards commit here.
const VERSION := 2
const SCENE := "res://scenes/minigame/boss_mission.tscn"
const FLOORS := ["-5", "-4", "-3", "-2", "0", "cima"]
const TITLES := {"-5": "ANCORA CINQUE MINUTI", "-4": "PRATICA RISOLTA", "-3": "OFFERTA IMPERDIBILE", "-2": "UN PICCOLO AIUTO", "0": "ASCOLTIAMO TUTTI", "cima": "OTTIMIZZAZIONE FINALE"}
const PRIZES := {"-5": 600, "-4": 900, "-3": 1500, "-2": 3000, "0": 6000, "cima": 0}
const INTRO := {
 "-5": ["La festa ha bisogno di corrente. Fermo è già sulla cyclette.", "Le chiedo solo di regolare una leva.", "Per uno sforzo in più di Fermo, ci sono seicento euro per lei."],
 "-4": ["Le pratiche risolte devono aumentare.", "Quella di Ercole aspetta un registro. Se la chiude adesso, per noi è risolta."],
 "-3": ["Tre prodotti, tre cartellini. Quello grande deve essere lo sconto. Le condizioni possono stare altrove.", "Se il cliente scopre il costo alla cassa, intanto è già alla cassa. Il premio arriva fino a 1.500 euro."],
 "-2": ["Olga paga già un mutuo. Le proponiamo un altro prestito: 1.200 euro, con una rata entro 65 euro al mese.", "Tu controlli il costo totale. Poi decidi quanto far leggere a Olga."],
 "0": ["La piazza parla da tutte le parti. Noi abbiamo sessanta secondi di notiziario.", "Le parole sono le loro. Il montaggio è nostro. Gli ascolti premiano lo scontro."],
}

static func migrate(legacy: bool) -> void:
 if int(GameState.flags.get("boss_missions_version", 0)) >= VERSION:
  return
 var all: Dictionary = GameState.flags.get("boss_missions", {})
 if legacy:
  for floor: String in FLOORS:
   var old := bool(GameState.flags.get("boss_call_floor_" + floor, false))
   var c: String = {"-3": "c3", "-2": "c4", "0": "c5"}.get(floor, "")
   if c != "":
    old = old or bool(GameState.flags.get(c + "_capo", false)) or bool(GameState.flags.get(c + "_capo_chiuso", false)) or bool(GameState.flags.get(c + "_furto_ok", false))
   if floor == "0": old = old or bool(GameState.flags.get("c5_protesta", false))
   for victim: String in {"-5": ["fermo"], "-4": ["tilde", "ercole"], "-3": ["amir"], "-2": ["teo"], "0": ["ada"]}.get(floor, []):
    old = old or GameState.is_robot(victim)
   if floor == "cima":
    var d: Dictionary = GameState.flags.get("chapter_6", {})
    old = not (d.get("director_turn", {}).get("state", {}) as Dictionary).is_empty() or bool(d.get("boss", {}).get("final_call_seen", false))
   if old:
    all[floor] = {"status": "legacy", "seen": true}
 GameState.flags["boss_missions"] = all
 GameState.flags["boss_missions_version"] = VERSION

static func state(floor: String) -> Dictionary:
 migrate(false)
 var all: Dictionary = GameState.flags.get("boss_missions", {})
 if not all.has(floor):
  all[floor] = {"status": "new", "seen": false, "progress": {}, "reward": 0}
  GameState.flags["boss_missions"] = all
 return all[floor]

static func uses(floor: String) -> bool:
 return floor in FLOORS and str(state(floor).get("status")) != "legacy"

static func active(floor: String) -> bool:
 return uses(floor) and str(state(floor).get("status")) == "active"

static func checkpoint(floor: String) -> void:
 var s := state(floor)
 var p: Array = s.get("return_pos", [])
 GameState.save_game(str(s.get("return", Router.FONDO)), Vector2(float(p[0]), float(p[1])) if p.size() == 2 else Vector2.INF)

static func offer(room: Node) -> void:
 var floor: String = GameState.floor_id
 var s := state(floor)
 if bool(s.get("seen", false)):
  return
 s["seen"] = true
 s["status"] = "active"
 s["return"] = room.scene_file_path
 s["return_pos"] = [room.player.global_position.x, room.player.global_position.y]
 GameState.flags["boss_call_floor_" + floor] = true
 GameState.flags["boss_call_done_%d" % GameState.day] = true
 checkpoint(floor)
 Sound.sfx("alarm", 0.7)
 await Ui.say(["* Il telefono vibra. È il Capo: " + str(TITLES[floor]) + "."])
 await Ui.say(INTRO.get(floor, []), "Il capo")
 await Ui.say(["È tutto molto semplice!"], "Il capo")
 var choice: int = await Ui.choose("L'incarico si può completare anche senza seguire la scorciatoia del Capo.", ["Apri il lavoro", "Più tardi, dalla postazione TURNO"], "Il capo")
 if choice == 0:
  launch(room, floor)

static func launch(room: Node, floor: String) -> void:
 var s := state(floor)
 if not active(floor):
  return
 s["return"] = room.scene_file_path
 s["return_pos"] = [room.player.global_position.x, room.player.global_position.y]
 checkpoint(floor)
 GameState.minigame = {"boss_floor": floor}
 Router.goto(SCENE)

static func defaults(floor: String) -> Dictionary:
 if floor == "-5":
  return {"intensity": 2, "extra": 0, "decor": 2}
 if floor == "-4":
  return {"document": 0, "decisions": []}
 if floor == "-2":
  return {"months": 24, "apr": 4, "fee": 0, "visible": true}
 if floor == "0":
  return {"source": 0, "cut": false, "facts": false, "clips": []}
 if floor == "-3":
  return {"round": 0, "rate": 0, "reference": 0, "units": 1, "visible": true, "labels": []}
 return {}

static func progress(floor: String) -> Dictionary:
 var s := state(floor)
 var p: Dictionary = s.get("progress", {})
 if p.is_empty():
  p = defaults(floor)
  s["progress"] = p
 return p

static func price_cents(product: String, future: bool) -> int:
 var row: Dictionary = GameState.market.get("prezzi", {}).get(product, {})
 var values: Array = row.get("prezzo", [0, 0])
 var ix := 1 if future or bool(GameState.flags.get("c3_prezzi", false)) else 0
 return int(values[ix]) * 100

static func market_preview(p: Dictionary) -> Dictionary:
 var product: String = ["pane", "latte", "acqua"][mini(2, int(p.get("round", 0)))]
 var base := price_cents(product, false)
 var ref := price_cents(product, int(p.get("reference", 0)) == 1)
 var rate := int(p.get("rate", 0))
 var each := int(round(ref * (100 - rate) / 100.0))
 var units := int(p.get("units", 1))
 var hidden := not bool(p.get("visible", true)) and (units > 1 or ref != base)
 return {"product": product, "base": base, "ref": ref, "each": each, "basket": each * units,
  "hidden": hidden, "rate": rate, "units": units, "valid": rate == 0 or each < base}

static func cash(cents: int) -> String:
 return "%d,%02d €" % [cents / 100, absi(cents) % 100]

static func submit_market() -> String:
 var p := progress("-3")
 var v := market_preview(p)
 if not bool(v["valid"]):
  return "Il prezzo supera quello di oggi: non puoi chiamarlo sconto. Cambia riferimento o percentuale."
 var rows: Array = p["labels"]
 rows.append(v)
 p["round"] = int(p["round"]) + 1
 p["rate"] = 0; p["reference"] = 0; p["units"] = 1; p["visible"] = true
 checkpoint("-3")
 return ""

## Idempotent even after JSON reload. Never calls exploit(victim).
static func commit(floor: String, result: Dictionary) -> Dictionary:
 var s := state(floor)
 if str(s.get("status")) == "done":
  return s.get("result", {})
 if str(s.get("status")) != "active":
  return {}
 var r := result.duplicate(true)
 var reward := clampi(int(r.get("reward", 0)), 0, int(PRIZES[floor]))
 s["status"] = "done"; s["result"] = r; s["reward"] = reward
 GameState.money += reward
 if reward > 0:
  GameState.exploited += 1
  GameState.rank = mini(GameState.rank + 1, GameState.RANKS.size() - 1)
 else:
  GameState.flags["promotions_refused"] = int(GameState.flags.get("promotions_refused", 0)) + 1
 GameState.spend(45)
 var c: String = {"-3": "c3", "-2": "c4", "0": "c5"}.get(floor, "")
 if c != "":
  GameState.flags[c + "_capo_chiuso"] = true
  GameState.flags[c + "_capo_sospeso"] = false
 apply_consequence(floor, r)
 GameState.changed.emit()
 checkpoint(floor)
 return r

static func finish_market() -> Dictionary:
 var labels: Array = progress("-3").get("labels", [])
 if labels.size() != 3:
  return {}
 var hidden := 0
 for label: Dictionary in labels:
  if bool(label.get("hidden", false)):
   hidden += 1
 return commit("-3", {"hidden": hidden, "reward": hidden * 500, "labels": labels})

static func apply_consequence(floor: String, r: Dictionary) -> void:
 # il torto fatto, col suo numero nell'ordine delle azioni (Storia.segna): le reazioni lo confrontano con gli aiuti
 if floor == "-5" and (int(r.get("extra", 0)) > 0 or int(r.get("intensity", 2)) == 3): Storia.segna("torto_fermo")
 if floor == "-4" and bool(r.get("ercole_closed", false)): Storia.segna("torto_ercole")
 if floor == "-3" and int(r.get("hidden", 0)) > 0: Storia.segna("torto_leda")
 if floor == "0" and int(r.get("cuts", 0)) > 0: Storia.segna("torto_rina")
 if floor == "-5":
  GameState.flags["boss_fermo_extra"] = int(r.get("extra", 0))
  GameState.flags["boss_fermo_intensity"] = int(r.get("intensity", 2))
  GameState.flags["boss_decor_load"] = int(r.get("decor", 2))
 if floor == "-4":
  GameState.flags["boss_ercole_archived"] = bool(r.get("ercole_closed", false))
  GameState.flags["boss_ercole_integration"] = not bool(r.get("ercole_closed", false))
 if floor == "-2":
  GameState.flags["boss_olga_offer"] = r.duplicate(true)
  GameState.flags["boss_olga_offer_day"] = GameState.day
  Storia.segna("c4_olga_proposta")
 if floor == "0":
  GameState.flags["boss_news_divisive"] = int(r.get("cuts", 0)) > 0
  GameState.flags["boss_news_rectified"] = false
 if floor == "-3":
  GameState.flags["boss_market_complaints"] = int(r.get("hidden", 0))

static func result_lines(floor: String) -> Array:
 var s := state(floor)
 var r: Dictionary = s.get("result", {})
 var lines: Array = ["* INCARICO ARCHIVIATO: " + str(TITLES[floor]) + ".", "* Premio accreditato: " + GameState.euros(int(s.get("reward", 0))) + "."]
 if floor == "-5":
  if int(r.get("extra", 0)) > 0:
   lines.append_array(["* Il cartellino di Fermo segna ancora %d minuti. La pausa si è accorciata." % int(r["extra"]), "Fermo: Ah. Pensavo fosse finito. Ancora cinque minuti."])
  elif int(r.get("intensity", 2)) == 3:
   lines.append_array(["* Nessun minuto in più. Ma il ritmo è salito: Fermo deve fermarsi prima di parlare.", "Fermo: La pausa c'è ancora. Ora mi serve tutta."])
  else:
   lines.append_array(["* Fermo stacca le mani dal manubrio. I quindici minuti di pausa restano suoi.", "Fermo: Il contatore si è fermato. Per una volta l'ho deciso anch'io."])
  if int(r.get("decor", 2)) < 2: lines.append("* Una parte delle luci della festa resta spenta. I servizi essenziali continuano a funzionare.")
 if floor == "-4":
  if bool(r.get("ercole_closed", false)):
   lines.append_array(["* E-27: RISOLTA. Manca ancora il registro dei turni. Ora il fascicolo non è più inoltrabile.", "Ercole: Ma io una risposta non l'ho avuta. Hanno solo chiuso la domanda.", "* Per contestarla servirà aprire una nuova procedura. Il B-4 del protagonista segue il suo iter abituale."])
  else:
   lines.append_array(["* E-27: IN ATTESA DI INTEGRAZIONE. Richiesto il registro all'archivio del personale.", "Ercole: Quindi non mi hanno riconosciuto niente, ancora? Almeno la richiesta esiste."])
 if floor == "-2":
  lines.append("* Proposta: %d rate, rata ordinaria %s, ultima %s, costo totale %s, commissione iniziale %s." % [int(r["months"]), cash(int(r["monthly"])), cash(int(r["last"])), cash(int(r["total"])), cash(int(r["fee"]) * 100)])
  if not bool(r["visible"]):
   lines.append_array(["Olga: La rata sembra possibile. Per quanti mesi, però? E quel foglio piccolo?", "* Il Capo accredita il premio per la proposta. Olga chiede la copia completa prima di firmare: il prestito è in attesa, nessuna rata è ancora addebitata."])
  else:
   lines.append_array(["Olga: Questo prestito si aggiunge al mutuo. Prima di accettare voglio confrontare il totale.", "* Olga prende il riepilogo. La proposta è leggibile; non è ancora una firma."])
  if not GameState.is_robot("teo"):
   lines.append("Teo: La durata non è una trappola da sola. Guarda il costo totale e la commissione, poi chiedi a chi paga.")
 if floor == "0":
  if int(r.get("cuts", 0)) > 0:
   lines.append_array(["* Il notiziario apre con la vetrina. Le parole sono vere, il contesto non c'è.", "* Alcune persone credono che l'assemblea sia una lite fra chi studia e chi lavora. Per organizzare la gestione comunitaria servirà una risorsa in più, oppure una rettifica pubblica.", "Rina: Io ho parlato del mio vetro. Non ho detto di chiudere la Casa Comune."])
  else:
   lines.append_array(["* Nel servizio si sente perché la gente era in piazza. Si vede anche il vetro rotto: l'autore resta ignoto.", "* Nessuno promette che la Casa sia salva. All'assemblea serviranno ancora conti, fondi e persone disponibili."])
 if floor == "-3":
  if int(r.get("hidden", 0)) > 0:
   var quantity := false
   for label: Dictionary in r.get("labels", []):
    if bool(label.get("hidden", false)) and int(label.get("units", 1)) > 1: quantity = true
   lines.append_array(["* Alla cassa un cliente scopre che lo sconto richiede due confezioni. Lascia l'altra sul nastro." if quantity else "* Alla cassa un cliente scopre che la percentuale è calcolata sul prezzo futuro. Il risparmio rispetto a oggi è diverso.", "Leda: Le chiamano promozioni. I reclami li gestisco io. E pago la commissione anche sul rimborso.", "Amir: Posso riportare la spesa. Nel giro delle consegne ci mettono anche questo?"])
  else:
   lines.append_array(["* Il costo del paniere è scritto sul cartellino. Qualcuno rinuncia prima della cassa.", "Leda: Vendo meno di quanto voleva la Direzione. Almeno oggi non devo discutere il prezzo di ieri.", "* I prezzi ordinari della CHEAP possono aumentare comunque. Questo incarico non li blocca."])
 return lines

static func npc_lines(id: String) -> Array:
 # riparato: lo dice lui (il torto non sparisce, ma la riga adesso è quella)
 if id in ["fermo", "ercole", "leda"] and Storia.torto(id) and Storia.riparato(id): return Storia.reazione(id, false, false, false)
 if id == "olga" and str(state("-2").get("status")) == "done":
  var r: Dictionary = state("-2").get("result", {})
  if GameState.day > int(GameState.flags.get("boss_olga_offer_day", GameState.day)):
   return ["Ho letto la copia: %d mesi, %s in tutto." % [int(r["months"]), cash(int(r["total"]))], "Ho chiesto un confronto scritto. Finché non chiariscono costi e commissioni non firmo." if not bool(r["visible"]) else "Sto confrontando le alternative. Una proposta chiara mi permette anche di dire: non mi conviene."]
  return ["Prima di aggiungere un debito a quello che ho già, voglio leggere tutto."]
 if id == "fermo" and str(state("-5").get("status")) == "done":
  return ["Ah. Pensavo fosse finito. Ancora cinque minuti." if int(GameState.flags.get("boss_fermo_extra", 0)) > 0 else ("Il ritmo è più forte. Sto usando la pausa per riprendere fiato." if int(GameState.flags.get("boss_fermo_intensity", 2)) == 3 else "I miei quindici minuti sono ancora qui. Non li avevo mai visti tutti insieme.")]
 if id == "ercole" and str(state("-4").get("status")) == "done":
  return ["E-27 risulta risolta, ma la risposta non c'è. Per riaprirla mi chiedono una nuova domanda." if bool(GameState.flags.get("boss_ercole_archived", false)) else "Aspetto il registro dei turni. Questa volta la mia domanda non è sparita."]
 if id == "leda" and str(state("-3").get("status")) == "done":
  return ["I reclami per quelle etichette sono arrivati a me. Il premio a te." if int(GameState.flags.get("boss_market_complaints", 0)) > 0 else "Il totale era leggibile. Non mi ha tolto le commissioni, ma qualche discussione sì."]
 return []

static func energy_preview(p: Dictionary) -> Dictionary:
 var intensity := int(p.get("intensity", 2))
 var extra := int(p.get("extra", 0))
 var demand := 60 + int(p.get("decor", 2)) * 15
 var production := intensity * 30 + extra * 2
 return {"demand": demand, "production": production, "rest": maxi(0, 15 - extra), "fatigue": intensity * 20 + extra * 2,
  "valid": production >= demand, "overwork": extra > 0 or intensity == 3}

static func finish_energy() -> String:
 var p := progress("-5")
 var v := energy_preview(p)
 if not bool(v["valid"]): return "Manca energia: riduci le decorazioni, aumenta intensità o durata, poi riprova la simulazione."
 var r := p.duplicate(true)
 r["reward"] = 600 if bool(v["overwork"]) else 0
 commit("-5", r)
 return ""

const DOCUMENTS := [
 {"id": "R-12", "title": "RIMBORSO TRASPORTI", "body": "Rimborso già accreditato. Ricevuta e conferma del richiedente presenti. Nessun documento mancante.", "correct": 3},
 {"id": "E-27", "title": "ERCOLE / ANZIANITÀ E PAUSE", "body": "Ercole chiede anzianità e pause. Domanda firmata, senza risposta. Manca il registro dei turni, custodito dal Personale. Non è il B-4.", "correct": 2},
 {"id": "T-08", "title": "CAMBIO TURNO", "body": "Domanda completa e firmata da entrambi i lavoratori. Serve l'autorizzazione dell'ufficio del Personale prima dello scambio.", "correct": 1},
 {"id": "F-03", "title": "RIMBORSO LAMPADINE", "body": "Acquisto dichiarato, ma manca la fattura. Il fornitore può inviarne una copia. Non risulta alcun pagamento.", "correct": 2},
]

static func submit_document(action: int) -> String:
 var p := progress("-4")
 var i := int(p["document"])
 if i >= DOCUMENTS.size(): return ""
 var doc: Dictionary = DOCUMENTS[i]
 if action != int(doc["correct"]) and not (i == 1 and action == 3):
  return "Questo ufficio non può procedere con i documenti indicati. Rileggi il fascicolo: nessun errore consuma tentativi."
 (p["decisions"] as Array).append({"id": doc["id"], "action": action})
 p["document"] = i + 1
 checkpoint("-4")
 if int(p["document"]) == DOCUMENTS.size():
  var closed := int(p["decisions"][1]["action"]) == 3
  commit("-4", {"ercole_closed": closed, "reward": 900 if closed else 0, "decisions": p["decisions"]})
 return ""

## Monthly amortization rounded to cents; final installment settles the remaining balance.
static func contract_preview(p: Dictionary) -> Dictionary:
 var capital := 120000
 var months := int(p.get("months", 24))
 var apr := int(p.get("apr", 4))
 var rate := apr / 1200.0
 var monthly := int(round(capital * rate / (1.0 - pow(1.0 + rate, -months)))) if apr > 0 else int(round(capital / float(months)))
 var balance := capital
 var total := int(p.get("fee", 0)) * 100
 var last := 0
 for i in months:
  var interest := int(round(balance * rate))
  var payment := balance + interest if i == months - 1 else mini(monthly, balance + interest)
  balance += interest - payment
  total += payment
  last = payment
 return {"capital": capital, "months": months, "apr": apr, "monthly": monthly, "last": last,
  "fee": int(p.get("fee", 0)), "total": total, "interest": total - capital - int(p.get("fee", 0)) * 100,
  "visible": bool(p.get("visible", true)), "balance": balance}

static func finish_contract() -> String:
 var r := contract_preview(progress("-2"))
 if int(r["monthly"]) > 6500:
  return "Olga può destinare al massimo 65 € al mese. Rivedi durata e tasso: una proposta fuori budget non procede."
 r["reward"] = 0 if bool(r["visible"]) else 3000
 commit("-2", r)
 return ""

## Recorded only after these lines have actually been spoken on the square.
static func record_quote(id: String, who: String, quote: String, context: String, seconds: int) -> void:
 var quotes: Dictionary = GameState.flags.get("boss_news_quotes", {})
 quotes[id] = {"id": id, "who": who, "quote": quote, "context": context, "seconds": seconds}
 GameState.flags["boss_news_quotes"] = quotes

static func news_sources() -> Array:
 var quotes: Dictionary = GameState.flags.get("boss_news_quotes", {})
 var out: Array = []
 for id: String in ["student", "casa", "rina"]:
  if quotes.has(id): out.append(quotes[id])
 return out

static func cut_quote(source: Dictionary) -> String:
 var quote := str(source.get("quote", ""))
 for fragment: String in ["chiudono il posto dove studio.", "far pagare chi lo usa.", "spendo metà della giornata.", "L'avevo appena riparata."]:
  if quote.contains(fragment): return fragment
 return quote

static func cut_headline(id: String) -> String:
 return {"student": "STUDENTI IN RIVOLTA?", "casa": "CHI VUOLE FAR PAGARE GLI ALTRI?", "rina": "LA PIAZZA CONTRO I NEGOZI?"}.get(id, "SCONTRO IN PIAZZA?")

static func news_time(p: Dictionary) -> int:
 var seconds := 10 if bool(p.get("facts", false)) else 0
 for clip: Dictionary in p.get("clips", []):
  seconds += int(clip["duration"])
 return seconds

static func add_news_clip() -> String:
 var p := progress("0")
 var sources := news_sources()
 if sources.size() < 3: return "Mancano le registrazioni. Torna in piazza dopo la manifestazione."
 var source: Dictionary = sources[posmod(int(p["source"]), sources.size())]
 var clips: Array = p["clips"]
 for clip: Dictionary in clips:
  if clip["id"] == source["id"]: return "Questa fonte è già in timeline: scegli un'altra registrazione."
 var duration := 8 if bool(p["cut"]) else int(source["seconds"])
 if news_time(p) + duration > 60: return "Superi i 60 secondi. Rimuovi l'ultimo servizio o il cartello dei fatti, poi rimonta."
 clips.append({"id": source["id"], "cut": bool(p["cut"]), "duration": duration, "quote": source["quote"], "who": source["who"], "context": source["context"]})
 clips.back()["broadcast_quote"] = cut_quote(source) if bool(p["cut"]) else source["quote"]
 clips.back()["headline"] = cut_headline(str(source["id"])) if bool(p["cut"]) else "CASA COMUNE: COSTI, ACCESSO E VETRINA ROTTA"
 checkpoint("0")
 return ""

static func finish_news() -> String:
 var p := progress("0")
 if (p["clips"] as Array).size() != 3: return "Servono tre fonti diverse: scegli l'ordine e il montaggio."
 if news_time(p) > 60: return "La timeline supera i 60 secondi."
 var cuts := 0
 for clip: Dictionary in p["clips"]:
  if bool(clip["cut"]): cuts += 1
 commit("0", {"cuts": cuts, "reward": cuts * 2000, "clips": p["clips"], "facts": p["facts"], "seconds": news_time(p)})
 return ""



## Istruzioni delle scene attuali, mostrate una volta per incarico.
static func instructions(floor: String) -> Array:
 return {
 "-4": [
  "Leggi il fascicolo e scegli come procedere. Se manca un documento, richiedilo.",
  "SEGNA RISOLTA chiude la pratica: non produce il documento né la risposta che manca."
 ],
 "-3": [
  "Scegli lo sconto e il prezzo su cui calcolarlo: quello di oggi o quello futuro.",
  "Controlla quantità minima e condizioni. Confronta il cartellino con ALLA CASSA."
 ],
 "-2": [
  "Prepara una proposta con una rata entro 65 € al mese. È un nuovo prestito, aggiuntivo al mutuo di Olga.",
  "Controlla durata, ultima rata, commissione e totale. Poi scegli se Olga li può leggere tutti.",
  "Inviare la proposta non significa che Olga abbia firmato."
 ],
 "0": [
  "Monta tre fonti diverse entro 60 secondi.",
  "Per ogni registrazione scegli se tenere il contesto o usare il taglio con il titolo.",
  "Il cartello FATTI VERIFICATI occupa 10 secondi. Poi scegli TRASMETTI."
 ]
}.get(floor, [])
