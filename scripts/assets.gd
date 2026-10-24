class_name Assets
extends RefCounted
## Carica gli asset LimeZu da res://assets/limezu/ (copiati con tools/import_assets.ps1).
## Se un file manca, per esempio in un clone pubblico del repo, usa un segnaposto colorato
## così il gioco parte lo stesso.

const ROOT := "res://assets/limezu/"
## Ordine delle direzioni nei fogli personaggio di LimeZu.
const DIRS: Array[String] = ["right", "up", "left", "down"]
## Animazioni speciali del foglio personaggio: nome -> [riga, primo fotogramma, quanti, velocità].
const EXTRA_ANIMS := {
	"sit_right": [4, 0, 6, 5.0],
	"sit_left": [4, 6, 6, 5.0],
	"phone": [6, 3, 6, 5.0],
	"read": [7, 0, 6, 4.0],
}

static var _textures := {}
static var _frames := {}
static var _font: Font


static func tex(rel: String, fallback_size := Vector2i(16, 16)) -> Texture2D:
	if _textures.has(rel):
		return _textures[rel]
	var path := ROOT + rel
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path) as Texture2D
	if t == null:
		push_warning("Asset mancante, uso un segnaposto: " + path)
		var img := Image.create(fallback_size.x, fallback_size.y, false, Image.FORMAT_RGBA8)
		img.fill(Color.from_hsv(float(absi(rel.hash()) % 360) / 360.0, 0.45, 0.75))
		t = ImageTexture.create_from_image(img)
	_textures[rel] = t
	return t


static func font() -> Font:
	if _font == null:
		# silkscreen.tres = Silkscreen (OFL): numeri chiari, il 5 si capisce
		_font = load("res://fonts/silkscreen.tres") if ResourceLoader.exists("res://fonts/silkscreen.tres") else ThemeDB.fallback_font
	return _font


## Animazioni di un personaggio del Character Generator (16x32 per fotogramma):
## riga 1 = fermo, riga 2 = camminata (6 fotogrammi per direzione), più seduto, telefono e lettura.
static func character(sheet: String) -> SpriteFrames:
	if _frames.has(sheet):
		return _frames[sheet]
	var t := tex("characters/%s.png" % sheet, Vector2i(896, 656))
	var sf := SpriteFrames.new()
	for i in DIRS.size():
		for kind: Array in [["idle", 1, 6.0], ["walk", 2, 10.0]]:
			_add(sf, "%s_%s" % [kind[0], DIRS[i]], t, int(kind[1]), i * 6, 6, kind[2])
	for anim: String in EXTRA_ANIMS:
		var a: Array = EXTRA_ANIMS[anim]
		_add(sf, anim, t, a[0], a[1], a[2], a[3])
	_frames[sheet] = sf
	return sf


static func _add(sf: SpriteFrames, anim: String, t: Texture2D, row: int, first: int, count: int, speed: float) -> void:
	sf.add_animation(anim)
	sf.set_animation_speed(anim, speed)
	sf.set_animation_loop(anim, true)
	for f in count:
		var at := AtlasTexture.new()
		at.atlas = t
		at.region = Rect2((first + f) * 16, row * 32, 16, 32)
		sf.add_frame(anim, at)


## Un'ombra ovale sotto i personaggi, per farli "poggiare" a terra.
static func shadow() -> Texture2D:
	if _textures.has("_shadow"):
		return _textures["_shadow"]
	var img := Image.create(12, 4, false, Image.FORMAT_RGBA8)
	for y in 4:
		for x in 12:
			var d := pow((x - 5.5) / 6.0, 2) + pow((y - 1.5) / 2.0, 2)
			if d <= 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0.35))
	var t := ImageTexture.create_from_image(img)
	_textures["_shadow"] = t
	return t


## C'è qualcuno (persona, passante o giocatore) subito davanti a chi cammina?
static func someone_ahead(walker: Node2D, direction: float, reach := 18.0) -> bool:
	var tree := walker.get_tree()
	var others: Array[Node] = []
	others.append_array(tree.get_nodes_in_group("npc"))
	others.append_array(tree.get_nodes_in_group("walker"))
	others.append_array(tree.get_nodes_in_group("player"))
	for o in others:
		if o == walker:
			continue
		var d: Vector2 = (o as Node2D).global_position - walker.global_position
		if absf(d.y) < 10 and d.x * direction > 0 and absf(d.x) < reach:
			return true
	return false
