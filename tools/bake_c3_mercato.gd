extends Node
## Costruisce la scena del Mercato (capitolo 3) e la salva come scena vera in res://chapters/c3/mercato.tscn.
## Da lì in poi la scena si può modificare nell'editor di Godot (rilanciare lo script la sovrascrive).
## Esegui:  Godot --headless --path . res://tools/bake_c3_mercato.tscn
##
## Tre stanze sullo stesso piano, col bordo bianco come nelle mappe di LimeZu (RoomOutline):
##   il supermercato   (a sinistra, grande): frigo, corsie, banchi frigo, casse col TURNO, il banco di Leda
##   l'ufficio badge   (in alto a destra): lo sportello di Nives e le scale per la Banca
##   il magazzino      (in basso a destra): le consegne di Amir, le cassette, l'angolo pausa con le panchine
## La mappa si legge in ROWS: # vuoto, S/U/M parete, s/u/m pavimento (una lettera per stanza).

const T := 16
const TILESET_PATH := "res://world/tilesets/interni.tres"
const OUT := "res://chapters/c3/mercato.tscn"
const MARKET := "res://assets/limezu/market/"
const PROPS := "res://assets/limezu/props/"
const GROCERY := "res://assets/limezu/grocery/"
const STREET := "res://assets/limezu/street/"
const AFTER := "c3_rivelazione"

## Le tessere (in room_builder): le pareti sono motivi 3x2, i pavimenti 3x2.
const VOID := Vector2i(12, 0)
const WALLS := {"S": Vector2i(22, 31), "U": Vector2i(11, 41), "M": Vector2i(0, 41)}
const FLOORS := {"s": Vector2i(38, 15), "u": Vector2i(34, 11), "m": Vector2i(46, 33)}

const ROWS := [
	"####################################",
	"#SSSSSSSSSSSSSSSSSSSSSS#UUUUUUUUUUU#",
	"#SSSSSSSSSSSSSSSSSSSSSS#UUUUUUUUUUU#",
	"#ssssssssssssssssssssss#uuuuuuuuuuu#",
	"#ssssssssssssssssssssssuuuuuuuuuuuu#",
	"#ssssssssssssssssssssssuuuuuuuuuuuu#",
	"#ssssssssssssssssssssss#uuuuuuuuuuu#",
	"#ssssssssssssssssssssss#############",
	"#ssssssssssssssssssssss#MMMMMMMMMMM#",
	"#ssssssssssssssssssssss#MMMMMMMMMMM#",
	"#ssssssssssssssssssssss#mmmmmmmmmmm#",
	"#ssssssssssssssssssssss#mmmmmmmmmmm#",
	"#ssssssssssssssssssssssmmmmmmmmmmmm#",
	"#ssssssssssssssssssssssmmmmmmmmmmmm#",
	"#ssssssssssssssssssssss#mmmmmmmmmmm#",
	"#ssssssssssssssssssssss#mmmmmmmmmmm#",
	"####################################",
]

var root: Node2D
var mondo: Node2D
var decori: Node2D


func _ready() -> void:
	var ts := _tileset()
	root = Node2D.new()
	root.name = "Mercato"
	root.set_script(load("res://chapters/c3/mercato_c3.gd"))
	root.set("room_floor", "-3")
	root.set("room_music", "mercato")
	var pav := TileMapLayer.new()
	pav.name = "Pavimento"
	pav.tile_set = ts
	_add(root, pav)
	var muri := TileMapLayer.new()
	muri.name = "Muri"
	muri.tile_set = ts
	_add(root, muri)
	for y in ROWS.size():
		var row: String = ROWS[y]
		for x in row.length():
			var c := Vector2i(x, y)
			var ch := row[x]
			if ch == "#":
				muri.set_cell(c, 0, VOID)
			elif WALLS.has(ch):
				# la parete è alta due caselle: la prima riga di parete usa la riga alta del motivo
				var top := y == 0 or str(ROWS[y - 1])[x] != ch
				muri.set_cell(c, 0, WALLS[ch] + Vector2i(x % 3, 0 if top else 1))
			else:
				pav.set_cell(c, 0, FLOORS[ch] + Vector2i(x % 3, y % 2))
	var bordo := RoomOutline.new()
	bordo.name = "Bordo"
	_add(root, bordo)
	decori = Node2D.new()
	decori.name = "Decori"
	_add(root, decori)
	mondo = Node2D.new()
	mondo.name = "Mondo"
	mondo.y_sort_enabled = true
	_add(root, mondo)
	_insegne()
	_negozio()
	_supermercato()
	_casse()
	_ufficio()
	_magazzino()
	_features()
	var arrivi := Node2D.new()
	arrivi.name = "Arrivi"
	_add(root, arrivi)
	_arrival(arrivi, "default", Vector2i(11, 6), "down")
	for n in root.find_children("*", "CharSprite", true, false):
		(n as CharSprite).sprite_frames = null
		(n as CharSprite).material = null
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		DirAccess.make_dir_recursive_absolute("res://chapters/c3")
		err = ResourceSaver.save(packed, OUT)
	print("BAKE ", OUT, " -> ", error_string(err))
	get_tree().quit()


func _add(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root


# --- il TileSet condiviso: aggiunge pareti e pavimenti del Mercato ------------------

func _tileset() -> TileSet:
	var ts: TileSet = load(TILESET_PATH)
	var s := ts.get_source(0) as TileSetAtlasSource
	var solid := [VOID]
	var floors := []
	for dy in 2:
		for dx in 3:
			for w: Vector2i in WALLS.values():
				solid.append(w + Vector2i(dx, dy))
			for f: Vector2i in FLOORS.values():
				floors.append(f + Vector2i(dx, dy))
	for c: Vector2i in solid + floors:
		if not s.has_tile(c):
			s.create_tile(c)
	var half := T / 2.0
	var square := PackedVector2Array([Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	for c: Vector2i in solid:
		var d := s.get_tile_data(c, 0)
		if d.get_collision_polygons_count(0) == 0:
			d.add_collision_polygon(0)
			d.set_collision_polygon_points(0, 0, square)
	ResourceSaver.save(ts, TILESET_PATH)
	return load(TILESET_PATH)


## Uno sprite con l'angolo in basso a sinistra sulla casella `cell`.
## `foot` = quanti pixel in basso sono solidi (0 = ci si passa sopra).
func _sprite(parent: Node, nm: String, tex: String, region: Rect2, cell: Vector2i, foot := 0, nudge := Vector2.ZERO) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = nm
	s.texture = load(tex)
	if region.size != Vector2.ZERO:
		s.region_enabled = true
		s.region_rect = region
	var size := region.size if region.size != Vector2.ZERO else s.texture.get_size()
	s.centered = false
	s.offset = Vector2(0, -size.y)
	s.position = Vector2(cell.x * T, (cell.y + 1) * T) + nudge
	_add(parent, s)
	if foot > 0:
		var body := StaticBody2D.new()
		body.name = "Collisione"
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(size.x - 4, foot)
		shape.shape = rect
		shape.position = Vector2(size.x / 2.0, -foot / 2.0)
		s.add_child(body)
		body.owner = root
		body.add_child(shape)
		shape.owner = root
	return s


func _examine(parent: Node, nm: String, cell: Vector2i, lines: Array, method := "", after: Array = []) -> void:
	var e := Examine.new()
	e.name = nm
	e.position = Vector2(cell.x * T + 8, cell.y * T + 8)
	e.lines = PackedStringArray(lines)
	e.method = method
	if not after.is_empty():
		e.lines_after = PackedStringArray(after)
		e.after_flag = AFTER
	_add(parent, e)


## Un muro invisibile (in caselle).
func _solid(nm: String, cells: Rect2i) -> void:
	var body := StaticBody2D.new()
	body.name = nm
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(cells.size * T)
	shape.shape = rect
	body.position = Vector2(cells.position * T) + rect.size / 2.0
	_add(mondo, body)
	body.add_child(shape)
	shape.owner = root


func _person(nm: String, sheet: String, anim: String, cell: Vector2i, nudge := Vector2.ZERO) -> CharSprite:
	var c := CharSprite.new()
	c.name = nm
	c.sheet = sheet
	c.anim = anim
	c.nudge = nudge
	c.position = Vector2(cell.x * T + 8, (cell.y + 1) * T - 2)
	_add(mondo, c)
	return c


func _npc(nm: String, id: String, activity: String, cell: Vector2i) -> void:
	var n := NpcSpot.new()
	n.name = nm
	n.npc_id = id
	n.activity = activity
	n.position = Vector2(cell.x * T + 8, (cell.y + 1) * T - 2)
	_add(mondo, n)


## Un pezzo del supermercato LimeZu (grocery/<n>.png).
func _g(nm: String, n: int, cell: Vector2i, foot := 0, nudge := Vector2.ZERO) -> Sprite2D:
	return _sprite(mondo, nm, GROCERY + "%d.png" % n, Rect2(), cell, foot, nudge)


## Una cosa appoggiata sopra un'altra (la frutta sulla cassetta): figlia, così si disegna davanti.
func _on_top(base: Sprite2D, nm: String, tex: String, lift: float) -> void:
	var s := Sprite2D.new()
	s.name = nm
	s.texture = load(tex)
	s.centered = false
	s.offset = Vector2(0, -s.texture.get_size().y - lift)
	_add(base, s)


# --- il supermercato: tutto saturo, tutto in offerta -------------------------------------

func _insegne() -> void:
	# "OGGI TUTTO AL 50%*" sopra il banco di Leda, il tabellone dei prezzi in mezzo alla parete
	var saldi := _sprite(decori, "InsegnaSaldi", "res://art/sign_saldi.png", Rect2(), Vector2i(3, 1), 0, Vector2(4, 4))
	saldi.z_index = 1
	var board := _sprite(decori, "Tabellone", "res://art/price_board.png", Rect2(), Vector2i(12, 2), 0, Vector2(0, 2))
	board.z_index = 1
	_examine(mondo, "GuardaSaldi", Vector2i(9, 3), [], "_saldi")
	_examine(mondo, "GuardaTabellone", Vector2i(15, 3), [], "_tabellone")
	# i cartellini dello sconto, appesi qua e là sulla parete
	for i in 3:
		var tag := _sprite(decori, "Cartellino%d" % i, GROCERY + "97.png", Rect2(), Vector2i([1, 10, 20][i], 1), 0, Vector2(0, 6))
		tag.z_index = 1


## Il banco di Leda, in alto a sinistra: pane, latte, sogni, aria. E la lavagnetta dei conti.
func _negozio() -> void:
	_g("Pane", 250, Vector2i(1, 4), 10)
	_g("Latte", 147, Vector2i(3, 4), 10)
	_g("Sogni", 437, Vector2i(5, 4), 10)
	_g("Aria", 249, Vector2i(7, 4), 10)
	_g("Bancone0", 145, Vector2i(1, 7), 12)
	_g("Bancone1", 146, Vector2i(3, 7), 12)
	_sprite(mondo, "Lavagnetta", "res://art/chalkboard.png", Rect2(), Vector2i(6, 7), 6)
	_examine(mondo, "ProdottoPane", Vector2i(1, 4), [], "_pane")
	_examine(mondo, "ProdottoLatte", Vector2i(3, 4), [], "_latte")
	_examine(mondo, "ProdottoSogno", Vector2i(5, 4), [], "_sogno")
	_examine(mondo, "ProdottoAria", Vector2i(7, 4), [], "_aria")
	_examine(mondo, "ProdottoTazza", Vector2i(2, 7), [], "_tazza")
	_examine(mondo, "GuardaLavagnetta", Vector2i(6, 7), [], "_lavagnetta")
	_npc("Leda", "leda", "idle_down", Vector2i(5, 7))


## Le corsie, i frigo, i banchi frigo, la frutta: il supermercato vero.
func _supermercato() -> void:
	_sprite(mondo, "Distributore", "res://art/water_machine.png", Rect2(), Vector2i(11, 3), 10)
	_examine(mondo, "UsaDistributore", Vector2i(11, 3), [], "_acqua")
	# i frigo contro la parete, a destra del tabellone
	_g("Frigo0", 58, Vector2i(19, 4), 12)
	_g("Frigo1", 61, Vector2i(21, 4), 12)
	_examine(mondo, "GuardaFrigo", Vector2i(20, 4), [
		"* Frigo pieni. Su ogni yogurt un adesivo giallo: \"-50%\". Sotto, uno più piccolo: \"sul prezzo di domani\".",
	])
	# tre corsie di scaffali, viste di lato: in mezzo ci si passa
	var aisles := [[113, 114], [115, 116], [113, 115]]
	for i in 3:
		var x := 9 + i * 4
		_g("Corsia%dA" % i, aisles[i][0], Vector2i(x, 8), 40)
		_g("Corsia%dB" % i, aisles[i][1], Vector2i(x, 11), 40)
	_examine(mondo, "GuardaCorsia", Vector2i(10, 12), [
		"* Una corsia intera di biscotti. Le confezioni sono grandi, i biscotti dentro sono tre.",
	])
	# i banchi frigo, a destra
	_g("BancoFrigo0", 148, Vector2i(20, 7), 12)
	_g("BancoFrigo1", 149, Vector2i(20, 10), 12)
	# la frutta: cassette impilate, con la frutta in cima
	var crates := [403, 404, 406, 407, 405, 403]
	var fruit := [409, 410, 412, 414, 415, 413]
	for i in 6:
		var c := _g("Frutta%d" % i, crates[i], Vector2i(16 + i, 15), 10)
		_on_top(c, "Sopra", GROCERY + "%d.png" % fruit[i], 22)
	_examine(mondo, "GuardaFrutta", Vector2i(18, 14), [
		"* Frutta lucida, tutta uguale. Le mele hanno il codice a barre stampato sulla buccia.",
	])
	_g("Pianta0", 451, Vector2i(22, 7), 8)
	_g("Pianta1", 449, Vector2i(1, 12), 8)
	var customers := [
		["Cliente0", "char_15", Vector2i(11, 9), "idle_right", ["* \"Ho comprato tre cose che non mi servono. Ma erano al 50%!\"", "* Ti mostra lo scontrino. È più lungo di lui."]],
		["Cliente1", "char_16", Vector2i(15, 10), "idle_left", ["* \"Mi scusi, sa dov'è il reparto Felicità? Sulla mappa c'è, ma è in esaurimento.\""]],
		["Cliente2", "char_19", Vector2i(15, 5), "idle_up", ["* Guarda il tabellone dei prezzi. Il latte costa quanto un'ora di cassa.", "* \"Lo guardo e basta. Guardare è ancora gratis. Credo.\""]],
	]
	for c: Array in customers:
		_person(c[0], c[1], c[3], c[2])
		_examine(mondo, "Guarda" + c[0], c[2], c[4], "", ["* Sorride ancora. Sorride a tutto. Anche al tabellone."])
		_solid("Piedi" + c[0], Rect2i(c[2], Vector2i.ONE))


## Le casse in basso, vicino alle scale: la prima è quella del TURNO.
func _casse() -> void:
	for i in 3:
		_g("Cassa%d" % i, 170 + i, Vector2i(7 + i * 3, 14), 12)
	# le barriere antitaccheggio all'uscita delle casse
	_g("Antifurto0", 151, Vector2i(6, 15), 6)
	_g("Antifurto1", 151, Vector2i(15, 15), 6)


## L'ufficio badge: Nives, una pianta, le scale per la Banca.
func _ufficio() -> void:
	_g("PiantaUfficio0", 449, Vector2i(24, 4), 8)
	_g("PiantaUfficio1", 451, Vector2i(34, 6), 8)


## Il magazzino di Amir: cassette fino al soffitto, i pallet, il terminale, l'angolo pausa.
func _magazzino() -> void:
	for i in 6:
		_g("Cassette%d" % i, [401, 402, 403, 404, 405, 406][i], Vector2i(26 + i, 10), 10)
	_sprite(mondo, "Pallet0", MARKET + "table_3.png", Rect2(), Vector2i(26, 13), 14)
	_sprite(mondo, "Scatoloni", PROPS + "boxes.png", Rect2(), Vector2i(32, 10), 12)
	# le tre scatole di Amir (le consegne sono quattro)
	for i in 3:
		_sprite(mondo, "ScatolaAmir%d" % i, MARKET + ["box_1.png", "box_2.png", "box_5.png"][i], Rect2(), Vector2i(25 + i * 2, 15), 10)
	_sprite(mondo, "Terminale", "res://art/terminal_consegne.png", Rect2(), Vector2i(34, 12), 8)
	_examine(mondo, "UsaTerminale", Vector2i(34, 12), [], "_terminale")
	_examine(mondo, "GuardaScatole", Vector2i(32, 10), [
		"* Scatole CHEAP impilate fino al soffitto. Su ognuna: \"FRAGILE — CONSEGNA ENTRO IERI\".",
	])
	_npc("Amir", "amir", "idle_down", Vector2i(30, 12))
	# l'angolo pausa: due panchine una di fronte all'altra (qui si siedono Leda e Amir, nella scena segreta)
	var bl := _sprite(mondo, "PanchinaSinistra", STREET + "bench_side.png", Rect2(), Vector2i(31, 15), 0)
	bl.flip_h = true
	_sprite(mondo, "PanchinaDestra", STREET + "bench_side.png", Rect2(), Vector2i(33, 15), 0)
	_solid("PiediPanchine", Rect2i(31, 13, 1, 3))
	_solid("PiediPanchine2", Rect2i(33, 13, 1, 3))
	_examine(mondo, "GuardaPanchine", Vector2i(32, 14), [
		"* L'angolo pausa: due panchine prese dal parco. Qualcuno ci ha scritto sopra a matita: \"5 MINUTI\".",
	])


func _feature(nm: String, kind: String, cell: Vector2i, props := {}) -> void:
	var f := RoomFeature.new()
	f.name = nm
	f.kind = kind
	f.position = Vector2(cell * T)
	for k: String in props:
		f.set(k, props[k])
	_add(mondo, f)


func _features() -> void:
	_feature("PostoCassa", "station", Vector2i(7, 14), {"job": "cassa_mercato"})
	_feature("SportelloBadge", "badge", Vector2i(28, 3))
	_feature("ScaleSu", "stairs_up", Vector2i(32, 3), {"target": "res://chapters/c4/banca.tscn", "spawn": "from_below", "need": "-2"})
	_feature("ScaleGiu", "stairs_down", Vector2i(2, 15), {"target": "res://chapters/c2/sottoufficio.tscn", "spawn": "from_above"})
	_feature("Stellina", "save", Vector2i(12, 12))


func _arrival(parent: Node, nm: String, cell: Vector2i, facing: String) -> void:
	var m := Marker2D.new()
	m.name = nm
	m.position = Vector2(cell.x * T + T / 2.0, (cell.y + 1) * T - 2)
	m.set_meta("facing", facing)
	_add(parent, m)
