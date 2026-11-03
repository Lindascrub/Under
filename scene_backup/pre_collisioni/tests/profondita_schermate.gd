extends Node
## Le schermate del controllo di profondità: per ogni mappa mette il giocatore nei punti segnalati da
## AuditMappa (e in quelli chiesti in PROVE) e salva una foto con le collisioni visibili.
## Da guardare a occhio: una collisione giusta non dice se il personaggio è coperto bene.
## Esegui (NON headless):
##   Godot --path . res://tests/collisioni/profondita_schermate.tscn -- --out=<cartella> [--solo=citta] [--tutti]
## --tutti: oltre ai problemi, una foto dietro e una davanti a ogni oggetto del Mondo alto almeno 12 px.

var _out := "user://profondita/"
var _solo: Array = []
var _tutti := false
var _mappa := false
var frame := 0


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.trim_prefix("--out=").trim_suffix("/") + "/"
		elif a.begins_with("--solo="):
			_solo = Array(a.trim_prefix("--solo=").split(","))
		elif a == "--tutti":
			_tutti = true
		elif a == "--mappa":
			_mappa = true
	DirAccess.make_dir_recursive_absolute(_out)
	get_tree().debug_collisions_hint = true
	await get_tree().process_frame
	GameState.save_path = "user://collisioni_schermate.json"
	var mappe: Dictionary = load("res://tests/collisioni/rapporto.gd").MAPPE
	for nome: String in mappe:
		if not _solo.is_empty() and nome not in _solo:
			continue
		var room: Room = await MappaAperta.apri(self, mappe[nome])
		if room == null:
			continue
		Ui.show_hud(false)
		# il giocatore viene spostato a mano: le uscite e le scale non devono portarlo via
		for area in room.find_children("*", "Area2D", true, false):
			(area as Area2D).monitoring = false
		var a := AuditMappa.new(room)
		var starts: Array = room.spawns.values()
		starts.append(room.player.position)
		a.flood(starts)
		a.check()
		var n := 0
		if _mappa:
			await _overview(room, a, nome)
		for kind: String in a.problems:
			for path: String in a.problems[kind]:
				n += 1
				await _shot(room, a.problems[kind][path], "%s_%02d_%s_%s" % [nome, n, kind, path.get_file()])
		if _tutti:
			for s in a.tall_world_sprites():
				for side: Array in [["dietro", -1], ["davanti", 1]]:
					var p := a.near_point(s, int(side[1]))
					if p != Vector2.INF:
						n += 1
						await _shot(room, p, "%s_%02d_%s_%s" % [nome, n, side[0], s.name])
		print("SCHERMATE ", nome, ": ", n)
		await MappaAperta.chiudi(self, room)
	get_tree().quit(0)


## Tutta la stanza dall'alto, coi punti dove si arriva a piedi in viola e i problemi in giallo.
func _overview(room: Room, a: AuditMappa, nome: String) -> void:
	var pts := a.points()
	var bad: Array[Vector2] = []
	for kind: String in a.problems:
		for path: String in a.problems[kind]:
			bad.append(a.problems[kind][path])
	var ov := Node2D.new()
	ov.z_index = 100
	ov.draw.connect(func() -> void:
		for p in pts:
			ov.draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(1, 0, 1, 0.3))
		for p in bad:
			ov.draw_circle(p, 5.0, Color(1, 1, 0, 0.9))
	)
	room.add_child(ov)
	room.player.visible = false
	var cam := room.player.camera
	var box := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		box = box.expand(p)
	box = box.grow(48)
	cam.top_level = true
	cam.position_smoothing_enabled = false
	cam.limit_left = -100000
	cam.limit_top = -100000
	cam.limit_right = 100000
	cam.limit_bottom = 100000
	# a pezzi, così i pixel si vedono: ogni foto copre al massimo 640x360 del mondo
	var tiles := Vector2i(ceili(box.size.x / 640.0), ceili(box.size.y / 360.0))
	for ty in tiles.y:
		for tx in tiles.x:
			cam.zoom = Vector2.ONE
			cam.global_position = box.position + Vector2(320 + tx * 640, 180 + ty * 360)
			for i in 6:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(_out + "%s_00_mappa_%d_%d.png" % [nome, ty, tx])
	ov.queue_free()
	room.player.visible = true
	cam.top_level = false


func _shot(room: Room, p: Vector2, name: String) -> void:
	if not is_instance_valid(room):
		return
	room.player.position = p
	room.player.facing = "down"
	for i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out + name.validate_filename() + ".png")


func _process(_delta: float) -> void:
	frame += 1
	MappaAperta.salta_dialoghi(frame)
