extends Node
## Il trailer: scene del gioco una dopo l'altra, con le frasi su nero. Si registra con --write-movie.
## La musica si aggiunge dopo con ffmpeg, qui il gioco è muto.

const FONT := preload("res://fonts/PixeloidSans-Bold.otf")
const GOLD := Color("ffe14d")

var card: ColorRect
var line: Label
var sub: Label
var frame := 0
var pedal := false
var skip_say := true
var slow_say := true


func _ready() -> void:
	GameState.save_path = "user://trailer.json"
	AudioServer.set_bus_mute(0, true)
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	card = ColorRect.new()
	card.color = Color.BLACK
	card.size = Vector2(640, 360)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(card)
	line = _label(22, Color.WHITE, 150)
	sub = _label(14, GOLD, 200)
	layer.add_child(line)
	layer.add_child(sub)
	await get_tree().process_frame
	await _run()
	get_tree().quit(0)


func _label(size: int, col: Color, y: float) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector2(20, y - 40)
	l.size = Vector2(600, 80)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _process(_d: float) -> void:
	frame += 1
	Ui.show_hud(false)
	if skip_say and Ui.busy and frame % (75 if slow_say else 4) == 0:
		_tap("confirm")
	if pedal and frame % 6 == 0:
		_tap("move_left" if frame % 12 == 0 else "move_right")


func _tap(action: String) -> void:
	for p in [true, false]:
		var e := InputEventAction.new()
		e.action = action
		e.pressed = p
		Input.parse_input_event(e)


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


## Una frase su nero: compare, resta, sparisce.
func _card(text: String, s: float, subtitle := "") -> void:
	line.text = text
	sub.text = subtitle
	line.add_theme_font_size_override("font_size", 40 if subtitle != "" else 22)
	for n: CanvasItem in [card, line, sub]:
		n.modulate.a = 1.0
		n.visible = true
	await _wait(s)


func _open_card() -> void:
	var tw := create_tween()
	for n: CanvasItem in [card, line, sub]:
		tw.parallel().tween_property(n, "modulate:a", 0.0, 0.35)
	await tw.finished


func _clear(scene: Node) -> void:
	if is_instance_valid(scene):
		scene.get_parent().remove_child(scene)
		scene.queue_free()
	Ui.cutscene = false
	Ui.transitioning = false
	await get_tree().process_frame


## Una stanza vera: la telecamera parte da `from` e scivola fino a `to` in `s` secondi.
func _room(path: String, from: Vector2, to: Vector2, zoom: float, s: float, walk := "") -> Room:
	var room: Room = await MappaAperta.apri(self, path)
	Ui.show_hud(false)
	for a in room.find_children("*", "Area2D", true, false):
		(a as Area2D).monitoring = false
	var cam := room.player.camera
	cam.top_level = true
	cam.position_smoothing_enabled = false
	cam.limit_left = -100000
	cam.limit_top = -100000
	cam.limit_right = 100000
	cam.limit_bottom = 100000
	cam.zoom = Vector2(zoom, zoom)
	cam.global_position = from
	if walk != "":
		room.player.set_physics_process(true)
		Input.action_press(walk)
	await _open_card()
	var tw := create_tween()
	tw.tween_property(cam, "global_position", to, s).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	if walk != "":
		Input.action_release(walk)
	return room


func _run() -> void:
	# 1. Benvenuto nella Torre: l'ascensore che scende (le sue frasi si leggono)
	await _card("Benvenuto nella Torre.", 2.0)
	GameState.new_game()
	var lift := (load(Router.ELEVATOR) as PackedScene).instantiate()
	get_tree().root.add_child(lift)
	get_tree().current_scene = lift
	await _open_card()
	await _wait(5.0)
	await _card("Il tuo debito è già pronto.", 0.8)
	await _clear(lift)
	slow_say = false

	# 2. il Fondo: la festa, Fermo seduto in alto
	var room := await _room(Router.FONDO, Vector2(110, 105), Vector2(250, 105), 2.0, 4.5)
	await _card("", 0.1)
	await MappaAperta.chiudi(self, room)

	# 3. il turno: la dinamo (istruzioni saltate)
	GameState.new_game()
	GameState.minigame = {"kind": "work", "game": "pedal", "name": "Il turno", "pay": 100, "intro": ["* Pedala."]}
	var work := (load(Router.WORK) as PackedScene).instantiate()
	get_tree().root.add_child(work)
	get_tree().current_scene = work
	await _wait(0.6)
	await _open_card()
	pedal = true
	await _wait(4.0)
	pedal = false
	await _card("Lavora. Paga. Sali.", 0.8)
	await _clear(work)

	# 4. i piani di sopra
	room = await _room(Router.SOTTOUFFICIO, Vector2(180, 150), Vector2(400, 150), 2.0, 3.0)
	await _card("", 0.1)
	await MappaAperta.chiudi(self, room)
	room = await _room(Router.MERCATO, Vector2(200, 160), Vector2(420, 160), 2.0, 3.0)
	await _card("Qualcuno, ai piani di sotto,
sta ancora pagando.", 0.8)
	await MappaAperta.chiudi(self, room)

	# 5. la festa perde il colore mentre cammini: diventa grigia
	var grey := CanvasLayer.new()
	grey.layer = 40
	add_child(grey)
	var rect := ColorRect.new()
	rect.size = Vector2(640, 360)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = "shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float amount = 0.0;
void fragment() {
	vec4 c = texture(screen_texture, SCREEN_UV);
	float g = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	COLOR = vec4(mix(c.rgb, vec3(g) * 0.85, amount), 1.0);
}"
	rect.material = mat
	grey.add_child(rect)
	var fade := create_tween()
	fade.tween_interval(3.2)
	fade.tween_method(func(v: float) -> void: mat.set_shader_parameter("amount", v), 0.0, 1.0, 3.0)
	room = await _room(Router.FONDO, Vector2(110, 120), Vector2(260, 120), 2.5, 4.8)
	await _card("CHEAP", 4.5, "Quanto costa una vita?")
	grey.queue_free()
	await MappaAperta.chiudi(self, room)
