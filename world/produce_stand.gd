@tool
extends Sprite2D
## Harvested produce on the original empty supermarket crates.
const Products := preload("res://scripts/product_art.gd")
const CRATE := preload("res://assets/limezu/market/box_1.png")
const CRATE_REGION := Rect2(9, 15, 16, 17)
@export_enum("Fragola", "Cipollotto", "Patata", "Cipolla") var produce_name := "Fragola":
	set(value):
		produce_name = value
		if is_inside_tree(): _refresh()

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	texture = CRATE
	centered = false
	region_enabled = true
	region_rect = CRATE_REGION
	offset = Vector2(0, -17)
	var top := get_node_or_null("Sopra") as Sprite2D
	if top:
		top.visible = true
		top.texture = CRATE
		top.centered = false
		top.region_enabled = true
		top.region_rect = CRATE_REGION
		top.offset = Vector2(0, -29)
	var product := get_node_or_null("Prodotto") as Sprite2D
	if not product:
		product = Sprite2D.new()
		product.name = "Prodotto"
		product.centered = false
		product.offset = Vector2(0, -40)
		add_child(product)
	product.texture = Products.texture(produce_name)
