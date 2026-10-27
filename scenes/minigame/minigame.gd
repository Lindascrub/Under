extends Node2D

const Art := preload("res://scripts/minigame_art.gd")
## Minigiochi "a sorpresa": partono quando dai una mano a qualcuno. Config in GameState.minigame:
##   type "timing":   premi Z quando il segno è nella zona verde (riparare, accordare, salire le scale)
##   type "collect":  muovi il cuore e raccogli tutto prima che scada il tempo (foglie, croccantini)
##   type "sequence": ricorda e ripeti la sequenza di frecce (pratiche, post-it, curriculum)
##   type "bulbs":    smista le lampadine: buona a DESTRA, rotta a SINISTRA, quella che sfarfalla
##                    si aggiusta con SU o GIÙ (Mina)
##   type "wires":    collega i fili dello stesso colore, come in Among Us (Nonno Bulbo)
##   type "inventory": ogni prodotto sul suo scaffale (Leda: SCATOLE E SCAFFALI)
##   type "route":    due giri (mattina e pomeriggio), tre pacchi ciascuno: scegli le strade (Amir: L'ULTIMA CONSEGNA)
##   type "rate":     sei documenti in ordine di data, poi la voce doppia nell'estratto conto
##                    (Olga: LE RATE MANCANTI; dati in data/bank.json)
##   type "pratiche": per ogni pratica, quale problema c'è (Teo: LA PRATICA IMPOSSIBILE)
##   type "stanze":   sei pezzi d'arredo in tre stanze, ognuna col suo bisogno (Ada: UNA STANZA PER TUTTI)
##   type "percorso": tratta dopo tratta, da casa al lavoro in tempo e nel budget (Nadir: IL PERCORSO
##                    POSSIBILE). Dati di tutti e due in data/city.json
## Opzioni: "win_flags"/"partial_flags" (flag da accendere), "item" (regalo se vinci),
## "help_on_win_only" (conta come aiuto solo se riesce; "help_on_partial": anche a metà).
## Se vinci, la persona ti ringrazia e ti dà qualche euro.

const INV := Rect2(112, 108, 416, 198)
const BOX := Rect2(170, 120, 300, 150)
## I giochi di carta della Banca hanno bisogno di più spazio (fogli da leggere).
const BIG := Rect2(40, 104, 560, 240)
const RED := Color("ff2a3c")
const YELLOW := Color("ffe14d")
const GREEN := Color("3ddc84")
const ARROWS := ["up", "down", "left", "right"]

var cfg: Dictionary = {}
var type := "timing"
var phase := "intro"
var won := false

# timing
var marker := 0.0
var marker_dir := 1.0
var marker_speed := 0.7
var zone := Vector2(0.4, 0.55)
var hits := 0
var misses := 0
var flash := 0.0
# collect
var soul := Vector2.ZERO
var items: Array[Vector2] = []
var time_left := 15.0
var hazards: Array[Dictionary] = []
# lampadine
var bulb := "buona"
var bulb_fix := 0
var bulb_done := 0
var bulb_t := 0.0
# fili
const WIRE_COLS := [Color("d23b3b"), Color("39b6ff"), Color("ffe14d"), Color("3ddc84")]
var wire_right: Array[int] = []
var wire_done: Array[int] = []
var wire_sel := 0
var wire_pick := -1
var wire_round := 0
var hurt_t := 0.0
## dove tiene il dito chi gioca col telefono (il cuore della raccolta); x < 0: nessun dito
var finger := Vector2(-1, -1)
# sequence
var seq: Array[String] = []
var shown := 0
var show_t := 0.0
var typed: Array[String] = []
var round_n := 0
var show_len := 0.75
## Ogni direzione ha il suo suono, così si capisce anche a orecchio.
const ARROW_PITCH := {"up": 1.5, "right": 1.25, "down": 0.75, "left": 1.0}

# inventario (Leda)
const INV_CATS := ["ALIMENTARI", "IGIENE", "SCUOLA", "CASA"]
const INV_COLS := [Color("e0a040"), Color("5ac8e8"), Color("e86a8a"), Color("8ad06a")]
const INV_GOODS := [["Pane", 0], ["Sapone", 1], ["Matita", 2], ["Riso", 0], ["Dentifricio", 1], ["Quaderno", 2],
	["Scopa", 3], ["Biscotti", 0], ["Shampoo", 1], ["Gomma", 2], ["Lampadina", 3], ["Pasta", 0], ["Spugna", 3], ["Righello", 2]]
var inv_queue: Array = []
var inv_sel := 0
var inv_done := 0
var inv_msg := ""
# consegne (Amir): incroci, strade [da, a, minuti, rischiosa], pacchi
## Due giri: la mattina e il pomeriggio. Ogni giro ha la sua mappa, i suoi tre pacchi e il suo tempo.
## In ogni mappa c'è una strada sicura che arriva in tempo; le scorciatoie rosse passano dal cantiere.
const RT_MAPS := [
	{"title": "MATTINA", "budget": 120, "parcels": [2, 4, 5],
		"nodes": [Vector2(196, 195), Vector2(262, 146), Vector2(262, 246), Vector2(330, 195), Vector2(430, 146), Vector2(430, 246)],
		"names": ["MAGAZZINO", "", "Scala B", "", "Via dei Fiori", "Piazza"],
		"edges": [[0, 1, 30, false], [0, 2, 30, false], [1, 3, 30, false], [2, 3, 30, false], [1, 4, 50, false],
			[2, 5, 50, false], [4, 5, 30, false], [0, 3, 10, true], [3, 4, 10, true], [3, 5, 10, true]]},
	# i nomi stanno sotto gli incroci in basso e sotto quello in alto a destra: non coprono i minuti
	{"title": "POMERIGGIO", "budget": 150, "parcels": [2, 5, 6],
		"nodes": [Vector2(194, 195), Vector2(250, 146), Vector2(250, 246), Vector2(318, 195), Vector2(386, 146), Vector2(386, 246), Vector2(446, 146)],
		"names": ["MAGAZZINO", "", "Scuola", "", "", "Via Roma", "Ospedale"],
		"edges": [[0, 1, 30, false], [0, 2, 40, false], [1, 3, 30, false], [2, 3, 30, false], [1, 4, 60, false],
			[2, 5, 50, false], [4, 6, 30, false], [5, 6, 50, false],
			[0, 3, 15, true], [3, 4, 20, true], [3, 5, 20, true]]},
]
var rt_map := 0
var rt_total := 0
var rt_nodes: Array = []
var rt_names: Array = []
var rt_edges: Array = []
var rt_parcels: Array = []
## Quanto costa un imprevisto in una strada rischiosa (il cantiere), e quanto spesso capita.
const RT_DETOUR := 40
const RT_RISK := 0.5
var rt_at := 0
var rt_left := 120
var rt_done: Array = []
var rt_sel := 0
var rt_from := Vector2.ZERO
var rt_to := Vector2.ZERO
var rt_k := 1.0
var rt_msg := ""
var rt_rng := RandomNumberGenerator.new()

# LE RATE MANCANTI (Olga): rate_cards = in che ordine stanno sul tavolo i documenti
var rate_cards: Array = []
var rate_placed: Array = []
var rate_phase := "order"
var rate_sel := 0
var rate_msg := ""
# LA PRATICA IMPOSSIBILE (Teo)
var pr_i := 0
var pr_sel := 0
var pr_msg := ""
# UNA STANZA PER TUTTI (Ada): st_where[i] = in che stanza sta il pezzo i (-1 = ancora da sistemare)
var st_where: Array = []
var st_sel := -1
var st_focus := 0
var st_msg := ""
# IL PERCORSO POSSIBILE (Nadir): le tratte scelte, una dopo l'altra
var pc_path: Array = []
var pc_at := 0
var pc_focus := 0
var pc_msg := ""

var _title: Label
var _info: Label


func _ready() -> void:
	cfg = GameState.minigame
	type = str(cfg.get("type", "timing"))
	Ui.show_hud(false)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.size = Vector2(640, 360)
	bg.z_index = -10
	add_child(bg)
	_title = _label(Vector2(0, 40), 22, YELLOW)
	_title.text = str(cfg.get("title", "Dai una mano"))
	_info = _label(Vector2(0, 80), 16, Color.WHITE)
	# ogni persona che aiuti ha la sua canzone (campo "music"); le altre, una per tutte
	Sound.music(str(cfg.get("music", "aiuto")))
	if Ui.transitioning:
		await Ui.faded_in
	await Ui.say(cfg.get("intro", ["* Dai una mano."]))
	_start()


func _label(pos: Vector2, size: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(640, size + 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	add_child(l)
	return l


func _start() -> void:
	phase = "play"
	match type:
		"timing":
			_info.text = GameState.fmt("Premi {ok} quando il segno è nel verde")
			_new_zone()
		"collect":
			_info.text = "Raccogli tutto con le frecce ed evita le cose rosse"
			soul = BOX.get_center()
			for i in int(cfg.get("count", 10)):
				items.append(Vector2(randf_range(BOX.position.x + 12, BOX.end.x - 12), randf_range(BOX.position.y + 12, BOX.end.y - 12)))
			time_left = float(cfg.get("time", 15.0)) * 0.7
			for i in 3:
				var hp := Vector2(randf_range(BOX.position.x + 20, BOX.end.x - 20), randf_range(BOX.position.y + 20, BOX.end.y - 20))
				if hp.distance_to(soul) < 50.0:
					hp.x = BOX.position.x + 30 if soul.x > BOX.get_center().x else BOX.end.x - 30
				hazards.append({"pos": hp, "vel": Vector2.from_angle(randf() * TAU) * randf_range(55.0, 85.0)})
		"sequence":
			_next_round()
		"bulbs":
			_info.text = "SCORRI: a destra buona, a sinistra rotta, su e giù aggiusta" if TouchControls.enabled else "DESTRA buona   SINISTRA rotta   SU/GIÙ aggiusta"
			time_left = float(cfg.get("time", 25.0))
			_new_bulb()
		"wires":
			_info.text = "Tocca un filo a sinistra, poi il suo posto a destra" if TouchControls.enabled else "SU/GIÙ scegli il filo, %s per collegarlo" % GameState.fmt("{ok}")
			time_left = float(cfg.get("time", 30.0))
			_new_wires()
		"inventory":
			time_left = float(cfg.get("time", 35.0))
			var goods := INV_GOODS.duplicate()
			goods.shuffle()
			inv_queue = goods.slice(0, int(cfg.get("count", 8)))
		"route":
			_rt_load(0)
			if cfg.has("seed"):
				rt_rng.seed = int(cfg["seed"])
			else:
				rt_rng.randomize()
			_info.text = "Tocca un incrocio vicino per andarci" if TouchControls.enabled else "FRECCE scegli la strada, %s per andare" % GameState.fmt("{ok}")
		"rate":
			rate_cards = range(_rate_docs().size())
			var rng := RandomNumberGenerator.new()
			if cfg.has("seed"):
				rng.seed = int(cfg["seed"])
			else:
				rng.randomize()
			# mescolati, ma mai già in ordine
			while rate_cards == range(rate_cards.size()):
				for i in range(rate_cards.size() - 1, 0, -1):
					var j := rng.randi_range(0, i)
					var tmp: int = rate_cards[i]
					rate_cards[i] = rate_cards[j]
					rate_cards[j] = tmp
			rate_msg = "Dal più vecchio al più recente."
		"pratiche":
			pr_i = 0
			pr_msg = ""
		"stanze":
			st_where = []
			for i in _st_pieces().size():
				st_where.append(-1)
			st_msg = "Tocca un pezzo, poi la stanza dove metterlo." if TouchControls.enabled else "FRECCE scegli, %s prendi e metti." % GameState.fmt("{ok}")
		"percorso":
			pc_path = []
			pc_at = 0
			pc_msg = "Tocca le tratte, una dopo l'altra, da casa di Nadir al lavoro." if TouchControls.enabled else "FRECCE scegli la tratta, %s la prendi." % GameState.fmt("{ok}")


func _new_bulb() -> void:
	bulb = ["buona", "rotta", "fioca"].pick_random()
	bulb_fix = 0
	bulb_t = 0.0


func _bulb_answer(ok: bool) -> void:
	if ok:
		bulb_done += 1
		Sound.sfx("blip", 1.3)
	else:
		misses += 1
		flash = 0.3
		Sound.sfx("deny")
	if bulb_done >= int(cfg.get("count", 10)):
		_finish(true)
	elif misses >= 4:
		_finish(false)
	else:
		_new_bulb()


func _new_wires() -> void:
	wire_right.assign([0, 1, 2, 3])
	wire_right.shuffle()
	wire_done.clear()
	wire_sel = 0
	wire_pick = -1


## Il filo di sinistra `wire_pick` va al posto di destra `wire_sel`: giusto o sbagliato?
func _wire_connect() -> void:
	if wire_right[wire_sel] == wire_pick:
		wire_done.append(wire_pick)
		Sound.sfx("coin")
		if wire_done.size() >= 4:
			wire_round += 1
			if wire_round >= 2:
				_finish(true)
				return
			_new_wires()
			return
	else:
		misses += 1
		flash = 0.3
		Sound.sfx("deny")
		if misses >= 4:
			_finish(false)
			return
	wire_pick = -1
	for i in 4:
		if i not in wire_done:
			wire_sel = i
			break


# --- col dito (vedi TouchControls) -------------------------------------------------

func touch_scheme() -> String:
	if phase != "play":
		return ""
	match type:
		"timing":
			return "tap"
		"sequence":
			return "dirs"
		"bulbs":
			return "swipe"
	return "point"


func touch_center() -> Vector2:
	return BOX.get_center()


func touch_point(pos: Vector2, step: int) -> void:
	if type == "rate" and step == 0:
		if rate_phase == "order":
			for k in rate_cards.size():
				if _rate_card(k).has_point(pos) and int(rate_cards[k]) not in rate_placed:
					rate_sel = k
					_rate_pick(k)
					return
		else:
			for i in _rate_rows().size():
				if _rate_row(i).has_point(pos):
					rate_sel = i
					_rate_row_pick(i)
					return
		return
	if type == "stanze" and step == 0:
		for t in _st_targets():
			if (t[1] as Rect2).has_point(pos):
				_st_act(t[0])
				return
		return
	if type == "percorso" and step == 0:
		for t in _pc_targets():
			if (t[1] as Rect2).has_point(pos):
				_pc_act(t[0])
				return
		return
	if type == "pratiche" and step == 0:
		for k in _pr_types().size():
			if _pr_button(k).grow(3).has_point(pos):
				pr_sel = k
				_pr_answer(k)
				return
		return
	if type == "inventory" and step == 0:
		for k in INV_CATS.size():
			if _inv_shelf(k).grow(4).has_point(pos):
				inv_sel = k
				_inv_place(k)
				return
		return
	if type == "route" and step == 0:
		for n in _rt_neighbors(rt_at):
			if pos.distance_to(rt_nodes[n]) < 26.0:
				_rt_go(n)
				return
		return
	if type == "collect":
		finger = pos if step != 2 else Vector2(-1, -1)
	elif type == "wires" and step == 0:
		# tocca un filo a sinistra, poi il posto a destra dove va
		var y0 := BOX.position.y + 26
		var gap := (BOX.size.y - 52) / 3.0
		var row := clampi(int(round((pos.y - y0) / gap)), 0, 3)
		if pos.x < BOX.get_center().x:
			if row not in wire_done:
				wire_pick = row
				wire_sel = row
				Sound.sfx("select")
		elif wire_pick >= 0:
			wire_sel = row
			_wire_connect()


# --- SCATOLE E SCAFFALI ---------------------------------------------------------

func _inv_shelf(k: int) -> Rect2:
	return Rect2(INV.position.x + 10 + k * 102, INV.position.y + 110, 90, 76)


func _inv_place(k: int) -> void:
	if inv_queue.is_empty() or phase != "play":
		return
	var g: Array = inv_queue[0]
	if int(g[1]) == k:
		inv_queue.pop_front()
		inv_done += 1
		inv_msg = ""
		Sound.sfx("coin", 1.1 + inv_done * 0.04)
		if inv_queue.is_empty():
			_finish(true)
	else:
		misses += 1
		flash = 0.3
		Sound.sfx("deny")
		inv_msg = "%s in %s? No. (Però una volta Leda ci ha trovato il sapone.)" % [str(g[0]), INV_CATS[k]]
		if misses >= int(cfg.get("misses", 3)):
			_finish(false)


# --- L'ULTIMA CONSEGNA ---------------------------------------------------------

func _rt_edge(a: int, b: int) -> Array:
	for e: Array in rt_edges:
		if (int(e[0]) == a and int(e[1]) == b) or (int(e[0]) == b and int(e[1]) == a):
			return e
	return []


func _rt_neighbors(a: int) -> Array:
	var out: Array = []
	for e: Array in rt_edges:
		if int(e[0]) == a:
			out.append(int(e[1]))
		elif int(e[1]) == a:
			out.append(int(e[0]))
	# in ordine da sinistra a destra (e dall'alto in basso): così le frecce vanno dove ti aspetti
	out.sort_custom(func(x: int, y: int) -> bool: return rt_nodes[x].x * 1000 + rt_nodes[x].y < rt_nodes[y].x * 1000 + rt_nodes[y].y)
	return out


## Vai all'incrocio `n` (deve essere vicino). La strada rischiosa a volte ha il cantiere.
func _rt_go(n: int) -> void:
	if rt_k < 1.0 or phase != "play":
		return
	var e := _rt_edge(rt_at, n)
	if e.is_empty():
		return
	var cost := int(e[2])
	rt_msg = ""
	if bool(e[3]) and rt_rng.randf() < RT_RISK:
		cost += RT_DETOUR
		rt_msg = "Cantiere! Giri intorno: +%d minuti." % RT_DETOUR
		flash = 0.3
		Sound.sfx("hurt")
	else:
		Sound.sfx("move")
	rt_from = rt_nodes[rt_at]
	rt_to = rt_nodes[n]
	rt_k = 0.0
	rt_at = n
	rt_sel = 0
	if cost > rt_left:
		rt_left = 0
		rt_msg = "Tempo scaduto a metà strada."
		_rt_map_over()
		return
	rt_left -= cost
	if n in rt_parcels and n not in rt_done:
		rt_done.append(n)
		Sound.sfx("coin")
		if rt_done.size() >= rt_parcels.size():
			_rt_map_over()
			return
	# se non c'è più tempo nemmeno per la strada più corta, è finita
	var shortest := 999
	for m in _rt_neighbors(rt_at):
		shortest = mini(shortest, int(_rt_edge(rt_at, m)[2]))
	if shortest > rt_left:
		_rt_map_over()


## Prepara il giro `i`: la sua mappa, il suo tempo, il cuore al magazzino.
func _rt_load(i: int) -> void:
	var m: Dictionary = RT_MAPS[i]
	rt_map = i
	rt_nodes = m["nodes"]
	rt_names = m["names"]
	rt_edges = m["edges"]
	rt_parcels = m["parcels"]
	rt_left = int(cfg.get("budget", m["budget"])) if i == 0 else int(m["budget"])
	rt_done = []
	rt_at = 0
	rt_sel = 0
	rt_k = 1.0
	rt_from = rt_nodes[0]
	rt_to = rt_nodes[0]


func _rt_all() -> int:
	var n := 0
	for m: Dictionary in RT_MAPS:
		n += (m["parcels"] as Array).size()
	return n


## Il giro è finito: i pacchi consegnati si sommano, e se c'è ancora il pomeriggio si riparte.
func _rt_map_over() -> void:
	rt_total += rt_done.size()
	if rt_map + 1 < RT_MAPS.size():
		var got := rt_done.size()
		_rt_load(rt_map + 1)
		rt_msg = "Mattina finita (%d pacchi su 3). Ora il pomeriggio: altri tre." % got
		Sound.sfx("ding")
		return
	_rt_end()


func _rt_end() -> void:
	var n := rt_total
	phase = "end"
	await get_tree().create_timer(0.7).timeout
	_finish(n >= _rt_all(), n > 0 and n < _rt_all())


func _new_zone() -> void:
	var w := maxf(0.1, 0.2 - hits * 0.025)
	var a := randf_range(0.05, 0.95 - w)
	zone = Vector2(a, a + w)


func _next_round() -> void:
	round_n += 1
	seq.clear()
	typed.clear()
	for i in 3 + round_n:
		seq.append(ARROWS[randi() % 4])
	shown = 0
	show_t = 0.8
	phase = "show"
	_info.text = "Guarda bene... (%d/2)" % round_n


var t_spin := 0.0


func _process(delta: float) -> void:
	flash = maxf(0.0, flash - delta)
	t_spin += delta * 4.0
	rt_k = minf(1.0, rt_k + delta * 2.0)
	match phase:
		"play":
			if type == "timing":
				marker += marker_dir * marker_speed * delta
				if marker > 1.0 or marker < 0.0:
					marker = clampf(marker, 0.0, 1.0)
					marker_dir = -marker_dir
			elif type == "bulbs" or type == "wires":
				bulb_t += delta
				time_left -= delta
				if type == "bulbs":
					_info.text = "Tempo: %d   Smistate: %d/%d   Errori: %d/4" % [int(ceil(time_left)), bulb_done, int(cfg.get("count", 10)), misses]
				else:
					_info.text = "Tempo: %d   Pannello %d/2   Errori: %d/4" % [int(ceil(time_left)), wire_round + 1, misses]
				if time_left <= 0.0:
					_finish(false)
			elif type == "rate":
				if rate_phase == "order":
					_info.text = "Documenti in ordine: %d/%d   Errori: %d/3" % [rate_placed.size(), rate_cards.size(), misses]
				else:
					_info.text = "Trova la voce doppia   Errori: %d/3" % misses
			elif type == "pratiche":
				_info.text = "Pratica %d/%d   Errori: %d/%d" % [mini(pr_i + 1, _pr_list().size()), _pr_list().size(), misses, int(cfg.get("misses", 2))]
			elif type == "stanze":
				_info.text = "Pezzi sistemati: %d/%d   Errori: %d/3" % [st_where.size() - st_where.count(-1), st_where.size(), misses]
			elif type == "percorso":
				_info.text = "Spesa: %d €   Arrivo: %s   Errori: %d/3" % [_pc_cost(), _clock(_pc_arrival()), misses]
			elif type == "inventory":
				time_left -= delta
				_info.text = "Tempo: %d   Sistemati: %d/%d   Errori: %d/%d" % [int(ceil(time_left)), inv_done, inv_done + inv_queue.size(), misses, int(cfg.get("misses", 3))]
				if time_left <= 0.0:
					_finish(false)
			elif type == "collect":
				if finger.x >= 0.0:
					soul = soul.move_toward(finger, 140.0 * delta)
				else:
					soul += Input.get_vector("move_left", "move_right", "move_up", "move_down") * 140.0 * delta
				soul = soul.clamp(BOX.position + Vector2(8, 8), BOX.end - Vector2(8, 8))
				for i in range(items.size() - 1, -1, -1):
					if items[i].distance_to(soul) < 10.0:
						items.remove_at(i)
						Sound.sfx("blip", 1.5)
				hurt_t = maxf(0.0, hurt_t - delta)
				for h in hazards:
					var hp: Vector2 = h["pos"]
					var hv: Vector2 = h["vel"]
					hp += hv * delta
					if hp.x < BOX.position.x + 8 or hp.x > BOX.end.x - 8:
						hv.x = -hv.x
					if hp.y < BOX.position.y + 8 or hp.y > BOX.end.y - 8:
						hv.y = -hv.y
					h["pos"] = hp.clamp(BOX.position + Vector2(8, 8), BOX.end - Vector2(8, 8))
					h["vel"] = hv
					if hurt_t <= 0.0 and hp.distance_to(soul) < 11.0:
						hurt_t = 1.0
						time_left -= 2.0
						flash = 0.3
						Sound.sfx("hurt")
				time_left -= delta
				_info.text = "Tempo: %d   Mancano: %d" % [int(ceil(time_left)), items.size()]
				if items.is_empty():
					_finish(true)
				elif time_left <= 0.0:
					_finish(false)
		"show":
			show_t -= delta
			if show_t <= 0.0:
				shown += 1
				show_len = maxf(0.55, 0.85 - round_n * 0.1)
				show_t = show_len
				if shown <= seq.size():
					Sound.sfx("blip", ARROW_PITCH[seq[shown - 1]])
				if shown > seq.size():
					phase = "play"
					_info.text = "Ora ripeti: tocca sopra, sotto, a sinistra o a destra!" if TouchControls.enabled else "Ora ripeti con le frecce!"
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if phase != "play":
		return
	# sul PC i giochi "a dito" si fanno anche col mouse
	if type in ["inventory", "route", "rate", "pratiche", "stanze", "percorso"] and event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and not TouchControls.enabled:
		touch_point((event as InputEventMouseButton).position, 0)
		return
	if type == "inventory":
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
			inv_sel = posmod(inv_sel + (-1 if event.is_action_pressed("move_left") else 1), INV_CATS.size())
			Sound.sfx("move")
		elif event.is_action_pressed("confirm"):
			_inv_place(inv_sel)
		return
	if type == "rate":
		var n := rate_cards.size() if rate_phase == "order" else _rate_rows().size()
		var step := 0
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_up"):
			step = -1
		elif event.is_action_pressed("move_right") or event.is_action_pressed("move_down"):
			step = 1
		if step != 0:
			for i in n:
				rate_sel = posmod(rate_sel + step, n)
				if rate_phase != "order" or int(rate_cards[rate_sel]) not in rate_placed:
					break
			Sound.sfx("move")
		elif event.is_action_pressed("confirm"):
			if rate_phase == "order":
				_rate_pick(rate_sel)
			else:
				_rate_row_pick(rate_sel)
		return
	if type == "stanze" or type == "percorso":
		var targets := _st_targets() if type == "stanze" else _pc_targets()
		var d := 0
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_up"):
			d = -1
		elif event.is_action_pressed("move_right") or event.is_action_pressed("move_down"):
			d = 1
		if d != 0:
			if type == "stanze":
				st_focus = posmod(st_focus + d, targets.size())
			else:
				pc_focus = posmod(pc_focus + d, targets.size())
			Sound.sfx("move")
		elif event.is_action_pressed("confirm") and not targets.is_empty():
			var f := st_focus if type == "stanze" else pc_focus
			var t: Array = targets[clampi(f, 0, targets.size() - 1)]
			if type == "stanze":
				_st_act(t[0])
			else:
				_pc_act(t[0])
		return
	if type == "pratiche":
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
			pr_sel = posmod(pr_sel + (-1 if event.is_action_pressed("move_left") else 1), _pr_types().size())
			Sound.sfx("move")
		elif event.is_action_pressed("confirm"):
			_pr_answer(pr_sel)
		return
	if type == "route":
		var nb := _rt_neighbors(rt_at)
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_up"):
			rt_sel = posmod(rt_sel - 1, nb.size())
			Sound.sfx("move")
		elif event.is_action_pressed("move_right") or event.is_action_pressed("move_down"):
			rt_sel = posmod(rt_sel + 1, nb.size())
			Sound.sfx("move")
		elif event.is_action_pressed("confirm"):
			_rt_go(int(nb[clampi(rt_sel, 0, nb.size() - 1)]))
		return
	var tapped := event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed
	if type == "timing" and (event.is_action_pressed("confirm") or tapped):
		if marker >= zone.x and marker <= zone.y:
			hits += 1
			Sound.sfx("select")
			marker_speed += 0.2
			_new_zone()
			if hits >= int(cfg.get("hits", 4)):
				_finish(true)
		else:
			misses += 1
			flash = 0.25
			Sound.sfx("deny")
			if misses >= 3:
				_finish(false)
	elif type == "bulbs":
		if event.is_action_pressed("move_right"):
			_bulb_answer(bulb == "buona")
		elif event.is_action_pressed("move_left"):
			_bulb_answer(bulb == "rotta")
		elif event.is_action_pressed("move_up") or event.is_action_pressed("move_down"):
			if bulb == "fioca":
				bulb_fix += 1
				Sound.sfx("move", 1.0 + bulb_fix * 0.2)
				if bulb_fix >= 2:
					bulb = "buona"
			else:
				_bulb_answer(false)
	elif type == "wires":
		var free_left: Array[int] = []
		for i in 4:
			if i not in wire_done:
				free_left.append(i)
		if event.is_action_pressed("move_up") or event.is_action_pressed("move_down"):
			var step := -1 if event.is_action_pressed("move_up") else 1
			if wire_pick < 0:
				var at := free_left.find(wire_sel)
				wire_sel = free_left[posmod(at + step, free_left.size())]
			else:
				wire_sel = posmod(wire_sel + step, 4)
			Sound.sfx("move")
		elif event.is_action_pressed("confirm") or event.is_action_pressed("move_right") or tapped:
			if wire_pick < 0:
				wire_pick = wire_sel
				wire_sel = 0
				Sound.sfx("select")
			else:
				_wire_connect()
		elif event.is_action_pressed("move_left") and wire_pick >= 0:
			wire_sel = wire_pick
			wire_pick = -1
	elif type == "sequence":
		for a: String in ARROWS:
			if event.is_action_pressed("move_" + a):
				typed.append(a)
				Sound.sfx("blip", ARROW_PITCH[a])
				if typed[typed.size() - 1] != seq[typed.size() - 1]:
					flash = 0.3
					Sound.sfx("deny")
					misses += 1
					if misses >= 2:
						_finish(false)
					else:
						round_n -= 1
						_next_round()
					return
				if typed.size() == seq.size():
					if round_n >= 2:
						_finish(true)
					else:
						Sound.sfx("select")
						_next_round()
				return


func _finish(success: bool, partial := false) -> void:
	if phase == "done":
		return
	phase = "done"
	won = success
	var who := str(cfg.get("name", ""))
	var id := str(cfg.get("id", ""))
	# di solito dare una mano conta anche se va male; per Leda e Amir conta solo se riesce (o a metà)
	if success or not cfg.get("help_on_win_only", false) or (partial and cfg.get("help_on_partial", false)):
		GameState.help(id, "time", GameState.COST_HELP_TIME)
	else:
		GameState.spend(GameState.COST_HELP_TIME)
	for f in cfg.get("win_flags" if success else ("partial_flags" if partial else "no_flags"), []):
		GameState.flags[str(f)] = true
	if cfg.has("quest"):
		# Il giorno dopo chi te l'ha chiesto ti dirà com'è andata.
		GameState.flags["quest_news_" + str(cfg["quest"])] = "done" if success else "fail"
	var lines: Array = []
	if success:
		Sound.sfx("spare")
		var reward := int(cfg.get("reward", 10))
		GameState.money += reward
		GameState.changed.emit()
		lines.append_array(cfg.get("win", ["Grazie!"]))
		if reward > 0:
			lines.append("Tieni, non è molto, ma te li sei guadagnati.")
			lines.append("* %s ti dà %s." % [who, GameState.euros(reward)])
		if cfg.has("item"):
			GameState.give_item(str(cfg["item"]))
			lines.append("* (Hai ricevuto: %s.)" % str(cfg["item"]))
	elif partial:
		Sound.sfx("select")
		lines.append_array(cfg.get("partial", ["È andata a metà. Meglio di niente."]))
	else:
		lines.append_array(cfg.get("lose", ["Non fa niente, grazie lo stesso."]))
		lines.append("* Non è andata benissimo, ma %s apprezza che ci hai provato." % who)
	# quello che il minigioco ha deciso (com'è diventata la Casa, che strada fa Nadir) viene prima
	if success and cfg.has("_extra"):
		lines = (cfg["_extra"] as Array) + lines
	await Ui.say(lines, who)
	Router.goto(str(cfg.get("return", Router.STREET)), "_mg")


func _draw() -> void:
	var font := Assets.font()
	var frame := INV if type == "inventory" else (BIG if type in ["rate", "pratiche", "stanze", "percorso"] else BOX)
	if type == "route":
		draw_rect(Rect2(0, 0, 640, 360), Color.BLACK)
		draw_rect(frame, Color.BLACK)
		draw_rect(frame, Color.WHITE, false, 3.0)
	else:
		Art.backdrop(self)
		Art.panel(self, frame, Color("24313e"), Color("829caa"))
	match type:
		"rate":
			_draw_rate(font)
		"pratiche":
			_draw_pratiche(font)
		"stanze":
			_draw_stanze(font)
		"percorso":
			_draw_percorso(font)
		"timing":
			var bar := Rect2(BOX.position.x + 20, BOX.get_center().y - 10, BOX.size.x - 40, 20)
			Art.panel(self, bar.grow(3), Color("46566b"), Color("94a7b9"))
			draw_rect(Rect2(bar.position.x + bar.size.x * zone.x, bar.position.y, bar.size.x * (zone.y - zone.x), bar.size.y), GREEN)
			var mx := bar.position.x + bar.size.x * marker
			draw_rect(Rect2(mx - 2, bar.position.y - 8, 4, bar.size.y + 16), Color.WHITE)
			draw_string(font, Vector2(BOX.position.x, BOX.end.y - 16), "Riusciti %d/%d    Errori %d/3" % [hits, int(cfg.get("hits", 4)), misses],
				HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 16, Color.WHITE)
		"collect":
			var col := Color(str(cfg.get("color", "#e0a030")))
			for it in items:
				Art.collectible(self, it, col, str(cfg.get("title", "")))
			# gli imprevisti: rossi, con le punte
			for h in hazards:
				var hp: Vector2 = h["pos"]
				draw_circle(hp, 6, Color("c0302a"))
				for k in 4:
					var a := t_spin + k * PI / 2.0
					draw_line(hp, hp + Vector2.from_angle(a) * 10.0, Color("ff6a5a"), 2.0)
			if hurt_t <= 0.0 or int(hurt_t * 12) % 2 == 0:
				_heart(soul, RED)
		"bulbs":
			_draw_bulbs(font)
		"wires":
			_draw_wires(font)
		"inventory":
			_draw_inventory(font)
		"route":
			_draw_route(font)
		"sequence":
			var cx := BOX.get_center()
			# la freccia resta accesa per due terzi del tempo, poi si spegne: così si vede quando cambia
			if phase == "show" and shown >= 1 and shown <= seq.size() and show_t > show_len * 0.33:
				_arrow(cx, seq[shown - 1], 18.0, YELLOW)
			if phase == "show" and shown >= 1 and shown <= seq.size():
				draw_string(font, Vector2(BOX.position.x, BOX.end.y - 14), "%d / %d" % [shown, seq.size()], HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 14, Color("8a8494"))
			elif phase == "play":
				var n := seq.size()
				for i in n:
					var p := Vector2(cx.x + (i - (n - 1) / 2.0) * 34.0, cx.y)
					if i < typed.size():
						_arrow(p, typed[i], 10.0, Color.WHITE)
					else:
						draw_rect(Rect2(p + Vector2(-8, 8), Vector2(16, 2)), Color("8a8494"))
	if flash > 0.0:
		draw_rect(INV if type == "inventory" else BOX, Color(1, 0.2, 0.2, flash))


func _draw_bulbs(font: Font) -> void:
	Art.panel(self, BOX.grow(-5), Color("3c4d5c"), Color("91abb7"))
	var c := BOX.get_center() + Vector2(0, -6)
	Art.carton(self, Rect2(BOX.position.x + 14, BOX.end.y - 56, 70, 44), Color("c46363"), true)
	draw_string(font, Vector2(BOX.position.x + 14, BOX.end.y - 62), "< ROTTE", HORIZONTAL_ALIGNMENT_CENTER, 70, 12, Color("ff8b84"))
	Art.carton(self, Rect2(BOX.end.x - 84, BOX.end.y - 56, 70, 44), Color("75b47c"), true)
	draw_string(font, Vector2(BOX.end.x - 84, BOX.end.y - 62), "BUONE >", HORIZONTAL_ALIGNMENT_CENTER, 70, 12, GREEN)
	Art.bulb(self, Vector2(BOX.position.x + 45, BOX.end.y - 33), "rotta", 1, false)
	Art.bulb(self, Vector2(BOX.end.x - 50, BOX.end.y - 33), "buona", 1)
	var lit := bulb == "buona" or (bulb == "fioca" and int(bulb_t * 9) % 3 != 0)
	Art.bulb(self, c, bulb, 3, lit)
	if bulb == "fioca":
		draw_string(font, Vector2(BOX.position.x, BOX.position.y + 18), ("Sfarfalla! Scorri su o giù (%d/2)" if TouchControls.enabled else "Sfarfalla! SU o GIÙ per avvitarla (%d/2)") % bulb_fix, HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 11, YELLOW)


# --- LE RATE MANCANTI (Olga) ------------------------------------------------------

func _rate_docs() -> Array:
	return GameState.bank.get("olga", {}).get("documenti", [])


func _rate_statement() -> Dictionary:
	return GameState.bank.get("olga", {}).get("estratto", {})


func _rate_rows() -> Array:
	return _rate_statement().get("righe", [])


## Le carte sul tavolo: tre per riga, due righe.
func _rate_card(k: int) -> Rect2:
	return Rect2(BIG.position.x + 10 + (k % 3) * 184, BIG.position.y + 8 + (k / 3) * 68, 172, 62)


## Lo spazio della linea del tempo (sotto le carte), dove finiscono quelle già in ordine.
func _rate_slot(i: int) -> Rect2:
	return Rect2(BIG.position.x + 10 + i * 91, BIG.position.y + 146, 85, 44)


func _rate_row(i: int) -> Rect2:
	return Rect2(BIG.position.x + 20, BIG.position.y + 58 + i * 26, BIG.size.x - 40, 22)


func _rate_pick(k: int) -> void:
	if phase != "play" or rate_phase != "order" or k < 0 or k >= rate_cards.size():
		return
	var doc := int(rate_cards[k])
	if doc in rate_placed:
		return
	if doc == rate_placed.size():
		rate_placed.append(doc)
		rate_msg = ""
		Sound.sfx("stamp" if rate_placed.size() == rate_cards.size() else "select", 1.0 + rate_placed.size() * 0.05)
		if rate_placed.size() == rate_cards.size():
			rate_phase = "find"
			rate_sel = 0
			rate_msg = "In ordine. Ora l'estratto conto: una commissione per lo stesso ritardo è addebitata due volte. Tocca la riga di troppo."
		else:
			for i in rate_cards.size():
				if int(rate_cards[i]) not in rate_placed:
					rate_sel = i
					break
	else:
		_rate_miss("Questo viene dopo. Guarda le date.")


func _rate_row_pick(i: int) -> void:
	if phase != "play" or rate_phase != "find":
		return
	if i in _rate_statement().get("doppie", []):
		Sound.sfx("stamp")
		_finish(true)
	else:
		_rate_miss("Questa voce c'è una volta sola. Una per ogni cosa, dice il contratto.")


func _rate_miss(msg: String) -> void:
	misses += 1
	flash = 0.3
	rate_msg = msg
	Sound.sfx("deny")
	if misses >= 3:
		_finish(false)


## 1485 -> "1.485,00 €"; -35 -> "−35,00 €".
static func _eur(v: int) -> String:
	var s := GameState.euros(absi(v)).trim_suffix(" €")
	return ("−" if v < 0 else ("+" if v > 0 else "")) + s + ",00 €"


func _draw_rate(font: Font) -> void:
	draw_rect(BIG.grow(-4), Color("2b2430"))
	var docs := _rate_docs()
	if rate_phase == "order":
		for k in rate_cards.size():
			var doc := int(rate_cards[k])
			var r := _rate_card(k)
			if doc in rate_placed:
				draw_rect(r, Color("3a3340"))
				continue
			var d: Dictionary = docs[doc]
			draw_rect(r, PracticeCard.PAPER)
			var sel := k == rate_sel and not TouchControls.enabled
			draw_rect(r, YELLOW if sel else Color.WHITE, false, 3.0 if sel else 2.0)
			draw_string(font, r.position + Vector2(8, 17), str(d["titolo"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 16, 10, PracticeCard.INK)
			draw_string(font, r.position + Vector2(8, 31), str(d["data"]), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 16, 10, Color("c0302a"))
			# il dettaglio va a capo (due righe): "una per ogni ritardo" deve leggersi tutto
			draw_multiline_string(font, r.position + Vector2(8, 44), str(d["testo"]), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 16, 7, 2, PracticeCard.FAINT)
		for i in rate_cards.size():
			var s := _rate_slot(i)
			draw_rect(s, Color("1a161e"))
			draw_rect(s, Color("5c5666"), false, 1.0)
			draw_string(font, s.position + Vector2(4, 12), "%d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("8a8494"))
			if i < rate_placed.size():
				var d: Dictionary = docs[int(rate_placed[i])]
				draw_string(font, s.position + Vector2(4, 27), str(d["titolo"]), HORIZONTAL_ALIGNMENT_LEFT, s.size.x - 8, 8, Color.WHITE)
				draw_string(font, s.position + Vector2(4, 39), str(d["data"]), HORIZONTAL_ALIGNMENT_LEFT, s.size.x - 8, 8, YELLOW)
	else:
		var st := _rate_statement()
		var paper := Rect2(BIG.position.x + 10, BIG.position.y + 8, BIG.size.x - 20, 200)
		draw_rect(paper, PracticeCard.PAPER)
		draw_string(font, paper.position + Vector2(0, 20), str(st.get("titolo", "")), HORIZONTAL_ALIGNMENT_CENTER, paper.size.x, 12, PracticeCard.INK)
		draw_string(font, paper.position + Vector2(12, 40), "Saldo al 01/06", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, PracticeCard.FAINT)
		draw_string(font, paper.position + Vector2(0, 40), _eur(int(st.get("saldo_iniziale", 0))).trim_prefix("+"), HORIZONTAL_ALIGNMENT_RIGHT, paper.size.x - 12, 10, PracticeCard.FAINT)
		var rows := _rate_rows()
		for i in rows.size():
			var row: Array = rows[i]
			var r := _rate_row(i)
			var sel := i == rate_sel and not TouchControls.enabled
			draw_rect(r, Color("e8e2d0") if i % 2 == 0 else PracticeCard.PAPER)
			if sel:
				draw_rect(r, Color("c08a00"), false, 2.0)
			draw_string(font, r.position + Vector2(8, 15), str(row[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, PracticeCard.INK)
			draw_string(font, r.position + Vector2(64, 15), str(row[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, PracticeCard.INK)
			draw_string(font, r.position + Vector2(0, 15), _eur(int(row[2])), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 8, 10, Color("c0302a") if int(row[2]) < 0 else Color("2a8a4a"))
		var fy := _rate_row(rows.size()).position.y + 16
		draw_string(font, Vector2(paper.position.x + 12, fy), "Saldo al 30/06", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, PracticeCard.INK)
		draw_string(font, Vector2(paper.position.x, fy), _eur(int(st.get("saldo_finale", 0))).trim_prefix("+"), HORIZONTAL_ALIGNMENT_RIGHT, paper.size.x - 12, 11, PracticeCard.INK)
	if rate_msg != "":
		draw_string(font, Vector2(BIG.position.x, BIG.end.y - 14), rate_msg, HORIZONTAL_ALIGNMENT_CENTER, BIG.size.x, 10, Color("ffb0b0") if flash > 0.0 else Color("c8c0d0"))


# --- LA PRATICA IMPOSSIBILE (Teo) ------------------------------------------------------

# --- UNA STANZA PER TUTTI (Ada) ----------------------------------------------------------

func _st_rooms() -> Array:
	return GameState.city.get("stanze", {}).get("stanze", [])


func _st_pieces() -> Array:
	return GameState.city.get("stanze", {}).get("pezzi", [])


func _st_room(r: int) -> Rect2:
	return Rect2(BIG.position.x + 10 + r * 184, BIG.position.y + 8, 172, 118)


## Il posto del pezzo i: nel vassoio in basso, o dentro la sua stanza (uno sotto l'altro).
func _st_piece(i: int) -> Rect2:
	var r := int(st_where[i])
	if r < 0:
		return Rect2(BIG.position.x + 10 + i * 78, BIG.position.y + 140, 72, 40)
	var k := 0
	for j in i:
		if int(st_where[j]) == r:
			k += 1
	var room := _st_room(r)
	return Rect2(room.position.x + 8, room.position.y + 46 + k * 23, room.size.x - 16, 20)


func _st_done_button() -> Rect2:
	return Rect2(BIG.end.x - 130, BIG.end.y - 46, 120, 36)


## Cosa si può toccare, in ordine (anche per le frecce): i pezzi, le stanze, FATTO.
func _st_targets() -> Array:
	var out: Array = []
	for i in st_where.size():
		out.append(["p%d" % i, _st_piece(i)])
	for r in _st_rooms().size():
		out.append(["r%d" % r, _st_room(r)])
	out.append(["done", _st_done_button()])
	return out


func _st_act(what: String) -> void:
	if phase != "play":
		return
	if what == "done":
		_st_check()
	elif what.begins_with("p"):
		var i := int(what.substr(1))
		if int(st_where[i]) >= 0:
			# un pezzo già in una stanza torna nel vassoio
			st_where[i] = -1
			st_sel = i
		else:
			st_sel = -1 if st_sel == i else i
		Sound.sfx("select")
	elif what.begins_with("r") and st_sel >= 0:
		var r := int(what.substr(1))
		var room: Dictionary = _st_rooms()[r]
		if st_where.count(r) >= int(room.get("max", 3)):
			st_msg = "Nella stanza %s non c'è più posto." % str(room["nome"]).to_lower()
			Sound.sfx("deny")
			return
		st_where[st_sel] = r
		st_sel = -1
		st_msg = ""
		Sound.sfx("clunk", 1.2)


## Va bene ogni distribuzione in cui tutte le stanze si possono usare. Nessuna è "quella giusta".
func _st_check() -> void:
	if st_where.has(-1):
		st_msg = "Restano dei pezzi da sistemare."
		Sound.sfx("deny")
		return
	var pieces := _st_pieces()
	for r in _st_rooms().size():
		var room: Dictionary = _st_rooms()[r]
		var ok := false
		for i in pieces.size():
			ok = ok or (int(st_where[i]) == r and pieces[i]["tipo"] == room["serve"])
		if not ok:
			misses += 1
			flash = 0.3
			st_msg = str(room["desc"])
			Sound.sfx("deny")
			if misses >= 3:
				_finish(false)
			return
	# com'è diventata la Casa: una riga per ogni pezzo in più
	var fx: Dictionary = GameState.city.get("stanze", {}).get("effetti", {})
	var extra: Array = []
	var counts := [0, 0, 0]
	for r in _st_rooms().size():
		var room: Dictionary = _st_rooms()[r]
		var used_need := false
		for i in pieces.size():
			if int(st_where[i]) != r:
				continue
			counts[r] += 1
			if pieces[i]["tipo"] == room["serve"] and not used_need:
				used_need = true
				continue
			extra.append("* " + str(fx.get(room["id"], {}).get(pieces[i]["tipo"], "")))
	GameState.flags["c5_stanze"] = counts
	cfg["_extra"] = extra
	Sound.sfx("stamp")
	_finish(true)


func _draw_stanze(font: Font) -> void:
	draw_rect(BIG.grow(-4), Color("26302a"))
	var pieces := _st_pieces()
	# durante l'introduzione i pezzi non sono ancora sul vassoio
	if st_where.size() != pieces.size():
		return
	var targets := _st_targets()
	var focus := "" if TouchControls.enabled or targets.is_empty() else str(targets[clampi(st_focus, 0, targets.size() - 1)][0])
	for r in _st_rooms().size():
		var room: Dictionary = _st_rooms()[r]
		var rr := _st_room(r)
		Art.panel(self, rr, Color("3a4a3e"), Color("8fae96"))
		draw_rect(rr, YELLOW if focus == "r%d" % r else Color("8fae96"), false, 2.0)
		draw_string(font, rr.position + Vector2(0, 16), str(room["nome"]), HORIZONTAL_ALIGNMENT_CENTER, rr.size.x, 11, Color.WHITE)
		draw_string(font, rr.position + Vector2(0, 32), "serve: %s   (%d/%d)" % [str(room["serve"]), st_where.count(r), int(room.get("max", 3))],
			HORIZONTAL_ALIGNMENT_CENTER, rr.size.x, 8, Color("c6e1d1"))
	for i in pieces.size():
		var pr := _st_piece(i)
		var col := Color("e8dcc0") if i != st_sel else YELLOW
		Art.paper(self, pr, col)
		draw_rect(pr, YELLOW if focus == "p%d" % i else Color("5a4a36"), false, 2.0)
		var p: Dictionary = pieces[i]
		if int(st_where[i]) < 0:
			Art.furniture(self, Rect2(pr.position + Vector2(4, 3), Vector2(pr.size.x - 8, 20)), str(p["tipo"]))
			draw_string(font, pr.position + Vector2(0, 34), str(p["nome"]), HORIZONTAL_ALIGNMENT_CENTER, pr.size.x, 8, Color("2a2018"))
		else:
			Art.furniture(self, Rect2(pr.position + Vector2(3, 2), Vector2(20, 16)), str(p["tipo"]))
			draw_string(font, pr.position + Vector2(26, 14), "%s (%s)" % [str(p["nome"]), str(p["tipo"])], HORIZONTAL_ALIGNMENT_LEFT, pr.size.x - 30, 8, Color("2a2018"))
	var b := _st_done_button()
	PracticeCard.button(self, b, "FATTO", Color("2a8a4a"), font, focus == "done")
	draw_string(font, Vector2(BIG.position.x + 14, BIG.end.y - 24), st_msg, HORIZONTAL_ALIGNMENT_LEFT, BIG.size.x - 160, 9,
		Color("ffb0b0") if flash > 0.0 else Color("c8c0d0"))


# --- IL PERCORSO POSSIBILE (Nadir) -------------------------------------------------------

func _pc_data() -> Dictionary:
	return GameState.city.get("percorso", {})


func _pc_stop(i: int) -> Vector2:
	var p: Array = _pc_data()["fermate"][i]["pos"]
	return BIG.position + Vector2(float(p[0]), float(p[1]))


## Il cartellino di una tratta, a metà strada (la navetta, sulla stessa linea del treno, è spostata).
func _pc_label(e: int) -> Rect2:
	var t: Dictionary = _pc_data()["tratte"][e]
	var a := _pc_stop(int(t["da"]))
	var b := _pc_stop(int(t["a"]))
	var mid := (a + b) / 2.0
	if int(t.get("curva", 0)) != 0:
		mid += (b - a).orthogonal().normalized() * -36.0
	var w := 80.0 if absf(a.x - b.x) < 1.0 else 104.0
	return Rect2(mid - Vector2(w / 2.0, 15), Vector2(w, 30))


func _pc_reset_button() -> Rect2:
	return Rect2(BIG.end.x - 120, BIG.end.y - 40, 110, 30)


func _pc_targets() -> Array:
	var out: Array = []
	for e in (_pc_data()["tratte"] as Array).size():
		out.append(["e%d" % e, _pc_label(e)])
	out.append(["reset", _pc_reset_button()])
	return out


func _pc_cost() -> int:
	var c := 0
	for e in pc_path:
		c += int(_pc_data()["tratte"][e]["euro"])
	return c


func _pc_arrival() -> int:
	var t := int(_pc_data().get("partenza", 400))
	for e in pc_path:
		t += int(_pc_data()["tratte"][e]["min"])
	return t


static func _clock(minutes: int) -> String:
	return "%d:%02d" % [minutes / 60, minutes % 60]


func _pc_visited() -> Array:
	var v: Array = [0]
	for e in pc_path:
		var t: Dictionary = _pc_data()["tratte"][e]
		v.append(int(t["a"]) if int(t["da"]) in v else int(t["da"]))
	return v


func _pc_act(what: String) -> void:
	if phase != "play":
		return
	if what == "reset":
		pc_path = []
		pc_at = 0
		pc_msg = "Si riparte da casa di Nadir."
		Sound.sfx("select")
		return
	var e := int(what.substr(1))
	var t: Dictionary = _pc_data()["tratte"][e]
	var other := -1
	if int(t["da"]) == pc_at:
		other = int(t["a"])
	elif int(t["a"]) == pc_at:
		other = int(t["da"])
	if other < 0 or other in _pc_visited():
		pc_msg = "Da %s questa tratta non parte." % str(_pc_data()["fermate"][pc_at]["nome"]).to_lower()
		Sound.sfx("deny")
		return
	pc_path.append(e)
	pc_at = other
	Sound.sfx("blip", 1.2)
	pc_msg = ""
	if pc_at == (_pc_data()["fermate"] as Array).size() - 1:
		_pc_check()


func _pc_check() -> void:
	var d := _pc_data()
	var late := _pc_arrival() > int(d.get("entrata", 480))
	var over := _pc_cost() > int(d.get("budget", 6))
	if late or over:
		misses += 1
		flash = 0.3
		Sound.sfx("deny")
		if late:
			pc_msg = "Arriveresti alle %s. Si entra alle %s." % [_clock(_pc_arrival()), _clock(int(d.get("entrata", 480)))]
		else:
			pc_msg = "%d € al giorno. Nadir ne ha %d." % [_pc_cost(), int(d.get("budget", 6))]
		pc_path = []
		pc_at = 0
		if misses >= 3:
			_finish(false)
		return
	GameState.flags["c5_nadir_tratta"] = pc_path.duplicate()
	cfg["_extra"] = ["* Partenza %s, arrivo %s, %d € al giorno." % [_clock(int(d.get("partenza", 400))), _clock(_pc_arrival()), _pc_cost()]]
	Sound.sfx("stamp")
	_finish(true)


func _draw_percorso(font: Font) -> void:
	draw_rect(BIG.grow(-4), Color("1e2a33"))
	var d := _pc_data()
	draw_string(font, BIG.position + Vector2(14, 20), "Partenza %s · Si entra alle %s · %d € al giorno" % [_clock(int(d.get("partenza", 400))),
		_clock(int(d.get("entrata", 480))), int(d.get("budget", 6))], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("c6d8e4"))
	var tratte: Array = d["tratte"]
	var targets := _pc_targets()
	var focus := "" if TouchControls.enabled or targets.is_empty() else str(targets[clampi(pc_focus, 0, targets.size() - 1)][0])
	for e in tratte.size():
		var t: Dictionary = tratte[e]
		var a := _pc_stop(int(t["da"]))
		var b := _pc_stop(int(t["a"]))
		var lab := _pc_label(e)
		var on := e in pc_path
		var col := YELLOW if on else Color("5f7a8c")
		if int(t.get("curva", 0)) != 0:
			draw_polyline(PackedVector2Array([a, lab.get_center(), b]), col, 3.0 if on else 2.0)
		else:
			draw_line(a, b, col, 3.0 if on else 2.0)
	for e in tratte.size():
		var t: Dictionary = tratte[e]
		var lab := _pc_label(e)
		draw_rect(lab, Color("f2ead8") if e not in pc_path else YELLOW)
		draw_rect(lab, YELLOW if focus == "e%d" % e else Color("2a3a46"), false, 2.0)
		draw_string(font, lab.position + Vector2(0, 12), str(t["nome"]).split(" (")[0], HORIZONTAL_ALIGNMENT_CENTER, lab.size.x, 8, Color("1e2a33"))
		draw_string(font, lab.position + Vector2(0, 25), "%d € · %d min" % [int(t["euro"]), int(t["min"])], HORIZONTAL_ALIGNMENT_CENTER, lab.size.x, 8, Color("8a3a2a"))
	var stops: Array = d["fermate"]
	for i in stops.size():
		var p := _pc_stop(i)
		draw_circle(p, 8.0, YELLOW if i == pc_at else (Color.WHITE if i in _pc_visited() else Color("8aa0b0")))
		var below := p.y > BIG.get_center().y
		draw_string(font, p + Vector2(-60, 22 if below else -13), str(stops[i]["nome"]), HORIZONTAL_ALIGNMENT_CENTER, 120, 8, Color.WHITE)
	PracticeCard.button(self, _pc_reset_button(), "RICOMINCIA", Color("4a5a6a"), font, focus == "reset", 11)
	draw_string(font, Vector2(BIG.position.x + 14, BIG.end.y - 20), pc_msg, HORIZONTAL_ALIGNMENT_LEFT, BIG.size.x - 150, 9,
		Color("ffb0b0") if flash > 0.0 else Color("c8c0d0"))


func _pr_list() -> Array:
	return GameState.bank.get("teo", {}).get("pratiche", [])


func _pr_types() -> Array:
	return GameState.bank.get("teo", {}).get("tipi", [])


func _pr_button(k: int) -> Rect2:
	var n := maxi(1, _pr_types().size())
	var w := (BIG.size.x - 20 - (n - 1) * 8) / float(n)
	return Rect2(BIG.position.x + 10 + k * (w + 8), BIG.end.y - 52, w, 44)


func _pr_answer(k: int) -> void:
	if phase != "play" or pr_i >= _pr_list().size():
		return
	var p: Dictionary = _pr_list()[pr_i]
	if k == int(p.get("tipo", 0)):
		pr_i += 1
		pr_msg = "Pratica %s: controllata." % str(p.get("id", ""))
		Sound.sfx("stamp", 1.0 + pr_i * 0.05)
		if pr_i >= _pr_list().size():
			_finish(true)
	else:
		misses += 1
		flash = 0.3
		pr_msg = "Teo: \"Mmm. Rileggiamola. Riga per riga.\""
		Sound.sfx("deny")
		if misses >= int(cfg.get("misses", 2)):
			_finish(false)


func _draw_pratiche(font: Font) -> void:
	draw_rect(BIG.grow(-4), Color("1e2430"))
	if pr_i < _pr_list().size():
		PracticeCard.draw(self, Rect2(BIG.position.x + 110, BIG.position.y + 10, 340, 116), _pr_list()[pr_i], font)
	if pr_msg != "":
		draw_string(font, Vector2(BIG.position.x, BIG.position.y + 150), pr_msg, HORIZONTAL_ALIGNMENT_CENTER, BIG.size.x, 10, Color("ffb0b0") if flash > 0.0 else Color("c8c0d0"))
	var labels := ["TUTTO IN\nORDINE", "MANCA UN\nDOCUMENTO", "DATI\nDIVERSI", "DOPPIONE", "ERRORE DI\nREGISTRAZIONE"]
	for k in _pr_types().size():
		var text: String = labels[k] if k < labels.size() else str(_pr_types()[k])
		PracticeCard.button(self, _pr_button(k), text, Color("2a8a4a") if k == 0 else Color("3a4a6a"), font, k == pr_sel and not TouchControls.enabled, 9)


func _draw_inventory(font: Font) -> void:
	Art.panel(self, INV.grow(-4), Color("50433e"), Color("c8a57a"))
	var card := Rect2(INV.position + Vector2(14, 12), Vector2(INV.size.x - 28, 80))
	Art.paper(self, card, Color("eee4cc"))
	if not inv_queue.is_empty():
		var g: Array = inv_queue[0]
		Art.product(self, Rect2(card.position + Vector2(10, 6), Vector2(72, 68)), str(g[0]))
		draw_string(font, card.position + Vector2(96, 34), str(g[0]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 108, 17, Color("352b36"))
		draw_string(font, card.position + Vector2(96, 56), "IN QUALE SCAFFALE?", HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 108, 9, Color("7a6257"))
		draw_string(font, card.position + Vector2(96, 71), "Altri prodotti: %d" % maxi(0, inv_queue.size() - 1), HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 108, 8, Color("7a6257"))
	if inv_msg != "":
		draw_string(font, Vector2(INV.position.x, INV.position.y + 105), inv_msg, HORIZONTAL_ALIGNMENT_CENTER, INV.size.x, 9, Color("ffb7aa"))
	var examples := [["Pane", "Riso", "Biscotti"], ["Sapone", "Dentifricio", "Shampoo"], ["Matita", "Quaderno", "Righello"], ["Scopa", "Lampadina", "Spugna"]]
	for k in INV_CATS.size():
		var r := _inv_shelf(k)
		var col: Color = INV_COLS[k]
		Art.panel(self, r, Color("684b3d"), Color("c99c68"))
		draw_rect(Rect2(r.position + Vector2(3, 3), Vector2(r.size.x - 6, 20)), col.darkened(0.58))
		draw_string(font, r.position + Vector2(0, 16), INV_CATS[k], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 9, Art.CREAM)
		for i in 3:
			Art.product(self, Rect2(r.position + Vector2(5 + i * 27, 27), Vector2(26, 30)), str(examples[k][i]))
		draw_rect(Rect2(r.position + Vector2(3, 59), Vector2(r.size.x - 6, 5)), Color("c99c68"))
		draw_rect(Rect2(r.position + Vector2(3, 64), Vector2(r.size.x - 6, 5)), Color("4d3631"))
		if k == inv_sel and not TouchControls.enabled:
			draw_rect(r.grow(2), YELLOW, false, 2)
			draw_rect(Rect2(r.get_center().x - 4, r.end.y - 9, 8, 3), YELLOW)


func _draw_route(font: Font) -> void:
	draw_rect(BOX.grow(-4), Color("1e2430"))
	var nb := _rt_neighbors(rt_at)
	for e: Array in rt_edges:
		var a: Vector2 = rt_nodes[int(e[0])]
		var b: Vector2 = rt_nodes[int(e[1])]
		var risky := bool(e[3])
		if risky:
			# a tratti, rossa: il cantiere
			var steps := int(a.distance_to(b) / 8.0)
			for i in steps:
				if i % 2 == 0:
					draw_line(a.lerp(b, float(i) / steps), a.lerp(b, float(i + 1) / steps), Color("ff6a5a"), 3.0)
		else:
			draw_line(a, b, Color("8a8494"), 4.0)
		var mid := a.lerp(b, 0.5)
		draw_string(font, mid + Vector2(-14, -3), ("%d'?" if risky else "%d'") % int(e[2]), HORIZONTAL_ALIGNMENT_CENTER, 28, 9, Color("ff9a8a") if risky else Color("c8c0d0"))
	for i in rt_nodes.size():
		var p: Vector2 = rt_nodes[i]
		var col := Color("4a4a5a")
		if i in rt_parcels:
			col = GREEN if i in rt_done else YELLOW
		draw_circle(p, 9, col)
		if i in nb and rt_k >= 1.0 and phase == "play":
			var sel := nb.find(i) == rt_sel and not TouchControls.enabled
			draw_arc(p, 13, 0, TAU, 20, Color.WHITE if sel else Color(1, 1, 1, 0.45), 3.0 if sel else 1.5)
		if rt_names[i] != "":
			# il magazzino ha la scritta sopra, se no copre i minuti della strada
			draw_string(font, p + Vector2(-40, -14 if i == 0 else 22), rt_names[i], HORIZONTAL_ALIGNMENT_CENTER, 80, 8, Color("c8c0d0"))
	_heart(rt_from.lerp(rt_to, rt_k), RED)
	draw_string(font, Vector2(BOX.position.x + 10, BOX.position.y + 18), "TEMPO RIMASTO: %02d:%02d" % [rt_left / 60, rt_left % 60], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, YELLOW)
	draw_string(font, Vector2(BOX.end.x - 160, BOX.position.y + 18), "%s %d/%d" % [str(RT_MAPS[rt_map]["title"]), rt_done.size(), rt_parcels.size()], HORIZONTAL_ALIGNMENT_RIGHT, 150, 11, Color.WHITE)
	if rt_msg != "":
		draw_string(font, Vector2(BOX.position.x, BOX.end.y - 8), rt_msg, HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 9, Color("ff9a8a"))


func _draw_wires(font: Font) -> void:
	if wire_right.size() < 4: return
	var lx := BOX.position.x + 40
	var rx := BOX.end.x - 40
	var y0 := BOX.position.y + 26
	var gap := (BOX.size.y - 52) / 3
	Art.panel(self, BOX.grow(-5), Color("465668"), Color("96adb8"))
	for x in [lx - 30, rx]:
		Art.panel(self, Rect2(x - 3, y0 - 12, 36, gap * 3 + 24), Color("293748"), Color("7a919f"))
	for i in 4:
		var yl := y0 + i * gap
		var col: Color = WIRE_COLS[i]
		var j := wire_right[i]
		var yr := y0 + i * gap
		Art.cable(self, PackedVector2Array([Vector2(lx - 27, yl), Vector2(lx - 12, yl + 2), Vector2(lx, yl)]), col, 4, true)
		Art.cable(self, PackedVector2Array([Vector2(rx, yr), Vector2(rx + 12, yr - 2), Vector2(rx + 27, yr)]), WIRE_COLS[j], 4, true)
		if i in wire_done:
			Art.lead(self, Vector2(lx, yl), Vector2(rx, y0 + wire_right.find(i) * gap), col, 4)
	if wire_pick < 0:
		draw_rect(Rect2(lx - 34, y0 + wire_sel * gap - 8, 38, 16), Art.CREAM, false, 2)
	else:
		var yl2 := y0 + wire_pick * gap
		var yr := y0 + wire_sel * gap
		Art.lead(self, Vector2(lx, yl2), Vector2(rx, yr), WIRE_COLS[wire_pick], 3)
		draw_rect(Rect2(rx - 4, yr - 8, 38, 16), Art.GOLD, false, 2)
	draw_string(font, Vector2(BOX.position.x, BOX.end.y - 6), "Pannello %d di 2" % (wire_round + 1), HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 10, Art.CREAM)


## Freccia piena (triangolo) che punta in una direzione.
func _arrow(c: Vector2, dir: String, r: float, col: Color) -> void:
	var pts := PackedVector2Array([Vector2(0, -r), Vector2(r, r * 0.6), Vector2(-r, r * 0.6)])
	var ang := {"up": 0.0, "right": PI / 2, "down": PI, "left": -PI / 2}[dir] as float
	for i in pts.size():
		pts[i] = c + pts[i].rotated(ang)
	draw_colored_polygon(pts, col)


func _heart(c: Vector2, col: Color) -> void:
	const ROWS := ["011000110", "111101111", "111111111", "111111111", "011111110", "001111100", "000111000", "000010000"]
	var o := c - Vector2(4.5, 4)
	for y in ROWS.size():
		var row: String = ROWS[y]
		for x in row.length():
			if row[x] == "1":
				draw_rect(Rect2(o + Vector2(x, y), Vector2.ONE), col)
