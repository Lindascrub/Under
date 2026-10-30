extends Node
## Regressioni fisiche dei problemi segnalati: mobili, sportelli, sedute e scale.

var failures: Array[String] = []
var frame := 0
var checks := 0
var room: Room

func _ready() -> void:
	await get_tree().process_frame
	GameState.save_path = "user://world_fixes_regression.json"
	for scene in [Router.FONDO, Router.SOTTOUFFICIO, Router.MERCATO, Router.BANCA, Router.CITY, Router.CASA_COMUNE, Router.CIMA]:
		await _open(scene)
		_check(room.player != null, scene + " player missing")
		await _furniture()
		_counters()
		_people_access()
		_stairs()
		_seats()
		if scene == Router.SOTTOUFFICIO:
			_check(not room.has_node("Mondo/SediaTurno"), "Chair beside TURNO remains")
		if scene == Router.BANCA:
			_check(not room.has_node("Mondo/Quaderno"), "Small screen remains")
			_check(room.has_node("Mondo/TerminaleRapporto"), "Report terminal removed")
			_check(room.get_node("Decori/DisplayNumeri").get_script().resource_path == "res://world/number_display.gd", "Old number display")
		print("WORLD checked: ", scene)
		await _close()
	# Dalla Banca al Mercato: il passaggio avviene camminando davvero nell'area.
	await _open(Router.BANCA)
	var p := room.player
	p.position = room._stairs_down_exit + Vector2(0, -12)
	p.set_physics_process(true)
	Input.action_press("move_down")
	for i in 90:
		await get_tree().physics_frame
		if room._descending_stairs: break
	Input.action_release("move_down")
	_check(room._descending_stairs, "Bank stairs did not start controlled descent")
	for i in 600:
		await get_tree().process_frame
		if not is_instance_valid(room): break
	for i in 1800:
		await get_tree().process_frame
		if get_tree().current_scene.scene_file_path == Router.MERCATO and not Ui.blocks_input(): break
	var destination := get_tree().current_scene as Room
	_check(destination != null and destination.scene_file_path == Router.MERCATO, "Bank stairs wrong destination")
	if destination:
		_check(destination.player.position.distance_to(destination._stairs_up_exit) < 1, "Stair arrival is inside the stair/floor edge")
		room = destination
		await _close()
	print("WORLD FIXES: ", checks, " checks, failures=", failures)
	Sound.music("")
	for child in Sound.get_children():
		if child is AudioStreamPlayer: child.stop(); child.stream = null
	for i in 10: await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)

func _process(_delta: float) -> void:
	frame += 1
	if Ui.busy and frame % 2 == 0:
		if Ui.get("_mode") == "choose": Ui.set("_sel", 1)
		var event := InputEventAction.new(); event.action = "confirm"; event.pressed = true
		Input.parse_input_event(event)
		event = InputEventAction.new(); event.action = "confirm"; Input.parse_input_event(event)

func _open(path: String) -> void:
	GameState.new_game()
	for flag in ["c1_arrivo", "c1_intro", "c2_arrivo", "c3_arrivo", "c4_arrivo", "c5_arrivo"]:
		GameState.flags[flag] = true
	Router.spawn = "from_casa" if path == Router.CITY else "default"
	room = load(path).instantiate() as Room
	get_tree().root.add_child(room); get_tree().current_scene = room
	room.player.set_physics_process(false)
	for i in 1800:
		await get_tree().process_frame
		if i > 80 and not Ui.blocks_input(): break
	_check(not Ui.blocks_input(), path + " blocked on entry")
	room.player.set_physics_process(false)
	for i in 2: await get_tree().physics_frame

func _close() -> void:
	get_tree().current_scene = self
	room.queue_free(); room = null
	Ui.cutscene = false; Ui.transitioning = false
	for i in 5: await get_tree().process_frame

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func _furniture() -> void:
	for node in room.find_children("*", "Sprite2D", true, false):
		var spr := node as Sprite2D
		if not spr.has_meta("footprint_applied"): continue
		var body := spr.find_children("*", "StaticBody2D", true, false)[0] as StaticBody2D
		var shape := body.get_child(0) as CollisionShape2D
		_check(shape != null and shape.shape is RectangleShape2D, str(spr.name)+" invalid footprint")
		var point := PhysicsPointQueryParameters2D.new()
		point.position = shape.global_position
		point.collision_mask = 1
		var found := false
		for hit in room.get_world_2d().direct_space_state.intersect_point(point):
			if hit.collider == body: found = true
		_check(found, str(spr.name)+" furniture center not solid")
		# A sweep from below must hit the actual table/fridge instead of crossing it.
		var size: Vector2 = (shape.shape as RectangleShape2D).size
		var old := room.player.position
		room.player.global_position = shape.global_position + Vector2(0, size.y / 2 + 10)
		var collision := room.player.move_and_collide(Vector2(0, -size.y-20), true)
		_check(collision != null, str(spr.name)+" can be crossed from below")
		room.player.position = old

func _counters() -> void:
	var p := room.player
	var old := p.position
	for target in get_tree().get_nodes_in_group("interactable"):
		if not target is Interactable or target.approach != Vector2.DOWN: continue
		var at: Vector2 = target.hotspot()
		p.position = at + Vector2(0, 24); p.facing = "up"
		_check(p._find_target() == target, str(target.name)+" not reachable from front")
		p.position = at + Vector2(0, -8); p.facing = "down"
		_check(p._find_target() != target, str(target.name)+" works from behind")
	p.position = old

func _stairs() -> void:
	for zone in room._stair_zones:
		var rect: Rect2 = zone.rect
		# Side rail center is solid while the lane is free.
		var p := room.player
		var old := p.position
		p.position = Vector2(rect.position.x-12, rect.get_center().y)
		var hit := p.move_and_collide(Vector2(32, 0), true)
		_check(hit != null and hit.get_travel().x < 12, "Stair left edge can be straddled in %s at %s (hit %s)" % [room.scene_file_path, rect, hit.get_travel() if hit else null])
		p.position = Vector2(rect.end.x+12, rect.get_center().y)
		if _feet_clear(p):
			hit = p.move_and_collide(Vector2(-32, 0), true)
			_check(hit != null and hit.get_travel().x > -12, "Stair right edge can be straddled")
		else:
			# La fiancata esterna della Torre è un muro: una sweep partita
			# dentro quel muro misura il recupero della collisione, non l'accesso alla scala.
			var point:=PhysicsPointQueryParameters2D.new()
			point.position=Vector2(rect.end.x-1.5,rect.get_center().y)
			_check(not room.get_world_2d().direct_space_state.intersect_point(point).is_empty(),"Stair right edge is not solid")
		p.position = old
	if room._stairs_down_exit != Vector2.INF:
		var p := room.player
		var old := p.position
		p.position = room._stairs_down_exit
		_check(p.move_and_collide(Vector2(0, -3), true) == null, "Upward arrival from down stairs is obstructed")
		p.position = old

func _seats() -> void:
	var p := room.player
	var old := p.position
	for node in room.find_children("*", "Seat", true, false):
		var seat := node as Seat
		var reachable := false
		for dir in ["up", "down", "left", "right"]:
			for distance in [16,18,20,22,24,26]:
				p.position = seat.hotspot() - (Player.FACING_VECTORS[dir] as Vector2) * distance + Vector2(0, 6)
				p.facing = dir
				if _feet_clear(p) and p._find_target() == seat:
					reachable = true; break
			if reachable: break
		_check(reachable, "Seat has no accessible interaction: " + str(seat.global_position))
		p.sit(seat.global_position, seat.dir, seat.lift, seat.low_pose)
		_check(p.seated and not p._shadow.visible, "Seat did not engage")
		if seat.dir in ["left", "right"] and seat.lift >= 6 and not seat.low_pose:
			_check(str(p._sprite.animation).begins_with("sit_high_"), "Tall seat uses floor pose")
		elif seat.low_pose:
			_check(str(p._sprite.animation) == "sit_" + seat.dir, "Bench uses dangling high-chair legs")
		p.stand_up()
		p.position = old

func _people_access() -> void:
	var p := room.player
	var old := p.position
	for npc in get_tree().get_nodes_in_group("npc"):
		if not npc is Npc or npc.id not in ["amir", "leda", "teo", "olga"] or not npc.visible: continue
		var reachable := false
		for dir in ["down", "up", "left", "right"]:
			var v: Vector2 = Player.FACING_VECTORS[dir]
			p.position = npc.hotspot() - v * 22 + Vector2(0, 6)
			p.facing = dir
			if _feet_clear(p) and p._find_target() == npc:
				reachable = true; break
		_check(reachable, "Furniture prevents talking to " + str(npc.id))
	p.position = old

func _feet_clear(p: Player) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := RectangleShape2D.new(); shape.size = Vector2(14, 6)
	query.shape = shape
	query.transform = Transform2D(0, p.position + Vector2(0, -3))
	query.exclude = [p.get_rid()]
	query.collision_mask = 1
	return room.get_world_2d().direct_space_state.intersect_shape(query).is_empty()
