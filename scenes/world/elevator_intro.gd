extends Node2D
## L'inizio: sei dentro l'ascensore della Torre CHEAP e scendi. -1, -2, -3, -4...
## Sul display c'è il tuo debito. Al -5 l'ascensore si blocca, la luce salta,
## le porte si aprono a metà sul buio.

const CABIN := Rect2(224, 36, 192, 252)
const WALL_H := 74.0

var _player: AnimatedSprite2D
var _floor_text := "0"
var _light := 1.0
var _shake := 0.0
var _doors := 0.0
var _display_on := true
var _sparks: Array[Vector2] = []
var _t := 0.0


func _ready() -> void:
	Ui.show_hud(false)
	Ui.cutscene = true
	# musica da ascensore: rilassante, aziendale, finché l'ascensore non si rompe
	Sound.music("ascensore")
	_player = AnimatedSprite2D.new()
	_player.sprite_frames = Assets.character("char_01")
	_player.centered = false
	_player.offset = Vector2(-8, -31)
	_player.scale = Vector2(2, 2)
	_player.position = Vector2(320, 236)
	_player.play("idle_up")
	add_child(_player)
	if Ui.transitioning:
		await Ui.faded_in
	await _sequence()


func _sequence() -> void:
	await _wait(0.8)
	await Ui.say(["* L'ascensore della Torre CHEAP. Odora di metallo e di gente che ci ha pianto dentro.",
		"* Una musichetta allegra esce da un altoparlante. Una voce registrata: \"Benvenuto nella Torre CHEAP! Il futuro costa poco!\""])
	for f in ["-1", "-2", "-3"]:
		await _wait(0.9)
		_floor_text = f
		Sound.sfx("ding", 0.9)
	await _wait(0.6)
	await Ui.say(["* Più scende, più la luce diventa gialla. Come un dente."])
	# al -4 la luce comincia a tremare
	await _wait(0.5)
	_floor_text = "-4"
	Sound.sfx("ding", 0.8)
	for i in 6:
		_light = 0.35 if i % 2 == 0 else 0.9
		await _wait(0.08 + randf() * 0.12)
	_light = 0.85
	# la musica rallenta, come un disco che si scarica
	Sound.music_pitch(0.55, 0.9)
	await _wait(1.0)
	# -5: lo schianto
	_floor_text = "-5"
	Sound.music("")
	Sound.sfx("clunk")
	_shake = 1.0
	_light = 0.0
	_player.play("idle_down")
	await _wait(0.9)
	_display_on = false
	await _wait(0.5)
	for i in 3:
		_display_on = true
		Sound.sfx("spark", 1.0 + i * 0.1)
		_add_sparks()
		await _wait(0.12)
		_display_on = false
		await _wait(0.35)
	_display_on = true
	_light = 0.12
	await Ui.say(["* L'ascensore si è fermato. Il display lampeggia: -5.",
		"* Premi tutti i pulsanti. Nessuno si accende. Nemmeno l'allarme."])
	await _wait(0.6)
	Sound.sfx("door", 0.7)
	var tw := create_tween()
	tw.tween_property(self, "_doors", 0.45, 1.4).set_trans(Tween.TRANS_SINE)
	await tw.finished
	await _wait(0.4)
	await Ui.say(["* Le porte si aprono a metà, poi si incastrano.",
		"* Fuori è buio. Da qualche parte, laggiù, c'è una piccola luce."])
	var walk := create_tween()
	walk.tween_property(_player, "position:y", 300.0, 1.3)
	_player.play("walk_down")
	await walk.finished
	Ui.cutscene = false
	Router.goto(Router.FONDO, "elevator")


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _add_sparks() -> void:
	for i in 6:
		_sparks.append(Vector2(randf_range(-10, 10), randf_range(-4, 4)))


func _process(delta: float) -> void:
	_t += delta
	_shake = maxf(0.0, _shake - delta * 1.6)
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 6.0 * _shake
	if not _sparks.is_empty() and randf() < 0.3:
		_sparks.pop_front()
	queue_redraw()


func _draw() -> void:
	var font := Assets.font()
	draw_rect(Rect2(-20, -20, 680, 400), Color("05040a"))
	var r := CABIN
	var dim := func(c: Color) -> Color: return c.darkened(1.0 - (0.15 + 0.85 * _light))
	# pavimento di lamiera
	draw_rect(Rect2(r.position.x, r.position.y + WALL_H, r.size.x, r.size.y - WALL_H), dim.call(Color("4d4a57")))
	for y in range(int(r.position.y + WALL_H) + 6, int(r.end.y) - 16, 12):
		for x in range(int(r.position.x) + 6, int(r.end.x) - 4, 12):
			draw_rect(Rect2(x + (y / 12 % 2) * 6, y, 4, 2), dim.call(Color("5d5a68")))
	# parete di fondo, con le pannellature
	draw_rect(Rect2(r.position, Vector2(r.size.x, WALL_H)), dim.call(Color("8a8696")))
	for k in 4:
		draw_rect(Rect2(r.position.x + 8 + k * 46, r.position.y + 8, 40, WALL_H - 22), dim.call(Color("9b97a8")))
	draw_rect(Rect2(r.position.x, r.position.y + WALL_H - 10, r.size.x, 4), dim.call(Color("c8c4d2")))  # corrimano
	draw_rect(Rect2(r.position.x, r.position.y + WALL_H - 2, r.size.x, 2), dim.call(Color("2a2632")))
	# pareti laterali
	draw_rect(Rect2(r.position.x - 8, r.position.y, 8, r.size.y), dim.call(Color("3a3644")))
	draw_rect(Rect2(r.end.x, r.position.y, 8, r.size.y), dim.call(Color("3a3644")))
	# display del piano e del debito
	var disp := Rect2(296, r.position.y + 12, 48, 26)
	draw_rect(disp.grow(2), Color("1a1622"))
	draw_rect(disp, Color("0c0a10"))
	if _display_on:
		draw_string(font, Vector2(disp.position.x, disp.position.y + 20), _floor_text, HORIZONTAL_ALIGNMENT_CENTER, disp.size.x, 20, Color("e8453a"))
	# pulsantiera
	var panel := Rect2(r.end.x - 34, r.position.y + 16, 18, 40)
	draw_rect(panel, dim.call(Color("b7b3c2")))
	for k in 5:
		var on := _display_on and str(-(k + 1)) == _floor_text
		draw_circle(Vector2(panel.position.x + 9, panel.position.y + 5 + k * 7.5), 2.5, Color("f2b23a") if on else dim.call(Color("5a5666")))
	# luce al soffitto (fuori dal quadro: si vede solo il suo riflesso)
	if _light > 0.05:
		draw_rect(Rect2(r.position.x + 40, r.position.y + WALL_H + 4, r.size.x - 80, 3), Color(1, 0.95, 0.75, 0.15 * _light))
	# le porte, in basso
	var door_y := r.end.y - 14
	var half := r.size.x / 2.0
	var gap := half * _doors
	draw_rect(Rect2(r.position.x, door_y, r.size.x, 14), Color("05040a"))
	draw_rect(Rect2(r.position.x, door_y, half - gap, 14), dim.call(Color("aeb4c4")))
	draw_rect(Rect2(r.position.x + half + gap, door_y, half - gap, 14), dim.call(Color("aeb4c4")))
	draw_line(Vector2(r.position.x + half - gap, door_y), Vector2(r.position.x + half - gap, door_y + 14), Color("2a2632"), 2)
	draw_line(Vector2(r.position.x + half + gap, door_y), Vector2(r.position.x + half + gap, door_y + 14), Color("2a2632"), 2)
	# scintille dal display
	for s in _sparks:
		draw_rect(Rect2(Vector2(320, r.position.y + 40) + s * 2.0, Vector2(2, 2)), Color("ffe08a"))
	# buio che avvolge la cabina quando salta la luce
	if _light < 1.0:
		draw_rect(Rect2(-20, -20, 680, 400), Color(0, 0, 0, 0.55 * (1.0 - _light)))
