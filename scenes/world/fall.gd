extends Node2D
## L'inizio, come la caduta di Undertale: il debito ti fa precipitare in un mondo
## fatto di soldi, bollette e lettere della banca. Atterri davanti a un ascensore
## che ti porta giù, nel Sottoufficio.

var _player: AnimatedSprite2D
var _falling := true
var _things: Array[Dictionary] = []
var _doors := 0.0
var _show_lift := false


func _ready() -> void:
	Ui.show_hud(false)
	Ui.cutscene = true
	Sound.music("notte")
	var bg := ColorRect.new()
	bg.color = Color("0b0a10")
	bg.size = Vector2(640, 360)
	bg.z_index = -10
	add_child(bg)
	for i in 40:
		_things.append({
			"pos": Vector2(randf_range(0, 640), randf_range(-360, 360)),
			"speed": randf_range(80, 220),
			"kind": ["coin", "bill", "letter"][i % 3],
		})
	_player = AnimatedSprite2D.new()
	_player.sprite_frames = Assets.character("char_01")
	_player.centered = true
	_player.scale = Vector2(2, 2)
	_player.position = Vector2(320, -40)
	_player.play("idle_down")
	add_child(_player)
	if Ui.transitioning:
		await Ui.faded_in
	await _sequence()


func _sequence() -> void:
	var tw := create_tween()
	tw.tween_property(_player, "position:y", 250.0, 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_player, "rotation", TAU * 2, 2.2)
	await tw.finished
	_player.rotation = 0
	_falling = false
	Sound.sfx("hurt", 0.6)
	await get_tree().create_timer(0.6).timeout
	await Ui.say([
		"* Sei caduto. Non per terra: nel debito.",
		"* Intorno a te piovono bollette, monete e lettere della banca.",
	])
	_show_lift = true
	Sound.sfx("select")
	var tw2 := create_tween()
	tw2.tween_property(self, "_doors", 1.0, 0.8)
	await tw2.finished
	await Ui.say(["* Davanti a te si apre un ascensore. Ha un solo pulsante: GIÙ."])
	var tw3 := create_tween()
	tw3.tween_property(_player, "position:y", 205.0, 0.8)
	_player.play("walk_up")
	await tw3.finished
	_player.visible = false
	Ui.cutscene = false
	Router.goto(Router.SOTTOUFFICIO, "elevator", [
		"L'ascensore scende. -1. -2. -3.",
		"Più scende, più fa caldo.",
		"Le porte si aprono su un ufficio che non dovrebbe esistere.",
	])


func _process(delta: float) -> void:
	for t in _things:
		var speed: float = t["speed"] * (1.0 if _falling else 0.25)
		t["pos"] = (t["pos"] as Vector2) + Vector2(0, -speed * delta) if _falling else (t["pos"] as Vector2) + Vector2(0, speed * delta)
		if (t["pos"] as Vector2).y < -20:
			t["pos"] = Vector2(randf_range(0, 640), 380)
		elif (t["pos"] as Vector2).y > 380:
			t["pos"] = Vector2(randf_range(0, 640), -20)
	queue_redraw()


func _draw() -> void:
	for t in _things:
		var p: Vector2 = (t["pos"] as Vector2).round()
		match str(t["kind"]):
			"coin":
				draw_circle(p, 4, Color("ffcd3c"))
				draw_circle(p, 2, Color("c88c1e"))
			"bill":
				draw_rect(Rect2(p - Vector2(7, 4), Vector2(14, 8)), Color("7fbf7a"))
				draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color("3d7a3a"))
			"letter":
				draw_rect(Rect2(p - Vector2(6, 4), Vector2(12, 8)), Color("f2f0e6"))
				draw_line(p - Vector2(6, 4), p, Color("d0302f"), 1.0)
				draw_line(p + Vector2(6, -4), p, Color("d0302f"), 1.0)
	if _show_lift:
		var r := Rect2(290, 150, 60, 70)
		draw_rect(r, Color("4a4658"))
		var gap := 26.0 * _doors
		draw_rect(Rect2(r.position + Vector2(3, 3), Vector2(27 - gap, r.size.y - 3)), Color("aeb4c4"))
		draw_rect(Rect2(r.position + Vector2(30 + gap, 3), Vector2(27 - gap, r.size.y - 3)), Color("aeb4c4"))
		draw_rect(Rect2(r.position + Vector2(3 + 27 - gap, 3), Vector2(gap * 2, r.size.y - 3)), Color("1a1420"))
		draw_string(Assets.font(), Vector2(290, 144), "GIÙ", HORIZONTAL_ALIGNMENT_CENTER, 60, 11, Color("d0302f"))
	if not _falling:
		draw_rect(Rect2(0, 258, 640, 102), Color("1a1622"))
