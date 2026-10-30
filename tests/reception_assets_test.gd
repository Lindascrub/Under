extends Node

var room: Room
var ticks:=0
var auto_dialogue:=true
var gift_done:=false
var failures:Array[String]=[]
var output:=""
var farthest:=0.0
var nearest:=INF
var gate_frames:={}
var watch_n:=0
var watch_bad:=0

func _ready() -> void:
	await get_tree().process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	GameState.save_path="user://reception_20261028_test.json"
	var lift:=Lift.new();add_child(lift)
	await lift.open(false)
	_check(lift._frame==7 and lift._spr.texture.resource_path=="res://assets/limezu/animations/elevator_glass.png","Glass elevator did not open with original art")
	await lift.close(false)
	lift.set_off(true)
	_check(lift._frame==0 and lift._spr.texture.resource_path=="res://assets/limezu/animations/elevator_glass.png","Out-of-service elevator changed style")
	lift.queue_free()
	GameState.new_game()
	GameState.flags["c1_arrivo"]=true
	Router.spawn="_save";Router.save_pos=Vector2(220,170)
	room=load(Router.FONDO).instantiate()
	get_tree().root.add_child(room);get_tree().current_scene=room
	await _frames(20)
	room.player.set_physics_process(false)
	var booth:Node2D=room._badge_booth
	var clerk:AnimatedSprite2D=booth.clerk
	var home:=clerk.global_position
	Ui.show_hud(false)
	_camera(booth.global_position+Vector2(64,-24),4)
	await _shot("biglietteria_chiusa")
	_check(not GameState.flags.get("badge_clerk_intro",false),"Test requires never having spoken to clerk")
	_check(room._turnstiles.size()==1 and room._turnstiles[0].current_frame==0,"Turnstile should begin closed")
	GameState.helped_ids.assign(["fermo","mina","bulbo"])
	_finish_gift()
	var photographed:=false
	for i in 2400:
		await get_tree().process_frame
		var distance:=clerk.global_position.distance_to(room.player.global_position)
		nearest=minf(nearest,distance)
		farthest=maxf(farthest,clerk.global_position.distance_to(home))
		if distance<32 and not photographed:
			photographed=true
			_camera((clerk.global_position+room.player.global_position)/2+Vector2(0,-10),3)
			await _shot("addetta_ti_raggiunge")
		if room._watched!=null and i%20==0:
			var dv:=clerk.global_position-room.player.global_position
			var want:=("right" if dv.x>0 else "left") if absf(dv.x)>absf(dv.y) else ("down" if dv.y>0 else "up")
			watch_n+=1
			if room.player.facing!=want:watch_bad+=1
		if gift_done:break
	_check(gift_done,"Gift animation did not finish")
	_check(watch_n>3 and watch_bad<=1,"Player did not keep facing Nives (%d/%d)"%[watch_bad,watch_n])
	_check(room._watched==null,"Still watching Nives after she left")
	_check(nearest<=32 and farthest>80,"Clerk did not approach the player")
	_check(clerk.global_position.distance_to(home)<1,"Clerk did not return to booth")
	_check(GameState.has_badge("-4") and GameState.flags.get("clerk_friend",false),"Gift did not grant badge/friendship")
	_check(room._turnstiles[0].current_frame==4,"Turnstile did not animate open")
	_check(gate_frames.has(0) and gate_frames.has(1) and gate_frames.has(2) and gate_frames.has(3) and gate_frames.has(4),"Turnstile skipped its animation")
	_check(not Ui.cutscene,"Gift left movement blocked")
	_camera(booth.global_position+Vector2(64,-24),4)
	await _shot("biglietteria_aperta")
	print("RECEPTION REGRESSION: ",failures," nearest=",nearest," moved=",farthest)
	get_tree().current_scene=self;room.queue_free();room=null
	await _frames(10)
	GameState.new_game();GameState.flags["c2_arrivo"]=true
	Router.spawn="_save";Router.save_pos=Vector2(184,104)
	room=load(Router.SOTTOUFFICIO).instantiate()
	get_tree().root.add_child(room);get_tree().current_scene=room
	await _frames(30);room.player.set_physics_process(false)
	_camera(Vector2(328,194),4)
	await _shot("scrivania_tritacarte")
	_camera(Vector2(182,51),4)
	await _shot("divano_manifesti")
	room.player.global_position=Vector2(152,104);room.player.face("up")
	room.player.camera.top_level=false;room.player.camera.position=Vector2.ZERO
	room.player.camera.zoom=Vector2(2,2)
	room.player.camera.limit_left=int(room.cam_rect.position.x);room.player.camera.limit_top=int(room.cam_rect.position.y)
	room.player.camera.limit_right=int(room.cam_rect.end.x);room.player.camera.limit_bottom=int(room.cam_rect.end.y)
	Ui.show_hud(true)
	await _frames(60)
	await _shot("manifesti_in_partita")
	get_tree().current_scene=self;room.queue_free();room=null
	Sound.music("")
	for child in Sound.get_children():
		if child is AudioStreamPlayer:child.stop();child.stream=null
	await _frames(10)
	get_tree().quit(0 if failures.is_empty() else 1)

func _finish_gift() -> void:
	await room._floor_gift()
	gift_done=true

func _process(_delta:float) -> void:
	ticks+=1
	if is_instance_valid(room) and room._turnstiles.size()>0:gate_frames[room._turnstiles[0].current_frame]=true
	if auto_dialogue and Ui.busy and ticks%2==0:
		var event:=InputEventAction.new();event.action="confirm";event.pressed=true;Input.parse_input_event(event)
		event=InputEventAction.new();event.action="confirm";Input.parse_input_event(event)

func _check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)

func _frames(count:int) -> void:
	for i in count:await get_tree().process_frame

func _camera(at:Vector2,zoom:float) -> void:
	var cam:=room.player.camera
	cam.top_level=true;cam.position_smoothing_enabled=false
	cam.limit_left=-100000;cam.limit_top=-100000;cam.limit_right=100000;cam.limit_bottom=100000
	cam.zoom=Vector2(zoom,zoom);cam.global_position=at;cam.reset_smoothing()

func _shot(name:String) -> void:
	if output=="" or DisplayServer.get_name()=="headless":return
	await _frames(8)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(name+".png"))
