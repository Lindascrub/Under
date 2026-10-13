class_name Quests
extends RefCounted
## Piccole missioni facoltative (data/quests.json) che "rubano" tempo:
##   find      -> trova qualcosa nascosto in un posto diverso ogni giorno e riportalo
##   deliver   -> porta qualcosa a un'altra persona
##   minigame  -> fai subito un favore (minigioco) che costa ore
## Stato in GameState.quests: id -> "active" | "found" | "done" | "failed".
## Se a fine giornata una missione non è finita, fallisce: il giorno dopo chi te l'ha chiesta te lo dice.

static var _data: Array = []


static func all() -> Array:
	if _data.is_empty() and FileAccess.file_exists("res://data/quests.json"):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/quests.json"))
		if parsed is Array:
			_data = parsed
	return _data


static func get_quest(id: String) -> Dictionary:
	for q: Dictionary in all():
		if q["id"] == id:
			return q
	return {}


static func state(id: String) -> String:
	return str(GameState.quests.get(id, ""))


## Elenco delle missioni in corso, per il menu di stato.
static func active_titles() -> Array:
	var out: Array = []
	for q: Dictionary in all():
		var s := state(q["id"])
		if s == "active" or s == "found":
			out.append(str(q["title"]))
	return out


## A fine giornata: ciò che non è finito fallisce.
static func end_day() -> void:
	for q: Dictionary in all():
		var s := state(q["id"])
		if s == "active" or s == "found":
			GameState.quests[q["id"]] = "failed"
			GameState.flags["quest_news_" + str(q["id"])] = "fail"


## Dove si trova oggi l'oggetto di una missione "find" (o {} se non serve).
static func find_spot(q: Dictionary) -> Dictionary:
	var spots: Array = q.get("spots", [])
	if spots.is_empty():
		return {}
	return spots[(GameState.day - 1) % spots.size()]


## Oggetti da trovare che oggi stanno in questa stanza: [{quest, cell}].
static func items_in(room_key: String) -> Array:
	var out: Array = []
	for q: Dictionary in all():
		if q.get("type") == "find" and state(q["id"]) == "active":
			var spot := find_spot(q)
			if spot.get("room", "") == room_key:
				out.append({"quest": q, "cell": Vector2i(int(spot["cell"][0]), int(spot["cell"][1]))})
	return out


## Gestisce le missioni quando parli con una persona. Restituisce true se ha "usato" la conversazione.
static func handle_npc(npc: Npc) -> bool:
	var id := npc.id
	var who := npc.display_name()
	# Notizie dal giorno prima (missione fallita o finita bene)
	for q: Dictionary in all():
		var key := "quest_news_" + str(q["id"])
		if q["giver"] == id and GameState.flags.has(key):
			var news := str(GameState.flags[key])
			GameState.flags.erase(key)
			await Ui.say(q.get("fail" if news == "fail" else "done_next_day", []), who)
			return true
	for q: Dictionary in all():
		var qid := str(q["id"])
		var s := state(qid)
		# Consegna: sei dalla persona giusta col pacco
		if q.get("type") == "deliver" and s == "active" and q.get("to") == id:
			GameState.quests[qid] = "found"
			Sound.sfx("select")
			await Ui.say(q.get("delivered", ["Grazie!"]), who)
			return true
		if q["giver"] != id:
			continue
		# Missione finita: riporti l'oggetto o torni dopo la consegna
		if s == "found":
			await _complete(q, who)
			return true
		if s == "active":
			await Ui.say(q.get("reminder", ["Allora?"]), who)
			return true
		# Nuova missione
		if s == "" and _today_in(q.get("days", [])):
			await Ui.say(q.get("offer", []), who)
			var c: int = await Ui.choose(str(q.get("ask", "Mi aiuti?")), ["Va bene", "Non posso"], who)
			if c != 0:
				GameState.quests[qid] = "declined"
				return true
			await Ui.say(q.get("accepted", []), who)
			if q.get("type") == "minigame":
				await _start_minigame(q, npc)
			else:
				GameState.quests[qid] = "active"
				Sound.sfx("select")
				await Ui.say(["* (Nuova missione: %s. La trovi nel menu con C.)" % q["title"]])
			return true
	return false


## I numeri letti dal JSON sono decimali (3.0): li confronto come interi.
static func _today_in(days: Array) -> bool:
	for d: Variant in days:
		if int(d) == GameState.day:
			return true
	return false


static func _complete(q: Dictionary, who: String) -> void:
	GameState.quests[q["id"]] = "done"
	var reward := int(q.get("reward", 0))
	GameState.money += reward
	GameState.helped += 1
	GameState.changed.emit()
	Sound.sfx("spare")
	var lines: Array = q.get("thanks", ["Grazie!"]).duplicate()
	if reward > 0:
		lines.append("* %s ti dà %s." % [who, GameState.euros(reward)])
	await Ui.say(lines, who)


static func _start_minigame(q: Dictionary, npc: Npc) -> void:
	var cost := int(q.get("cost", 120))
	if not GameState.has_time(cost):
		await Ui.say(["* Non ti restano abbastanza ore oggi."])
		return
	GameState.quests[q["id"]] = "done"
	GameState.spend(cost - GameState.COST_HELP_TIME)
	var cfg: Dictionary = (q["minigame"] as Dictionary).duplicate(true)
	cfg["id"] = npc.id
	cfg["quest"] = q["id"]
	cfg["lose"] = q.get("fail_now", ["Non fa niente. Grazie di averci provato."])
	cfg["name"] = npc.display_name()
	cfg["win"] = q.get("thanks", ["Grazie!"])
	cfg["reward"] = int(q.get("reward", 0))
	cfg["return"] = npc.get_tree().current_scene.scene_file_path
	cfg["return_pos"] = (npc.get_tree().get_first_node_in_group("player") as Node2D).global_position
	Router.minigame(cfg)


## Quando trovi l'oggetto nascosto.
static func pick_up(q: Dictionary) -> void:
	GameState.quests[q["id"]] = "found"
	Sound.sfx("select")
	var lines: Array = q.get("found", []).duplicate()
	lines.append("* (Riportalo a %s.)" % GameState.npc_data(str(q["giver"])).get("name", "chi te l'ha chiesto"))
	await Ui.say(lines)
