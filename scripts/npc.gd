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
var _emote: Sprite2D
var _emote_t := 0.0
var _greeted := false


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
	sprite.play(_anim_for(activity))
	sprite.frame = randi() % 6
	if GameState.is_robot(id):
		sprite.speed_scale = 0.0
	_emote = Sprite2D.new()
	var at := AtlasTexture.new()
	at.atlas = load("res://art/emotes.png") if ResourceLoader.exists("res://art/emotes.png") else Assets.tex("_emotes", Vector2i(44, 10))
	at.region = Rect2(0, 0, 11, 10)
	_emote.texture = at
	_emote.position = Vector2(4, -42)
	_emote.visible = false
	_emote.z_index = 5
	add_child(_emote)
	_emote_t = randf_range(3.0, 10.0)


func _anim_for(act: String) -> String:
	if act == "wander":
		return "walk_right"
	return act


## Nuvoletta sopra la testa: "..." , "!", una nota, un cuore. I robot non ne fanno mai.
func emote(kind: String, time := 1.6) -> void:
	if GameState.is_robot(id):
		return
	var idx := ["dots", "bang", "note", "heart"].find(kind)
	(_emote.texture as AtlasTexture).region = Rect2(maxi(idx, 0) * 11, 0, 11, 10)
	_emote.visible = true
	await get_tree().create_timer(time).timeout
	if is_instance_valid(_emote):
		_emote.visible = false


func _update_emote(delta: float) -> void:
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


func _process(delta: float) -> void:
	_update_emote(delta)
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
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: _mat.set_shader_parameter("amount", v), 0.0, 1.0, time)
	await tw.finished


func interact() -> void:
	_face_player()
	var who := display_name()
	if GameState.is_robot(id):
		await Ui.say([GameState.robot_line(id)], who)
		return
	if await Quests.handle_npc(self):
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
	cfg["return"] = back
	cfg["return_pos"] = back_pos
	return cfg
