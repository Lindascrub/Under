extends Node

var room: Room
var failures: Array[String] = []
var ticks := 0
var checks := 0
var output := ""

func _ready() -> void:
	await get_tree().process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	GameState.save_path="user://booth_stair_private_test.json"
	# A missing badge must still stop the player at the turnstile.
	await _open(Router.SOTTOUFFICIO,false)
	await _walk_up(100)
	_check(is_instance_valid(room) and get_tree().current_scene==room,"Stairs bypass badge gate")
	_check(room.player.position.y>50,"Closed gate can be crossed")
	await _close()
	var cases := [
		[Router.FONDO,Router.SOTTOUFFICIO,"c1"],
		[Router.SOTTOUFFICIO,Router.MERCATO,"c2"],
		[Router.MERCATO,Router.BANCA,"c3"],
		[Router.BANCA,Router.CITY,"c4"],
		[Router.CITY,Router.CIMA,"c5"]]
	for item: Array in cases:
		await _open(str(item[0]),true)
		var booth := room._badge_booth
		var area := Rect2(booth.global_position+Vector2(0,-64),Vector2(96,64))
		for seat in room.find_children("*","Seat",true,false):
			_check(not area.has_point(seat.global_position),str(item[2])+" has a seat inside ticket booth")
		for s in room.find_children("*","Sprite2D",true,false):
			if booth.is_ancestor_of(s) or not s.texture:continue
			if str(item[2])=="c5" and str(s.name) in ["Torre","InsegnaEsterno"]:continue
			_check(not area.intersects(PropTalk._rect(s)),str(item[2])+" old sprite painted through booth: "+str(s.name))
		if str(item[2])=="c1":
			var bike:=room.get_node("Mondo/CycletteDinamo") as Sprite2D
			_check(bike != null and bike.texture.resource_path=="res://assets/limezu/themes/gym.png" and bike.region_rect==Rect2(96,480,32,32),"Original gym bike was not restored")
			_check(not room.has_node("Mondo/Divano"),"Old hidden sofa remains")
			await _shot("cyclette_originale",Vector2(74,100),4)
			await _shot("biglietteria_pulita",booth.global_position+Vector2(50,-24),4)
		if str(item[2])=="c2":
			_check(not room.has_node("Mondo/Libreria26"),"Shelf still covers the stair lane")
			for name_ in ["PosterSorridi","PosterModulo","PosterAttesa"]:
				var poster:=room.find_child(name_,true,false) as Node2D
				_check(is_zero_approx(poster.rotation),name_+" is tilted")
				_check(poster.get("broken"),name_+" is not worn after reveal")
				var size:Vector2=poster.call("paper_size")
				room.player.position=poster.position+Vector2(size.x/2,16)
				room.player.face("up")
				var hit:=room.player.move_and_collide(Vector2(0,-64),true)
				_check(hit != null,name_+" can be walked through")
				_check(poster.position.y<=48,name_+" has fallen onto floor")
			# il divano si può togliere nell'editor: se c'è, deve essere quello giusto
			var sofa:=room.get_node_or_null("Mondo/DivanoRelax") as Sprite2D
			if sofa:
				_check(sofa.region_rect==Rect2(112,448,32,32),"Sofa includes an unfinished extension tile")
				var count:=0
				var r:=PropTalk._rect(sofa)
				for seat in room.find_children("*","Seat",true,false):
					if Rect2(r.position,r.size+Vector2(0,4)).has_point(seat.position):count+=1
				_check(count==2,"Sofa has seats outside its actual width")
			room.player.position=Vector2(122,66);room.player.face("up")
			await _shot("manifesti_appesi_divano",Vector2(142,45),3)
			room.player.position=room._stairs_up_exit+Vector2(0,20);room.player.face("up")
			await _shot("scala_libera",room._stairs_up_exit+Vector2(-12,-16),3)
		# Enter from the real floor, keep walking until the next scene is loaded.
		await _walk_up(240)
		var transition:=Ui.transitioning or Ui.cutscene or not is_instance_valid(room) or get_tree().current_scene!=room
		_check(transition,str(item[2])+" cannot ascend from floor to next chapter")
		for i in 3600:
			await get_tree().process_frame
			if get_tree().current_scene != room and not Ui.blocks_input():break
		var destination:=get_tree().current_scene
		_check(destination.scene_file_path==str(item[1]),str(item[2])+" stairs arrived at "+destination.scene_file_path)
		print("WALKED STAIRS ",item[2]," -> ",destination.scene_file_path)
		if destination != room and destination != self:
			get_tree().current_scene=self;destination.queue_free()
		if is_instance_valid(room):room.queue_free()
		room=null;Ui.cutscene=false;Ui.transitioning=false
		for i in 6:await get_tree().process_frame
	await _open(Router.CIMA,true)
	var copy:=room.get_node("Mondo/CycletteVecchia") as Sprite2D
	_check(copy != null and copy.texture.resource_path=="res://assets/limezu/themes/gym.png","Cima still uses homemade bike")
	await _close()
	print("BOOTH ACCESS: ",checks," checks, failures=",failures)
	Sound.music("");get_tree().quit(0 if failures.is_empty() else 1)

func _walk_up(frames: int) -> void:
	room.player.position=room._stairs_up_exit+Vector2(0,20)
	room.player.face("up");room.player.set_physics_process(true)
	Input.action_press("move_up")
	for i in frames:
		await get_tree().physics_frame
		if Ui.transitioning or not is_instance_valid(room) or get_tree().current_scene!=room:break
	Input.action_release("move_up")
	if is_instance_valid(room):room.player.set_physics_process(false)

func _open(path:String,badge:bool) -> void:
	GameState.new_game()
	for f in ["c1_arrivo","c1_intro","c2_arrivo","c3_arrivo","c4_arrivo","c5_arrivo","c6_arrivo","c1_rivelazione","c2_rivelazione","c3_rivelazione","c4_rivelazione","c5_rivelazione","c1_fine","c2_fine","c3_fine","c4_fine"]:GameState.flags[f]=true
	if badge:GameState.badges.assign(["-4","-3","-2","-1","0","cima"])
	Router.spawn="_save";Router.save_pos=Vector2(200,160)
	room=load(path).instantiate() as Room
	get_tree().root.add_child(room);get_tree().current_scene=room
	room.player.set_physics_process(false)
	for i in 240:
		await get_tree().process_frame
		if i>40 and not Ui.blocks_input():break
	for i in 3:await get_tree().physics_frame

func _close() -> void:
	get_tree().current_scene=self
	if is_instance_valid(room):room.queue_free()
	room=null;Ui.cutscene=false;Ui.transitioning=false
	for i in 6:await get_tree().process_frame

func _process(_delta:float) -> void:
	ticks+=1
	if Ui.busy and ticks%3==0:
		if Ui.get("_mode")=="choose":Ui.set("_sel",1)
		var e:=InputEventAction.new();e.action="confirm";e.pressed=true;Input.parse_input_event(e)
		e=InputEventAction.new();e.action="confirm";Input.parse_input_event(e)

func _check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures.append(message);push_error(message)

func _shot(name_:String,center:Vector2,zoom:float) -> void:
	if output=="" or DisplayServer.get_name()=="headless":return
	var cam:=room.player.camera
	var saved:={"top":cam.top_level,"position":cam.position,"zoom":cam.zoom,"offset":cam.offset,"limits":[cam.limit_left,cam.limit_top,cam.limit_right,cam.limit_bottom]}
	cam.top_level=true;cam.offset=Vector2.ZERO;cam.position_smoothing_enabled=false
	cam.limit_left=-100000;cam.limit_top=-100000;cam.limit_right=100000;cam.limit_bottom=100000
	cam.zoom=Vector2(zoom,zoom);cam.global_position=center
	Ui.show_hud(false)
	for i in 10:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(name_+".png"))
	cam.top_level=saved.top;cam.position=saved.position;cam.zoom=saved.zoom;cam.offset=saved.offset
	cam.limit_left=saved.limits[0];cam.limit_top=saved.limits[1];cam.limit_right=saved.limits[2];cam.limit_bottom=saved.limits[3]
	Ui.show_hud(true)
