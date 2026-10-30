extends RefCounted
## Dedicated illustrated products shared by checkout and Leda's shelves.

const FILES := {
	"pane": "pane", "latte": "latte", "sapone": "sapone", "riso": "riso", "tazza": "tazza",
	"matita": "matita", "biscotti": "biscotti", "aria premium": "aria", "detersivo": "detersivo", "mele": "mele",
	"dentifricio": "dentifricio", "quaderno": "quaderno", "scopa": "scopa", "shampoo": "shampoo", "gomma": "gomma",
	"lampadina": "lampadina", "pasta": "pasta", "spugna": "spugna", "righello": "righello",
}
const PRODUCE_SHEET := "res://assets/farm_rpg/spring_crops.png"
const PRODUCE := {
	"fragola": Rect2(128, 16, 16, 16), "fragole": Rect2(128, 16, 16, 16),
	"cipollotto": Rect2(128, 48, 16, 16), "cipollotti": Rect2(128, 48, 16, 16),
	"patata": Rect2(128, 80, 16, 16), "patate": Rect2(128, 80, 16, 16),
	"cipolla": Rect2(128, 112, 16, 16), "cipolle": Rect2(128, 112, 16, 16),
}
static var _textures: Dictionary = {}

static func texture(name: String) -> Texture2D:
	var key := name.strip_edges().to_lower()
	if _textures.has(key): return _textures[key] as Texture2D
	if PRODUCE.has(key):
		var crop := AtlasTexture.new()
		crop.atlas = load(PRODUCE_SHEET)
		crop.region = PRODUCE[key]
		_textures[key] = crop
		return crop
	if not FILES.has(key):
		push_warning("Nessuna illustrazione dedicata al prodotto: " + name)
		return null
	var path := "res://art/minigiochi/prodotti/" + str(FILES[key]) + ".png"
	var tex := load(path) as Texture2D
	_textures[key] = tex
	return tex

static func draw(ci: CanvasItem, r: Rect2, name: String) -> void:
	var tex := texture(name)
	if tex == null: return
	var k := minf(r.size.x / tex.get_width(), r.size.y / tex.get_height())
	if k >= 1.0: k = maxf(1.0, floorf(k))
	var size := (tex.get_size() * k).floor()
	ci.draw_texture_rect(tex, Rect2((r.get_center() - size / 2).floor(), size), false)
