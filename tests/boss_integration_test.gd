extends Node
const B := preload("res://scripts/boss_missions.gd")
var current: Node
var ticks := 0
var auto_dialogue := true
var checks := 0
var failures: Array[String] = []
var output := ""
func _ready() -> void:
 await get_tree().process_frame
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
 GameState.save_path = "user://test_boss_integration.json"
 # The actual phone call routes to the new screen, closes once, and can be resumed.
 for floor: String in ["-5", "-4", "-3", "-2", "0"]:
  await open_room(floor)
  if floor == "0":
   current.call("_protest")
  else:
   current.call("_boss_call")
  await wait_scene(B.SCENE)
  check(is_instance_valid(current) and current.scene_file_path == B.SCENE, "Telefonata apre incarico " + floor)
  if not is_instance_valid(current) or current.scene_file_path != B.SCENE: break
  await frames(8)
  auto_dialogue = false
  check(current.buttons.size() >= 5 or current.dinamo != null, "Comandi visibili " + floor)
  check(B.active(floor), "Stato attivo " + floor)
  # Real mouse and touch coordinates, including non-16:9 window transforms.
  for size: Vector2i in [Vector2i(1280, 720), Vector2i(1000, 800)]:
   get_window().size = size
   await frames(4)
   if floor == "-5":
    # il -5 ha la leva (scenes/minigame/capo_dinamo.tscn): tutta giù col mouse, tutta su col dito
    var bin: Rect2 = (current.dinamo.get_node("Leva/Binario") as Control).get_global_rect()
    TouchControls.enabled = false
    await click(Vector2(bin.get_center().x, bin.end.y - 1))
    check(int(current.p["intensity"]) == 3 and int(current.p["extra"]) == 10, "Mouse trasformato -5" + str(size))
    TouchControls.enabled = true
    await frames(4)
    await touch(Vector2(bin.get_center().x, bin.position.y + 1))
    check(int(current.p["intensity"]) == 2 and int(current.p["extra"]) == 0, "Touch trasformato -5" + str(size))
    TouchControls.enabled = false
    continue
   TouchControls.enabled = false
   var key: String = {"-5": "intensity", "-4": "document", "-3": "rate", "-2": "months", "0": "source"}[floor]
   var old_value: int = int(current.p[key])
   await click((current.buttons[0]["rect"] as Rect2).get_center())
   if floor != "-4": check(int(current.p[key]) != old_value, "Mouse trasformato " + floor + str(size))
   # First office button intentionally targets wrong office: retry with no penalty.
   if floor == "-4": check(current.msg != "", "Errore pratica spiega e permette riprova")
   TouchControls.enabled = true
   await frames(4)
   old_value = int(current.p[key])
   await touch((current.buttons[0]["rect"] as Rect2).get_center())
   if floor != "-4": check(int(current.p[key]) != old_value, "Touch trasformato " + floor + str(size))
  TouchControls.enabled = false
  if floor == "-4":
   current.selected = 0
   await action("move_right")
   check(int(current.selected) == 1, "Vaschette: destra segue la riga superiore")
   await action("move_down")
   check(int(current.selected) == 3, "Vaschette: giù segue la colonna")
   await action("move_down")
   check(int(current.selected) == 4, "Vaschette: giù raggiunge SALVA ED ESCI")
   await action("move_up")
   check(int(current.selected) == 2, "Vaschette: su rientra nella scrivania")
  current.selected = 0
  var old_value: int = int(current.p.get("intensity", current.p.get("rate", current.p.get("months", current.p.get("source", 0)))))
  if floor == "-5":
   await action("move_down"); await action("move_down")
  else:
   await action("confirm")
  if floor != "-4": check(int(current.p.get("intensity", current.p.get("rate", current.p.get("months", current.p.get("source", 0))))) != old_value, "Tastiera " + floor)
  # Checkpoint and actual exit restore the saved world position.
  var progress_copy: Dictionary = current.p.duplicate(true)
  var saved_pos: Array = B.state(floor)["return_pos"]
  await shot("boss_" + str(["-5", "-4", "-3", "-2", "0"].find(floor) + 1))
  auto_dialogue = true
  current._act("exit")
  var path: String = {"-5": Router.FONDO, "-4": Router.SOTTOUFFICIO, "-3": Router.MERCATO, "-2": Router.BANCA, "0": Router.CITY}[floor]
  await wait_scene(path)
  check(current is Room, "Ritorno nel piano " + floor)
  if current is Room:
   check(current.player.global_position.distance_to(Vector2(saved_pos[0], saved_pos[1])) < 1, "Posizione ripristinata " + floor)
   var booth_spot := current.find_child("SportelloBadgeInterazione", true, false) as Interactable
   var booth_clerk := current._badge_booth.get_node_or_null("Addetta") as Node2D
   var booth_positions: Array[Vector2] = []
   if booth_clerk and not Rect2(0, -48, 96, 48).has_point(booth_clerk.position):
    # In Città non c'è più la cabina: Nives è accanto alle scale e si parla davanti a lei.
    for x in [-8, 0, 8]:
     booth_positions.append(booth_clerk.global_position + Vector2(x, 16))
   else:
    for x in [8, 30, 56]:
     booth_positions.append(current._badge_booth.global_position + Vector2(x, 12))
   for booth_position in booth_positions:
    current.player.global_position = booth_position
    current.player.face("up")
    check(current.player._find_target() == booth_spot, "Sportello raggiungibile davanti a Nives " + floor + str(booth_position))
   current.player.global_position = Vector2(saved_pos[0], saved_pos[1])
  GameState.load_game()
  check(B.progress(floor) == JSON.parse_string(JSON.stringify(progress_copy)), "Ricarica progressi " + floor)
  check(bool(B.state(floor)["seen"]), "Telefonata registrata una volta " + floor)
  await close_current()
 # Actual Director screen: one turn (money, Casa Comune, debts), policy prompt, save, final review.
 await open_room("cima")
 var c6_script = load("res://chapters/c6/cima_c6.gd")
 var d: Dictionary = c6_script.c6()
 d["president"]["met"] = true; d["president"]["debt_contract_read"] = true; d["president"]["offer_received"] = true
 for cycle in [1]:
  await close_current()
  GameState.minigame = {"cycle": cycle}
  current = load(Router.DIREZIONE).instantiate()
  get_tree().root.add_child(current); get_tree().current_scene = current
  await frames(100)
  check(current.get("phase") == "alloc", "Ciclo pronto " + str(cycle))
  if cycle == 1: await shot("boss_6_bilancio")
  current._confirm()
  for i in 500:
   await frames(1)
   if get_tree().current_scene != current: break
   if current.get("phase") in ["casa", "debiti"]:
    # Pick non-intervention or conserving debt: always available.
    current._pick(current.options.size() - 1 if current.get("phase") == "casa" else 0)
  await wait_scene(Router.CIMA)
  check(c6_script.cycles_done() == 3, "Turno applicato una volta")
  await frames(120)
 await frames(120)
 check(c6_script.c6()["boss"]["final_call_seen"], "Riepilogo del Capo dopo i tre bilanci")
 check(str(B.state("cima")["status"]) == "done", "Sesto incarico completato")
 check(not Ui.cutscene and not Ui.transitioning, "Comandi liberi dopo il Capo")
 print("BOSS INTEGRATION: %d verifiche, errori %s" % [checks, str(failures)])
 await close_current()
 get_tree().quit(failures.size())

func open_room(floor: String) -> void:
 GameState.new_game(); GameState.floor_id = floor
 for f in ["c1_arrivo", "c2_arrivo", "c3_arrivo", "c4_arrivo", "c5_arrivo", "c6_arrivo"]: GameState.flags[f] = true
 if floor == "cima":
  var d: Dictionary = load("res://chapters/c6/cima_c6.gd").c6()
  d["entered"] = true; d["elevator"]["intro_seen"] = true
 Router.spawn = "_save"; Router.save_pos = Vector2(220, 170)
 var path: String = {"-5": Router.FONDO, "-4": Router.SOTTOUFFICIO, "-3": Router.MERCATO, "-2": Router.BANCA, "0": Router.CITY, "cima": Router.CIMA}[floor]
 current = load(path).instantiate()
 get_tree().root.add_child(current); get_tree().current_scene = current
 await frames(30)
 current.player.set_physics_process(false)

func close_current() -> void:
 if is_instance_valid(current): current.queue_free()
 get_tree().current_scene = self
 current = null
 await frames(5)

func wait_scene(path: String) -> void:
 for i in 3000:
  await frames(1)
  var scene := get_tree().current_scene
  if scene and scene.scene_file_path == path and not Ui.transitioning and not Ui.busy and not Ui.cutscene:
   current = scene
   return
 failures.append("Timeout scena " + path)
 current = get_tree().current_scene

func frames(n: int) -> void:
 for i in n: await get_tree().process_frame
func _process(_delta: float) -> void:
 ticks += 1
 if auto_dialogue and Ui.busy and ticks % 2 == 0:
  if Ui.get("_mode") == "choose" and (Ui.get("_options") as Array).has("Basta così."):
   var c6: Dictionary = GameState.flags.get("chapter_6", {})
   if c6.get("director_turn", {}).get("consulted_citizens", false):
    Ui.set("_sel", (Ui.get("_options") as Array).find("Basta così."))
  var e := InputEventAction.new(); e.action = "confirm"; e.pressed = true; Input.parse_input_event(e)
  e = InputEventAction.new(); e.action = "confirm"; Input.parse_input_event(e)
func check(ok: bool, why: String) -> void:
 checks += 1
 if not ok: failures.append(why); push_error(why)
func action(name: String) -> void:
 var e := InputEventAction.new(); e.action = name; e.pressed = true; Input.parse_input_event(e)
 await frames(1)
 e = InputEventAction.new(); e.action = name; Input.parse_input_event(e)
 await frames(2)
func click(pos: Vector2) -> void:
 pos = get_viewport().get_screen_transform() * current.get_global_transform_with_canvas() * pos
 var e := InputEventMouseButton.new(); e.button_index = MOUSE_BUTTON_LEFT; e.pressed = true; e.position = pos; e.global_position = pos
 Input.parse_input_event(e); await frames(1)
 e = InputEventMouseButton.new(); e.button_index = MOUSE_BUTTON_LEFT; e.position = pos; Input.parse_input_event(e)
 await frames(2)
func touch(pos: Vector2) -> void:
 pos = get_viewport().get_screen_transform() * current.get_global_transform_with_canvas() * pos
 var e := InputEventScreenTouch.new(); e.index = 0; e.pressed = true; e.position = pos; Input.parse_input_event(e)
 await frames(1)
 e = InputEventScreenTouch.new(); e.index = 0; e.position = pos; Input.parse_input_event(e)
 await frames(2)
func shot(name: String) -> void:
 if output == "" or DisplayServer.get_name() == "headless": return
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(output.path_join(name + ".png"))
