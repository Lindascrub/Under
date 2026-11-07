extends Node2D
## Manipolazione dei documenti; regole, dati e premi restano in boss_missions.gd.
signal richiesta(azione: String, dati: Dictionary)
const B := preload("res://scripts/boss_missions.gd")
const ART := preload("res://scripts/minigame_art.gd")
const PAPER := Color("eee4cc")
const GOLD := Color("ffe14d")
const MINT := Color("67d1c2")
const INK := Color("241d32")
const TIMBRI := ["CONTI", "PERSONALE", "RICHIEDI\nDOCUMENTI", "RISOLTA"]
const IMPRONTE := ["ALLA CONTABILITÀ", "AL PERSONALE", "IN ATTESA", "RISOLTA"]
var p: Dictionary = {}
var avviso := ""
var documento := 0
var campi: Array = []
var posati: Array = []
var timbro := -1
var in_mano := ""
var premuto := ""
var origine := Vector2.ZERO
var cursore := Vector2.ZERO
var trascina := false
var fuoco := 0
var conferma_aperta := false
var dettagli_aperti := false
var consegnando := false
var scatto := 0.0
var carta_volante := -1
var carta_da := Vector2.ZERO
var carta_a := Vector2.ZERO
var volo := 1.0
var spostamento := Vector2.ZERO
var titoli := ["Rimborso trasporti", "Ercole · anzianità e pause", "Cambio turno", "Rimborso lampadine"]
var stato_breve := ["Pagamento già ricevuto.", "Ercole aspetta ancora una risposta.", "Manca l'autorizzazione del Personale.", "Nessun rimborso pagato."]

func aggiorna(stato: Dictionary, messaggio: String) -> void:
	p = stato
	var nuovo := mini(3, int(p.get("document", 0)))
	if nuovo != documento:
		in_mano = ""
		conferma_aperta = false
		dettagli_aperti = false
	documento = nuovo
	campi = B.document_pieces(documento)
	posati = B.document_placed(p)
	timbro = B.document_stamp(p)
	avviso = messaggio
	queue_redraw()

func rett(nome: String) -> Rect2:
	return get_node(nome).get_global_rect()

func rett_sagoma(i: int) -> Rect2:
	return rett("Fascicolo/Sagoma%d" % i)

func rett_carta(i: int) -> Rect2:
	return rett_sagoma(i) if i in posati else rett("Tavolo/Foglio%d" % i)

func bersagli() -> Array:
	if consegnando: return []
	if conferma_aperta:
		return [{"rect": rett("Conferma/Indietro"), "action": "fasc_indietro"}, {"rect": rett("Conferma/Chiudi"), "action": "fasc_chiudi"}]
	if dettagli_aperti: return [{"rect": rett("Dettagli/Chiudi"), "action": "fasc_dettagli"}]
	var out: Array = []
	for i in campi.size():
		if bool(campi[i]["available"]): out.append({"rect": rett_carta(i), "action": "fasc_carta_%d" % i})
	for i in campi.size():
		if i not in posati: out.append({"rect": rett_sagoma(i), "action": "fasc_sagoma_%d" % i})
	for i in 4: out.append({"rect": rett("Timbri/Timbro%d" % i), "action": "fasc_timbro_%d" % i})
	for nome in ["Fascicolo", "Consegna", "Dettagli", "Esci"]:
		out.append({"rect": rett(nome), "action": "fasc_" + nome.to_lower()})
	return out

func evidenzia(i: int) -> void:
	fuoco = i
	queue_redraw()

func naviga(i: int, direzione: Vector2) -> int:
	var targets := bersagli()
	if targets.is_empty(): return 0
	i = clampi(i, 0, targets.size() - 1)
	var da: Vector2 = targets[i]["rect"].get_center()
	var migliore := i
	var costo := INF
	for k in targets.size():
		var delta: Vector2 = targets[k]["rect"].get_center() - da
		var avanti := delta.dot(direzione)
		if avanti <= 8: continue
		var laterale := absf(delta.cross(direzione))
		var c := avanti + laterale * 3
		if c < costo:
			costo = c
			migliore = k
	return migliore

func tastiera(e: InputEvent) -> bool:
	if e.is_action_pressed("ui_cancel"):
		in_mano = ""
		conferma_aperta = false
		dettagli_aperti = false
		queue_redraw()
		return true
	return false

func attiva(azione: String) -> void:
	if consegnando: return
	if conferma_aperta:
		if azione == "indietro": conferma_aperta = false
		elif azione == "chiudi":
			conferma_aperta = false
			richiesta.emit("submit", {})
		queue_redraw()
		return
	if dettagli_aperti:
		if azione == "dettagli": dettagli_aperti = false
		return
	if azione == "dettagli": dettagli_aperti = true
	elif azione == "esci": richiesta.emit("exit", {})
	elif azione == "consegna":
		if timbro < 0: avviso = "Prendi un timbro e applicalo al fascicolo."
		elif documento == 1 and timbro == 3:
			conferma_aperta = true
			richiesta.emit("focus_confirm", {})
		else: richiesta.emit("submit", {})
	elif azione.begins_with("timbro_"):
		in_mano = "" if in_mano == azione else azione
		Sound.sfx("arcade/select_2")
	elif azione == "fascicolo" or azione.begins_with("sagoma_") or azione.begins_with("carta_"):
		if in_mano.begins_with("timbro_"):
			if azione.begins_with("carta_") and azione.trim_prefix("carta_").to_int() not in posati:
				avviso = "Il timbro va sul fascicolo, dopo aver sistemato i fogli."
			else: _applica_timbro(in_mano.trim_prefix("timbro_").to_int())
		elif in_mano.begins_with("carta_") and azione.begins_with("sagoma_"):
			_mettilo(in_mano.trim_prefix("carta_").to_int(), azione.trim_prefix("sagoma_").to_int())
		elif azione.begins_with("carta_"):
			in_mano = "" if in_mano == azione else azione
			Sound.sfx("arcade/select_2")
		elif azione.begins_with("sagoma_"):
			var i := azione.trim_prefix("sagoma_").to_int()
			avviso = str(campi[i].get("missing", "Metti qui il documento corrispondente."))
	queue_redraw()

func _mettilo(carta: int, sagoma: int) -> void:
	var prima := B.document_placed()
	var da := rett_carta(carta).get_center()
	richiesta.emit("place", {"piece": carta, "slot": sagoma})
	if carta not in prima and carta in B.document_placed():
		carta_volante = carta
		carta_da = da
		carta_a = rett_sagoma(carta).get_center()
		volo = 0
		create_tween().tween_property(self, "volo", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		Sound.sfx("select")
	in_mano = ""

func _applica_timbro(i: int) -> void:
	richiesta.emit("stamp", {"stamp": i})
	if timbro == i:
		scatto = 1
		create_tween().tween_property(self, "scatto", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Sound.sfx("stamp")
	in_mano = ""

func punta(pos: Vector2, fase: int) -> void:
	if consegnando: return
	cursore = pos
	if fase == 0:
		premuto = ""
		origine = pos
		trascina = false
		for b in bersagli():
			if b["rect"].has_point(pos):
				premuto = str(b["action"]).trim_prefix("fasc_")
				break
	elif fase == 1:
		trascina = trascina or pos.distance_to(origine) > 8
	elif fase == 2:
		var azione := premuto
		premuto = ""
		if trascina:
			if azione.begins_with("carta_"):
				var carta := azione.trim_prefix("carta_").to_int()
				var sagoma := -1
				for i in campi.size():
					if rett_sagoma(i).has_point(pos): sagoma = i
				if sagoma >= 0: _mettilo(carta, sagoma)
				elif rett("Tavolo").has_point(pos): richiesta.emit("remove", {"piece": carta})
			elif azione.begins_with("timbro_") and rett("Fascicolo").has_point(pos):
				_applica_timbro(azione.trim_prefix("timbro_").to_int())
		elif azione != "" and pos.distance_to(origine) < 16: attiva(azione)
		trascina = false
		queue_redraw()

func anima_consegna() -> void:
	consegnando = true
	in_mano = ""
	var tw := create_tween()
	tw.tween_property(self, "spostamento", Vector2(0, -20), 0.1).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "spostamento", Vector2(0, 300), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
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
				if y <= r.end.y: draw_string(font, Vector2(r.position.x, y), linea.strip_edges(), HORIZONTAL_ALIGNMENT_LEFT, -1, size, colore)
				y += size + 2
				linea = parola
			else: linea = prova
		if y <= r.end.y: draw_string(font, Vector2(r.position.x, y), linea.strip_edges(), HORIZONTAL_ALIGNMENT_LEFT, -1, size, colore)
		y += size + 2

func _icona(i: int, at: Vector2, vuoto := false) -> void:
	var colore := Color("827d78") if vuoto else Color("34354a")
	match str(campi[i]["kind"]):
		"ricevuta", "fattura":
			draw_rect(Rect2(at + Vector2(-14, -16), Vector2(28, 32)), colore, false, 2)
			for y in [-9, -2, 5]: draw_line(at + Vector2(-9, y), at + Vector2(9, y), colore, 2)
			if not vuoto: draw_rect(Rect2(at + Vector2(4, 9), Vector2(7, 5)), Color("49896f"))
		"registro":
			draw_rect(Rect2(at + Vector2(-18, -15), Vector2(36, 30)), colore, false, 2)
			for x in [-7, 4]: draw_line(at + Vector2(x, -13), at + Vector2(x, 13), colore, 1)
			for y in [-5, 4]: draw_line(at + Vector2(-16, y), at + Vector2(16, y), colore, 1)
		"acquisto": ART.bulb(self, at, "buona", 1, true)
		"firma":
			draw_polyline(PackedVector2Array([at + Vector2(-18, 7), at + Vector2(-8, -9), at + Vector2(-12, 6), at + Vector2(0, -3), at + Vector2(3, 7), at + Vector2(18, -1)]), colore, 2)
			_testo(str(i + 1), Rect2(at + Vector2(15, -20), Vector2(15, 14)), 11, colore)
		"domanda":
			draw_rect(Rect2(at + Vector2(-13, -16), Vector2(26, 32)), colore, false, 2)
			for y in [-9, -3]: draw_line(at + Vector2(-8, y), at + Vector2(9, y), colore, 2)
			draw_polyline(PackedVector2Array([at + Vector2(-8, 9), at + Vector2(-2, 3), at + Vector2(3, 10), at + Vector2(9, 4)]), colore, 2)
		"conferma":
			draw_circle(at, 18, colore, false, 2)
			draw_polyline(PackedVector2Array([at + Vector2(-10, 0), at + Vector2(-2, 9), at + Vector2(12, -9)]), colore, 3)

func _carta(i: int, r: Rect2) -> void:
	draw_rect(Rect2(r.position + Vector2(3, 3), r.size), Color(0, 0, 0, 0.25))
	ART.paper(self, r, PAPER)
	_icona(i, r.get_center() - Vector2(0, 6))
	_testo(str(campi[i]["name"]), Rect2(r.position + Vector2(8, r.size.y - 25), r.size - Vector2(16, 0)), 10, INK)
	if in_mano == "carta_%d" % i: draw_rect(r.grow(2), MINT, false, 2)

func _timbro(i: int, r: Rect2, preso := false) -> void:
	var base := r.get_center() - Vector2(0, 10)
	ART.panel(self, r, Color("445151") if preso else Color("3e4146"))
	draw_rect(Rect2(base + Vector2(-11, -21), Vector2(22, 15)), INK)
	draw_rect(Rect2(base + Vector2(-8, -18), Vector2(16, 12)), Color("c59665"))
	draw_rect(Rect2(base + Vector2(-5, -8), Vector2(10, 16)), Color("ad784e"))
	draw_rect(Rect2(base + Vector2(-23, 4), Vector2(46, 13)), INK)
	draw_rect(Rect2(base + Vector2(-21, 5), Vector2(42, 7)), Color("c59665"))
	_testo(TIMBRI[i], Rect2(r.position + Vector2(4, r.size.y - 25), r.size - Vector2(8, 0)), 10)
	if preso: draw_rect(r, MINT, false, 2)

func _draw() -> void:
	ART.backdrop(self)
	_testo("CAPO · IL FASCICOLO INCOMPLETO", Rect2(16, 6, 608, 25), 18, GOLD)
	_testo("%s · %d / 4" % [titoli[documento], documento + 1], Rect2(16, 36, 608, 20), 13)
	ART.panel(self, Rect2(12, 64, 616, 253), Color("4c3f3b"), Color("8d7a67"))
	_testo("SUL TAVOLO", Rect2(25, 72, 150, 15), 10, MINT)
	for i in campi.size():
		if bool(campi[i]["available"]) and i not in posati:
			_carta(i, rett_carta(i))
	_draw_fascicolo()
	for i in 4: _timbro(i, rett("Timbri/Timbro%d" % i), in_mano == "timbro_%d" % i)
	for nome in ["Consegna", "Dettagli", "Esci"]:
		var r := rett(nome)
		ART.panel(self, r, Color("365b55") if nome == "Consegna" and timbro >= 0 else Color("293642"))
		_testo({"Consegna": "CONSEGNA", "Dettagli": "DETTAGLI", "Esci": "SALVA / ESCI"}[nome], Rect2(r.position + Vector2(8, 7), r.size - Vector2(16, 7)), 11, GOLD if nome == "Consegna" else PAPER)
	var aiuto := "Foglio, poi sagoma. Timbro, poi fascicolo."
	if not TouchControls.enabled: aiuto = "FRECCE e INVIO: fogli, sagome, timbri."
	if in_mano.begins_with("carta_"): aiuto = "Scegli la sagoma dello stesso documento."
	elif in_mano.begins_with("timbro_"): aiuto = "Appoggia il timbro sul fascicolo."
	if avviso != "": aiuto = avviso
	_testo(aiuto, Rect2(116, 331, 388, 28), 10, GOLD if avviso != "" else PAPER)
	var targets := bersagli()
	if not TouchControls.enabled and fuoco >= 0 and fuoco < targets.size(): draw_rect(targets[fuoco]["rect"].grow(2), GOLD, false, 1)
	if carta_volante >= 0 and volo < 1:
		_carta(carta_volante, Rect2(carta_da.lerp(carta_a, volo) - Vector2(54, 38), Vector2(108, 76)))
	if trascina:
		if premuto.begins_with("carta_"):
			_carta(premuto.trim_prefix("carta_").to_int(), Rect2(cursore - Vector2(54, 38), Vector2(108, 76)))
		elif premuto.begins_with("timbro_"):
			_timbro(premuto.trim_prefix("timbro_").to_int(), Rect2(cursore - Vector2(36, 35), Vector2(72, 70)), true)
	if conferma_aperta: _draw_conferma()
	if dettagli_aperti: _draw_dettagli()

func _draw_fascicolo() -> void:
	draw_set_transform(spostamento)
	var r := rett("Fascicolo")
	draw_rect(Rect2(r.position + Vector2(-4, -5), Vector2(92, 18)), Color("b28b59"))
	ART.panel(self, r, Color("bc9b6b"), Color("e0c79c"))
	_testo(str(B.DOCUMENTS[documento]["id"]), Rect2(r.position + Vector2(14, 8), Vector2(180, 19)), 16, INK)
	_testo(stato_breve[documento], Rect2(r.position + Vector2(14, 33), Vector2(r.size.x - 38, 34)), 11, INK)
	if documento == 1:
		var frames := Assets.character(str(GameState.npc_data("ercole").get("sheet", "char_08")))
		draw_texture_rect(frames.get_frame_texture("idle_down", 0), Rect2(418, 88, 16, 32), false)
	for i in campi.size():
		var s := rett_sagoma(i)
		if i in posati and not (carta_volante == i and volo < 1): _carta(i, s)
		else:
			draw_rect(s, Color("9b835f"))
			for x in range(int(s.position.x), int(s.end.x), 10):
				for y in [s.position.y, s.end.y - 2]: draw_rect(Rect2(x, y, 5, 2), PAPER)
			for y in range(int(s.position.y), int(s.end.y), 10):
				for x in [s.position.x, s.end.x - 2]: draw_rect(Rect2(x, y, 2, 5), PAPER)
			_icona(i, s.get_center() - Vector2(0, 13), true)
			_testo(str(campi[i]["name"]), Rect2(s.position + Vector2(7, 65), s.size - Vector2(14, 0)), 10, INK)
			if not bool(campi[i]["available"]):
				_testo("MANCANTE", Rect2(s.position + Vector2(7, 90), s.size - Vector2(14, 0)), 10, Color("6d3237"))
	if timbro >= 0:
		var impronta := Rect2(r.position + Vector2(14, r.size.y - 38), Vector2(r.size.x - 28, 29)).grow(scatto * 3)
		draw_rect(impronta, Color("613d53"), false, 2)
		_testo(IMPRONTE[timbro], impronta.grow(-7), 13, Color("613d53"))
	else:
		_testo("APPLICA QUI IL TIMBRO", Rect2(r.position + Vector2(17, r.size.y - 29), Vector2(r.size.x - 34, 20)), 10, Color("6d5949"))
	draw_set_transform(Vector2.ZERO)

func _draw_conferma() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.8))
	ART.panel(self, Rect2(92, 95, 456, 170), Color("293642"))
	_testo("IL REGISTRO NON C'È.", Rect2(112, 110, 416, 28), 18, GOLD)
	_testo("RISOLTA chiude la domanda.\nErcole resta senza risposta.", Rect2(112, 145, 416, 38), 13)
	for nome in ["Indietro", "Chiudi"]:
		var r := rett("Conferma/" + nome)
		ART.panel(self, r, Color("344550"))
		_testo("TORNA AL TAVOLO" if nome == "Indietro" else "CHIUDI E-27", r.grow(-12), 12)

func _draw_dettagli() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.8))
	ART.paper(self, Rect2(96, 72, 448, 218), PAPER)
	_testo(str(B.DOCUMENTS[documento]["id"]) + " · DETTAGLI", Rect2(114, 88, 412, 27), 17, INK)
	_testo(str(B.DOCUMENTS[documento]["body"]), Rect2(114, 128, 412, 95), 13, INK)
	var r := rett("Dettagli/Chiudi")
	ART.panel(self, r, Color("344550"))
	_testo("TORNA AL TAVOLO", r.grow(-11), 12)
