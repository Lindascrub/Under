extends Node2D
signal richiesta(azione: String, dati: Dictionary)
const B := preload("res://scripts/boss_missions.gd")
const ART := preload("res://scripts/minigame_art.gd")
const PRODUCTS := preload("res://scripts/product_art.gd")
const GROCERY := preload("res://assets/limezu/themes/grocery.png")
const PAPER := Color("eee4cc")
const GOLD := Color("ffe14d")
const INK := Color("241d32")
const MINT := Color("67d1c2")
var p: Dictionary = {}
var v: Dictionary = {}
var avviso := ""
var in_mano := ""
var premuto := ""
var origine := Vector2.ZERO
var cursore := Vector2.ZERO
var trascina := false
var fuoco := 0
var conferma_aperta := false
var consegnando := false
var spostamento := Vector2.ZERO
var scatto := 0.0
var condizioni_interne := ""

func aggiorna(stato: Dictionary, messaggio: String) -> void:
	p = stato
	v = B.market_preview(p)
	avviso = messaggio
	condizioni_interne = "%d pezzi · %s l'uno\nBase: %s %s" % [int(v.units), B.cash(int(v.each)), "oggi" if int(p.reference) == 0 else "futuro", B.cash(int(v.ref))]
	queue_redraw()

func rett(nome: String) -> Rect2:
	return get_node(nome).get_global_rect()

func stampato() -> bool:
	return not (p.get("label_work", {}).get("printed", {}) as Dictionary).is_empty()

func rett_adesivo(tipo: String) -> Rect2:
	if tipo == "conditions" and not bool(p.get("visible", true)): return rett("Terminale")
	var punto: Vector2 = B.market_sticker_position(tipo, p)
	return Rect2(rett("Cartellino").position + punto, B.market_sticker_size(tipo))

func bersagli() -> Array:
	if consegnando: return []
	if conferma_aperta:
		return [{"rect": rett("Conferma/Indietro"), "action": "label_indietro"}, {"rect": rett("Conferma/Applica"), "action": "label_conferma"}]
	var out: Array = [{"rect": rett("Rotella"), "action": "label_rate"}]
	for i in 2:
		out.append({"rect": rett("Listini/Listino%d" % i), "action": "label_ref_%d" % i})
		out.append({"rect": rett("Prodotti/Minimo%d" % (i + 1)), "action": "label_units_%d" % (i + 1)})
	if stampato():
		for tipo in ["discount", "conditions"]: out.append({"rect": rett_adesivo(tipo), "action": "label_" + tipo})
	for nome in ["Stampa", "Cartellino", "Terminale", "Applica", "Esci"]:
		out.append({"rect": rett(nome), "action": "label_" + nome.to_lower()})
	return out

func evidenzia(i: int) -> void:
	fuoco = i
	queue_redraw()

func naviga(i: int, direzione: Vector2) -> int:
	var targets := bersagli()
	if targets.is_empty(): return 0
	i = clampi(i, 0, targets.size() - 1)
	var da: Vector2 = targets[i].rect.get_center()
	var migliore := i
	var costo := INF
	for k in targets.size():
		var delta: Vector2 = targets[k].rect.get_center() - da
		var avanti := delta.dot(direzione)
		if avanti <= 8: continue
		var c := avanti + absf(delta.cross(direzione)) * 3
		if c < costo:
			costo = c
			migliore = k
	return migliore

func tastiera(e: InputEvent) -> bool:
	if e.is_action_pressed("ui_cancel"):
		conferma_aperta = false
		in_mano = ""
		return true
	if not conferma_aperta and e is InputEventKey and e.pressed and e.shift_pressed and in_mano in ["discount", "conditions"]:
		var dir := Vector2.ZERO
		match e.keycode:
			KEY_LEFT: dir = Vector2.LEFT
			KEY_RIGHT: dir = Vector2.RIGHT
			KEY_UP: dir = Vector2.UP
			KEY_DOWN: dir = Vector2.DOWN
		if dir != Vector2.ZERO:
			richiesta.emit("move", {"kind": in_mano, "point": B.market_sticker_position(in_mano, p) + dir * 4})
			return true
	return false

func attiva(azione: String) -> void:
	if consegnando: return
	if conferma_aperta:
		if azione == "indietro": conferma_aperta = false
		elif azione == "conferma":
			conferma_aperta = false
			richiesta.emit("submit", {})
		return
	if azione == "rate":
		richiesta.emit("set", {"key": "rate", "value": [0, 10, 50][posmod([0, 10, 50].find(int(p.get("rate", 0))) + 1, 3)]})
		Sound.sfx("arcade/select_2")
	elif azione.begins_with("ref_"): richiesta.emit("set", {"key": "reference", "value": azione.trim_prefix("ref_").to_int()})
	elif azione.begins_with("units_"): richiesta.emit("set", {"key": "units", "value": azione.trim_prefix("units_").to_int()})
	elif azione == "stampa":
		richiesta.emit("print", {})
		scatto = 1
		create_tween().tween_property(self, "scatto", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Sound.sfx("arcade/computer_1")
	elif azione in ["discount", "conditions"]:
		if in_mano == "conditions" and azione == "discount":
			_posa("conditions", B.market_sticker_position("conditions", p))
		else: in_mano = "" if in_mano == azione else azione
	elif azione == "cartellino":
		if in_mano in ["discount", "conditions"]: _posa(in_mano, B.market_sticker_position(in_mano, p))
	elif azione == "terminale":
		if in_mano == "conditions":
			richiesta.emit("hide", {})
			in_mano = ""
		else: avviso = "Prendi il foglio delle condizioni."
	elif azione == "applica":
		var error := B.prepared_market_error()
		if error != "": avviso = error
		elif bool(v.hidden):
			conferma_aperta = true
			richiesta.emit("focus_confirm", {})
		else: richiesta.emit("submit", {})
	elif azione == "esci": richiesta.emit("exit", {})
	queue_redraw()

func _posa(tipo: String, punto: Vector2) -> void:
	richiesta.emit("move", {"kind": tipo, "point": punto})
	in_mano = ""
	if avviso == "": Sound.sfx("select")

func punta(pos: Vector2, fase: int) -> void:
	if consegnando: return
	cursore = pos
	if fase == 0:
		origine = pos
		premuto = ""
		trascina = false
		for b in bersagli():
			if b.rect.has_point(pos):
				premuto = str(b.action).trim_prefix("label_")
				break
	elif fase == 1: trascina = trascina or pos.distance_to(origine) > 8
	elif fase == 2:
		var azione := premuto
		premuto = ""
		if trascina:
			if azione in ["discount", "conditions"]:
				if rett("Cartellino").has_point(pos):
					var punto := pos - rett("Cartellino").position - B.market_sticker_size(azione) / 2
					var max_pos := Vector2(240, 160) - B.market_sticker_size(azione)
					punto = punto.clamp(Vector2(4, 26), max_pos).round()
					_posa(azione, punto)
				elif azione == "conditions" and rett("Terminale").has_point(pos): richiesta.emit("hide", {})
			elif azione.begins_with("ref_") and rett("Riferimento").has_point(pos): attiva(azione)
			elif azione.begins_with("units_") and rett("Cassa").has_point(pos): attiva(azione)
		elif azione != "" and pos.distance_to(origine) < 16: attiva(azione)
		trascina = false
		queue_redraw()

func anima_applicazione() -> void:
	consegnando = true
	in_mano = ""
	var tw := create_tween()
	tw.tween_property(self, "spostamento", Vector2(45, -8), 0.12).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "spostamento", Vector2(460, 0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	spostamento = Vector2.ZERO
	consegnando = false

func _process(_dt: float) -> void:
	queue_redraw()

func _testo(t: String, r: Rect2, size := 11, colore := PAPER) -> void:
	var font := Assets.font()
	var y := r.position.y + size
	for paragrafo in t.split("\n"):
		var linea := ""
		for parola in paragrafo.split(" "):
			var prova := linea + (" " if linea != "" else "") + parola
			if font.get_string_size(prova, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > r.size.x and linea != "":
				if y <= r.end.y: draw_string(font, Vector2(r.position.x, y), linea, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colore)
				y += size + 2
				linea = parola
			else: linea = prova
		if y <= r.end.y: draw_string(font, Vector2(r.position.x, y), linea, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colore)
		y += size + 2

func _prodotto(r: Rect2) -> void:
	if str(v.product) == "acqua":
		var k := maxi(1, int(minf(r.size.x / 16, r.size.y / 24)))
		draw_texture_rect_region(GROCERY, Rect2((r.get_center() - Vector2(8, 12) * k).round(), Vector2(16, 24) * k), Rect2(128, 872, 16, 24))
	else: PRODUCTS.draw(self, r, str(v.product))

func _draw() -> void:
	ART.backdrop(self)
	_testo("CAPO · LO SCONTO IN VETRINA", Rect2(16, 6, 608, 26), 18, GOLD)
	_testo("%s · cartellino %d / 3" % [str(v.get("product", "")).to_upper(), mini(3, int(p.get("round", 0)) + 1)], Rect2(16, 35, 608, 20), 13)
	ART.panel(self, Rect2(12, 64, 616, 254), Color("4b4140"), Color("9b8b72"))
	_draw_stampante()
	for i in 2:
		var r := rett("Listini/Listino%d" % i)
		ART.paper(self, r)
		_testo("OGGI" if i == 0 else "FUTURO", Rect2(r.position + Vector2(6, 5), r.size), 11, INK)
		var valore := B.price_cents(str(v.get("product", "pane")), i == 1)
		_testo(B.cash(valore), Rect2(r.position + Vector2(6, 27), r.size), 11, INK)
		if int(p.get("reference", 0)) == i: draw_rect(r, MINT, false, 2)
	_draw_cartellino()
	_draw_cassa()
	for i in [1, 2]:
		var r := rett("Prodotti/Minimo%d" % i)
		ART.panel(self, r, Color("42645b") if int(p.get("units", 1)) == i else Color("34434a"))
		if i == 1: _prodotto(Rect2(r.position + Vector2(16, 3), Vector2(36, 36)))
		else:
			for dx in [1, 35]: _prodotto(Rect2(r.position + Vector2(dx, 3), Vector2(32, 36)))
		_testo("MIN %d" % i, Rect2(r.position + Vector2(8, 43), r.size), 11)
	var tasca := rett("Terminale")
	ART.panel(self, tasca, Color("2c3444"))
	draw_rect(Rect2(tasca.position + Vector2(8, 16), Vector2(tasca.size.x - 16, 10)), INK)
	_testo("TERMINALE", Rect2(tasca.position + Vector2(4, 42), tasca.size), 10)
	if stampato() and not bool(p.get("visible", true)):
		ART.paper(self, Rect2(tasca.position + Vector2(15, 2), Vector2(52, 30)))
		for y in [8, 14, 20]: draw_line(tasca.position + Vector2(21, y), tasca.position + Vector2(58, y), Color("7e8077"), 1)
	for nome in ["Applica", "Esci"]:
		var r := rett(nome)
		ART.panel(self, r, Color("365b55") if nome == "Applica" else Color("293642"))
		_testo("APPLICA" if nome == "Applica" else "SALVA/ESCI", Rect2(r.position + Vector2(9, 8), r.size - Vector2(18, 8)), 13 if nome == "Applica" else 11, GOLD if nome == "Applica" else PAPER)
	var aiuto := "Scegli lo sconto. STAMPA prepara il cartellino."
	if stampato(): aiuto = "Sistema le etichette sul cartellino, poi APPLICA."
	if stampato() and not B.market_print_current(p): aiuto = "Bozza cambiata: ristampa il cartellino."
	if not TouchControls.enabled: aiuto = "FRECCE e INVIO: usa gli oggetti. Mouse: trascina."
	if in_mano != "":
		aiuto = "Appoggia l'etichetta sul cartellino o annulla."
		if not TouchControls.enabled: aiuto = "MAIUSC + FRECCE: sposta. INVIO sul cartellino: posa."
	if avviso != "": aiuto = avviso
	_testo(aiuto, Rect2(16, 331, 488, 28), 10, GOLD if avviso != "" else PAPER)
	var targets := bersagli()
	if not TouchControls.enabled and fuoco >= 0 and fuoco < targets.size(): draw_rect(targets[fuoco].rect.grow(2), GOLD, false, 1)
	if trascina:
		if premuto in ["discount", "conditions"]:
			_adesivo(premuto, Rect2(cursore - B.market_sticker_size(premuto) / 2, B.market_sticker_size(premuto)))
		elif premuto.begins_with("units_"): _prodotto(Rect2(cursore - Vector2(20, 24), Vector2(40, 48)))
		elif premuto.begins_with("ref_"):
			ART.paper(self, Rect2(cursore - Vector2(38, 24), Vector2(76, 48)))
			_testo("LISTINO", Rect2(cursore - Vector2(33, 17), Vector2(66, 20)), 11, INK)
	if conferma_aperta: _draw_conferma()

func _draw_stampante() -> void:
	ART.panel(self, Rect2(16, 69, 172, 157), Color("4d626d"))
	_testo("STAMPANTE", Rect2(26, 75, 150, 17), 11)
	var r := rett("Rotella")
	draw_circle(r.get_center(), 33, INK)
	draw_circle(r.get_center(), 29, Color("94a1a2"))
	var a := -PI / 2 + [0, 10, 50].find(int(p.get("rate", 0))) * TAU / 3
	draw_line(r.get_center() + Vector2(cos(a), sin(a)) * 22, r.get_center() + Vector2(cos(a), sin(a)) * 28, GOLD, 4)
	_testo("%d%%" % int(p.get("rate", 0)), Rect2(r.position + Vector2(11, 23), Vector2(56, 27)), 18, INK)
	var prezzo := rett("Riferimento")
	ART.panel(self, prezzo, Color("273847"))
	_testo("BASE\n" + ("OGGI" if int(p.get("reference", 0)) == 0 else "FUTURO"), prezzo.grow(-7), 11)
	var stampa := rett("Stampa")
	ART.panel(self, stampa, Color("34434a"))
	draw_rect(Rect2(stampa.position + Vector2(8, 10), Vector2(14, 10)), GOLD)
	_testo("STAMPA", Rect2(stampa.position + Vector2(32, 8), stampa.size), 13)

func _draw_cartellino() -> void:
	draw_set_transform(spostamento + Vector2(0, -scatto * 3))
	var r := rett("Cartellino")
	ART.paper(self, r)
	_testo(str(v.get("product", "")).to_upper(), Rect2(r.position + Vector2(10, 7), Vector2(220, 19)), 13, INK)
	if not stampato():
		_testo("STAMPA QUI\nIL TUO CARTELLINO", Rect2(r.position + Vector2(26, 70), Vector2(200, 43)), 14, Color("8b8175"))
	else:
		_adesivo("discount", rett_adesivo("discount"))
		if bool(p.get("visible", true)): _adesivo("conditions", rett_adesivo("conditions"))
		else: _testo("Condizioni al terminale", Rect2(r.position + Vector2(104, 0), Vector2(130, 25)), 10, INK)
		if not B.market_print_current(p):
			draw_rect(Rect2(r.position + Vector2(5, 25), Vector2(r.size.x - 10, 19)), Color("513e45"))
			_testo("DA RISTAMPARE", Rect2(r.position + Vector2(14, 27), Vector2(220, 16)), 11, GOLD)
	draw_set_transform(Vector2.ZERO)

func _adesivo(tipo: String, r: Rect2) -> void:
	var print_data: Dictionary = p.get("label_work", {}).get("printed", {})
	ART.paper(self, r, Color("f8e18e") if tipo == "discount" else Color("ddd7bd"))
	if tipo == "discount":
		var percentuale := int(print_data.get("rate", 0))
		_testo("-%d%%" % percentuale if percentuale > 0 else B.cash(int(print_data.get("each", 0))), Rect2(r.position + Vector2(5, 8), r.size - Vector2(10, 10)), 32 if percentuale > 0 else 22, INK)
	else:
		var testo := "MINIMO %d · %s l'uno\nBase: %s %s" % [int(print_data.get("units", 1)), B.cash(int(print_data.get("each", 0))), "oggi" if int(print_data.get("reference", 0)) == 0 else "futuro", B.cash(int(print_data.get("ref", 0)))]
		_testo(testo, r.grow(-6), 10, INK)
	if in_mano == tipo: draw_rect(r.grow(1), MINT, false, 2)

func _draw_cassa() -> void:
	var r := rett("Cassa")
	ART.panel(self, r, Color("44545e"))
	_testo("PROVA CASSA", Rect2(r.position + Vector2(8, 6), r.size), 11, MINT)
	var monitor := Rect2(r.position + Vector2(7, 27), Vector2(136, 67))
	ART.panel(self, monitor, Color("172b30"))
	_testo(B.cash(int(v.get("basket", 0))), Rect2(monitor.position + Vector2(7, 6), Vector2(122, 25)), 19, GOLD)
	_testo("%d × %s" % [int(v.get("units", 1)), B.cash(int(v.get("each", 0)))], Rect2(monitor.position + Vector2(7, 37), Vector2(122, 18)), 11)
	for i in int(v.get("units", 1)): _prodotto(Rect2(r.position + Vector2(18 + i * 60, 99), Vector2(46, 50)))
	_testo("Costo reale", Rect2(r.position + Vector2(8, 151), Vector2(132, 20)), 10)
	var cliente := Assets.character("char_05").get_frame_texture("idle_left", 0)
	draw_texture_rect(cliente, Rect2(r.end.x - 22, r.end.y - 34, 16, 32), false)

func _draw_conferma() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.8))
	ART.panel(self, Rect2(92, 94, 456, 172), Color("293642"))
	_testo("CONDIZIONI FUORI DAL CARTELLINO", Rect2(112, 109, 416, 27), 15, GOLD)
	_testo("Il cliente vede la promozione.\nQuantità e base restano al terminale.", Rect2(112, 145, 416, 37), 13)
	for nome in ["Indietro", "Applica"]:
		var r := rett("Conferma/" + nome)
		ART.panel(self, r, Color("344550"))
		_testo("TORNA AL BANCO" if nome == "Indietro" else "APPLICA COSÌ", r.grow(-11), 12)
