extends Node
## Costruisce UNA VOLTA la scena del Fondo-festa (capitolo 1) e la salva come scena vera
## in res://chapters/c1/fondo.tscn. Da lì in poi la scena si modifica nell'editor di Godot:
## questo script serve solo a creare la prima versione (non rilanciarlo, o sovrascrive le modifiche).
## Esegui:  Godot --headless --path . res://tools/bake_c1_fondo.tscn

const T := 16
const W := 24
const H := 14
const RB := "res://assets/limezu/tiles/room_builder.png"
const BDAY := "res://assets/limezu/tiles/birthday.png"
const TILESET_PATH := "res://world/tilesets/interni.tres"
const OUT := "res://chapters/c1/fondo.tscn"

## Le piastrelle colorate della festa (ognuna è un motivo da 3x2 caselle in room_builder).
const FLOORS := [Vector2i(42, 17), Vector2i(42, 33), Vector2i(34, 17)]
const WALL := Vector2i(22, 29)
const BORDER := Vector2i(12, 0)

var root: Node2D
var mondo: Node2D
var decori: Node2D


func _ready() -> void:
	var ts := _tileset()
	root = Node2D.new()
	root.name = "Fondo"
	root.set_script(load("res://chapters/c1/fondo_c1.gd"))
	root.set("room_floor", "-5")
	root.set("room_music", "festa")
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
			var border := x == 0 or x == W - 1 or y == 0 or y == H - 1
			if border:
				muri.set_cell(c, 0, BORDER)
			elif y <= 2:
				muri.set_cell(c, 0, WALL + Vector2i(x % 3, y - 1))
			else:
				var block := (x / 2 + y / 2) % 3
				var base: Vector2i = FLOORS[block]
				pav.set_cell(c, 0, base + Vector2i(x % 3, y % 2))
	# i decori per terra (coriandoli): sotto a tutto
	decori = Node2D.new()
	decori.name = "Decori"
	_add(root, decori)
	mondo = Node2D.new()
	mondo.name = "Mondo"
	mondo.y_sort_enabled = true
	_add(root, mondo)
	_party()
	_people()
	_features()
	var arrivi := Node2D.new()
	arrivi.name = "Arrivi"
	_add(root, arrivi)
	_arrival(arrivi, "default", Vector2i(11, 3), "down")
	_arrival(arrivi, "elevator", Vector2i(11, 3), "down")
	_arrival(arrivi, "from_above", Vector2i(21, 5), "down")
	# niente risorse "pesanti" dentro la scena: i personaggi si ridisegnano da soli
	for n in root.find_children("*", "CharSprite", true, false):
		(n as CharSprite).sprite_frames = null
		(n as CharSprite).material = null
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT)
	print("BAKE ", OUT, " -> ", error_string(err))
	get_tree().quit()


func _add(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root


# --- il TileSet condiviso: room_builder con le collisioni sui muri ------------------

func _tileset() -> TileSet:
	var ts: TileSet
	if ResourceLoader.exists(TILESET_PATH):
		ts = load(TILESET_PATH)
	else:
		ts = TileSet.new()
		ts.tile_size = Vector2i(T, T)
		ts.add_physics_layer()
		var src := TileSetAtlasSource.new()
		src.texture = load(RB)
		src.texture_region_size = Vector2i(T, T)
		ts.add_source(src, 0)
	var s := ts.get_source(0) as TileSetAtlasSource
	var solid := [BORDER]
	for dy in 2:
		for dx in 3:
			solid.append(WALL + Vector2i(dx, dy))
	var floors := []
	for f: Vector2i in FLOORS:
		for dy in 2:
			for dx in 3:
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


# --- la festa che nessuno festeggia ------------------------------------------------

## Uno sprite da un foglio, con l'angolo in basso a sinistra sulla casella `cell`.
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
		e.after_flag = "c1_rivelazione"
	_add(parent, e)


func _party() -> void:
	# festoni lungo tutto il muro
	for i in 7:
		var r := Rect2(0, 64, 32, 16) if i % 2 == 0 else Rect2(32, 64, 48, 16)
		var g := _sprite(decori, "Festone%d" % i, BDAY, r, Vector2i(1 + i * 3, 1), 0, Vector2(4, 4))
		g.z_index = 1
	# palloncini legati qua e là
	var balloons := [[Vector2i(2, 3), 0], [Vector2i(3, 3), 16], [Vector2i(9, 3), 32], [Vector2i(16, 3), 48], [Vector2i(20, 12), 0], [Vector2i(1, 12), 32]]
	# ogni palloncino ha la sua frase (e un'altra dopo che la festa si spegne)
	var balloon_lines := [
		[["* Un palloncino giallo. Ci hanno stampato sopra: \"BENVENUTO AL FONDO!\".", "* Non c'è scritto il nome di nessuno. Va bene per tutti quelli che arrivano."],
			["* Il palloncino giallo è afflosciato. La scritta adesso dice \"BENVE...\". Il resto è una piega."]],
		[["* Un palloncino blu. Lo tocchi: è tiepido. Come se qualcuno ci avesse soffiato dentro poco fa.", "* Su un'etichetta: \"Gonfiato al piano terra. Non riutilizzabile\"."],
			["* Il palloncino blu è grigio e floscio. Tiepido non lo è più."]],
		[["* Un palloncino rosso a forma di cuore. Sopra: \"LA CHEAP TI VUOLE BENE\".", "* Il filo è legato a un peso di piombo. Così non vola via. Come te."],
			["* Il cuore rosso si è sgonfiato. Adesso sembra un portafoglio vuoto."]],
		[["* Un palloncino verde. Dentro c'è un bigliettino: \"Hai vinto un turno extra!\".", "* Sul retro, in piccolo: \"Il premio non è convertibile in tempo libero\"."],
			["* Il palloncino verde è per terra. Il bigliettino è rimasto dentro, ma ormai non lo legge nessuno."]],
		[["* Un palloncino in fondo alla stanza, lontano da tutti. Anche le decorazioni, qui, fanno i turni.", "* Questo è di guardia."],
			["* Anche quello di guardia si è sgonfiato. Nessuno gli darà il cambio."]],
		[["* Un palloncino che qualcuno ha disegnato a pennarello con una faccina. La faccina è triste.", "* L'unico onesto della festa."],
			["* La faccina triste, adesso che è tutto grigio, sembra quasi sollevata."]],
	]
	for i in balloons.size():
		var b: Array = balloons[i]
		_sprite(mondo, "Palloncino%d" % i, BDAY, Rect2(int(b[1]), 80, 16, 32), b[0], 4)
		var bl: Array = balloon_lines[i % balloon_lines.size()]
		_examine(mondo, "GuardaPalloncino%d" % i, b[0], bl[0], "", bl[1])
	# il tavolo della festa con la torta, i regali e il cibo
	_sprite(mondo, "TavoloFesta", "res://assets/limezu/market/table_1.png", Rect2(), Vector2i(10, 10), 14)
	var cake := _sprite(mondo, "Torta", BDAY, Rect2(0, 40, 32, 24), Vector2i(10, 10), 0, Vector2(8, -12))
	cake.z_index = 1
	_examine(mondo, "GuardaTorta", Vector2i(11, 10), [
		"* Una torta con le candeline. Sulla glassa c'è scritto: \"AUGURI ALLA CHEAP\".",
		"* La festa è per l'azienda. Tu sei l'invitato che porta il regalo.",
	], "", ["* La torta, adesso, si vede per quello che è: plastica. Le candeline sono lampadine. Spente."])
	_sprite(mondo, "RegaloRosso", BDAY, Rect2(160, 0, 16, 24), Vector2i(13, 10), 6)
	_sprite(mondo, "RegaloBlu", BDAY, Rect2(176, 0, 16, 24), Vector2i(9, 11), 6)
	_examine(mondo, "GuardaRegaloRosso", Vector2i(13, 10), [
		"* Un regalo impacchettato benissimo. Lo scuoti: è vuoto.",
		"* Sul biglietto: \"Il regalo sei tu. Con affetto, l'Ufficio Risorse Umane\".",
	], "", ["* Il regalo rosso è grigio. Il fiocco si è sciolto da solo. Dentro, sempre niente."])
	_examine(mondo, "GuardaRegaloBlu", Vector2i(9, 11), [
		"* Un regalo blu, con il tuo nome scritto a mano sul biglietto. Come facevano a saperlo?",
		"* Dentro c'è un modulo: \"Dichiarazione di disponibilità al lavoro straordinario\". Già firmato. Con la tua firma.",
	], "", ["* Il regalo blu, spento, sembra solo una scatola. Il modulo dentro è ancora firmato."])
	# coriandoli per terra
	var conf := [Vector2i(5, 5), Vector2i(12, 7), Vector2i(17, 6), Vector2i(7, 11), Vector2i(19, 9), Vector2i(14, 12), Vector2i(3, 9)]
	for i in conf.size():
		_sprite(decori, "Coriandoli%d" % i, BDAY, Rect2(64, 80, 16, 16) if i % 2 == 0 else Rect2(144, 32, 16, 16), conf[i])
	_examine(mondo, "GuardaStriscione", Vector2i(6, 3), [
		"* Uno striscione: \"IL POSTO PIÙ FELICE DELLA TORRE!\".",
		"* Più in piccolo: \"Felicità garantita fino a esaurimento scorte\".",
	])


func _people() -> void:
	# intorno a Fermo la festa si spegne: un alone scuro e sfumato sul pavimento
	var halo := Sprite2D.new()
	halo.name = "AloneFermo"
	var g := Gradient.new()
	g.set_color(0, Color(0.08, 0.07, 0.12, 0.85))
	g.set_color(1, Color(0.08, 0.07, 0.12, 0.0))
	g.add_point(0.45, Color(0.08, 0.07, 0.12, 0.6))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.5, 0.0)
	gt.width = 96
	gt.height = 72
	halo.texture = gt
	halo.position = Vector2(14 * T + 8, 5 * T - 6)
	_add(decori, halo)
	# accanto a Bulbo (la ragazza), le scatole di lampadine da smistare
	_sprite(mondo, "ScatolaLampadine1", "res://art/bulb_box.png", Rect2(), Vector2i(18, 10), 8)
	_sprite(mondo, "ScatolaLampadine2", "res://art/bulb_box.png", Rect2(), Vector2i(18, 11), 8, Vector2(6, 2))
	_examine(mondo, "GuardaScatole", Vector2i(19, 10), [
		"* Scatole piene di lampadine. Alcune accese, alcune rotte, alcune che non hanno ancora deciso.",
	])
	# accanto a Nonno Mina, i cavi aggrovigliati (sono linee: si possono spostare nell'editor)
	var cols := [Color("d23b3b"), Color("39b6ff"), Color("ffe14d"), Color("3ddc84")]
	for i in cols.size():
		var line := Line2D.new()
		line.name = "Cavo%d" % i
		line.width = 1.5
		line.default_color = cols[i]
		var pts := PackedVector2Array()
		var start := Vector2(4 * T + 4, 8 * T + 4 + i * 3)
		for k in 9:
			pts.append(start + Vector2(k * 5, sin(k * 1.7 + i * 2.1) * 6 + cos(k * 0.9 + i) * 3))
		line.points = pts
		_add(decori, line)
	_examine(mondo, "GuardaCavi", Vector2i(5, 8), [
		"* Un groviglio di cavi colorati. Rosso con rosso, blu con blu. In teoria.",
	])
	# Fermo, seduto su una cassetta accanto all'ascensore: l'unico grigio
	_sprite(mondo, "CassettaFermo", "res://assets/limezu/street/box_trash.png", Rect2(), Vector2i(14, 4), 16)
	var fermo := CharSprite.new()
	fermo.name = "Fermo"
	fermo.sheet = "char_14"
	fermo.person = "fermo"
	fermo.anim = "sit_left"
	fermo.grey = true
	fermo.nudge = Vector2(-3, -6)
	fermo.position = Vector2(14 * T + 8, 5 * T - 1)
	_add(mondo, fermo)
	_examine(mondo, "ParlaConFermo", Vector2i(14, 4), [], "_talk_fermo")
	var mina := NpcSpot.new()
	mina.name = "Bulbo"
	mina.npc_id = "mina"
	mina.activity = "idle_left"
	mina.position = Vector2(17 * T + 8, 11 * T - 2)
	_add(mondo, mina)
	var bulbo := NpcSpot.new()
	bulbo.name = "NonnoMina"
	bulbo.npc_id = "bulbo"
	bulbo.activity = "idle_down"
	bulbo.position = Vector2(6 * T + 8, 9 * T - 2)
	_add(mondo, bulbo)


func _feature(nm: String, kind: String, cell: Vector2i, props := {}) -> void:
	var f := RoomFeature.new()
	f.name = nm
	f.kind = kind
	f.position = Vector2(cell * T)
	for k: String in props:
		f.set(k, props[k])
	_add(mondo, f)


func _features() -> void:
	# la cyclette con la dinamo (la grafica), e il posto di lavoro (la logica) davanti
	_sprite(mondo, "CycletteDinamo", "res://art/generator.png", Rect2(), Vector2i(3, 6), 10)
	_feature("Cyclette", "station", Vector2i(4, 6), {"job": "dinamo"})
	_feature("SportelloBadge", "badge", Vector2i(18, 3))
	_feature("ScaleSu", "stairs_up", Vector2i(21, 3), {"target": "res://chapters/c2/sottoufficio.tscn", "spawn": "", "need": "-4"})
	_feature("Stellina", "save", Vector2i(5, 11))


func _arrival(parent: Node, nm: String, cell: Vector2i, facing: String) -> void:
	var m := Marker2D.new()
	m.name = nm
	m.position = Vector2(cell.x * T + T / 2.0, (cell.y + 1) * T - 2)
	m.set_meta("facing", facing)
	_add(parent, m)
