extends Node2D

const Art := preload("res://scripts/minigame_art.gd")
## Minigiochi "a sorpresa": partono quando dai una mano a qualcuno. Config in GameState.minigame:
##   type "timing":   premi Z quando il segno è nella zona verde (riparare, accordare, salire le scale)
##                    con "zones": 2 le fasce sono due e si accendono a turno (ogni "swap" secondi):
##                    vale solo quella accesa, l'altra è un errore (Ercole: TIENI SVEGLIO ERCOLE)
##   type "collect":  muovi il cuore e raccogli tutto prima che scada il tempo (foglie, croccantini)
##   type "sequence": ricorda e ripeti la sequenza di frecce (pratiche, post-it, curriculum)
##   type "bulbs":    smista le lampadine: buona a DESTRA, rotta a SINISTRA, quella che sfarfalla
##                    si aggiusta con SU o GIÙ (Mina)
##   type "wires":    collega i fili dello stesso colore, come in Among Us (Nonno Bulbo)
##   type "inventory": ogni prodotto sul suo scaffale (Leda: SCATOLE E SCAFFALI)
##   type "route":    due giri (mattina e pomeriggio), tre pacchi ciascuno: scegli le strade (Amir: L'ULTIMA CONSEGNA)
##   type "rate":     sei documenti in ordine di data, poi la voce doppia nell'estratto conto
##                    (Olga: LE RATE MANCANTI; dati in data/bank.json)
##   type "pratiche": trova direttamente la riga sospetta nel fascicolo
##                    (Teo: LA PRATICA IMPOSSIBILE)
##   type "volantini": in piazza passa la gente; dai il volantino a chi ti guarda, non a chi ha fretta,
##                    è al telefono o è una guardia CHEAP (Ada: VOLANTINAGGIO). Dati in data/city.json
##   type "consegne": il furgone di Amir, come uno snake: prendi il pacco, portalo alla casa che si
##                    illumina prima che scada il tempo; muri, cantieri e le altre case fanno sbattere
##                    (Amir: L'ULTIMA CONSEGNA). Numeri, case e cantieri nella config del minigioco
##   type "coincidenze": la mappa delle linee; trascini il dito da una fermata all'altra lungo una linea
##                    e Nadir prende la prima corsa che fa in tempo a prendere, fino al lavoro in orario e
##                    nel budget, prima che scada il tempo (Nadir: L'ORARIO DELLE COINCIDENZE).
##                    Dati in data/city.json, "coincidenze" (anche dove stanno le fermate: "mappa")
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
## con "zones": 2, la seconda fascia (spenta finché non tocca a lei); x < 0 = non c'è
var zone_off := Vector2(-1, -1)
var swap_t := 0.0
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
## true quando la lampadina sfarfallava e l'hai appena avvitata
var bulb_fixed := false
# fili
const WIRE_COLS := [Color("d23b3b"), Color("39b6ff"), Color("ffe14d"), Color("3ddc84")]
var wire_right: Array[int] = []
var wire_done: Array[int] = []
var wire_sel := 0
var wire_pick := -1
var wire_round := 0
## dove sta il dito che trascina un filo (come in Among Us); x < 0: nessun filo trascinato
var wire_drag := Vector2(-1, -1)
var hurt_t := 0.0
# consegne (il furgone di Amir)
var sn_body: Array[Vector2i] = []
var sn_dir := Vector2i.RIGHT
var sn_next := Vector2i.RIGHT
var sn_t := 0.0
var sn_parcel := Vector2i(-1, -1)  # il pacco da prendere (-1: nessuno per terra)
var sn_carry := -1                 # la casa a cui portare il pacco a bordo (-1: niente a bordo)
var sn_left := 0.0                 # secondi rimasti per questa consegna
var sn_done := 0
var sn_late := 0
var sn_msg := ""
var sn_rng := RandomNumberGenerator.new()
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
	["Scopa", 3], ["Biscotti", 0], ["Shampoo", 1], ["Gomma", 2], ["Lampadina", 3], ["Pasta", 0], ["Spugna", 3], ["Righello", 2], ["Fragola", 0], ["Cipollotto", 0], ["Patata", 0], ["Cipolla", 0]]
var inv_queue: Array = []
var inv_sel := 0
var inv_done := 0
var inv_msg := ""
# consegne (Amir): incroci, strade [da, a, minuti, rischiosa], pacchi
## Due giri: la mattina e il pomeriggio. Ogni giro ha la sua mappa, i suoi tre pacchi e il suo tempo.
## In ogni mappa c'è una strada sicura che arriva in tempo; le scorciatoie rosse passano dal cantiere.
const RT_MAPS := [
	{"title": "MATTINA", "budget": 120, "parcels": [2, 4, 5],
		"nodes": [Vector2(64, 190), Vector2(151, 126), Vector2(151, 258), Vector2(238, 190), Vector2(352, 126), Vector2(352, 258)],
		"names": ["MAGAZZINO", "Incrocio A", "Scala B", "Incrocio B", "Via dei Fiori", "Piazza"],
		"edges": [[0, 1, 30, false], [0, 2, 30, false], [1, 3, 30, false], [2, 3, 30, false], [1, 4, 50, false],
			[2, 5, 50, false], [4, 5, 30, false], [0, 3, 10, true], [3, 4, 10, true], [3, 5, 10, true]]},
	# i nomi stanno sotto gli incroci in basso e sotto quello in alto a destra: non coprono i minuti
	{"title": "POMERIGGIO", "budget": 150, "parcels": [2, 5, 6],
		"nodes": [Vector2(64, 190), Vector2(137, 126), Vector2(137, 258), Vector2(210, 190), Vector2(283, 126), Vector2(283, 258), Vector2(356, 126)],
		"names": ["MAGAZZINO", "Incrocio A", "Scuola", "Incrocio B", "Incrocio C", "Via Roma", "Ospedale"],
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
# VOLANTINAGGIO (Ada): chi passa (CharSprite figli del minigioco), quanti volantini presi, fra quanto arriva il prossimo
var vl_walkers: Array[CharSprite] = []
var vl_given := 0
var vl_next := 0.0
var vl_t := 0.0
var vl_msg := ""
# L'ORARIO DELLE COINCIDENZE (Nadir): le corse prese, dove sei, che ore sono, quanto hai speso
var cz_path: Array = []
var cz_at := 0
var cz_now := 0
var cz_focus := 0
var cz_msg := ""
var cz_trail := PackedVector2Array()  # la strada che sta tracciando il dito (vuota: nessun trascinamento)

var _title: Label
var _info: Label
## la risposta ai colpi e le stelline (scenes/minigame/risposta.tscn, nodo Risposta)
var _risposta: Risposta
## i giochi che hanno già stelline e risposta ai colpi (gli altri arrivano capitolo per capitolo)
const CON_STELLE := ["wires", "bulbs"]
## i secondi all'inizio (per la barra del tempo e le stelline)
var time_total := 0.0
## true finché non hai fatto il primo gesto giusto: si vede come si gioca, senza leggere
var guida := true


func _ready() -> void:
	cfg = GameState.minigame
	type = str(cfg.get("type", "timing"))
	Ui.show_hud(false)
	# lo sfondo, il titolo e la riga sotto sono nodi di scenes/minigame/minigame.tscn: Titolo e Info,
	# oppure TitoloPercorso e InfoPercorso (più in alto e più piccoli) per il gioco del percorso
	var route := type == "route"
	_title = $TitoloPercorso if route else $Titolo
	_info = $InfoPercorso if route else $Info
	for l: Label in [$Titolo, $Info, $TitoloPercorso, $InfoPercorso]:
		l.visible = l == _title or l == _info
	_title.text = str(cfg.get("title", "Dai una mano"))
	_risposta = get_node_or_null("Risposta")
	_info.text = ""
	# ogni persona che aiuti ha la sua canzone (campo "music"); le altre, una per tutte
	Sound.music(str(cfg.get("music", "aiuto")))
	if Ui.transitioning:
		await Ui.faded_in
	await Ui.say(cfg.get("intro", ["* Dai una mano."]))
	_start()


func _start() -> void:
	phase = "play"
	match type:
		"timing":
			_info.text = GameState.fmt("Premi {ok} quando il segno è nel verde")
			_new_zone()
		"collect":
			_info.text = GameState.fmt("Raccogli tutto con le frecce ed evita le cose rosse")
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
			time_total = time_left
			_new_bulb()
		"wires":
			_info.text = "Trascina ogni filo sul suo colore" if TouchControls.enabled else "Trascina col mouse ogni filo sul suo colore"
			time_left = float(cfg.get("time", 30.0))
			time_total = time_left
			_new_wires()
		"inventory":
			time_left = float(cfg.get("time", 35.0))
			var goods := INV_GOODS.duplicate()
			goods.shuffle()
			inv_queue = goods.slice(0, int(cfg.get("count", 8)))
		"consegne":
			if cfg.has("seed"):
				sn_rng.seed = int(cfg["seed"])
			else:
				sn_rng.randomize()
			_sn_start()
			_sn_spawn_parcel()
			sn_msg = "Scorri il dito per partire e girare il furgone." if TouchControls.enabled else "Le FRECCE fanno partire e girare il furgone."
		"route":
			_rt_load(0)
			if cfg.has("seed"):
				rt_rng.seed = int(cfg["seed"])
			else:
				rt_rng.randomize()
			_info.text = "Tocca una destinazione a destra. Porta tutti e tre i pacchi." if TouchControls.enabled else "FRECCE scegli la destinazione • %s viaggia • Porta tutti e tre i pacchi" % GameState.fmt("{ok}")
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
			rate_msg = "Tocca i documenti dal più vecchio al più recente." if TouchControls.enabled else "Clicca i documenti dal più vecchio al più recente."
		"pratiche":
			pr_i = 0
			pr_msg = ""
		"volantini":
			vl_given = 0
			vl_t = 0.0
			vl_next = 0.3
			time_left = float(_vl_data().get("tempo", 45))
			vl_msg = "Tocca quando chi ti guarda è davanti ad Ada." if TouchControls.enabled else "%s quando chi ti guarda è davanti ad Ada." % GameState.fmt("{ok}")
			_vl_ada()
		"coincidenze":
			_cz_restart()
			time_left = float(_cz_data().get("tempo", 75))
			cz_msg = "Trascina il dito da una fermata all'altra, lungo una linea, fino al lavoro." if TouchControls.enabled else "Trascina col mouse da una fermata all'altra. Oppure FRECCE e %s." % GameState.fmt("{ok}")


func _new_bulb() -> void:
	bulb = ["buona", "rotta", "fioca"].pick_random()
	bulb_fix = 0
	bulb_fixed = false
	bulb_t = 0.0


## In alto: come si gioca finché non hai fatto il primo gesto, poi solo quante ne hai smistate.
## Il tempo e gli errori si vedono nel gioco (la barra sotto, le lampadine a destra).
func _bulb_info() -> void:
	if guida:
		return
	_info.text = "Smistate %d di %d" % [bulb_done, int(cfg.get("count", 10))]


func _bulb_answer(ok: bool) -> void:
	if ok:
		bulb_done += 1
		guida = false
		# la scatola giusta: le rotte a sinistra, le buone (e quelle avvitate) a destra
		var box := Vector2(BOX.position.x + 49, BOX.end.y - 34) if bulb == "rotta" else Vector2(BOX.end.x - 49, BOX.end.y - 34)
		if _risposta: _risposta.giusto(box, "blip")
	else:
		misses += 1
		flash = 0.3
		if _risposta: _risposta.sbagliato()
		else: Sound.sfx("deny")
	_bulb_info()
	if bulb_done >= int(cfg.get("count", 10)):
		_finish(true)
	elif misses >= _max_misses():
		_finish(false)
	else:
		_new_bulb()


## Quanti errori si possono fare (lampadine e fili; "misses" nel minigioco, di solito 4).
func _max_misses() -> int:
	return int(cfg.get("misses", 4))


## Quanti pannelli di fili ("rounds", di solito 2).
func _wire_rounds() -> int:
	return int(cfg.get("rounds", 2))


func _new_wires() -> void:
	wire_right.assign([0, 1, 2, 3])
	wire_right.shuffle()
	wire_done.clear()
	wire_sel = 0
	wire_pick = -1
	wire_drag = Vector2(-1, -1)


## Il filo di sinistra `wire_pick` va al posto di destra `wire_sel`: giusto o sbagliato?
func _wire_connect() -> void:
	if wire_right[wire_sel] == wire_pick:
		wire_done.append(wire_pick)
		guida = false
		_info.text = ""
		if _risposta: _risposta.giusto(Vector2(BOX.end.x - 40, BOX.position.y + 26 + wire_sel * (BOX.size.y - 52) / 3.0))
		else: Sound.sfx("coin")
		if wire_done.size() >= 4:
			wire_round += 1
			if wire_round >= _wire_rounds():
				_finish(true)
				return
			_new_wires()
			return
	else:
		misses += 1
		flash = 0.3
		if _risposta: _risposta.sbagliato()
		else: Sound.sfx("deny")
		if misses >= _max_misses():
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
		"volantini":
			return "tap"
		"consegne":
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
	if type == "coincidenze":
		_cz_touch(pos, step)
		return
	if type == "pratiche" and step == 0:
		for k in _pr_target_count():
			if _pr_target(k).grow(3).has_point(pos):
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
		var choices := _rt_neighbors(rt_at)
		for i in choices.size():
			if _rt_card(i).has_point(pos):
				_rt_go(int(choices[i]))
				return
		for n in choices:
			if pos.distance_to(rt_nodes[n]) < 26.0:
				_rt_go(n)
				return
		return
	if type == "collect":
		finger = pos if step != 2 else Vector2(-1, -1)
	elif type == "wires":
		# come in Among Us: tieni il dito su un filo a sinistra, trascinalo e lascialo sul posto a destra.
		# Va bene anche toccare il filo e poi toccare il posto.
		var y0 := BOX.position.y + 26
		var gap := (BOX.size.y - 52) / 3.0
		var row := clampi(int(round((pos.y - y0) / gap)), 0, 3)
		var right := pos.x >= BOX.get_center().x
		if step == 0:
			if not right:
				if row not in wire_done:
					wire_pick = row
					wire_sel = row
					wire_drag = pos
					Sound.sfx("select")
			elif wire_pick >= 0:
				wire_sel = row
				_wire_connect()
		elif step == 1 and wire_drag.x >= 0.0:
			wire_drag = pos
			if right:
				wire_sel = row
		elif step == 2 and wire_drag.x >= 0.0:
			wire_drag = Vector2(-1, -1)
			if right and wire_pick >= 0:
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
		Sound.sfx("arcade/collect_3", 1.0 + inv_done * 0.025, 4.0)
		if inv_queue.is_empty():
			# il contatore in alto si aggiorna solo mentre si gioca: l'ultimo prodotto lo scrive qui
			_info.text = "Tempo: %d   Sistemati: %d/%d   Errori: %d/%d" % [int(ceil(time_left)), inv_done, inv_done, misses, int(cfg.get("misses", 3))]
			_finish(true)
	else:
		misses += 1
		flash = 0.3
		Sound.sfx("arcade/blocked", 1.0, 4.0)
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
	if int(cfg.get("zones", 1)) >= 2:
		# due fasce lontane fra loro, una nella metà sinistra e una nella destra
		var a := randf_range(0.04, 0.48 - w)
		var b := randf_range(0.52, 0.96 - w)
		zone = Vector2(a, a + w)
		zone_off = Vector2(b, b + w)
		if randf() < 0.5:
			_swap_zones()
		swap_t = _swap_time()
		return
	var a := randf_range(0.05, 0.95 - w)
	zone = Vector2(a, a + w)


func _swap_time() -> float:
	return maxf(0.6, float(cfg.get("swap", 1.4)) - hits * 0.15)


func _swap_zones() -> void:
	var z := zone
	zone = zone_off
	zone_off = z


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
				if zone_off.x >= 0.0:
					swap_t -= delta
					if swap_t <= 0.0:
						_swap_zones()
						swap_t = _swap_time()
						Sound.sfx("blip", 1.4)
				marker += marker_dir * marker_speed * delta
				if marker > 1.0 or marker < 0.0:
					marker = clampf(marker, 0.0, 1.0)
					marker_dir = -marker_dir
			elif type == "bulbs" or type == "wires":
				bulb_t += delta
				time_left -= delta
				if type == "bulbs":
					_bulb_info()
					# "per_bulb": ogni lampadina ha i suoi secondi; se ci pensi troppo, è un errore
					if cfg.has("per_bulb") and bulb_t > float(cfg["per_bulb"]) and time_left > 0.0:
						_bulb_answer(false)
				if time_left <= 0.0:
					_finish(false)
			elif type == "rate":
				if rate_phase == "order":
					_info.text = "Documenti in ordine: %d/%d   Errori: %d" % [rate_placed.size(), rate_cards.size(), misses]
				else:
					_info.text = "Trova la commissione ripetuta   Errori: %d" % misses
			elif type == "pratiche":
				_info.text = "Trova la riga sospetta · Pratica %d/%d · Errori %d/%d" % [mini(pr_i + 1, _pr_list().size()), _pr_list().size(), misses, int(cfg.get("misses", 2))]
			elif type == "volantini":
				_vl_step(delta)
			elif type == "consegne":
				_sn_process(delta)
			elif type == "coincidenze":
				time_left -= delta
				_info.text = "Tempo: %d   Ore %s   Spesa: %d €   Errori: %d/3" % [int(ceil(time_left)), _clock(cz_now), _cz_cost(), misses]
				if time_left <= 0.0:
					_finish(false)
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
	# la mappa di Nadir e i fili di Bulbo col mouse: si preme, si trascina, si lascia sul posto giusto
	if type in ["coincidenze", "wires"] and not TouchControls.enabled:
		if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			touch_point((event as InputEventMouseButton).position, 0 if (event as InputEventMouseButton).pressed else 2)
			return
		if event is InputEventMouseMotion and ((event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT):
			touch_point((event as InputEventMouseMotion).position, 1)
			return
	if type in ["inventory", "route", "rate", "pratiche"] and event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and not TouchControls.enabled:
		touch_point((event as InputEventMouseButton).position, 0)
		return
	if type == "inventory":
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
			inv_sel = posmod(inv_sel + (-1 if event.is_action_pressed("move_left") else 1), INV_CATS.size())
			Sound.sfx("arcade/select_2", 1.0, 4.0)
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
	if type == "volantini":
		if event.is_action_pressed("confirm"):
			_vl_give()
		return
	if type == "consegne":
		for pair in [["move_up", Vector2i.UP], ["move_down", Vector2i.DOWN], ["move_left", Vector2i.LEFT], ["move_right", Vector2i.RIGHT]]:
			if event.is_action_pressed(pair[0]):
				_sn_turn(pair[1])
		return
	if type == "coincidenze":
		var targets := _cz_targets()
		var d := 0
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_up"):
			d = -1
		elif event.is_action_pressed("move_right") or event.is_action_pressed("move_down"):
			d = 1
		if d != 0:
			cz_focus = posmod(cz_focus + d, targets.size())
			Sound.sfx("move")
		elif event.is_action_pressed("confirm") and not targets.is_empty():
			var t: Variant = targets[clampi(cz_focus, 0, targets.size() - 1)]
			if t is Dictionary:
				_cz_take(t)
			else:
				_cz_act("reset")
		return
	if type == "pratiche":
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_up") \
				or event.is_action_pressed("move_right") or event.is_action_pressed("move_down"):
			var step := -1 if event.is_action_pressed("move_left") or event.is_action_pressed("move_up") else 1
			pr_sel = posmod(pr_sel + step, _pr_target_count())
			Sound.sfx("arcade/select_2", 1.0, 4.0)
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
				if bulb_fix >= int(cfg.get("fix", 2)):
					bulb = "buona"
					bulb_fixed = true
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
	# le stelline: dalla bravura (errori e tempo avanzato)
	var quante := 0
	if success and _risposta and type in CON_STELLE:
		quante = _risposta.stelle(misses, time_left / time_total if time_total > 0.0 else -1.0)
		await _risposta.vittoria(quante, id)
	var lines: Array = []
	if success:
		Sound.sfx("spare")
		var reward := int(cfg.get("reward", 10))
		GameState.money += reward
		GameState.changed.emit()
		lines.append_array(cfg.get("win", ["Grazie!"]))
		if quante == 3:
			lines.append_array(cfg.get("win_best", []))   # con tre stelline, una battuta in più
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
	var frame := INV if type == "inventory" else (Rect2(24, 64, 592, 280) if type == "route" else (BIG if type in ["rate", "pratiche", "volantini", "coincidenze", "consegne"] else BOX))
	if type == "route":
		Art.backdrop(self)
		Art.panel(self, frame, Color("202b35"), Color("829caa"))
	else:
		Art.backdrop(self)
		Art.panel(self, frame, Color("24313e"), Color("829caa"))
	match type:
		"rate":
			_draw_rate(font)
		"pratiche":
			_draw_pratiche(font)
		"volantini":
			_draw_volantini(font)
		"coincidenze":
			_draw_coincidenze(font)
		"consegne":
			_draw_consegne(font)
		"timing":
			var bar := Rect2(BOX.position.x + 20, BOX.get_center().y - 10, BOX.size.x - 40, 20)
			Art.panel(self, bar.grow(3), Color("46566b"), Color("94a7b9"))
			if zone_off.x >= 0.0:
				# la fascia spenta: si vede dove sarà, ma adesso non vale
				draw_rect(Rect2(bar.position.x + bar.size.x * zone_off.x, bar.position.y, bar.size.x * (zone_off.y - zone_off.x), bar.size.y), GREEN.darkened(0.65))
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
			_draw_stato()
		"wires":
			_draw_wires(font)
			_draw_stato()
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
		draw_rect(frame, Color(1, 0.2, 0.2, flash))


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
		draw_string(font, Vector2(BOX.position.x, BOX.position.y + 18), ("Sfarfalla! Scorri su o giù (%d/%d)" if TouchControls.enabled else "Sfarfalla! SU o GIÙ per avvitarla (%d/%d)") % [bulb_fix, int(cfg.get("fix", 2))], HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 11, YELLOW)
	elif bulb_fixed and phase == "play":
		draw_string(font, Vector2(BOX.position.x, BOX.position.y + 18), "Avvitata! Ora mettila nelle BUONE >", HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 11, GREEN)


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
			rate_msg = "Stesso ritardo, stessa commissione: tocca una delle due righe." if TouchControls.enabled else "Stesso ritardo, stessa commissione: clicca una delle due righe."
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
	# JSON carica gli indici come float; Array.has distingue 3 da 3.0.
	var duplicated := false
	for index in _rate_statement().get("doppie", []):
		if int(index) == i:
			duplicated = true
			break
	if duplicated:
		Sound.sfx("stamp")
		_finish(true)
	else:
		_rate_miss("Questa voce è unica. Cerca le due commissioni uguali.")


func _rate_miss(msg: String) -> void:
	misses += 1
	flash = 0.3
	rate_msg = msg
	Sound.sfx("deny")
	# Il puzzle si può riprovare: un errore dà un indizio, non chiude l'aiuto a Olga.


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
		draw_multiline_string(font, Vector2(BIG.position.x + 12, BIG.end.y - 22), rate_msg, HORIZONTAL_ALIGNMENT_CENTER, BIG.size.x - 24, 9, 2, Color("ffb0b0") if flash > 0.0 else Color("c8c0d0"))


# --- LA PRATICA IMPOSSIBILE (Teo) ------------------------------------------------------

# --- VOLANTINAGGIO (Ada) ---------------------------------------------------------------
# La gente passa da destra a sinistra sul marciapiede; Ada sta in mezzo. Chi ti guarda (?) prende il
# volantino; chi ha fretta (!), chi è al telefono e la guardia CHEAP no: darlo a loro è un errore.
# Tutti i numeri (quanti, quanto tempo, quanto vanno veloci, chi passa) sono in data/city.json, "volantini".

func _vl_data() -> Dictionary:
	return GameState.city.get("volantini", {})


## La riga dove camminano i piedi, e il pezzo di marciapiede davanti ad Ada.
func _vl_feet_y() -> float:
	return BIG.position.y + 176


func _vl_zone() -> Rect2:
	var w := float(_vl_data().get("zona", 44))
	return Rect2(BIG.get_center().x - w / 2.0, _vl_feet_y() - 70, w, 82)


func _vl_ada() -> void:
	var ada := CharSprite.new()
	ada.name = "Ada"
	ada.sheet = str(GameState.npc_data("ada").get("sheet", "cheap_ada"))
	ada.anim = "idle_down"
	ada.scale = Vector2(2, 2)
	ada.position = Vector2(BIG.get_center().x, _vl_feet_y() - 56)
	add_child(ada)


func _vl_kind_line(kind: String) -> Dictionary:
	for k: Dictionary in _vl_data().get("tipi", []):
		if str(k.get("id", "")) == kind:
			return k
	return {}


## Fa passare qualcuno. Senza `kind` lo sceglie a caso coi pesi dei dati.
func _vl_spawn(kind := "", x := -1.0) -> CharSprite:
	var kinds: Array = _vl_data().get("tipi", [])
	if kind == "":
		var tot := 0.0
		for k: Dictionary in kinds:
			tot += float(k.get("peso", 1))
		var r := randf() * tot
		for k: Dictionary in kinds:
			r -= float(k.get("peso", 1))
			if r <= 0.0:
				kind = str(k["id"])
				break
	var info := _vl_kind_line(kind)
	var w := CharSprite.new()
	var sheets: Array = info.get("fogli", _vl_data().get("comparse", ["char_02"]))
	w.sheet = str(sheets.pick_random())
	w.anim = str(info.get("anim", "walk_left"))
	w.scale = Vector2(2, 2)
	w.position = Vector2(BIG.end.x - 24 if x < 0.0 else x, _vl_feet_y())
	w.set_meta("kind", kind)
	var sp: Array = info.get("velocita", _vl_data().get("velocita", [40, 60]))
	w.set_meta("speed", randf_range(float(sp[0]), float(sp[1])) * (1.0 + vl_t * float(_vl_data().get("accelera", 0.01))))
	var mark := Label.new()
	mark.text = str(info.get("segno", ""))
	mark.add_theme_font_override("font", Assets.font())
	mark.add_theme_font_size_override("font_size", 8)
	mark.add_theme_color_override("font_color", Color(str(info.get("colore", "ffe14d"))))
	mark.add_theme_color_override("font_outline_color", Color("1a1420"))
	mark.add_theme_constant_override("outline_size", 3)
	mark.position = Vector2(-12, -46)
	mark.size = Vector2(24, 10)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w.add_child(mark)
	add_child(w)
	vl_walkers.append(w)
	return w


func _vl_clear() -> void:
	for w in vl_walkers:
		w.queue_free()
	vl_walkers.clear()


func _vl_step(delta: float) -> void:
	vl_t += delta
	time_left -= delta
	vl_next -= delta
	if vl_next <= 0.0:
		var gap: Array = _vl_data().get("ogni", [0.9, 1.6])
		vl_next = randf_range(float(gap[0]), float(gap[1]))
		_vl_spawn()
	for w in vl_walkers.duplicate():
		w.position.x -= float(w.get_meta("speed")) * delta
		if w.position.x < BIG.position.x + 20:
			vl_walkers.erase(w)
			w.queue_free()
	_info.text = "Tempo: %d   Volantini presi: %d/%d   Errori: %d/3" % [int(ceil(time_left)), vl_given, int(_vl_data().get("obiettivo", 8)), misses]
	if time_left <= 0.0:
		_finish(false)


## Il volantino va a chi è davanti ad Ada (il più vicino). Se non c'è nessuno, non succede niente.
func _vl_give() -> void:
	if phase != "play":
		return
	var zone := _vl_zone()
	var best: CharSprite = null
	for w in vl_walkers:
		if not w.has_meta("done") and zone.has_point(w.position - Vector2(0, 8)) and (best == null or absf(w.position.x - zone.get_center().x) < absf(best.position.x - zone.get_center().x)):
			best = w
	if best == null:
		vl_msg = "Davanti ad Ada non c'è nessuno."
		Sound.sfx("move")
		return
	best.set_meta("done", true)
	var info := _vl_kind_line(str(best.get_meta("kind")))
	vl_msg = str(info.get("frase", ""))
	var mark := best.get_child(0) as Label
	if bool(info.get("giusto", false)):
		vl_given += 1
		mark.text = "OK"
		mark.add_theme_color_override("font_color", Color("8fe08f"))
		Sound.sfx("blip", 1.3)
		if vl_given >= int(_vl_data().get("obiettivo", 8)):
			GameState.flags["c5_volantini"] = vl_given
			cfg["_extra"] = ["* %d volantini in mano a gente che li ha letti. Uno è già attaccato in bacheca." % vl_given]
			Sound.sfx("stamp")
			_finish(true)
		return
	mark.text = "X"
	mark.add_theme_color_override("font_color", Color("ff7a6a"))
	misses += 1
	flash = 0.3
	Sound.sfx("deny")
	if misses >= 3:
		_finish(false)


func _draw_volantini(font: Font) -> void:
	var r := BIG.grow(-4)
	var feet := _vl_feet_y()
	# la facciata della Casa Comune, il marciapiede, la strada
	draw_rect(Rect2(r.position, Vector2(r.size.x, feet - 70 - r.position.y)), Color("6a5a4e"))
	for k in 6:
		var win := Rect2(r.position.x + 30 + k * 90, r.position.y + 14, 40, 26)
		draw_rect(win, Color("9fc4d6"))
		draw_rect(win, Color("3a2e2a"), false, 2.0)
	draw_rect(Rect2(r.position.x, feet - 70, r.size.x, 82), Color("b9b0a4"))
	for k in int(r.size.x / 32.0) + 1:
		draw_line(Vector2(r.position.x + k * 32, feet - 70), Vector2(r.position.x + k * 32, feet + 12), Color("a39a8e"), 1.0)
	draw_rect(Rect2(r.position.x, feet + 12, r.size.x, r.end.y - feet - 12), Color("4a4a52"))
	var zone := _vl_zone()
	draw_rect(zone, Color(1, 0.88, 0.3, 0.22))
	draw_rect(zone, YELLOW, false, 1.0)
	draw_string(font, Vector2(r.position.x + 10, r.end.y - 8), vl_msg, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 20, 9,
		Color("ffb0b0") if flash > 0.0 else Color("f0eadc"))


# --- LE CONSEGNE DI AMIR: il furgone (uno snake) ------------------------------------------------
# Tutti i numeri (pacchi, secondi, velocità, case, cantieri) stanno nella config del minigioco
# (data/npcs.json, amir > help > minigame): si cambiano lì.

const SN_CELL := 16
const SN_GRID := Vector2i(34, 12)
## Dove comincia la griglia (in alto c'è la riga con il pacco a bordo).
const SN_ORIGIN := Vector2(48, 130)


func _sn_houses() -> Array:
	return cfg.get("case", [])


func _sn_house_cell(i: int) -> Vector2i:
	var c: Array = _sn_houses()[i]["cella"]
	return Vector2i(int(c[0]), int(c[1]))


func _sn_house_at(c: Vector2i) -> int:
	for i in _sn_houses().size():
		if _sn_house_cell(i) == c:
			return i
	return -1


func _sn_blocked(c: Vector2i) -> bool:
	for r: Array in cfg.get("cantieri", []):
		if Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])).has_point(c):
			return true
	return false


func _sn_cell_rect(c: Vector2i) -> Rect2:
	return Rect2(SN_ORIGIN + Vector2(c * SN_CELL), Vector2(SN_CELL, SN_CELL))


func _sn_start() -> void:
	var s: Array = cfg.get("partenza", [5, 6])
	var head := Vector2i(int(s[0]), int(s[1]))
	sn_body = []
	for i in maxi(2, int(cfg.get("lunghezza", 3)) + sn_done):
		sn_body.append(head - Vector2i(i, 0))
	# fermo finché non giri la prima volta (anche dopo un incidente): così non sbatte da solo
	sn_dir = Vector2i.ZERO
	sn_next = Vector2i.ZERO
	sn_t = 0.0


func _sn_spawn_parcel() -> void:
	var head: Vector2i = sn_body[0]
	var free: Array[Vector2i] = []
	for y in SN_GRID.y:
		for x in SN_GRID.x:
			var c := Vector2i(x, y)
			if c in sn_body or _sn_blocked(c) or _sn_house_at(c) >= 0:
				continue
			if absi(c.x - head.x) + absi(c.y - head.y) < 5:
				continue
			free.append(c)
	sn_parcel = free[sn_rng.randi_range(0, free.size() - 1)] if not free.is_empty() else Vector2i(-1, -1)


## Una mossa del furgone: una casella avanti.
func _sn_step() -> void:
	if sn_next != -sn_dir:
		sn_dir = sn_next
	if sn_dir == Vector2i.ZERO:
		return
	var head: Vector2i = sn_body[0] + sn_dir
	var house := _sn_house_at(head)
	var crash := ""
	if head.x < 0 or head.y < 0 or head.x >= SN_GRID.x or head.y >= SN_GRID.y:
		crash = "Il marciapiede! Amir frena di colpo."
	elif _sn_blocked(head):
		crash = "Il cantiere! Di qui non si passa."
	elif head in sn_body.slice(0, sn_body.size() - 1):
		crash = "Il furgone si è chiuso da solo in un vicolo."
	elif house >= 0 and house != sn_carry:
		crash = "Non è questa casa: il furgone ci sbatte contro."
	if crash != "":
		_sn_crash(crash)
		return
	sn_body.insert(0, head)
	if head == sn_parcel:
		# il pacco sale sul furgone: adesso c'è una casa da raggiungere, col tempo che corre
		sn_parcel = Vector2i(-1, -1)
		var choices: Array = range(_sn_houses().size()).filter(func(i: int) -> bool:
			var hc := _sn_house_cell(i)
			return absi(hc.x - head.x) + absi(hc.y - head.y) >= 8)
		if choices.is_empty():
			choices = range(_sn_houses().size())
		sn_carry = int(choices[sn_rng.randi_range(0, choices.size() - 1)])
		sn_left = float(cfg.get("secondi", 12))
		sn_msg = "Pacco a bordo! Portalo alla casa %s." % str(_sn_houses()[sn_carry]["nome"])
		Sound.sfx("blip", 1.3)
		sn_body.pop_back()
	elif house >= 0 and house == sn_carry:
		var late := sn_left <= 0.0
		sn_done += 1
		if late:
			sn_late += 1
		sn_carry = -1
		sn_msg = "Consegnato, ma in ritardo." if late else "Consegnato! Il furgone si allunga."
		Sound.sfx("coin" if not late else "deny", 1.2)
		# il furgone si allunga (la coda resta dov'è) e va un po' più veloce
		if sn_done >= int(cfg.get("consegne", 6)):
			_sn_end()
			return
		_sn_spawn_parcel()
	else:
		sn_body.pop_back()


func _sn_crash(msg: String) -> void:
	misses += 1
	flash = 0.4
	Sound.sfx("deny")
	sn_msg = msg + (" Si riparte: gira per ripartire." if misses < int(cfg.get("errori", 3)) else "")
	if misses >= int(cfg.get("errori", 3)):
		_sn_end()
		return
	_sn_start()
	if sn_parcel == Vector2i(-1, -1) and sn_carry < 0:
		_sn_spawn_parcel()


## Tutti puntuali: vinto (anche il bonus). Consegnati tutti ma qualcuno in ritardo, o fermi a metà
## con almeno la metà dei pacchi: a metà. Altrimenti è andata male.
func _sn_end() -> void:
	var total := int(cfg.get("consegne", 6))
	if sn_done >= total and sn_late == 0:
		_finish(true)
	elif sn_done >= total or sn_done * 2 >= total:
		_finish(false, true)
	else:
		_finish(false)


func _sn_process(delta: float) -> void:
	if sn_carry >= 0 and sn_left > 0.0:
		sn_left -= delta
		if sn_left <= 0.0:
			sn_msg = "Tempo scaduto! Il pacco arriverà in ritardo."
			Sound.sfx("deny", 0.8)
	sn_t += delta
	var step := maxf(0.07, float(cfg.get("passo", 0.17)) - float(cfg.get("accelera", 0.012)) * sn_done)
	while sn_t >= step and phase == "play":
		sn_t -= step
		_sn_step()
	var total := int(cfg.get("consegne", 6))
	_info.text = "Pacchi: %d/%d   %s   Errori: %d/%d" % [sn_done, total,
		("Tempo: %d" % int(ceil(sn_left)) if sn_left > 0.0 else "IN RITARDO") if sn_carry >= 0 else "Prendi il pacco",
		misses, int(cfg.get("errori", 3))]


func _sn_turn(d: Vector2i) -> void:
	# non si torna indietro dentro il furgone
	if d == -sn_dir or (sn_body.size() > 1 and sn_body[0] + d == sn_body[1]):
		return
	sn_next = d


func _draw_consegne(font: Font) -> void:
	var area := Rect2(SN_ORIGIN, Vector2(SN_GRID * SN_CELL))
	draw_rect(area, Color("3a4048"))
	# le strisce della strada, per capire la griglia
	for x in range(0, SN_GRID.x, 2):
		for y in range(0, SN_GRID.y, 2):
			draw_rect(Rect2(SN_ORIGIN + Vector2(x * SN_CELL + 7, y * SN_CELL + 7), Vector2(2, 2)), Color("4d545e"))
	for r: Array in cfg.get("cantieri", []):
		for x in range(int(r[0]), int(r[0]) + int(r[2])):
			for y in range(int(r[1]), int(r[1]) + int(r[3])):
				var cr := _sn_cell_rect(Vector2i(x, y))
				draw_rect(cr, Color("e08a2a"))
				draw_line(cr.position + Vector2(2, cr.size.y - 2), cr.position + Vector2(cr.size.x - 2, 2), Color("2a2a2a"), 3.0)
	for i in _sn_houses().size():
		var h: Dictionary = _sn_houses()[i]
		var r := _sn_cell_rect(_sn_house_cell(i))
		var col := Color(str(h.get("colore", "#c0c0c0")))
		var target := i == sn_carry
		if target:
			draw_rect(r.grow(3 + sin(t_spin * 2.0) * 1.5), YELLOW, false, 2.0)
		draw_rect(Rect2(r.position + Vector2(1, 6), Vector2(r.size.x - 2, r.size.y - 6)), col if target or sn_carry < 0 else col.darkened(0.5))
		draw_colored_polygon(PackedVector2Array([r.position + Vector2(0, 7), r.position + Vector2(r.size.x / 2.0, 0), r.position + Vector2(r.size.x, 7)]), Color("6a3a2a"))
		draw_rect(Rect2(r.position + Vector2(6, 10), Vector2(4, 6)), Color("2a2a2a"))
	if sn_parcel != Vector2i(-1, -1):
		var pr := _sn_cell_rect(sn_parcel).grow(-3)
		draw_rect(pr, Color("b0844c"))
		draw_line(pr.position + Vector2(pr.size.x / 2.0, 0), pr.position + Vector2(pr.size.x / 2.0, pr.size.y), Color("6a4a2a"), 2.0)
	for k in range(sn_body.size() - 1, -1, -1):
		var br := _sn_cell_rect(sn_body[k]).grow(-1)
		if k == 0:
			draw_rect(br, Color("f2f2f2"))
			# il finestrino guarda dove va il furgone
			var c := br.get_center() + Vector2(sn_dir) * 4.0
			draw_rect(Rect2(c - Vector2(3, 3), Vector2(6, 6)), Color("4aa8f0"))
		else:
			draw_rect(br, Color("d8d8d8") if k % 2 == 0 else Color("c8c8c8"))
			draw_rect(br.grow(-4), Color("b0844c"))
	var top := Vector2(SN_ORIGIN.x, SN_ORIGIN.y - 8)
	var line := "A bordo: pacco per la casa %s" % str(_sn_houses()[sn_carry]["nome"]) if sn_carry >= 0 else "Vai a prendere il pacco (la scatola marrone)."
	draw_string(font, top, line, HORIZONTAL_ALIGNMENT_LEFT, area.size.x, 9, YELLOW)
	if sn_msg != "":
		draw_string(font, Vector2(SN_ORIGIN.x, area.end.y + 14), sn_msg, HORIZONTAL_ALIGNMENT_LEFT, area.size.x, 9,
			Color("ffb0b0") if flash > 0.0 else Color("c8c0d0"))


# --- IL PERCORSO POSSIBILE (Nadir) -------------------------------------------------------

func _cz_data() -> Dictionary:
	return GameState.city.get("coincidenze", {})


func _cz_rides() -> Array:
	return _cz_data().get("corse", [])


func _cz_restart() -> void:
	cz_path = []
	cz_at = 0
	cz_now = int(_cz_data().get("partenza", 400))


## Le linee della mappa: le corse con lo stesso nome, la stessa partenza e lo stesso arrivo
## sono una linea sola (una curva), con i suoi orari. Tra due fermate con più linee le curve
## si allargano, così si vedono tutte e col dito si sceglie quale seguire.
func _cz_lines() -> Array:
	var out: Array = []
	var by_key := {}
	var rides := _cz_rides()
	for k in rides.size():
		var c: Dictionary = rides[k]
		var key := "%s|%d|%d" % [str(c["linea"]), int(c["da"]), int(c["a"])]
		if not by_key.has(key):
			by_key[key] = {"linea": str(c["linea"]), "da": int(c["da"]), "a": int(c["a"]), "corse": []}
			out.append(by_key[key])
		(by_key[key]["corse"] as Array).append(k)
	var per_pair := {}
	for l: Dictionary in out:
		var pair := _cz_pair(l)
		l["i"] = int(per_pair.get(pair, 0))
		per_pair[pair] = int(l["i"]) + 1
	for l: Dictionary in out:
		l["n"] = int(per_pair[_cz_pair(l)])
	return out


func _cz_pair(l: Dictionary) -> String:
	return "%d|%d" % [mini(int(l["da"]), int(l["a"])), maxi(int(l["da"]), int(l["a"]))]


const CZ_COLORS: Array[Color] = [Color("f0a040"), Color("4aa8f0"), Color("6ad07a"), Color("9a9aa8"), Color("c07af0"), Color("f06a6a"), Color("f0e06a")]
const CZ_STOP := 11.0      # raggio di una fermata
const CZ_GRAB := 24.0      # quanto vicino deve arrivare il dito per "prendere" una fermata
const CZ_BEND := 44.0      # quanto si allontanano le curve di due linee sulle stesse fermate


func _cz_stop_pos(i: int) -> Vector2:
	var p: Array = (_cz_data().get("mappa", {}) as Dictionary).get(_cz_stop_name(i), [0, 0])
	return BIG.position + Vector2(float(p[0]), float(p[1]))


## I punti della curva di una linea, dalla fermata di partenza a quella di arrivo.
func _cz_curve(l: Dictionary) -> PackedVector2Array:
	var p0 := _cz_stop_pos(int(l["da"]))
	var p2 := _cz_stop_pos(int(l["a"]))
	# la piegatura non dipende dal verso della linea
	var lo := _cz_stop_pos(mini(int(l["da"]), int(l["a"])))
	var hi := _cz_stop_pos(maxi(int(l["da"]), int(l["a"])))
	var perp := (hi - lo).orthogonal().normalized()
	var off := (float(l["i"]) - (float(l["n"]) - 1.0) / 2.0) * CZ_BEND
	var ctrl := (p0 + p2) / 2.0 + perp * off * 2.0
	var pts := PackedVector2Array()
	for t in 21:
		var u := t / 20.0
		pts.append(p0.lerp(ctrl, u).lerp(ctrl.lerp(p2, u), u))
	return pts


func _cz_reset_button() -> Rect2:
	return Rect2(BIG.end.x - 120, BIG.end.y - 30, 110, 24)


## Per la tastiera: le linee che partono da dove è Nadir, poi RICOMINCIA.
func _cz_targets() -> Array:
	var out: Array = []
	for l: Dictionary in _cz_lines():
		if int(l["da"]) == cz_at:
			out.append(l)
	out.append("reset")
	return out


## Il dito: si preme sulla fermata dov'è Nadir, si trascina, si lascia su un'altra fermata.
func _cz_touch(pos: Vector2, step: int) -> void:
	if phase != "play":
		return
	var stops := (_cz_data()["fermate"] as Array).size()
	if step == 0:
		cz_trail = PackedVector2Array()
		if _cz_reset_button().has_point(pos):
			_cz_act("reset")
			return
		if pos.distance_to(_cz_stop_pos(cz_at)) <= CZ_GRAB:
			cz_trail.append(_cz_stop_pos(cz_at))
			cz_trail.append(pos)
			Sound.sfx("arcade/select_2", 1.0, 4.0)
			return
		for i in stops:
			if pos.distance_to(_cz_stop_pos(i)) <= CZ_GRAB:
				cz_msg = "Nadir è a %s: parti da lì." % _cz_stop_name(cz_at)
				Sound.sfx("deny")
		return
	if cz_trail.is_empty():
		return
	if step == 1:
		if pos.distance_to(cz_trail[cz_trail.size() - 1]) > 3.0:
			cz_trail.append(pos)
		return
	# step 2: il dito si alza
	var trail := cz_trail
	trail.append(pos)
	cz_trail = PackedVector2Array()
	var dest := -1
	for i in stops:
		if i != cz_at and pos.distance_to(_cz_stop_pos(i)) <= CZ_GRAB:
			dest = i
	if dest < 0:
		cz_msg = "Porta la linea fino a un'altra fermata."
		return
	# tra le linee che vanno lì, quella che il dito ha seguito di più
	var best: Dictionary = {}
	var best_d := INF
	for l: Dictionary in _cz_lines():
		if int(l["da"]) != cz_at or int(l["a"]) != dest:
			continue
		var curve := _cz_curve(l)
		var tot := 0.0
		for q in trail:
			var m := INF
			for c in curve:
				m = minf(m, q.distance_squared_to(c))
			tot += m
		if tot < best_d:
			best_d = tot
			best = l
	if best.is_empty():
		cz_msg = "Da %s a %s non passa nessuna linea." % [_cz_stop_name(cz_at), _cz_stop_name(dest)]
		Sound.sfx("deny")
		return
	_cz_take(best)


## Nadir prende la prima corsa di quella linea che fa in tempo a prendere.
func _cz_take(l: Dictionary) -> void:
	var ready := cz_now + (0 if cz_path.is_empty() else int(_cz_data().get("cambio", 3)))
	var pick := -1
	for k: int in l["corse"]:
		var c: Dictionary = _cz_rides()[k]
		if str(c.get("stato", "")) == "soppressa":
			continue
		pick = k
		if str(c.get("stato", "")) == "badge" or _cz_min(str(c["parte"])) >= ready:
			break
	if pick < 0:
		cz_msg = "SOPPRESSA. Oggi questa linea non passa."
		Sound.sfx("deny")
		return
	# se nessuna corsa fa in tempo resta l'ultima: è già partita, e _cz_act lo dice
	_cz_act("c%d" % pick)


func _cz_cost() -> int:
	var c := 0
	for k in cz_path:
		c += int(_cz_rides()[k].get("euro", 0))
	return c


## "7:04" -> 424 (minuti dalla mezzanotte).
static func _cz_min(t: String) -> int:
	var hm := t.split(":")
	return int(hm[0]) * 60 + int(hm[1])


static func _clock(minutes: int) -> String:
	return "%d:%02d" % [minutes / 60, minutes % 60]


func _cz_stop_name(i: int) -> String:
	return str(_cz_data()["fermate"][i])


func _cz_act(what: String) -> void:
	if phase != "play":
		return
	if what == "reset":
		_cz_restart()
		cz_msg = "Si riparte da casa di Nadir."
		Sound.sfx("select")
		return
	var d := _cz_data()
	var c: Dictionary = _cz_rides()[int(what.substr(1))]
	var leave := _cz_min(str(c["parte"]))
	# da casa si esce quando passa; a una fermata servono i minuti per scendere e cambiare
	var ready := cz_now + (0 if cz_path.is_empty() else int(d.get("cambio", 3)))
	if str(c.get("stato", "")) == "soppressa":
		cz_msg = "SOPPRESSA. Sul tabellone la scritta va avanti e indietro, poi sparisce."
		Sound.sfx("deny")
		return
	if int(c["da"]) != cz_at:
		cz_msg = "Questa corsa parte da %s. Nadir è a %s." % [_cz_stop_name(int(c["da"])), _cz_stop_name(cz_at)]
		Sound.sfx("deny")
		return
	if str(c.get("stato", "")) == "badge":
		cz_msg = "Solo per dipendenti CHEAP con badge. Nadir non ce l'ha."
		Sound.sfx("deny")
		return
	if leave < ready:
		_cz_miss("Parte alle %s. Nadir ci arriva alle %s: la vede andare via." % [str(c["parte"]), _clock(ready)])
		return
	cz_path.append(int(what.substr(1)))
	cz_at = int(c["a"])
	cz_now = _cz_min(str(c["arriva"]))
	Sound.sfx("blip", 1.2)
	cz_msg = "Nadir sale sul %s. Scende alle %s, a %s." % [str(c["linea"]), str(c["arriva"]), _cz_stop_name(cz_at)]
	if _cz_cost() > int(d.get("budget", 6)):
		_cz_miss("%d € al giorno. Nadir ne ha %d." % [_cz_cost(), int(d.get("budget", 6))])
		return
	if cz_at == (d["fermate"] as Array).size() - 1:
		if cz_now > _cz_min(str(d.get("entrata", "8:00"))):
			_cz_miss("Arriva alle %s. Si entra alle %s." % [_clock(cz_now), str(d.get("entrata", "8:00"))])
			return
		GameState.flags["c5_nadir_corse"] = cz_path.duplicate()
		cfg["_extra"] = ["* Partenza %s, arrivo %s, %d € al giorno." % [_clock(int(d.get("partenza", 400))), _clock(cz_now), _cz_cost()]]
		Sound.sfx("stamp")
		_finish(true)


func _cz_miss(msg: String) -> void:
	misses += 1
	flash = 0.3
	Sound.sfx("deny")
	cz_msg = msg
	_cz_restart()
	if misses >= 3:
		_finish(false)


func _draw_coincidenze(font: Font) -> void:
	draw_rect(BIG.grow(-4), Color("1c232b"))
	var d := _cz_data()
	draw_string(font, BIG.position + Vector2(14, 18), "Nadir è a %s alle %s   ·   si entra alle %s   ·   %d € al giorno" % [
		_cz_stop_name(cz_at), _clock(cz_now), str(d.get("entrata", "8:00")), int(d.get("budget", 6))], HORIZONTAL_ALIGNMENT_LEFT, BIG.size.x - 28, 9, YELLOW)
	var targets := _cz_targets()
	var focus: Variant = null if TouchControls.enabled or targets.is_empty() else targets[clampi(cz_focus, 0, targets.size() - 1)]
	var lines := _cz_lines()
	var rides := _cz_rides()
	# prima le curve, poi i cartellini con gli orari, poi le fermate sopra a tutto
	for li in lines.size():
		var l: Dictionary = lines[li]
		var curve := _cz_curve(l)
		var taken := false
		for k: int in l["corse"]:
			taken = taken or k in cz_path
		var col: Color = CZ_COLORS[li % CZ_COLORS.size()]
		if int(l["da"]) != cz_at and not taken:
			col = col.darkened(0.55)
		if focus is Dictionary and (focus as Dictionary)["linea"] == l["linea"] and (focus as Dictionary)["da"] == l["da"]:
			draw_polyline(curve, YELLOW, 8.0)
		draw_polyline(curve, Color.WHITE if taken else col, 4.0)
		# la freccia (prima del cartellino): da che parte va la linea
		var mid := curve[5]
		var dir := (curve[6] - curve[4]).normalized()
		draw_colored_polygon(PackedVector2Array([mid + dir * 7, mid - dir * 5 + dir.orthogonal() * 6, mid - dir * 5 - dir.orthogonal() * 6]), Color.WHITE if taken else col)
	for li in lines.size():
		var l: Dictionary = lines[li]
		var first: Dictionary = rides[(l["corse"] as Array)[0]]
		var stato := str(first.get("stato", ""))
		var top := str(l["linea"]) + "  ·  " + ("solo badge" if stato == "badge" else (str(first["nota"]) if first.has("nota") else "%d €" % int(first.get("euro", 0))))
		var times: Array = []
		for k: int in l["corse"]:
			var c: Dictionary = rides[k]
			times.append(str(c["parte"]) + (" soppressa" if str(c.get("stato", "")) == "soppressa" else ""))
		var bottom := "parte " + ", ".join(times)
		var curve := _cz_curve(l)
		var w := maxf(font.get_string_size(top, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x, font.get_string_size(bottom, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x) + 8
		# il cartellino sta sulla curva, a metà: così non si confonde con quello della linea accanto
		var r := Rect2(curve[10] - Vector2(w, 21) / 2.0, Vector2(w, 21))
		var col: Color = CZ_COLORS[li % CZ_COLORS.size()]
		var here := int(l["da"]) == cz_at
		draw_rect(r, Color(0.08, 0.1, 0.13, 0.92 if here else 0.75))
		draw_rect(r, col if here else col.darkened(0.55), false, 1.0)
		draw_string(font, r.position + Vector2(4, 9), top, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("ff7a6a") if stato == "badge" else (Color("f2ead8") if here else Color("8a98a4")))
		draw_string(font, r.position + Vector2(4, 18), bottom, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("f2ead8") if here else Color("8a98a4"))
	var last := (d["fermate"] as Array).size() - 1
	for i in last + 1:
		var p := _cz_stop_pos(i)
		var here := i == cz_at
		draw_circle(p, CZ_STOP + 2, Color.BLACK)
		draw_circle(p, CZ_STOP, YELLOW if here else (Color("6ad07a") if i == last else Color("e8e8e8")))
		var name := _cz_stop_name(i) + (" (lavoro)" if i == last else "")
		# il lavoro ha il nome sotto: sopra passano le linee che arrivano
		draw_string(font, p + Vector2(-60, CZ_STOP + 14 if i == last else -CZ_STOP - 5), name, HORIZONTAL_ALIGNMENT_CENTER, 120, 9, YELLOW if here else Color("f2ead8"))
		if here:
			draw_arc(p, CZ_STOP + 4 + sin(Time.get_ticks_msec() / 160.0) * 2.0, 0, TAU, 24, YELLOW, 2.0)
	if cz_trail.size() >= 2:
		draw_polyline(cz_trail, YELLOW, 3.0)
		draw_circle(cz_trail[cz_trail.size() - 1], 5, YELLOW)
	PracticeCard.button(self, _cz_reset_button(), "RICOMINCIA", Color("4a5a6a"), font, focus is String, 11)
	draw_string(font, Vector2(BIG.position.x + 14, BIG.end.y - 14), cz_msg, HORIZONTAL_ALIGNMENT_LEFT, BIG.size.x - 150, 9,
		Color("ffb0b0") if flash > 0.0 else Color("c8c0d0"))


func _pr_list() -> Array:
	return GameState.bank.get("teo", {}).get("pratiche", [])


func _pr_card() -> Rect2:
	return Rect2(BIG.position.x + 70, BIG.position.y + 8, BIG.size.x - 140, 116)


func _pr_row(k: int) -> Rect2:
	var card := _pr_card()
	return Rect2(card.position.x + 8, card.position.y + 29 + k * 17, card.size.x - 16, 17)


func _pr_none_button() -> Rect2:
	return Rect2(BIG.position.x + 160, BIG.end.y - 46, BIG.size.x - 320, 36)


func _pr_target_count() -> int:
	if pr_i >= _pr_list().size():
		return 1
	return (_pr_list()[pr_i].get("righe", []) as Array).size() + 1


func _pr_target(k: int) -> Rect2:
	return _pr_none_button() if k == _pr_target_count() - 1 else _pr_row(k)


## Riga che dimostra l'anomalia; -1 significa che il fascicolo è davvero in ordine.
## Il ripiego mantiene compatibili eventuali dati precedenti privi del campo `riga`.
func _pr_correct(p: Dictionary) -> int:
	if p.has("riga"):
		return int(p["riga"])
	return [-1, 0, 2, 2, 3][clampi(int(p.get("tipo", 0)), 0, 4)]


func _pr_answer(k: int) -> void:
	if phase != "play" or pr_i >= _pr_list().size():
		return
	var p: Dictionary = _pr_list()[pr_i]
	var picked := -1 if k == _pr_target_count() - 1 else k
	if picked == _pr_correct(p):
		pr_i += 1
		pr_sel = 0
		pr_msg = "Pratica %s: anomalia trovata." % str(p.get("id", "")) if picked >= 0 else "Pratica %s: nessuna anomalia." % str(p.get("id", ""))
		Sound.sfx("arcade/confirm_2", 1.0 + pr_i * 0.025, 4.0)
		if pr_i >= _pr_list().size():
			_finish(true)
	else:
		misses += 1
		flash = 0.3
		pr_msg = "Teo: \"Non il nome del problema. Fammi vedere la riga che lo prova.\""
		Sound.sfx("arcade/blocked", 1.0, 4.0)
		if misses >= int(cfg.get("misses", 2)):
			_finish(false)


func _draw_pratiche(font: Font) -> void:
	draw_rect(BIG.grow(-4), Color("1e2430"))
	if pr_i < _pr_list().size():
		var card := _pr_card()
		PracticeCard.draw(self, card, _pr_list()[pr_i], font)
		for k in (_pr_list()[pr_i].get("righe", []) as Array).size():
			var row := _pr_row(k)
			if k == pr_sel and not TouchControls.enabled:
				draw_rect(row, Color(1.0, 0.88, 0.30, 0.22))
				draw_rect(row, YELLOW, false, 2.0)
		draw_string(font, Vector2(BIG.position.x, BIG.position.y + 145), "Indica la riga che dimostra l'errore.", HORIZONTAL_ALIGNMENT_CENTER, BIG.size.x, 10, Color("c8c0d0"))
	if pr_msg != "":
		draw_string(font, Vector2(BIG.position.x, BIG.position.y + 167), pr_msg, HORIZONTAL_ALIGNMENT_CENTER, BIG.size.x, 9, Color("ffb0b0") if flash > 0.0 else Color("c8c0d0"))
	if pr_i < _pr_list().size():
		var none_index := _pr_target_count() - 1
		PracticeCard.button(self, _pr_none_button(), "NESSUNA ANOMALIA", Color("2a7a54"), font, pr_sel == none_index and not TouchControls.enabled, 10)


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
	var examples := [["Fragola", "Cipollotto", "Patata", "Cipolla"], ["Sapone", "Dentifricio", "Shampoo"], ["Matita", "Quaderno", "Righello"], ["Scopa", "Lampadina", "Spugna"]]
	for k in INV_CATS.size():
		var r := _inv_shelf(k)
		var col: Color = INV_COLS[k]
		Art.panel(self, r, Color("684b3d"), Color("c99c68"))
		draw_rect(Rect2(r.position + Vector2(3, 3), Vector2(r.size.x - 6, 20)), col.darkened(0.58))
		draw_string(font, r.position + Vector2(0, 16), INV_CATS[k], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 9, Art.CREAM)
		var spacing := (r.size.x - 10.0) / float(examples[k].size())
		for i in examples[k].size():
			Art.product(self, Rect2(r.position + Vector2(5 + i * spacing, 27), Vector2(floorf(spacing - 1), 30)), str(examples[k][i]))
		draw_rect(Rect2(r.position + Vector2(3, 59), Vector2(r.size.x - 6, 5)), Color("c99c68"))
		draw_rect(Rect2(r.position + Vector2(3, 64), Vector2(r.size.x - 6, 5)), Color("4d3631"))
		if k == inv_sel and not TouchControls.enabled:
			draw_rect(r.grow(2), YELLOW, false, 2)
			draw_rect(Rect2(r.get_center().x - 4, r.end.y - 9, 8, 3), YELLOW)


func _rt_card(i: int) -> Rect2:
	return Rect2(410, 122 + i * 43, 194, 38)


func _draw_route(font: Font) -> void:
	var nb := _rt_neighbors(rt_at)
	var selected := int(nb[clampi(rt_sel, 0, nb.size()-1)]) if not nb.is_empty() else -1
	draw_string(font, Vector2(38, 84), "%s   CONSEGNE %d/3" % [str(RT_MAPS[rt_map]["title"]), rt_done.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
	draw_string(font, Vector2(410, 84), "%d MIN DISPONIBILI" % rt_left, HORIZONTAL_ALIGNMENT_CENTER, 194, 10, YELLOW)
	draw_line(Vector2(36, 94), Vector2(604, 94), Color("52616d"), 1)
	# Il tragitto selezionato resta l'unico luminoso; gli altri sono sullo sfondo.
	for e: Array in rt_edges:
		var a: Vector2 = rt_nodes[int(e[0])]
		var b: Vector2 = rt_nodes[int(e[1])]
		var risky := bool(e[3])
		var active := (int(e[0]) == rt_at and int(e[1]) == selected) or (int(e[1]) == rt_at and int(e[0]) == selected)
		var col := YELLOW if active else (Color("bd7168") if risky else Color("617b86"))
		if risky:
			var steps := maxi(1, int(a.distance_to(b) / 9.0))
			for i in steps:
				if i % 2 == 0: draw_line(a.lerp(b,float(i)/steps), a.lerp(b,float(i+1)/steps), col, 3 if active else 2)
		else:
			draw_line(a, b, col, 5 if active else 3)
		var mid := a.lerp(b, 0.5)
		draw_rect(Rect2(mid-Vector2(13,7), Vector2(26,14)), Color("202b35"))
		draw_string(font, mid+Vector2(-13,3), str(int(e[2]))+"'", HORIZONTAL_ALIGNMENT_CENTER, 26, 9, col)
	for i in rt_nodes.size():
		var at: Vector2 = rt_nodes[i]
		var parcel := rt_parcels.find(i)
		var col := GREEN if i in rt_done else (YELLOW if parcel >= 0 else Color("9baeb5"))
		draw_circle(at, 11, Color("141e29"))
		draw_arc(at, 11, 0, TAU, 32, col, 2)
		if i == selected: draw_arc(at, 15, 0, TAU, 32, YELLOW, 2)
		if parcel >= 0:
			draw_string(font, at+Vector2(-9,4), "OK" if i in rt_done else str(parcel+1), HORIZONTAL_ALIGNMENT_CENTER, 18, 9, col)
		elif i != rt_at:
			draw_circle(at, 3, col)
		# Le destinazioni stanno fuori dalle strade, mai sopra i costi.
		var y := at.y+28 if at.y >= 190 else at.y-20
		var name_ := str(rt_names[i]).replace("Incrocio", "Inc.")
		draw_string(font, Vector2(at.x-48,y), name_, HORIZONTAL_ALIGNMENT_CENTER, 96, 9, col)
	_heart(rt_from.lerp(rt_to, rt_k), RED)
	draw_string(font, Vector2(410, 112), "SCEGLI DOVE ANDARE", HORIZONTAL_ALIGNMENT_CENTER, 194, 10, Color.WHITE)
	for i in nb.size():
		var n := int(nb[i])
		var edge := _rt_edge(rt_at, n)
		var risk := bool(edge[3])
		var card := _rt_card(i)
		var chosen := i == rt_sel
		draw_rect(card, Color("3b4c58") if chosen else Color("293640"))
		draw_rect(card, YELLOW if chosen else Color("52616d"), false, 1)
		draw_string(font, card.position+Vector2(7,14), str(rt_names[n]), HORIZONTAL_ALIGNMENT_LEFT, 180, 10, Color.WHITE)
		var detail := "%d min  %s" % [int(edge[2]), "CANTIERE: rischio +40" if risk else "STRADA SICURA"]
		draw_string(font, card.position+Vector2(7,29), detail, HORIZONTAL_ALIGNMENT_LEFT, 180, 8, Color("f09c87") if risk else Color("83d6bd"))
	draw_string(font, Vector2(38, 310), "1 2 3 = PACCHI   VERDE = CONSEGNATO", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("c4d3d7"))
	var message := rt_msg if rt_msg != "" else "Il tempo scende solo quando viaggi. Le linee rosse passano dai cantieri."
	draw_string(font, Vector2(38, 332), message, HORIZONTAL_ALIGNMENT_LEFT, 566, 8, Color("f0b58a") if rt_msg != "" else Color("c4d3d7"))


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
		if wire_drag.x >= 0.0 and wire_drag.x < rx - 4:
			# il filo segue il dito
			Art.lead(self, Vector2(lx, yl2), wire_drag, WIRE_COLS[wire_pick], 4)
		else:
			Art.lead(self, Vector2(lx, yl2), Vector2(rx, yr), WIRE_COLS[wire_pick], 3)
			draw_rect(Rect2(rx - 4, yr - 8, 38, 16), Art.GOLD, false, 2)
	draw_string(font, Vector2(BOX.position.x, BOX.end.y - 6), "Pannello %d di %d" % [mini(wire_round + 1, _wire_rounds()), _wire_rounds()], HORIZONTAL_ALIGNMENT_CENTER, BOX.size.x, 10, Art.CREAM)


## Il tempo e gli errori, da vedere e non da leggere: una barra sotto il riquadro che si accorcia
## (gialla, poi rossa che lampeggia) e a destra una lampadina per ogni errore che puoi fare:
## a ogni errore se ne fulmina una.
func _draw_stato() -> void:
	if time_total > 0.0:
		var bar := Rect2(BOX.position.x, BOX.end.y + 8, BOX.size.x, 6)
		var k := clampf(time_left / time_total, 0.0, 1.0)
		var col := GREEN if k > 0.5 else (YELLOW if k > 0.25 else RED)
		draw_rect(bar.grow(1), Color("1a222b"))
		if k > 0.25 or int(t_spin * 2.0) % 2 == 0:
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * k, bar.size.y)), col)
	for i in _max_misses():
		var ok := i < _max_misses() - misses
		Art.bulb(self, Vector2(BOX.end.x + 18, BOX.position.y + 14 + i * 24), "buona" if ok else "rotta", 1, ok)
	if guida and phase == "play":
		_draw_guida()


## Il primo giro mostra il gesto giusto, poi sparisce: un dito (o la freccia del mouse) che porta
## il primo filo al suo posto; per le lampadine, una freccia verso la scatola giusta.
func _draw_guida() -> void:
	var a := 0.55 + 0.35 * sin(t_spin * 2.0)
	if type == "bulbs":
		var c := BOX.get_center() + Vector2(0, -6)
		var dir := "up" if bulb == "fioca" else ("left" if bulb == "rotta" else "right")
		var off: Vector2 = {"up": Vector2(0, -34), "left": Vector2(-62, 0), "right": Vector2(62, 0)}[dir]
		_arrow(c + off + off.normalized() * 4.0 * sin(t_spin * 3.0), dir, 9.0, Color(1, 0.88, 0.3, a))
		return
	if wire_pick >= 0 or wire_right.size() < 4:
		return
	var y0 := BOX.position.y + 26
	var gap := (BOX.size.y - 52) / 3.0
	var from := Vector2(BOX.position.x + 40, y0)
	var to := Vector2(BOX.end.x - 40, y0 + wire_right.find(0) * gap)
	var k := fmod(bulb_t / 1.6, 1.0)
	var p := from.lerp(to, ease(minf(k * 1.25, 1.0), -2.0))
	if TouchControls.enabled:
		draw_circle(p, 7.0, Color(1, 1, 1, a * 0.5))
		draw_circle(p, 4.0, Color(1, 1, 1, a))
	else:
		var pts := PackedVector2Array([p, p + Vector2(0, 12), p + Vector2(3, 9), p + Vector2(6, 14), p + Vector2(8, 13), p + Vector2(5, 8), p + Vector2(9, 8)])
		draw_colored_polygon(pts, Color(1, 1, 1, a))


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
