extends Node
## Costruisce UNA VOLTA la Cima (capitolo 6) e la salva come scena vera in res://chapters/c6/cima.tscn.
## Esegui:  Godot --headless --path . res://tools/bake_c6_cima.tscn
##
##   a sinistra   l'ascensore dorato (senza pulsanti): si arriva qui
##   in mezzo     il corridoio degli specchi (lungo: tre specchi, due ritratti, la stellina)
##   sotto        la stanza della dinamo: la prima cyclette, dimenticata (si entra dall'ufficio)
##   a destra     l'ufficio della Presidente: enorme, colorato, quasi vuoto. Ogni cosa ha il suo angolo:
##                il terminale dei bilanci (ovest), la scrivania del TURNO (al centro), la finestra
##                panoramica (nord), l'archivio del debito (est), il tavolo della decisione (sud),
##                il caffè (sud-ovest), il salottino (sud-est)
## Tessere dal TileSet degli interni (fogli LimeZu): ogni zona ha il suo pavimento e il suo muro.

const T := 16
const W := 48
const H := 22
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
## la stanza della dinamo ha il pavimento e il muro del Fondo
const DYNAMO_FLOOR := Vector2i(42, 33)
## muri: corallo, azzurro, viola, e quello del Fondo
const LIFT_WALL := Vector2i(29, 11)
const MIRROR_WALL := Vector2i(29, 19)
const OFFICE_WALL := Vector2i(29, 15)
const DYNAMO_WALL := Vector2i(22, 29)
const LIFT := Rect2i(1, 8, 5, 6)
const CORRIDOR := Rect2i(7, 9, 14, 4)
const OFFICE := Rect2i(22, 4, 24, 16)
const DYNAMO := Rect2i(15, 15, 6, 4)
## porte: ascensore-corridoio (x 6), corridoio-ufficio (x 21), dinamo-ufficio (x 21, più in basso)
const DOOR_ROWS := [10, 11]
const DYNAMO_DOOR_ROWS := [16, 17]

var root: Node2D
var mondo: Node2D
var decori: Node2D


func _ready() -> void:
	var ts: TileSet = load(TILESET_PATH)
	var src := ts.get_source(0) as TileSetAtlasSource
	for base: Vector2i in [GOLD_FLOOR, PINK_FLOOR, PURPLE_FLOOR, DYNAMO_FLOOR, LIFT_WALL, MIRROR_WALL, OFFICE_WALL, DYNAMO_WALL]:
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
			var wall_base: Vector2i = {"lift": LIFT_WALL, "corr": MIRROR_WALL, "office": OFFICE_WALL, "dynamo": DYNAMO_WALL}[zone]
			var floor_base: Vector2i = {"lift": GOLD_FLOOR, "corr": PINK_FLOOR, "office": PURPLE_FLOOR, "dynamo": DYNAMO_FLOOR}[zone]
			var rect: Rect2i = {"lift": LIFT, "corr": CORRIDOR, "office": OFFICE, "dynamo": DYNAMO}[zone]
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
	_dinamo()
	_ufficio()
	var arrivi := Node2D.new()
	arrivi.name = "Arrivi"
	_add(root, arrivi)
	_arrival(arrivi, "default", Vector2i(3, 11), "right")
	_arrival(arrivi, "from_below", Vector2i(3, 11), "right")
	_arrival(arrivi, "desk", Vector2i(32, 9), "up")
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		DirAccess.make_dir_recursive_absolute("res://chapters/c6")
		err = ResourceSaver.save(packed, OUT)
	print("BAKE ", OUT, " -> ", error_string(err))
	get_tree().quit()


## In che zona è la casella (pavimento o muro della zona), "" se è bordo.
func _zone(c: Vector2i) -> String:
	for z: Array in [["lift", LIFT], ["corr", CORRIDOR], ["office", OFFICE], ["dynamo", DYNAMO]]:
		var r: Rect2i = z[1]
		var with_wall := Rect2i(r.position - Vector2i(0, 2), r.size + Vector2i(0, 2))
		if with_wall.has_point(c):
			return str(z[0])
	# le porte fra le zone
	if c.y in DOOR_ROWS and (c.x == 6 or c.x == 21):
		return "corr"
	if c.y in DYNAMO_DOOR_ROWS and c.x == 21:
		return "dynamo"
	return ""


## L'ascensore: niente pulsanti, solo un'insegna e uno specchio.
func _ascensore() -> void:
	var sign := _sprite(decori, "InsegnaAscensore", ART + "insegna_ascensore.png", Rect2(), Vector2i(1, 6), 0, Vector2(8, -4))
	sign.z_index = 1
	var mirror := _sprite(decori, "SpecchioAscensore", ART + "specchio_ascensore.png", Rect2(), Vector2i(2, 7), 0, Vector2(8, 0))
	mirror.z_index = 1
	_examine(mondo, "GuardaSpecchioAscensore", Vector2i(3, 8), [], "_specchio_ascensore")
	_examine(mondo, "CercaPulsanti", Vector2i(5, 8), [
		"* Nessun pulsante. Una targhetta: \"PER SCENDERE, RIVOLGERSI ALLA PRESIDENZA\".",
	])


## Il corridoio degli specchi: ognuno riflette qualcuno che hai incontrato. Fra uno e l'altro, i ritratti
## dei Presidenti di prima.
func _corridoio() -> void:
	for i in 3:
		var x := 9 + i * 5
		var m := _sprite(decori, "Specchio%d" % i, ART + "specchio.png", Rect2(), Vector2i(x, 8), 0, Vector2(0, 0))
		m.z_index = 1
		_examine(mondo, "GuardaSpecchio%d" % i, Vector2i(x, 9), [], "_specchio_%d" % i)
	for i in 2:
		var p := _sprite(decori, "Ritratto%d" % i, PROPS + "portrait.png", Rect2(), Vector2i(11 + i * 5, 8), 0, Vector2(0, -4))
		p.z_index = 1
	_examine(mondo, "GuardaRitratti", Vector2i(11, 9), [
		"* Ritratti. I Presidenti di prima. Stessa giacca, stessa poltrona, facce diverse.",
		"* L'ultima cornice è vuota. Sotto c'è scritto: \"PROSSIMAMENTE\".",
	])
	_feature("Stellina", "save", Vector2i(19, 12))
	_sprite(mondo, "VasoCorridoio0", GENERIC, POT, Vector2i(7, 12), 6)
	_sprite(mondo, "VasoCorridoio1", GENERIC, POT, Vector2i(14, 12), 6)


## La stanza della dinamo: la prima cyclette, identica a quella del Fondo. Si entra dall'ufficio.
func _dinamo() -> void:
	_sprite(mondo, "CycletteVecchia", "res://art/generator.png", Rect2(), Vector2i(16, 16), 10)
	_examine(mondo, "UsaDinamo", Vector2i(17, 17), [], "_dinamo")
	_sprite(mondo, "ScatoleDinamo", PROPS + "boxes_small.png", Rect2(), Vector2i(19, 18), 6)
	_examine(mondo, "GuardaScatole", Vector2i(19, 17), [
		"* Scatoloni. Su uno c'è scritto \"MODELLO 1 — NON BUTTARE\". Sotto, a matita: \"perché?\"",
	])


## L'ufficio: grande, colorato, vuoto. Ogni cosa sta nel suo angolo, lontana da tutto il resto.
func _ufficio() -> void:
	# nord: la finestra panoramica
	var window := _sprite(decori, "Finestra", ART + "finestra_panorama.png", Rect2(), Vector2i(31, 3), 0, Vector2(0, 0))
	window.z_index = 1
	_examine(mondo, "GuardaFinestra", Vector2i(33, 4), [], "_finestra")
	# centro: la scrivania (con la cartellina e la lampadina della dinamo)
	_sprite(decori, "Tappeto", GENERIC, RUG, Vector2i(31, 9), 0, Vector2(8, 4))
	_sprite(mondo, "Scrivania", ART + "scrivania_presidenza.png", Rect2(), Vector2i(31, 7), 14)
	var folder := _sprite(mondo, "Cartellina", ART + "cartellina_obbligo.png", Rect2(), Vector2i(32, 7), 0, Vector2(4, -26))
	folder.z_index = 1
	var lamp := _sprite(mondo, "Lampadina", ART + "lampadina.png", Rect2(), Vector2i(34, 7), 0, Vector2(2, -24))
	lamp.z_index = 1
	lamp.modulate = Color(0.45, 0.45, 0.5)
	_examine(mondo, "UsaScrivania", Vector2i(32, 8), [], "_scrivania")
	# ovest: il terminale dei bilanci
	_sprite(mondo, "TerminaleBilanci", ART + "terminale_direzione.png", Rect2(), Vector2i(24, 5), 8)
	_examine(mondo, "UsaTerminale", Vector2i(24, 6), [], "_terminale")
	_sprite(mondo, "Pianta0", GENERIC, POT, Vector2i(22, 5), 6)
	# est: l'archivio del debito
	_sprite(mondo, "ArchivioDebito", ART + "archivio_debito.png", Rect2(), Vector2i(42, 5), 12)
	_examine(mondo, "ApriArchivio", Vector2i(42, 6), [], "_archivio")
	_sprite(mondo, "Pianta1", PROPS + "plant.png", Rect2(), Vector2i(45, 5), 6)
	# sud: il tavolo della decisione
	_sprite(mondo, "Tavolo", ART + "tavolo_decisione.png", Rect2(), Vector2i(32, 16), 14)
	_examine(mondo, "SiediTavolo", Vector2i(33, 14), [], "_tavolo")
	# sud-ovest: il caffè
	_sprite(mondo, "Caffe", ART + "macchina_caffe.png", Rect2(), Vector2i(24, 19), 8)
	_examine(mondo, "UsaCaffe", Vector2i(24, 18), [], "_caffe")
	_sprite(mondo, "Cestino", PROPS + "trash.png", Rect2(), Vector2i(26, 19), 4)
	# sud-est: un salottino dove nessuno si siede
	_sprite(mondo, "Palma", PROPS + "palm.png", Rect2(), Vector2i(44, 19), 8)
	_sprite(mondo, "Lampada", PROPS + "lamp.png", Rect2(), Vector2i(41, 18), 4)
	_sprite(mondo, "Pianta2", GENERIC, POT, Vector2i(38, 19), 6)
	_examine(mondo, "GuardaSalotto", Vector2i(40, 17), [
		"* Un angolo per gli ospiti. I cuscini sono ancora nella plastica.",
	])
	_examine(mondo, "GuardaVuoto", Vector2i(38, 11), [
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
