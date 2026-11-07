extends Node2D
signal richiesta(azione: String, dati: Dictionary)
const B := preload("res://scripts/boss_missions.gd")
const ART := preload("res://scripts/minigame_art.gd")
const PAPER := Color("eee4cc")
const INK := Color("241d32")
const GOLD := Color("ffe14d")
const MINT := Color("67d1c2")
var p: Dictionary = {}
var v: Dictionary = {}
var avviso := ""
var in_mano := false
var premuto := ""
var origine := Vector2.ZERO
var cursore := Vector2.ZERO
var trascina := false
var fuoco := 0
var conferma_aperta := false
var consegnando := false
var mesi_visivi := 24.0
var mese_precedente := -1
var tween_mesi: Tween
var totale_precedente := -1
var verso_totale := 0
var impulso := 0.0
var spostamento := Vector2.ZERO
var riepilogo_interno := ""

func aggiorna(stato: Dictionary, messaggio: String) -> void:
	p = stato
	v = B.contract_preview(p)
	avviso = messaggio
	var mesi := int(p.get("months", 24))
	if mese_precedente < 0: mesi_visivi = mesi
	elif mesi != mese_precedente:
		if tween_mesi != null and tween_mesi.is_valid(): tween_mesi.kill()
		tween_mesi = create_tween()
		tween_mesi.tween_property(self, "mesi_visivi", float(mesi), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	mese_precedente = mesi
	if totale_precedente >= 0 and int(v.total) != totale_precedente:
		verso_totale = 1 if int(v.total) > totale_precedente else -1
		impulso = 0.55
	totale_precedente = int(v.total)
	riepilogo_interno = "Interessi %s\nSpesa iniziale %d €\nUltima rata %s\nTOTALE %s" % [B.cash(int(v.interest)), int(v.fee), B.cash(int(v.last)), B.cash(int(v.total))]
	queue_redraw()

func rett(nome: String) -> Rect2:
	return get_node(nome).get_global_rect()

func maniglia() -> Rect2:
	return Rect2(28 + roundf(mesi_visivi * 9) - 13, 88, 26, 48)

func rett_riepilogo() -> Rect2:
	return rett("Riepilogo") if bool(p.get("visible", true)) else rett("Interno/Tasca")

func bersagli() -> Array:
	if consegnando: return []
	if conferma_aperta:
		return [{"rect": rett("Conferma/Indietro"), "action": "loan_indietro"}, {"rect": rett("Conferma/Invia"), "action": "loan_conferma"}]
	var out: Array = [{"rect": maniglia(), "action": "loan_months"}]
	for mesi in [12, 24, 36]:
		out.append({"rect": rett("Calendario/Anno%d" % (mesi / 12)), "action": "loan_year_%d" % mesi})
	out.append({"rect": rett_riepilogo(), "action": "loan_summary"})
	for nome in ["Tasso", "Spesa", "Interno", "Olga", "Invia", "Esci"]:
		out.append({"rect": rett(nome), "action": "loan_" + nome.to_lower()})
	return out

func evidenzia(i: int) -> void:
	fuoco = i
	queue_redraw()

func naviga(i: int, direzione: Vector2) -> int:
	var targets := bersagli()
	if targets.is_empty(): return 0
	i = clampi(i, 0, targets.size() - 1)
	var da: Vector2 = targets[i].rect.get_center()
	var best := i
	var costo := INF
	for k in targets.size():
		var delta: Vector2 = targets[k].rect.get_center() - da
		var avanti := delta.dot(direzione)
		if avanti <= 8: continue
		var c := avanti + absf(delta.cross(direzione)) * 3
		if c < costo:
			costo = c
			best = k
	return best

func tastiera(e: InputEvent) -> bool:
	if e.is_action_pressed("ui_cancel"):
		in_mano = false
		conferma_aperta = false
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
	match azione:
		"months": richiesta.emit("set", {"key": "months", "value": [12, 24, 36][posmod([12, 24, 36].find(int(p.get("months", 24))) + 1, 3)]})
		"tasso": richiesta.emit("set", {"key": "apr", "value": [4, 8, 12][posmod([4, 8, 12].find(int(p.get("apr", 4))) + 1, 3)]})
		"spesa": richiesta.emit("set", {"key": "fee", "value": posmod(int(p.get("fee", 0)) + 60, 180)})
		"summary": in_mano = not in_mano
		"interno":
			if in_mano:
				richiesta.emit("copy", {"visible": false})
				in_mano = false
			elif not bool(p.get("visible", true)): in_mano = true
		"olga":
			if in_mano:
				richiesta.emit("copy", {"visible": true})
				in_mano = false
		"invia":
			if int(v.get("monthly", 0)) > 6500: avviso = "La rata supera 65 €. Prova ad allungare il calendario."
			else:
				conferma_aperta = true
				richiesta.emit("focus_confirm", {})
		"esci": richiesta.emit("exit", {})
		_:
			if azione.begins_with("year_"): richiesta.emit("set", {"key": "months", "value": azione.trim_prefix("year_").to_int()})
	queue_redraw()

func _mesi_al_punto(pos: Vector2) -> int:
	return clampi(int(round((pos.x - 28) / 108.0)), 1, 3) * 12

func punta(pos: Vector2, fase: int) -> void:
	if consegnando: return
	cursore = pos
	if fase == 0:
		premuto = ""
		origine = pos
		trascina = false
		for b in bersagli():
			if b.rect.has_point(pos):
				premuto = str(b.action).trim_prefix("loan_")
				break
	elif fase == 1:
		trascina = trascina or pos.distance_to(origine) > 8
		if trascina and (premuto == "months" or premuto.begins_with("year_")):
			var mesi := _mesi_al_punto(pos)
			if mesi != int(p.get("months", 24)): richiesta.emit("set", {"key": "months", "value": mesi})
	elif fase == 2:
		var azione := premuto
		premuto = ""
		if trascina:
			if azione == "summary" or (azione == "interno" and not bool(p.get("visible", true))):
				if rett("Interno").has_point(pos): richiesta.emit("copy", {"visible": false})
				elif rett("Olga").has_point(pos): richiesta.emit("copy", {"visible": true})
				in_mano = false
		elif azione != "" and pos.distance_to(origine) < 16: attiva(azione)
		trascina = false
		queue_redraw()

func anima_invio() -> void:
	consegnando = true
	in_mano = false
	var tw := create_tween()
	tw.tween_property(self, "spostamento", Vector2(0, -8), 0.1).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "spostamento", Vector2(320, -80), 0.23).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	spostamento = Vector2.ZERO
	consegnando = false

func _process(dt: float) -> void:
	impulso = maxf(0, impulso - dt)
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

func _draw() -> void:
	ART.backdrop(self)
	_testo("CAPO · IL CALENDARIO DI OLGA", Rect2(16, 6, 608, 26), 18, GOLD)
	_testo("Nuovo prestito: 1.200 € · in più al mutuo.", Rect2(16, 35, 608, 20), 13)
	ART.panel(self, Rect2(12, 64, 616, 255), Color("454246"), Color("968f7c"))
	_draw_calendario()
	_draw_rata()
	_draw_controlli()
	_draw_copie()
	var invia := rett("Invia")
	ART.panel(self, invia, Color("365b55") if int(v.get("monthly", 0)) <= 6500 else Color("51454b"))
	_testo("INVIA PROPOSTA", Rect2(invia.position + Vector2(10, 8), invia.size - Vector2(20, 8)), 11, GOLD)
	var esci := rett("Esci")
	ART.panel(self, esci, Color("293642"))
	_testo("SALVA/ESCI", Rect2(esci.position + Vector2(8, 8), esci.size - Vector2(16, 8)), 11)
	var aiuto := "Allunga il calendario. Confronta rata e totale."
	if not TouchControls.enabled: aiuto = "FRECCE e INVIO: usa. Trascina il bordo del calendario."
	if in_mano: aiuto = "Scegli la copia in cui lasciare il riepilogo."
	if avviso != "": aiuto = avviso
	_testo(aiuto, Rect2(16, 332, 314, 27), 10, GOLD if avviso != "" else PAPER)
	var targets := bersagli()
	if not TouchControls.enabled and fuoco >= 0 and fuoco < targets.size(): draw_rect(targets[fuoco].rect.grow(2), GOLD, false, 1)
	if trascina and premuto == "summary":
		_draw_riepilogo(Rect2(cursore - Vector2(142, 33), Vector2(284, 66)))
	if conferma_aperta: _draw_conferma()

func _draw_calendario() -> void:
	ART.panel(self, rett("Calendario"), Color("4b6070"))
	_testo("%d MESI" % int(p.get("months", 24)), Rect2(28, 73, 342, 19), 14)
	var quanti := clampi(int(round(mesi_visivi)), 12, 36)
	for i in 36:
		var r := Rect2(28 + i * 9, 97, 8, 29)
		if i < quanti:
			draw_rect(r, PAPER if (i / 12) % 2 == 0 else Color("c5d4ca"))
			draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(6, 5)), Color("856d70"))
		else: draw_rect(r, Color("344750"), false, 1)
	for i in 3: _testo(str((i + 1) * 12), Rect2(104 + i * 108, 127, 28, 16), 10)
	var bordo := maniglia()
	ART.panel(self, bordo, Color("7caaa0"))
	for dx in [-3, 3]: draw_line(bordo.get_center() + Vector2(dx, -9), bordo.get_center() + Vector2(dx, 9), INK, 1)

func _draw_rata() -> void:
	var r := rett("Rata")
	ART.panel(self, r, Color("293e46"))
	_testo("RATA AL MESE", Rect2(r.position + Vector2(10, 5), r.size), 11, MINT)
	_testo(B.cash(int(v.get("monthly", 0))), Rect2(r.position + Vector2(10, 23), Vector2(188, 32)), 23, GOLD)
	_testo("Disponibili: 65 €", Rect2(r.position + Vector2(10, 56), Vector2(188, 17)), 11)
	var barra := Rect2(r.position + Vector2(10, 78), Vector2(180, 9))
	draw_rect(barra, INK)
	var quota := clampf(float(v.get("monthly", 0)) / 12000.0, 0, 1)
	draw_rect(Rect2(barra.position, Vector2(roundf(barra.size.x * quota), barra.size.y)), MINT if int(v.get("monthly", 0)) <= 6500 else Color("db9b72"))
	var limite := barra.position.x + barra.size.x * 6500.0 / 12000.0
	draw_line(Vector2(limite, barra.position.y - 3), Vector2(limite, barra.end.y + 3), PAPER, 2)
	_testo("ENTRO IL LIMITE" if int(v.get("monthly", 0)) <= 6500 else "OLTRE IL LIMITE", Rect2(r.position + Vector2(10, 94), Vector2(188, 15)), 10)

func _draw_controlli() -> void:
	for nome in ["Tasso", "Spesa"]:
		var r := rett(nome)
		ART.panel(self, r, Color("344550"))
		if nome == "Tasso":
			draw_circle(r.position + Vector2(16, 16), 10, Color("aab8ae"))
			var a := -PI / 2 + [4, 8, 12].find(int(p.get("apr", 4))) * TAU / 3
			draw_line(r.position + Vector2(16, 16), r.position + Vector2(16, 16) + Vector2(cos(a), sin(a)) * 8, INK, 2)
			_testo("Tasso annuo %d%%" % int(p.get("apr", 4)), Rect2(r.position + Vector2(32, 8), r.size - Vector2(38, 8)), 11)
		else:
			draw_circle(r.position + Vector2(16, 16), 9, GOLD)
			draw_circle(r.position + Vector2(16, 16), 6, INK, false, 1)
			_testo("Spesa iniziale %d €" % int(p.get("fee", 0)), Rect2(r.position + Vector2(32, 8), r.size - Vector2(38, 8)), 10)

func _draw_copie() -> void:
	var interno := rett("Interno")
	ART.paper(self, interno)
	_testo("COPIA INTERNA", Rect2(28, 202, 200, 16), 11, INK)
	_testo("Rata %s · %d mesi" % [B.cash(int(v.get("monthly", 0))), int(v.get("months", 24))], Rect2(28, 221, 200, 17), 11, INK)
	_testo("Interessi %s\nSpesa iniziale %d €\nUltima rata %s" % [B.cash(int(v.get("interest", 0))), int(v.get("fee", 0)), B.cash(int(v.get("last", 0)))], Rect2(28, 241, 200, 38), 10, INK)
	_testo("TOTALE " + B.cash(int(v.get("total", 0))), Rect2(28, 285, 205, 24), 16, INK)
	_draw_monete()
	var tasca := rett("Interno/Tasca")
	draw_rect(tasca, Color("ad9c7d"))
	draw_rect(Rect2(tasca.position + Vector2(3, 15), Vector2(tasca.size.x - 6, 4)), INK)
	_testo("TASCA", Rect2(tasca.position + Vector2(6, 25), tasca.size), 9, INK)
	if not bool(p.get("visible", true)):
		ART.paper(self, Rect2(tasca.position + Vector2(4, 1), Vector2(tasca.size.x - 8, 22)), PAPER)
		for y in [7, 12, 17]: draw_line(tasca.position + Vector2(10, y), tasca.position + Vector2(47, y), Color("8f8c7c"), 1)
	draw_set_transform(spostamento)
	ART.paper(self, rett("Olga"))
	_testo("COPIA PER OLGA", Rect2(332, 202, 250, 16), 11, INK)
	_testo("Rata %s · %d mesi" % [B.cash(int(v.get("monthly", 0))), int(v.get("months", 24))], Rect2(332, 222, 264, 17), 11, INK)
	if bool(p.get("visible", true)): _draw_riepilogo(rett("Riepilogo"))
	else:
		_testo("Il riepilogo dei costi\nresta nella copia interna.", Rect2(336, 255, 264, 40), 12, Color("6b4c50"))
	var persona := Assets.character(str(GameState.npc_data("olga").get("sheet", "char_09"))).get_frame_texture("idle_left", 0)
	draw_texture_rect(persona, Rect2(602, 198, 16, 32), false)
	draw_set_transform(Vector2.ZERO)
	if in_mano: draw_rect(rett_riepilogo().grow(1), MINT, false, 2)

func _draw_riepilogo(r: Rect2) -> void:
	ART.paper(self, r, Color("ddd6bb"))
	_testo("TOTALE " + B.cash(int(v.get("total", 0))), Rect2(r.position + Vector2(7, 3), r.size - Vector2(14, 3)), 15, INK)
	_testo("Interessi %s · Spesa iniziale %d €\nUltima rata %s" % [B.cash(int(v.get("interest", 0))), int(v.get("fee", 0)), B.cash(int(v.get("last", 0)))], Rect2(r.position + Vector2(7, 25), r.size - Vector2(14, 25)), 10, INK)

func _draw_monete() -> void:
	var alto := int(round(float(v.get("total", 120000)) / 180000.0 * 72))
	var base := Vector2(260, 305)
	var capitale := int(round(120000.0 / 180000.0 * 72))
	for y in range(0, alto, 4):
		var colore := Color("b8b9a6") if y < capitale else Color("e8bc63")
		draw_rect(Rect2(base + Vector2(-16, -y - 4), Vector2(32, 4)), INK)
		draw_rect(Rect2(base + Vector2(-15, -y - 4), Vector2(30, 2)), colore)
	if impulso > 0:
		var centro := base + Vector2(25, -alto / 2.0)
		draw_line(centro + Vector2(0, -8), centro + Vector2(0, 8), GOLD, 2)
		var punta := centro + Vector2(0, -8 if verso_totale > 0 else 8)
		draw_line(punta, punta + Vector2(-4, 5 if verso_totale > 0 else -5), GOLD, 2)
		draw_line(punta, punta + Vector2(4, 5 if verso_totale > 0 else -5), GOLD, 2)

func _draw_conferma() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.8))
	ART.panel(self, Rect2(92, 92, 456, 176), Color("293642"))
	_testo("INVIARE QUESTA PROPOSTA?", Rect2(112, 106, 416, 28), 18, GOLD)
	var testo := "%s al mese · %d mesi.\n" % [B.cash(int(v.get("monthly", 0))), int(v.get("months", 24))]
	if bool(p.get("visible", true)): testo += "Totale %s, riepilogo completo.\n" % B.cash(int(v.get("total", 0)))
	else: testo += "Olga non riceve il riepilogo dei costi.\n"
	testo += "Olga deciderà se accettare."
	_testo(testo, Rect2(112, 145, 416, 48), 12)
	for nome in ["Indietro", "Invia"]:
		var r := rett("Conferma/" + nome)
		ART.panel(self, r, Color("344550"))
		_testo("RIVEDI" if nome == "Indietro" else "INVIA PROPOSTA", r.grow(-11), 12)
