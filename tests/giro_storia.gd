extends "res://tests/smoke_test.gd"
## Il giro della storia, SOLO TESTO (niente video): gioca dal Fondo al finale e scrive in un file
## ogni frase, ogni scelta mostrata e quella fatta, i cambi di stanza e cosa il giro ha forzato a mano.
## Serve a leggere la storia come la vede chi gioca, e a distinguere i problemi della storia da quelli del giro.
##   Godot --headless --path . --fixed-fps 30 --disable-vsync res://tests/giro_storia.tscn -- \
##       --strada=gentile|cattiva|solo --finale=A|B|C --turno=buono|conserva|niente --contesta=si|no --log=C:/percorso/file.txt
## gentile: parla con tutti e li aiuta, rifiuta il Capo.  cattiva: accetta gli incarichi del Capo (scorciatoie).
## solo: non parla con nessuno dei personaggi dei piani (solo oggetti, sportelli e Cima).

const B := preload("res://scripts/boss_missions.gd")
const FIN := preload("res://chapters/c6/finali.gd")
const PIANI := [
	[Router.FONDO, "-4"], [Router.SOTTOUFFICIO, "-3"], [Router.MERCATO, "-2"], [Router.BANCA, "0"], [Router.CITY, "cima"],
]
## Le azioni da non fare da soli: lavori, sportelli, stelline, sedie e uscite si fanno a parte.
const SALTA_METODI := ["_badge_machine", "_save_here", "use_save_point", "_station", "_scendi", "_pity_offer"]

var strada := "gentile"
var finale := "C"
var turno := "buono"
var contesta := "si"
var _log: FileAccess
var _ultimo := ""
var _visti := {}
var _scena := ""
var _forzati: Array[String] = []


func _ready() -> void:
	GameState.save_path = "user://giro_storia.json"
	var percorso := "user://giro_storia.txt"
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		if kv.size() < 2: continue
		match kv[0]:
			"strada": strada = kv[1]
			"finale": finale = kv[1]
			"turno": turno = kv[1]
			"contesta": contesta = kv[1]
			"log": percorso = kv[1]
	# ogni giro ha il suo salvataggio e la sua memoria di Nives, vuota: i giri non si ricordano fra loro
	GameState.save_path = "user://giro_storia_%s.json" % percorso.get_file().get_basename()
	if FileAccess.file_exists(MemoriaNives.path()):
		DirAccess.remove_absolute(MemoriaNives.path())
	_log = FileAccess.open(percorso, FileAccess.WRITE)
	_scrivi("# GIRO STORIA  strada=%s finale=%s turno=%s contesta=%s" % [strada, finale, turno, contesta])
	var placeholder := Node.new()
	get_tree().root.add_child.call_deferred(placeholder)
	await get_tree().process_frame
	get_tree().current_scene = placeholder
	await _run()


func _scrivi(t: String) -> void:
	if _log:
		_log.store_line(t)
		_log.flush()


## [GIRO]: quello che non ha fatto il gioco ma il giro automatico (da non scambiare per storia).
func _forza(t: String) -> void:
	_forzati.append(t)
	_scrivi("    [GIRO] " + t)


func _process(_delta: float) -> void:
	_frame += 1
	GameState.energy = GameState.MAX_ENERGY
	var sp := _scene_path()
	if sp != _scena:
		_scena = sp
		_scrivi("\n== %s  (giorno %d, debito %s, soldi %s)" % [sp.get_file().get_basename(), GameState.day, GameState.debt, GameState.money])
	var scene := get_tree().current_scene
	if scene == null:
		return
	if sp == Router.MINIGAME and not Ui.transitioning and scene.get("phase") == "play" and not Ui.busy:
		_scrivi("    [minigioco %s: vinto dal giro]" % str(GameState.minigame.get("name", GameState.minigame.get("type", "?"))))
		var v: Node = scene.get("visivo")
		if v != null:
			v.errori = 0
			v.chiudi(true)
		else:
			scene.set("misses", 0)
			scene.call("_finish", true, false)
		return
	if sp == Router.WORK and not Ui.transitioning and scene.get("phase") == "play" and not Ui.busy:
		_scrivi("    [turno di lavoro: finito dal giro]")
		scene.set("score", scene.get("target"))
		scene.set("time_left", 0.0)
		return
	if sp == Router.DIREZIONE and not Ui.transitioning and not Ui.busy and _frame % 3 == 0:
		_scrivi("    [TURNO di Direzione, fase %s: piano %s]" % [scene.get("phase"), director_plan])
		_drive_direction(scene)
		return
	if sp == Router.FINALE:
		scene.set("fast", true)
	if not Ui.busy or _frame % 2 != 0:
		return
	var mode := str(Ui.get("_mode"))
	if mode == "say":
		if bool(Ui.get("_typing")):
			_tap("confirm")   # salta la scrittura lettera per lettera
			return
		var lbl: Label = Ui.get("_label")
		var nome: Label = Ui.get("_name")
		var box: Control = Ui.get("_choice_box")
		var t := ""
		if box.visible and (Ui.get("_options") as Array).size() == 1:
			t = "  TU> " + str((Ui.get("_options") as Array)[0])
		elif lbl == Ui.get("_narr"):
			t = "  ~~ " + lbl.text
		else:
			t = "  " + ((nome.text + ": ") if nome.visible and nome.text != "" else "") + lbl.text
		_registra(t)
		_tap("confirm")
	elif mode == "choose":
		var opts: Array = Ui.get("_options")
		var prompt := str((Ui.get("_text") as Label).text)
		var i := _scelta(prompt, opts)
		Ui.set("_sel", i)
		var righe: Array = []
		for k in opts.size():
			righe.append(("[x] " if k == i else "[ ] ") + GameState.fmt(str(opts[k])))
		_registra("  ?? " + prompt.replace("\n", " / ") + "\n      " + "\n      ".join(righe))
		_tap("confirm")


func _registra(t: String) -> void:
	if t == _ultimo:
		return
	_ultimo = t
	_scrivi(t)


## Quale opzione scegliere: regole per strada e finale, poi la strada gentile, e i menu ripetuti si chiudono.
func _scelta(prompt: String, opts: Array) -> int:
	if not choose_queue.is_empty():
		return mini(int(choose_queue.pop_front()), opts.size() - 1)
	var p := prompt.to_lower()
	var low: Array = opts.map(func(o) -> String: return GameState.fmt(str(o)).to_lower())
	var trova := func(parole: Array) -> int:
		for k in low.size():
			for w: String in parole:
				if str(low[k]).contains(w):
					return k
		return -1
	# il finale
	if p.contains("cosa vuoi fare della torre"):
		return {"A": 0, "B": 1, "C": 2}.get(finale, 2)
	if p.contains("confermi? dopo non si torna"):
		return 0
	if p.contains("chi si occupa di"):
		return 0 if strada != "solo" else opts.size() - 1
	if p.contains("attribuzione globale"):
		var k: int = trova.call(["accett", "firm", "sì"])
		var r: int = trova.call(["rifiut", "no"])
		return (k if strada == "cattiva" else r) if (k >= 0 and r >= 0) else 0
	if p.contains("la tua registrazione"):
		return 0 if contesta == "si" else 1
	if p.contains("anche senza seguire la scorciatoia del capo") or low.has("apri il lavoro"):
		return 0 if strada == "cattiva" else 1
	if p.contains("iniziare il turno") or p.contains("comincia") and low.has("comincia."):
		return 0
	if p.contains("comprare il badge"):
		return 0
	# rifare un aiuto già perfetto: no, si va avanti
	if trova.call(["rifallo", "rigioca"]) >= 0:
		var k: int = trova.call(["non ora", "no"])
		return k if k >= 0 else opts.size() - 1
	if p.contains("cosa sostieni"):
		var k: int = trova.call(["comunitaria"] if strada != "solo" else ["non prendo", "mi astengo"])
		if strada == "cattiva": k = 0
		return k if k >= 0 else 0
	if p.contains("dove mandi la tua richiesta"):
		var k: int = trova.call(["direzione"])
		return k if k >= 0 and strada != "solo" else 0
	if p.contains("rapporto dei bilanci è nell'archivio"):
		var k: int = trova.call(["prima vado"])
		return k if k >= 0 and strada != "solo" else 0
	if strada != "solo":
		var k: int = trova.call(["proponi ordini condivisi", "condivis", "hai bisogno di aiuto", "posso fare qualcosa",
			"ti aiuto", "ti do una mano", "dai una mano", "prepariamo", "aiuta teo", "potresti organizzare"])
		if k >= 0 and int(_visti.get(prompt + "|" + ",".join(opts), 0)) < 2:
			_visti[prompt + "|" + ",".join(opts)] = int(_visti.get(prompt + "|" + ",".join(opts), 0)) + 1
			return k
	# menu ripetuti: alla terza volta si esce (di solito l'ultima voce è "chiudi" / "indietro")
	var firma := prompt + "|" + ",".join(opts)
	_visti[firma] = int(_visti.get(firma, 0)) + 1
	if int(_visti[firma]) >= 3:
		return opts.size() - 1
	var cattive := ["nascond", "firma", "accett", "sfrutt", "ruba", "prendi i soldi", "sì, capo", "vend", "prenditi il merito"]
	if strada == "cattiva":
		var k: int = trova.call(cattive)
		if k >= 0:
			return k
		return 0
	# gentile / solo: la prima voce che non è una scorciatoia
	for k in low.size():
		var ok := true
		for w: String in cattive:
			if str(low[k]).contains(w):
				ok = false
		if ok and str(low[k]) != "admin":
			# se c'è un modo di andare per gradi (visita successiva), la menu ripetuta lo trova col contatore
			return k
	return 0


## Aspetta che il gioco sia di nuovo in una stanza, fermo, senza dialoghi. Gli incarichi del Capo li gioca qui.
func _calma(max_frames := 20000) -> void:
	var fermo := 0
	var n := 0
	while fermo < 120 and n < max_frames:
		await get_tree().process_frame
		n += 1
		if _scene_path() == B.SCENE and not Ui.transitioning and not Ui.busy:
			await _incarico()
			fermo = 0
			continue
		var ok := _scene_path() in Router.WORLD and not Ui.busy and not Ui.transitioning and not Ui.cutscene
		fermo = fermo + 1 if ok else 0
	if n >= max_frames:
		_scrivi("    [GIRO BLOCCATO in %s busy=%s modo=%s trans=%s cut=%s]" % [_scene_path(), Ui.busy, Ui.get("_mode"), Ui.transitioning, Ui.cutscene])
		_fail("bloccato in " + _scene_path())


## Un incarico del Capo aperto: lo si gioca con le stesse mosse di tests/boss_playthrough_test.gd.
func _incarico() -> void:
	var cur := get_tree().current_scene
	var floor := str(GameState.minigame.get("boss_floor", GameState.floor_id))
	var sfrutta := strada == "cattiva"
	_scrivi("    [incarico del Capo %s giocato dal giro, %s]" % [floor, "con la scorciatoia" if sfrutta else "onesto"])
	await get_tree().create_timer(0.2).timeout
	match floor:
		"-5":
			cur.dinamo.attiva("decor_0")
			cur.dinamo._metti(2 if sfrutta else 1)
			cur.dinamo._conferma()
			cur.dinamo.attiva("applica")
		"-4":
			for choice in [3, 3 if sfrutta else 2, 1, 2]:
				var pieces := B.document_pieces(int(cur.p["document"]))
				for i in pieces.size():
					if bool(pieces[i]["available"]):
						cur._act("fasc_carta_%d" % i)
						cur._act("fasc_sagoma_%d" % i)
				cur._act("fasc_timbro_%d" % choice)
				cur._act("fasc_fascicolo")
				cur._act("fasc_consegna")
				if cur.visuale.conferma_aperta: cur._act("fasc_chiudi")
				await get_tree().create_timer(0.42).timeout
		"-3":
			for i in 3:
				if sfrutta: cur._act("label_units_2")
				cur._act("label_stampa")
				if sfrutta:
					cur._act("label_conditions")
					cur._act("label_terminale")
				cur._act("label_applica")
				if cur.visuale.conferma_aperta: cur._act("label_conferma")
				await get_tree().create_timer(0.42).timeout
		"-2":
			if sfrutta:
				cur._act("loan_summary"); cur._act("loan_interno")
			cur._act("loan_invia")
			cur._act("loan_conferma")
			await get_tree().create_timer(0.42).timeout
		"0":
			for i in 3:
				cur._act("mont_fonte_%d" % i)
				if sfrutta:
					cur._act("mont_taglia")
					cur._act("mont_fonte_%d" % i)
				cur._act("mont_aggiungi")
			cur._act("mont_trasmetti")
			cur._act("mont_invia")
	var n := 0
	while _scene_path() == B.SCENE and n < 3000:
		await get_tree().process_frame
		n += 1
	if _scene_path() == B.SCENE:
		_forza("l'incarico del Capo non si chiudeva: uscito a mano")
		Router.goto(str(B.state(floor).get("return", Router.FONDO)))
		await _wait_scene(str(B.state(floor).get("return", Router.FONDO)), 6000)


func _room() -> Room:
	return get_tree().current_scene as Room


## Le cose con cui si può interagire nella stanza, da sinistra a destra (la Presidente per ultima).
func _cose(solo_persone := false) -> Array:
	var out: Array = []
	for n in get_tree().get_nodes_in_group("interactable"):
		var it := n as Node2D
		if it == null or not it.is_visible_in_tree() or n is Seat:
			continue
		if it.has_meta("job_id"):
			continue
		var persona := n.is_in_group("npc")
		if solo_persone and not persona:
			continue
		if persona and strada == "solo":
			continue
		if n is Interactable:
			var a: Callable = (n as Interactable).action
			if a.is_valid() and a.get_method() in SALTA_METODI:
				continue
		var sc: Script = n.get_script()
		if sc and (sc.resource_path.contains("badge_booth") or sc.resource_path.contains("stellina")):
			continue
		out.append(it)
	out.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		var pa := _e_presidente(a)
		var pb := _e_presidente(b)
		if pa != pb: return pb
		return a.global_position.x < b.global_position.x)
	return out


## La Presidente (che chiude la partita) e l'assemblea (che chiude la piazza) si fanno per ultime.
func _e_presidente(n: Node) -> bool:
	if n is Interactable and (n as Interactable).action.is_valid():
		return (n as Interactable).action.get_method() in ["talk_president", "_organizer_talk"]
	return false


func _nome(n: Node) -> String:
	if n.is_in_group("npc"):
		return "persona " + str(n.get("id"))
	if n is Examine:
		return "oggetto " + n.name + (" (" + str(n.get("method")) + ")" if str(n.get("method")) != "" else "")
	if n is Interactable and (n as Interactable).action.is_valid():
		return "punto " + n.name + " (" + (n as Interactable).action.get_method() + ")"
	return "punto " + n.name


func _usa(n: Node2D, path: String) -> void:
	if not is_instance_valid(n) or _scene_path() != path:
		return
	var r := _room()
	if r and r.player:
		r.player.global_position = n.global_position + Vector2(0, 14)
	_scrivi("\n  >> " + _nome(n))
	await n.call("interact")
	await _calma()
	if _scene_path() != path and _scene_path() in Router.WORLD and _scene_path() != Router.CIMA:
		# un'uscita (per esempio la porta della Casa Comune): si torna indietro
		_forza("uscito in %s: si torna a %s" % [_scene_path().get_file(), path.get_file()])
		Router.goto(path)
		await _wait_scene(path, 20000)
		await _calma()


var _fatti := {}


## giro 0: tutto quello che non si e' ancora toccato; giri dopo: le persone e i punti "di storia"
## (gli oggetti con un metodo), perche' dopo un aiuto dicono cose nuove (Agenda, sportelli...).
func _giro_stanza(path: String, giri := 2) -> void:
	for g in giri:
		for n in _cose():
			if _scene_path() != path:
				return
			if not is_instance_valid(n):
				continue
			var key := str(n.get_path())
			var storia: bool = n.is_in_group("npc") or (n is Examine and str(n.get("method")) != "")
			if g == 0 and _fatti.has(key):
				continue
			if g > 0 and not storia:
				continue
			_fatti[key] = true
			await _usa(n, path)


## Un turno di lavoro al piano, alla sua postazione TURNO (la paga; dopo il turno il Capo telefona).
func _turno(path: String) -> void:
	if GameState.worked_today:
		return
	for n in get_tree().get_nodes_in_group("interactable"):
		if (n as Node).has_meta("job_id") and (n as Node2D).is_visible_in_tree():
			_scrivi("\n  >> postazione TURNO (" + str(n.get_meta("job_id")) + ")")
			var r := _room()
			if r and r.player:
				r.player.global_position = (n as Node2D).global_position + Vector2(0, 14)
			await n.call("interact")
			await _calma()
			if _scene_path() != path:
				Router.goto(path)
				await _wait_scene(path, 20000)
				await _calma()
			return


func _notte() -> void:
	# il giorno dopo (come la stellina): niente scena, solo il tempo
	GameState.day += 1
	GameState.worked_today = false
	GameState.minutes = GameState.DAY_START


func _sali(path: String, need: String) -> void:
	var r := _room()
	if not GameState.has_badge(need):
		var cost := GameState.badge_cost(need)
		if GameState.money < cost:
			_forza("soldi aggiunti per il badge: %s -> %s" % [GameState.money, cost])
			GameState.money = cost
		for volta in 3:
			if GameState.has_badge(need):
				break
			_scrivi("\n  >> sportello badge (volta %d)" % (volta + 1))
			await _room().call("_badge_machine")
			await _calma()
	if not GameState.has_badge(need):
		_forza("badge del %s dato a mano (lo sportello non l'ha dato)" % need)
		GameState.badges.append(need)
	r = _room()
	_scrivi("\n  >> le scale (" + need + ")")
	await r.call("on_stairs_step", r.player, need)
	await _calma()
	# sul primo gradino si può ancora voltarsi: chi è curioso torna a parlare con le persone
	if strada != "solo" and _scene_path() == path:
		_scrivi("\n  -- dopo il primo gradino, ci si volta")
		await _giro_stanza(path, 2)
	r = _room()
	if r.call("on_stairs_top", r.player):
		pass
	else:
		_forza("on_stairs_top non ha cambiato piano: Router.goto a mano")
		Router.goto(PIANI[PIANI.map(func(x): return x[0]).find(path) + 1][0] if path != Router.CITY else Router.CIMA, "from_below")


func _run() -> void:
	GameState.new_game()
	GameState.player_name = "Pietro"
	match turno:
		"buono": director_plan = [{"alloc": {"stipendi": 45, "servizi": 20, "manutenzione": 25, "riserve": 10}, "casa": "risorse", "choice": "revisione"}]
		"conserva": director_plan = [{"alloc": {"stipendi": 45, "servizi": 20, "manutenzione": 25, "riserve": 10}, "casa": "risorse", "choice": "conservare"}]
		"tagli": director_plan = [{"alloc": {"stipendi": 30, "servizi": 10, "manutenzione": 25, "riserve": 35}, "choice": "revisione"}]
		_: director_plan = [{"alloc": {"stipendi": 30, "servizi": 10, "manutenzione": 25, "riserve": 35}, "choice": "conservare"}]
	Router.goto(Router.ELEVATOR)
	await _wait_scene(Router.FONDO, 60000)
	await _calma()
	for i in PIANI.size():
		var path: String = PIANI[i][0]
		var need: String = PIANI[i][1]
		if _scene_path() != path:
			await _wait_scene(path, 60000)
		await _calma()
		_scrivi("\n#### PIANO %s" % path.get_file().get_basename())
		await _giro_stanza(path, 1)
		await _turno(path)
		await _giro_stanza(path, 3)
		if path == Router.CITY:
			Router.goto(Router.CASA_COMUNE, "default")
			await _wait_scene(Router.CASA_COMUNE, 20000)
			await _calma()
			await _giro_stanza(Router.CASA_COMUNE, 2)
			Router.goto(Router.CITY, "casa")
			await _wait_scene(Router.CITY, 20000)
			await _calma()
			await _giro_stanza(Router.CITY, 2)
		_notte()
		await _sali(path, need)
		var n := 0
		while _scene_path() == path and n < 30000:
			await get_tree().process_frame
			n += 1
	# la Cima: tutto quello che c'è, più volte, finché la scelta finale porta al Finale
	await _wait_scene(Router.CIMA, 60000)
	await _calma()
	_scrivi("\n#### LA CIMA")
	for giro in 6:
		if _scene_path() != Router.CIMA:
			break
		_scrivi("\n  -- giro %d della Cima" % (giro + 1))
		for c in _cose():
			if _scene_path() != Router.CIMA:
				break
			await _usa(c, Router.CIMA)
		if _scene_path() == Router.DIREZIONE:
			await _wait_scene(Router.CIMA, 60000)
			await _calma()
	var n := 0
	while _scene_path() != Router.FINALE and n < 60000:
		await get_tree().process_frame
		n += 1
	var c6: Dictionary = GameState.flags.get("chapter_6", {})
	var fatti: Dictionary = FIN.facts()
	_scrivi("\n#### ESITO: %s" % str(c6.get("outcome", {})))
	_scrivi("#### FATTI: %s" % str(fatti))
	_scrivi("#### AIUTATI: %s  ROBOT: %s" % [GameState.helped_ids, GameState.robots])
	n = 0
	while _scene_path() == Router.FINALE and n < 60000:
		await get_tree().process_frame
		n += 1
	_scrivi("\n#### FINE. Forzati dal giro: %d. Problemi: %s" % [_forzati.size(), _failures])
	print("GIRO STORIA FINITO ", c6.get("outcome", {}), " problemi ", _failures)
	get_tree().quit()
