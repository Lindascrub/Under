extends Node
## Costruisce UNA VOLTA la Cima (capitolo 6) e la salva come scena vera in res://chapters/c6/cima.tscn.
## Esegui:  Godot --headless --path . res://tools/bake_c6_cima.tscn
##
##   a sinistra   l'ascensore dorato (senza pulsanti): si arriva qui
##   in mezzo     il corridoio degli specchi (e la stellina)
##   a destra     l'ufficio della Presidente: enorme, colorato, quasi vuoto. La scrivania del TURNO,
##                il terminale dei bilanci, la finestra panoramica, l'archivio del debito, il tavolo
##                della decisione, la macchina del caffè
## Tessere dal TileSet degli interni (fogli LimeZu): ogni zona ha il suo pavimento e il suo muro.

const T := 16
const W := 32
const H := 14
const TILESET_PATH := "res://world/tilesets/interni.tres"
const OUT := "res://chapters/c6/cima.tscn"
const PROPS := "res://assets/limezu/props/"
const ART := "res://art/c6/"
const GENERIC := "res://assets/limezu/tiles/generic.png"
const RUG := Rect2(48, 354, 32, 28)
const POT := Rect2(212, 408, 23, 31)
const BORDER := Vector2i(12, 0)
## pavimenti: oro (ascensore), rosa (specchi), viola a disegni (ufficio)
const GOLD_FLOOR := Vector2i(34, 17)
const PINK_FLOOR := Vector2i(42, 17)
const PURPLE_FLOOR := Vector2i(42, 29)
## muri: corallo, azzurro, viola
const LIFT_WALL := Vector2i(29, 11)
const MIRROR_WALL := Vector2i(29, 19)
const OFFICE_WALL := Vector2i(29, 15)
const LIFT := Rect2i(1, 5, 4, 6)
const CORRIDOR := Rect2i(6, 6, 7, 4)
const OFFICE := Rect2i(14, 3, 17, 10)
const DOOR_ROWS := [7, 8]

var root: Node2D
var mondo: Node2D
var decori: Node2D


func _ready() -> void:
	var ts: TileSet = load(TILESET_PATH)
	var src := ts.get_source(0) as TileSetAtlasSource
	for base: Vector2i in [GOLD_FLOOR, PINK_FLOOR, PURPLE_FLOOR, LIFT_WALL, MIRROR_WALL, OFFICE_WALL]:
		for dx in 3:
			for dy in 2:
				var c := base + Vector2i(dx, dy)
				if not src.has_tile(c):
					src.create_tile(c)
	ResourceSaver.save(ts, TILESET_PATH)
	root = Node2D.new()
	root.name = "Cima"
	root.set_script(load("res://chapters/c6/cima_c6.gd"))
	root.set("room_floor", "cima")
	root.set("room_music", "cima")
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
			var zone := _zone(c)
			if zone == "":
				muri.set_cell(c, 0, BORDER)
				continue
			var wall_base: Vector2i = {"lift": LIFT_WALL, "corr": MIRROR_WALL, "office": OFFICE_WALL}[zone]
			var floor_base: Vector2i = {"lift": GOLD_FLOOR, "corr": PINK_FLOOR, "office": PURPLE_FLOOR}[zone]
			var rect: Rect2i = {"lift": LIFT, "corr": CORRIDOR, "office": OFFICE}[zone]
			# le due righe sopra ogni zona sono il suo muro
			if y < rect.position.y and y >= rect.position.y - 2:
				muri.set_cell(c, 0, wall_base + Vector2i(x % 3, y - (rect.position.y - 2)))
			else:
				pav.set_cell(c, 0, floor_base + Vector2i(x % 3, y % 2))
	decori = Node2D.new()
	decori.name = "Decori"
	_add(root, decori)
	mondo = Node2D.new()
	mondo.name = "Mondo"
	mondo.y_sort_enabled = true
	_add(root, mondo)
	_ascensore()
	_corridoio()
	_ufficio()
	var arrivi := Node2D.new()
	arrivi.name = "Arrivi"
	_add(root, arrivi)
	_arrival(arrivi, "default", Vector2i(2, 8), "right")
	_arrival(arrivi, "from_below", Vector2i(2, 8), "right")
	_arrival(arrivi, "desk", Vector2i(20, 7), "up")
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		DirAccess.make_dir_recursive_absolute("res://chapters/c6")
		err = ResourceSaver.save(packed, OUT)
	print("BAKE ", OUT, " -> ", error_string(err))
	get_tree().quit()


## In che zona è la casella (pavimento o muro della zona), "" se è bordo.
func _zone(c: Vector2i) -> String:
	for z: Array in [["lift", LIFT], ["corr", CORRIDOR], ["office", OFFICE]]:
		var r: Rect2i = z[1]
		var with_wall := Rect2i(r.position - Vector2i(0, 2), r.size + Vector2i(0, 2))
		if with_wall.has_point(c):
			return str(z[0])
	# le porte fra le zone
	if c.y in DOOR_ROWS and (c.x == 5 or c.x == 13):
		return "corr"
	return ""


## L'ascensore: niente pulsanti, solo un'insegna e uno specchio.
func _ascensore() -> void:
	var sign := _sprite(decori, "InsegnaAscensore", ART + "insegna_ascensore.png", Rect2(), Vector2i(1, 3), 0, Vector2(0, -4))
	sign.z_index = 1
	var mirror := _sprite(decori, "SpecchioAscensore", ART + "specchio_ascensore.png", Rect2(), Vector2i(1, 4), 0, Vector2(16, 0))
	mirror.z_index = 1
	_examine(mondo, "GuardaSpecchioAscensore", Vector2i(2, 5), [], "_specchio_ascensore")
	_examine(mondo, "CercaPulsanti", Vector2i(4, 5), [
		"* Nessun pulsante. Una targhetta: \"PER SCENDERE, RIVOLGERSI ALLA PRESIDENZA\".",
	])


## Il corridoio degli specchi: ognuno riflette qualcuno che hai incontrato.
func _corridoio() -> void:
	for i in 3:
		var m := _sprite(decori, "Specchio%d" % i, ART + "specchio.png", Rect2(), Vector2i(7 + i * 2, 5), 0, Vector2(0, 0))
		m.z_index = 1
		_examine(mondo, "GuardaSpecchio%d" % i, Vector2i(7 + i * 2, 6), [], "_specchio_%d" % i)
	_feature("Stellina", "save", Vector2i(11, 9))
	_sprite(mondo, "VasoCorridoio", GENERIC, POT, Vector2i(6, 9), 6)


## L'ufficio: grande, colorato, vuoto. Tutto quello che serve sta lontano da tutto il resto.
func _ufficio() -> void:
	_sprite(mondo, "Scrivania", ART + "scrivania_presidenza.png", Rect2(), Vector2i(19, 5), 14)
	var folder := _sprite(mondo, "Cartellina", ART + "cartellina_obbligo.png", Rect2(), Vector2i(20, 5), 0, Vector2(4, -26))
	folder.z_index = 1
	_examine(mondo, "UsaScrivania", Vector2i(20, 6), [], "_scrivania")
	_sprite(mondo, "TerminaleBilanci", ART + "terminale_direzione.png", Rect2(), Vector2i(16, 4), 8)
	_examine(mondo, "UsaTerminale", Vector2i(16, 5), [], "_terminale")
	var window := _sprite(decori, "Finestra", ART + "finestra_panorama.png", Rect2(), Vector2i(23, 2), 0, Vector2(0, 0))
	window.z_index = 1
	_examine(mondo, "GuardaFinestra", Vector2i(25, 3), [], "_finestra")
	_sprite(mondo, "ArchivioDebito", ART + "archivio_debito.png", Rect2(), Vector2i(29, 4), 12)
	_examine(mondo, "ApriArchivio", Vector2i(29, 5), [], "_archivio")
	_sprite(mondo, "Tavolo", ART + "tavolo_decisione.png", Rect2(), Vector2i(21, 10), 14)
	_examine(mondo, "SiediTavolo", Vector2i(22, 9), [], "_tavolo")
	_sprite(mondo, "Caffe", ART + "macchina_caffe.png", Rect2(), Vector2i(15, 11), 8)
	_examine(mondo, "UsaCaffe", Vector2i(15, 10), [], "_caffe")
	_sprite(mondo, "Pianta0", GENERIC, POT, Vector2i(14, 3), 6)
	_sprite(mondo, "Pianta1", GENERIC, POT, Vector2i(30, 12), 6)
	_sprite(mondo, "Pianta2", PROPS + "palm.png", Rect2(), Vector2i(27, 12), 8)
	_sprite(decori, "Tappeto", GENERIC, RUG, Vector2i(19, 7), 0, Vector2(8, 4))
	_examine(mondo, "GuardaVuoto", Vector2i(26, 8), [
		"* Qui non c'è niente. Lo spazio di un ufficio intero al -4.",
		"* Il pavimento è lucidato lo stesso. Tutti i giorni.",
	])


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
