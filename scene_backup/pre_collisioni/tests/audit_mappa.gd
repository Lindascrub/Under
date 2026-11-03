class_name AuditMappa
extends RefCounted
## Il controllo di collisioni e profondità di una stanza già aperta (usato dai test GdUnit in
## tests/gdunit/ e dalle schermate di tests/collisioni/profondita_schermate.gd).
##
## 1. Trova tutti i punti dove i piedi del giocatore (il suo rettangolo vero, 14x6) possono arrivare
##    camminando dall'arrivo, su una griglia di PASSO pixel.
## 2. Per ogni punto raggiunto guarda cosa è disegnato lì (i pixel veri delle immagini) e in che ordine:
##    - sopra_edificio: sei su un edificio o un mobile disegnato SOTTO di te (Decori, Terra...)
##    - dentro_base:    sei nella base di un oggetto del Mondo: lì ci vuole la collisione
##    - copre_tutto:    un oggetto disegnato SOPRA a tutto (fuori dal Mondo) ti copre il corpo
##    - ordine:         nel Mondo l'oggetto si ordina da un punto lontano dai suoi piedi, quindi ti
##                      copre (o ti passa dietro) quando non dovrebbe
## Un oggetto si può segnare come "si cammina sopra" con il metadato calpestabile = true.

const PASSO := 4
## Quanto è alto un oggetto disegnato sotto perché sia un edificio o un mobile (non un tappeto).
const ALTO := 28
## Il giocatore visto dall'alto: piedi in basso, testa 30 px più su.
const CORPO := Rect2(-6, -28, 12, 26)

var room: Room
var reach := {}
var problems := {"sopra_edificio": {}, "dentro_base": {}, "copre_tutto": {}, "ordine": {}}
var _space: PhysicsDirectSpaceState2D
var _query := PhysicsShapeQueryParameters2D.new()
var _images := {}
var _bounds := Rect2()


func _init(r: Room) -> void:
	room = r
	_space = r.get_world_2d().direct_space_state
	var feet := RectangleShape2D.new()
	feet.size = Vector2(14, 6)
	_query.shape = feet
	_query.collision_mask = r.player.collision_mask
	_query.exclude = [r.player.get_rid()]
	_bounds = r.cam_rect.grow(24) if r.cam_rect.size != Vector2.ZERO else Rect2(Vector2.ZERO, Vector2(r.map_size * Room.T))


## I piedi in `p` non toccano niente di solido?
func free_at(p: Vector2) -> bool:
	_query.transform = Transform2D(0, p + Vector2(0, -3))
	return _space.intersect_shape(_query, 1).is_empty()


## Tutti i punti raggiungibili camminando da `starts` (in pixel del mondo).
func flood(starts: Array) -> void:
	reach.clear()
	var todo: Array[Vector2i] = []
	for s: Vector2 in starts:
		var c := Vector2i((s / PASSO).round())
		# un arrivo dentro una sedia o un tornello: si parte dalla casella libera più vicina
		for r in 4:
			var found := false
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					var k := c + Vector2i(dx, dy)
					if not reach.has(k) and _bounds.has_point(Vector2(k * PASSO)) and free_at(Vector2(k * PASSO)):
						reach[k] = true
						todo.append(k)
						found = true
						break
				if found:
					break
			if found:
				break
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n := c + d
			if reach.has(n):
				continue
			var p := Vector2(n * PASSO)
			if not _bounds.has_point(p):
				continue
			# anche a metà strada: niente passaggi più stretti del passo
			if free_at(p) and free_at((Vector2(c * PASSO) + p) / 2.0):
				reach[n] = true
				todo.append(n)


func points() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for k: Vector2i in reach:
		out.append(Vector2(k * PASSO))
	return out


## Il controllo vero: riempie `problems` (per tipo: percorso del nodo -> un punto d'esempio).
func check() -> void:
	var mondo := room.get_node_or_null("Mondo") as Node2D
	var pts := points()
	for s in _sprites():
		var info := _layer(s, mondo)
		if info == "":
			continue
		var r := _opaque_rect(s)
		if r.size.y < 4:
			continue
		var path := str(room.get_path_to(s))
		match info:
			"sotto":
				if r.size.y < ALTO:
					continue
				for p in pts:
					# ai piedi dell'edificio si può stare (si è davanti); più su no
					if p.y < r.end.y - 6 and r.has_point(p) and _opaque(s, p):
						problems["sopra_edificio"][path] = p
						break
			"mondo":
				var band := clampf(r.size.y * 0.25, 4.0, 12.0)
				for p in pts:
					if p.y >= r.end.y - band and p.y <= r.end.y and r.has_point(p) and _opaque(s, p):
						problems["dentro_base"][path] = p
						break
				# l'oggetto si ordina da sort_y ma i suoi piedi sono a r.end.y: chi sta in mezzo, e lo tocca
				# col corpo, viene disegnato dalla parte sbagliata
				var sort_y := _sort_node(s, mondo).global_position.y
				if r.size.y >= 10 and absf(sort_y - r.end.y) > 6.0:
					var lo := minf(sort_y, r.end.y) + 2.0
					var hi := maxf(sort_y, r.end.y) - 2.0
					for p in pts:
						if p.y > lo and p.y < hi and r.intersects(Rect2(p + CORPO.position, CORPO.size)) \
								and (_opaque(s, p + Vector2(0, -8)) or _opaque(s, p + Vector2(0, -20)) or _opaque(s, p + Vector2(4, -14)) or _opaque(s, p + Vector2(-4, -14))):
							problems["ordine"][path] = p
							break
			"sopra":
				for p in pts:
					if r.intersects(Rect2(p + CORPO.position, CORPO.size)) and (_opaque(s, p + Vector2(0, -8)) or _opaque(s, p + Vector2(0, -20))):
						problems["copre_tutto"][path] = p
						break


func count() -> int:
	var n := 0
	for k: String in problems:
		n += (problems[k] as Dictionary).size()
	return n


func report() -> String:
	var lines: Array[String] = []
	for k: String in problems:
		for path: String in problems[k]:
			lines.append("%s  %s  %s" % [k, path, str(problems[k][path])])
	lines.sort()
	return "\n".join(lines)


# --- i disegni della stanza ---------------------------------------------------------------------------

func _sprites() -> Array[Sprite2D]:
	var out: Array[Sprite2D] = []
	for n in room.find_children("*", "Sprite2D", true, false):
		var s := n as Sprite2D
		if s.texture == null or not s.is_visible_in_tree() or _skip(s):
			continue
		out.append(s)
	return out


func _skip(n: Node) -> bool:
	var a := n
	while a and a != room:
		if a is Player or a is Npc or a is CanvasLayer or bool(a.get_meta("calpestabile", false)):
			return true
		# le scale si salgono: sono fatte per stare "sopra"
		if a.scene_file_path.begins_with("res://world/stairs") or str(a.name).begins_with("Scale"):
			return true
		a = a.get_parent()
	return false


## "sotto", "mondo" (ordinato coi piedi) o "sopra" rispetto al giocatore.
func _layer(s: Sprite2D, mondo: Node2D) -> String:
	var z := 0
	var a: Node = s
	while a and a != room:
		if a is CanvasItem:
			z += (a as CanvasItem).z_index
			if not (a as CanvasItem).z_as_relative:
				break
		a = a.get_parent()
	if z > 0:
		return "sopra"
	if z < 0:
		return "sotto"
	if mondo == null:
		return ""
	if s == mondo or mondo.is_ancestor_of(s):
		return "mondo"
	var top: Node = s
	while top.get_parent() != room:
		top = top.get_parent()
	return "sopra" if top.get_index() > mondo.get_index() else "sotto"


## Il nodo che il Mondo ordina: lo sprite se il suo genitore è ordinato per y, se no il primo antenato che lo è.
func _sort_node(s: Node2D, mondo: Node2D) -> Node2D:
	var a: Node2D = s
	while a.get_parent() != mondo and a.get_parent() is Node2D and not (a.get_parent() as Node2D).y_sort_enabled:
		a = a.get_parent()
	return a


func _image(t: Texture2D) -> Image:
	if not _images.has(t):
		var img := t.get_image()
		if img and img.is_compressed():
			img.decompress()
		_images[t] = img
	return _images[t]


## Il pixel dell'immagine sotto il punto del mondo `p` è pieno?
func _opaque(s: Sprite2D, p: Vector2) -> bool:
	var local := s.global_transform.affine_inverse() * p
	var rect := s.get_rect()
	if not rect.has_point(local):
		return false
	var img := _image(s.texture)
	if img == null:
		return true
	var px := local - rect.position
	if s.flip_h:
		px.x = rect.size.x - 1 - px.x
	if s.flip_v:
		px.y = rect.size.y - 1 - px.y
	var origin := Vector2.ZERO
	if s.region_enabled:
		origin = s.region_rect.position
	if s.hframes > 1 or s.vframes > 1:
		origin += Vector2(s.frame % s.hframes, s.frame / s.hframes) * rect.size
	var q := Vector2i(origin + px)
	if q.x < 0 or q.y < 0 or q.x >= img.get_width() or q.y >= img.get_height():
		return false
	return img.get_pixelv(q).a > 0.5


## Il rettangolo (nel mondo) dei pixel pieni dello sprite.
func _opaque_rect(s: Sprite2D) -> Rect2:
	var rect := s.get_rect()
	var img := _image(s.texture)
	var used := Rect2(Vector2.ZERO, rect.size)
	if img:
		var origin := s.region_rect.position if s.region_enabled else Vector2.ZERO
		if s.hframes > 1 or s.vframes > 1:
			origin += Vector2(s.frame % s.hframes, s.frame / s.hframes) * rect.size
		var src := Rect2i(Vector2i(origin), Vector2i(rect.size)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		if src.size.x <= 0 or src.size.y <= 0:
			return Rect2()
		var u := img.get_region(src).get_used_rect()
		used = Rect2(u)
		if s.flip_h:
			used.position.x = rect.size.x - used.end.x
		if s.flip_v:
			used.position.y = rect.size.y - used.end.y
	var a := s.global_transform * (rect.position + used.position)
	var b := s.global_transform * (rect.position + used.end)
	return Rect2(a, b - a).abs()


# --- per le schermate -----------------------------------------------------------------------------------

## Gli oggetti del Mondo abbastanza alti da coprire qualcuno.
func tall_world_sprites() -> Array[Sprite2D]:
	var out: Array[Sprite2D] = []
	var mondo := room.get_node_or_null("Mondo") as Node2D
	for s in _sprites():
		if _layer(s, mondo) == "mondo" and _opaque_rect(s).size.y >= 12:
			out.append(s)
	return out


## Un punto raggiunto subito dietro (side -1) o subito davanti (side 1) ai piedi dell'oggetto.
func near_point(s: Sprite2D, side: int) -> Vector2:
	var r := _opaque_rect(s)
	var best := Vector2.INF
	var best_d := INF
	for p in points():
		if p.x < r.position.x or p.x > r.end.x:
			continue
		var d := (r.end.y - p.y) if side < 0 else (p.y - r.end.y)
		if d < 4.0 or d > 24.0:
			continue
		var dd := absf(p.x - r.get_center().x) + d
		if dd < best_d:
			best_d = dd
			best = p
	return best
