@tool
class_name NpcSpot
extends Node2D
## Dove sta una persona del gioco (data/npcs.json). Nell'editor si vede il suo sprite;
## quando la stanza parte, al suo posto compare la persona vera, con dialoghi e aiuti.

@export var npc_id := "":
	set(v):
		npc_id = v
		_preview()
@export var activity := "idle_down":
	set(v):
		activity = v
		_preview()

var _sprite: CharSprite


func _ready() -> void:
	_preview()


func _preview() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	if _sprite == null:
		_sprite = CharSprite.new()
		add_child(_sprite)
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/npcs.json"))
	var sheet := "char_02"
	if data is Dictionary and (data as Dictionary).has(npc_id):
		sheet = str(data[npc_id].get("sheet", "char_02"))
	_sprite.sheet = sheet
	_sprite.anim = activity if activity.contains("_") else "idle_down"


func setup_in_room(room: Room) -> void:
	if npc_id == "":
		return
	var n := Npc.new()
	n.id = npc_id
	n.activity = activity
	n.position = position
	room.world.add_child(n)
	queue_free()
