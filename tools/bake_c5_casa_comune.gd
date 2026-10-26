extends Node
## Costruisce UNA VOLTA l'interno della Casa Comune (capitolo 5) e lo salva come scena vera
## in res://chapters/c5/casa_comune.tscn. Da lì in poi la scena si modifica nell'editor di Godot.
## Esegui:  Godot --headless --path . res://tools/bake_c5_casa_comune.tscn
##
##   a sinistra   la sala: librerie, tavoli, sedie spaiate, la bacheca, Ada
##   a destra     l'archivio (chiuso fino alla manifestazione): il terminale dei bilanci,
##                l'armadio dei documenti, il contatore della rete della Torre
## Si esce dal basso, a sinistra, verso la piazza. Pavimento e muri dal TileSet degli interni
## (le stesse tessere del Mercato: legno e muro chiaro).

const T := 16
const W := 22
const H := 13
const TILESET_PATH := "res://world/tilesets/interni.tres"
const OUT := "res://chapters/c5/casa_comune.tscn"
const PROPS := "res://assets/limezu/props/"
const ART := "res://art/c5/"
const GENERIC := "res://assets/limezu/tiles/generic.png"
const RUG := Rect2(48, 354, 32, 28)
const WOOD := Vector2i(34, 33)
const WALL := Vector2i(29, 25)
const BORDER := Vector2i(12, 0)
## La parete fra la sala e l'archivio (con la porta a ARCHIVE_DOOR).
const WALL_X := 14
const ARCHIVE_DOOR := Vector2i(14, 7)

var root: Node2D
var mondo: Node2D
var decori: Node2D


func _ready() -> void:
	var ts: TileSet = load(TILESET_PATH)
	root = Node2D.new()
	root.name = "CasaComune"
	root.set_script(load("res://chapters/c5/casa_comune_c5.gd"))
	root.set("room_floor", "0")
	root.set("room_music", "quartiere")
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
			elif x == WALL_X and c != ARCHIVE_DOOR:
				muri.set_cell(c, 0, BORDER)
			else:
				pav.set_cell(c, 0, WOOD + Vector2i(x % 3, y % 2))
	decori = Node2D.new()
	decori.name = "Decori"
	_add(root, decori)
	mondo = Node2D.new()
	mondo.name = "Mondo"
	mondo.y_sort_enabled = true
	_add(root, mondo)
	_sala()
	_archivio()
	var arrivi := Node2D.new()
	arrivi.name = "Arrivi"
	_add(root, arrivi)
	_arrival(arrivi, "default", Vector2i(3, 9), "up")
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


## La sala: si studia, si cerca lavoro, ci si incontra. Le sedie non sono mai due uguali.
func _sala() -> void:
	_sprite(mondo, "Libreria", ART + "libreria.png", Rect2(), Vector2i(5, 4), 14)
	_sprite(mondo, "Libreria2", ART + "libreria.png", Rect2(), Vector2i(8, 4), 14)
	_examine(mondo, "GuardaLibreria", Vector2i(8, 4), [
		"* Una libreria piena. Sul dorso dei libri, a pennarello: \"PRESTITO LIBERO. RESTITUZIONE: QUANDO PUOI\".",
	])
	var notice := _sprite(decori, "AvvisoChiusura", ART + "avviso_chiusura.png", Rect2(), Vector2i(2, 2), 0, Vector2(0, -2))
	notice.z_index = 1
	_examine(mondo, "GuardaAvviso", Vector2i(2, 3), [], "_avviso")
	var board := _sprite(decori, "Bacheca", ART + "bacheca.png", Rect2(), Vector2i(10, 2), 0, Vector2(0, -2))
	board.z_index = 1
	_examine(mondo, "GuardaBacheca", Vector2i(11, 3), [], "_bacheca")
	_sprite(mondo, "Tavolo", ART + "tavolo_lungo.png", Rect2(), Vector2i(3, 8), 14)
	_sprite(mondo, "Sedie", ART + "sedie_spaiate.png", Rect2(), Vector2i(3, 9), 6)
	_sprite(mondo, "Tavolo2", ART + "tavolo_lungo.png", Rect2(), Vector2i(8, 8), 14)
	var letter := _sprite(mondo, "LetteraCheap", ART + "lettera_cheap.png", Rect2(), Vector2i(9, 8), 0, Vector2(3, -12))
	letter.z_index = 1
	_examine(mondo, "LeggiLettera", Vector2i(9, 8), [], "_lettera")
	_sprite(mondo, "Sedie2", ART + "sedie_spaiate.png", Rect2(), Vector2i(8, 9), 6)
	_sprite(mondo, "Cassettiera", PROPS + "dresser.png", Rect2(), Vector2i(11, 4), 14)
	var folder := _sprite(mondo, "CartellaB4", ART + "cartella_b4.png", Rect2(), Vector2i(11, 4), 0, Vector2(10, -30))
	folder.z_index = 1
	_examine(mondo, "GuardaCartella", Vector2i(12, 4), [], "_cartella_b4")
	_sprite(mondo, "Pianta0", PROPS + "plant.png", Rect2(), Vector2i(1, 3), 8)
	_sprite(mondo, "Pianta1", PROPS + "plant.png", Rect2(), Vector2i(13, 3), 8)
	_sprite(mondo, "Scatoloni", PROPS + "boxes.png", Rect2(), Vector2i(11, 10), 12)
	_examine(mondo, "GuardaScatoloni", Vector2i(11, 10), [
		"* Scatoloni con scritto \"TRASLOCO?\". Il punto interrogativo è stato aggiunto dopo, con un'altra penna.",
	])
	_npc("Ada", "ada", "idle_up", Vector2i(6, 5))
	# lo zerbino: da qui si esce in piazza
	_sprite(decori, "Zerbino", GENERIC, RUG, Vector2i(3, 11), 0, Vector2(0, 4))


## L'archivio: la porta resta chiusa fino alla manifestazione (vedi casa_comune_c5.gd).
func _archivio() -> void:
	_sprite(mondo, "PortaArchivio", ART + "porta_archivio.png", Rect2(), ARCHIVE_DOOR, 16)
	_examine(mondo, "BussaArchivio", ARCHIVE_DOOR + Vector2i(-1, 0), [], "_porta_archivio")
	_sprite(mondo, "TerminaleBilanci", ART + "terminale_bilanci.png", Rect2(), Vector2i(17, 4), 8)
	_examine(mondo, "UsaTerminaleBilanci", Vector2i(17, 4), [], "_bilanci")
	_sprite(mondo, "Armadio", ART + "armadio_documenti.png", Rect2(), Vector2i(19, 4), 12)
	_examine(mondo, "GuardaArmadio", Vector2i(19, 4), [], "_armadio")
	var meter := _sprite(decori, "Contatore", ART + "contatore.png", Rect2(), Vector2i(15, 2), 0, Vector2(0, 4))
	meter.z_index = 1
	_examine(mondo, "GuardaContatore", Vector2i(15, 3), [], "_contatore")
	_sprite(mondo, "PiantaArchivio", PROPS + "plant.png", Rect2(), Vector2i(20, 10), 8)


func _add(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root


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


func _examine(parent: Node, nm: String, cell: Vector2i, lines: Array, method := "") -> void:
	var e := Examine.new()
	e.name = nm
	e.position = Vector2(cell.x * T + 8, cell.y * T + 8)
	e.lines = PackedStringArray(lines)
	e.method = method
	_add(parent, e)


func _npc(nm: String, id: String, activity: String, cell: Vector2i) -> void:
	var n := NpcSpot.new()
	n.name = nm
	n.npc_id = id
	n.activity = activity
	n.position = Vector2(cell.x * T + 8, (cell.y + 1) * T - 2)
	_add(mondo, n)


func _arrival(parent: Node, nm: String, cell: Vector2i, facing: String) -> void:
	var m := Marker2D.new()
	m.name = nm
	m.position = Vector2(cell.x * T + T / 2.0, (cell.y + 1) * T - 2)
	m.set_meta("facing", facing)
	_add(parent, m)
