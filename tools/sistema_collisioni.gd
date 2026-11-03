extends Node
## Sistema DENTRO le scene da editor collisioni e ordine di disegno trovati da tests/collisioni/rapporto.tscn.
## Dopo, tutto si ritocca a mano nell'editor: sono nodi e forme vere.
##   base:         l'oggetto si ordina dai suoi piedi veri (il pixel pieno più in basso) e ha una collisione
##                 alla base, larga come la sua base e profonda circa metà (vedi AuditMappa.base_depth).
##                 "percorso:4" = profonda 4 px (per cordoni e panchine, più larghi che profondi);
##                 "percorso:basso" = un oggetto basso ma grosso (carretto, cassonetto, fontana): profondo
##                 quanto serve perché da dietro si veda la testa (altezza - 18)
##   forme:        {forma: Rect2 nel mondo}: una forma che c'è già, rifatta di questa misura
##   calpestabile: tappeti, strisce, prati: ci si cammina sopra (metadato calpestabile)
##   in_decori:    cose appese al muro: sotto a chi passa davanti
##   in_mondo:     cose che stavano sopra a tutto: ora si ordinano coi piedi
##   dentro:       [nodo, nuovo genitore]: un pezzo che fa parte di un altro oggetto (la cartella sul mobile)
##   muri:         {nome: [Rect2 nel mondo...]}: un corpo solido nel Mondo (lo crea o ne rifà le forme)
##   via:          nodi da togliere
## Esegui:  Godot --headless --path . res://tools/sistema_collisioni.tscn [-- --solo=citta]

const FIX := {
	"res://chapters/c1/fondo.tscn": {
		"in_decori": ["Mondo/Telecamera_304", "Mondo/Telecamera_496"],
		"base": ["Mondo/CycletteDinamo", "Mondo/Palloncino5", "Mondo/PiantaBadge1", "Mondo/ScatolaLampadine1", "Mondo/ScatolaLampadine2"],
	},
	"res://chapters/c2/sottoufficio.tscn": {
		"in_decori": ["Mondo/Telecamera_192", "Mondo/Telecamera_432"],
		"base": ["Mondo/Pianta1", "Mondo/Pianta5"],
	},
	"res://chapters/c3/mercato.tscn": {
		"base": ["Mondo/CarrelloCliente2", "Mondo/PiantaUfficio1", "Mondo/ScatolaAmir2", "Mondo/Frutta4:basso", "Mondo/Frutta5:basso"],
		# fra i due pezzi di ogni scaffale c'era una fessura di 10 px dove ci si infilava
		"forme": {
			"Mondo/Corsia0A/Collisione/@CollisionShape2D@31": Rect2(150.5, 104, 18.5, 47),
			"Mondo/Corsia1A/Collisione/@CollisionShape2D@33": Rect2(213, 104, 20, 48),
			"Mondo/Corsia2A/Collisione/@CollisionShape2D@35": Rect2(278, 104, 19, 48),
		},
	},
	"res://chapters/c4/banca.tscn": {
		"calpestabile": ["Decori/BasementSingles227", "Decori/BasementSingles228", "Decori/TappetoMarrone0",
			"Decori/TappetoMarrone1", "Decori/TappetoMarrone2", "Decori/TappetoMarrone3"],
		"in_decori": ["HospitalSingles69", "Mondo/Telecamera_320", "Mondo/Telecamera_608"],
		"in_mondo": ["Mondo/Divano1/Collisione/HospitalSingles37", "Mondo/Divano1/Collisione/HospitalSingles50"],
		"base": ["Mondo/Cordone0:4", "Mondo/Cordone1:4", "Mondo/Leggio", "Mondo/HospitalSingles127", "Mondo/HospitalSingles130",
			"Mondo/HospitalSingles131", "Mondo/PiantaAttesa", "Mondo/PiantaUfficio", "Mondo/Divano1",
			"Mondo/HospitalSingles37", "Mondo/HospitalSingles50"],
		# fra la scrivania e la sua sedia restavano 7 px: ci si infilava in diagonale
		"forme": {"Mondo/ConferenceHallSingles64/Collisione/Ingombro": Rect2(274, 242, 14, 14)},
	},
	"res://chapters/c5/citta.tscn": {
		"calpestabile": ["Terra", "PratoParco"],
		"in_mondo": ["Tree2"],
		"muri": {
			# la torre: tutto il palazzo fino alla facciata; le scale restano aperte (195..221)
			"Torre": [Rect2(-80, -140, 311, 228), Rect2(-80, 88, 272, 24)],
			"TorreAngolo": [Rect2(-80, 112, 111, 41)],
			"DietroScala": [Rect2(144, 112, 48, 42)],
			# la casa comune: si entra solo dalla porta (256..288, fra CasaSinistra e CasaDestra)
			"CasaComune": [Rect2(224, -140, 96, 284)],
			# la fessura fra due palazzi a destra (771..786): ci si entrava di qualche pixel
			"FessuraPalazzi": [Rect2(771, 148, 15, 8)],
		},
		# stava sopra le scale e non si poteva salire
		"via": ["Mondo/TorreDestra"],
		"base": ["Mondo/Tree2", "Mondo/Fontana:basso", "Mondo/Idrante", "Mondo/ModernExteriorsSinglesBasketballBasket1",
			"Mondo/ModernExteriorsSinglesBin5", "Mondo/ModernExteriorsSinglesBin7", "Mondo/ModernExteriorsSinglesCandyCart2",
			"Mondo/ModernExteriorsSinglesDumpster1", "Mondo/ModernExteriorsSinglesDumpsterOpen2:basso", "Mondo/ModernExteriorsSinglesDumpsterOpen4:basso",
			"Mondo/ModernExteriorsSinglesGarageSalesTable3", "Mondo/ModernExteriorsSinglesGarageSalesTable4",
			"Mondo/ModernExteriorsSinglesHydrant1", "Mondo/ModernExteriorsSinglesHydrant2", "Mondo/ModernExteriorsSinglesLemonadeStand2:basso",
			"Mondo/ModernExteriorsSinglesMailbox1", "Mondo/ModernExteriorsSinglesOtherSigns1", "Mondo/ModernExteriorsSinglesOtherSigns2",
			"Mondo/ModernExteriorsSinglesOtherSigns3", "Mondo/ModernExteriorsSinglesOtherSigns4", "Mondo/ModernExteriorsSinglesOtherSigns5",
			"Mondo/ModernExteriorsSinglesParkSlide1", "Mondo/ModernExteriorsSinglesParkSwing1",
			"Mondo/ModernExteriorsSinglesPortableBathroom1", "Mondo/ModernExteriorsSinglesPortableBathroom4",
			"Mondo/ModernExteriorsSinglesShopShoppingCenterTrolleyShelter1", "Mondo/ModernExteriorsSinglesTrafficCone2",
			"Mondo/ModernExteriorsSinglesTrafficSigns25", "Mondo/Tabellone", "Mondo/ModernExteriorsSinglesInfoSign1",
			"Mondo/ModernExteriorsSinglesStreetLamp4", "Mondo/ModernExteriorsSinglesStreetLamp6", "Mondo/ModernExteriorsSinglesStoplight2",
			"Mondo/ModernExteriorsSinglesCandyCart2:basso", "Mondo/ModernExteriorsSinglesParkSlide1:basso"],
	},
	"res://chapters/c5/casa_comune.tscn": {
		"dentro": [["Mondo/CartellaB4", "Mondo/Cassettiera"]],
		"base": ["Mondo/Cassettiera", "Mondo/ClassroomAndLibrarySingles26", "Mondo/ClassroomAndLibrarySingles26b",
			"Mondo/ClassroomAndLibrarySingles27"],
	},
	"res://chapters/c6/cima.tscn": {
		"in_decori": ["Decori/Finestra", "Decori/Specchio0", "Decori/Specchio1", "Decori/Specchio2", "Decori/SpecchioAscensore",
			"Decori/InsegnaAscensore", "Decori/Ritratto0", "Decori/Ritratto1"],
		"base": ["Mondo/Lampada", "Mondo/Palma", "Mondo/Pianta0", "Mondo/Pianta2", "Mondo/ScatoleDinamo", "Mondo/Stampante",
			"Mondo/VasoCorridoio0", "Mondo/VasoCorridoio1", "Mondo/ArchivioDebito:basso"],
	},
}

var _images := {}
var _props := {}
var _baker: Node


func _ready() -> void:
	var solo := ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--solo="):
			solo = a.trim_prefix("--solo=")
	_props = JSON.parse_string(FileAccess.get_file_as_string("res://data/props.json"))
	_baker = load("res://tools/bake_footprints.gd").new()
	for path: String in FIX:
		if solo != "" and not path.contains(solo):
			continue
		var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
		var ops: Dictionary = FIX[path]
		for p: String in ops.get("calpestabile", []):
			_need(root, p).set_meta("calpestabile", true)
		# si può rilanciare: chi è già stato spostato si trova al suo posto nuovo
		for p: String in ops.get("in_decori", []):
			var n := _moved(root, p, "Decori")
			if n.get_parent() != root.get_node("Decori"):
				_move(root, n, root.get_node("Decori"))
			n.z_index = 0
		for p: String in ops.get("in_mondo", []):
			var n := _moved(root, p, "Mondo")
			if n.get_parent() != root.get_node("Mondo"):
				_move(root, n, root.get_node("Mondo"))
			n.z_index = 0
		for pair: Array in ops.get("dentro", []):
			var n := _moved(root, pair[0], pair[1])
			if n.get_parent() != root.get_node(pair[1]):
				_move(root, n, _need(root, pair[1]))
			n.z_index = 0
		var walls: Dictionary = ops.get("muri", {})
		for wall_name: String in walls:
			_wall(root, wall_name, walls[wall_name])
		for p: String in ops.get("via", []):
			var n := root.get_node_or_null(p)
			if n:
				n.get_parent().remove_child(n)
				n.free()
		var forme: Dictionary = ops.get("forme", {})
		for p: String in forme:
			_set_shape(_need(root, p) as CollisionShape2D, forme[p])
		for spec: String in ops.get("base", []):
			var parts := spec.split(":")
			var how := parts[1] if parts.size() > 1 else ""
			_base(root, _need(root, parts[0]) as Node2D, -2.0 if how == "basso" else (float(how) if how != "" else -1.0))
		var packed := PackedScene.new()
		var err := packed.pack(root)
		if err == OK:
			err = ResourceSaver.save(packed, path)
		print("SISTEMATA ", path, " -> ", error_string(err))
		root.free()
	_baker.free()
	get_tree().quit()


func _need(root: Node, p: String) -> Node:
	var n := root.get_node_or_null(p)
	assert(n != null, "manca " + p)
	if n == null:
		push_error("manca " + p)
	return n


func _moved(root: Node, p: String, to: String) -> Node2D:
	var n := root.get_node_or_null(p)
	if n == null:
		n = root.get_node_or_null(to + "/" + p.get_file())
	return _need(root, p) if n == null else n


# --- spostare nodi tenendoli dove si vedono ------------------------------------------------------------

func _xf(n: Node) -> Transform2D:
	var t := Transform2D.IDENTITY
	var a := n
	while a != null and a.get_parent() != null:
		if a is Node2D:
			t = (a as Node2D).transform * t
		a = a.get_parent()
	return t


func _move(root: Node, n: Node2D, to: Node) -> void:
	var g := _xf(n)
	var owned: Array[Node] = [n]
	for c in n.find_children("*", "", true, false):
		if c.owner == root:
			owned.append(c)
	for c in owned:
		c.owner = null
	n.get_parent().remove_child(n)
	to.add_child(n)
	n.transform = _xf(to).affine_inverse() * g
	for c in owned:
		c.owner = root
	if n.name != n.name.validate_node_name():
		n.name = n.name.validate_node_name()


# --- muri ---------------------------------------------------------------------------------------------

func _wall(root: Node, wall_name: String, rects: Array) -> void:
	var mondo := root.get_node("Mondo")
	var body := mondo.get_node_or_null(wall_name) as StaticBody2D
	if body == null:
		body = StaticBody2D.new()
		body.name = wall_name
		mondo.add_child(body)
		body.owner = root
		body.position = (rects[0] as Rect2).get_center().round()
	for c in body.get_children():
		if c is CollisionShape2D or c is CollisionPolygon2D:
			body.remove_child(c)
			c.free()
	var inv := _xf(body).affine_inverse()
	var i := 0
	for r: Rect2 in rects:
		var shape := CollisionShape2D.new()
		shape.name = "Forma" if i == 0 else "Forma%d" % (i + 1)
		var rect := RectangleShape2D.new()
		rect.size = r.size
		shape.shape = rect
		shape.position = inv * r.get_center()
		body.add_child(shape)
		shape.owner = root
		i += 1


# --- la base degli oggetti --------------------------------------------------------------------------

func _base(root: Node, g: Node2D, depth: float) -> void:
	# l'ingombro di data/props.json, se c'è, entra nella scena prima (come tools/bake_footprints.gd)
	if g is Sprite2D and not g.has_meta("footprint_applied"):
		var entry: Variant = _props.get(_baker.call("_key", g))
		if entry is Dictionary and (entry as Dictionary).has("footprint"):
			_baker.call("_bake", root, g, entry["footprint"])
	var members := _members(g)
	var r := _group_rect(members)
	if r.size.y < 2:
		push_warning("vuoto: " + str(root.get_path_to(g)))
		return
	var span := _bottom_span(members, r)
	var low := depth == -2.0
	if depth < 0:
		depth = clampf(minf((span.y - span.x) * 0.5, r.size.y * 0.3), 2.0, 12.0)
	if low:
		# da dietro si vede la testa: il giocatore è alto 28, la testa resta fuori di 10 px
		depth = clampf(maxf(depth, r.size.y - 18.0), 2.0, r.size.y - 2.0)
	var deep := ceilf(depth) + 1.0
	var base := Rect2(span.x, r.end.y - deep, span.y - span.x, deep)
	# i piedi dell'oggetto: il suo punto di ordine va sul pixel pieno più in basso
	var gx := _xf(g)
	var target := roundf(r.end.y)
	var delta := target - gx.origin.y
	if absf(delta) > 1.5:
		var parent_scale := _xf(g.get_parent()).get_scale().y if g.get_parent() is Node2D else 1.0
		var own := gx.get_scale().y
		g.position.y += delta / parent_scale
		if g is Sprite2D:
			(g as Sprite2D).offset.y -= delta / own
		for c in g.get_children():
			if c is Node2D:
				(c as Node2D).position.y -= delta / own
	# la collisione alla base
	var body: StaticBody2D = null
	for c in g.get_children():
		if c is StaticBody2D:
			body = c
			break
	if body == null:
		body = StaticBody2D.new()
		body.name = "Collisione"
		g.add_child(body)
		body.owner = root
	var shapes: Array[CollisionShape2D] = []
	var others := 0
	for c in body.get_children():
		if c is CollisionShape2D and (c as CollisionShape2D).shape is RectangleShape2D:
			shapes.append(c)
		elif c is CollisionShape2D or c is CollisionPolygon2D:
			others += 1
	var inv := _xf(body).affine_inverse()
	if shapes.size() == 1 and others == 0:
		var s := shapes[0]
		var e := _shape_rect(s)
		# se la forma di prima sta già sulla base la si allarga, se sta altrove (spostata) si rifà
		var over := e.intersection(base)
		var want := e.merge(base) if over.get_area() >= base.get_area() * 0.5 else base
		var rect := RectangleShape2D.new()
		rect.size = want.size
		s.shape = rect
		s.position = inv * want.get_center()
	else:
		var covered := false
		for s in shapes:
			if _shape_rect(s).grow(1).encloses(base):
				covered = true
		if not covered:
			var s := CollisionShape2D.new()
			s.name = "Base"
			var rect := RectangleShape2D.new()
			rect.size = base.size
			s.shape = rect
			s.position = inv * base.get_center()
			body.add_child(s)
			s.owner = root
	if g is Sprite2D:
		g.set_meta("footprint_applied", true)


func _set_shape(s: CollisionShape2D, want: Rect2) -> void:
	var rect := RectangleShape2D.new()
	rect.size = want.size
	s.shape = rect
	s.position = _xf(s.get_parent()).affine_inverse() * want.get_center()


func _shape_rect(s: CollisionShape2D) -> Rect2:
	var r := (s.shape as RectangleShape2D).get_rect()
	var t := _xf(s)
	var a := t * r.position
	var b := t * r.end
	return Rect2(a, b - a).abs()


func _members(g: Node2D) -> Array:
	var out: Array = []
	if g is Sprite2D and (g as Sprite2D).texture and g.visible:
		out.append(g)
	for c in g.find_children("*", "Sprite2D", true, false):
		var s := c as Sprite2D
		if s.texture and s.visible:
			out.append(s)
	return out


# --- i pixel (come AuditMappa, ma su una scena che non è nell'albero) --------------------------------

func _image(t: Texture2D) -> Image:
	if not _images.has(t):
		var img := t.get_image()
		if img and img.is_compressed():
			img.decompress()
		_images[t] = img
	return _images[t]


func _opaque(s: Sprite2D, p: Vector2) -> bool:
	var local := _xf(s).affine_inverse() * p
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


func _opaque_any(members: Array, p: Vector2) -> bool:
	for m: Sprite2D in members:
		if _opaque(m, p):
			return true
	return false


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
		used = Rect2(img.get_region(src).get_used_rect())
		if s.flip_h:
			used.position.x = rect.size.x - used.end.x
		if s.flip_v:
			used.position.y = rect.size.y - used.end.y
	var t := _xf(s)
	var a := t * (rect.position + used.position)
	var b := t * (rect.position + used.end)
	return Rect2(a, b - a).abs()


func _group_rect(members: Array) -> Rect2:
	var r := Rect2()
	for m: Sprite2D in members:
		var mr := _opaque_rect(m)
		if mr.size == Vector2.ZERO:
			continue
		r = mr if r.size == Vector2.ZERO else r.merge(mr)
	return r


func _bottom_span(members: Array, r: Rect2) -> Vector2:
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
