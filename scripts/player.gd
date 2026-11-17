class_name Player
extends CharacterBody2D
## Il protagonista. Frecce per muoversi, X per correre, Z per interagire, C per lo stato.

const SPEED := 72.0
const RUN_SPEED := 115.0
const FACING_VECTORS := {
	"right": Vector2.RIGHT, "left": Vector2.LEFT, "up": Vector2.UP, "down": Vector2.DOWN,
}

var sheet := "char_01"
var facing := "down"
## La scena è scripts/player.tscn: ombra, sprite, collisione e telecamera sono nodi veri, da spostare
## nell'editor. Lo zoom della telecamera nella scena è quello normale del gioco.
@onready var camera: Camera2D = $Camera
@onready var _shadow: Sprite2D = $Ombra
@onready var _sprite: AnimatedSprite2D = $Sprite
var _step_t := 0.0
## Dove sta lo sprite in piedi (dalla scena): da seduto si abbassa partendo da qui.
var _stand_offset := Vector2.ZERO
## Seduto su qualcosa (una cassetta, una panchina): fermo finché non ti muovi.
var seated := false

# --- telefono: si cammina toccando ---------------------------------------------------------------
## Sul telefono non c'è il joystick: tocchi un punto e ci vai; tocchi una persona o un oggetto e ci vai a parlare.
## I punti del percorso da seguire (vuoto: fermo) e la cosa da usare quando si arriva.
var _percorso: PackedVector2Array = []
var _meta: Node = null
var _fermo_da := 0.0
## Il lato di un quadretto della griglia su cui si cerca la strada, e quanto lontano si cerca (in quadretti).
const PASSO_DITO := 8.0
const RAGGIO_DITO := 90
## Col dito: quanto oltre la portata si può fermare la strada verso una cosa, e la si usa lo stesso.
const DITO_TOLLERANZA := 24.0
## Da quanti punti di strada in su si corre invece di camminare (un punto = 8 pixel).
const PUNTI_PER_CORRERE := 14
## Il tasto prende una cosa fino a questa distanza anche se la sua `reach` è più corta.
const PORTATA_MINIMA := 14.0


func _ready() -> void:
	add_to_group("player")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_sprite.sprite_frames = Assets.character(sheet)
	_stand_offset = _sprite.offset
	camera.make_current()
	_sprite.play("idle_" + facing)


func _physics_process(_delta: float) -> void:
	var v := Vector2.ZERO
	if not Ui.blocks_input():
		v = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	else:
		_percorso.clear()
		_meta = null
	# col dito: si segue il percorso, un punto alla volta (un tasto premuto lo annulla)
	if v != Vector2.ZERO:
		_percorso.clear()
		_meta = null
	elif not _percorso.is_empty():
		v = _passo_sul_percorso(_delta)
	if seated:
		if v == Vector2.ZERO:
			return
		# ti alzi: un passo giù, davanti a quello su cui eri seduto
		stand_up()
		if _stand_pos != Vector2.INF:
			position = _stand_pos
		else:
			position.y += 14
		_stand_pos = Vector2.INF
	if v != Vector2.ZERO:
		if absf(v.x) > absf(v.y):
			facing = "right" if v.x > 0 else "left"
		else:
			facing = "down" if v.y > 0 else "up"
	# col dito non c'è il tasto per correre: si corre da soli quando la strada è lunga
	var running := Input.is_action_pressed("cancel") or _percorso.size() > PUNTI_PER_CORRERE
	velocity = v * (RUN_SPEED if running else SPEED)
	move_and_slide()
	if v != Vector2.ZERO and velocity.length() > 1.0:
		_step_t -= _delta
		if _step_t <= 0.0:
			_step_t = 0.22 if running else 0.32
			Sound.sfx("step", randf_range(0.9, 1.1))
	var anim := ("walk_" if v != Vector2.ZERO else "idle_") + facing
	if _sprite.animation != anim:
		_sprite.play(anim)


func _unhandled_input(event: InputEvent) -> void:
	if Ui.blocks_input():
		return
	if TouchControls.enabled and event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		get_viewport().set_input_as_handled()
		_tocco_nel_mondo(get_canvas_transform().affine_inverse() * (event as InputEventScreenTouch).position)
		return
	if event.is_action_pressed("confirm"):
		var target: Node = _find_target()
		if target:
			get_viewport().set_input_as_handled()
			target.call("interact")
	elif event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		Ui.show_status()


## Cammina sulle scale fino a `to`, un gradino alla volta. `fade_out`: la luce cala (stai
## lasciando il piano); altrimenti torna (stai arrivando).
func climb(to: Vector2, dir: String, fade_out: bool) -> void:
	facing = dir
	_sprite.play("walk_" + dir)
	_shadow.visible = false
	var t := 1.2
	var tw := create_tween()
	tw.tween_property(self, "position", to, t)
	tw.parallel().tween_property(_sprite, "modulate", Color(0.3, 0.3, 0.36) if fade_out else Color.WHITE, t)
	var steps := create_tween()
	for i in 5:
		steps.tween_callback(Sound.sfx.bind("step", 1.05 - i * 0.05))
		steps.tween_interval(t / 5.0)
	await tw.finished
	_shadow.visible = not fade_out
	_sprite.play("idle_" + dir)


## Cammina fino a `to` (senza fisica), guardando nella direzione in cui va.
func walk_to(to: Vector2) -> void:
	var delta_pos := to - position
	if delta_pos.length() < 1.0:
		return
	if absf(delta_pos.x) > absf(delta_pos.y):
		facing = "right" if delta_pos.x > 0 else "left"
	else:
		facing = "down" if delta_pos.y > 0 else "up"
	_sprite.play("walk_" + facing)
	var tw := create_tween()
	tw.tween_property(self, "position", to, delta_pos.length() / SPEED)
	await tw.finished
	_sprite.play("idle_" + facing)


## 0 = luce piena, 1 = buio (mentre fai le scale).
func set_shade(f: float) -> void:
	if _sprite:
		_sprite.modulate = Color.WHITE.lerp(Color(0.3, 0.3, 0.36), f)


func set_dark(dark: bool) -> void:
	if _sprite == null:
		await ready
	_sprite.modulate = Color(0.3, 0.3, 0.36) if dark else Color.WHITE


func face(dir: String) -> void:
	facing = dir
	_sprite.play("idle_" + dir)


## Cerca la cosa più vicina davanti al giocatore (gruppo "interactable", metodo hotspot()).
func _find_target() -> Node:
	var probe := global_position + Vector2(0, -6) + (FACING_VECTORS[facing] as Vector2) * 6.0
	var best: Node = null
	var best_d := INF
	var seat: Node = null
	var seat_d := INF
	for n in get_tree().get_nodes_in_group("interactable"):
		if n is Interactable and n.facing_required != "" and n.facing_required != facing:
			continue
		var at: Vector2 = n.interaction_point(probe) if n is Interactable else n.call("hotspot")
		var side: Vector2 = n.approach if n is Interactable else Vector2.ZERO
		if side != Vector2.ZERO and (global_position - at).dot(side.normalized()) < 0.0:
			continue
		var d := probe.distance_to(at)
		# le cose dentro un mobile (un tornello, la gente in fila) si usano anche da un passo più in là
		if n is Interactable and d > maxf(n.reach, PORTATA_MINIMA):
			continue
		# Se una persona e un oggetto sono nello stesso punto (Bruno sulla panchina), vince la persona.
		if n.is_in_group("npc") or n.is_in_group("walker"):
			d -= 6.0
		elif n is Seat:
			d -= 4.0
		elif n.get_meta("inspect_prop", false):
			d += 3.0
		if not n is Interactable and d >= 16.0:
			continue
		# sedie e sportelli (le cose che si usano da un lato preciso) contano più delle descrizioni
		var main: bool = n is Seat or n.has_meta("job_id") or (n is Interactable and n.approach != Vector2.ZERO and not n.get_meta("inspect_prop", false))
		if main and d < seat_d:
			seat = n
			seat_d = d
		if d < best_d:
			best_d = d
			best = n
	# una sedia o uno sportello a portata vince sulla descrizione automatica del mobile accanto
	if seat and best and best.get_meta("inspect_prop", false):
		return seat
	return best


var _sleep_nodes: Array[Node] = []


## Si siede su qualcosa: `feet` è il bordo in basso del sedile, `dir` dove guardi.
## left/right: di profilo (panchine, divani laterali), davanti al sedile (z_index).
## down: su una sedia vista di fronte, alzata sul sedile. up: di spalle, dietro lo schienale.
## `lift` = quanto è alto il sedile (una cassetta 6, una sedia 6, un divano 8).
func sit(feet: Vector2, dir: String, lift := 6.0, low_pose := false) -> void:
	if not seated:
		_stand_pos = position
	seated = true
	velocity = Vector2.ZERO
	position = feet + Vector2(0, -2)
	facing = dir
	_shadow.visible = false
	match dir:
		"up":
			# di spalle: lo schienale della sedia resta davanti e copre le gambe
			z_index = 0
			position = feet + Vector2(0, -5)
			_sprite.offset = _stand_offset + Vector2(0, 8 - lift)
			_sprite.play("idle_up")
		"down":
			z_index = 1
			_sprite.offset = _stand_offset + Vector2(0, 8 - lift)
			_sprite.play("idle_down")
			_sprite.pause()
		_:
			z_index = 1
			# alzata sul sedile: sotto si vede ancora (una cassetta è alta 12 pixel)
			_sprite.offset = _stand_offset + Vector2(0, 8 - lift)
			_sprite.play(("sit_high_" if lift >= 6.0 and not low_pose else "sit_") + dir)


## Dove eri prima di sederti: alzandoti torni lì (così non finisci dentro la sedia).
var _stand_pos := Vector2.INF


func stand_up() -> void:
	if not seated:
		return
	seated = false
	z_index = 0
	_sprite.offset = _stand_offset
	_shadow.visible = true
	_sprite.play("idle_down")
	facing = "down"


## Si sdraia nel letto: la testa sul cuscino che respira, e sopra la coperta.
## `bed_top_left` è l'angolo in alto a sinistra dello sprite del letto.
func lie_down(bed_top_left: Vector2) -> void:
	get_up_instant()
	_sprite.visible = false
	_shadow.visible = false
	var head := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	var tex := Assets.tex("characters/%s.png" % sheet, Vector2i(896, 656))
	for i in 6:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * 16, 96, 16, 20)
		frames.add_frame("default", at)
	frames.set_animation_speed("default", 3.0)
	head.sprite_frames = frames
	head.centered = false
	head.top_level = true
	head.global_position = bed_top_left + Vector2(1, -1)
	head.z_index = 20
	head.play()
	add_child(head)
	var blanket := Sprite2D.new()
	var bt := AtlasTexture.new()
	bt.atlas = Assets.tex("props/bed.png", Vector2i(32, 48))
	bt.region = Rect2(0, 15, 32, 23)
	blanket.texture = bt
	blanket.centered = false
	blanket.top_level = true
	blanket.global_position = bed_top_left + Vector2(0, 15)
	blanket.z_index = 21
	add_child(blanket)
	_sleep_nodes = [head, blanket]


func get_up_instant() -> void:
	for n in _sleep_nodes:
		n.queue_free()
	_sleep_nodes.clear()
	_sprite.visible = true
	_shadow.visible = true


## Si alza dal letto e fa due passi fino a `to`.
func get_up(to: Vector2) -> void:
	get_up_instant()
	facing = "right"
	_sprite.play("walk_right")
	var tw := create_tween()
	tw.tween_property(self, "position", to, 0.6)
	await tw.finished
	_sprite.play("idle_down")
	facing = "down"


# --- telefono: si cammina toccando ---------------------------------------------------------------

## Un dito sul mondo: se sotto c'è una persona o un oggetto si va lì e lo si usa, se no si va nel punto toccato.
func _tocco_nel_mondo(punto: Vector2) -> void:
	var cosa := _cosa_sotto_il_dito(punto)
	var dove := punto
	if cosa != null:
		dove = cosa.interaction_point(global_position) if cosa is Interactable else cosa.call("hotspot")
		# già abbastanza vicino: si usa subito, senza fare un passo
		if global_position.distance_to(dove) <= _portata(cosa):
			_usa(cosa, dove)
			return
	var strada := _cerca_strada(dove, cosa)
	if strada.is_empty():
		# già davanti (l'agenda dietro la pedana): più vicino non si va, la si usa da qui
		if cosa != null and global_position.distance_to(dove) <= _portata(cosa) + DITO_TOLLERANZA:
			_usa(cosa, dove)
			return
		Sound.sfx("deny", 1.2, -8.0)
		return
	_percorso = strada
	_meta = cosa
	_fermo_da = 0.0
	_segna(strada[strada.size() - 1])


## La cosa con cui si interagisce più vicina al dito (anche toccandone il corpo, sopra i piedi).
func _cosa_sotto_il_dito(punto: Vector2) -> Node:
	var meglio: Node = null
	var dist := 18.0
	for n in get_tree().get_nodes_in_group("interactable"):
		if not (n as CanvasItem).is_visible_in_tree():
			continue
		var at: Vector2 = n.interaction_point(punto) if n is Interactable else n.call("hotspot")
		var d := punto.distance_to(at)
		# una persona è alta: vale anche il tocco sulla testa
		if n.is_in_group("npc") or n.is_in_group("walker"):
			d = minf(d, punto.distance_to(at + Vector2(0, -12)))
			d -= 4.0
		if d < dist:
			dist = d
			meglio = n
	return meglio


func _portata(cosa: Node) -> float:
	return (maxf(float(cosa.reach), PORTATA_MINIMA) if cosa is Interactable else 12.0) + 10.0


## Ci si gira verso la cosa e la si usa, come con il tasto.
func _usa(cosa: Node, dove: Vector2) -> void:
	if not is_instance_valid(cosa):
		return
	var verso := dove - global_position
	if absf(verso.x) > absf(verso.y):
		facing = "right" if verso.x > 0 else "left"
	else:
		facing = "down" if verso.y > 0 else "up"
	_sprite.play("idle_" + facing)
	cosa.call("interact")


## Un passo lungo il percorso: la direzione da prendere adesso. Arrivati, si usa la cosa toccata (se c'era).
func _passo_sul_percorso(delta: float) -> Vector2:
	while not _percorso.is_empty() and global_position.distance_to(_percorso[0]) < 3.0:
		_percorso.remove_at(0)
	if _percorso.is_empty():
		var cosa := _meta
		_meta = null
		if is_instance_valid(cosa):
			var dove: Vector2 = cosa.interaction_point(global_position) if cosa is Interactable else cosa.call("hotspot")
			# la stessa tolleranza di _cerca_strada: se ci si è incamminati è perché da lì si arriva
			# (l'insegna in alto, la panchina contro il muro: più vicino di così non si va)
			if global_position.distance_to(dove) <= _portata(cosa) + DITO_TOLLERANZA:
				_usa.call_deferred(cosa, dove)
		return Vector2.ZERO
	# bloccati contro qualcosa (una persona che si è spostata): ci si ferma, senza spingere all'infinito
	_fermo_da = _fermo_da + delta if get_real_velocity().length() < 4.0 else 0.0
	if _fermo_da > 0.6:
		_percorso.clear()
		var cosa := _meta
		_meta = null
		# bloccati all'ultimo passo (Ada in mezzo alla folla): se si è già abbastanza vicini, la si usa
		if is_instance_valid(cosa):
			var dove: Vector2 = cosa.interaction_point(global_position) if cosa is Interactable else cosa.call("hotspot")
			if global_position.distance_to(dove) <= _portata(cosa) + DITO_TOLLERANZA:
				_usa.call_deferred(cosa, dove)
		return Vector2.ZERO
	return (_percorso[0] - global_position).normalized()


## La strada fino a `dove`, girando intorno ai mobili: una griglia di quadretti liberi, cercata intorno al giocatore.
## Se `dove` è dentro un mobile o una persona, si arriva al quadretto libero più vicino.
func _cerca_strada(dove: Vector2, cosa: Node) -> PackedVector2Array:
	var spazio := get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = ($Collisione as CollisionShape2D).shape
	# un pixel di margine per lato: camminando la fisica tiene un po' di distanza dai muri,
	# e una strada che li sfiora esatti si incastra sullo spigolo (Banca, vicino alla pianta)
	if q.shape is RectangleShape2D:
		var largo := (q.shape as RectangleShape2D).duplicate() as RectangleShape2D
		largo.size += Vector2(2, 2)
		q.shape = largo
	q.collision_mask = collision_mask
	q.exclude = [get_rid()]
	var sposta: Vector2 = ($Collisione as CollisionShape2D).position
	var inizio := Vector2i.ZERO
	var da := {inizio: inizio}
	var coda: Array[Vector2i] = [inizio]
	var testa := 0
	var arrivo := inizio
	var arrivo_d := global_position.distance_to(dove)
	var vicini: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	var libero := {}
	var prova := func(c: Vector2i) -> bool:
		if not libero.has(c):
			q.transform = Transform2D(0.0, global_position + Vector2(c) * PASSO_DITO + sposta)
			libero[c] = spazio.intersect_shape(q, 1).is_empty()
		return libero[c]
	while testa < coda.size():
		var c: Vector2i = coda[testa]
		testa += 1
		var qui := global_position + Vector2(c) * PASSO_DITO
		var d := qui.distance_to(dove)
		if d < arrivo_d:
			arrivo_d = d
			arrivo = c
			if d < PASSO_DITO * 0.75:
				break
		for v: Vector2i in vicini:
			var n := c + v
			if da.has(n) or absi(n.x) > RAGGIO_DITO or absi(n.y) > RAGGIO_DITO:
				continue
			# in diagonale solo se i due lati sono liberi: non si passa fra due spigoli
			if v.x != 0 and v.y != 0 and not (prova.call(c + Vector2i(v.x, 0)) and prova.call(c + Vector2i(0, v.y))):
				continue
			if prova.call(n):
				da[n] = c
				coda.append(n)
	if arrivo == inizio:
		return PackedVector2Array()
	# verso una cosa: se anche dal punto migliore resta troppo lontana, non ci si muove a vuoto
	if cosa != null and arrivo_d > _portata(cosa) + DITO_TOLLERANZA:
		return PackedVector2Array()
	var strada: PackedVector2Array = []
	var k := arrivo
	while k != inizio:
		strada.append(global_position + Vector2(k) * PASSO_DITO)
		k = da[k]
	strada.reverse()
	return strada


## Un cerchietto che dice «vado lì», e sparisce.
func _segna(punto: Vector2) -> void:
	var s := Node2D.new()
	s.top_level = true
	s.z_index = 50
	s.global_position = punto
	s.draw.connect(func() -> void:
		s.draw_arc(Vector2.ZERO, 5.0, 0, TAU, 20, Color(1, 0.88, 0.3, 0.9), 1.5))
	get_parent().add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "scale", Vector2(0.4, 0.4), 0.5)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.5)
	tw.tween_callback(s.queue_free)
