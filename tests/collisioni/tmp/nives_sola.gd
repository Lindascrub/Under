extends Node
func _ready() -> void:
	var path := "res://chapters/c5/citta.tscn"
	var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	var mondo := root.get_node("Mondo")
	var old := mondo.get_node("SportelloBadge") as Node2D
	var old_clerk := old.get_node("Addetta") as AnimatedSprite2D
	var old_frame := old.get_node("InquadraturaAddetta") as Node2D
	var booth := Node2D.new()
	booth.name = "SportelloBadge"
	booth.set_script(load("res://world/badge_booth.gd"))
	booth.position = old.position
	booth.y_sort_enabled = true
	booth.set_meta("prop_talk_skip", true)
	var clerk := AnimatedSprite2D.new()
	clerk.name = "Addetta"
	clerk.set_script(load("res://world/char_sprite.gd"))
	clerk.position = old_clerk.position
	clerk.centered = false
	clerk.offset = old_clerk.offset
	clerk.set("sheet", old_clerk.get("sheet"))
	clerk.set("anim", old_clerk.get("anim"))
	booth.add_child(clerk)
	var body := StaticBody2D.new()
	body.name = "Ingombro"
	clerk.add_child(body)
	var shape := CollisionShape2D.new()
	shape.name = "Forma"
	shape.position = Vector2(0, -3)
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 6)
	shape.shape = r
	body.add_child(shape)
	var frame := Marker2D.new()
	frame.name = "InquadraturaAddetta"
	frame.set_script(load("res://world/inquadratura.gd"))
	frame.position = old_frame.position
	for k in ["zoom", "durata", "durata_ritorno", "velocita_inseguimento"]:
		frame.set(k, old_frame.get(k))
	booth.add_child(frame)
	var idx := old.get_index()
	mondo.remove_child(old)
	old.free()
	mondo.add_child(booth)
	mondo.move_child(booth, idx)
	for n: Node in [booth, clerk, body, shape, frame]:
		n.owner = root
	var packed := PackedScene.new()
	print("pack ", packed.pack(root))
	print("save ", ResourceSaver.save(packed, path))
	get_tree().quit(0)
