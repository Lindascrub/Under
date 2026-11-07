extends Node

const Probe=preload("res://tests/fixtures/rate_probe.gd")
var current: Node
var ticks:=0
var failures: Array[String]=[]

func _ready() -> void:
	await get_tree().process_frame
	GameState.save_path="user://olga_input_regression.json"
	GameState.new_game()
	GameState.minigame={"type":"rate","title":"LE RATE MANCANTI","intro":[],"seed":17}
	# le scritte del minigioco sono nodi della sua scena: la sonda usa la scena vera
	current=load("res://scenes/minigame/minigame.tscn").instantiate()
	current.set_script(Probe)
	get_tree().root.add_child(current)
	get_tree().current_scene=current
	for i in 1200:
		if current.get("phase")=="play" and not Ui.blocks_input():break
		await get_tree().process_frame
	current.set_process(false)
	var baseline:="--baseline" in OS.get_cmdline_user_args()
	for index in [2,3]:
		current.set("phase","play");current.set("rate_phase","find")
		current.set("misses",0);current.set("won",false)
		await _click(current.call("_rate_row",index).get_center())
		print("OLGA click row ",index,": won=",current.get("won")," errors=",current.get("misses"))
		if bool(current.get("won"))==baseline:failures.append("Wrong result for original JSON row "+str(index))
	if not baseline:
		current.set("phase","play");current.set("rate_phase","find")
		current.set("misses",0);current.set("won",false)
		for i in 4:await _click(current.call("_rate_row",0).get_center())
		if current.get("phase")!="play":failures.append("Retry ended the puzzle")
		await _click(current.call("_rate_row",3).get_center())
		if not current.get("won"):failures.append("Could not finish after retry")
		current.set("phase","play");current.set("rate_phase","order")
		current.set("rate_placed",[]);current.set("misses",0)
		for doc in current.call("_rate_docs").size():
			var slot: int=current.get("rate_cards").find(doc)
			await _click(current.call("_rate_card",slot).get_center())
		if current.get("rate_phase")!="find":failures.append("Mouse document ordering did not reach statement")
		await _click(current.call("_rate_row",2).get_center())
		if not current.get("won"):failures.append("Mouse order/find journey failed")
		for size in [Vector2i(960,540),Vector2i(1000,800),Vector2i(1280,720)]:
			get_window().size=size
			for i in 8:await get_tree().process_frame
			current.set("phase","play");current.set("rate_phase","find");current.set("won",false)
			await _click(current.call("_rate_row",3).get_center())
			if not current.get("won"):failures.append("Mouse failed at "+str(size))
		current.set("phase","play");current.set("rate_phase","find");current.set("won",false);current.set("rate_sel",0)
		for i in 2:await _action("move_down")
		await _action("confirm")
		if not current.get("won"):failures.append("Keyboard selection failed")
		TouchControls.enabled=true
		current.set("phase","play");current.set("rate_phase","find");current.set("won",false)
		for i in 4:await get_tree().process_frame
		var point:Vector2=get_viewport().get_screen_transform()*current.get_global_transform_with_canvas()*(current.call("_rate_row",2) as Rect2).get_center()
		var finger:=InputEventScreenTouch.new();finger.index=0;finger.position=point;finger.pressed=true
		Input.parse_input_event(finger)
		await get_tree().process_frame
		finger=InputEventScreenTouch.new();finger.index=0;finger.position=point;Input.parse_input_event(finger)
		for i in 2:await get_tree().process_frame
		if not current.get("won"):failures.append("Touch original duplicate row failed")
	print("OLGA INPUT ","BASELINE" if baseline else "REGRESSION",": ",failures)
	Sound.music("")
	for child in Sound.get_children():
		if child is AudioStreamPlayer:child.stop();child.stream=null
	current.queue_free();get_tree().current_scene=self
	for i in 20:await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)

func _process(_delta: float) -> void:
	ticks+=1
	if is_instance_valid(current) and current.get("phase")=="intro" and Ui.busy and ticks%2==0:
		var event:=InputEventAction.new();event.action="confirm";event.pressed=true;Input.parse_input_event(event)
		event=InputEventAction.new();event.action="confirm";Input.parse_input_event(event)

func _click(point: Vector2) -> void:
	# Input.parse_input_event riceve coordinate finestra; Godot le converte nel viewport.
	point=get_viewport().get_screen_transform()*current.get_global_transform_with_canvas()*point
	var event:=InputEventMouseButton.new()
	event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.button_mask=MOUSE_BUTTON_MASK_LEFT;event.pressed=true
	Input.parse_input_event(event)
	await get_tree().process_frame
	event=InputEventMouseButton.new()
	event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT
	Input.parse_input_event(event)
	for i in 2:await get_tree().process_frame

func _action(action:String) -> void:
	var event:=InputEventAction.new();event.action=action;event.pressed=true;Input.parse_input_event(event)
	await get_tree().process_frame
	event=InputEventAction.new();event.action=action;Input.parse_input_event(event)
	await get_tree().process_frame
