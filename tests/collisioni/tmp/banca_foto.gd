extends Node
var frame := 0
var out := "C:/Users/linda/AppData/Local/Temp/claude/C--Users-linda-Documents-sito-siw-personle/2f16c58e-bb47-4c51-9f96-d6f04090c739/scratchpad/banca/"
func _shot(room: Room, center: Vector2, zoom: float, name: String) -> void:
	var cam := room.player.camera
	cam.top_level = true; cam.position_smoothing_enabled = false
	cam.limit_left = -100000; cam.limit_top = -100000; cam.limit_right = 100000; cam.limit_bottom = 100000
	cam.global_position = center; cam.zoom = Vector2(zoom, zoom)
	for i in 8: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + name + ".png")
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	await get_tree().process_frame
	GameState.save_path = "user://banca_foto.json"
	var room: Room = await MappaAperta.apri(self, "res://chapters/c4/banca.tscn")
	Ui.show_hud(false)
	for a in room.find_children("*", "Area2D", true, false): (a as Area2D).monitoring = false
	var s := room.find_child("Serranda", true, false) as Node2D
	print("serranda ", s.global_position)
	room.player.position = s.global_position + Vector2(0, 40)
	await _shot(room, s.global_position + Vector2(0, 0), 3.0, "serranda_aperta")
	s.call("chiudi", false)
	await _shot(room, s.global_position + Vector2(0, 0), 3.0, "serranda_chiusa")
	var spot := room.find_child("PostoSportello", true, false) as Node2D
	print("posto sportello ", spot.global_position)
	var use := spot.get_node("PuntoUso") as Node2D
	print("punto uso ", use.global_position)
	room.player.position = use.global_position
	await _shot(room, spot.global_position + Vector2(0, -10), 3.0, "turno_punto")
	get_tree().quit(0)
func _process(_d: float) -> void:
	frame += 1
	MappaAperta.salta_dialoghi(frame)
