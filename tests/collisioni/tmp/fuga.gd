extends Node
var frame := 0
const CASI := [["res://chapters/c4/banca.tscn", Vector2(292,240), Vector2(283.18,248.92)], ["res://chapters/c5/citta.tscn", Vector2(784,164), Vector2(778.07,156.08)]]
func _ready() -> void:
	await get_tree().process_frame
	GameState.save_path = "user://collisioni_tmp.json"
	for c: Array in CASI:
		var room: Room = await MappaAperta.apri(self, c[0])
		var a := AuditMappa.new(room)
		var starts: Array = room.spawns.values()
		starts.append(room.player.position)
		a.flood(starts)
		var e: Vector2 = c[2]
		print(c[0], " fine ", e, " libero ", a.free_at(e))
		var k := Vector2i((e / 4).floor())
		for dy in range(-3, 4):
			var line := ""
			for dx in range(-3, 4):
				var q := k + Vector2i(dx, dy)
				line += ("R" if a.reach.has(q) else ("." if a.free_at(Vector2(q * 4)) else "#"))
			print("  ", line)
		# corpi vicini
		for n in room.find_children("*", "CollisionShape2D", true, false):
			var s := n as CollisionShape2D
			if s.shape is RectangleShape2D and not s.disabled:
				var r := (s.shape as RectangleShape2D).get_rect()
				var gr := Rect2(s.global_position + r.position, r.size)
				if gr.grow(10).has_point(e) and s.get_parent() is StaticBody2D:
					print("  corpo ", room.get_path_to(s), " ", gr)
		await MappaAperta.chiudi(self, room)
	get_tree().quit(0)
func _process(_d: float) -> void:
	frame += 1
	MappaAperta.salta_dialoghi(frame)
