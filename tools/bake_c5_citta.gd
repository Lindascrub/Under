extends Node
## Costruisce UNA VOLTA la scena della Città (capitolo 5) e la salva come scena vera
## in res://chapters/c5/citta.tscn. Da lì in poi la scena si modifica nell'editor di Godot:
## questo script serve solo a creare la prima versione (non rilanciarlo, o sovrascrive le modifiche).
## Esegui:  Godot --headless --path . res://tools/bake_c5_citta.tscn
##
## Una piazza piccola, da leggere su un telefono. In alto, da sinistra a destra, le facciate:
##   la Torre (porta di vetro verso la Banca, lo sportello di Nives, la scala esterna verso la Cima)
##   la Casa Comune (la porta porta dentro: casa_comune.tscn)
##   l'Ufficio Comunicazioni (il TURNO e il terminale delle presentazioni)
##   il cartellone CHEAP e la bottega di Rina (con la vetrina)
## In mezzo la strada con la fermata; in basso la piazza: l'albero, la panchina, la fontana.
## La grafica fatta apposta è ancora SEGNAPOSTO (art/c5/, vedi docs/ASSET_LIST.md).

const T := 16
const W := 42
const H := 21
const TILESET_PATH := "res://world/tilesets/citta.tres"
const OUT := "res://chapters/c5/citta.tscn"
const L := "res://assets/limezu/"
const ART := "res://art/c5/"
const CITY_TILES := "res://assets/limezu/tiles/city_terrains.png"
const TERRAINS := "res://assets/limezu/tiles/terrains.png"
const ROAD_ROWS := [12, 13]
const GRASS := Rect2i(1, 15, 8, 5)
## Dove stanno le scritte "BUS" sulla strada (7x2 caselle dal foglio city_terrains).
const BUS_AT := Vector2i(22, 12)

var root: Node2D
var mondo: Node2D
var decori: Node2D


func _ready() -> void:
	var ts := _tileset()
	root = Node2D.new()
	root.name = "Citta"
	root.set_script(load("res://chapters/c5/citta_c5.gd"))
	root.set("room_floor", "0")
	root.set("room_music", "citta")
	var pav := TileMapLayer.new()
	pav.name = "Pavimento"
	pav.tile_set = ts
	_add(root, pav)
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if y in ROAD_ROWS:
				var bus := c - BUS_AT
				if bus.x >= 0 and bus.x < 7 and bus.y >= 0 and bus.y < 2:
					pav.set_cell(c, 0, Vector2i(14 + bus.x, bus.y))
				else:
					pav.set_cell(c, 0, Vector2i(1 + x % 3, 4 + y % 3))
			elif GRASS.has_point(c):
				var gx := 0 if x == GRASS.position.x else (2 if x == GRASS.end.x - 1 else 1)
				var gy := 6 if y == GRASS.position.y else (8 if y == GRASS.end.y - 1 else 7)
				pav.set_cell(c, 1, Vector2i(gx, gy))
			else:
				pav.set_cell(c, 0, Vector2i(9 + x % 4, y % 4))
	decori = Node2D.new()
	decori.name = "Decori"
	_add(root, decori)
	var sky := _sprite(decori, "Cielo", ART + "cielo.png", Rect2(), Vector2i(0, -1))
	sky.scale = Vector2(W * T / 640.0, 1.0)
	sky.z_index = -1
	mondo = Node2D.new()
	mondo.name = "Mondo"
	mondo.y_sort_enabled = true
	_add(root, mondo)
	_torre()
	_casa_comune()
	_comunicazioni()
	_bottega()
	_piazza()
	_features()
	_bordi()
	var arrivi := Node2D.new()
	arrivi.name = "Arrivi"
	_add(root, arrivi)
	_arrival(arrivi, "default", Vector2i(3, 11), "down")
	_arrival(arrivi, "from_below", Vector2i(3, 10), "down")
	_arrival(arrivi, "from_casa", Vector2i(17, 10), "down")
	for n in root.find_children("*", "CharSprite", true, false):
		(n as CharSprite).sprite_frames = null
		(n as CharSprite).material = null
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		DirAccess.make_dir_recursive_absolute("res://chapters/c5")
		err = ResourceSaver.save(packed, OUT)
	print("BAKE ", OUT, " -> ", error_string(err))
	get_tree().quit()


# --- le facciate ---------------------------------------------------------------------------

## La Torre: la porta di vetro (verso la Banca), lo sportello di Nives, la scala esterna.
func _torre() -> void:
	_sprite(decori, "Torre", L + "buildings/cheap_tower.png", Rect2(), Vector2i(-5, 9))
	var sign := _sprite(decori, "InsegnaEsterno", ART + "insegna_esterno.png", Rect2(), Vector2i(0, 7), 0, Vector2(0, 0))
	sign.z_index = 2
	var door := _sprite(decori, "PortaVetro", ART + "porta_vetro.png", Rect2(), Vector2i(2, 9))
	door.z_index = 1
	_examine(mondo, "GuardaInsegna", Vector2i(1, 10), [], "_insegna_esterno")
	_solid("Torre", Rect2i(0, 0, 14, 7))
	_solid("TorreSinistra", Rect2i(0, 7, 2, 3))
	_solid("SopraPorta", Rect2i(2, 7, 2, 2))
	_solid("TorreNives", Rect2i(4, 7, 5, 3))
	_solid("TorreDestra", Rect2i(11, 7, 3, 3))
	_solid("SopraScala", Rect2i(9, 6, 2, 1))
	var lamp := _sprite(mondo, "Lampione", L + "street/lamp.png", Rect2(), Vector2i(12, 11), 6)
	var speaker := _sprite(lamp, "Altoparlante", ART + "altoparlante.png", Rect2(), Vector2i.ZERO, 0, Vector2(18, -60))
	speaker.position = Vector2(18, -50)
	_examine(mondo, "GuardaAltoparlante", Vector2i(12, 11), [], "_altoparlante")


## La Casa Comune: la porta in mezzo porta dentro (la stanza la aggiunge in citta_c5.gd).
func _casa_comune() -> void:
	_sprite(decori, "CasaComune", L + "buildings/condo_yellow.png", Rect2(), Vector2i(14, 9))
	var sign := _sprite(decori, "InsegnaCasaComune", ART + "insegna_casa_comune.png", Rect2(), Vector2i(14, 5), 0, Vector2(8, 0))
	sign.z_index = 2
	var notice := _sprite(decori, "AvvisoChiusura", ART + "avviso_chiusura.png", Rect2(), Vector2i(18, 8), 0, Vector2(0, 6))
	notice.z_index = 2
	var fl := _sprite(decori, "Volantini", ART + "volantini.png", Rect2(), Vector2i(14, 8), 0, Vector2(4, 6))
	fl.z_index = 2
	_examine(mondo, "GuardaAvviso", Vector2i(18, 10), [], "_avviso")
	_examine(mondo, "GuardaVolantini", Vector2i(14, 10), [], "_volantini")
	_solid("CasaComune", Rect2i(14, 0, 6, 9))
	_solid("CasaSinistra", Rect2i(14, 9, 2, 1))
	_solid("CasaDestra", Rect2i(18, 9, 2, 1))


## L'Ufficio Comunicazioni: il TURNO davanti alla porta, il terminale delle presentazioni accanto.
func _comunicazioni() -> void:
	_sprite(decori, "Comunicazioni", L + "buildings/condo_blue.png", Rect2(), Vector2i(21, 9))
	var sign := _sprite(decori, "InsegnaComunicazioni", ART + "insegna_comunicazioni.png", Rect2(), Vector2i(21, 5), 0, Vector2(8, 0))
	sign.z_index = 2
	_solid("Comunicazioni", Rect2i(21, 0, 6, 10))
	_sprite(mondo, "TerminalePresentazioni", ART + "terminale_presentazioni.png", Rect2(), Vector2i(26, 11), 8)
	_examine(mondo, "UsaTerminalePresentazioni", Vector2i(26, 11), [], "_presentazioni")
	# il cartellone CHEAP, sul palo, fra l'ufficio e la bottega
	_sprite(decori, "Cartellone", L + "street/billboard.png", Rect2(), Vector2i(27, 9))
	var ad := _sprite(decori, "CartellonePremium", ART + "cartellone_premium.png", Rect2(), Vector2i(27, 6), 0, Vector2(4, 8))
	ad.z_index = 2
	_examine(mondo, "GuardaCartellone", Vector2i(29, 10), [], "_cartellone")
	_solid("DietroCartellone", Rect2i(27, 0, 5, 9))
	_solid("PaloCartellone", Rect2i(29, 9, 1, 1))
	_solid("Vicolo", Rect2i(20, 0, 1, 10))
	_solid("Vicolo2", Rect2i(32, 0, 1, 10))


## La bottega di Rina: due vetrine, una intera e una già rotta.
func _bottega() -> void:
	_sprite(decori, "Bottega", L + "market/shop_big.png", Rect2(), Vector2i(33, 9))
	_solid("Bottega", Rect2i(33, 0, 7, 10))
	_examine(mondo, "GuardaVetrina", Vector2i(34, 10), [], "_vetrina")
	_examine(mondo, "GuardaVetrinaRotta", Vector2i(38, 10), [], "_vetrina_rotta")
	var old := _sprite(decori, "VetrinaGiaRotta", ART + "vetrina_rotta.png", Rect2(), Vector2i(37, 9), 0, Vector2(0, -2))
	old.z_index = 2
	old.modulate.a = 0.7
	_sprite(mondo, "AlberoFondo", L + "street/tree.png", Rect2(), Vector2i(40, 9), 6)
	_solid("FondoDestra", Rect2i(40, 0, 2, 9))
	_npc("Rina", "rina", "idle_down", Vector2i(31, 11))


# --- la piazza --------------------------------------------------------------------------------

func _piazza() -> void:
	_sprite(mondo, "Albero", L + "street/tree_round.png", Rect2(), Vector2i(3, 17), 8)
	_examine(mondo, "GuardaAlbero", Vector2i(3, 18), [], "_albero")
	_sprite(mondo, "Panchina", L + "street/bench.png", Rect2(), Vector2i(6, 18), 8)
	_examine(mondo, "GuardaPanchina", Vector2i(6, 18), [], "_panchina")
	for p: Array in [["Cespuglio0", Vector2i(1, 15)], ["Cespuglio1", Vector2i(8, 19)], ["Cespuglio2", Vector2i(8, 15)]]:
		_sprite(mondo, p[0], L + "park/bush.png", Rect2(), p[1], 6)
	_sprite(mondo, "Fiori", L + "street/flowers.png", Rect2(), Vector2i(4, 15))
	_sprite(mondo, "Fontana", L + "park/fountain.png", Rect2(), Vector2i(18, 18), 14)
	_examine(mondo, "GuardaFontana", Vector2i(18, 19), [
		"* Una fontana. L'acqua è gratis. Sul bordo, un adesivo: \"ACQUA PREMIUM: PROSSIMAMENTE\".",
	], "", ["* La fontana va ancora. Per ora nessuno l'ha messa in abbonamento."])
	_sprite(mondo, "Tabellone", ART + "tabellone_bus.png", Rect2(), Vector2i(21, 15), 6)
	_examine(mondo, "GuardaTabellone", Vector2i(22, 15), [], "_tabellone")
	_sprite(mondo, "Cestino", L + "street/trashbin.png", Rect2(), Vector2i(19, 15), 6)
	_sprite(mondo, "Idrante", L + "street/hydrant.png", Rect2(), Vector2i(33, 15), 6)
	_npc("Nadir", "nadir", "idle_left", Vector2i(24, 15))


func _features() -> void:
	_feature("PostoTurno", "station", Vector2i(23, 10), {"job": "comunicazioni_citta"})
	_feature("SportelloBadge", "badge", Vector2i(6, 9))
	# la scala esterna della Torre porta alla Cima: in cima la stanza fa lo sguardo indietro
	_feature("ScaleSu", "stairs_up", Vector2i(9, 9), {"target": "res://scenes/world/boss_office.tscn", "spawn": "default", "need": "cima"})
	_feature("Stellina", "save", Vector2i(13, 16))


## La piazza finisce dove finisce lo schermo: muri invisibili ai bordi.
func _bordi() -> void:
	_solid("BordoSinistro", Rect2i(-1, 0, 1, H))
	_solid("BordoDestro", Rect2i(W, 0, 1, H))
	_solid("BordoSotto", Rect2i(0, H, W, 1))


func _add(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root


# --- il TileSet della Città: marciapiede, asfalto, erba (fogli LimeZu) ---------------------------

func _tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	for path: String in [CITY_TILES, TERRAINS]:
		var s := TileSetAtlasSource.new()
		s.texture = load(path)
		s.texture_region_size = Vector2i(T, T)
		ts.add_source(s)
	var city := ts.get_source(0) as TileSetAtlasSource
	var cells: Array[Vector2i] = []
	for y in 4:
		for x in 4:
			cells.append(Vector2i(9 + x, y))
	for y in 3:
		for x in 3:
			cells.append(Vector2i(1 + x, 4 + y))
	for y in 2:
		for x in 7:
			cells.append(Vector2i(14 + x, y))
	for c in cells:
		city.create_tile(c)
	var grass := ts.get_source(1) as TileSetAtlasSource
	for y in 3:
		for x in 3:
			grass.create_tile(Vector2i(x, 6 + y))
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
		e.after_flag = "c5_rivelazione"
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


func _npc(nm: String, id: String, activity: String, cell: Vector2i) -> void:
	var n := NpcSpot.new()
	n.name = nm
	n.npc_id = id
	n.activity = activity
	n.position = Vector2(cell.x * T + 8, (cell.y + 1) * T - 2)
	_add(mondo, n)


func _feature(nm: String, kind: String, cell: Vector2i, props := {}) -> void:
	var f := RoomFeature.new()
	f.name = nm
	f.kind = kind
	f.position = Vector2(cell * T)
	for k: String in props:
		f.set(k, props[k])
	_add(mondo, f)


func _arrival(parent: Node, nm: String, cell: Vector2i, facing: String) -> void:
	var m := Marker2D.new()
	m.name = nm
	m.position = Vector2(cell.x * T + T / 2.0, (cell.y + 1) * T - 2)
	m.set_meta("facing", facing)
	_add(parent, m)
