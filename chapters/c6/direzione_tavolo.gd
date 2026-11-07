extends Node2D
signal richiesta(azione: String, dati: Dictionary)
const R := preload("res://chapters/c6/direzione_regole.gd")
const ART := preload("res://scripts/minigame_art.gd")
const GOLD := Color("ffe14d")
const PAPER := Color("eee4cc")
const INK := Color("241d32")
const MINT := Color("67d1c2")
const COLORS := [Color("d8b785"), Color("75b7c3"), Color("bd998c"), Color("b6ab75")]
const TITOLI := {"accessi":"ACCESSI GRATUITI", "contratto":"RINEGOZIA", "risorse":"RISORSE ALLA CASA", "autonomia":"AUTONOMIA", "proroga":"PROROGA", "modello":"MODELLO DI ADA", "niente":"NON INTERVENIRE", "conservare":"CONSERVA", "interessi":"RIDUCI INTERESSI", "revisione":"REVISIONE", "alternative":"RETI ALTERNATIVE"}
const DEBITI_BREVI := {"conservare":"2% a notte", "interessi":"0,5% a notte · servono 15 di riserve", "revisione":"Sospendi e ricontrolla i debiti senza firma", "alternative":"Finanzia i servizi con le reti già attive"}
var st: Dictionary = {}
var alloc: Dictionary = {}
var preview: Dictionary = {}
var phase := "intro"
var options: Array = []
var msg := ""
var focus := 0
var passo := 5
var preso := -2
var premuto := ""
var origine := Vector2.ZERO
var cursore := Vector2.ZERO
var trascina := false
var scelta := 0
var scatto := 0.0
var anim_da := Vector2.ZERO
var anim_a := Vector2.ZERO
var anim_quantita := 5

func aggiorna(state: Dictionary, a: Dictionary, fase: String, opzioni: Array, avviso: String) -> void:
	st = state; alloc = a; phase = fase; options = opzioni; msg = avviso
	preview = R.preview(st, alloc) if not alloc.is_empty() else {}
	if phase != "alloc": preso = -2
	focus = clampi(focus, 0, maxi(0, bersagli().size() - 1))
	scelta = clampi(scelta, 0, maxi(0, options.size() - 1))
	queue_redraw()
func rett(nome: String) -> Rect2:
	return get_node(nome).get_global_rect()
func vasca(i: int) -> Rect2:
	return rett("Fondi/" + str(i))
func minus_button(i: int) -> Rect2:
	return Rect2(vasca(i).position + Vector2(8, 156), Vector2(40, 32))
func plus_button(i: int) -> Rect2:
	return Rect2(vasca(i).position + Vector2(96, 156), Vector2(40, 32))
func option_button(i: int) -> Rect2:
	return rett("Scelte/" + str(i))
func bersagli() -> Array:
	var out: Array = []
	if phase == "alloc":
		for i in 4:
			out.append({"rect": Rect2(vasca(i).position, Vector2(144, 150)), "action": "cat_%d" % i})
			out.append({"rect": minus_button(i), "action": "minus_%d" % i})
			out.append({"rect": plus_button(i), "action": "plus_%d" % i})
		for nome in ["Liberi", "Passo", "Regole", "Conferma", "Esci"]: out.append({"rect": rett(nome), "action": nome.to_lower()})
	elif phase in ["casa", "debiti"]:
		for i in options.size(): out.append({"rect": option_button(i), "action": "option_%d" % i})
		out.append({"rect": rett("Conferma"), "action": "scegli"})
		out.append({"rect": rett("Esci"), "action": "esci"})
	return out
func naviga(d: Vector2) -> void:
	var bs := bersagli()
	if bs.is_empty(): return
	var da: Vector2 = bs[focus].rect.get_center()
	var best := focus
	var costo := INF
	for i in bs.size():
		var v: Vector2 = bs[i].rect.get_center() - da
		if v.dot(d) <= 8: continue
		var c := v.dot(d) + absf(v.cross(d)) * 3
		if c < costo: best = i; costo = c
	focus = best
	var azione: String = bs[focus].action
	if azione.begins_with("option_"): scelta = azione.trim_prefix("option_").to_int()
	queue_redraw()
func tastiera(e: InputEvent) -> void:
	if e is InputEventKey and e.echo: return
	if e.is_action_pressed("ui_cancel"): preso = -2; queue_redraw(); return
	if e.is_action_pressed("move_left"): naviga(Vector2.LEFT)
	elif e.is_action_pressed("move_right"): naviga(Vector2.RIGHT)
	elif e.is_action_pressed("move_up"): naviga(Vector2.UP)
	elif e.is_action_pressed("move_down"): naviga(Vector2.DOWN)
	elif e.is_action_pressed("confirm"):
		var bs := bersagli()
		if focus < bs.size(): attiva(bs[focus].action)
func attiva(azione: String) -> void:
	if azione.begins_with("cat_") or azione == "liberi":
		var i := azione.trim_prefix("cat_").to_int() if azione != "liberi" else -1
		if preso == -2: preso = i
		elif preso == i: preso = -2
		else:
			richiesta.emit("transfer", {"from": preso, "to": i, "amount": passo})
			preso = -2
	elif azione.begins_with("plus_") or azione.begins_with("minus_"):
		richiesta.emit("nudge", {"index": azione.get_slice("_", 1).to_int(), "dir": 1 if azione.begins_with("plus_") else -1, "amount": passo})
	elif azione == "passo": passo = 1 if passo == 5 else 5; preso = -2
	elif azione.begins_with("option_"):
		scelta = azione.trim_prefix("option_").to_int()
		richiesta.emit("select_option", {"index": scelta})
	else: richiesta.emit(azione, {})
	queue_redraw()
func punta(pos: Vector2, fase: int) -> void:
	cursore = pos
	if fase == 0:
		premuto = ""; origine = pos; trascina = false
		var bs := bersagli()
		for i in bs.size():
			if bs[i].rect.has_point(pos):
				premuto = bs[i].action; focus = i
				if premuto.begins_with("option_"): scelta = premuto.get_slice("_", 1).to_int()
				break
	elif fase == 1: trascina = trascina or pos.distance_to(origine) > 8
	elif fase == 2:
		var a := premuto; premuto = ""
		if trascina and (a.begins_with("cat_") or a == "liberi"):
			var da := a.get_slice("_", 1).to_int() if a != "liberi" else -1
			var dest := -2
			for i in 4:
				if vasca(i).has_point(pos): dest = i
			if rett("Liberi").has_point(pos): dest = -1
			if dest != -2 and dest != da: richiesta.emit("transfer", {"from": da, "to": dest, "amount": passo})
			preso = -2
		elif not trascina:
			for b in bersagli():
				if b.action == a and b.rect.has_point(pos): attiva(a); break
		trascina = false
	queue_redraw()
func quantita_sorgente(i: int) -> int:
	return mini(passo, 100 - R.total(alloc) if i < 0 else int(alloc[R.CATS[i]]) - R.minimum(st, R.CATS[i]))
func anima(da: int, a: int, quanti: int) -> void:
	anim_da = vasca(da).get_center() if da >= 0 else rett("Liberi").get_center()
	anim_a = vasca(a).get_center() if a >= 0 else rett("Liberi").get_center()
	scatto = 0.24
	anim_quantita = quanti
func _process(dt: float) -> void:
	if scatto > 0: scatto = maxf(0, scatto - dt); queue_redraw()
func testo(t: String, r: Rect2, size := 11, col := PAPER) -> void:
	var f := Assets.font()
	var y := r.position.y + size
	for par in t.split("\n"):
		var line := ""
		for word in par.split(" "):
			var trial := line + (" " if line != "" else "") + word
			if f.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > r.size.x and line != "":
				if y <= r.end.y: draw_string(f, Vector2(r.position.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
				y += size + 2; line = word
			else: line = trial
		if y <= r.end.y: draw_string(f, Vector2(r.position.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
		y += size + 2
func moneta(p: Vector2, valore := 5) -> void:
	draw_circle(p.round(), 6, INK); draw_circle(p.round(), 5, GOLD)
	if valore < 5: draw_string(Assets.font(), p + Vector2(-2, 3), str(valore), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, INK)
func _draw() -> void:
	ART.backdrop(self)
	testo("DIREZIONE · UN SOLO TURNO", Rect2(16, 7, 608, 24), 18, GOLD)
	if phase in ["alloc", "intro"]: _draw_alloc()
	elif phase in ["casa", "debiti"]: _draw_options()
	else: testo("Il tavolo resta in attesa della decisione.", Rect2(16, 60, 608, 40), 14)
	if phase in ["alloc", "casa", "debiti"]:
		ART.panel(self, rett("Esci"), Color("293642"))
		testo("SALVA / ESCI", rett("Esci").grow(-7), 12)
	var bs := bersagli()
	if not TouchControls.enabled and focus < bs.size(): draw_rect(bs[focus].rect.grow(1), GOLD, false, 1)
	if scatto > 0:
		var k := 1 - scatto / 0.24
		moneta(anim_da.lerp(anim_a, k) + Vector2(0, -sin(k * PI) * 24), anim_quantita)
	if trascina and (premuto.begins_with("cat_") or premuto == "liberi"):
		var quanti := quantita_sorgente(premuto.get_slice("_", 1).to_int() if premuto != "liberi" else -1)
		if quanti > 0: moneta(cursore + Vector2(0, -16), quanti)
func _draw_alloc() -> void:
	if preview.is_empty(): return
	ART.panel(self, rett("Liberi"), Color("354650"))
	testo("SUL TAVOLO: %d" % (100 - R.total(alloc)), Rect2(26, 45, 250, 24), 14, GOLD)
	for i in int(ceil((100 - R.total(alloc)) / 5.0)):
		moneta(Vector2(250 + i % 10 * 12, 49 + int(i / 10) * 12), mini(5, 100 - R.total(alloc) - i * 5))
	ART.panel(self, rett("Passo"), Color("344550"))
	testo("GETTONE: %d" % passo, rett("Passo").grow(-7), 11)
	ART.panel(self, rett("Regole"), Color("344550"))
	testo("DETTAGLI", rett("Regole").grow(-7), 11)
	for i in 4:
		var c: String = R.CATS[i]
		var r := vasca(i)
		ART.panel(self, r, Color("34404a"), COLORS[i])
		if preso == i: draw_rect(r.grow(-2), MINT, false, 2)
		testo(R.NAMES[c], Rect2(r.position + Vector2(8, 7), Vector2(128, 18)), 11, COLORS[i])
		mondo(i, Rect2(r.position + Vector2(8, 29), Vector2(128, 59)))
		for k in int(ceil(int(alloc[c]) / 5.0)):
			var v := mini(5, int(alloc[c]) - k * 5)
			moneta(r.position + Vector2(16 + k % 10 * 12, 98 + int(k / 10) * 12), v)
		testo(_effetto(i), Rect2(r.position + Vector2(8, 121), Vector2(128, 31)), 10)
		for b in [minus_button(i), plus_button(i)]: ART.panel(self, b, Color("25333e"))
		testo("−", minus_button(i).grow(-7), 16)
		testo("+", plus_button(i).grow(-7), 16)
		testo(str(int(alloc[c])), Rect2(r.position + Vector2(54, 160), Vector2(39, 28)), 20, GOLD)
	ART.panel(self, rett("Dettaglio"), Color("27343e"))
	var help := "Sposta un gettone fra due destinazioni. Il totale resta 100."
	if not TouchControls.enabled: help = "FRECCE: scegli · INVIO: prendi o usa · ESC: lascia."
	if preso != -2: help = "Scegli dove lasciare il gettone. Fuori dal tavolo annulli."
	if msg != "": help = msg
	testo(help, Rect2(26, 286, 402, 30), 11, GOLD if msg != "" else PAPER)
	testo("ANTEPRIMA · nessuna decisione applicata", Rect2(26, 323, 402, 18), 10, MINT)
	ART.panel(self, rett("Conferma"), Color("365b55") if R.invalid(st, alloc) == "" else Color("51454b"))
	testo("PROSEGUI", rett("Conferma").grow(-9), 14, GOLD)
func _effetto(i: int) -> String:
	match i:
		0: return R.wage_label(int(alloc.stipendi))
		1: return R.service_label(int(preview.services_eff)) + (" · spese %d" % int(preview.from_services) if int(preview.from_services) > 0 else "")
		2: return "Arretrato: %d" % int(preview.state.backlog) + (" · guasto previsto" if bool(preview.state.breakdown_due) else " · coperta" if int(alloc.manutenzione) >= R.maint_need(st) else "")
		3: return "In cassa: %d" % int(preview.state.reserve)
	return ""
func persona(nome: String, p: Vector2, pagato := true) -> void:
	var dati := GameState.npc_data(nome)
	var tex := Assets.character(str(dati.get("sheet", "char_09"))).get_frame_texture("idle_down", 0)
	draw_texture_rect(tex, Rect2(p, Vector2(16, 32)), false, Color.WHITE if pagato else Color("777887"))
func mondo(i: int, r: Rect2) -> void:
	draw_rect(r, Color("22343d"))
	draw_rect(Rect2(r.position + Vector2(0, 52), Vector2(r.size.x, 7)), Color("62716d"))
	match i:
		0:
			for j in 3:
				persona(["fermo", "olga", "amir"][j], r.position + Vector2(14 + j * 38, 17))
				var b := Rect2(r.position + Vector2(10 + j * 38, 3), Vector2(27, 11))
				draw_rect(b, Color("829a8e")); draw_rect(Rect2(b.position, Vector2(clampf(float(alloc.stipendi) / 55, 0, 1) * 27, 11)), GOLD)
		1:
			var paga := int(preview.services_eff) < 15
			ART.panel(self, Rect2(r.position + Vector2(9, 10), Vector2(90, 34)), Color("9bafb0") if not paga else Color("656d78"))
			for j in 3: draw_rect(Rect2(r.position + Vector2(17 + j * 24, 15), Vector2(18, 14)), Color("334d60"))
			for x in [28, 81]: draw_circle(r.position + Vector2(x, 46), 6, INK)
			if int(preview.services_eff) >= 25: persona("nadir", r.position + Vector2(105, 16))
			if paga: moneta(r.position + Vector2(111, 16))
		2:
			ART.panel(self, Rect2(r.position + Vector2(17, 3), Vector2(65, 49)), Color("838e98"))
			draw_rect(Rect2(r.position + Vector2(23, 9), Vector2(24, 42)), Color("394a55"))
			draw_rect(Rect2(r.position + Vector2(49, 9), Vector2(27, 42)), Color("394a55"))
			var ok := not bool(preview.state.breakdown_due)
			draw_circle(r.position + Vector2(91, 16), 4, MINT if ok else Color("f2a573"))
			if not ok: draw_polyline(PackedVector2Array([r.position + Vector2(47, 9), r.position + Vector2(42, 21), r.position + Vector2(53, 33), r.position + Vector2(46, 50)]), Color("f2a573"), 2)
			persona("teo", r.position + Vector2(103, 20))
		3:
			ART.panel(self, Rect2(r.position + Vector2(26, 4), Vector2(76, 48)), Color("889590"))
			draw_circle(r.position + Vector2(64, 28), 13, INK)
			draw_circle(r.position + Vector2(64, 28), 10, Color("aeb7a6"), false, 2)
			for k in mini(10, int(preview.state.reserve) / 5): moneta(r.position + Vector2(14 + k * 10, 49))
func _draw_options() -> void:
	var casa := phase == "casa"
	testo("LA CASA COMUNE" if casa else "LA REGOLA DEI DEBITI", Rect2(16, 40, 608, 26), 16, MINT)
	ART.panel(self, rett("Oggetto"), Color("344550"))
	if casa:
		var esito := R.casa_state()
		draw_rect(Rect2(40, 129, 132, 94), Color("a6a394"))
		draw_colored_polygon(PackedVector2Array([Vector2(32, 129), Vector2(106, 85), Vector2(180, 129)]), Color("7b6670"))
		for x in [54, 132]: draw_rect(Rect2(x, 148, 22, 25), Color("355561"))
		draw_rect(Rect2(93, 181, 27, 42), Color("344550"))
		persona("ada", Vector2(67, 190))
		if esito == "riconversione":
			draw_line(Vector2(92, 209), Vector2(133, 209), GOLD, 3)
		elif esito == "sospesa":
			draw_line(Vector2(91, 184), Vector2(122, 219), Color("cb9a78"), 4)
		testo({"riconversione":"Centro CHEAP", "comunitaria":"Gestione comunitaria", "sospesa":"Chiusura rinviata"}.get(esito, esito), Rect2(32, 233, 152, 40), 12)
	else:
		ART.paper(self, Rect2(47, 100, 117, 110))
		testo("DEBITI", Rect2(59, 113, 95, 25), 16, INK)
		for y in [147, 159, 171, 183]: draw_line(Vector2(59, y), Vector2(151, y), Color("958a79"), 2)
		testo("Prove: %d\nReti attive: %d" % [R.evidence().size(), R.networks(st).size()], Rect2(32, 233, 152, 40), 12)
	for i in options.size():
		var r := option_button(i)
		var o: Array = options[i]
		var closed := str(o[-1]) != ""
		ART.panel(self, r, Color("354650") if not closed else Color("3a3842"))
		testo(TITOLI.get(str(o[0]), str(o[1])), Rect2(r.position + Vector2(10, 8), Vector2(r.size.x - 20, 18)), 12, GOLD if scelta == i else PAPER)
		testo(str(o[-1]) if closed else (DEBITI_BREVI.get(str(o[0]), "") if not casa else str(o[1])), Rect2(r.position + Vector2(10, 27), Vector2(r.size.x - 20, 24)), 10, Color("d2a68e") if closed else PAPER)
	# La selezione apre i dettagli; un secondo gesto distinto applica la scelta.
	ART.panel(self, rett("Dettaglio"), Color("27343e"))
	if not options.is_empty():
		var o: Array = options[scelta]
		var descrizione := str(o[-1]) if str(o[-1]) != "" else (str(o[2]) if not casa else str(o[1]))
		testo(msg if msg != "" else descrizione, Rect2(26, 285, 402, 56), 11, GOLD if msg != "" else PAPER)
	ART.panel(self, rett("Conferma"), Color("365b55"))
	testo("SCEGLI", rett("Conferma").grow(-9), 14, GOLD)
