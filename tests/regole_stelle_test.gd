extends "res://tests/smoke_test.gd"

var checks := 0
var choices := 0
var said: Array[String] = []
var accept_help := false

func check(ok: bool, message: String) -> void:
	checks += 1
	_check(ok, message)

func _process(_delta: float) -> void:
	_frame += 1
	if Ui.busy:
		var label: Label = Ui.get("_label")
		if label.text not in said: said.append(label.text)
		if _frame % 3 == 0:
			if Ui.get("_mode") == "choose":
				Ui.set("_sel", 0 if accept_help else (Ui.get("_options") as Array).size() - 1)
			_tap("confirm")

func _run() -> void:
	GameState.save_path = "user://test_regole_stelle_nov9.json"
	Ui.get("_choice_box").visibility_changed.connect(func():
		if Ui.get("_choice_box").visible: choices += 1)
	var expected := {"-5":["bulbo","mina"],"-4":["tilde","ercole"],"-3":["leda","amir"],"-2":["olga","teo"],"0":["ada","nadir"]}
	for floor_id: String in expected:
		GameState.new_game()
		var ids: Array = GameState.floor_minigames(floor_id)
		check(ids == expected[floor_id], floor_id + ": elenco esatto dei giochi, Rina e Fermo esclusi")
		GameState.helped_ids.assign(ids)
		check(not GameState.floor_minigames_mastered(floor_id), floor_id + ": aiutare senza stelle non basta")
		GameState.flags["stelle_" + ids[0]] = 3
		GameState.flags["stelle_" + ids[1]] = 2
		check(not GameState.floor_minigames_mastered(floor_id), floor_id + ": 3 e 2 non bastano")
		GameState.flags["stelle_" + ids[1]] = 3.0
		check(GameState.floor_minigames_mastered(floor_id), floor_id + ": tutti a 3, anche record caricati da JSON")
		if floor_id in ["-3","-2","0"]:
			var script: Script = load({"-3":"res://chapters/c3/mercato_c3.gd","-2":"res://chapters/c4/banca_c4.gd","0":"res://chapters/c5/citta_c5.gd"}[floor_id])
			var room: Node = script.new()
			check(room.gift_allowed(), floor_id + ": Nives usa la regola comune senza requisiti narrativi nascosti")
			GameState.flags["stelle_" + ids[1]] = 2
			check(not room.gift_allowed(), floor_id + ": Nives non regala il badge con 2 stelle")
			GameState.flags["stelle_" + ids[1]] = 3
			room.free()
		GameState.robots.append(ids[0])
		check(not GameState.floor_minigames_mastered(floor_id), floor_id + ": aiutare e poi sfruttare non conserva il regalo")
	check(not GameState.floor_minigames_mastered("cima"), "nessun regalo dove non ci sono minigiochi")
	for tel in [false,true]:
		TouchControls.enabled = tel
		for floor_id: String in expected:
			for id: String in expected[floor_id]:
				GameState.new_game()
				GameState.flags["stelle_" + id] = 3
				GameState.helped_ids.append(id)
				var npc: Npc = load("res://scripts/npc.tscn").instantiate()
				npc.id = id
				add_child(npc)
				var before := choices
				var time_before := GameState.minutes
				var money_before := GameState.money
				said.clear()
				check(await npc._offer_replay(npc.display_name()), id + ": dialogo conclusivo gestito")
				check(choices == before and not said.is_empty(), id + ": tre stelle danno una battuta, nessuna scelta di rigiocare")
				await Npc.offer_minigame(id,npc.display_name(),self)
				check(choices == before and GameState.minutes == time_before and GameState.money == money_before, id + ": percorso diretto bloccato senza costo")
				var old_cfg := GameState.minigame.duplicate(true)
				Router.minigame({"id":id,"stelle":true})
				check(GameState.minigame == old_cfg and not Ui.transitioning, id + ": anche il router rifiuta il rigioco")
				GameState.flags["stelle_" + id] = 2
				await npc._offer_replay(npc.display_name())
				check(choices > before and GameState.minutes == time_before, id + ": sotto tre stelle si può riprovare, rifiuto gratuito")
				npc.queue_free()
				await get_tree().process_frame
	# Replays actually launched from the shared offer must not duplicate help, money or items.
	for floor_id: String in expected:
		for id: String in expected[floor_id]:
			GameState.new_game()
			GameState.floor_id = floor_id
			GameState.flags["stelle_" + id] = 2
			GameState.helped_ids.append(id)
			GameState.helped = 1
			if id == "leda": GameState.give_item("Biscotti di Leda")
			var items_before := GameState.items.duplicate()
			var money0 := GameState.money
			var minutes0 := GameState.minutes
			var offer_room := Node2D.new()
			offer_room.scene_file_path = Router.MENU
			add_child(offer_room)
			accept_help = true
			await Npc.offer_minigame(id,GameState.npc_data(id).name,offer_room)
			accept_help = false
			await _wait_scene(Router.MINIGAME)
			await _idle()
			var game := get_tree().current_scene
			check(bool(game.cfg.get("rigioco",false)) and int(game.cfg.get("stelle_prima",0)) == 2, id + ": rigioco avviato con record reale")
			game.misses = 1
			var response: Node = game.get_node("Risposta")
			response.fermo_vittoria = 0
			response.durata_stelle = .01
			game._finish(true)
			await _wait_scene(Router.MENU)
			await _idle()
			check(GameState.helped == 1 and GameState.items == items_before and GameState.money == money0, id + ": rigioco uguale non duplica ricompense o aiuti")
			check(GameState.minutes == minutes0 + GameState.COST_HELP_TIME, id + ": rigioco costa una sola ora")
			offer_room.queue_free()
	GameState.new_game()
	TouchControls.enabled = false
	GameState.flags["c1_arrivo"] = true
	GameState.flags["fermo_called"] = true
	GameState.flags["fermo_talked"] = true
	GameState.helped_ids.assign(GameState.floor_people("-5"))
	var room := await _go(Router.FONDO)
	check(not GameState.has_badge("-4"), "Fondo reale: nessun regalo per il solo aiuto")
	GameState.flags["stelle_bulbo"] = 3
	GameState.flags["stelle_mina"] = 2
	await room._floor_gift()
	check(not GameState.has_badge("-4"), "Fondo reale: con 3 e 2 stelle niente regalo")
	GameState.flags["stelle_mina"] = 3
	var money_before := GameState.money
	var debt_before := GameState.debt
	await room._floor_gift()
	check(GameState.has_badge("-4") and GameState.money == money_before and GameState.debt == debt_before, "regalo effettivo dopo la terza stella, gratis")
	await room._floor_gift()
	check(GameState.badges.count("-4") == 1, "regalo mai duplicato")
	said.clear()
	var before := choices
	await room._badge_machine()
	check(str(said).contains("Sei tornato davvero"), "Nives mantiene la promessa di salutare dopo il regalo")
	var first := said.duplicate()
	said.clear()
	await room._badge_machine()
	check(not said.is_empty() and said != first and choices == before, "secondo saluto diverso, nessun acquisto richiesto")
	print("REGOLE STELLE NOV9: %d controlli, errori %s" % [checks,_failures])
	get_tree().quit(0 if _failures.is_empty() else 1)
