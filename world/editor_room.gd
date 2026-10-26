class_name EditorRoom
extends Room
## Una stanza costruita nell'editor di Godot (non con il codice). La scena contiene:
##   Pavimento, Muri   TileMapLayer (i muri hanno le collisioni nel TileSet)
##   Mondo             Node2D ordinato per y: oggetti, persone (NpcSpot), cose speciali (RoomFeature)
##   Arrivi            Marker2D: il nome è il punto d'arrivo ("default", "from_above"...),
##                     il metadato "facing" dice dove guarda il giocatore
## Gli oggetti con collisione sono Sprite2D con uno StaticBody2D figlio.
## Le stanze vere estendono questa e scrivono solo la loro logica (dialoghi, eventi).

@export var room_music := "fondo"
@export var room_floor := ""


func build() -> void:
	music = room_music
	floor_id = room_floor
	var floor_layer := get_node_or_null("Pavimento") as TileMapLayer
	if floor_layer:
		var used := floor_layer.get_used_rect()
		map_size = used.end
		# la telecamera resta dentro i muri: il bordo scuro intorno alla stanza non si vede
		var walls := get_node_or_null("Muri") as TileMapLayer
		var all := used.merge(walls.get_used_rect()) if walls else used
		var inner := all.grow(-1) if walls else all
		cam_rect = Rect2(Vector2(inner.position * T), Vector2(inner.size * T))
	var arrivals := get_node_or_null("Arrivi")
	if arrivals:
		for m in arrivals.get_children():
			if m is Node2D:
				spawns[str(m.name)] = (m as Node2D).position
				spawn_facing[str(m.name)] = str(m.get_meta("facing", "down"))
	for n in find_children("*", "", true, false):
		if n.has_method("setup_in_room"):
			n.call("setup_in_room", self)
	setup()


## Da scrivere nelle stanze vere: dialoghi, luci, eventi.
func setup() -> void:
	pass


# --- lo sguardo indietro: la fine di ogni capitolo -------------------------------

## In cima alle scale ti volti: la telecamera si allarga su tutta la stanza, compare `line`,
## poi buio, il titolo del capitolo dopo e il cambio di piano.
func look_back(p: Player, line: String, chapter: String, title: String, path: String, spawn_name: String, narration: Array) -> void:
	Ui.cutscene = true
	Ui.show_hud(false)
	p.set_physics_process(false)
	p.face("down")
	# la telecamera si allarga su tutta la stanza, com'è diventata
	# solo il pavimento e i muri: niente bordo scuro, niente fuori-mappa
	var inner := cam_rect
	var fit := maxf(640.0 / inner.size.x, 360.0 / inner.size.y)
	var half := Vector2(320, 180) / fit
	var look := (inner.get_center() + Vector2(0, 10)).clamp(inner.position + half, inner.end - half)
	var cam := p.camera
	Sound.music_pitch(0.6, 4.0)
	# la telecamera si stacca dal giocatore (così i bordi della stanza la tengono dentro)
	var from := cam.get_screen_center_position()
	cam.position_smoothing_enabled = false
	cam.top_level = true
	cam.global_position = from
	var tw := create_tween()
	tw.tween_property(cam, "global_position", look, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(cam, "zoom", Vector2(fit, fit), 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	await get_tree().create_timer(0.8).timeout
	# una frase sola, quella che ti sei guadagnato
	var layer := CanvasLayer.new()
	layer.layer = 15
	add_child(layer)
	# la frase in basso, su una striscia scura, per non coprire la stanza
	var band := ColorRect.new()
	band.color = Color(0, 0, 0, 0)
	band.position = Vector2(0, 278)
	band.size = Vector2(640, 82)
	layer.add_child(band)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0)
	shade.size = Vector2(640, 360)
	layer.add_child(shade)
	var label := big_label(layer, line, Vector2(40, 280), Vector2(560, 78), 13, Color.WHITE)
	label.modulate.a = 0.0
	var a := create_tween().set_parallel()
	a.tween_property(band, "color:a", 0.75, 1.2)
	a.tween_property(label, "modulate:a", 1.0, 1.2)
	await a.finished
	await get_tree().create_timer(4.0).timeout
	# buio, poi il capitolo dopo
	var b := create_tween()
	b.tween_property(label, "modulate:a", 0.0, 0.8)
	b.tween_property(shade, "color:a", 1.0, 1.0)
	await b.finished
	Sound.music("")
	var small := big_label(layer, chapter, Vector2(0, 138), Vector2(640, 24), 13, Color("8a8494"))
	var big := big_label(layer, title, Vector2(0, 162), Vector2(640, 40), 26, Color("ffe14d"))
	small.modulate.a = 0.0
	big.modulate.a = 0.0
	var c := create_tween()
	c.tween_property(small, "modulate:a", 1.0, 0.8)
	c.tween_property(big, "modulate:a", 1.0, 0.8)
	Sound.sfx("stamp", 0.8)
	await c.finished
	await get_tree().create_timer(2.0).timeout
	Ui.cutscene = false
	Router.goto(path, spawn_name, narration)


func big_label(parent: Node, text: String, pos: Vector2, size: Vector2, font_size: int, col: Color) -> Label:
	var l := Label.new()
	# l'a capo prima della larghezza: se no la scritta si allarga quanto tutta la frase ed esce dallo schermo
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.text = text
	l.position = pos
	l.size = size
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l
