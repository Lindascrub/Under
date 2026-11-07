extends Node2D
## Oggetti sul tavolo; scripts/boss_missions.gd possiede tutti i dati e le conseguenze.
signal richiesta(azione: String, dati: Dictionary)

const B := preload("res://scripts/boss_missions.gd")
const ART := preload("res://scripts/minigame_art.gd")
const CASA := preload("res://assets/limezu/buildings/home.png")
const VETRO := preload("res://art/c5/vetrina_rotta.png")
const INSEGNA := preload("res://art/c5/insegna_casa_comune.png")
const CARTELLO := preload("res://art/c5/cartello_protesta.png")
const PAPER := Color("eee4cc")
const GOLD := Color("ffe14d")
const MINT := Color("65d8c2")
const INK := Color("171d2a")

var p: Dictionary = {}
var fonti: Array = []
var messaggio := ""
var bersaglio := 0
var tipo_fuoco := "fonte"
var clip_fuoco := -1
var utensile := ""
var premuto := ""
var origine := Vector2.ZERO
var dito := Vector2.ZERO
var trascina := false
var conferma_aperta := false
var riproduzione := false
var riproduzione_indice := 0
var riproduzione_tempo := 0.0
var didascalia := ""
var contesto_originale := ""
var testo_anteprima := ""
var animazione_taglio := 0.0

func aggiorna(stato: Dictionary, avviso: String) -> void:
	p = stato
	fonti = B.news_sources()
	messaggio = avviso
	clip_fuoco = mini(clip_fuoco, p.get("clips", []).size() - 1)
	if tipo_fuoco == "clip" and clip_fuoco < 0: tipo_fuoco = "fonte"
	_aggiorna_testi()
	queue_redraw()

func rett(nome: String) -> Rect2:
	return get_node(nome).get_global_rect()

func rett_fonte(i: int) -> Rect2:
	return rett("Fonti/Fonte%d" % i)

func clips() -> Array:
	return p.get("clips", [])

func rett_clip(i: int) -> Rect2:
	var x := rett("Timeline").position.x + 4
	for j in i: x += float(clips()[j]["duration"]) * 10.0
	return Rect2(x, 299, float(clips()[i]["duration"]) * 10.0 - 2, 25)

func fonte_corrente() -> Dictionary:
	if fonti.is_empty(): return {}
	var indice := riproduzione_indice if riproduzione else clip_fuoco
	if (riproduzione or tipo_fuoco == "clip") and indice >= 0 and indice < clips().size():
		for fonte: Dictionary in fonti:
			if fonte["id"] == clips()[indice]["id"]: return fonte
	return fonti[posmod(int(p.get("source", 0)), fonti.size())]

func inquadratura() -> Dictionary:
	if (riproduzione and bool(p.get("facts", false)) and riproduzione_indice == clips().size()) or tipo_fuoco == "fatti":
		return {"id": "facts", "who": "Fatti verificati", "cut": false, "broadcast_quote": "La Casa rischia la chiusura.\nLa vetrina è rotta.\nL'autore del danno è ignoto.", "context": ""}
	if riproduzione and not clips().is_empty():
		return clips()[posmod(riproduzione_indice, clips().size())]
	if tipo_fuoco == "clip" and clip_fuoco >= 0 and clip_fuoco < clips().size():
		return clips()[clip_fuoco]
	var s := fonte_corrente().duplicate()
	if not s.is_empty():
		s["cut"] = bool(p.get("cut", false))
		s["broadcast_quote"] = B.cut_quote(s) if s["cut"] else s["quote"]
		s["headline"] = B.cut_headline(str(s["id"])) if s["cut"] else ""
	return s

func _aggiorna_testi() -> void:
	var s := fonte_corrente()
	didascalia = str(s.get("quote", ""))
	contesto_originale = str(s.get("context", ""))
	var v := inquadratura()
	testo_anteprima = str(v.get("broadcast_quote", ""))
	if not bool(v.get("cut", false)):
		testo_anteprima += "\n" + str(v.get("context", ""))

func bersagli() -> Array:
	if conferma_aperta:
		return [{"rect": rett("Conferma/Indietro"), "action": "mont_indietro"}, {"rect": rett("Conferma/Invia"), "action": "mont_invia"}]
	var out: Array = []
	for i in fonti.size(): out.append({"rect": rett_fonte(i), "action": "mont_fonte_%d" % i})
	for i in clips().size(): out.append({"rect": rett_clip(i), "action": "mont_clip_%d" % i})
	out.append({"rect": rett("Timeline"), "action": "mont_aggiungi"})
	for azione in ["taglia", "ripristina", "fatti", "anteprima", "trasmetti", "esci"]:
		out.append({"rect": rett(azione.capitalize()), "action": "mont_" + azione})
	return out

func evidenzia(i: int) -> void:
	bersaglio = i
	queue_redraw()

func attiva(azione: String) -> void:
	if conferma_aperta:
		if azione == "indietro": conferma_aperta = false
		elif azione == "invia":
			conferma_aperta = false
			richiesta.emit("broadcast", {})
		queue_redraw()
		return
	if azione.begins_with("fonte_"):
		tipo_fuoco = "fonte"
		riproduzione = false
		var i := azione.trim_prefix("fonte_").to_int()
		richiesta.emit("select", {"source": i})
		if utensile != "": _applica_utensile()
	elif azione.begins_with("clip_"):
		tipo_fuoco = "clip"
		clip_fuoco = azione.trim_prefix("clip_").to_int()
		riproduzione = false
		if utensile != "": _applica_utensile()
	elif azione in ["taglia", "ripristina"]:
		utensile = "" if utensile == azione else azione
		Sound.sfx("arcade/select_2")
	elif azione == "aggiungi":
		if tipo_fuoco == "fonte": richiesta.emit("insert", {"source": int(p.get("source", 0)), "index": clips().size()})
	elif azione == "fatti":
		richiesta.emit("facts", {})
		if bool(p.get("facts", false)): tipo_fuoco = "fatti"
		else: tipo_fuoco = "fonte"
	elif azione == "esci": richiesta.emit("exit", {})
	elif azione == "anteprima":
		if not clips().is_empty():
			if riproduzione:
				tipo_fuoco = "fatti" if riproduzione_indice == clips().size() else "clip"
				clip_fuoco = mini(riproduzione_indice, clips().size() - 1)
				riproduzione = false
			else:
				riproduzione = true
				riproduzione_indice = 0
				riproduzione_tempo = 0
		else: messaggio = "Metti una registrazione sulla pista."
	elif azione == "trasmetti":
		if clips().size() != 3: messaggio = "Servono le tre voci della piazza."
		else:
			conferma_aperta = true
			riproduzione = false
			richiesta.emit("focus_confirm", {})
	_aggiorna_testi()
	queue_redraw()

func _applica_utensile() -> void:
	var taglia := utensile == "taglia"
	richiesta.emit("edit" if tipo_fuoco == "clip" else "draft_cut", {"index": clip_fuoco, "cut": taglia})
	utensile = ""
	animazione_taglio = 0.25
	Sound.sfx("stamp" if taglia else "select")

func punta(pos: Vector2, fase: int) -> void:
	dito = pos
	if fase == 0:
		premuto = ""
		origine = pos
		trascina = false
		# La pista ampia viene dopo i singoli spezzoni nell'ordine dei bersagli.
		for b in bersagli():
			if b["rect"].has_point(pos):
				premuto = str(b["action"]).trim_prefix("mont_")
				break
	elif fase == 1:
		trascina = trascina or pos.distance_to(origine) > 8
	elif fase == 2:
		var azione := premuto
		premuto = ""
		if azione == "": return
		if trascina:
			if rett("Timeline").grow(0).has_point(pos):
				var indice := _inserimento(pos.x)
				if azione.begins_with("fonte_"):
					richiesta.emit("insert", {"source": azione.trim_prefix("fonte_").to_int(), "index": indice})
				elif azione.begins_with("clip_"):
					richiesta.emit("move", {"from": azione.trim_prefix("clip_").to_int(), "to": indice})
			elif rett("Fonti").has_point(pos) and azione.begins_with("clip_"):
				richiesta.emit("remove", {"index": azione.trim_prefix("clip_").to_int()})
		elif pos.distance_to(origine) < 16:
			attiva(azione)
		trascina = false
		queue_redraw()

func _inserimento(x: float) -> int:
	for i in clips().size():
		if x < rett_clip(i).get_center().x: return i
	return clips().size()

func tastiera(e: InputEvent) -> bool:
	if e.is_action_pressed("ui_cancel"):
		conferma_aperta = false
		utensile = ""
		premuto = ""
		return true
	if conferma_aperta or tipo_fuoco != "clip" or clip_fuoco < 0: return false
	if e is InputEventKey and e.pressed:
		if e.keycode in [KEY_DELETE, KEY_BACKSPACE]:
			richiesta.emit("remove", {"index": clip_fuoco})
			return true
		if e.shift_pressed and e.keycode in [KEY_LEFT, KEY_RIGHT]:
			var target := clip_fuoco - 1 if e.keycode == KEY_LEFT else clip_fuoco + 2
			var next := clampi(clip_fuoco + (-1 if e.keycode == KEY_LEFT else 1), 0, clips().size() - 1)
			richiesta.emit("move", {"from": clip_fuoco, "to": maxi(0, target)})
			clip_fuoco = next
			return true
	return false

func _process(dt: float) -> void:
	animazione_taglio = maxf(0, animazione_taglio - dt)
	if riproduzione and not clips().is_empty():
		riproduzione_tempo += dt
		if riproduzione_tempo > 5.5:
			riproduzione_indice += 1
			riproduzione_tempo = 0
			if riproduzione_indice >= clips().size() + (1 if bool(p.get("facts", false)) else 0):
				riproduzione = false
				riproduzione_indice = clips().size() - 1
				tipo_fuoco = "clip"
				clip_fuoco = riproduzione_indice
		_aggiorna_testi()
	queue_redraw()

func _testo(t: String, r: Rect2, size := 11, color := PAPER) -> void:
	var font := Assets.font()
	var y := r.position.y + size
	for paragrafo in t.split("\n"):
		var linea := ""
		for parola in paragrafo.split(" "):
			var prova := linea + (" " if linea != "" else "") + parola
			if font.get_string_size(prova, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > r.size.x and linea != "":
				draw_string(font, Vector2(r.position.x, y), linea, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
				y += size + 2
				linea = parola
			else: linea = prova
		if y <= r.end.y + 1: draw_string(font, Vector2(r.position.x, y), linea, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
		y += size + 2

func _film(r: Rect2, colore: Color) -> void:
	draw_rect(r, INK)
	draw_rect(r.grow(-2), colore)
	for x in range(int(r.position.x) + 5, int(r.end.x) - 4, 10):
		for y in [r.position.y + 2, r.end.y - 5]: draw_rect(Rect2(x, y, 5, 3), Color("10151e"))

func _persona(s: Dictionary, at: Vector2, scala: int) -> void:
	var sheet := "char_05"
	if str(s.get("id")) == "rina": sheet = str(GameState.npc_data("rina").get("sheet", "char_05"))
	elif str(s.get("who")) == "Ada": sheet = str(GameState.npc_data("ada").get("sheet", "char_19"))
	var frames := Assets.character(sheet)
	var texture: Texture2D = frames.get_frame_texture("idle_down", 0)
	draw_texture_rect(texture, Rect2(at - Vector2(8, 32) * scala, Vector2(16, 32) * scala), false)

func _immagine(s: Dictionary, r: Rect2, tagliato: bool) -> void:
	draw_rect(r, Color("94b3b7"))
	draw_rect(Rect2(r.position + Vector2(0, r.size.y * 0.7), Vector2(r.size.x, r.size.y * 0.3)), Color("787c7c"))
	var k := 2 if r.size.x > 130 else 1
	var base := Vector2(r.end.x - 6, r.end.y - 4)
	if str(s.get("id")) == "rina":
		draw_texture_rect(VETRO, Rect2(base - Vector2(32, 24) * k, Vector2(32, 24) * k), false)
	else:
		var casa := Rect2(base - Vector2(72, 40) * k, Vector2(72, 40) * k)
		draw_texture_rect_region(CASA, casa, Rect2(20, 240, 72, 40))
		if not tagliato and r.size.x > 130:
			draw_texture_rect(INSEGNA, Rect2(r.position + Vector2(8, 5), Vector2(78, 9)), false)
	_persona(s, Vector2(r.position.x + 20 * k, r.end.y - 2), k)
	if not tagliato:
		draw_texture_rect(CARTELLO, Rect2(r.position + Vector2(32 * k, 7), Vector2(16, 16) * k), false)
	else:
		draw_rect(r.grow(-1), Color("e17a70"), false, 2)

func _forbici(at: Vector2) -> void:
	for y in [-5, 5]: draw_circle(at + Vector2(-8, y), 5, GOLD, false, 2)
	draw_line(at + Vector2(-4, -3), at + Vector2(12, 8), PAPER, 2)
	draw_line(at + Vector2(-4, 3), at + Vector2(12, -8), PAPER, 2)

func _draw() -> void:
	_aggiorna_testi()
	ART.backdrop(self)
	draw_rect(Rect2(12, 58, 616, 271), Color("34313a"))
	_testo("CAPO · IL TAVOLO DI MONTAGGIO", Rect2(16, 7, 608, 24), 18, GOLD)
	_testo("Tre voci. Sessanta secondi di servizio.", Rect2(16, 35, 608, 18), 12)
	_testo("REGISTRAZIONI", Rect2(16, 59, 320, 14), 10, MINT)
	for i in fonti.size():
		var r := rett_fonte(i)
		_film(r, Color("4c5b63"))
		_immagine(fonti[i], Rect2(r.position + Vector2(5, 8), r.size - Vector2(10, 29)), false)
		_testo(str(fonti[i]["who"]), Rect2(r.position + Vector2(6, r.size.y - 18), r.size - Vector2(12, 0)), 11)
		if tipo_fuoco == "fonte" and i == int(p.get("source", 0)): draw_rect(r, MINT, false, 2)
		for c in clips():
			if c["id"] == fonti[i]["id"]: _testo("IN PISTA", Rect2(r.position + Vector2(5, 9), Vector2(90, 15)), 9, GOLD)
	var s := fonte_corrente()
	if s.is_empty():
		_testo("Le registrazioni si raccolgono in piazza.", Rect2(20, 160, 312, 50), 12)
	else:
		_testo("«" + didascalia + "»", Rect2(20, 156, 312, 43), 11)
		var ritaglio := Rect2(16, 201, 320, 33)
		draw_rect(ritaglio, Color("645747") if bool(inquadratura().get("cut", false)) else Color("36564f"))
		_testo(contesto_originale, ritaglio.grow(-4), 10)
		if bool(inquadratura().get("cut", false)):
			draw_line(ritaglio.position + Vector2(5, 1), ritaglio.position + Vector2(315, 1), GOLD, 2)
			_testo("SCARTO", Rect2(281, 189, 55, 12), 9, GOLD)
	_draw_tv()
	for nome in ["Taglia", "Ripristina", "Fatti", "Anteprima", "Trasmetti", "Esci"]:
		var r := rett(nome)
		var attivo: bool = (nome.to_lower() == utensile) or (nome == "Fatti" and bool(p.get("facts", false)))
		ART.panel(self, r, Color("3d645c") if attivo else Color("293642"))
		var titolo: String = {"Taglia": "FORBICI", "Ripristina": "RIMETTI", "Fatti": "FATTI · 10s", "Anteprima": "PAUSA" if riproduzione else "ANTEPRIMA", "Trasmetti": "TRASMETTI", "Esci": "SALVA / ESCI"}[nome]
		if nome == "Taglia":
			_forbici(r.position + Vector2(20, 17))
			_testo(titolo, Rect2(r.position + Vector2(38, 11), r.size), 10)
		else: _testo(titolo, Rect2(r.position + Vector2(9, 11), r.size), 11, GOLD if nome == "Trasmetti" else PAPER)
	_draw_pista()
	var aiuto := "Trascina un rullo sulla pista. FORBICI, poi uno spezzone: taglia."
	if not TouchControls.enabled:
		aiuto = "FRECCE / INVIO: scegli fonte, poi pista. Mouse: trascina."
		if tipo_fuoco == "clip": aiuto = "MAIUSC + FRECCE: ordine. CANC: togli. FORBICI: taglia."
	if utensile != "": aiuto = "Scegli lo spezzone: " + ("togli il contesto." if utensile == "taglia" else "rimetti il contesto.")
	if messaggio != "": aiuto = messaggio
	_testo(aiuto, Rect2(16, 332, 488, 27), 10, GOLD if messaggio != "" else PAPER)
	var targets := bersagli()
	if not TouchControls.enabled and bersaglio < targets.size() and bersaglio >= 0:
		draw_rect(targets[bersaglio]["rect"].grow(2), GOLD, false, 1)
	if trascina and premuto != "":
		var ghost := Rect2(dito - Vector2(36, 15), Vector2(72, 30))
		_film(ghost, Color("648783"))
		_testo("SPOSTA", ghost.grow(-8), 10)
	if animazione_taglio > 0: _forbici(Vector2(316, 197))
	if conferma_aperta: _draw_conferma()

func _draw_pista() -> void:
	var r := rett("Timeline")
	draw_rect(r, Color("121b23"))
	_testo("PISTA", Rect2(r.position + Vector2(4, 0), Vector2(60, 12)), 9, MINT)
	_testo("%d / 60 s" % B.news_time(p), Rect2(534, 282, 90, 13), 10, GOLD)
	for i in 7:
		var x := r.position.x + 4 + i * 100
		draw_line(Vector2(x, 295), Vector2(x, 326), Color("45525b"), 1)
	for i in clips().size():
		var clip: Dictionary = clips()[i]
		var cr := rett_clip(i)
		_film(cr, Color("845548") if bool(clip["cut"]) else Color("386d67"))
		_testo(str(clip["who"]), cr.grow(-7), 10)
		if bool(clip["cut"]):
			draw_line(cr.end - Vector2(10, 17), cr.end - Vector2(4, 8), GOLD, 2)
			draw_line(cr.end - Vector2(10, 8), cr.end - Vector2(4, 17), GOLD, 2)
		if tipo_fuoco == "clip" and i == clip_fuoco: draw_rect(cr, MINT, false, 2)
	if bool(p.get("facts", false)):
		var x := r.position.x + 4
		for c in clips(): x += float(c["duration"]) * 10
		_film(Rect2(x, 299, 98, 25), Color("596c81"))
		_testo("FATTI", Rect2(x + 8, 306, 84, 14), 10)
	if clips().is_empty(): _testo("Metti qui il primo spezzone", Rect2(182, 306, 320, 16), 11, Color("8fa4a9"))

func _draw_tv() -> void:
	var r := rett("Televisore")
	ART.panel(self, r, Color("121820"), Color("5b6c75"))
	var v := inquadratura()
	_testo("ANTEPRIMA" + (" · IN PLAY" if riproduzione else ""), Rect2(r.position + Vector2(10, 4), Vector2(246, 14)), 10, MINT)
	if v.is_empty(): return
	_immagine(v, Rect2(r.position + Vector2(10, 21), Vector2(246, 61)), bool(v.get("cut", false)))
	var nome := str(v.get("headline", "")) if bool(v.get("cut", false)) else str(v.get("who", ""))
	_testo(nome, Rect2(r.position + Vector2(12, 84), Vector2(242, 25)), 10, GOLD)
	_testo(testo_anteprima, Rect2(r.position + Vector2(12, 109), Vector2(242, 57)), 10)
	if bool(v.get("cut", false)):
		_testo("CONTESTO ESCLUSO", Rect2(r.position + Vector2(12, 151), Vector2(242, 14)), 9, Color("ffb18a"))

func _draw_conferma() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.8))
	ART.panel(self, Rect2(102, 104, 436, 152), Color("293642"))
	_testo("MANDI IN ONDA QUESTO MONTAGGIO?", Rect2(122, 119, 396, 30), 15, GOLD)
	var tagli := 0
	for c in clips():
		if bool(c["cut"]): tagli += 1
	_testo("3 voci · %d secondi · %d tagli al contesto" % [B.news_time(p), tagli], Rect2(122, 157, 396, 30), 12)
	for nome in ["Indietro", "Invia"]:
		var r := rett("Conferma/" + nome)
		ART.panel(self, r, Color("36564f") if nome == "Invia" else Color("34414f"))
		_testo("TRASMETTI" if nome == "Invia" else "TORNA AL TAVOLO", Rect2(r.position + Vector2(12, 12), r.size), 12)
