@tool
class_name RoomOutline
extends Node2D
## Il bordo bianco delle stanze, come nelle mappe di LimeZu: una riga bianca (con il filo scuro
## ai lati) sul vuoto che tocca una stanza. Si disegna da solo leggendo Pavimento e Muri,
## quindi segue le modifiche fatte nell'editor (stanze nuove, porte aperte nei muri).
## Sopra le pareti non si disegna: la parete ha già il suo bordo bianco in cima.
## Tra due stanze vicine (una sola casella di vuoto in mezzo) il separatore è pieno, come i pezzi
## "room border" di LimeZu: un muretto bianco visto dall'alto, non due righe con il buio in mezzo.

const T := 16
const LINE := 6
const WHITE := Color("f4f2ee")
const DARK := Color("2e2b3b")

## La tessera del vuoto (il "soffitto" scuro) nel livello Muri.
@export var void_tile := Vector2i(12, 0)


func _ready() -> void:
	for n in ["Pavimento", "Muri"]:
		var l := get_parent().get_node_or_null(n) as TileMapLayer
		if l and not l.changed.is_connected(queue_redraw):
			l.changed.connect(queue_redraw)
	queue_redraw()


var _area := Rect2i()


## 0 = vuoto, 1 = pavimento, 2 = parete (o una casella svuotata dentro la mappa: le scale nel muro)
func _kind(floor_l: TileMapLayer, walls: TileMapLayer, c: Vector2i) -> int:
	if walls and walls.get_cell_source_id(c) != -1:
		return 0 if walls.get_cell_atlas_coords(c) == void_tile else 2
	if floor_l and floor_l.get_cell_source_id(c) != -1:
		return 1
	return 2 if _area.has_point(c) else 0


var _tex: ImageTexture


func _draw() -> void:
	var img := build_image()
	if img:
		# la texture va tenuta: se si libera subito, si disegna un rettangolo bianco
		_tex = ImageTexture.create_from_image(img)
		draw_texture(_tex, Vector2(_used().position * T))


func _used() -> Rect2i:
	var floor_l := get_parent().get_node_or_null("Pavimento") as TileMapLayer
	var walls := get_parent().get_node_or_null("Muri") as TileMapLayer
	if not floor_l:
		return Rect2i()
	return floor_l.get_used_rect().merge(walls.get_used_rect()) if walls else floor_l.get_used_rect()


## L'immagine del bordo (grande quanto la mappa): bianco col filo scuro, trasparente altrove.
func build_image() -> Image:
	var floor_l := get_parent().get_node_or_null("Pavimento") as TileMapLayer
	var walls := get_parent().get_node_or_null("Muri") as TileMapLayer
	if not floor_l:
		return null
	var used := _used()
	_area = used
	var w := used.size.x * T
	var h := used.size.y * T
	if w <= 0 or h <= 0:
		return null
	# prima la maschera della riga (pixel per pixel), poi il bianco è la riga senza il suo bordo
	var mask := PackedByteArray()
	mask.resize(w * h)
	# i separatori: caselle di vuoto con una stanza da tutte e due le parti
	var dividers := {}
	for y in range(used.position.y, used.end.y):
		for x in range(used.position.x, used.end.x):
			var c := Vector2i(x, y)
			if _kind(floor_l, walls, c) == 0 and (
					(_kind(floor_l, walls, c + Vector2i.LEFT) != 0 and _kind(floor_l, walls, c + Vector2i.RIGHT) != 0)
					or (_kind(floor_l, walls, c + Vector2i.UP) != 0 and _kind(floor_l, walls, c + Vector2i.DOWN) != 0)):
				dividers[c] = true
	for y in range(used.position.y, used.end.y):
		for x in range(used.position.x, used.end.x):
			var c := Vector2i(x, y)
			if _kind(floor_l, walls, c) != 0:
				continue
			var o := (c - used.position) * T
			var strips: Array[Rect2i] = []
			if dividers.has(c):
				strips.append(Rect2i(o, Vector2i(T, T)))
			var l := _kind(floor_l, walls, c + Vector2i.LEFT) != 0 or dividers.has(c + Vector2i.LEFT)
			var r := _kind(floor_l, walls, c + Vector2i.RIGHT) != 0 or dividers.has(c + Vector2i.RIGHT)
			var u := _kind(floor_l, walls, c + Vector2i.UP) != 0 or dividers.has(c + Vector2i.UP)
			# (verso il basso solo il pavimento: sopra il separatore tra due pareti non si sporge)
			var d := _kind(floor_l, walls, c + Vector2i.DOWN) == 1
			# dove si incrociano i separatori, la casella è piena anche lei
			if [l, r, u, d].count(true) >= 3:
				strips.append(Rect2i(o, Vector2i(T, T)))
			if l:
				strips.append(Rect2i(o, Vector2i(LINE, T)))
			if r:
				strips.append(Rect2i(o + Vector2i(T - LINE, 0), Vector2i(LINE, T)))
			if u:
				strips.append(Rect2i(o, Vector2i(T, LINE)))
			if d:
				strips.append(Rect2i(o + Vector2i(0, T - LINE), Vector2i(T, LINE)))
			# gli angoli esterni: la stanza tocca solo in diagonale
			for k in [[Vector2i(-1, -1), Vector2i(0, 0), not l and not u], [Vector2i(1, -1), Vector2i(T - LINE, 0), not r and not u],
					[Vector2i(-1, 1), Vector2i(0, T - LINE), not l and not d], [Vector2i(1, 1), Vector2i(T - LINE, T - LINE), not r and not d]]:
				if k[2] and _kind(floor_l, walls, c + k[0]) == 1:
					strips.append(Rect2i(o + k[1], Vector2i(LINE, LINE)))
			for s in strips:
				for py in range(s.position.y, s.end.y):
					for px in range(s.position.x, s.end.x):
						mask[py * w + px] = 1
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for py in h:
		for px in w:
			if mask[py * w + px] == 0:
				continue
			var inner := px > 0 and px < w - 1 and py > 0 and py < h - 1 				and mask[py * w + px - 1] == 1 and mask[py * w + px + 1] == 1 				and mask[(py - 1) * w + px] == 1 and mask[(py + 1) * w + px] == 1
			img.set_pixel(px, py, WHITE if inner else DARK)
	return img
