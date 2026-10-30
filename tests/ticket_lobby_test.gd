extends "res://tests/boss_integration_test.gd"
func _ready() -> void:
 await get_tree().process_frame
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
 GameState.save_path = "user://test_ticket_lobby.json"
 await open_room("-5")
 var room := current as Room
 await room.call("_talk_fermo")
 check(GameState.flags.get("fermo_talked", false), "Primo dialogo reale con Fermo completato")
 var floor_layer := room.get_node("Pavimento") as TileMapLayer
 for c: Vector2i in floor_layer.get_used_cells():
  if c.x >= 24: check(floor_layer.get_cell_atlas_coords(c) == Vector2i(38 + c.x % 3, 13 + c.y % 2), "Piastrella originale " + str(c))
 check(room.has_node("Mondo/CycletteDinamo") and not room.has_node("Mondo/Cyclette"), "Un solo disegno della cyclette")
 var bike := room.get_node("Mondo/CycletteDinamo") as Sprite2D
 check(bike.region_rect == Rect2(96, 480, 32, 32), "CycletteDinamo originale")
 check(room.get_node("Mondo/AscensoreOriginale") is Lift, "Ascensore presente anche nella scena dell'editor")
 check(room._lift._spr.texture.resource_path == Lift.SHEET, "Porte originali dell'ascensore")
 check(room.find_children("Telecamera_*", "Sprite2D", true, false).size() == 2, "Due telecamere animate")
 check(room._stairs_up_pos.x > 512, "Scale oltre il pilastro, non dentro la biglietteria")
 room.player.global_position = Vector2(344, 160)
 for i in 90:
  await get_tree().physics_frame
  room.player.velocity = Vector2(80, 0)
  room.player.move_and_slide()
 check(room.player.global_position.x > 414, "Mini corridoio attraversabile dalla festa")
 for i in 90:
  await get_tree().physics_frame
  room.player.velocity = Vector2(-80, 0)
  room.player.move_and_slide()
 check(room.player.global_position.x < 350, "Mini corridoio attraversabile al ritorno")
 room.player.velocity = Vector2.ZERO
 room.player.global_position = Vector2(428, 148)
 room.player.camera.top_level = true
 room.player.camera.limit_left = -10000; room.player.camera.limit_top = -10000
 room.player.camera.limit_right = 10000; room.player.camera.limit_bottom = 10000
 room.player.camera.global_position = Vector2(438, 96)
 room.player.camera.zoom = Vector2(2, 2)
 Ui.show_hud(false)
 await frames(5)
 await shot("biglietteria_corridoio")
 room.player.camera.global_position = Vector2(192, 42)
 room.player.camera.zoom = Vector2(4, 4)
 await frames(4); await shot("ascensore_originale")
 await close_current()
 GameState.minigame = {"kind": "work", "game": "pedal", "name": "CycletteDinamo", "pay": 200, "job": GameState.job("dinamo")["battle"], "intro": [], "return": Router.FONDO, "return_pos": Vector2(64, 112)}
 current = load(Router.WORK).instantiate()
 get_tree().root.add_child(current); get_tree().current_scene = current
 await frames(100)
 await shot("cyclette_dinamo_minigioco")
 await close_current()
 print("TICKET LOBBY: %d verifiche, errori %s" % [checks, str(failures)])
 get_tree().quit(failures.size())
