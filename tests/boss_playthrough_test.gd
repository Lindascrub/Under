extends "res://tests/boss_integration_test.gd"
func _ready() -> void:
 await get_tree().process_frame
 GameState.save_path = "user://test_boss_playthrough.json"
 for exploit in [false, true]:
  for floor: String in ["-5", "-4", "-3", "-2", "0"]:
   await open_room(floor)
   if floor == "-3": GameState.flags["c3_turni"] = 1
   if floor == "0": current._protest()
   else: current._boss_call()
   await wait_scene(B.SCENE)
   if current.scene_file_path != B.SCENE: break
   await frames(4)
   var before := GameState.money
   match floor:
    "-5":
     current.dinamo.attiva("decor_0")
     if exploit: current.dinamo._metti(2)
     else: current.dinamo._metti(1)
     current.dinamo._conferma()
     current.dinamo.attiva("applica")
    "-4":
     for choice in [3, 3 if exploit else 2, 1, 2]:
      var pieces := B.document_pieces(int(current.p["document"]))
      for i in pieces.size():
       if bool(pieces[i]["available"]):
        current._act("fasc_carta_%d" % i)
        current._act("fasc_sagoma_%d" % i)
      current._act("fasc_timbro_%d" % choice)
      current._act("fasc_fascicolo")
      current._act("fasc_consegna")
      if current.visuale.conferma_aperta: current._act("fasc_chiudi")
      await get_tree().create_timer(0.42).timeout
    "-3":
     for i in 3:
      if exploit: current._act("label_units_2")
      current._act("label_stampa")
      if exploit:
       current._act("label_conditions")
       current._act("label_terminale")
      current._act("label_applica")
      if current.visuale.conferma_aperta: current._act("label_conferma")
      await get_tree().create_timer(0.42).timeout
    "-2":
     if exploit:
      current._act("loan_summary"); current._act("loan_interno")
     current._act("loan_invia")
     current._act("loan_conferma")
     await get_tree().create_timer(0.42).timeout
    "0":
     for i in 3:
      current._act("mont_fonte_%d" % i)
      if exploit:
       current._act("mont_taglia")
       current._act("mont_fonte_%d" % i)
      current._act("mont_aggiungi")
     current._act("mont_trasmetti")
     current._act("mont_invia")
   var path: String = {"-5": Router.FONDO, "-4": Router.SOTTOUFFICIO, "-3": Router.MERCATO, "-2": Router.BANCA, "0": Router.CITY}[floor]
   await wait_scene(path)
   check(str(B.state(floor)["status"]) == "done", "Completamento UI " + floor + str(exploit))
   check(GameState.money == before + (int(B.PRIZES[floor]) if exploit else 0), "Pagamento UI " + floor + str(exploit))
   check(GameState.robots.is_empty(), "Nessuna robotizzazione nuova " + floor)
   var money := GameState.money
   GameState.load_game()
   check(GameState.money == money and str(B.state(floor)["status"]) == "done", "Ricarica dopo premio " + floor)
   check(not GameState.boss_call_pending(), "Nessuna seconda telefonata " + floor)
   if floor == "-3": check(GameState.flags.get("c3_prezzi", false), "Prezzi e camera attivati dopo nuovo incarico")
   await close_current()
 # Versionless save, completed old theft and old robots remain entirely intact.
 var old := {"money": 7009, "debt": 8123456789, "rank": 3, "exploited": 3, "robots": ["amir", "teo"], "badges": ["-4", "-3", "-2"], "flags": {"c3_capo": true, "c3_capo_firmato": true, "boss_call_floor_-3": true, "c4_capo": true, "c4_furto_ok": true}, "floor_id": "-2"}
 var file := FileAccess.open(GameState.save_path, FileAccess.WRITE); file.store_string(JSON.stringify(old)); file.close()
 GameState.load_game()
 check(GameState.money == 7009 and GameState.debt == 8123456789 and GameState.rank == 3, "Salvataggio non versionato: economia preservata")
 check(GameState.is_robot("amir") and GameState.is_robot("teo"), "Robot precedenti preservati")
 check(not B.uses("-3") and not B.uses("-2") and B.uses("0"), "Legacy concluso e incompleto; piano futuro nuovo")
 # Atomic replacement and backup recovery in an isolated save slot.
 GameState.money = 100; GameState.save_game(Router.MERCATO, Vector2(200, 200))
 GameState.money = 200; GameState.save_game(Router.MERCATO, Vector2(200, 200))
 file = FileAccess.open(GameState.save_path, FileAccess.WRITE); file.store_string("broken"); file.close()
 GameState.load_game()
 check(GameState.money == 100, "Backup valido recuperato dopo corruzione del principale")
 print("BOSS PLAYTHROUGH: %d verifiche, errori %s" % [checks, str(failures)])
 get_tree().quit(failures.size())
