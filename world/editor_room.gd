class_name EditorRoom
extends Room
## Una stanza costruita nell'editor di Godot (non con il codice). La scena contiene:
##   Pavimento, Muri   TileMapLayer (i muri hanno le collisioni nel TileSet)
##   Mondo             Node2D ordinato per y: oggetti, persone (NpcSpot), cose speciali (RoomFeature)
##   Arrivi            Marker2D: il nome è il punto d'arrivo ("default", "from_above"...),
##                     il metadato "facing" dice dove guarda il giocatore
## Gli oggetti con collisione sono Sprite2D con uno StaticBody2D figlio.
## Le stanze vere estendono questa e scrivono solo la loro logica (dialoghi, eventi).

## Le scritte dello sguardo indietro di fine capitolo.
const LOOK_BACK_CARD := "res://world/sguardo_indietro.tscn"

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
## poi buio, il titolo del capitolo dopo (e il sottotitolo, se c'è) e il cambio di piano.
func look_back(p: Player, line: String, chapter: String, title: String, path: String, spawn_name: String, narration: Array,
		subtitle := "", preface: Array = []) -> void:
	Ui.cutscene = true
	Ui.show_hud(false)
	p.set_physics_process(false)
	p.face("down")
	# la telecamera si allarga su tutta la stanza, com'è diventata: dove la porta il nodo
	# Inquadrature/SguardoIndietro della scena (si sposta e si cambia lo zoom nell'editor)
	var shot := get_node_or_null("Inquadrature/SguardoIndietro") as Inquadratura
	if shot == null:
		push_warning("Manca il nodo Inquadrature/SguardoIndietro in " + scene_file_path)
	var look := shot.global_position if shot else cam_rect.get_center()
	var fit := shot.zoom if shot else maxf(640.0 / cam_rect.size.x, 360.0 / cam_rect.size.y)
	var duration := shot.durata if shot else 3.5
	var cam := p.camera
	Sound.music_pitch(0.6, 4.0)
	# la telecamera si stacca dal giocatore (così i bordi della stanza la tengono dentro)
	var from := cam.get_screen_center_position()
	cam.position_smoothing_enabled = false
	cam.top_level = true
	cam.global_position = from
	var tw := create_tween()
	tw.tween_property(cam, "global_position", look, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(cam, "zoom", Vector2(fit, fit), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	# una frase sola, quella che ti sei guadagnato; poi buio e il capitolo dopo.
	# Le scritte sono la scena world/sguardo_indietro.tscn (posizioni, colori e tempi si cambiano lì).
	var card := load(LOOK_BACK_CARD).instantiate() as SguardoIndietro
	add_child(card)
	await card.frase(line)
	await card.buio()
	Sound.music("")
	# qualche riga sul buio prima del titolo (la Città: "PRESIDENZA CHEAP. SEI ARRIVATO.")
	if not preface.is_empty():
		await card.premessa(preface)
	await card.titolo(chapter, title, subtitle)
	Ui.cutscene = false
	Router.goto(path, spawn_name, narration)

