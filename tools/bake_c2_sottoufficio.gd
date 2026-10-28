extends Node
## Costruisce UNA VOLTA la scena del Sottoufficio (capitolo 2) e la salva come scena vera
## in res://chapters/c2/sottoufficio.tscn. Da lì in poi la scena si modifica nell'editor di Godot:
## questo script serve solo a creare la prima versione (non rilanciarlo, o sovrascrive le modifiche).
## Esegui:  Godot --headless --path . res://tools/bake_c2_sottoufficio.tscn

const T := 16
const RB := "res://assets/limezu/tiles/room_builder.png"
const GENERIC := "res://assets/limezu/tiles/generic.png"
const DESK := Rect2(96, 8, 16, 40)
const HOSPITAL := "res://assets/limezu/themes/hospital.png"
const CONFERENCE := "res://assets/limezu/themes/conference.png"
const SUBWAY := "res://assets/limezu/themes/subway.png"
const CLASSROOM := "res://assets/limezu/themes/classroom.png"
const LIVING := "res://assets/limezu/themes/living_room.png"
const TILESET_PATH := "res://world/tilesets/interni.tres"
const OUT := "res://chapters/c2/sottoufficio.tscn"

## Ogni stanza ha la sua parete e il suo pavimento (motivi da 3x2 in room_builder):
## C/c il call center (la moquette arancione e la carta a righe, anni '80), B/b l'ufficio badge
## (grigio, come al Fondo), R/r la sala dello sportello B-4 (rossa, da sala riunioni), E/e l'archivio (legno).
const WALLS := {"C": Vector2i(11, 17), "B": Vector2i(11, 41), "R": Vector2i(22, 13), "E": Vector2i(11, 23)}
const FLOORS := {"c": Vector2i(38, 25), "b": Vector2i(34, 11), "r": Vector2i(42, 19), "e": Vector2i(34, 25)}
const BORDER := Vector2i(12, 0)
const AFTER := "c2_rivelazione"

## Il bancone di legno della sala riunioni, l'urna, la biglietteria della stazione,
## le librerie dell'archivio, le sedie (viste di lato), il divano di pelle.
const COUNTER := Rect2(144, 72, 56, 16)
const BALLOT := Rect2(112, 32, 16, 32)
const TICKETS := Rect2(0, 288, 32, 32)
const BOOKCASE := Rect2(0, 208, 32, 48)
## la sedia vista di lato (ci si siede davvero, con l'animazione seduta)
const CHAIR := Rect2(96, 288, 16, 32)
const SOFA := Rect2(112, 448, 48, 32)

## Quattro stanze: il call center (a sinistra, con le scale per il -5 e i posti del turno),
## l'ufficio badge (in alto al centro: lo sportello, il tornello, la scala mobile per il -3),
## la sala dello sportello B-4 della Signora Agenda (in basso al centro), l'archivio di Ercole (a destra).
const ROWS := [
	"#########################################",
	"#CCCCCCCCCCCCCCC#BBBBBBBBBBBB#EEEEEEEEEE#",
	"#CCCCCCCCCCCCCCC#BBBBBBBBBBBB#EEEEEEEEEE#",
	"#ccccccccccccccc#bbbbbbbbbbbb#eeeeeeeeee#",
	"#ccccccccccccccc#bbbbbbbbbbbb#eeeeeeeeee#",
	"#ccccccccccccccc#bbbbbbbbbbbb#eeeeeeeeee#",
	"#ccccccccccccccccbbbbbbbbbbbb#eeeeeeeeee#",
	"#ccccccccccccccccbbbbbbbbbbbb#eeeeeeeeee#",
	"#ccccccccccccccc##############eeeeeeeeee#",
	"#ccccccccccccccc#RRRRRRRRRRRR#eeeeeeeeee#",
	"#ccccccccccccccc#RRRRRRRRRRRR#eeeeeeeeee#",
	"#ccccccccccccccc#rrrrrrrrrrrr#eeeeeeeeee#",
	"#ccccccccccccccc#rrrrrrrrrrrr#eeeeeeeeee#",
	"#ccccccccccccccccrrrrrrrrrrrreeeeeeeeeee#",
	"#ccccccccccccccccrrrrrrrrrrrreeeeeeeeeee#",
	"#ccccccccccccccc#rrrrrrrrrrrr#eeeeeeeeee#",
	"#########################################",
]

var root: Node2D
var mondo: Node2D
var decori: Node2D


func _ready() -> void:
	var ts := _tileset()
	root = Node2D.new()
	root.name = "Sottoufficio"
	root.set_script(load("res://chapters/c2/sottoufficio_c2.gd"))
	root.set("room_floor", "-4")
	root.set("room_music", "attesa")
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
				muri.set_cell(c, 0, BORDER)
			elif WALLS.has(ch):
				# la riga alta o bassa della parete: dipende da cosa c'è sopra
				var top := 0 if y == 0 or ROWS[y - 1][x] != ch else 1
				muri.set_cell(c, 0, WALLS[ch] + Vector2i(x % 3, top))
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
	_posters()
	_sportello()
	_callcenter()
	_ufficio_badge()
	_archivio()
	_plants()
	_features()
	var arrivi := Node2D.new()
	arrivi.name = "Arrivi"
	_add(root, arrivi)
	_arrival(arrivi, "default", Vector2i(11, 6), "down")
	_arrival(arrivi, "elevator", Vector2i(11, 6), "down")
	for n in root.find_children("*", "CharSprite", true, false):
		(n as CharSprite).sprite_frames = null
		(n as CharSprite).material = null
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		DirAccess.make_dir_recursive_absolute("res://chapters/c2")
		err = ResourceSaver.save(packed, OUT)
	print("BAKE ", OUT, " -> ", error_string(err))
	get_tree().quit()


func _add(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root


# --- il TileSet condiviso: aggiunge moquette e carta da parati --------------------

func _tileset() -> TileSet:
	var ts: TileSet = load(TILESET_PATH)
	var s := ts.get_source(0) as TileSetAtlasSource
	var solid := [BORDER]
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


## Dietro una scrivania la persona si disegna più in alto (`nudge`), se no la copre il monitor.
## Un muro invisibile (in caselle): dietro i banconi non ci si infila.
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


# --- il call center: tutto finto allegro ---------------------------------------

## I poster stanno sulla parete, sotto le persone: chi passa davanti si vede.
func _posters() -> void:
	_sprite(decori, "PosterSorridi", "res://art/poster_sorridi.png", Rect2(), Vector2i(2, 1), 0, Vector2(4, -2))
	_sprite(decori, "PosterModulo", "res://art/poster_modulo.png", Rect2(), Vector2i(6, 1), 0, Vector2(2, 0))
	_sprite(decori, "PosterAttesa", "res://art/poster_attesa.png", Rect2(), Vector2i(13, 1), 0, Vector2(6, -6))
	_examine(mondo, "GuardaSorridi", Vector2i(3, 3), [
		"* Un poster con una faccina gialla: \"SORRIDI! È GRATIS\".",
		"* Sotto, in piccolo: \"Il sorriso è parte integrante della mansione (art. 4 del contratto)\".",
	], "", ["* \"SORRIDI! È GRATIS\". Adesso che la musica si è fermata una volta, la faccina sembra un ordine."])
	_examine(mondo, "GuardaModulo", Vector2i(7, 3), [
		"* \"UN MODULO AL GIORNO TOGLIE IL PENSIERO\".",
		"* Qualcuno ha cancellato \"il pensiero\" e scritto sopra a penna: \"la giornata\". Poi qualcun altro ha cancellato anche quello.",
	], "", ["* \"UN MODULO AL GIORNO TOGLIE IL PENSIERO\". Ora sai dove vanno, i moduli. Il pensiero, invece, resta."])
	_examine(mondo, "GuardaAttesa", Vector2i(14, 3), [
		"* \"RESTI IN LINEA!\". Il cartello è appeso proprio sopra l'altoparlante della musichetta.",
		"* La musichetta è sempre la stessa. Dura quarantadue secondi. L'hai già contata tre volte.",
	], "", ["* \"RESTI IN LINEA!\". La musichetta è ripartita, più lenta. Come una giostra che nessuno ha il coraggio di spegnere."])


## La sala del call center: i colleghi colorati al telefono, Tilde in mezzo, grigia.
## In alto l'"angolo relax": un divano dove ci si può sedere (90 secondi al massimo).
func _callcenter() -> void:
	var colleagues := [[Vector2i(3, 6), "char_18"], [Vector2i(4, 6), "char_19"], [Vector2i(8, 6), "char_15"], [Vector2i(9, 6), "char_16"]]
	var lines := [
		["* \"Grazie per la sua pazienza. Grazie per la sua pazienza.\" Ti sorride senza guardarti."],
		["* \"Resti in linea, la sua chiamata è importante per noi!\" Sta parlando con il segnale di libero."],
		["* \"Le propongo l'offerta Serenità Plus!\" Dall'altra parte, qualcuno piange."],
		["* Ha la cuffia al contrario. Non se n'è accorto nessuno, nemmeno lui. Sorride lo stesso."],
	]
	var after := [
		["* Ha ancora la cornetta in mano. Il sorriso è rimasto dov'era, ma gli occhi no."],
		["* \"Resti in linea...\" lo dice piano, adesso. Forse lo dice a se stessa."],
		["* Ripete l'offerta a nessuno. Le dita, sulla scrivania, tremano un po'."],
		["* Si è girato la cuffia dal verso giusto. Poi l'ha rigirata. Così almeno non sente."],
	]
	for i in colleagues.size():
		var c: Array = colleagues[i]
		_sprite(mondo, "ScrivaniaCollega%d" % i, GENERIC, DESK, c[0] + Vector2i(0, 1), 22)
		_person("Collega%d" % i, c[1], "phone", c[0], Vector2(0, -14))
		_examine(mondo, "GuardaCollega%d" % i, c[0] + Vector2i(0, 1), lines[i], "", after[i])
		_solid("SediaCollega%d" % i, Rect2i(c[0], Vector2i.ONE))
	var tilde := NpcSpot.new()
	tilde.name = "Tilde"
	tilde.npc_id = "tilde"
	tilde.activity = "phone"
	tilde.position = Vector2(6 * T + 8, 8 * T - 2)
	_add(mondo, tilde)
	# la scrivania vuota del turno: telefono beige e cuffia
	_sprite(mondo, "ScrivaniaTurno", GENERIC, DESK, Vector2i(8, 10), 22)
	# l'angolo relax
	_sprite(mondo, "DivanoRelax", LIVING, SOFA, Vector2i(10, 4), 14)
	_examine(mondo, "GuardaRelax", Vector2i(13, 4), [
		"* Un cartello sopra il divano: \"ANGOLO RELAX. Durata massima del relax: 90 secondi\".",
		"* Sotto, un timer da cucina. È già partito.",
	])


# --- l'ufficio badge: come una biglietteria della metropolitana --------------

func _ufficio_badge() -> void:
	# la biglietteria dei piani (lo sportello vero è la reception: RoomFeature "badge")
	_sprite(mondo, "Biglietteria", SUBWAY, TICKETS, Vector2i(17, 3), 12)
	_examine(mondo, "GuardaBiglietteria", Vector2i(18, 3), [
		"* Una biglietteria automatica. Sullo schermo: \"BADGE DEL PIANO -3. Selezioni il metodo di pagamento: DEBITO\".",
		"* Non c'è un altro metodo. C'è solo il tasto DEBITO, consumato.",
	])
	# le sedie della sala d'attesa, girate verso lo sportello (ci si siede)
	for x in [21, 22, 23]:
		_sprite(mondo, "SediaAttesa%d" % x, HOSPITAL, CHAIR, Vector2i(x, 7), 10)
	_examine(mondo, "GuardaAttesaBadge", Vector2i(20, 7), [
		"* Un distributore di numeri per la fila. Prendi il biglietto: 4.817.",
		"* Sul display, il numero servito: 12.",
	])


## La sala dello sportello B-4: un bancone di legno da sala riunioni, le bandiere della CHEAP,
## la Signora Agenda dietro, il tritacarte accanto. Davanti, le sedie per aspettare.
func _sportello() -> void:
	_sprite(mondo, "BanconeAgenda", CONFERENCE, COUNTER, Vector2i(21, 12), 14)
	var agenda := _person("Agenda", "char_20", "idle_down", Vector2i(22, 11), Vector2(4, 8))
	agenda.set_meta("finto", true)
	_examine(mondo, "ParlaConAgenda", Vector2i(22, 12), [], "_agenda")
	_solid("DietroLoSportello", Rect2i(20, 11, 6, 1))
	var tri := _sprite(mondo, "Tritacarte", "res://art/shredder.png", Rect2(), Vector2i(26, 12), 10)
	tri.set_meta("finto", true)
	_examine(mondo, "GuardaTritacarte", Vector2i(26, 12), [
		"* Un tritacarte, lucido come nuovo. Accanto, un cartellino: \"ARCHIVIAZIONE RAPIDA\".",
		"* Il cestino sotto è pieno di striscioline. Su una leggi: \"...B-4...\".",
	], "", ["* Il tritacarte. Dentro c'è il tuo B-4, in centoventi striscioline. L'archiviazione più rapida della torre."])
	_sprite(mondo, "UrnaModuli", CONFERENCE, BALLOT, Vector2i(18, 12), 12)
	_examine(mondo, "GuardaUrna", Vector2i(18, 12), [
		"* Una cassetta di legno con una fessura: \"SUGGERIMENTI E RECLAMI\".",
		"* La fessura è stata chiusa con lo scotch. Il reclamo, si vede, è stato accolto.",
	])
	for x in [21, 22, 23, 24]:
		_sprite(mondo, "SediaB4_%d" % x, HOSPITAL, CHAIR, Vector2i(x, 15), 10)


# --- l'archivio di Ercole: scaffali di scartoffie -----------------------------

func _archivio() -> void:
	for x in [30, 32, 34, 36, 38]:
		_sprite(mondo, "Libreria%d" % x, CLASSROOM, BOOKCASE, Vector2i(x, 3), 14)
	_examine(mondo, "GuardaLibrerie", Vector2i(33, 4), [
		"* Scaffali di raccoglitori fino al soffitto. Sulle coste: \"PRATICHE 1984\", \"PRATICHE 1985\"... \"PRATICHE DOMANI\".",
	], "", ["* I raccoglitori di \"DOMANI\" sono già pieni. Di moduli B-4, timbrati \"in attesa\"."])
	var rows := [[7, [31, 32, 33, 34, 36, 37, 38]], [12, [31, 32, 33, 36, 37, 38]]]
	for r: Array in rows:
		for x: int in r[1]:
			_sprite(mondo, "Schedario%d_%d" % [x, r[0]], "res://art/cabinet.png", Rect2(), Vector2i(x, r[0]), 12)
	_examine(mondo, "GuardaSchedari", Vector2i(32, 8), [
		"* Schedari dell'archivio, pieni fino a scoppiare. Ogni cassetto ha un'etichetta: \"1984\", \"1985\", \"1986\"...",
		"* Il cassetto \"OGGI\" è chiuso a chiave.",
	], "", ["* Apri un cassetto. Cartelline, cartelline, cartelline. Tutte vuote. Qualcuna ha dentro un foglio bianco, perché sembri piena."])
	_examine(mondo, "GuardaSchedari2", Vector2i(37, 13), [
		"* Uno schedario ha un post-it: \"NON APRIRE. ARCHIVIO DELL'ARCHIVIO\".",
	], "", ["* L'archivio dell'archivio. Dentro c'è un elenco di cassetti vuoti. È l'unica cosa vera, qui dentro."])
	_sprite(mondo, "Scatoloni0", "res://assets/limezu/props/boxes.png", Rect2(), Vector2i(34, 15), 12)
	_sprite(mondo, "Scatoloni1", "res://assets/limezu/props/boxes.png", Rect2(), Vector2i(38, 15), 12)
	# Ercole in mezzo agli scaffali: niente sgabelli intorno, si parla solo standogli vicino
	var ercole := NpcSpot.new()
	ercole.name = "Ercole"
	ercole.npc_id = "ercole"
	ercole.activity = "idle_down"
	ercole.position = Vector2(34 * T + 8, 10 * T - 2)
	_add(mondo, ercole)


func _plants() -> void:
	var plants := [["res://assets/limezu/props/plant.png", Vector2i(1, 4)], ["res://assets/limezu/props/palm.png", Vector2i(13, 4)],
		["res://assets/limezu/props/plant.png", Vector2i(5, 15)], ["res://assets/limezu/props/plant.png", Vector2i(13, 15)],
		["res://assets/limezu/props/plant.png", Vector2i(28, 15)], ["res://assets/limezu/props/plant.png", Vector2i(28, 7)]]
	for i in plants.size():
		var p: Array = plants[i]
		_sprite(mondo, "Pianta%d" % i, p[0], Rect2(), p[1], 10)
	_examine(mondo, "GuardaPianta", Vector2i(1, 4), [
		"* Una pianta di plastica. La terra nel vaso è bagnata: qualcuno la annaffia lo stesso, ogni mattina.",
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
	_feature("PostoCallCenter", "station", Vector2i(8, 10), {"job": "callcenter"})
	_feature("SportelloBadge", "badge", Vector2i(25, 3))
	_feature("ScaleSu", "stairs_up", Vector2i(21, 3), {"target": "res://chapters/c3/mercato.tscn", "spawn": "from_below", "need": "-3"})
	_feature("Stellina", "save", Vector2i(11, 11))


func _arrival(parent: Node, nm: String, cell: Vector2i, facing: String) -> void:
	var m := Marker2D.new()
	m.name = nm
	m.position = Vector2(cell.x * T + T / 2.0, (cell.y + 1) * T - 2)
	m.set_meta("facing", facing)
	_add(parent, m)
