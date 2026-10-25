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
