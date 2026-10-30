extends Node

const RouteProbe = preload("res://tests/fixtures/rate_probe.gd")
var room: Room
var mg: Node2D
var failures: Array[String] = []
var checks := 0
var ticks := 0
var output := ""
var camera_seen := false
var camera_at := Vector2.ZERO
var record_camera := false
var shots := {}

func _ready() -> void:
	await get_tree().process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
	GameState.save_path = "user://interactions_chapters_regression.json"
	await _open(Router.SOTTOUFFICIO)
	_check(not room.has_node("Mondo/Scatoloni0") and not room.has_node("Mondo/Scatoloni1"), "Ercole still has box stacks")
	var p := room.player
	for i in 4:
		var spot := room.find_child("GuardaCollega%d" % i, true, false) as Interactable
		p.position = spot.position + Vector2(0, -48); p.face("down")
		_check(p._find_target() == spot, "Worker %d cannot be approached from behind" % i)
		p.position = spot.position + Vector2(0, 23); p.face("up")
		_check(p._find_target() == spot, "Worker %d lost front interaction" % i)
	var station := _station("callcenter")
	p.position = Vector2(136, 128); p.face("down")
	_check(p._find_target() == station, "Callcenter monitor not usable from operator side")
	p.position = Vector2(136, 195); p.face("up")
	_check(p._find_target() != station, "Callcenter work starts behind wrong side of table")
	p.position = Vector2(64, 74); p.face("down")
	await _shot("lavoratori_dietro", Vector2(112, 96), 3.0)
	await _shot("sedie_ufficio", Vector2(344, 128), 3.0)
	p.position = room._stairs_up_exit
	var saved_zoom := p.camera.zoom
	record_camera = true; camera_seen = false
	await room.call("on_stairs_step", p, "-3")
	record_camera = false
	_check(camera_seen and camera_at.distance_to(Vector2(352, 223)) < 5, "B4 was shredded outside the camera")
	_check(not p.camera.top_level and p.camera.zoom == saved_zoom, "C2 camera did not return to player")
	_check(not Ui.cutscene and bool(GameState.flags.get("c2_rivelazione", false)), "C2 ending left controls blocked")
	_check(room.get("_ring_voices").size() == 4 and room.get("_ring_intense"), "Unanswered ringing did not build up")
	for name_ in ["PosterSorridi", "PosterModulo", "PosterAttesa"]:
		var poster := room.find_child(name_, true, false)
		_check(poster.get("broken") and is_zero_approx(poster.rotation), name_+" must stay hanging while worn")
	_check(room.get_node("Pavimento").material != null, "C2 office stayed colorful")
	await _shot("ufficio_finale", Vector2(200, 115), 1.9)
	await _close()
	await _open(Router.SOTTOUFFICIO, {"c2_rivelazione":true})
	_check(room.find_child("PosterModulo",true,false).get("broken"), "Broken posters not restored on return")
	_check(room.get_node("Pavimento").material != null, "Gray office not restored")
	await _close()
	await _open(Router.MERCATO)
	p = room.player
	station = _station("cassa_mercato")
	p.position = Vector2(200, 238); p.face("left")
	_check(p._find_target() == station, "Checkout monitor cannot start work")
	p.position = Vector2(153, 238); p.face("right")
	_check(p._find_target() != station, "Checkout starts from customer side")
	var sale := room.find_child("GuardaSaldi", true, false)
	p.position = Vector2(184, 80); p.face("up")
	_check(p._find_target() != sale, "50% sign still usable from vending machine")
	p.position = Vector2(160, 68); p.face("up")
	_check(p._find_target() == sale, "50% sign cannot be read nearby")
	for name_ in ["Bancone0", "Bancone1", "BancoFrigo0", "BancoFrigo1", "Frigo1", "Scatoloni", "ScatolaAmir0"]:
		var spr := room.find_child(name_, true, false) as Sprite2D
		var r := PropTalk._rect(spr)
		p.position = Vector2(r.get_center().x, r.end.y+16); p.face("up")
		_check(p._find_target() != null, name_+" has no interaction")
	# The cashier bay is empty space; the conveyor and the right arm are solid.
	var register := room.find_child("CassaTurno", true, false) as Sprite2D
	_check(not _solid(register, Vector2(22,-30)), "Cashier bay is an invisible wall")
	_check(_solid(register, Vector2(7,-22)), "Conveyor can be walked through")
	_check(_solid(register, Vector2(29,-22)), "Checkout right arm can be walked through")
	var pallet := room.find_child("Pallet0",true,false) as Sprite2D
	_check(not _solid(pallet, Vector2(3,-46)), "Empty upper pallet corner has an invisible wall")
	_check(_solid(pallet, Vector2(20,-9)), "Pallet table has no solid base")
	var shelf := room.find_child("Aria",true,false) as Sprite2D
	_check(not _solid(shelf, Vector2(30,-8)), "Empty roller shelf blocks transparent right margin")
	_check(_solid(shelf, Vector2(20,-8)), "Roller shelf lost its solid base")
	p.position = Vector2(152,74);p.face("left")
	await _shot("scaffale_laterale",Vector2(112,72),4.0)
	p.position = Vector2(470,196);p.face("left")
	await _shot("pallet_magazzino",Vector2(448,201),3.5)
	for seat in room.find_children("*","Seat",true,false):
		if not seat.get_meta("bench",false): continue
		var side: Vector2 = seat.approach
		p.position = seat.position + side*17; p.face("left" if side.x > 0 else "right")
		_check(p._find_target() == seat, "Bench cannot be used from the seat side")
		p.position = seat.position - side*17; p.face("right" if side.x > 0 else "left")
		_check(p._find_target() != seat, "Bench still seats player on its back")
		p.position = seat.position + side*17
		await seat.interact()
		_check(p.seated and str(p._sprite.animation)=="sit_"+seat.dir, "Bench has dangling high-chair legs")
		await _shot("panchina_"+seat.dir, seat.position+Vector2(0,-12), 4.0)
		p.stand_up()
	p.position = Vector2(200, 238); p.face("left")
	await _shot("cassa_turno", Vector2(180, 231), 4.0)
	camera_seen = false; record_camera = true
	await room.call("_price_update")
	record_camera = false
	_check(camera_seen and camera_at.distance_to(Vector2(256,60)) < 5, "Price change was off-camera")
	_check(room.call("board").texture.resource_path.ends_with("price_board_nuovo.png"), "Prices did not change visibly")
	_check(not p.camera.top_level and not Ui.cutscene, "Price announcement left camera or input locked")
	await _close()
	await _open(Router.MERCATO, {"c3_leda_inventario":true,"c3_amir_aiutato":true,"c3_amir_sogno":true,"c3_leda_mamma":true,"c3_prezzi":true})
	for name_ in ["SedutaLeda","SedutoAmir"]:
		var seated := room.find_child(name_,true,false) as CharSprite
		_check(seated != null and is_equal_approx(seated.position.y,246), name_+" is off the bench")
	await _shot("pausa_leda_amir", Vector2(520,234), 4.0)
	await _close()
	await _routes()
	print("INTERACTIONS CHAPTERS: ",checks," checks, failures=",failures)
	Sound.music("")
	get_tree().quit(0 if failures.is_empty() else 1)

func _process(_delta: float) -> void:
	ticks += 1
	if room and record_camera and room.player.camera.top_level and is_equal_approx(room.player.camera.zoom.x, 3.5 if room.scene_file_path == Router.SOTTOUFFICIO else 3.0):
		camera_seen = true; camera_at = room.player.camera.global_position
		var label := "documento_b4" if room.scene_file_path == Router.SOTTOUFFICIO else "aumento_prezzi"
		if not shots.has(label):
			shots[label] = true; _capture(label)
		if room.find_child("B4DaTritare",true,false) and not shots.has("documento_b4_triturato"):
			shots["documento_b4_triturato"]=true;_capture("documento_b4_triturato")
		if room.scene_file_path == Router.MERCATO and room.call("board").texture.resource_path.ends_with("price_board_nuovo.png") and not shots.has("prezzi_aggiornati"):
			shots["prezzi_aggiornati"]=true;_capture("prezzi_aggiornati")
	if Ui.busy and ticks % 4 == 0:
		if Ui.get("_mode") == "choose": Ui.set("_sel",1)
		_event("confirm")

func _open(path: String, flags := {}) -> void:
	GameState.new_game()
	for flag in ["c1_intro","c1_arrivo","c2_arrivo","c3_arrivo","c4_arrivo"]: GameState.flags[flag] = true
	GameState.flags.merge(flags,true)
	Router.spawn="_save"; Router.save_pos=Vector2(200,130)
	room=load(path).instantiate() as Room
	get_tree().root.add_child(room); get_tree().current_scene=room
	room.player.set_physics_process(false)
	for i in 180:
		await get_tree().process_frame
		if i>45 and not Ui.blocks_input(): break
	for i in 2: await get_tree().physics_frame

func _close() -> void:
	get_tree().current_scene=self
	room.queue_free();room=null
	Ui.cutscene=false;Ui.transitioning=false
	for i in 5: await get_tree().process_frame

func _station(id: String) -> Interactable:
	for n in get_tree().get_nodes_in_group("interactable"):
		if n.get_meta("job_id","") == id:return n
	return null

func _solid(spr: Sprite2D, local: Vector2) -> bool:
	var query:=PhysicsPointQueryParameters2D.new();query.position=spr.to_global(local)
	for hit in room.get_world_2d().direct_space_state.intersect_point(query):
		if spr.is_ancestor_of(hit.collider): return true
	return false

func _routes() -> void:
	GameState.minigame={"type":"route","title":"L'ULTIMA CONSEGNA","intro":[],"seed":17}
	mg=RouteProbe.new();get_tree().root.add_child(mg);get_tree().current_scene=mg
	for i in 40: await get_tree().process_frame
	_check(mg.get("phase")=="play","Amir did not start")
	await _capture("amir_mappa")
	# Reach every parcel using the safe itinerary; exercise actual input at different sizes.
	var plan := [2,5,4,2,5,6]
	for i in plan.size():
		var target: int=plan[i]
		for frame in 40:await get_tree().process_frame
		var choices: Array=mg.call("_rt_neighbors",mg.get("rt_at"))
		var index:=choices.find(target)
		_check(index>=0,"Safe route is disconnected")
		if index<0:break
		if i==0:
			mg.set("rt_sel",0)
			for j in index:_event("move_down");await get_tree().process_frame
			_event("confirm")
			for j in 3:await get_tree().process_frame
		elif i==3:
			get_window().size=Vector2i(1000,800)
			for j in 8:await get_tree().process_frame
			await _tap_card(index,true)
		else:
			await _tap_card(index,false)
		_check(int(mg.get("rt_at"))==target or i in [2,5],"Selected route did not move")
		print("ROUTE step=",i," at=",mg.get("rt_at")," map=",mg.get("rt_map")," left=",mg.get("rt_left")," total=",mg.get("rt_total")," phase=",mg.get("phase"))
	for i in 50:await get_tree().process_frame
	_check(mg.get("won") and int(mg.get("rt_total"))==6,"Safe deliveries cannot be completed")
	get_tree().current_scene=self;mg.queue_free();mg=null
	for i in 5:await get_tree().process_frame

func _tap_card(index: int, touch: bool) -> void:
	var local: Vector2=(mg.call("_rt_card",index) as Rect2).get_center()
	var point:Vector2=get_viewport().get_screen_transform()*mg.get_global_transform_with_canvas()*local
	if touch:
		TouchControls.enabled=true
		var event:=InputEventScreenTouch.new();event.position=point;event.index=0;event.pressed=true;Input.parse_input_event(event)
		await get_tree().process_frame
		event=InputEventScreenTouch.new();event.position=point;event.index=0;Input.parse_input_event(event)
		TouchControls.enabled=false
	else:
		var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;Input.parse_input_event(event)
		await get_tree().process_frame
		event=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;Input.parse_input_event(event)
	for i in 2:await get_tree().process_frame

func _event(action: String) -> void:
	var ev:=InputEventAction.new();ev.action=action;ev.pressed=true;Input.parse_input_event(ev)
	ev=InputEventAction.new();ev.action=action;Input.parse_input_event(ev)

func _check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures.append(message);push_error(message)

func _shot(label: String, center: Vector2, zoom: float) -> void:
	if output=="":return
	var cam:=room.player.camera
	var old_pos:=cam.position;var old_zoom:=cam.zoom;var old_top:=cam.top_level
	var limits:=[cam.limit_left,cam.limit_top,cam.limit_right,cam.limit_bottom]
	cam.top_level=true;cam.offset=Vector2.ZERO;cam.position_smoothing_enabled=false
	cam.limit_left=-100000;cam.limit_top=-100000;cam.limit_right=100000;cam.limit_bottom=100000
	cam.global_position=center;cam.zoom=Vector2(zoom,zoom)
	for i in 5:await get_tree().process_frame
	await _capture(label)
	cam.top_level=old_top;cam.position=old_pos;cam.zoom=old_zoom
	cam.limit_left=limits[0];cam.limit_top=limits[1];cam.limit_right=limits[2];cam.limit_bottom=limits[3]

func _capture(label: String) -> void:
	if output=="":return
	for i in 2:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(label+".png"))
