class_name Assets
extends RefCounted
## Carica gli asset LimeZu da res://assets/limezu/ (copiati con tools/import_assets.ps1).
## Se un file manca, per esempio in un clone pubblico del repo, usa un segnaposto colorato
## così il gioco parte lo stesso.

const ROOT := "res://assets/limezu/"
## Ordine delle direzioni nei fogli personaggio di LimeZu.
const DIRS: Array[String] = ["right", "up", "left", "down"]

static var _textures := {}
static var _frames := {}


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


## Animazioni di un personaggio del Character Generator (foglio 16x32 per fotogramma):
## riga 1 = fermo, riga 2 = camminata, 6 fotogrammi per direzione.
static func character(sheet: String) -> SpriteFrames:
	if _frames.has(sheet):
		return _frames[sheet]
	var t := tex("characters/%s.png" % sheet, Vector2i(384, 96))
	var sf := SpriteFrames.new()
	for i in DIRS.size():
		for kind: Array in [["idle", 1, 6.0], ["walk", 2, 10.0]]:
			var anim := "%s_%s" % [kind[0], DIRS[i]]
			sf.add_animation(anim)
			sf.set_animation_speed(anim, kind[2])
			sf.set_animation_loop(anim, true)
			for f in 6:
				var at := AtlasTexture.new()
				at.atlas = t
				at.region = Rect2((i * 6 + f) * 16, int(kind[1]) * 32, 16, 32)
				sf.add_frame(anim, at)
	_frames[sheet] = sf
	return sf
