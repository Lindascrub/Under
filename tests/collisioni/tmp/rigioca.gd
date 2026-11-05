extends Node
## Rigiocare, sgridata, battute per stelline (temporaneo).
const NPC := preload("res://scripts/npc.gd")
var cur: Node
var visti: Array[String] = []

func _process(_d: float) -> void:
	if Ui.busy:
		var t := str((Ui.get("_text") as RichTextLabel).text) if Ui.get("_text") is RichTextLabel else str(Ui.get("_text").text)
		if t not in visti: visti.append(t)
		if Engine.get_process_frames() % 4 == 0:
			var e := InputEventAction.new(); e.action = "confirm"; e.pressed = true; Input.parse_input_event(e)
			var u := InputEventAction.new(); u.action = "confirm"; u.pressed = false; Input.parse_input_event(u)

func _apri(cfg: Dictionary) -> void:
	GameState.minigame = cfg
	if is_instance_valid(get_tree().current_scene) and get_tree().current_scene != self: get_tree().current_scene.queue_free()
	await get_tree().process_frame
	cur = load(Router.MINIGAME).instantiate(); get_tree().root.add_child(cur); get_tree().current_scene = cur
	var n := 0
	while (str(cur.get("phase")) != "play" or Ui.busy) and n < 3000:
		await get_tree().process_frame; n += 1

func _fine() -> void:
	var n := 0
	while is_instance_valid(cur) and cur.is_inside_tree() and str(cur.get("phase")) != "done" and n < 3000:
		await get_tree().process_frame; n += 1
	n = 0
	while is_instance_valid(cur) and cur.is_inside_tree() and n < 3000:
		await get_tree().process_frame; n += 1
	n = 0
	while (Ui.busy or Ui.transitioning or n < 10) and n < 3000:
		await get_tree().process_frame; n += 1

func _cfg(id: String, rigioco: bool) -> Dictionary:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/npcs.json"))
	var c := NPC.minigame_cfg(id, str(d[id]["name"]), d[id]["help"], Router.FONDO, Vector2.ZERO)
	if rigioco:
		c["rigioco"] = true
		c["stelle_prima"] = int(GameState.flags.get("stelle_" + id, 0))
	return c

func _vede(pezzo: String) -> bool:
	for v in visti:
		if pezzo in v: return true
	return false

func _ready() -> void:
	GameState.save_path = "user://test_rigioca.json"
	GameState.new_game()
	var errori: Array[String] = []
	# 1. rigioco dopo 1 stellina: tutto giusto = 3 stelline, paga 10 - 3 = 7
	GameState.helped_ids.append("bulbo"); GameState.flags["stelle_bulbo"] = 1
	await _apri(_cfg("bulbo", true))
	var soldi := GameState.money
	for r in int(cur.get("cfg").get("rounds", 2)):
		for w in 4:
			cur.set("wire_pick", w); cur.set("wire_sel", (cur.get("wire_right") as Array).find(w)); cur.call("_wire_connect")
			for i in 4: await get_tree().process_frame
	await _fine()
	if GameState.money - soldi != 7: errori.append("rigioco meglio: soldi %d invece di 7" % (GameState.money - soldi))
	if not _vede("non una banca"): errori.append("manca la battuta 'meglio'")
	if GameState.flags.get("stelle_bulbo", 0) != 3: errori.append("record non 3")
	# 2. rigioco con 3 stelline già: paga 0, battuta 'uguale'
	visti.clear()
	await _apri(_cfg("bulbo", true))
	soldi = GameState.money
	for r in int(cur.get("cfg").get("rounds", 2)):
		for w in 4:
			cur.set("wire_pick", w); cur.set("wire_sel", (cur.get("wire_right") as Array).find(w)); cur.call("_wire_connect")
			for i in 4: await get_tree().process_frame
	await _fine()
	if GameState.money != soldi: errori.append("rigioco uguale: ha pagato %d" % (GameState.money - soldi))
	if not _vede("li hai già presi"): errori.append("manca la battuta 'uguale'")
	# 3. Bulbo: perde 3 volte di fila (prima volta + 2 rigiochi): 5 euro solo la prima, poi la sgridata
	for k in 3:
		visti.clear()
		await _apri(_cfg("mina", k > 0))
		soldi = GameState.money
		cur.call("_finish", false)
		await _fine()
		var preso := GameState.money - soldi
		if preso != (5 if k == 0 else 0): errori.append("sconfitta %d: soldi %d" % [k, preso])
		if k < 2 and not _vede("come ogni giorno"): errori.append("sconfitta %d: manca la battuta" % k)
		if k == 2 and not _vede("mettici più impegno"): errori.append("manca la sgridata")
		if k == 2 and _vede("apprezza che ci hai provato"): errori.append("sgridata + 'apprezza' insieme")
	if GameState.flags.get("persi_mina", -1) != 0: errori.append("dopo la sgridata il conto non riparte")
	# 4. una vittoria con 2 stelline (prima volta): battuta delle 2 stelline
	GameState.new_game(); visti.clear()
	await _apri(_cfg("bulbo", false))
	cur.set("wire_pick", 0); cur.set("wire_sel", (cur.get("wire_right") as Array).find(1)); cur.call("_wire_connect")
	for r in int(cur.get("cfg").get("rounds", 2)):
		for w in 4:
			cur.set("wire_pick", w); cur.set("wire_sel", (cur.get("wire_right") as Array).find(w)); cur.call("_wire_connect")
			for i in 4: await get_tree().process_frame
	await _fine()
	if not _vede("promettente"): errori.append("manca la battuta delle 2 stelline")
	# 5. riparlare con Mina nel Fondo: chiede di rifarlo, OK = parte il minigioco da rigiocare
	GameState.helped_ids.append("bulbo"); GameState.flags["thanked_bulbo"] = true; GameState.flags["met_bulbo"] = true
	GameState.flags["stelle_bulbo"] = 2; visti.clear()
	if is_instance_valid(get_tree().current_scene) and get_tree().current_scene != self: get_tree().current_scene.queue_free()
	await get_tree().process_frame
	var fondo: Node = load(Router.FONDO).instantiate(); get_tree().root.add_child(fondo); get_tree().current_scene = fondo
	for i in 20: await get_tree().process_frame
	var mina: Node = null
	for n2 in get_tree().get_nodes_in_group("npc"):
		if str(n2.get("id")) == "bulbo": mina = n2
	if mina == null:
		for n2 in fondo.find_children("*", "", true, false):
			if n2.get("id") != null and str(n2.get("id")) == "bulbo": mina = n2
	if mina == null: errori.append("Mina non trovata nel Fondo")
	else:
		mina.call("interact")
		var n := 0
		while n < 600 and not (GameState.minigame as Dictionary).get("rigioco", false):
			await get_tree().process_frame; n += 1
		if not _vede("li stacco"): errori.append("Mina non chiede di rifarlo")
		if not (GameState.minigame as Dictionary).get("rigioco", false): errori.append("OK non fa partire il rigioco")
	print("RIGIOCA: errori ", errori)
	get_tree().quit(0)
