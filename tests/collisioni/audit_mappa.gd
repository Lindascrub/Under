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
## Un oggetto più basso di così (un carretto, un cassonetto, una fontana) non nasconde mai tutto il
## giocatore: da dietro si vede almeno la testa.
const BASSO := 44
## Il giocatore visto dall'alto: piedi in basso, testa 30 px più su.
const CORPO := Rect2(-6, -28, 12, 26)

var room: Room
var reach := {}
## Le uscite (le zone che portano in un'altra stanza): ci si arriva, ma lì la stanza finisce.
var exits: Array[Rect2] = []
## Per ogni uscita, se a piedi ci si arriva.
var exits_reached := {}
var problems := {"sopra_edificio": {}, "dentro_base": {}, "copre_tutto": {}, "ordine": {}, "nasconde": {}}
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
	# le macchine passano: dove sono adesso non conta
	var skip: Array[RID] = [r.player.get_rid()]
	for car in r.find_children("*", "Car", true, false):
		skip.append((car as CollisionObject2D).get_rid())
	_query.exclude = skip
	for a in r.get_children():
		if a is Area2D:
			for c in a.get_children():
				if c is CollisionShape2D and (c as CollisionShape2D).shape is RectangleShape2D:
					var sr := ((c as CollisionShape2D).shape as RectangleShape2D).get_rect()
					exits.append(Rect2((c as CollisionShape2D).global_position + sr.position, sr.size))
	_bounds = r.cam_rect.grow(24) if r.cam_rect.size != Vector2.ZERO else Rect2(Vector2.ZERO, Vector2(r.map_size * Room.T))


## I piedi in `p` non toccano niente di solido?
func free_at(p: Vector2) -> bool:
	_query.transform = Transform2D(0, p + Vector2(0, -3))
	return _space.intersect_shape(_query, 1).is_empty()


## I piedi in `p` sono su un'uscita? (-1 = no)
func exit_at(p: Vector2) -> int:
	var feet := Rect2(p + Vector2(-7, -6), Vector2(14, 6))
	for i in exits.size():
		if exits[i].intersects(feet):
			return i
	return -1


## Tutti i punti raggiungibili camminando da `starts` (in pixel del mondo). Chi arriva su un'uscita
## esce: quel punto non conta e da lì non si va avanti.
func flood(starts: Array) -> void:
	reach.clear()
	exits_reached.clear()
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
			if not free_at(p):
				# contro il muro si arriva al pixel: una porta può essere lì, a meno di un passo
				for t in range(1, PASSO):
					var q := Vector2(c * PASSO) + Vector2(d) * t
					if not free_at(q):
						break
					if exit_at(q) >= 0:
						exits_reached[exit_at(q)] = true
				continue
			# anche a metà strada: niente passaggi più stretti del passo
			if free_at((Vector2(c * PASSO) + p) / 2.0):
				var e := exit_at(p)
				if e >= 0:
					exits_reached[e] = true
					continue
				reach[n] = true
				todo.append(n)


## Da `start` si arriva a piedi fino a `end` passando solo per posti liberi, a passi di 1 px?
## (Più preciso della griglia: trova anche le fessure strette fra due mobili.)
func walk_reaches(start: Vector2, end: Vector2, radius := 32) -> bool:
	var s := Vector2i(start.round())
	var goal := Vector2i(end.round())
	var box := Rect2i(s - Vector2i(radius, radius), Vector2i(radius, radius) * 2 + Vector2i.ONE)
	if not box.has_point(goal):
		return false
	var seen := {s: true}
	var todo: Array[Vector2i] = [s]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		if (c - goal).abs().x <= 1 and (c - goal).abs().y <= 1:
			return true
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n := c + d
			if seen.has(n) or not box.has_point(n):
				continue
			seen[n] = true
			if free_at(Vector2(n)):
				todo.append(n)
	return false


## A piedi si arriva a toccare `area` (un rettangolo nel mondo)?
func touches(area: Rect2) -> bool:
	for k: Vector2i in reach:
		if area.intersects(Rect2(Vector2(k * PASSO) + Vector2(-7, -6), Vector2(14, 6))):
			return true
	return false


## Il rettangolo nel mondo della prima forma di un'area (la cima delle scale, una porta).
static func area_rect(a: Area2D) -> Rect2:
	for c in a.get_children():
		if c is CollisionShape2D and (c as CollisionShape2D).shape is RectangleShape2D:
			var r := ((c as CollisionShape2D).shape as RectangleShape2D).get_rect()
			return Rect2((c as CollisionShape2D).global_position + r.position, r.size)
	return Rect2()


## I punti raggiunti, senza quelli sulle uscite (chi arriva lì da una porta ci sta solo un attimo).
func points() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for k: Vector2i in reach:
		if exit_at(Vector2(k * PASSO)) < 0:
			out.append(Vector2(k * PASSO))
	return out


## Il controllo vero: riempie `problems` (per tipo: percorso del nodo -> un punto d'esempio).
func check() -> void:
	var mondo := room.get_node_or_null("Mondo") as Node2D
	var pts := points()
	# nel Mondo un oggetto fatto di più pezzi (la cassetta con la frutta sopra) si guarda tutto insieme:
	# si ordina da un punto solo, quello del nodo che il Mondo ordina
	var groups := {}
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
				var g := _sort_node(s, mondo)
				if not groups.has(g):
					groups[g] = []
				groups[g].append(s)
			"sopra":
				for p in pts:
					if r.intersects(Rect2(p + CORPO.position, CORPO.size)) and (_opaque(s, p + Vector2(0, -8)) or _opaque(s, p + Vector2(0, -20))):
						problems["copre_tutto"][path] = p
						break
	for g: Node2D in groups:
		_check_group(g, groups[g], pts)


## Un oggetto del Mondo (uno o più sprite ordinati insieme).
func _check_group(g: Node2D, members: Array, pts: Array[Vector2]) -> void:
	var r := group_rect(members)
	if r.size.y < 4:
		return
	var path := str(room.get_path_to(g))
	var band := base_depth(members, r)
	var bottoms := {}
	for p in pts:
		if not r.has_point(p) or not _opaque_any(members, p):
			continue
		var x := int(p.x)
		if not bottoms.has(x):
			bottoms[x] = _column_bottom(members, p.x, r)
		var b: float = bottoms[x]
		# chi ha la base sotto i piedi dei pezzi che stanno in alto (l'insegna di un palo) non conta;
		# le colonne che arrivano a terra (anche fra due ruote) hanno la base sul fondo dell'oggetto
		if b < r.end.y - 8.0:
			continue
		if p.y > r.end.y - band + 1.0 and p.y <= r.end.y:
			problems["dentro_base"][path] = p
			break
	# l'oggetto si ordina da sort_y ma i suoi piedi sono a r.end.y: chi sta in mezzo, e lo tocca
	# col corpo, viene disegnato dalla parte sbagliata
	var sort_y := g.global_position.y
	if r.size.y >= 10 and absf(sort_y - r.end.y) > 6.0:
		var lo := minf(sort_y, r.end.y) + 2.0
		var hi := maxf(sort_y, r.end.y) - 2.0
		for p in pts:
			if p.y > lo and p.y < hi and r.intersects(Rect2(p + CORPO.position, CORPO.size)) 					and (_opaque_any(members, p + Vector2(0, -8)) or _opaque_any(members, p + Vector2(0, -20))
					or _opaque_any(members, p + Vector2(4, -14)) or _opaque_any(members, p + Vector2(-4, -14))):
				problems["ordine"][path] = p
				break
	# chi sta dietro un oggetto basso resta coperto solo in basso: se piedi e testa sono coperti tutti e
	# due, la collisione è troppo corta e si è finiti dentro l'oggetto
	if r.size.y <= BASSO:
		for p in pts:
			if p.y < sort_y and r.has_point(p + Vector2(0, -3)) and _covers(members, p):
				problems["nasconde"][path] = p
				break


## Quanto è profondo l'oggetto sul pavimento, visto di 3/4: circa metà della larghezza in basso, ma non
## più di un terzo dell'altezza. Un palo è profondo 2 px, un cordone 5, una cassetta 8, una scrivania 12.
func base_depth(members: Array, r: Rect2) -> float:
	return clampf(minf(_bottom_width(members, r) * 0.5, r.size.y * 0.3), 2.0, 12.0)


## Le colonne piene nella parte bassa: [prima x, ultima x + 1] nel mondo.
func bottom_span(members: Array, r: Rect2) -> Vector2:
	var rows := clampf(r.size.y * 0.25, 2.0, 8.0)
	var lo := INF
	var hi := -INF
	var x := floorf(r.position.x) + 0.5
	while x < r.end.x:
		var y := r.end.y - 0.5
		while y > r.end.y - rows:
			if _opaque_any(members, Vector2(x, y)):
				lo = minf(lo, x - 0.5)
				hi = maxf(hi, x + 0.5)
				break
			y -= 1.0
		x += 1.0
	return Vector2(lo, hi)


## Il rettangolo dei pixel pieni di tutti i pezzi.
func group_rect(members: Array) -> Rect2:
	var r := Rect2()
	for m: Sprite2D in members:
		var mr := _opaque_rect(m)
		r = mr if r.size == Vector2.ZERO else r.merge(mr)
	return r


## Piedi e testa coperti in tutta la larghezza del corpo (un palo sottile copre solo una riga in mezzo).
func _covers(members: Array, p: Vector2) -> bool:
	for dx: float in [-4.0, 0.0, 4.0]:
		if not _opaque_any(members, p + Vector2(dx, -3)) or not _opaque_any(members, p + Vector2(dx, -24)):
			return false
	return true


func _opaque_any(members: Array, p: Vector2) -> bool:
	for m: Sprite2D in members:
		if _opaque(m, p):
			return true
	return false


## Il pixel pieno più in basso della colonna x.
func _column_bottom(members: Array, x: float, r: Rect2) -> float:
	var y := floorf(r.end.y) - 0.5
	while y > r.position.y:
		if _opaque_any(members, Vector2(x, y)):
			return y + 0.5
		y -= 1.0
	return r.end.y


## Quante colonne sono piene nella parte bassa dell'oggetto (gli ultimi 8 px al massimo).
func _bottom_width(members: Array, r: Rect2) -> float:
	var rows := clampf(r.size.y * 0.25, 2.0, 8.0)
	var n := 0
	var x := floorf(r.position.x) + 0.5
	while x < r.end.x:
		var y := r.end.y - 0.5
		while y > r.end.y - rows:
			if _opaque_any(members, Vector2(x, y)):
				n += 1
				break
			y -= 1.0
		x += 1.0
	return float(n)


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
		if a is Player or a is Npc or a is Car or a is CanvasLayer or bool(a.get_meta("calpestabile", false)):
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
