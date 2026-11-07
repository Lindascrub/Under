extends Node2D
signal cambiato(scelta: Dictionary)
signal confermato(scelta: Dictionary)
signal esci
const B := preload("res://scripts/boss_missions.gd")
const ART := preload("res://scripts/minigame_art.gd")
const GOLD := Color("ffe14d")
const PAPER := Color("eee4cc")
const INK := Color("241d32")
const MINT := Color("67d1c2")
@export var pedalate: Array[float] = [0.0, 3.0, 6.0, 11.0]
@export var colore_stanco := Color(1.0, 0.42, 0.38)
@onready var _corpo: Sprite2D = $Fermo/Corpo
@onready var _sudore: CPUParticles2D = $Fermo/Sudore
@onready var _binario: Control = $Leva/Binario
@onready var _manico: Control = $Leva/Manico
var p := {"intensity":2, "extra":0, "decor":2}
var v: Dictionary = {}
var _t := 0.0
var _riga_corpo := 128.0
var focus := 0
var premuto := ""
var origine := Vector2.ZERO
var trascina := false
var conferma_aperta := false
var consegnato := false
var messaggio := ""
var pausa_visiva := 15.0
var tween_pausa: Tween
var initialized := false
var valore_premuto := 0
func _ready() -> void:
	_riga_corpo = _corpo.region_rect.position.y
	# Disegnati nello stesso CanvasItem: la conferma copre anche persona e leva.
	_corpo.visible = false
	$Fermo/Cyclette.visible = false
	_manico.visible = false
	_binario.visible = false
	_aggiorna()
func rett(nome: String) -> Rect2:
	return get_node(nome).get_global_rect()
func scelta() -> Dictionary:
	return p.duplicate(true)
func imposta(stato: Dictionary) -> void:
	for key in ["intensity", "extra", "decor"]: p[key] = int(stato.get(key, p[key]))
	_aggiorna()
func avviso(testo: String) -> void:
	messaggio = testo
	queue_redraw()
func _aggiorna() -> void:
	if not is_node_ready(): return
	v = B.energy_preview(p)
	var stanco := clampf((float(v.fatigue) - 40) / 40, 0, 1)
	_corpo.modulate = Color.WHITE.lerp(colore_stanco, stanco)
	_sudore.emitting = bool(v.overwork)
	_sudore.speed_scale = 0.6 + stanco
	_manico.position.y = _binario.position.y + _binario.size.y * (int(p.intensity) - 1) / 2.0 - _manico.size.y / 2
	if initialized:
		if tween_pausa != null and tween_pausa.is_valid(): tween_pausa.kill()
		tween_pausa = create_tween()
		tween_pausa.tween_property(self, "pausa_visiva", float(v.rest), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else: pausa_visiva = float(v.rest)
	initialized = true
	queue_redraw()
func _cambia(key: String, value: int) -> void:
	if consegnato or conferma_aperta or int(p[key]) == value: return
	p[key] = value
	messaggio = ""
	_aggiorna()
	Sound.sfx("move", 0.95 + int(p.intensity) * 0.05)
	cambiato.emit(scelta())
func _metti(n: int) -> void:
	_cambia("intensity", clampi(n + 1, 1, 3))
func _conferma() -> void:
	if consegnato or conferma_aperta: return
	if not bool(v.valid):
		messaggio = "Manca energia. Spegni luci, cambia ritmo o minuti extra."
		Sound.sfx("deny")
	else:
		conferma_aperta = true
		focus = 0
	queue_redraw()
func bersagli() -> Array:
	if consegnato: return []
	if conferma_aperta: return [{"rect":rett("Conferma/Indietro"),"action":"indietro"},{"rect":rett("Conferma/Applica"),"action":"applica"}]
	var out: Array = [{"rect":rett("Leva/Area"),"action":"ritmo"},{"rect":rett("Pausa"),"action":"pausa"}]
	for i in 3: out.append({"rect":rett("Festa/Scelta%d" % i),"action":"decor_%d" % i})
	out.append({"rect":rett("Invia"),"action":"invia"})
	out.append({"rect":rett("Esci"),"action":"esci"})
	return out
func attiva(azione: String) -> void:
	if consegnato: return
	if conferma_aperta:
		if azione == "indietro": conferma_aperta = false; focus = 0
		elif azione == "applica":
			consegnato = true; conferma_aperta = false
			Sound.sfx("select")
			confermato.emit(scelta())
		queue_redraw()
		return
	match azione:
		"ritmo": _cambia("intensity", posmod(int(p.intensity), 3) + 1)
		"pausa": _cambia("extra", posmod(int(p.extra) + 5, 25))
		"invia": _conferma()
		"esci": consegnato = true; esci.emit()
		_:
			if azione.begins_with("decor_"): _cambia("decor", azione.trim_prefix("decor_").to_int())
func _ritmo_al_punto(pos: Vector2) -> int:
	var r := _binario.get_global_rect()
	return 1 + roundi(clampf((pos.y - r.position.y) / r.size.y, 0, 1) * 2)
func _extra_al_punto(pos: Vector2) -> int:
	return clampi(roundi((pos.x - 40) / 65.0), 0, 4) * 5
func punta(pos: Vector2, step: int) -> void:
	if consegnato or Ui.busy: return
	if step == 0:
		premuto = ""; origine = pos; trascina = false
		var bs := bersagli()
		for i in bs.size():
			if bs[i].rect.has_point(pos): premuto = bs[i].action; focus = i; break
		valore_premuto = int(p.extra) if premuto == "pausa" else int(p.intensity)
		if premuto == "ritmo": _cambia("intensity", _ritmo_al_punto(pos))
	elif step == 1:
		trascina = trascina or pos.distance_to(origine) > 8
		if premuto == "ritmo": _cambia("intensity", _ritmo_al_punto(pos))
		elif premuto == "pausa": _cambia("extra", _extra_al_punto(pos))
	elif step == 2:
		var azione := premuto; premuto = ""
		if azione == "pausa":
			# Rilasciare fuori dal cartellino restituisce i minuti della scelta iniziale.
			if rett("Pausa").has_point(pos): _cambia("extra", _extra_al_punto(pos))
			else: _cambia("extra", valore_premuto)
		elif azione == "ritmo":
			if not rett("Leva/Area").has_point(pos): _cambia("intensity", valore_premuto)
		elif azione != "ritmo" and not trascina:
			for b in bersagli():
				if b.action == azione and b.rect.has_point(pos): attiva(azione); break
		trascina = false
	queue_redraw()
func _process(dt: float) -> void:
	_t += dt * pedalate[clampi(int(p.intensity), 0, pedalate.size() - 1)]
	var r := _corpo.region_rect
	r.position = Vector2((int(_t) % 6) * 16, _riga_corpo)
	_corpo.region_rect = r
	queue_redraw()
func _unhandled_input(e: InputEvent) -> void:
	if Ui.busy or not visible or consegnato: return
	if e is InputEventKey and e.echo: return
	if not TouchControls.enabled:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			punta(e.position, 0 if e.pressed else 2); get_viewport().set_input_as_handled(); return
		if e is InputEventMouseMotion and e.button_mask & MOUSE_BUTTON_MASK_LEFT:
			punta(e.position, 1); get_viewport().set_input_as_handled(); return
	if e.is_action_pressed("ui_cancel"):
		if premuto == "ritmo": _cambia("intensity", valore_premuto)
		elif premuto == "pausa": _cambia("extra", valore_premuto)
		premuto = ""; trascina = false
		conferma_aperta = false; focus = 0
	elif e.is_action_pressed("move_up") or e.is_action_pressed("move_down"):
		var d := 1 if e.is_action_pressed("move_down") else -1
		focus = posmod(focus + d, maxi(1, bersagli().size()))
	elif e.is_action_pressed("move_left") or e.is_action_pressed("move_right"):
		var d := 1 if e.is_action_pressed("move_right") else -1
		if not conferma_aperta and focus == 0: _cambia("intensity", clampi(int(p.intensity) + d, 1, 3))
		elif not conferma_aperta and focus == 1: _cambia("extra", clampi(int(p.extra) + d * 5, 0, 20))
		else: focus = posmod(focus + d, maxi(1, bersagli().size()))
	elif e.is_action_pressed("confirm"):
		var bs := bersagli()
		if focus < bs.size(): attiva(bs[focus].action)
	else: return
	queue_redraw()
	get_viewport().set_input_as_handled()
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
func _draw() -> void:
	if not is_node_ready(): return
	ART.backdrop(self)
	testo("CAPO · LA FESTA E LA PAUSA", Rect2(16, 7, 608, 26), 18, GOLD)
	testo("Accendi quello che serve. Guarda quanta pausa resta a Fermo.", Rect2(16, 36, 608, 20), 12)
	ART.panel(self, Rect2(16, 62, 192, 205), Color("34434b"))
	_sudore.visible = not conferma_aperta
	var fermo: Node2D = $Fermo
	draw_set_transform(fermo.position,0,fermo.scale)
	var bici: Sprite2D = $Fermo/Cyclette
	draw_texture_rect_region(bici.texture,Rect2(bici.position+bici.offset,bici.region_rect.size),bici.region_rect)
	draw_texture_rect_region(_corpo.texture,Rect2(_corpo.position+_corpo.offset,_corpo.region_rect.size),_corpo.region_rect,_corpo.modulate)
	draw_set_transform(Vector2.ZERO)
	var battuta := "Quindici minuti. Li conto sempre."
	if int(p.extra)>0: battuta = "Era una pausa. Ora è un altro turno."
	elif int(p.intensity)==3: battuta = "La pausa c'è. Il fiato un po' meno."
	testo("FERMO: " + battuta, Rect2(28, 73, 168, 45), 11)
	for i in 15: draw_rect(Rect2(28+i*11, 252, 9, 6), MINT if i < roundi(pausa_visiva) else Color("27313c"))
	ART.panel(self, Rect2(220,62,112,205), Color("394750"))
	testo("RITMO %d" % int(p.intensity), Rect2(232,72,90,24), 14, GOLD)
	draw_rect(_binario.get_global_rect(), INK)
	ART.panel(self,_manico.get_global_rect(),GOLD)
	for i in 3:
		var y := 111 + i*55
		draw_line(Vector2(263,y),Vector2(278,y),PAPER,2)
		testo(str(i+1),Rect2(286,y-9,28,20),12)
	ART.cable(self, PackedVector2Array([Vector2(152,230),Vector2(196,242),Vector2(338,242),Vector2(338,96),Vector2(352,96)]), MINT if int(v.production)>=60 else Color("b87d70"),2)
	_draw_servizi()
	_draw_festa()
	_draw_pausa()
	ART.panel(self, rett("Invia"), Color("365b55") if bool(v.valid) else Color("51454b"))
	testo("CONFERMA", rett("Invia").grow(-7), 12, GOLD)
	ART.panel(self, rett("Esci"), Color("293642"))
	testo("SALVA/ESCI", rett("Esci").grow(-7), 11)
	var aiuto := "Ritmo, pausa e luci: scegli con calma."
	if not TouchControls.enabled: aiuto = "SU/GIÙ: scegli · SINISTRA/DESTRA: regola · INVIO: usa."
	if messaggio != "": aiuto = messaggio
	testo(aiuto,Rect2(16,330,390,28),10,GOLD if messaggio != "" else PAPER)
	if conferma_aperta: _draw_conferma()
	var bs := bersagli()
	if not TouchControls.enabled and focus < bs.size(): draw_rect(bs[focus].rect.grow(1),GOLD,false,1)
func _draw_servizi() -> void:
	ART.panel(self, rett("Servizi"), Color("293e46"))
	var acceso := int(v.production)>=60
	ART.panel(self,Rect2(352,83,26,29),Color("829a8e") if acceso else Color("6e5254"))
	for x in [360,368]: draw_rect(Rect2(x,91,3,8),INK)
	testo("SERVIZI ESSENZIALI",Rect2(390,71,226,18),12,MINT)
	testo("60 energia · collegamento fisso",Rect2(390,93,226,16),10)
	testo("Energia %d / richiesta %d" % [int(v.production),int(v.demand)],Rect2(352,113,258,16),11,GOLD)
func _draw_festa() -> void:
	ART.panel(self,rett("Festa"),Color("39434a"))
	var disponibile := maxi(0,int(v.production)-60)
	for gruppo in 2:
		var y := 155 + gruppo*31
		var richiesto := int(p.decor)>gruppo
		var acceso := richiesto and disponibile >= (gruppo+1)*15
		ART.cable(self,PackedVector2Array([Vector2(354,y+8),Vector2(400,y+8),Vector2(436,y+16),Vector2(488,y+16),Vector2(562,y+8)]), GOLD if acceso else Color("59636a"),1)
		for i in 3: ART.bulb(self, Vector2(428+i*62,y+11),"buona",1,acceso)
		if richiesto and not acceso: testo("!",Rect2(600,y,15,18),14,GOLD)
	testo("FESTA · 15 energia ogni 3 luci",Rect2(352,211,262,16),10)
	for i in 3:
		var r := rett("Festa/Scelta%d" % i)
		ART.panel(self,r,Color("677d70") if int(p.decor)==i else Color("293642"))
		testo("SPENTE" if i==0 else "%d LUCI" % (i*3),r.grow(-7),11,GOLD if int(p.decor)==i else PAPER)
func _draw_pausa() -> void:
	ART.paper(self,rett("Pausa"))
	testo("EXTRA %d min" % int(p.extra),Rect2(28,279,160,18),12,INK)
	testo("PAUSA %d min" % int(v.rest),Rect2(194,279,130,18),12,INK)
	draw_line(Vector2(40,306),Vector2(300,306),Color("988e79"),2)
	for i in 5:
		var x := 40+i*65
		draw_line(Vector2(x,303),Vector2(x,309),INK,1)
		testo(str(i*5),Rect2(x-6,309,24,12),9,INK)
	var at := Vector2(40+int(p.extra)*13,303)
	draw_colored_polygon(PackedVector2Array([at+Vector2(-6,-8),at+Vector2(6,-8),at]),INK)
func _draw_conferma() -> void:
	draw_rect(Rect2(0,0,640,360),Color(0,0,0,0.85))
	ART.panel(self,Rect2(92,88,456,184),Color("293642"))
	testo("CONFERMARE IL TURNO DI FERMO?",Rect2(108,102,424,28),16,GOLD)
	var t := "Ritmo %d · %d minuti extra · %d luci.\n" % [int(p.intensity),int(p.extra),int(p.decor)*3]
	t += "A Fermo restano %d minuti di pausa.\n" % int(v.rest)
	t += "Premio del Capo: %s." % GameState.euros(600 if bool(v.overwork) else 0)
	testo(t,Rect2(112,144,416,55),12)
	for nome in ["Indietro","Applica"]:
		var r := rett("Conferma/"+nome)
		ART.panel(self,r,Color("344550"))
		testo("RIVEDI" if nome=="Indietro" else "APPLICA",r.grow(-10),12)
