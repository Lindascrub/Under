extends Node
func _premi(a: String) -> void:
	var e := InputEventAction.new(); e.action = a; e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame
	var u := InputEventAction.new(); u.action = a; u.pressed = false
	Input.parse_input_event(u)
	for i in 5: await get_tree().process_frame
func _ready() -> void:
	await get_tree().process_frame
	var v0 := Sound.volume("SFX")
	Ui.settings_menu()
	for i in 5: await get_tree().process_frame
	await _premi("move_down")
	print("prima: sel=", Ui.get("_sel"))
	await _premi("confirm")
	for i in 10: await get_tree().process_frame
	print("dopo effetti: sel=", Ui.get("_sel"), " (1 = Effetti)")
	await _premi("confirm")
	for i in 10: await get_tree().process_frame
	print("ancora: sel=", Ui.get("_sel"))
	Sound.set_volume("SFX", v0)
	get_tree().quit(0)
