extends Node
## Costruisce la scena della Banca (capitolo 4) e la salva come scena vera in res://chapters/c4/banca.tscn.
## Da lì in poi la scena si può modificare nell'editor di Godot (rilanciare lo script la sovrascrive).
## Esegui:  Godot --headless --path . res://tools/bake_c4_banca.tscn
##
## Quattro stanze sullo stesso piano, col bordo bianco come nelle mappe di LimeZu (RoomOutline):
##   la sala d'attesa  (a sinistra): divani, file di sedie, il tavolino, la TV, il distributore. Olga.
##   l'atrio           (al centro): l'insegna, il display dei numeri, gli sportelli (il primo è il TURNO),
##                     la fila grigia, i cordoni rossi, il distributore dei numeri, le scale dal Mercato
##   l'ufficio badge   (in alto a destra): lo sportello di Nives e le scale per il Piano Terra
##   l'ufficio di Teo  (in basso a destra): la scrivania, il quaderno, le librerie, il leggio, il rapporto 404
## La mappa si legge in ROWS: # vuoto, maiuscola parete, minuscola pavimento (una lettera per stanza).
## La grafica fatta apposta (insegna, display, terminali, quaderno) è ancora SEGNAPOSTO (art/c4/).

const T := 16
const TILESET_PATH := "res://world/tilesets/interni.tres"
const OUT := "res://chapters/c4/banca.tscn"
const PROPS := "res://assets/limezu/props/"
const GROCERY := "res://assets/limezu/grocery/"
const GENERIC := "res://assets/limezu/tiles/generic.png"
const HOSPITAL := "res://assets/limezu/themes/hospital.png"
const LIVING := "res://assets/limezu/themes/living_room.png"
const CLASSROOM := "res://assets/limezu/themes/classroom.png"
const ART := "res://art/c4/"
const AFTER := "c4_rivelazione"

const VOID := Vector2i(12, 0)
const WALLS := {"A": Vector2i(22, 39), "B": Vector2i(22, 35), "N": Vector2i(22, 41), "T": Vector2i(0, 33)}
const FLOORS := {"a": Vector2i(38, 11), "b": Vector2i(38, 39), "n": Vector2i(34, 11), "t": Vector2i(34, 21)}

## I pezzi presi dai fogli dei temi (in pixel).
const DESK := Rect2(80, 0, 64, 48)          # bancone della reception (ospedale), col monitor
const ROPE := Rect2(208, 368, 48, 16)       # cordone rosso tra colonnine dorate
const VENDING := Rect2(192, 192, 32, 48)    # distributore di merendine
const TV := Rect2(176, 240, 32, 24)         # la TV appesa
const BOARD := Rect2(32, 0, 32, 32)         # bacheca con i fogli
const SOFA := Rect2(16, 448, 48, 32)        # divano grigio (soggiorno)
const TABLE := Rect2(80, 96, 48, 32)        # tavolino basso
const RUG := Rect2(144, 64, 64, 48)         # tappeto rosso e oro
const RUG_SMALL := Rect2(144, 160, 32, 32)  # tappetino
const BOOKCASE := Rect2(0, 208, 48, 48)     # libreria (biblioteca)
const LECTERN := Rect2(224, 232, 32, 40)    # il leggio col libro aperto
const CHAIRS := [Rect2(160, 304, 16, 16), Rect2(160, 336, 16, 16), Rect2(192, 304, 16, 16), Rect2(160, 208, 16, 16)]

const ROWS := [
	"########################################",
	"#AAAAAAAAAA#BBBBBBBBBBBBBBBB#NNNNNNNNNN#",
	"#AAAAAAAAAA#BBBBBBBBBBBBBBBB#NNNNNNNNNN#",
	"#aaaaaaaaaa#bbbbbbbbbbbbbbbb#nnnnnnnnnn#",
	"#aaaaaaaaaa#bbbbbbbbbbbbbbbbnnnnnnnnnnn#",
	"#aaaaaaaaaa#bbbbbbbbbbbbbbbbnnnnnnnnnnn#",
	"#aaaaaaaaaa#bbbbbbbbbbbbbbbb#nnnnnnnnnn#",
	"#aaaaaaaaaa#bbbbbbbbbbbbbbbb############",
	"#aaaaaaaaaa#bbbbbbbbbbbbbbbb#TTTTTTTTTT#",
	"#aaaaaaaaaa#bbbbbbbbbbbbbbbb#TTTTTTTTTT#",
	"#aaaaaaaaaa#bbbbbbbbbbbbbbbb#tttttttttt#",
	"#aaaaaaaaaaabbbbbbbbbbbbbbbb#tttttttttt#",
	"#aaaaaaaaaaabbbbbbbbbbbbbbbbttttttttttt#",
	"#aaaaaaaaaa#bbbbbbbbbbbbbbbbttttttttttt#",
	"#aaaaaaaaaa#bbbbbbbbbbbbbbbb#tttttttttt#",
	"#aaaaaaaaaa#bbbbbbbbbbbbbbbb#tttttttttt#",
	"########################################",
]

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
	for y in ROWS.size():
		var row: String = ROWS[y]
		for x in row.length():
			var c := Vector2i(x, y)
			var ch := row[x]
			if ch == "#":
				muri.set_cell(c, 0, VOID)
			elif WALLS.has(ch):
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
	_atrio()
	_attesa()
	_ufficio()
	_teo()
	_features()
	var arrivi := Node2D.new()
	arrivi.name = "Arrivi"
	_add(root, arrivi)
	_arrival(arrivi, "default", Vector2i(19, 12), "up")
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


func _add(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root


# --- il TileSet condiviso: aggiunge pareti e pavimenti della Banca ------------------

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


## Un pezzo preso da un foglio dei temi (una regione in pixel).
func _r(parent: Node, nm: String, tex: String, region: Rect2, cell: Vector2i, foot := 0, nudge := Vector2.ZERO) -> Sprite2D:
	return _sprite(parent, nm, tex, region, cell, foot, nudge)


# --- la Banca: marmo, oro, cordoni rossi, persone grigie in fila ------------------------

func _insegne() -> void:
	var sign := _sprite(decori, "InsegnaBanca", ART + "insegna_banca.png", Rect2(), Vector2i(13, 1), 0, Vector2(0, 12))
	sign.z_index = 1
	var display := _sprite(decori, "DisplayNumeri", ART + "display_numeri.png", Rect2(), Vector2i(22, 1), 0, Vector2(0, 10))
	display.z_index = 1
	_examine(mondo, "GuardaInsegna", Vector2i(18, 3), [], "_insegna")
	_examine(mondo, "GuardaDisplay", Vector2i(24, 3), [], "_display")


## L'atrio: due sportelli (il primo è il tuo TURNO), la fila grigia, i cordoni, il distributore dei numeri.
func _atrio() -> void:
	_r(decori, "Tappeto", GENERIC, RUG, Vector2i(18, 15), 0, Vector2(0, -2))
	_r(mondo, "Bancone", HOSPITAL, DESK, Vector2i(13, 5), 12)
	_examine(mondo, "GuardaBancone", Vector2i(14, 5), [
		"* Lo sportello del settore fiducia. Sul vetro, un adesivo: \"SORRIDI, STAI PER ESSERE VALUTATO\".",
	], "", ["* Lo sportello. Il timbro APPROVATA è consumato da un lato solo."])
	_r(mondo, "Bancone2", HOSPITAL, DESK, Vector2i(20, 5), 12)
	# l'impiegata dello sportello accanto: è del sistema, quindi è colorata
	_person("Impiegata", "char_11", "idle_down", Vector2i(21, 4))
	_examine(mondo, "GuardaImpiegata", Vector2i(21, 5), [
		"* \"Questo sportello è chiuso. È chiuso da quando hanno aperto quello accanto.\"",
	])
	_solid("PiediImpiegata", Rect2i(21, 4, 2, 1))
	for i in 2:
		_r(mondo, "Cordone%d" % i, HOSPITAL, ROPE, Vector2i(17, 8 + i * 3), 4)
	_sprite(mondo, "Distributore", ART + "distributore_numeri.png", Rect2(), Vector2i(16, 13), 8)
	_examine(mondo, "UsaDistributore", Vector2i(16, 13), [], "_distributore")
	_sprite(mondo, "TerminaleConto", ART + "terminale_conto.png", Rect2(), Vector2i(26, 4), 8)
	_examine(mondo, "UsaTerminaleConto", Vector2i(26, 4), [], "_conto")
	_sprite(mondo, "Pianta0", GROCERY + "451.png", Rect2(), Vector2i(12, 4), 8)
	_sprite(mondo, "Pianta1", GROCERY + "449.png", Rect2(), Vector2i(27, 15), 8)
	# la fila: persone grigie, una dietro l'altra, verso il tuo sportello
	var queue := [
		["Fila0", "char_13", ["* \"Sono il numero 5. Ero il numero 5 anche l'anno scorso.\""]],
		["Fila1", "char_18", ["* \"Mi hanno detto di aspettare. Sono bravissimo ad aspettare. È l'unica cosa in cui sono migliorato.\""]],
		["Fila2", "char_20", ["* Tiene stretto un biglietto. Il numero è stato stampato così tante volte che si è consumato."]],
		["Fila3", "char_05", ["* \"Non so cosa devo chiedere. Lo saprò quando tocca a me. Se tocca a me.\""]],
	]
	for i in queue.size():
		var c: Array = queue[i]
		var cell := Vector2i(15, 6 + i)
		var p := _person(c[0], c[1], "idle_up", cell)
		p.grey = true
		_examine(mondo, "Guarda" + c[0], cell, c[2], "", ["* È ancora in fila. La fila non ha sentito niente."])
		_solid("Piedi" + c[0], Rect2i(cell, Vector2i.ONE))


## La sala d'attesa: due divani, il tavolino con le riviste, le file di sedie, la TV, Olga.
func _attesa() -> void:
	_r(decori, "TV", HOSPITAL, TV, Vector2i(5, 2), 0, Vector2(0, -4)).z_index = 1
	_r(mondo, "Divano0", LIVING, SOFA, Vector2i(1, 4), 10)
	_r(mondo, "Divano1", LIVING, SOFA, Vector2i(5, 4), 10)
	_r(mondo, "Merendine", HOSPITAL, VENDING, Vector2i(9, 4), 12)
	_examine(mondo, "GuardaMerendine", Vector2i(9, 4), [
		"* Merendine a 4 €. Sotto, piccolo: \"Il prezzo comprende la commissione di attesa\".",
	])
	_r(decori, "Tappetino", GENERIC, RUG_SMALL, Vector2i(3, 7), 0, Vector2(0, 4))
	_r(mondo, "Tavolino", GENERIC, TABLE, Vector2i(2, 7), 10)
	_examine(mondo, "GuardaTavolino", Vector2i(3, 7), [
		"* Riviste: \"Risparmiare con gioia\", \"Il tuo mutuo e te\". Sono di tre anni fa. Le copertine sorridono ancora.",
	])
	for row in 2:
		for i in 6:
			var x := 2 + i + (1 if i >= 3 else 0)
			_r(mondo, "Sedia%d_%d" % [row, i], HOSPITAL, CHAIRS[(i + row) % CHAIRS.size()], Vector2i(x, 10 + row * 3), 6)
	_examine(mondo, "GuardaPanche", Vector2i(3, 10), [
		"* Sedie di plastica, avvitate al pavimento. Sullo schienale, inciso con una chiave: \"MARTEDÌ\".",
	])
	_sprite(mondo, "PiantaAttesa", GROCERY + "450.png", Rect2(), Vector2i(1, 15), 8)
	_npc("Olga", "olga", "idle_left", Vector2i(8, 7))


## L'ufficio badge: la bacheca, una pianta. Lo sportello e le scale sono caratteristiche.
func _ufficio() -> void:
	_r(decori, "Bacheca", HOSPITAL, BOARD, Vector2i(30, 2), 0, Vector2(0, -2)).z_index = 1
	_sprite(mondo, "PiantaUfficio", GROCERY + "449.png", Rect2(), Vector2i(29, 6), 8)


## L'ufficio di Teo: le librerie, la scrivania col quaderno, il leggio, il terminale del rapporto 404.
func _teo() -> void:
	_r(mondo, "Archivio", CLASSROOM, BOOKCASE, Vector2i(32, 10), 12)
	_r(mondo, "Archivio2", CLASSROOM, BOOKCASE, Vector2i(35, 10), 12)
	_examine(mondo, "GuardaArchivio", Vector2i(33, 10), [], "_archivio")
	_r(decori, "TappetoTeo", GENERIC, RUG_SMALL, Vector2i(30, 14), 0, Vector2(0, 4))
	_sprite(mondo, "ScrivaniaTeo", PROPS + "office_desk.png", Rect2(), Vector2i(31, 13), 10)
	var nb := _sprite(mondo, "Quaderno", ART + "quaderno.png", Rect2(), Vector2i(31, 13), 0, Vector2(3, -14))
	nb.z_index = 1
	_examine(mondo, "GuardaQuaderno", Vector2i(31, 13), [], "_quaderno")
	_r(mondo, "Leggio", CLASSROOM, LECTERN, Vector2i(37, 13), 6)
	_examine(mondo, "GuardaLeggio", Vector2i(37, 13), [
		"* Un leggio con un libro aperto: \"Regolamento interno, vol. 7\". Qualcuno ha disegnato un mantello a un articolo.",
	])
	_sprite(mondo, "TerminaleRapporto", ART + "terminale_rapporto.png", Rect2(), Vector2i(38, 11), 8)
	_examine(mondo, "UsaTerminaleRapporto", Vector2i(38, 11), [], "_rapporto")
	_npc("Teo", "teo", "idle_right", Vector2i(30, 13))


func _feature(nm: String, kind: String, cell: Vector2i, props := {}) -> void:
	var f := RoomFeature.new()
	f.name = nm
	f.kind = kind
	f.position = Vector2(cell * T)
	for k: String in props:
		f.set(k, props[k])
	_add(mondo, f)


func _features() -> void:
	_feature("PostoSportello", "station", Vector2i(13, 6), {"job": "sportello_banca"})
	_feature("SportelloBadge", "badge", Vector2i(32, 3))
	# le scale per il Piano Terra (la Città)
	_feature("ScaleSu", "stairs_up", Vector2i(36, 3), {"target": "res://scenes/world/office.tscn", "spawn": "from_below", "need": "0"})
	_feature("ScaleGiu", "stairs_down", Vector2i(13, 15), {"target": "res://chapters/c3/mercato.tscn", "spawn": "from_above"})
	_feature("Stellina", "save", Vector2i(24, 13))


func _arrival(parent: Node, nm: String, cell: Vector2i, facing: String) -> void:
	var m := Marker2D.new()
	m.name = nm
	m.position = Vector2(cell.x * T + T / 2.0, (cell.y + 1) * T - 2)
	m.set_meta("facing", facing)
	_add(parent, m)
