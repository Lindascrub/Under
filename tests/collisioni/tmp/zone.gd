extends Node
var frame := 0
func _ready() -> void:
	await get_tree().process_frame
	GameState.save_path = "user://collisioni_tmp.json"
	var path := "res://chapters/c5/citta.tscn"
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--map="):
			path = a.trim_prefix("--map=")
	var room: Room = await MappaAperta.apri(self, path)
	var a := AuditMappa.new(room)
	var starts: Array = room.spawns.values()
	starts.append(room.player.position)
	a.flood(starts)
	print("cam ", room.cam_rect, " spawn ", room.player.position)
	print("exits ", a.exits, " reached ", a.exits_reached)
	for c in room.get_children():
		if c is Area2D: print("AREA ", c.name, " ", c.position, " ", c.get_children())
	# righe: per ogni y (passo 8) gli intervalli x raggiunti
	var rows := {}
	for p in a.points():
		if int(p.y) % 8 != 0: continue
		if not rows.has(p.y): rows[p.y] = []
		rows[p.y].append(int(p.x))
	var ys := rows.keys(); ys.sort()
	for y in ys:
		var xs: Array = rows[y]; xs.sort()
		var segs := []
		var s0: int = xs[0]; var prev: int = xs[0]
		for x: int in xs.slice(1):
			if x - prev > 4:
				segs.append("%d..%d" % [s0, prev]); s0 = x
			prev = x
		segs.append("%d..%d" % [s0, prev])
		print("y=", y, "  ", " ".join(segs))
	get_tree().quit(0)
func _process(_d: float) -> void:
	frame += 1
	MappaAperta.salta_dialoghi(frame)
