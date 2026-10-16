class_name Room
extends Node2D
## Base di tutte le stanze. Una stanza figlia scrive build() usando:
##   paint(righe, legenda)  -> disegna la mappa da una griglia di caratteri
##   add_prop / add_npc / add_spot / add_exit / block
## e può scrivere enter() per i dialoghi all'ingresso.

const T := 16
## Area visibile del mondo con lo zoom 2x della camera.
const VIEW := Vector2(320, 180)

var map_size := Vector2i.ZERO
## Caratteri della mappa non presenti in legenda: carattere -> celle (per piazzare cose).
var markers: Dictionary = {}
## Punti di arrivo: nome -> posizione dei piedi del giocatore.
var spawns: Dictionary = {}
var spawn_facing: Dictionary = {}
## Quanto la camera può salire sopra la mappa (per mostrare edifici alti).
var camera_top := 0
## Sposta la visuale verso l'alto (per vedere gli edifici sullo sfondo).
var camera_lift := 0
## Musica della stanza (vedi Sound.music) e se è all'aperto (la luce cambia con l'ora).
var music := "quartiere"
var outdoor := false
## Il piano della torre in cui si trova la stanza ("" per le stanze fuori dalla torre).
var floor_id := ""
var player: Player
## Contenitore con y-sort: oggetti e persone si coprono nel giusto ordine.
var world: Node2D

var _tiles: TileMapLayer
var _tileset: TileSet
var _sources: Dictionary = {}
var _solids: StaticBody2D
var _light: CanvasModulate
## Caselle bloccate da muri e oggetti, e caselle già occupate da persone (per non sovrapporle).
var _blocked_cells := {}
var _people_cells := {}
var _grey_rect: ColorRect


func _ready() -> void:
	_tiles = TileMapLayer.new()
	_tileset = TileSet.new()
	_tileset.tile_size = Vector2i(T, T)
	_tiles.tile_set = _tileset
	add_child(_tiles)
	_solids = StaticBody2D.new()
	add_child(_solids)
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	build()
	if floor_id != "":
		GameState.enter_floor(floor_id)
	_spawn_player()
	Ui.show_hud(true)
	Sound.music(music)
	_grey_world()
	if outdoor:
		_light = CanvasModulate.new()
		add_child(_light)
		_update_light()
		GameState.changed.connect(_update_light)
	if Ui.transitioning:
		await Ui.faded_in
	enter()


func build() -> void:
	pass


## Più alto è il LV, più il mondo perde colore. I dialoghi e l'HUD restano a colori.
func _grey_world() -> void:
	if GameState.exploited <= 0 or player == null:
		return
	# Attaccato alla telecamera e sopra a tutto il mondo (ma sotto l'interfaccia, che sta in un altro strato).
	var rect := ColorRect.new()
	rect.size = VIEW + Vector2(8, 8)
	rect.position = -rect.size / 2.0
	rect.z_index = 100
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/grey_world.gdshader")
	mat.set_shader_parameter("amount", minf(0.85, GameState.exploited * 0.22))
	rect.material = mat
	add_child(rect)
	_grey_rect = rect


## Il filtro grigio segue quello che inquadra la telecamera (anche ai bordi della mappa).
func _process(_delta: float) -> void:
	if _grey_rect and player:
		_grey_rect.global_position = player.camera.get_screen_center_position() - _grey_rect.size / 2.0


func _update_light() -> void:
	if _light:
		_light.color = GameState.daylight()


func enter() -> void:
	await show_pending()


func show_pending() -> void:
	if not GameState.pending_lines.is_empty():
		var lines := GameState.pending_lines.duplicate()
		GameState.pending_lines.clear()
		await Ui.say(lines)
	if GameState.boss_call_pending():
		await _boss_call()


## Il posto di lavoro del lavoro assegnato oggi, se si trova in questa stanza.
func add_station(room_key: String) -> void:
	for j: Dictionary in GameState.jobs_available():
		if j.get("room", "") != room_key:
			continue
		var cell := Vector2i(int(j["station"][0]), int(j["station"][1]))
		if not GameState.worked_today:
			# un segnale che lampeggia sopra il posto di lavoro
			var mark := Label.new()
			mark.text = "!"
			mark.add_theme_font_size_override("font_size", 12)
			mark.add_theme_color_override("font_color", Color("ffe14d"))
			mark.add_theme_constant_override("outline_size", 3)
			mark.add_theme_color_override("font_outline_color", Color.BLACK)
			mark.position = cell_center(cell) + Vector2(-3, -26)
			mark.z_index = 30
			add_child(mark)
			var tw := mark.create_tween().set_loops()
			tw.tween_property(mark, "position:y", mark.position.y - 3, 0.4)
			tw.tween_property(mark, "position:y", mark.position.y, 0.4)
		var jj := j
		add_spot(cell_center(cell), func() -> void: _station(jj))


func _station(j: Dictionary) -> void:
	if GameState.worked_today:
		await Ui.say(["* " + str(j.get("station_text", "Un posto di lavoro.")),
			"* (Per oggi hai già dato. Il prossimo turno è domani: tocca una stellina e scegli di lasciar passare la notte.)"])
		return
	var c: int = await Ui.choose(str(j.get("station_text", "")) + "\nIniziare il turno? (10 ore)", ["Inizia", "Non ancora"])
	if c != 0:
		return
	var cfg: Dictionary = (j.get("battle", {}) as Dictionary).duplicate(true)
	cfg["kind"] = "work"
	cfg["return"] = scene_file_path
	cfg["return_pos"] = player.global_position
	Router.battle(cfg)


## Il capo telefona dopo il turno: una promozione, cioè sfruttare qualcuno che conosci.
func _boss_call() -> void:
	GameState.flags["boss_call_done_%d" % GameState.day] = true
	var victim := GameState.promotion_victim()
	var promo := GameState.promotion(victim)
	if victim == "" or promo.is_empty():
		return
	Sound.sfx("alarm", 0.7)
	await Ui.say(["* Il telefono vibra. È il capo."])
	await Ui.say(promo.get("desc", []), "Il capo")
	var c: int = await Ui.choose("Una firma, e sei promosso. (+%s)" % GameState.euros(GameState.easy_pay()),
		["Firma", "Rifiuta"], "Il capo")
	if c != 0:
		GameState.flags["promotions_refused"] = int(GameState.flags.get("promotions_refused", 0)) + 1
		await Ui.say(["Peccato. Ci sono altri cento come lei, sa? Ci pensi."], "Il capo")
		return
	var data := GameState.npc_data(victim)
	Router.battle({
		"kind": "sign",
		"promotion": true,
		"id": victim,
		"name": str(data.get("name", "Qualcuno")),
		"sheet": str(data.get("sheet", "char_02")),
		"intro": "* " + str(promo.get("title", "Una pratica")) + ".\n* Qualunque cosa tu scelga, la risposta è sempre la stessa.",
		"return": scene_file_path,
		"return_pos": player.global_position,
	})


# --- mappa ------------------------------------------------------------------

## Ogni voce di legenda: {"tex": percorso, "at": Vector2i o Callable(cella) -> Vector2i, "solid": bool}.
## La voce "_floor" viene usata sotto i caratteri sconosciuti (che finiscono in markers).
func paint(rows: Array, legend: Dictionary) -> void:
	map_size = Vector2i(str(rows[0]).length(), rows.size())
	for y in rows.size():
		var row := str(rows[y])
		for x in row.length():
			var ch := row[x]
			var cell := Vector2i(x, y)
			if legend.has(ch):
				_paint_cell(cell, legend[ch])
			else:
				_paint_cell(cell, legend["_floor"])
				if not markers.has(ch):
					markers[ch] = []
				markers[ch].append(cell)


func _paint_cell(cell: Vector2i, def: Dictionary) -> void:
	var at: Variant = def["at"]
	var coords: Vector2i = at.call(cell) if at is Callable else at
	put(cell, def["tex"], coords)
	if def.get("solid", false):
		block(Rect2i(cell, Vector2i.ONE))


func put(cell: Vector2i, rel: String, coords: Vector2i) -> void:
	var sid := _source(rel)
	var src := _tileset.get_source(sid) as TileSetAtlasSource
	var size := src.texture.get_size()
	if (coords.x + 1) * T > size.x or (coords.y + 1) * T > size.y:
		coords = Vector2i.ZERO
	if not src.has_tile(coords):
		src.create_tile(coords)
	_tiles.set_cell(cell, sid, coords)


func _source(rel: String) -> int:
	if _sources.has(rel):
		return _sources[rel]
	var src := TileSetAtlasSource.new()
	src.texture = Assets.tex(rel)
	src.texture_region_size = Vector2i(T, T)
	var sid := _tileset.add_source(src)
	_sources[rel] = sid
	return sid


## Rende solido un rettangolo preciso in pixel (per oggetti più piccoli di una casella).
func block_px(r: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = r.size
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = r.get_center()
	_solids.add_child(col)


## Panchina laterale (16x48): solo la seduta blocca il passaggio.
func add_side_bench(bottom: Vector2i, text: Array = []) -> void:
	add_prop("street/bench_side.png", bottom, 0, Vector2i(16, 48), text)
	block_px(Rect2(bottom.x * T + 3, (bottom.y - 2) * T + 22, 10, 24))


## Rende solide le celle del rettangolo.
func block(r: Rect2i) -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(r.size * T)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(r.position * T) + shape.size / 2.0
	_solids.add_child(col)
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_blocked_cells[Vector2i(x, y)] = true


# --- contenuto --------------------------------------------------------------

func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * T + T / 2.0, cell.y * T + T / 2.0)


func cell_feet(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * T + T / 2.0, (cell.y + 1) * T - 2)


## Piazza un oggetto con l'angolo in basso a sinistra sulla cella indicata.
## Le ultime `solid_rows` righe di celle occupate diventano solide.
## `text`: cosa dice l'oggetto quando lo guardi (Z). `nudge`: spostamento fine in pixel.
func add_prop(rel: String, bottom_left: Vector2i, solid_rows := 1, fallback := Vector2i(16, 32),
		text: Array = [], nudge := Vector2.ZERO) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Assets.tex(rel, fallback)
	s.centered = false
	s.offset = Vector2(0, -s.texture.get_height())
	s.position = Vector2(bottom_left.x * T, (bottom_left.y + 1) * T) + nudge
	world.add_child(s)
	var w := int(ceil(s.texture.get_width() / float(T)))
	if solid_rows > 0:
		# Blocca solo i pixel veri della base dell'oggetto (il palo, il tronco), non tutta la casella.
		var r := _solid_rect(s.texture, solid_rows)
		if r.size.x > 0:
			block_px(Rect2(s.position + r.position, r.size))
			for cx in range(int(floor((s.position.x + r.position.x) / T)), int(ceil((s.position.x + r.end.x) / T))):
				for cy in range(int(floor((s.position.y + r.position.y) / T)), int(ceil((s.position.y + r.end.y) / T))):
					_blocked_cells[Vector2i(cx, cy)] = true
		else:
			block(Rect2i(bottom_left.x, bottom_left.y - solid_rows + 1, w, solid_rows))
	if not text.is_empty():
		examine(Vector2(bottom_left.x * T + s.texture.get_width() / 2.0, (bottom_left.y + 1) * T - 8) + nudge, text)
	return s


static var _solid_cache := {}


## Rettangolo dei pixel non trasparenti nelle ultime `rows` righe di caselle dello sprite,
## relativo all'angolo in basso a sinistra (le y sono negative). Vuoto se non si può leggere l'immagine.
func _solid_rect(tex: Texture2D, rows: int) -> Rect2:
	var key := "%d_%d" % [tex.get_rid().get_id(), rows]
	if _solid_cache.has(key):
		return _solid_cache[key]
	var out := Rect2()
	var img := tex.get_image()
	if img:
		if img.is_compressed():
			img.decompress()
		var h := img.get_height()
		# Oggetti bassi (lampioni, alberi): conta solo la base, i "piedi" dell'oggetto.
		var top := maxi(0, h - (rows * T if rows > 1 else 6))
		var minx := img.get_width()
		var maxx := -1
		var miny := h
		var maxy := -1
		for y in range(top, h):
			for x in img.get_width():
				if img.get_pixel(x, y).a > 0.3:
					minx = mini(minx, x)
					maxx = maxi(maxx, x)
					miny = mini(miny, y)
					maxy = maxi(maxy, y)
		if maxx >= 0:
			out = Rect2(minx, miny - h, maxx - minx + 1, maxy - miny + 1)
	_solid_cache[key] = out
	return out


## Punto di salvataggio: una stellina che brilla. Salva stanza, posizione e ora, e ridà energia.
func add_save_point(cell: Vector2i) -> void:
	var star := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	var tex: Texture2D = load("res://art/save_star.png") if ResourceLoader.exists("res://art/save_star.png") else Assets.tex("_star", Vector2i(26, 13))
	for i in 2:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * 13, 0, 13, 13)
		frames.add_frame("default", at)
	frames.set_animation_speed("default", 2.0)
	star.sprite_frames = frames
	star.position = cell_center(cell) + Vector2(0, -4)
	star.play()
	world.add_child(star)
	add_spot(cell_center(cell), func() -> void: _save_here(cell))


## La stellina salva, ridà energia e, se vuoi, fa passare la notte (così il giorno dopo si può
## lavorare di nuovo). La notte però costa: gli interessi corrono.
func _save_here(cell: Vector2i) -> void:
	GameState.restore(GameState.MAX_ENERGY)
	var here := cell_feet(cell + Vector2i(0, 1))
	var c: int = await Ui.choose("* (Una stellina brilla a mezz'aria. Guardarla ti fa tornare la voglia di andare avanti.)",
		["Salva", "Salva e lascia passare la notte", "Lascia stare"])
	if c == 2:
		return
	if c == 1:
		GameState.spend(GameState.MIDNIGHT - GameState.minutes)
		GameState.save_game(scene_file_path, here)
		Sound.sfx("spare")
		Router.save_pos = here
		Router.goto(scene_file_path, "_save", ["Ti siedi vicino alla stellina e chiudi gli occhi.", "La notte passa. Da qualche parte, sopra di te, qualcuno conta gli interessi.", "{floor}, ore {clock}."])
		return
	GameState.save_game(scene_file_path, here)
	Sound.sfx("spare")
	await Ui.say(["* Energia al massimo. Partita salvata: {floor}, ore {clock}."])


## Un punto che, guardato, mostra una descrizione.
func examine(pos: Vector2, text: Array) -> Interactable:
	return add_spot(pos, func() -> void: Ui.say(text))


## Mette nella stanza le persone che oggi, secondo data/npcs.json, si trovano qui.
func spawn_people(room_key: String) -> void:
	var items := Quests.items_in(room_key)
	for it: Dictionary in items:
		_people_cells[it["cell"]] = true
	for id: String in GameState.npc_ids():
		var place := GameState.npc_place(id)
		if place.get("room", "") != room_key:
			continue
		var cell: Array = place.get("cell", [1, 1])
		add_npc(id, Vector2i(int(cell[0]), int(cell[1])), str(place.get("anim", "idle_down")))
	for it: Dictionary in items:
		_add_quest_item(it["quest"], it["cell"])


## L'oggetto nascosto di una missione: un gatto che dorme o un paio di occhiali per terra.
func _add_quest_item(q: Dictionary, cell: Vector2i) -> void:
	var node: Node2D
	if q.get("item") == "cat":
		var cat := AnimatedSprite2D.new()
		var frames := SpriteFrames.new()
		var tex := Assets.tex("props/cat.png", Vector2i(576, 16))
		for i in 12:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * 48, 0, 48, 16)
			frames.add_frame("default", at)
		frames.set_animation_speed("default", 6.0)
		cat.sprite_frames = frames
		cat.centered = false
		cat.offset = Vector2(-24, -15)
		cat.play()
		node = cat
	else:
		var s := Sprite2D.new()
		s.texture = load("res://art/glasses.png") if ResourceLoader.exists("res://art/glasses.png") else Assets.tex("_glasses", Vector2i(10, 6))
		s.offset = Vector2(0, -4)
		node = s
	node.position = cell_feet(cell)
	world.add_child(node)
	var holder: Array = []
	holder.append(add_spot(cell_feet(cell) + Vector2(0, -6), func() -> void:
		node.queue_free()
		for h: Node in holder:
			h.queue_free()
		await Quests.pick_up(q)
	))


## Ritaglia un pezzo da un foglio grande (per esempio un edificio intero).
func add_region(rel: String, sheet_size: Vector2i, region: Rect2, bottom_left: Vector2i) -> Sprite2D:
	var at := AtlasTexture.new()
	at.atlas = Assets.tex(rel, sheet_size)
	at.region = region
	var s := Sprite2D.new()
	s.texture = at
	s.centered = false
	s.offset = Vector2(0, -region.size.y)
	s.position = Vector2(bottom_left.x * T, (bottom_left.y + 1) * T)
	world.add_child(s)
	return s


## Un cartello su due pali piantati a terra: `foot` è il punto a terra sotto il centro del cartello,
## `post` l'altezza dei pali. Va nel mondo ordinato per y, così ci si passa dietro.
func add_signpost(path: String, foot: Vector2, post := 14) -> void:
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	var holder := Node2D.new()
	holder.position = foot
	for k in 2:
		var pole := ColorRect.new()
		pole.color = Color("5a3e2b")
		pole.size = Vector2(2, post + 2)
		pole.position = Vector2(-tex.get_width() / 2.0 + 4 + k * (tex.get_width() - 10), -post - 2)
		holder.add_child(pole)
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = Vector2(-tex.get_width() / 2.0, -post - tex.get_height())
	holder.add_child(s)
	world.add_child(holder)
	var x0 := int(foot.x - tex.get_width() / 2.0 + 4) / T
	var x1 := int(foot.x + tex.get_width() / 2.0 - 5) / T
	block(Rect2i(x0, int(foot.y - 1) / T, x1 - x0 + 1, 1))


## Casella libera più vicina a quella voluta: niente muri e nessun'altra persona attaccata.
## Chi è seduto resta sulla sua panchina.
func free_cell(cell: Vector2i, keep := false) -> Vector2i:
	if keep:
		_people_cells[cell] = true
		return cell
	for r in 6:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := cell + Vector2i(dx, dy)
				if c.x < 0 or c.y < 0 or (map_size != Vector2i.ZERO and (c.x >= map_size.x or c.y >= map_size.y)):
					continue
				if _blocked_cells.has(c) or _near_person(c):
					continue
				_people_cells[c] = true
				return c
	_people_cells[cell] = true
	return cell


func _near_person(c: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if _people_cells.has(c + Vector2i(dx, dy)):
				return true
	return false


func add_npc(id: String, cell: Vector2i, activity := "idle_down") -> Npc:
	var n := Npc.new()
	n.id = id
	n.activity = activity if activity.contains("_") or activity in ["phone", "read", "wander"] else "idle_" + activity
	cell = free_cell(cell, n.activity.begins_with("sit"))
	n.position = cell_feet(cell)
	world.add_child(n)
	return n


## Uno sprite dalla cartella art/ (grafica fatta per Cheap), con l'angolo in basso a sinistra sulla cella.
func add_art(path: String, bottom_left: Vector2i, solid_rows := 0, nudge := Vector2.ZERO) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = false
	s.offset = Vector2(0, -s.texture.get_height())
	s.position = Vector2(bottom_left.x * T, (bottom_left.y + 1) * T) + nudge
	world.add_child(s)
	if solid_rows > 0:
		var r := _solid_rect(s.texture, solid_rows)
		if r.size.x > 0:
			block_px(Rect2(s.position + r.position, r.size))
			_blocked_cells[bottom_left] = true
	return s


## Scale che salgono al piano di sopra, dentro al muro, con il tornello accanto: si passa
## solo con il badge di quel piano. `bottom_left` è il primo gradino (sul pavimento).
func add_stairs_up(bottom_left: Vector2i, path: String, spawn_name: String, need: String) -> void:
	add_art("res://art/stairs_up.png", bottom_left)
	var turn := add_art("res://art/turnstile.png", bottom_left + Vector2i(-1, 0), 1)
	if GameState.has_badge(need):
		turn.modulate = Color(0.85, 1.0, 0.85)
	examine(cell_center(bottom_left + Vector2i(-1, 0)), [
		"* Il tornello. Sopra il lettore c'è scritto: \"%s. Solo con badge\"." % GameState.floor_name(need),
	])
	var a := Area2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(2 * T - 6, 8)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(bottom_left.x * T + T, bottom_left.y * T + 4)
	a.add_child(col)
	add_child(a)
	a.body_entered.connect(func(b: Node2D) -> void:
		if not (b is Player) or Ui.blocks_input():
			return
		if GameState.has_badge(need):
			var key := "stairs_" + need
			var lines: Array = []
			if not GameState.flags.get(key, false):
				GameState.flags[key] = true
				lines = ["Sali le scale. Gli scalini sono consumati al centro, da tutti quelli che sono passati prima.", GameState.floor_name(need) + "."]
			Router.goto(path, spawn_name, lines)
			return
		Sound.sfx("deny")
		b.position.y += 10
		await Ui.say(["* Il tornello lampeggia rosso. \"Badge del %s richiesto.\"" % GameState.floor_name(need),
			"* (Il badge si compra al distributore: %s, a scalare dal debito.)" % GameState.euros(GameState.badge_cost(need))])
	)


## Scale che scendono al piano di sotto (una botola nel pavimento, 2x2 caselle).
func add_stairs_down(bottom_left: Vector2i, path: String, spawn_name: String) -> void:
	add_art("res://art/stairs_down.png", bottom_left)
	var a := Area2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(2 * T - 8, T)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(bottom_left.x * T + T, bottom_left.y * T + 4)
	a.add_child(col)
	add_child(a)
	a.body_entered.connect(func(b: Node2D) -> void:
		if b is Player and not Ui.blocks_input():
			Router.goto(path, spawn_name)
	)


## Il distributore dei badge: paghi una parte del debito e ricevi il badge del piano di sopra.
func add_badge_machine(bottom_left: Vector2i) -> void:
	var m := add_prop("props/terminal.png", bottom_left)
	m.modulate = Color(0.85, 1.0, 0.9)
	if ResourceLoader.exists("res://art/plate_badge.png"):
		var plate := Sprite2D.new()
		plate.texture = load("res://art/plate_badge.png")
		plate.position = Vector2(bottom_left.x * T + T / 2.0, (bottom_left.y + 1) * T - 32 - 6)
		plate.z_index = 1
		add_child(plate)
	add_spot(cell_center(bottom_left), _badge_machine)


func _badge_machine() -> void:
	var need := GameState.floor_above()
	if need == "":
		await Ui.say(["* Il distributore è spento. Più su di così non si va."])
		return
	var cost := GameState.badge_cost(need)
	if GameState.has_badge(need):
		await Ui.say(["* \"Hai già il badge del %s. Il distributore ti augura una buona salita.\"" % GameState.floor_name(need)])
		return
	await Ui.say(["* Il distributore di badge. Sullo schermo: \"BADGE %s: %s.\"" % [GameState.floor_name(need).to_upper(), GameState.euros(cost)],
		"* Più in piccolo: \"L'importo verrà scalato dal suo debito. Grazie per la fiducia.\""])
	var c: int = await Ui.choose("Comprare il badge? Hai %s." % GameState.euros(GameState.money), ["Compra (%s)" % GameState.euros(cost), "Non ora"])
	if c != 0:
		return
	if not GameState.buy_badge(need):
		Sound.sfx("deny")
		await Ui.say(["* Non hai abbastanza soldi. Il distributore fa un rumore che somiglia a una risata."])
		return
	Sound.sfx("coin")
	Sound.sfx("stamp")
	await Ui.say(["* Il badge esce caldo, come un biglietto della lotteria che hai già perso.",
		"* Debito: {debt}. Il tornello adesso ha la lucina verde."])
	for n in world.get_children():
		if n is Sprite2D and (n as Sprite2D).texture and (n as Sprite2D).texture.resource_path.ends_with("turnstile.png"):
			n.modulate = Color(0.85, 1.0, 0.85)


func add_spot(pos: Vector2, action: Callable) -> Interactable:
	var i := Interactable.new()
	i.position = pos
	i.action = action
	add_child(i)
	return i


## Zona che porta in un'altra scena quando il giocatore ci cammina sopra.
func add_exit(r: Rect2i, path: String, spawn_name: String) -> void:
	var a := Area2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(r.size * T)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(r.position * T) + shape.size / 2.0
	a.add_child(col)
	add_child(a)
	a.body_entered.connect(func(b: Node2D) -> void:
		if b is Player and not Ui.blocks_input():
			Router.goto(path, spawn_name)
	)


func _spawn_player() -> void:
	player = Player.new()
	if Router.spawn == "_back" and GameState.battle.has("return_pos"):
		spawns["_back"] = GameState.battle["return_pos"]
	if Router.spawn == "_mg" and GameState.minigame.has("return_pos"):
		spawns["_mg"] = GameState.minigame["return_pos"]
	if Router.spawn == "_save" and Router.save_pos != Vector2.INF:
		spawns["_save"] = Router.save_pos
	var key := Router.spawn if spawns.has(Router.spawn) else "default"
	player.position = spawns.get(key, Vector2(map_size * T) / 2.0)
	player.facing = spawn_facing.get(key, "down")
	world.add_child(player)
	var cam := player.camera
	var w := map_size.x * T
	var h := map_size.y * T
	var pad_x := maxi(0, int(VIEW.x) - w) / 2
	var pad_y := maxi(0, int(VIEW.y) - (h - camera_top)) / 2
	cam.limit_left = -pad_x
	cam.limit_right = w + pad_x
	cam.limit_top = -camera_top - pad_y
	cam.limit_bottom = h + pad_y
	cam.offset.y = -camera_lift
