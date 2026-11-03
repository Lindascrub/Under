class_name Npc
extends StaticBody2D
## Una persona del quartiere. Testi, orari e "battaglia" sono in data/npcs.json.
## Attività possibili (campo "anim"): idle_<dir>, sit_left, sit_right, phone, read, wander.
## Se GameState.is_robot(id) è vero, la persona è stata sostituita da un robot:
## stessa faccia, frasi vuote, ferma a guardarti invece di fare le sue cose.

const ROBOT_SHADER := preload("res://shaders/robot.gdshader")
const WANDER_SPEED := 18.0

var id := ""
var activity := "idle_down"
var data: Dictionary = {}
var sprite: AnimatedSprite2D
var _mat: ShaderMaterial
var _home := Vector2.ZERO
var _wander_range := 32.0
var _wander_dir := 1.0
var _pause := 0.0
var _emote: Node2D
var _emote_top: Sprite2D
var _emote_tail: Sprite2D
var _emote_id := 0
var _emote_t := 0.0
var _greeted := false
# la vita da ferma (attività idle_<dir>): si guarda intorno, fa un passo e torna, guarda il telefono
const FIDGET_SPEED := 20.0
const FIDGET_STEP := 12.0
var _fidget_t := 0.0
var _fidget_back := 0.0
var _fidget_to := Vector2.ZERO
var _fidget_walking := false


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("npc")
	data = GameState.npc_data(id)
	_home = position
	var shadow := Sprite2D.new()
	shadow.texture = Assets.shadow()
	shadow.position = Vector2(0, -1)
	add_child(shadow)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Assets.character(str(data.get("sheet", "char_02")))
	sprite.centered = false
	sprite.offset = Vector2(-8, -31)
	_mat = ShaderMaterial.new()
	_mat.shader = ROBOT_SHADER
	sprite.material = _mat
	add_child(sprite)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 8)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -4)
	add_child(col)

	if GameState.is_robot(id) and not activity.begins_with("sit"):
		activity = "idle_down"
	if activity.begins_with("sit"):
		# Seduto su una panchina: un po' più in basso nell'ordinamento, così resta sopra la panchina.
		# La panchina laterale ha lo schienale a destra: chi è seduto (guarda a sinistra) va sulla seduta.
		shadow.visible = false
		position.y += 3
		sprite.offset += Vector2(-3, -13) if activity == "sit_left" else Vector2(3, -13)
	# le persone vere, in un piano colorato e finto, sono grigie (campo "grey"): ognuna nel suo grigio,
	# con un gesto suo (data/looks.json). I robot no.
	if not GameState.is_robot(id):
		Looks.apply(sprite, id, bool(data.get("grey", false)))
	sprite.play(_anim_for(activity))
	sprite.frame = randi() % 6
	if GameState.is_robot(id):
		sprite.speed_scale = 0.0
	_emote = Node2D.new()
	_emote_top = Sprite2D.new()
	_emote_tail = Sprite2D.new()
	for s in [_emote_top, _emote_tail]:
		s.texture = AtlasTexture.new()
		_emote.add_child(s)
	if ResourceLoader.exists(LIMEZU_EMOTES):
		(_emote_top.texture as AtlasTexture).atlas = load(LIMEZU_EMOTES)
		(_emote_tail.texture as AtlasTexture).atlas = load(LIMEZU_EMOTES)
		_emote.position = Vector2(7, -34)
		_emote_tail.position = Vector2(0, 16)
	else:
		# senza gli asset LimeZu: la vecchia nuvoletta disegnata da noi
		(_emote_top.texture as AtlasTexture).atlas = load("res://art/emotes.png") if ResourceLoader.exists("res://art/emotes.png") else Assets.tex("_emotes", Vector2i(44, 10))
		_emote_tail.visible = false
		_emote.position = Vector2(4, -42)
	_emote.visible = false
	_emote.z_index = 5
	add_child(_emote)
	_emote_t = randf_range(3.0, 10.0)
	_fidget_t = randf_range(2.0, 6.0)


func _anim_for(act: String) -> String:
	if act == "wander":
		return "walk_right"
	return act


const LIMEZU_EMOTES := "res://assets/limezu/ui/emotes.png"
## Le nuvolette di LimeZu (UI_thinking_emotes_animation_16x16): caselle da 16 px, ogni icona ha due fotogrammi
## affiancati. La nuvoletta prima "si gonfia" (colonne 0-3 delle righe 2-3), poi l'icona alterna i suoi due fotogrammi.
const EMOTE_CELLS := {
	"dots": Vector2i(2, 9), "bang": Vector2i(0, 4), "alarm": Vector2i(0, 5), "note": Vector2i(6, 6),
	"heart": Vector2i(4, 2), "question": Vector2i(2, 5), "zzz": Vector2i(6, 5), "coin": Vector2i(4, 6),
	"sweat": Vector2i(6, 9), "angry": Vector2i(0, 9), "idea": Vector2i(2, 8),
}
const OLD_EMOTES := ["dots", "bang", "note", "heart"]


func _emote_frame(top: Vector2i, tail: Vector2i) -> void:
	(_emote_top.texture as AtlasTexture).region = Rect2(top * 16, Vector2(16, 16))
	(_emote_tail.texture as AtlasTexture).region = Rect2(tail * 16, Vector2(16, 16))


## Nuvoletta sopra la testa: "...", "!", una nota, un cuore (e le altre di EMOTE_CELLS). I robot non ne fanno mai.
func emote(kind: String, time := 1.6) -> void:
	if GameState.is_robot(id):
		return
	_emote_id += 1
	var me := _emote_id
	_emote.visible = true
	if not _emote_tail.visible:
		var idx := OLD_EMOTES.find(kind)
		(_emote_top.texture as AtlasTexture).region = Rect2(maxi(idx, 0) * 11, 0, 11, 10)
		await get_tree().create_timer(time).timeout
	else:
		var cell: Vector2i = EMOTE_CELLS.get(kind, EMOTE_CELLS["dots"])
		# si gonfia
		for f in range(1, 4):
			_emote_frame(Vector2i(f, 2), Vector2i(f, 3))
			await get_tree().create_timer(0.07).timeout
			if not is_instance_valid(_emote) or me != _emote_id:
				return
		# l'icona, che alterna i suoi due fotogrammi
		var left := time
		var i := 0
		while left > 0.0:
			_emote_frame(cell + Vector2i(i % 2, 0), Vector2i(4 + i % 2, 3))
			await get_tree().create_timer(0.25).timeout
			if not is_instance_valid(_emote) or me != _emote_id:
				return
			left -= 0.25
			i += 1
		# si sgonfia
		for f in [3, 2]:
			_emote_frame(Vector2i(f, 2), Vector2i(f, 3))
			await get_tree().create_timer(0.06).timeout
			if not is_instance_valid(_emote) or me != _emote_id:
				return
	if is_instance_valid(_emote) and me == _emote_id:
		_emote.visible = false


func _update_emote(delta: float) -> void:
	if GameState.is_robot(id) and sprite.has_node("Gesto"):
		# è appena diventata un robot: niente più gesto
		Looks.strip(sprite)
	if GameState.is_robot(id) or Ui.blocks_input():
		return
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p and not _greeted and p.global_position.distance_to(global_position) < 36:
		_greeted = true
		emote("bang" if not GameState.flags.get("met_" + id, false) else ("heart" if id in GameState.helped_ids else "dots"), 1.2)
		return
	_emote_t -= delta
	if _emote_t <= 0.0:
		_emote_t = randf_range(6.0, 14.0)
		emote(str(data.get("emote", "dots")))


## Chi sta in piedi non è una statua: ogni tanto si guarda intorno, fa un passo e torna al suo posto,
## guarda il telefono. Se le sei vicino (o si parla) sta ferma, così le puoi parlare.
func _fidget(delta: float) -> void:
	if not activity.begins_with("idle_") or GameState.is_robot(id) or data.get("still", false):
		return
	var base := activity.trim_prefix("idle_")
	var p := get_tree().get_first_node_in_group("player") as Node2D
	var near := p != null and p.global_position.distance_to(global_position) < 44
	if Ui.blocks_input() or near:
		if _fidget_walking:
			_fidget_walking = false
			sprite.play("idle_" + base)
		return
	if _fidget_walking:
		var to := _fidget_to - position
		if to.length() < 0.6 or test_move(global_transform, to.normalized() * 2.0):
			_fidget_walking = false
			sprite.play("idle_" + base)
			return
		position += to.normalized() * minf(FIDGET_SPEED * delta, to.length())
		return
	if _fidget_back > 0.0:
		_fidget_back -= delta
		if _fidget_back <= 0.0:
			sprite.play("idle_" + base)
		return
	_fidget_t -= delta
	if _fidget_t > 0.0:
		return
	_fidget_t = randf_range(3.0, 8.0)
	# se una scena l'ha portata altrove (Olga che va alla porta), il suo posto adesso è lì
	if position.distance_to(_home) > FIDGET_STEP + 2.0:
		_home = position
	var roll := randf()
	if position.distance_to(_home) > 1.0 or roll < 0.35:
		# un passo (o il ritorno al suo posto)
		var dirs := {"left": Vector2.LEFT, "right": Vector2.RIGHT, "up": Vector2.UP, "down": Vector2.DOWN}
		var d: String = dirs.keys()[randi() % 4]
		_fidget_to = _home + dirs[d] * FIDGET_STEP
		if position.distance_to(_home) > 1.0:
			_fidget_to = _home
			var back := _home - position
			d = ("right" if back.x > 0 else "left") if absf(back.x) > absf(back.y) else ("down" if back.y > 0 else "up")
		if not test_move(global_transform, (_fidget_to - position).normalized() * 3.0):
			_fidget_walking = true
			sprite.play("walk_" + d)
	elif roll < 0.75:
		# si guarda intorno
		var look: String = ["left", "right", "up", "down"][randi() % 4]
		sprite.play("idle_" + look)
		_fidget_back = randf_range(1.0, 2.2)
	else:
		# il telefono, o un foglio da leggere
		var act: String = ["phone", "read"][randi() % 2]
		if sprite.sprite_frames.has_animation(act):
			sprite.play(act)
			_fidget_back = randf_range(2.0, 3.5)


func _process(delta: float) -> void:
	_update_emote(delta)
	_fidget(delta)
	if activity != "wander" or Ui.blocks_input():
		if activity == "wander" and sprite.animation.begins_with("walk"):
			sprite.play("idle_" + sprite.animation.trim_prefix("walk_"))
		return
	if _pause > 0.0:
		_pause -= delta
		return
	if test_move(global_transform, Vector2(_wander_dir * 3.0, 0)):
		_wander_dir = -_wander_dir
		_pause = randf_range(0.6, 1.4)
		sprite.play("idle_down")
		return
	position.x += _wander_dir * WANDER_SPEED * delta
	var anim := "walk_right" if _wander_dir > 0 else "walk_left"
	if sprite.animation != anim:
		sprite.play(anim)
	if absf(position.x - _home.x) > _wander_range:
		position.x = _home.x + signf(position.x - _home.x) * _wander_range
		_wander_dir = -_wander_dir
		_pause = randf_range(1.0, 2.5)
		sprite.play("idle_down")


func hotspot() -> Vector2:
	return global_position + Vector2(0, -8)


func display_name() -> String:
	return str(data.get("name", id.capitalize()))


func face(dir: String) -> void:
	if activity.begins_with("sit"):
		return
	sprite.play("idle_" + dir)


## Mostra il robot che c'era sotto (usato nel finale ricco).
func reveal(time := 2.0) -> void:
	sprite.material = _mat
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: _mat.set_shader_parameter("amount", v), 0.0, 1.0, time)
	await tw.finished


func interact() -> void:
	_face_player()
	var who := display_name()
	if GameState.is_robot(id):
		# la stanza può far rispondere il robot a qualche domanda (robot_talk_<id>, Ada nella Città)
		var here := get_tree().current_scene
		if here and here.has_method("robot_talk_" + id) and await here.call("robot_talk_" + id, self):
			return
		await Ui.say([GameState.robot_line(id)], who)
		return
	if await Quests.handle_npc(self):
		return
	# la stanza può avere qualcosa di speciale da far dire a questa persona (talk_<id>)
	var room := get_tree().current_scene
	if room and room.has_method("talk_" + id) and await room.call("talk_" + id, self):
		return
	# dopo la rivelazione del capitolo, chi ha perso il colore ti dice la verità (campo "reveal")
	var reveal_flag := str(data.get("reveal_flag", "c1_rivelazione"))
	if data.has("reveal") and GameState.flags.get(reveal_flag, false) and not GameState.flags.get("svelato_" + id, false):
		GameState.flags["svelato_" + id] = true
		await Ui.say(data["reveal"], who)
		return
	# chi lavora per restare colorato, dopo un po' ti manda via (campo "busy_line")
	if data.has("busy_line"):
		var talks := int(GameState.flags.get("talks_" + id, 0)) + 1
		GameState.flags["talks_" + id] = talks
		var thanked: bool = GameState.flags.get("thanked_" + id, false)
		if id in GameState.helped_ids and not thanked:
			GameState.flags["thanked_" + id] = true
			await Ui.say(data.get("helped", ["Grazie."]), who)
			return
		if talks >= 3 or id in GameState.helped_ids:
			await Ui.say(data["busy_line"], who)
			return
	await Ui.say(_lines(), who)
	if id == "nico" and GameState.flags.get("coffee_day", 0) != GameState.day:
		GameState.flags["coffee_day"] = GameState.day
		GameState.give_item("Caffè di Nico")
		Sound.sfx("heal")
		await Ui.say(["Tieni, offre la casa. Ne hai bisogno.", "* (Hai ricevuto: Caffè di Nico. Usalo dal menu con C.)"], who)
	await _offer_encounter(who)


func _face_player() -> void:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p == null:
		return
	var d := p.global_position - global_position
	if absf(d.x) > absf(d.y):
		face("right" if d.x > 0 else "left")
	else:
		face("down" if d.y > 0 else "up")


func _lines() -> Array:
	var met_key := "met_" + id
	if not GameState.flags.get(met_key, false) and data.has("intro"):
		GameState.flags[met_key] = true
		return data["intro"]
	if id == "nico":
		return GameState.nico_lines()
	if id in GameState.freed and data.has("motive"):
		return data["motive"].get("freed_lines", ["..."])
	if id in GameState.helped_ids and data.has("helped"):
		return data["helped"]
	var days: Array = data.get("days", [["..."]])
	return days[clampi(GameState.day - 1, 0, days.size() - 1)]


## Come in Undertale: invece di combattere, la persona ti "attacca" coi suoi problemi.
## Chi non ha una battaglia ti chiede direttamente una mano (minigioco a sorpresa).
func _offer_encounter(who: String) -> void:
	if not GameState.can_meet(id):
		return
	if not data.has("battle"):
		await _offer_help(who)
		return
	if not GameState.has_time(GameState.COST_LISTEN):
		return
	var choice: int = await Ui.choose(str(data["battle"].get("hook", "Sembra che abbia bisogno di sfogarsi.")),
		["Ascolta (1 ora)", "Saluta e vai"], who)
	if choice != 0:
		return
	GameState.met_today.append(id)
	GameState.spend(GameState.COST_LISTEN)
	var cfg: Dictionary = (data["battle"] as Dictionary).duplicate(true)
	cfg["kind"] = "person"
	cfg["id"] = id
	cfg["name"] = who
	cfg["sheet"] = data.get("sheet", "char_02")
	cfg["help"] = data.get("help", {})
	if data.has("motive"):
		cfg["motive"] = data["motive"]
	cfg["return"] = get_tree().current_scene.scene_file_path
	cfg["return_pos"] = (get_tree().get_first_node_in_group("player") as Node2D).global_position
	Router.battle(cfg)


func _offer_help(who: String) -> void:
	var h: Dictionary = data.get("help", {})
	if not h.has("minigame") or not GameState.has_time(GameState.COST_HELP_TIME):
		return
	var choice: int = await Ui.choose(str(h.get("ask", "Ti chiede una mano.")), ["Dai una mano (1 ora)", "Non ora"], who)
	if choice != 0:
		return
	GameState.met_today.append(id)
	Router.minigame(Npc.minigame_cfg(id, who, h, get_tree().current_scene.scene_file_path,
		(get_tree().get_first_node_in_group("player") as Node2D).global_position))


## Prepara la configurazione del minigioco di aiuto di una persona.
static func minigame_cfg(npc_id: String, who: String, help: Dictionary, back: String, back_pos: Vector2) -> Dictionary:
	var cfg: Dictionary = (help["minigame"] as Dictionary).duplicate(true)
	cfg["id"] = npc_id
	cfg["name"] = who
	cfg["win"] = help.get("yes", ["Grazie!"])
	for k in ["partial", "lose"]:
		if help.has(k):
			cfg[k] = help[k]
	var above := GameState.floor_above()
	# chi non ha soldi da dare (Leda, Amir) ringrazia in un altro modo: "fixed_reward"
	if above != "" and GameState.room_floor != "" and not cfg.get("fixed_reward", false):
		cfg["reward"] = maxi(int(cfg.get("reward", 10)), GameState.badge_cost(above) / 8)
	cfg["return"] = back
	cfg["return_pos"] = back_pos
	return cfg
