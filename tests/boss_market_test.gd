extends Node
const B := preload("res://scripts/boss_missions.gd")
var failures := 0
var count := 0
func check(v: bool, label: String) -> void:
 count += 1
 if not v: failures += 1; push_error(label)
func _ready() -> void:
 GameState.save_path = "user://test_boss_market.json"
 GameState.new_game()
 GameState.floor_id = "-3"
 var s := B.state("-3")
 s.merge({"status": "active", "return": Router.MERCATO, "return_pos": [200, 200]}, true)
 var p := B.progress("-3")
 check(int(B.market_preview(p)["base"]) == 1800, "Prezzo prima dell'aumento")
 p["rate"] = 50; p["reference"] = 1; p["visible"] = false
 check(bool(B.market_preview(p)["hidden"]), "Riferimento futuro occultato")
 check(int(B.market_preview(p)["each"]) == 1250, "Sconto calcolato sul riferimento futuro reale")
 check(B.submit_market() == "", "Prima etichetta")
 p["rate"] = 10; p["units"] = 2; p["visible"] = false
 check(int(B.market_preview(p)["basket"]) == 4320, "Paniere di due pezzi")
 check(B.submit_market() == "", "Seconda etichetta")
 p["rate"] = 10; p["visible"] = true
 check(B.submit_market() == "", "Terza etichetta trasparente")
 var before := GameState.money
 B.finish_market()
 check(GameState.money == before + 1000, "Premio proporzionato a due etichette opache")
 check(not GameState.is_robot("amir"), "Amir rimane umano")
 check(GameState.flags.get("c3_capo_chiuso", false), "Sblocca l'aggiornamento prezzi")
 B.finish_market()
 check(GameState.money == before + 1000, "Riaprire non duplica il premio")
 GameState.load_game()
 B.finish_market()
 check(GameState.money == before + 1000, "Reload non duplica il premio")
 check(FileAccess.file_exists(GameState.save_path + ".bak"), "Backup conservato")
 GameState.new_game(); GameState.floor_id = "-3"
 s = B.state("-3"); s["status"] = "active"; s["return"] = Router.MERCATO
 p = B.progress("-3")
 for i in 3:
  check(B.submit_market() == "", "Alternativa trasparente giocata %d" % i)
 B.finish_market()
 check(GameState.money == 0 and not GameState.is_robot("amir"), "Alternativa senza bonus e senza robot")
 # Progress persists halfway; the actual screen exposes the four independent controls.
 GameState.new_game(); GameState.floor_id = "-3"
 s = B.state("-3"); s["status"] = "active"; s["return"] = Router.MERCATO
 p = B.progress("-3"); p["units"] = 2
 B.checkpoint("-3"); GameState.load_game()
 check(int(B.progress("-3")["units"]) == 2, "Ripresa a metà")
 GameState.minigame = {"boss_floor": "-3"}
 var ui: Control = load(B.SCENE).instantiate()
 add_child(ui)
 await get_tree().process_frame
 await get_tree().process_frame
 ui._act("rate")
 check(int(ui.p["rate"]) == 10, "Controllo percentuale")
 ui._act("visible")
 check(not ui.p["visible"], "Controllo condizioni")
 ui.queue_free()
 GameState.flags = {"c3_capo": true}; GameState.money = 800; GameState.robots.assign(["amir"])
 B.migrate(true)
 check(not B.uses("-3") and B.uses("-2"), "Migrazione conserva piano vecchio e abilita successivo")
 check(GameState.money == 800 and GameState.is_robot("amir"), "Nessuna riscrittura di soldi e robot")
 print("BOSS MARKET: %d verifiche, %d errori" % [count, failures])
 get_tree().quit(failures)

