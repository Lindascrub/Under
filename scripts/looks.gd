class_name Looks
extends RefCounted
## L'aspetto delle persone vere (data/looks.json). Sono grigie, ma di un grigio sbiadito che tiene il contrasto
## e un filo del colore del loro personaggio, un po' più caldo o più freddo per ognuna; e hanno un gesto
## loro quando stanno ferme. Chi diventa robot perde il gesto: è proprio quello che il sistema gli toglie.
##
## Uso: Looks.apply(sprite, "nadir", true)   (sprite = AnimatedSprite2D con offset (-8, -31))

const DATA := "res://data/looks.json"
const GREY := preload("res://shaders/greyscale.gdshader")

static var _data := {}


static func data(id: String) -> Dictionary:
	if _data.is_empty():
		var f := FileAccess.open(DATA, FileAccess.READ)
		if f:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				_data = parsed
	var d: Variant = _data.get(id, {})
	return d if d is Dictionary else {}


## Applica il grigio personale e il gesto. `grey` = è una persona vera in un mondo colorato.
static func apply(sprite: AnimatedSprite2D, id: String, grey: bool) -> void:
	var d := data(id)
	if grey:
		var m := ShaderMaterial.new()
		m.shader = GREY
		var t: Array = d.get("tint", [1.0, 1.0, 1.0])
		m.set_shader_parameter("tint", Vector3(float(t[0]), float(t[1]), float(t[2])))
		# sbiadite ma riconoscibili: il contrasto resta, e un filo del colore di prima
		m.set_shader_parameter("person", 1.0)
		sprite.material = m
	if d.is_empty():
		return
	var tic: Dictionary = d.get("tic", {})
	if not tic.is_empty() and not sprite.has_node("Gesto"):
		var timer := Timer.new()
		timer.name = "Gesto"
		timer.wait_time = float(tic.get("every", 7.0)) * randf_range(0.8, 1.2)
		timer.autostart = true
		sprite.add_child(timer)
		timer.timeout.connect(_tic.bind(sprite, str(tic.get("anim", "idle_up")), timer))


## Toglie il gesto (quando una persona diventa robot davanti a te).
static func strip(sprite: AnimatedSprite2D) -> void:
	if sprite.has_node("Gesto"):
		sprite.get_node("Gesto").queue_free()


## Il gesto: per un momento la persona fa la sua cosa, poi torna com'era. Solo se sta ferma.
static func _tic(sprite: AnimatedSprite2D, anim: String, timer: Timer) -> void:
	timer.wait_time = randf_range(timer.wait_time * 0.8, timer.wait_time * 1.2)
	var was := str(sprite.animation)
	if not was.begins_with("idle") or was == anim or not sprite.sprite_frames.has_animation(anim):
		return
	if Ui.busy:
		return
	sprite.play(anim)
	await sprite.get_tree().create_timer(1.8).timeout
	if is_instance_valid(sprite) and str(sprite.animation) == anim:
		sprite.play(was)
