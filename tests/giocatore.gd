extends "res://tests/giro_storia.gd"
## Il giro "da giocatore": come giro_storia.gd, ma si cammina davvero (frecce sul PC, dito sul telefono),
## si gira per ogni piano su e giù, nei minigiochi si provano tasti e tocchi a caso per qualche secondo
## e la prima volta a volte si perde. Fa le foto dell'arrivo in ogni stanza, di ogni minigioco e dei
## PROBLEMI (cose che non si riescono a usare, scritte che escono dal riquadro).
## Va lanciato CON la grafica (non --headless), a 640x360:
##   Godot --path . --resolution 640x360 --fixed-fps 30 --disable-vsync res://tests/giocatore.tscn -- \
##       --vero=pc|tel --strada=... --finale=... --turno=... --foto=C:/cartella --log=C:/cartella/giro.txt

var foto_dir := ""
var _n_foto := 0
var _problemi: Array[String] = []
var _rng := RandomNumberGenerator.new()
var _mg_id := 0
var _mg_frame := 0
var _mg_durata := 0
var _mg_prove := {}
var _lavoro_id := 0
var _lavoro_frame := 0
var _arrivo_foto := ""
var _arrivo_frame := 0
var _gia_problema := {}


func _ready() -> void:
	vero = "pc"
	ovunque = true
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		if kv.size() == 2 and kv[0] == "foto":
			foto_dir = kv[1]
		if kv.size() == 2 and kv[0] == "pausa":
			pausa = int(kv[1])
	if foto_dir != "":
		DirAccess.make_dir_recursive_absolute(foto_dir)
	_rng.seed = hash(str(OS.get_cmdline_user_args()))
	await super._ready()


func _process(delta: float) -> void:
	var sp := _scene_path()
	var scene := get_tree().current_scene
	if vero == "tel" and not TouchControls.enabled:
		TouchControls.enabled = true
	# la foto di ogni stanza appena arrivati (quando la scena si è fermata)
	if sp != _scena and sp in Router.WORLD:
		_arrivo_foto = "arrivo_" + sp.get_file().get_basename()
		_arrivo_frame = _frame + 45
	if _arrivo_foto != "" and _frame >= _arrivo_frame:
		_foto(_arrivo_foto)
		_arrivo_foto = ""
	if scene != null and sp == Router.MINIGAME and not Ui.transitioning and scene.get("phase") == "play" and not Ui.busy:
		_frame += 1
		_minigioco(scene)
		return
	if scene != null and sp == Router.WORK and not Ui.transitioning and scene.get("phase") == "play" and not Ui.busy:
		if _lavoro_id != scene.get_instance_id():
			_lavoro_id = scene.get_instance_id()
			_lavoro_frame = 0
			_foto("turno_di_lavoro")
		_lavoro_frame += 1
		if _lavoro_frame < 150:
			_frame += 1
			if _lavoro_frame % 7 == 0:
				_a_caso()
			return
	super._process(delta)


# --- i minigiochi: si prova davvero, poi il giro decide -----------------------------------------------

func _minigioco(scene: Node) -> void:
	var id := str(GameState.minigame.get("id", GameState.minigame.get("type", "?")))
	if _mg_id != scene.get_instance_id():
		_mg_id = scene.get_instance_id()
		_mg_frame = 0
		_mg_durata = _rng.randi_range(90, 210)
		_mg_prove[id] = int(_mg_prove.get(id, 0)) + 1
		_foto("minigioco_%s_prova%d" % [id, _mg_prove[id]])
	_mg_frame += 1
	if not _coda.is_empty():
		(_coda.pop_front() as Callable).call()
		return
	if _mg_frame < _mg_durata:
		if _mg_frame % 8 == 0:
			_a_caso()
		return
	if _mg_frame == _mg_durata:
		_foto("minigioco_%s_dopo_le_prove" % id)
	# la prima volta, quasi una su due si perde (come chi non ha ancora capito il gioco)
	var vince := strada != "perde" and not (int(_mg_prove[id]) == 1 and _rng.randf() < 0.45)
	_scrivi("    [minigioco %s, prova %d: provato a mano per %d s, poi %s dal giro]" % [id, _mg_prove[id], _mg_durata / 30, "vinto" if vince else "PERSO"])
	var v: Node = scene.get("visivo")
	if v != null:
		v.errori = 0 if vince else 99
		v.chiudi(vince)
	else:
		scene.set("misses", 0 if vince else 99)
		scene.call("_finish", vince, false)


## Un tocco, un clic o un tasto a caso: quello che fa chi non ha ancora capito.
func _a_caso() -> void:
	var p := Vector2(_rng.randf_range(30, 610), _rng.randf_range(60, 340))
	if vero == "tel":
		_touch(p, true, 0)
		if _rng.randf() < 0.3:
			var q := p + Vector2(_rng.randf_range(-80, 80), _rng.randf_range(-60, 60))
			_coda.append(func() -> void: _drag(q, 0))
			_coda.append(func() -> void: _touch(q, false, 0))
		else:
			_coda.append(func() -> void: _touch(p, false, 0))
	else:
		match _rng.randi_range(0, 3):
			0:
				_clic(p, true)
				_coda.append(func() -> void: _clic(p, false))
			1:
				_tap("confirm")
			_:
				var az: String = ["move_left", "move_right", "move_up", "move_down"][_rng.randi_range(0, 3)]
				Input.action_press(az)
				_coda.append(func() -> void: pass)
				_coda.append(func() -> void: Input.action_release(az))


# --- camminare davvero -------------------------------------------------------------------------------

func _usa(n: Node2D, path: String) -> void:
	if not is_instance_valid(n) or _scene_path() != path:
		return
	_scrivi("\n  >> " + _nome(n))
	var ok: bool = await _cammina_e_usa(n)
	if not ok:
		# prima la foto del problema, poi il giro rimedia
		for f in 3:
			await get_tree().process_frame
		if is_instance_valid(n) and _scene_path() == path and not Ui.busy:
			_forza("usato a mano dopo il problema: " + _nome(n))
			var r := _room()
			if r and r.player:
				r.player.global_position = n.global_position + Vector2(0, 14)
			# senza await: se la persona sparisce (si apre un minigioco), quell'await non tornerebbe più
			n.call("interact")
			for f in 5:
				await get_tree().process_frame
	await _calma()
	if _scene_path() != path and _scene_path() in Router.WORLD and _scene_path() != Router.CIMA:
		_forza("uscito in %s: si torna a %s" % [_scene_path().get_file(), path.get_file()])
		Router.goto(path)
		await _wait_scene(path, 20000)
		await _calma()


func _nome(n: Node) -> String:
	var s := super._nome(n)
	if n is Node2D:
		s += " a (%d,%d)" % [int((n as Node2D).global_position.x), int((n as Node2D).global_position.y)]
		if n.get_parent() and not n.get_parent().name.begins_with("@"):
			s += " in " + str(n.get_parent().name)
	return s


func _punto(n: Node2D, da: Vector2) -> Vector2:
	return n.interaction_point(da) if n is Interactable else n.call("hotspot")


func _successo_qualcosa(path: String) -> bool:
	return Ui.busy or Ui.transitioning or _scene_path() != path


## Va fino alla cosa e la usa, come un giocatore. true se si è aperto qualcosa.
func _cammina_e_usa(n: Node2D) -> bool:
	await _calma(3000)
	var r := _room()
	if r == null or r.player == null or not is_instance_valid(n):
		return false
	var path := _scene_path()
	if vero == "tel":
		for volta in 8:
			if not is_instance_valid(n): return _successo_qualcosa(path)
			var pl: Node2D = r.player
			var bersaglio := _punto(n, pl.global_position)
			if n.is_in_group("npc") or n.is_in_group("walker"):
				bersaglio += Vector2(0, -8)
			var schermo: Vector2 = pl.get_canvas_transform() * bersaglio
			var dentro := Rect2(16, 64, 608, 284).has_point(schermo)
			if not dentro:
				# troppo lontano: come un giocatore, si tocca il pavimento lungo la strada giusta
				# (giro intorno ai muri, dalla porta), il punto più avanti che si vede sullo schermo
				var me: Vector2 = pl.get_canvas_transform() * pl.global_position
				var via: PackedVector2Array = pl.call("_cerca_strada", bersaglio, null)
				var scelto := Vector2.INF
				for i in range(via.size() - 1, -1, -1):
					var sp: Vector2 = pl.get_canvas_transform() * via[i]
					if Rect2(24, 72, 592, 268).has_point(sp) and sp.distance_to(me) > 12.0 and pl.call("_cosa_sotto_il_dito", via[i]) == null:
						scelto = sp
						break
				if scelto != Vector2.INF:
					schermo = scelto
				else:
					schermo = me + (schermo - me).limit_length(140.0)
					schermo = schermo.clamp(Vector2(24, 72), Vector2(616, 340))
			if dentro and strada == "solo":
				var sotto: Node = pl.call("_cosa_sotto_il_dito", bersaglio)
				if sotto != null and sotto != n and (sotto.is_in_group("npc") or sotto.is_in_group("walker")):
					_nota("strada solitaria: il dito prenderebbe %s, si lascia stare" % _nome(sotto))
					return false
			_premi(schermo)
			for k in 420:
				await get_tree().process_frame
				if _successo_qualcosa(path):
					return true
				if k > 20 and (pl as CharacterBody2D).get_real_velocity().length() < 1.0 and (pl.get("_percorso") as PackedVector2Array).is_empty():
					break
			if dentro and volta >= 3:
				break
		_problema("col dito non si riesce a usare %s (toccato, ma non si apre niente)" % _nome(n))
		if is_instance_valid(r.player) and is_instance_valid(n):
			var pl2: Node2D = r.player
			var strada_dito: PackedVector2Array = pl2.call("_cerca_strada", _punto(n, pl2.global_position), n)
			_nota("dito: giocatore a %s (schermo %s), blocca=%s busy=%s cut=%s trans=%s, strada %d passi, sotto il dito: %s" % [
				pl2.global_position, pl2.get_canvas_transform() * pl2.global_position, Ui.blocks_input(), Ui.busy, Ui.cutscene,
				Ui.transitioning, strada_dito.size(), _nome(pl2.call("_cosa_sotto_il_dito", _punto(n, pl2.global_position))) if pl2.call("_cosa_sotto_il_dito", _punto(n, pl2.global_position)) else "niente"])
			var cam := get_viewport().get_camera_2d()
			_nota("dito: camera %s (del giocatore: %s) centro %s, giocatore visibile %s, processa %s, input %s" % [
				cam.get_path() if cam else "nessuna", cam == pl2.get("camera"), cam.get_screen_center_position() if cam else Vector2.ZERO,
				pl2.is_visible_in_tree(), pl2.can_process(), pl2.is_processing_unhandled_input()])
		return false
	# PC: le frecce lungo la strada, poi INVIO davanti alla cosa
	var pl: CharacterBody2D = r.player
	var dove := _punto(n, pl.global_position)
	# davanti allo sportello, dal lato giusto (come chi lo vede)
	if n is Interactable and (n as Interactable).approach != Vector2.ZERO:
		dove += (n as Interactable).approach.normalized() * 10.0
	# il posto da cui, con la tastiera, il tasto prende proprio questa cosa (il più vicino a dove sei)
	var posto: Array = []
	var strada_pc := PackedVector2Array()
	for tentativo in 2:
		var posti: Array = _posto_per(pl, n)
		if posti.is_empty():
			_problema("da tastiera %s non si può usare da nessun punto libero lì intorno" % _nome(n))
			return false
		# il primo posto buono a cui si arriva davvero camminando (alcuni sono chiusi fra i mobili)
		var scelti: Array = []
		# al massimo 4 posti da provare: ogni ricerca della strada costa cara
		for k in mini(4, posti.size()):
			scelti.append(posti[k * posti.size() / mini(4, posti.size())])
		for cand: Array in scelti:
			if pl.global_position.distance_to(cand[0]) <= 4.0:
				posto = cand
				break
			var s: PackedVector2Array = pl.call("_cerca_strada", cand[0], null)
			if not s.is_empty() and s[s.size() - 1].distance_to(cand[0]) <= 6.0:
				posto = cand
				strada_pc = s
				strada_pc.append(cand[0])
				break
		if not posto.is_empty():
			break
		# incastrati fra le sedie: due passi a caso con le frecce, come fa chiunque
		var az: String = ["move_left", "move_right", "move_up", "move_down"][_rng.randi_range(0, 3)]
		Input.action_press(az)
		for f in 10:
			await get_tree().process_frame
		Input.action_release(az)
	if posto.is_empty():
		_nota("non si trova una strada per arrivare a %s (da %d,%d)" % [_nome(n), int(pl.global_position.x), int(pl.global_position.y)])
		return false
	dove = posto[0]
	pl.set("_percorso", strada_pc)
	pl.set("_meta", null)
	pl.set("_fermo_da", 0.0)
	for k in 900:
		await get_tree().process_frame
		if _successo_qualcosa(path):
			pl.set("_percorso", PackedVector2Array())
			return true
		if (pl.get("_percorso") as PackedVector2Array).is_empty():
			break
	_lascia()
	if not is_instance_valid(n): return _successo_qualcosa(path)
	if pl.global_position.distance_to(_punto(n, pl.global_position)) > float(pl.call("_portata", n)) + 30.0:
		_nota("non si arriva vicino a %s (fermo a %d pixel)" % [_nome(n), int(pl.global_position.distance_to(_punto(n, pl.global_position)))])
		return false
	if not is_instance_valid(n): return _successo_qualcosa(path)
	# girati verso la cosa (un colpetto di freccia, poi si spinge un po' contro) e INVIO;
	# se non la prende, si prova a girarsi dalle altre parti, come fa chi cerca il punto giusto
	var verso := _punto(n, pl.global_position) - pl.global_position
	var az := ("move_right" if verso.x > 0 else "move_left") if absf(verso.x) > absf(verso.y) else ("move_down" if verso.y > 0 else "move_up")
	if n is Interactable and (n as Interactable).facing_required != "":
		az = "move_" + (n as Interactable).facing_required
	elif n is Interactable and (n as Interactable).approach != Vector2.ZERO:
		var a := -(n as Interactable).approach
		az = ("move_right" if a.x > 0 else "move_left") if absf(a.x) > absf(a.y) else ("move_down" if a.y > 0 else "move_up")
	# un passo contro la cosa, poi ci si gira (un colpetto di freccia gira senza quasi muovere)
	az = "move_" + str(posto[1])
	pl.call("face", str(posto[1]))
	await get_tree().process_frame
	var preso: Node = pl.call("_find_target")
	if preso != n:
		for dir in [az.trim_prefix("move_"), "up", "down", "left", "right"]:
			pl.call("face", dir)
			preso = pl.call("_find_target")
			if preso == n:
				break
	if preso != n:
		pl.call("face", az.trim_prefix("move_"))
		preso = pl.call("_find_target")
	if preso != n:
		if preso == null:
			_nota("da tastiera, davanti a %s il tasto non prende niente (distanza %d)" % [_nome(n), int(pl.global_position.distance_to(_punto(n, pl.global_position)))])
			return false
		_scrivi("    [davanti a %s il tasto prende invece %s]" % [_nome(n), _nome(preso)])
		if strada == "solo" and (preso.is_in_group("npc") or preso.is_in_group("walker")):
			_nota("strada solitaria: non si parla con %s, si guarda solo l'oggetto" % _nome(preso))
			return false
	_tap("confirm")
	for k in 60:
		await get_tree().process_frame
		if _successo_qualcosa(path):
			return true
	_nota("da tastiera, INVIO davanti a %s non apre niente" % _nome(n))
	return false


## [posizione, direzione]: un punto libero (il giocatore ci sta senza toccare mobili) da cui, girati
## in quella direzione, il tasto prende proprio `n`. Il più vicino al giocatore. [] se non esiste.
func _posto_per(pl: CharacterBody2D, n: Node2D) -> Array:
	var col: CollisionShape2D = pl.get_node("Collisione")
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = col.shape
	q.collision_mask = pl.collision_mask
	q.exclude = [pl.get_rid()]
	var spazio := pl.get_world_2d().direct_space_state
	var vero_pos := pl.global_position
	var vero_dir := str(pl.get("facing"))
	var centro := _punto(n, vero_pos)
	var meglio: Array = []
	var buoni := {}
	for dy in range(-30, 31, 2):
		for dx in range(-30, 31, 2):
			var p := centro + Vector2(dx, dy)
			q.transform = Transform2D(0.0, p + col.position)
			if not spazio.intersect_shape(q, 1).is_empty():
				continue
			pl.global_position = p
			for dir in ["up", "down", "left", "right"]:
				pl.set("facing", dir)
				if pl.call("_find_target") == n:
					buoni[Vector2i(dx, dy)] = dir
					break
	pl.global_position = vero_pos
	pl.set("facing", vero_dir)
	# solo i punti "dentro" la zona buona: la strada si ferma a 3 pixel, e deve restare buona lì intorno
	for c: Vector2i in buoni:
		var dentro := true
		for v: Vector2i in [Vector2i(4, 0), Vector2i(-4, 0), Vector2i(0, 4), Vector2i(0, -4)]:
			if not buoni.has(c + v) or buoni[c + v] != buoni[c]:
				dentro = false
		if dentro:
			var p := centro + Vector2(c)
			meglio.append([p, buoni[c], p.distance_to(vero_pos)])
	if meglio.is_empty():
		for c: Vector2i in buoni:
			var p := centro + Vector2(c)
			meglio.append([p, buoni[c], p.distance_to(vero_pos)])
	meglio.sort_custom(func(a: Array, b: Array) -> bool: return float(a[2]) < float(b[2]))
	return meglio


func _premi_verso(d: Vector2) -> void:
	var v := d.normalized()
	for coppia: Array in [["move_right", v.x], ["move_left", -v.x], ["move_down", v.y], ["move_up", -v.y]]:
		if float(coppia[1]) > 0.2:
			Input.action_press(str(coppia[0]), clampf(float(coppia[1]) * 1.4, 0.0, 1.0))
		else:
			Input.action_release(str(coppia[0]))


func _lascia() -> void:
	for az in ["move_right", "move_left", "move_down", "move_up"]:
		Input.action_release(az)


## Su e giù per il piano: qualche punto lontano, a caso, come chi si guarda intorno.
func _esplora(path: String) -> void:
	_scrivi("\n  -- giro per il piano, su e giù")
	for volta in 4:
		if _scene_path() != path: return
		var r := _room()
		if r == null or r.player == null: return
		var pl: CharacterBody2D = r.player
		var meta := pl.global_position + Vector2(_rng.randf_range(-260, 260), _rng.randf_range(-150, 150))
		if vero == "tel":
			var s: Vector2 = pl.get_canvas_transform() * meta
			_premi(s.clamp(Vector2(24, 72), Vector2(616, 340)))
			for k in 300:
				await get_tree().process_frame
				if Ui.busy or _scene_path() != path: break
				if k > 20 and pl.get_real_velocity().length() < 1.0: break
		else:
			var strada_pc: PackedVector2Array = pl.call("_cerca_strada", meta, null)
			pl.set("_percorso", strada_pc)
			pl.set("_meta", null)
			for k in 600:
				await get_tree().process_frame
				if Ui.busy or _scene_path() != path or (pl.get("_percorso") as PackedVector2Array).is_empty():
					break
		await _calma()
		if volta % 2 == 1:
			_foto("giro_" + path.get_file().get_basename())


func _giro_stanza(path: String, giri := 2) -> void:
	if not _fatti.has("esplorato_" + path):
		_fatti["esplorato_" + path] = true
		await _esplora(path)
	await super._giro_stanza(path, giri)


# --- controlli e foto ---------------------------------------------------------------------------------

func _registra(t: String) -> void:
	super._registra(t)
	var lbl: Label = Ui.get("_label")
	if lbl and lbl.is_visible_in_tree() and lbl.get_line_count() > lbl.get_visible_line_count() and lbl.get_visible_line_count() > 0:
		_problema("scritta troppo lunga per il riquadro (%d righe, se ne vedono %d): %s" % [lbl.get_line_count(), lbl.get_visible_line_count(), lbl.text.left(60)])


func _scelta(prompt: String, opts: Array) -> int:
	var i := super._scelta(prompt, opts)
	var carte: Array = Ui.get("_carte")
	var schermo := Rect2(0, 0, 640, 360)
	for c in carte:
		var rc := (c as Control).get_global_rect()
		if not schermo.encloses(rc):
			_problema("un cartoncino di scelta esce dallo schermo: %s" % prompt.left(50))
	return i


## Il giro non è riuscito a camminare fin lì: di solito è il giro, non il gioco (il controllo fisso
## tests/collisioni/tmp/tasto_ovunque.gd dice se col tasto si può davvero).
var _note := 0


func _nota(t: String) -> void:
	_note += 1
	_scrivi("    [nota del giro] " + t)


func _problema(t: String) -> void:
	var chiave := t.left(70)
	if _gia_problema.has(chiave):
		_scrivi("    [PROBLEMA, di nuovo] " + t)
		return
	_gia_problema[chiave] = true
	_problemi.append(t)
	_scrivi("    [PROBLEMA] " + t)
	_foto("PROBLEMA_" + t.left(40))


func _foto(nome: String) -> void:
	if foto_dir == "" or DisplayServer.get_name() == "headless":
		return
	_n_foto += 1
	var numero := _n_foto
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var pulito := ""
	for ch in nome:
		pulito += ch if (ch.is_valid_identifier() or ch.is_valid_int()) else "_"
	img.save_png("%s/%03d_%s.png" % [foto_dir, numero, pulito.left(60)])


## --da=sottoufficio|mercato|banca|citta|cima: si parte da quel piano (per riprovare un pezzo solo).
var da := ""


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--da="):
			da = a.trim_prefix("--da=")
	if da == "":
		await super._run()
	else:
		await _run_da()
	print("PROBLEMI DA GIOCATORE ", _problemi.size())
	_scrivi("\n#### PROBLEMI DA GIOCATORE (%d):\n- %s" % [_problemi.size(), "\n- ".join(_problemi)])


func _run_da() -> void:
	GameState.new_game()
	GameState.player_name = "Pietro"
	director_plan = [{"alloc": {"stipendi": 45, "servizi": 20, "manutenzione": 25, "riserve": 10}, "casa": "risorse", "choice": "revisione"}]
	var inizio := 0
	for i in PIANI.size():
		if str(PIANI[i][0]).get_file().get_basename() == da:
			inizio = i
	for i in inizio:
		GameState.badges.append(str(PIANI[i][1]))
	GameState.money = 2000
	var dove: String = PIANI[inizio][0] if da != "cima" else Router.CIMA
	Router.goto(dove, "from_below")
	await _wait_scene(dove, 60000)
	await _calma()
	for i in range(inizio, PIANI.size()):
		var path: String = PIANI[i][0]
		if _scene_path() != path:
			await _wait_scene(path, 60000)
		await _calma()
		_scrivi("\n#### PIANO %s" % path.get_file().get_basename())
		await _giro_stanza(path, 1)
		await _turno(path)
		await _giro_stanza(path, 3)
		await _sali(path, str(PIANI[i][1]))
		var n := 0
		while _scene_path() == path and n < 30000:
			await get_tree().process_frame
			n += 1
	_scrivi("\n#### FINE PEZZO")
	get_tree().quit()
