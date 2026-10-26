extends Node
## Costruisce UNA VOLTA la scena della Banca (capitolo 4) e la salva come scena vera
## in res://chapters/c4/banca.tscn. Da lì in poi la scena si modifica nell'editor di Godot:
## questo script serve solo a creare la prima versione (non rilanciarlo, o sovrascrive le modifiche).
## Esegui:  Godot --headless --path . res://tools/bake_c4_banca.tscn
##
## Una banca piccola, da leggere su un telefono:
##   in basso a sinistra  le scale dal Mercato (l'ingresso) e il distributore dei numeri
##   a sinistra           la sala d'attesa (panche, Olga)
##   al centro            l'atrio: tappeti rossi, la fila grigia, lo sportello del TURNO
##   in alto              l'insegna, il display dei numeri, il terminale del conto
##   a destra             la scrivania e l'archivio di Teo (il rapporto 404)
##   in alto a destra     lo sportello di Nives e le scale per il Piano Terra
## La grafica fatta apposta è ancora SEGNAPOSTO (art/c4/, vedi docs/ASSET_LIST.md).

const T := 16
const W := 22
const H := 14
const TILESET_PATH := "res://world/tilesets/interni.tres"
const OUT := "res://chapters/c4/banca.tscn"
const PROPS := "res://assets/limezu/props/"
const GENERIC := "res://assets/limezu/tiles/generic.png"
const ART := "res://art/c4/"

## Le piastrelle (motivi da 3x2 in room_builder): marmo chiaro nell'atrio, piastrelle azzurrine
## nell'ufficio di Teo, muro rosso scuro da banca.
const MARBLE := Vector2i(38, 39)
const OFFICE := Vector2i(46, 41)
const WALL := Vector2i(29, 13)
const BORDER := Vector2i(12, 0)
const AFTER := "c4_rivelazione"
const TEO_AREA := Rect2i(14, 6, 7, 5)
## Dal foglio generic.png di LimeZu: tappeto rosso, panca, pianta in vaso.
const RUG := Rect2(48, 354, 32, 28)
const BENCH := Rect2(1, 254, 30, 18)
const POT := Rect2(212, 408, 23, 31)

var root: Node2D
var mondo: Node2D
var decori: Node2D


func _ready() -> void:
	var ts := _tileset()
	root = Node2D.new()
	root.name = "Banca"
	root.set_script(load("res://chapters/c4/banca_c4.gd"))
	root.set("room_floor", "-2")
	root.set("room_music", "banca")
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
				var base := OFFICE if TEO_AREA.has_point(c) else MARBLE
				pav.set_cell(c, 0, base + Vector2i(x % 3, y % 2))
	decori = Node2D.new()
	decori.name = "Decori"
	_add(root, decori)
	mondo = Node2D.new()
	mondo.name = "Mondo"
	mondo.y_sort_enabled = true
	_add(root, mondo)
	_insegne()
	_atrio()
	_attesa()
	_teo()
	_features()
	var arrivi := Node2D.new()
	arrivi.name = "Arrivi"
	_add(root, arrivi)
	_arrival(arrivi, "default", Vector2i(6, 10), "up")
	for n in root.find_children("*", "CharSprite", true, false):
		(n as CharSprite).sprite_frames = null
		(n as CharSprite).material = null
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		DirAccess.make_dir_recursive_absolute("res://chapters/c4")
		err = ResourceSaver.save(packed, OUT)
	print("BAKE ", OUT, " -> ", error_string(err))
	get_tree().quit()


# --- la Banca: marmo, oro, tappeti rossi, persone grigie in fila ------------------------

func _insegne() -> void:
	var sign := _sprite(decori, "InsegnaBanca", ART + "insegna_banca.png", Rect2(), Vector2i(2, 1), 0, Vector2(0, 12))
	sign.z_index = 1
	var display := _sprite(decori, "DisplayNumeri", ART + "display_numeri.png", Rect2(), Vector2i(12, 1), 0, Vector2(0, 10))
	display.z_index = 1
	_examine(mondo, "GuardaInsegna", Vector2i(5, 3), [], "_insegna")
	_examine(mondo, "GuardaDisplay", Vector2i(13, 3), [], "_display")


## L'atrio: lo sportello del TURNO tra due colonne d'oro, la fila, i tappeti rossi.
func _atrio() -> void:
	for i in 3:
		_sprite(decori, "Tappeto%d" % i, GENERIC, RUG, Vector2i(8, 6 + i * 2), 0, Vector2(0, 4))
	_sprite(mondo, "Bancone", ART + "bancone_sportello.png", Rect2(), Vector2i(8, 3), 10)
	_sprite(mondo, "ColonnaSinistra", ART + "colonna_oro.png", Rect2(), Vector2i(7, 3), 6)
	_sprite(mondo, "ColonnaDestra", ART + "colonna_oro.png", Rect2(), Vector2i(12, 3), 6)
	_examine(mondo, "GuardaBancone", Vector2i(8, 3), [
		"* Lo sportello del settore fiducia. Sul vetro, un adesivo: \"SORRIDI, STAI PER ESSERE VALUTATO\".",
	], "", ["* Lo sportello. Il timbro APPROVATA è consumato da un lato solo."])
	_sprite(mondo, "Distributore", ART + "distributore_numeri.png", Rect2(), Vector2i(5, 9), 8)
	_examine(mondo, "UsaDistributore", Vector2i(5, 9), [], "_distributore")
	_sprite(mondo, "TerminaleConto", ART + "terminale_conto.png", Rect2(), Vector2i(14, 4), 8)
	_examine(mondo, "UsaTerminaleConto", Vector2i(14, 4), [], "_conto")
	_sprite(mondo, "Pianta0", GENERIC, POT, Vector2i(1, 4), 8)
	_sprite(mondo, "Pianta1", GENERIC, POT, Vector2i(13, 11), 8)
	# la fila: persone grigie, una dietro l'altra, verso lo sportello
	var queue := [
		["Fila0", "char_13", ["* \"Sono il numero 5. Ero il numero 5 anche l'anno scorso.\""]],
		["Fila1", "char_18", ["* \"Mi hanno detto di aspettare. Sono bravissimo ad aspettare. È l'unica cosa in cui sono migliorato.\""]],
		["Fila2", "char_20", ["* Tiene stretto un biglietto. Il numero è stato stampato così tante volte che si è consumato."]],
		["Fila3", "char_05", ["* \"Non so cosa devo chiedere. Lo saprò quando tocca a me. Se tocca a me.\""]],
	]
	for i in queue.size():
		var c: Array = queue[i]
		var cell := Vector2i(11, 4 + i)
		var p := _person(c[0], c[1], "idle_up", cell)
		p.grey = true
		_examine(mondo, "Guarda" + c[0], cell, c[2], "", ["* È ancora in fila. La fila non ha sentito niente."])
		_solid("Piedi" + c[0], Rect2i(cell, Vector2i.ONE))


## La sala d'attesa: due panche, Olga e la sua borsa di ricevute.
func _attesa() -> void:
	for i in 2:
		_sprite(mondo, "Panca%d" % i, GENERIC, BENCH, Vector2i(1 + i * 2, 6), 6)
	_examine(mondo, "GuardaPanche", Vector2i(2, 6), [
		"* Panche di velluto rosso. Sul bracciolo, inciso con una chiave: \"MARTEDÌ\".",
	])
	_npc("Olga", "olga", "idle_left", Vector2i(5, 7))


## La scrivania di Teo, il suo quaderno, l'archivio e il terminale del rapporto 404.
func _teo() -> void:
	_sprite(mondo, "ScrivaniaTeo", PROPS + "office_desk.png", Rect2(), Vector2i(17, 7), 10)
	var nb := _sprite(mondo, "Quaderno", ART + "quaderno.png", Rect2(), Vector2i(17, 7), 0, Vector2(3, -14))
	nb.z_index = 1
	_examine(mondo, "GuardaQuaderno", Vector2i(17, 7), [], "_quaderno")
	_sprite(mondo, "Archivio", ART + "archivio.png", Rect2(), Vector2i(19, 7), 10)
	_examine(mondo, "GuardaArchivio", Vector2i(19, 7), [], "_archivio")
	_sprite(mondo, "TerminaleRapporto", ART + "terminale_rapporto.png", Rect2(), Vector2i(20, 9), 8)
	_examine(mondo, "UsaTerminaleRapporto", Vector2i(20, 9), [], "_rapporto")
	_npc("Teo", "teo", "idle_right", Vector2i(16, 7))



func _add(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root


# --- il TileSet condiviso: aggiunge piastrelle e muro della Banca ------------------

func _tileset() -> TileSet:
	var ts: TileSet = load(TILESET_PATH)
	var s := ts.get_source(0) as TileSetAtlasSource
	var solid := [BORDER]
	var floors := []
	for dy in 2:
		for dx in 3:
			solid.append(WALL + Vector2i(dx, dy))
			for f in [MARBLE, OFFICE]:
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



func _feature(nm: String, kind: String, cell: Vector2i, props := {}) -> void:
	var f := RoomFeature.new()
	f.name = nm
	f.kind = kind
	f.position = Vector2(cell * T)
	for k: String in props:
		f.set(k, props[k])
	_add(mondo, f)


func _features() -> void:
	_feature("PostoSportello", "station", Vector2i(9, 4), {"job": "sportello_banca"})
	_feature("SportelloBadge", "badge", Vector2i(16, 3))
	# le scale portano al Piano Terra: la stanza sceglie la scena vera (vedi banca_c4.gd, next_scene)
	_feature("ScaleSu", "stairs_up", Vector2i(19, 3), {"target": "res://scenes/world/office.tscn", "spawn": "from_below", "need": "0"})
	_feature("ScaleGiu", "stairs_down", Vector2i(2, 12), {"target": "res://chapters/c3/mercato.tscn", "spawn": "from_above"})
	_feature("Stellina", "save", Vector2i(7, 11))


func _arrival(parent: Node, nm: String, cell: Vector2i, facing: String) -> void:
	var m := Marker2D.new()
	m.name = nm
	m.position = Vector2(cell.x * T + T / 2.0, (cell.y + 1) * T - 2)
	m.set_meta("facing", facing)
	_add(parent, m)
