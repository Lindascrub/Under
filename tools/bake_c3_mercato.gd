extends Node
## Costruisce UNA VOLTA la scena del Mercato (capitolo 3) e la salva come scena vera
## in res://chapters/c3/mercato.tscn. Da lì in poi la scena si modifica nell'editor di Godot:
## questo script serve solo a creare la prima versione (non rilanciarlo, o sovrascrive le modifiche).
## Esegui:  Godot --headless --path . res://tools/bake_c3_mercato.tscn
##
## Sei zone intorno alla piazza:
##   in basso a sinistra  le scale dal Sottoufficio (l'ingresso)
##   in alto a sinistra   la cassa (TURNO)
##   a sinistra           il negozio di Leda (parquet)
##   in basso a destra    il magazzino di Amir (cemento)
##   al centro            la piazza: distributore d'acqua, tabellone dei prezzi, clienti colorati
##   in alto a destra     lo sportello di Nives e le scale per la Banca

const T := 16
const W := 24
const H := 14
const TILESET_PATH := "res://world/tilesets/interni.tres"
const OUT := "res://chapters/c3/mercato.tscn"
const MARKET := "res://assets/limezu/market/"
const PROPS := "res://assets/limezu/props/"

## Le piastrelle (motivi da 3x2 in room_builder): piazza azzurra, parquet da Leda,
## cemento nel magazzino, muro bianco da supermercato.
const PIAZZA := Vector2i(42, 33)
const WOOD := Vector2i(34, 33)
const CONCRETE := Vector2i(46, 33)
const WALL := Vector2i(29, 25)
const BORDER := Vector2i(12, 0)
const AFTER := "c3_rivelazione"
const SHOP := Rect2i(1, 6, 6, 4)
const STORE := Rect2i(15, 8, 8, 5)

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
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if x == 0 or x == W - 1 or y == 0 or y == H - 1:
				muri.set_cell(c, 0, BORDER)
			elif y <= 2:
				muri.set_cell(c, 0, WALL + Vector2i(x % 3, y - 1))
			else:
				var base := PIAZZA
				if SHOP.has_point(c):
					base = WOOD
				elif STORE.has_point(c):
					base = CONCRETE
				pav.set_cell(c, 0, base + Vector2i(x % 3, y % 2))
	decori = Node2D.new()
	decori.name = "Decori"
	_add(root, decori)
	mondo = Node2D.new()
	mondo.name = "Mondo"
	mondo.y_sort_enabled = true
	_add(root, mondo)
	_insegne()
	_cassa()
	_negozio()
	_piazza()
	_magazzino()
	_features()
	var arrivi := Node2D.new()
	arrivi.name = "Arrivi"
	_add(root, arrivi)
	_arrival(arrivi, "default", Vector2i(11, 7), "down")
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


# --- il TileSet condiviso: aggiunge piastrelle e muro del Mercato ------------------

func _tileset() -> TileSet:
	var ts: TileSet = load(TILESET_PATH)
	var s := ts.get_source(0) as TileSetAtlasSource
	var solid := [BORDER]
	var floors := []
	for dy in 2:
		for dx in 3:
			solid.append(WALL + Vector2i(dx, dy))
			for f in [PIAZZA, WOOD, CONCRETE]:
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


# --- il Mercato: tutto saturo, tutto in offerta -------------------------------------

func _insegne() -> void:
	# "OGGI TUTTO AL 50%*" sopra la cassa, il tabellone dei prezzi sopra la piazza
	var saldi := _sprite(decori, "InsegnaSaldi", "res://art/sign_saldi.png", Rect2(), Vector2i(3, 1), 0, Vector2(4, 4))
	saldi.z_index = 1
	var board := _sprite(decori, "Tabellone", "res://art/price_board.png", Rect2(), Vector2i(12, 2), 0, Vector2(0, 2))
	board.z_index = 1
	_examine(mondo, "GuardaSaldi", Vector2i(6, 3), [], "_saldi")
	_examine(mondo, "GuardaTabellone", Vector2i(14, 3), [], "_tabellone")


## La cassa: il nastro, lo scanner, il posto del TURNO.
func _cassa() -> void:
	_sprite(mondo, "Cassa", "res://art/cassa.png", Rect2(), Vector2i(2, 4), 12)
	_sprite(mondo, "CestiniCassa", PROPS + "boxes_small.png", Rect2(), Vector2i(1, 4), 8)
	# niente "guarda" sulla cassa: toccarla è il TURNO (PostoCassa)


## Il negozio di Leda: scaffali di legno, un bancone, la lavagnetta dei conti.
func _negozio() -> void:
	var sign := _sprite(decori, "InsegnaLeda", "res://art/sign_leda.png", Rect2(), Vector2i(1, 5), 0, Vector2(6, -2))
	sign.z_index = 1
	for i in 2:
		_sprite(mondo, "Scaffale%d" % i, "res://art/shelf.png", Rect2(), Vector2i(1 + i * 2, 7), 12)
	# solido tutto il piano del tavolo, non solo il bordo davanti (prima ci si finiva sotto)
	_sprite(mondo, "Bancone", MARKET + "table_2.png", Rect2(), Vector2i(1, 9), 22)
	_sprite(mondo, "Lavagnetta", "res://art/chalkboard.png", Rect2(), Vector2i(6, 7), 6)
	_examine(mondo, "ProdottoPane", Vector2i(1, 7), [], "_pane")
	_examine(mondo, "ProdottoLatte", Vector2i(2, 7), [], "_latte")
	_examine(mondo, "ProdottoSogno", Vector2i(3, 7), [], "_sogno")
	_examine(mondo, "ProdottoAria", Vector2i(4, 7), [], "_aria")
	_examine(mondo, "ProdottoTazza", Vector2i(2, 9), [], "_tazza")
	_examine(mondo, "GuardaLavagnetta", Vector2i(6, 7), [], "_lavagnetta")
	_npc("Leda", "leda", "idle_down", Vector2i(5, 8))


## La piazza: il distributore, le bancarelle colorate, i clienti che sorridono ai prezzi.
func _piazza() -> void:
	_sprite(mondo, "Distributore", "res://art/water_machine.png", Rect2(), Vector2i(9, 4), 10)
	_examine(mondo, "UsaDistributore", Vector2i(9, 4), [], "_acqua")
	_sprite(mondo, "Carretto", MARKET + "cart.png", Rect2(), Vector2i(14, 6), 14)
	_sprite(mondo, "TelaRossa", MARKET + "cloth_1.png", Rect2(), Vector2i(8, 11), 0)
	_sprite(mondo, "TelaBlu", MARKET + "cloth_3.png", Rect2(), Vector2i(12, 12), 0)
	_sprite(mondo, "Cestino", PROPS + "trash.png", Rect2(), Vector2i(16, 4), 8)
	var customers := [
		["Cliente0", "char_15", Vector2i(10, 8), "idle_right", ["* \"Ho comprato tre cose che non mi servono. Ma erano al 50%!\"", "* Ti mostra lo scontrino. È più lungo di lui."]],
		["Cliente1", "char_16", Vector2i(13, 9), "idle_left", ["* \"Mi scusi, sa dov'è il reparto Felicità? Sulla mappa c'è, ma è in esaurimento.\""]],
		["Cliente2", "char_19", Vector2i(15, 5), "idle_down", ["* Guarda il carretto dei gelati. Il gelato costa quanto un'ora di cassa.", "* \"Lo guardo e basta. Guardare è ancora gratis. Credo.\""]],
	]
	for c: Array in customers:
		_person(c[0], c[1], c[3], c[2])
		_examine(mondo, "Guarda" + c[0], c[2], c[4], "", ["* Sorride ancora. Sorride a tutto. Anche al tabellone."])
		_solid("Piedi" + c[0], Rect2i(c[2], Vector2i.ONE))


## Il magazzino di Amir: scatole, scaffalature, il terminale delle consegne.
func _magazzino() -> void:
	_sprite(mondo, "Pallet0", MARKET + "table_3.png", Rect2(), Vector2i(15, 10), 14)
	_sprite(mondo, "Pallet1", MARKET + "table_4.png", Rect2(), Vector2i(15, 12), 14)
	_sprite(mondo, "Scatoloni", PROPS + "boxes.png", Rect2(), Vector2i(21, 9), 12)
	# le tre scatole di Amir (le consegne sono quattro)
	for i in 3:
		_sprite(mondo, "ScatolaAmir%d" % i, MARKET + ["box_1.png", "box_2.png", "box_5.png"][i], Rect2(), Vector2i(17 + i * 2, 12), 10)
	_sprite(mondo, "Terminale", "res://art/terminal_consegne.png", Rect2(), Vector2i(22, 11), 8)
	_examine(mondo, "UsaTerminale", Vector2i(22, 11), [], "_terminale")
	_examine(mondo, "GuardaScatole", Vector2i(21, 9), [
		"* Scatole CHEAP impilate fino al soffitto. Su ognuna: \"FRAGILE — CONSEGNA ENTRO IERI\".",
	])
	_npc("Amir", "amir", "idle_down", Vector2i(19, 10))


func _feature(nm: String, kind: String, cell: Vector2i, props := {}) -> void:
	var f := RoomFeature.new()
	f.name = nm
	f.kind = kind
	f.position = Vector2(cell * T)
	for k: String in props:
		f.set(k, props[k])
	_add(mondo, f)


func _features() -> void:
	_feature("PostoCassa", "station", Vector2i(2, 4), {"job": "cassa_mercato"})
	_feature("SportelloBadge", "badge", Vector2i(18, 3))
	_feature("ScaleSu", "stairs_up", Vector2i(21, 3), {"target": "res://chapters/c4/banca.tscn", "spawn": "from_below", "need": "-2"})
	_feature("ScaleGiu", "stairs_down", Vector2i(4, 12), {"target": "res://chapters/c2/sottoufficio.tscn", "spawn": "from_above"})
	_feature("Stellina", "save", Vector2i(11, 11))


func _arrival(parent: Node, nm: String, cell: Vector2i, facing: String) -> void:
	var m := Marker2D.new()
	m.name = nm
	m.position = Vector2(cell.x * T + T / 2.0, (cell.y + 1) * T - 2)
	m.set_meta("facing", facing)
	_add(parent, m)
