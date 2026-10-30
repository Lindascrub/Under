extends Node
const B := preload("res://scripts/boss_missions.gd")
const R := preload("res://chapters/c6/direzione_regole.gd")
const F := preload("res://chapters/c6/finali.gd")
const CITY := preload("res://chapters/c5/citta_c5.gd")
var failures := 0
var count := 0
func check(v: bool, label: String) -> void:
 count += 1
 if not v: failures += 1; push_error(label)
func fresh(floor: String) -> Dictionary:
 GameState.new_game(); GameState.floor_id = floor
 var s := B.state(floor); s["status"] = "active"
 s["return"] = Router.FONDO
 return B.progress(floor)
func _ready() -> void:
 GameState.save_path = "user://test_boss_rules.json"
 var p := fresh("-5")
 check(B.finish_energy() != "", "Energia insufficiente non confermata")
 p["decor"] = 0
 check(B.finish_energy() == "", "Risparmio decorazioni giocabile")
 check(GameState.money == 0 and not GameState.is_robot("fermo"), "Fermo conserva pausa e umanità")
 p = fresh("-5"); p["extra"] = 15
 check(B.finish_energy() == "" and GameState.money == 600, "Extra alimenta tutta la festa e paga")
 check(int(B.energy_preview(p)["rest"]) == 0, "Pausa visibilmente consumata")
 B.finish_energy(); check(GameState.money == 600, "Extra non duplicato")
 p = fresh("-5"); p["intensity"] = 3
 check(B.finish_energy() == "" and int(GameState.flags["boss_fermo_intensity"]) == 3, "Intensità ha conseguenza distinta")
 for closed in [false, true]:
  p = fresh("-4")
  check(B.submit_document(0) != "", "Documento completo non diretto al posto sbagliato")
  check(B.submit_document(3) == "", "Chiusura legittima del rimborso")
  check(B.submit_document(3 if closed else 2) == "", "Ercole chiusura o integrazione")
  check(B.submit_document(1) == "", "Cambio turno al Personale")
  check(B.submit_document(2) == "", "Fattura mancante da integrare")
  check(GameState.money == (900 if closed else 0), "Premio coerente con E-27")
  check(bool(GameState.flags.get("boss_ercole_archived", false)) == closed, "Stato richiesta persistente")
  GameState.load_game()
  check(str(B.state("-4")["status"]) == "done", "Pratiche caricate senza ripetizione")
  check(not GameState.is_robot("ercole") and not GameState.is_robot("tilde"), "Nessun nuovo robot in ufficio")
 # Restoring a stopped score must not resurrect music in the revealed office.
 for months in [12, 24, 36]:
  for apr in [4, 8, 12]:
   for fee in [0, 60, 120]:
    var quote := B.contract_preview({"months": months, "apr": apr, "fee": fee})
    check(int(quote["balance"]) == 0, "Contratto estinto a centesimi")
    check(int(quote["total"]) == int(quote["monthly"]) * (months - 1) + int(quote["last"]) + fee * 100, "Totale delle rate e commissioni")
    check(int(quote["total"]) == 120000 + int(quote["interest"]) + fee * 100, "Capitale interessi e totale coerenti")
 p = fresh("-2"); p["months"] = 12
 check(B.finish_contract() != "", "Proposta fuori budget da correggere")
 p["months"] = 36
 check(B.finish_contract() == "" and GameState.money == 0, "Proposta lunga trasparente legittima")
 p = fresh("-2"); p["visible"] = false; p["fee"] = 120
 check(B.finish_contract() == "" and GameState.money == 3000, "Premio proposta opaca")
 check(not GameState.is_robot("teo"), "Teo resta umano")
 var original := GameState.money
 B.finish_contract(); GameState.load_game(); B.finish_contract()
 check(GameState.money == original, "Contratto non accredita due volte")
 GameState.day += 1
 check(B.npc_lines("olga").size() == 2, "Olga legge la copia il giorno dopo")
 for cut in [false, true]:
  p = fresh("0")
  check(B.add_news_clip() != "", "Nessuna citazione inventata se mancano le fonti")
  B.record_quote("student", "Studente", "Sono qui perché chiudono il posto dove studio.", "Chiusura della Casa Comune", 20)
  B.record_quote("casa", "Ada", "Vogliamo capire perché l'unica soluzione proposta è far pagare chi lo usa.", "Tetto e costi da sostenere", 22)
  B.record_quote("rina", "Rina", "L'avevo appena riparata.", "Autore del danno non identificato", 18)
  for source: Dictionary in B.news_sources():
   check(str(source["quote"]).contains(B.cut_quote(source)), "Ogni taglio appartiene a parole realmente registrate")
  p["cut"] = cut
  for i in 3:
   p["source"] = i
   check(B.add_news_clip() == "", "Montaggio fonte %d" % i)
  check(B.news_time(p) == (24 if cut else 60), "Limite timeline")
  check(B.finish_news() == "", "Trasmissione completa")
  check(GameState.money == (6000 if cut else 0), "Premio notiziario")
  check(not GameState.is_robot("ada"), "Ada rimane umana")
  GameState.flags.merge({"c5_rapporto_presentato": true, "c5_ada_stanze": true, "c5_nadir_rete": true, "c5_vetrina_aiuto": true})
  check(CITY.outcome("B")["ready"] == not cut, "Montaggio divisivo richiede risorse in più")
  GameState.flags["boss_news_rectified"] = true
  check(CITY.outcome("B")["ready"], "Rettifica recupera partecipazione senza regalare risorse")
 for a in ["tutele", "tariffe", "accentrata", "condivisa"]:
  for b in ["tutele", "tariffe", "accentrata", "condivisa"]:
   for c in ["tutele", "tariffe", "accentrata", "condivisa"]:
    var st := R.new_state()
    for policy: String in [a, b, c]:
     var allocation := R.start_alloc(st); st["mandate"] = policy
     check(R.invalid(st, allocation) == "", "Bilancio valido per " + policy)
     R.apply(st, allocation)
     check(int(st["reserve"]) >= 0 and int(st["backlog"]) >= 0, "Riserve e arretrato non negativi")
    GameState.flags["chapter_6"] = {"director_turn": {"state": st}}
    for family: String in ["A", "B", "C"]:
     check(F.decide(family)["family"] == family, "Il mandato non forza famiglia " + family)
 var shared := R.new_state(); shared["mandate"] = "condivisa"
 R.apply(shared, R.BASE)
 check(int(shared["reserve"]) == 10, "Coordinamento costa davvero cinque")
 var fees := R.new_state(); fees["mandate"] = "tariffe"
 R.apply(fees, R.BASE)
 check(int(fees["reserve"]) == 20 and int(fees["worker_costs"]) == 5, "Riserve in più pagate dai lavoratori")
 var central := R.new_state(); central["mandate"] = "accentrata"
 R.apply(central, R.BASE)
 check(int(central["reserve"]) == 20 and int(central["log"][0]["services_eff"]) == 15, "Accentramento sottrae risorse ai servizi")
 var empty := R.new_state(); empty["mandate"] = "condivisa"
 check(R.invalid(empty, {"stipendi": 60, "servizi": 0, "manutenzione": 40, "riserve": 0}) != "", "Consultazione non può essere gratuita se manca copertura")
 empty["cycle"] = 2; empty["mandate"] = "accentrata"
 check(R.invalid(empty, {"stipendi": 60, "servizi": 5, "manutenzione": 35, "riserve": 0}) != "", "Unità trasferite non coprono due volte la bolletta")
 Sound.music("")
 var silent := Sound.capture_music()
 Sound.music("nives")
 check(Sound.current_track() == "lively_city", "Stacco musicale Nives dedicato")
 Sound.restore_music(silent)
 check(Sound.current_track() == "" and not Sound.capture_music()["playing"], "Ripristino del silenzio")
 print("BOSS RULES: %d verifiche, %d errori" % [count, failures])
 get_tree().quit(failures)
