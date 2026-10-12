extends Node2D
## Minigioco "Consegne": corri tra le corsie, prendi i pacchi, evita le auto.

const DURATION := 35.0
const LANES: Array[float] = [250.0, 320.0, 390.0]
const PLAYER_Y := 290.0

var time_left := DURATION
var lane := 1
var items: Array[Dictionary] = []
var spawn_t := 0.5
var speed := 170.0
var delivered := 0
var crashes := 0
var flash := 0.0
var scroll := 0.0
var started := false
var done := false
var _rider: AnimatedSprite2D


func _ready() -> void:
	Ui.show_hud(false)
	_rider = AnimatedSprite2D.new()
	_rider.sprite_frames = Assets.character("char_01")
	_rider.scale = Vector2(2, 2)
	_rider.position = Vector2(LANES[lane], PLAYER_Y)
	_rider.play("walk_up")
	add_child(_rider)
	if Ui.transitioning:
		await Ui.faded_in
	await Ui.say([
		"* CONSEGNE. Piove. Frecce SINISTRA/DESTRA per cambiare corsia.",
		"* Prendi i pacchi, evita le auto. Hai %d secondi." % int(DURATION),
	])
	started = true


func _process(delta: float) -> void:
	queue_redraw()
	_rider.position.x = lerpf(_rider.position.x, LANES[lane], 0.3)
	if not started or done:
		return
	time_left -= delta
	flash = maxf(flash - delta, 0.0)
	scroll = fmod(scroll + speed * delta, 40.0)
	speed += 4.0 * delta
	if time_left <= 0.0:
		time_left = 0.0
		_finish()
		return
	spawn_t -= delta
	if spawn_t <= 0.0:
		spawn_t = randf_range(0.45, 0.8)
		items.append({"lane": randi() % 3, "y": -40.0, "pkg": randf() < 0.35})
	for it in items:
		it["y"] = float(it["y"]) + speed * delta
	var keep: Array[Dictionary] = []
	for it in items:
		var y := float(it["y"])
		if int(it["lane"]) == lane and absf(y - PLAYER_Y) < 24.0:
			if it["pkg"]:
				delivered += 1
			else:
				crashes += 1
				flash = 0.35
			continue
		if y < 400.0:
			keep.append(it)
	items = keep


func _unhandled_input(event: InputEvent) -> void:
	if not started or done:
		return
	if event.is_action_pressed("move_left"):
		lane = maxi(0, lane - 1)
	elif event.is_action_pressed("move_right"):
		lane = mini(2, lane + 1)


func _finish() -> void:
	done = true
	var pay := maxi(50, 80 + delivered * 22 - crashes * 30)
	await Ui.say([
		"* Fine turno. Pacchi consegnati: %d. Incidenti: %d." % [delivered, crashes],
		"* Paga: %s. Hai le gambe a pezzi e la pioggia nelle ossa." % GameState.euros(pay),
	])
	GameState.finish_hard_job(pay)
	GameState.pending_lines = ["* Il turno di consegne è finito. Puoi tornare a casa a dormire."]
	Router.goto(Router.OFFICE, "terminal")


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, 640, 360), Color("2c3a2c"))
	draw_rect(Rect2(212, 0, 216, 360), Color("3a3a42"))
	for x in [285.0, 355.0]:
		var y := -40.0 + scroll
		while y < 360.0:
			draw_rect(Rect2(x - 2, y, 4, 20), Color("cfcfd6"))
			y += 40.0
	for it in items:
		var x: float = LANES[int(it["lane"])]
		var y := float(it["y"])
		if it["pkg"]:
			draw_rect(Rect2(x - 10, y - 10, 20, 20), Color("b9894f"))
			draw_rect(Rect2(x - 10, y - 2, 20, 4), Color("e8d29a"))
		else:
			draw_rect(Rect2(x - 18, y - 28, 36, 56), Color("c23b3b"))
			draw_rect(Rect2(x - 14, y - 18, 28, 14), Color("9fc3e0"))
	# pioggia
	for i in 40:
		var rx := fmod(i * 97.0 + scroll * 3.0, 640.0)
		var ry := fmod(i * 53.0 + scroll * 9.0, 360.0)
		draw_line(Vector2(rx, ry), Vector2(rx - 3, ry + 10), Color(0.7, 0.8, 1.0, 0.35), 1.0)
	var hud := "Tempo %d    Pacchi %d    Incidenti %d" % [int(ceil(time_left)), delivered, crashes]
	draw_string(font, Vector2(16, 28), hud, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	if flash > 0.0:
		draw_rect(Rect2(0, 0, 640, 360), Color(1, 0, 0, flash))
