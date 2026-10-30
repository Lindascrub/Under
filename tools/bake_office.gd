extends Node
## Costruisce UNA VOLTA la scena del piano terra (scenes/world/office.tscn) come scena vera da editor:
## da lì in poi le cose si spostano a mano in Godot (pavimento, muri, scrivanie, piante, ascensore,
## sportello, scale). La logica resta in scenes/world/office.gd.
## Esegui:  Godot --headless --path . res://tools/bake_office.tscn   (non sovrascrive: serve -- --force)

const T := 16
const RB := "res://assets/limezu/tiles/room_builder.png"
const GENERIC := "res://assets/limezu/tiles/generic.png"
const PROPS := "res://assets/limezu/props/"
const DESK := Rect2(96, 8, 16, 40)
const TILESET_PATH := "res://world/tilesets/interni.tres"
const OUT := "res://scenes/world/office.tscn"

const BORDER := Vector2i(12, 0)
const WALL_TOP := Vector2i(1, 13)
const WALL_LOW := Vector2i(1, 14)
const FLOOR := Vector2i(38, 11)

const ROWS := [
	"####################",
	"#WWWWWWWWWWWWWWWWWW#",
	"#wwwwwwwwwwwwwwwwww#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#########..#########",
	"#########..#########",
]

const DESK_TEXTS := [
	["* Sul monitor: PRODUTTIVITÀ DEL REPARTO 37%. Sotto, a penna: \"aiuto\"."],
	["* Una scrivania. Nel cassetto c'è una scorta di caffè solubile e di antidolorifici."],
	["* Sul monitor è aperta un'email: \"Oggetto: ottimizzazione del personale (riservato)\"."],
	["* Una foto di famiglia, girata verso il muro. Forse per non farsi vedere."],
	["* Post-it sul monitor: \"Sorridi! Il cliente ti sente.\""],
	["* Il computer è spento. Sopra c'è un biglietto: \"Grazie di tutto. Scusate.\""],
	["* Sul monitor scorre un grafico. Sale sempre. Non c'è scritto cosa."],
	["* Una tazza con la scritta \"Il miglior dipendente del mondo\". È piena di polvere."],
]

var root: Node2D
var mondo: Node2D
var decori: Node2D


func _ready() -> void:
	if FileAccess.file_exists(OUT) and ResourceLoader.load(OUT).instantiate().get_child_count() > 0 \
			and not "--force" in OS.get_cmdline_user_args():
		print("BAKE saltato: ", OUT, " è già una scena da editor. Per rifarla da zero: -- --force")
		get_tree().quit()
		return
	var ts := _tileset()
	root = Node2D.new()
	root.name = "Office"
	root.set_script(load("res://scenes/world/office.gd"))
	root.set("room_floor", "0")
	root.set("room_music", "ufficio")
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
			match row[x]:
				"#":
					muri.set_cell(c, 0, BORDER)
				"W":
					muri.set_cell(c, 0, WALL_TOP)
				"w":
					muri.set_cell(c, 0, WALL_LOW)
				_:
					pav.set_cell(c, 0, FLOOR + Vector2i(x % 3, y % 2))
	decori = Node2D.new()
	decori.name = "Decori"
	_add(root, decori)
	mondo = Node2D.new()
	mondo.name = "Mondo"
	mondo.y_sort_enabled = true
	_add(root, mondo)
	_things()
	var arrivi := Node2D.new()
	arrivi.name = "Arrivi"
	_add(root, arrivi)
	_arrival(arrivi, "default", Vector2i(9, 9), "up")
	_arrival(arrivi, "street", Vector2i(9, 9), "up")
	_arrival(arrivi, "terminal", Vector2i(9, 4), "up")
	_arrival(arrivi, "elevator", Vector2i(12, 4), "down")
	_arrival(arrivi, "from_below", Vector2i(3, 9), "right")
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT)
	print("BAKE ", OUT, " -> ", error_string(err))
	get_tree().quit()


func _add(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root


func _tileset() -> TileSet:
	var ts: TileSet = load(TILESET_PATH)
	var s := ts.get_source(0) as TileSetAtlasSource
	var solid := [BORDER, WALL_TOP, WALL_LOW]
	var floors := []
	for dy in 2:
		for dx in 3:
			floors.append(FLOOR + Vector2i(dx, dy))
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


## Uno sprite con l'angolo in basso a sinistra sulla casella `cell`; `foot` = pixel solidi in basso.
func _sprite(parent: Node, nm: String, tex: String, region: Rect2, cell: Vector2i, foot := 0) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = nm
	s.texture = load(tex)
	if region.size != Vector2.ZERO:
		s.region_enabled = true
		s.region_rect = region
	var size := region.size if region.size != Vector2.ZERO else s.texture.get_size()
	s.centered = false
	s.offset = Vector2(0, -size.y)
	s.position = Vector2(cell.x * T, (cell.y + 1) * T)
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


## Cosa si legge toccando un oggetto: figlio dello sprite, così si sposta insieme a lui.
func _examine(parent: Node, nm: String, at: Vector2, lines: Array, method := "") -> void:
	var e := Examine.new()
	e.name = nm
	e.position = at
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


func _things() -> void:
	var term := _sprite(mondo, "Terminale", PROPS + "terminal.png", Rect2(), Vector2i(9, 3), 10)
	_examine(term, "UsaTerminale", Vector2(8, 0), [], "_terminal")
	var portrait := _sprite(decori, "Ritratto", PROPS + "portrait.png", Rect2(), Vector2i(6, 2))
	_examine(portrait, "GuardaRitratto", Vector2(8, 8), ["* Il ritratto del fondatore della CHEAP. Ti sorride come sorride una banca."])
	var trash := _sprite(mondo, "Cestino", PROPS + "trash.png", Rect2(), Vector2i(17, 3), 8)
	_examine(trash, "GuardaCestino", Vector2(8, -8), ["* Il cestino è pieno di curriculum. Alcuni sono ancora chiusi nella busta."])
	var palm := _sprite(mondo, "Palma", PROPS + "palm.png", Rect2(), Vector2i(1, 3), 8)
	_examine(palm, "GuardaPalma", Vector2(16, -8), ["* Una palma finta. È l'unica cosa qui dentro che non si stanca mai."])
	var plant := _sprite(mondo, "Pianta", PROPS + "plant.png", Rect2(), Vector2i(18, 9), 8)
	_examine(plant, "GuardaPianta", Vector2(8, -8), ["* Una pianta vera. Qualcuno la annaffia di nascosto ogni mattina."])
	var k := 0
	for y in [5, 8]:
		for x in [3, 4, 14, 15]:
			var d := _sprite(mondo, "Scrivania%d" % k, GENERIC, DESK, Vector2i(x, y), 22)
			_examine(d, "GuardaScrivania%d" % k, Vector2(8, -8), DESK_TEXTS[k % DESK_TEXTS.size()])
			k += 1
	# l'ascensore per la Direzione (si vede anche nell'editor); toccandolo si prova a salire
	var lift := Lift.new()
	lift.name = "Ascensore"
	lift.position = Vector2(12 * T, 1 * T)
	_add(mondo, lift)
	_examine(lift, "UsaAscensore", Vector2(16, 2 * T + 8), [], "_ride_elevator")
	_feature("ScaleGiu", "stairs_down", Vector2i(1, 9), {"target": "res://chapters/c4/banca.tscn", "spawn": "from_above"})
	_feature("SportelloBadge", "badge", Vector2i(16, 3))


func _arrival(parent: Node, nm: String, cell: Vector2i, facing: String) -> void:
	var m := Marker2D.new()
	m.name = nm
	m.position = Vector2(cell.x * T + T / 2.0, (cell.y + 1) * T - 2)
	m.set_meta("facing", facing)
	_add(parent, m)
