class_name Looks
extends RefCounted
## L'aspetto delle persone vere (data/looks.json). Sono tutte grigie, e i fogli LimeZu si somigliano:
## così ognuna ha un grigio suo (più caldo, più freddo, più chiaro), UN dettaglio a colori (un casco,
## una sciarpa, un fiore: art/people/<nome>.png, 16x32, sopra la cornice del personaggio) e un gesto
## suo quando sta ferma. Chi diventa robot li perde tutti: è proprio quello che il sistema gli toglie.
##
## Uso: Looks.apply(sprite, "nadir", true)   (sprite = AnimatedSprite2D con offset (-8, -31))

const DATA := "res://data/looks.json"
const ART := "res://art/people/"
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


## Applica grigio personale, dettaglio e gesto. `grey` = è una persona vera in un mondo colorato.
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
	var acc := str(d.get("accessory", ""))
	if acc != "" and ResourceLoader.exists(ART + acc + ".png") and not sprite.has_node("Dettaglio"):
		var s := Sprite2D.new()
		s.name = "Dettaglio"
		s.texture = load(ART + acc + ".png")
		s.centered = false
		s.offset = sprite.offset
		# il dettaglio resta a colori: non eredita il grigio
		s.use_parent_material = false
		s.material = null
		sprite.add_child(s)
		if bool(d.get("front_only", false)):
			# un dettaglio sul davanti (una spilla) non si vede da dietro
			var sync := func() -> void: s.visible = not str(sprite.animation).ends_with("_up")
			sprite.animation_changed.connect(sync)
			sync.call()
	var tic: Dictionary = d.get("tic", {})
	if not tic.is_empty() and not sprite.has_node("Gesto"):
		var timer := Timer.new()
		timer.name = "Gesto"
		timer.wait_time = float(tic.get("every", 7.0)) * randf_range(0.8, 1.2)
		timer.autostart = true
		sprite.add_child(timer)
		timer.timeout.connect(_tic.bind(sprite, str(tic.get("anim", "idle_up")), timer))


## Toglie dettaglio e gesto (quando una persona diventa robot davanti a te).
static func strip(sprite: AnimatedSprite2D) -> void:
	for n: String in ["Dettaglio", "Gesto"]:
		if sprite.has_node(n):
			sprite.get_node(n).queue_free()


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
