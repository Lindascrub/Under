extends Node2D
## Minigioco "Magazzino": le scatole scendono, frecce SINISTRA/DESTRA per smistarle.
## Rosse (fragili) a sinistra, blu a destra. Paga bassa, fatica vera.

const DURATION := 30.0
const RED := Color("d0453f")
const BLUE := Color("4a78d0")

var time_left := DURATION
var score := 0
var mistakes := 0
var box_y := 40.0
var box_red := true
var box_speed := 70.0
var sending := 0
var send_x := 0.0
var flash := 0.0
var started := false
var done := false
var _worker: AnimatedSprite2D


func _ready() -> void:
	Ui.show_hud(false)
	_worker = AnimatedSprite2D.new()
	_worker.sprite_frames = Assets.character("char_01")
	_worker.centered = false
	_worker.scale = Vector2(3, 3)
	_worker.position = Vector2(372, 170)
	_worker.play("idle_left")
	add_child(_worker)
	_new_box()
	if Ui.transitioning:
		await Ui.faded_in
	await Ui.say([
		"* MAGAZZINO. Le scatole ROSSE (fragili) vanno a SINISTRA, le BLU a DESTRA.",
		"* Usa le frecce. Hai %d secondi. Ogni errore ti costa." % int(DURATION),
	])
	started = true


func _new_box() -> void:
	sending = 0
	send_x = 0.0
	box_y = 40.0
	box_red = randf() < 0.5


func _process(delta: float) -> void:
	queue_redraw()
	if not started or done:
		return
	time_left -= delta
	flash = maxf(flash - delta, 0.0)
	if time_left <= 0.0:
		time_left = 0.0
		_finish()
		return
	if sending != 0:
		send_x += sending * 650.0 * delta
		if absf(send_x) > 210.0:
			_new_box()
	else:
		box_y += box_speed * delta
		if box_y > 290.0:
			mistakes += 1
			flash = 0.3
			_new_box()


func _unhandled_input(event: InputEvent) -> void:
	if not started or done or sending != 0:
		return
	var dir := 0
	if event.is_action_pressed("move_left"):
		dir = -1
	elif event.is_action_pressed("move_right"):
		dir = 1
	if dir == 0:
		return
	sending = dir
	_worker.play("idle_left" if dir < 0 else "idle_right")
	if (dir < 0) == box_red:
		score += 1
		box_speed += 7.0
	else:
		mistakes += 1
		flash = 0.3


func _finish() -> void:
	done = true
	var pay := maxi(60, 100 + score * 12 - mistakes * 15)
	await Ui.say([
		"* Fine turno. Scatole smistate: %d. Errori: %d." % [score, mistakes],
		"* Paga: %s. Ti fanno male la schiena e le braccia." % GameState.euros(pay),
	])
	GameState.finish_hard_job(pay)
	GameState.pending_lines = ["* Il turno in magazzino è finito. Puoi tornare a casa a dormire."]
	Router.goto(Router.OFFICE, "terminal")


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, 640, 360), Color("1b1720"))
	draw_rect(Rect2(0, 300, 640, 60), Color("2a2430"))
	# contenitori
	draw_rect(Rect2(40, 240, 150, 70), RED.darkened(0.45))
	draw_string(font, Vector2(40, 232), "FRAGILE", HORIZONTAL_ALIGNMENT_CENTER, 150, 16, RED)
	draw_rect(Rect2(450, 240, 150, 70), BLUE.darkened(0.45))
	draw_string(font, Vector2(450, 232), "NORMALE", HORIZONTAL_ALIGNMENT_CENTER, 150, 16, BLUE)
	# scivolo
	draw_rect(Rect2(290, 20, 60, 280), Color("2c2633"))
	draw_rect(Rect2(288, 20, 4, 280), Color("4a4252"))
	draw_rect(Rect2(348, 20, 4, 280), Color("4a4252"))
	# scatola
	var r := Rect2(302 + send_x, box_y, 36, 30)
	draw_rect(r, RED if box_red else BLUE)
	draw_rect(r, Color.BLACK, false, 2.0)
	draw_line(r.position + Vector2(0, 10), r.position + Vector2(36, 10), Color(0, 0, 0, 0.4), 2.0)
	# HUD
	var hud := "Tempo %d    Scatole %d    Errori %d" % [int(ceil(time_left)), score, mistakes]
	draw_string(font, Vector2(16, 28), hud, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	if flash > 0.0:
		draw_rect(Rect2(0, 0, 640, 360), Color(1, 0, 0, flash))
