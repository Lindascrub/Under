extends Control
const B := preload("res://scripts/boss_missions.gd")
const FONT := preload("res://fonts/PixeloidSans-Bold.otf")
const BG := Color("171e2a")
const PAPER := Color("f3eddc")
const INK := Color("302d3c")
const GOLD := Color("ffe14d")
## Il -5 ha una scena sua, con la leva e Fermo (scenes/minigame/capo_dinamo.tscn).
const DINAMO := preload("res://scenes/minigame/capo_dinamo.tscn")
var dinamo: Node = null
var floor := "-3"
var p: Dictionary = {}
var buttons: Array = []
var selected := 0
var msg := ""
var finishing := false
var visuale: Node = null
const VISIVI := {
 "-4": preload("res://scenes/minigame/rifatti/capo_documenti.tscn"),
 "-3": preload("res://scenes/minigame/rifatti/capo_cartellino.tscn"),
 "-2": preload("res://scenes/minigame/rifatti/capo_contratto.tscn"),
 "0": preload("res://scenes/minigame/rifatti/capo_notiziario.tscn"),
}

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 floor = str(GameState.minigame.get("boss_floor", GameState.floor_id))
 Ui.show_hud(false)
 Sound.music("capo")
 p = B.progress(floor)
 if str(B.state(floor).get("status")) == "done":
  _return_world()
 elif floor == "-5":
  dinamo = DINAMO.instantiate()
  add_child(dinamo)
  dinamo.imposta(p)
  dinamo.cambiato.connect(_dinamo_cambiato)
  dinamo.confermato.connect(_dinamo_confermato)
  dinamo.esci.connect(_dinamo_esci)
 elif VISIVI.has(floor):
  visuale = VISIVI[floor].instantiate()
  add_child(visuale)
  if floor == "0": visuale.richiesta.connect(_montaggio_request)
  if floor == "-4": visuale.richiesta.connect(_fascicoli_request)
  if floor == "-3": visuale.richiesta.connect(_etichette_request)
  if floor == "-2": visuale.richiesta.connect(_calendario_request)
  _sync_visuale()
 queue_redraw()
 if visuale != null and not bool(B.state(floor).get("instructions_seen", false)):
  if Ui.transitioning:
   await Ui.faded_in
  await Ui.say(B.instructions(floor))
  B.state(floor)["instructions_seen"] = true
  B.checkpoint(floor)

func _sync_visuale() -> void:
 if visuale == null: return
 visuale.aggiorna(p, msg)
 buttons = visuale.bersagli()
 selected = clampi(selected, 0, maxi(0, buttons.size() - 1))
 visuale.evidenzia(selected)

func _process(_dt: float) -> void:
 if visuale != null: visuale.evidenzia(selected)

func _dinamo_cambiato(s: Dictionary) -> void:
 p.merge(s, true)
 B.checkpoint(floor)

func _dinamo_confermato(s: Dictionary) -> void:
 if finishing or Ui.busy: return
 _dinamo_cambiato(s)
 msg = B.finish_energy()
 if msg != "": dinamo.consegnato = false; dinamo.avviso(msg); return
 dinamo.visible = false
 _finish()

func _dinamo_esci() -> void:
 B.checkpoint(floor)
 _return_world()

func text_line(t: String, x: float, y: float, size := 10, col := PAPER) -> void:
 draw_string(FONT, Vector2(x, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _wrap_text(t: String, area: Rect2, size := 10, col := PAPER) -> void:
 var line := ""
 var y := area.position.y + size
 for word: String in t.split(" "):
  var test := line + (" " if line != "" else "") + word
  if FONT.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > area.size.x and line != "":
   if y <= area.end.y: text_line(line, area.position.x, y, size, col)
   y += size + 5; line = word
  else: line = test
 if y <= area.end.y: text_line(line, area.position.x, y, size, col)

func button(r: Rect2, label: String, action: String) -> void:
 var i := buttons.size()
 draw_style_box(_style(GOLD if i == selected else Color("415061")), r)
 _wrap_text(label, r.grow(-6), 9, INK if i == selected else PAPER)
 buttons.append({"rect": r, "action": action})

func _style(c: Color) -> StyleBoxFlat:
 var s := StyleBoxFlat.new(); s.bg_color = c
 return s

func _draw() -> void:
 if visuale != null and visuale.visible: return
 buttons.clear()
 draw_rect(Rect2(0, 0, 640, 360), BG)
 draw_rect(Rect2(16, 14, 4, 30), GOLD)
 text_line(str(B.TITLES.get(floor, "INCARICO")), 28, 29, 16, GOLD)
 text_line("CAPO / " + GameState.floor_name(floor), 28, 45, 8, Color("abb9c7"))
 if finishing and str(B.state(floor).get("status")) == "done":
  text_line("INCARICO CONSEGNATO", 28, 110, 20, GOLD)
  _wrap_text("Il lavoro è stato consegnato. Al piano restano le persone che ne sentiranno gli effetti.", Rect2(28, 132, 530, 65), 11)
  return
 if dinamo != null and dinamo.visible: return
 if msg != "": _wrap_text(msg, Rect2(24, 291, 592, 28), 8, GOLD)
 text_line("TOCCA PER SCEGLIERE E USARE" if TouchControls.enabled else "FRECCE: SCEGLI   INVIO O CLIC: USA", 24, 350, 8, Color("abb9c7"))
 button(Rect2(462, 320, 154, 22), "SALVA ED ESCI", "exit")

func touch_scheme() -> String:
 return "point" if not finishing else ""
func touch_point(pos: Vector2, step: int) -> void:
 if dinamo != null and dinamo.visible and not finishing and not Ui.busy:
  dinamo.punta(pos, step); return
 if finishing or Ui.busy: return
 if floor in ["0", "-4", "-3", "-2"] and visuale != null:
  visuale.punta(pos, step)
  buttons = visuale.bersagli()
  selected = clampi(selected, 0, maxi(0, buttons.size() - 1))
  return
 if step != 0: return
 for i in buttons.size():
  if (buttons[i]["rect"] as Rect2).has_point(pos):
   selected = i; _act(str(buttons[i]["action"])); return
func _unhandled_input(event: InputEvent) -> void:
 if Ui.busy or finishing or dinamo != null: return
 if event is InputEventKey and event.echo: return
 if floor in ["0", "-4", "-3", "-2"] and visuale != null and visuale.tastiera(event):
  buttons = visuale.bersagli()
  selected = clampi(selected, 0, maxi(0, buttons.size() - 1))
  return
 if floor in ["0", "-4", "-3", "-2"] and visuale != null and not TouchControls.enabled:
  if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
   touch_point(event.position, 0 if event.pressed else 2)
   return
  elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
   touch_point(event.position, 1)
   return
 if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not TouchControls.enabled:
  touch_point(event.position, 0)
 elif floor in ["-4", "-3", "-2"] and visuale != null and (event.is_action_pressed("move_up") or event.is_action_pressed("move_down") or event.is_action_pressed("move_left") or event.is_action_pressed("move_right")):
  var dir := Vector2.ZERO
  if event.is_action_pressed("move_left"): dir = Vector2.LEFT
  elif event.is_action_pressed("move_right"): dir = Vector2.RIGHT
  elif event.is_action_pressed("move_up"): dir = Vector2.UP
  else: dir = Vector2.DOWN
  selected = visuale.naviga(selected, dir)
  Sound.sfx("arcade/select_2")
 elif event.is_action_pressed("move_up") or event.is_action_pressed("move_left"):
  selected = posmod(selected - 1, maxi(1, buttons.size())); queue_redraw()
 elif event.is_action_pressed("move_down") or event.is_action_pressed("move_right"):
  selected = posmod(selected + 1, maxi(1, buttons.size())); queue_redraw()
 elif event.is_action_pressed("confirm") and selected < buttons.size():
  _act(str(buttons[selected]["action"]))

func _act(action: String) -> void:
 if finishing: return
 if floor == "0" and visuale != null and action.begins_with("mont_"):
  visuale.attiva(action.trim_prefix("mont_"))
  buttons = visuale.bersagli()
  selected = clampi(selected, 0, maxi(0, buttons.size() - 1))
  return
 if floor == "-4" and visuale != null and action.begins_with("fasc_"):
  visuale.attiva(action.trim_prefix("fasc_"))
  buttons = visuale.bersagli()
  selected = clampi(selected, 0, maxi(0, buttons.size() - 1))
  return
 if floor == "-3" and visuale != null and action.begins_with("label_"):
  visuale.attiva(action.trim_prefix("label_"))
  buttons = visuale.bersagli()
  selected = clampi(selected, 0, maxi(0, buttons.size() - 1))
  return
 if floor == "-2" and visuale != null and action.begins_with("loan_"):
  visuale.attiva(action.trim_prefix("loan_"))
  buttons = visuale.bersagli()
  selected = clampi(selected, 0, maxi(0, buttons.size() - 1))
  return
 if action == "exit":
  B.checkpoint(floor); _return_world(); return
 if floor == "0":
  match action:
   "facts":
    p["facts"] = not bool(p["facts"])
    if B.news_time(p) > 60: p["facts"] = false; msg = "Il cartello verificato richiede 10 secondi liberi."
   "broadcast":
    msg = B.finish_news()
    if msg == "": _finish(); return
 B.checkpoint(floor)
 _sync_visuale()
 Sound.sfx("arcade/computer_1" if floor == "-4" else "blip")
 queue_redraw()

func _finish() -> void:
 finishing = true
 if visuale != null: visuale.visible = false
 Sound.sfx("arcade/chime", 1.0, 2.0)
 queue_redraw()
 await Ui.say(B.result_lines(floor))
 _return_world()

func _return_world() -> void:
 finishing = true
 var s := B.state(floor)
 var pos: Array = s.get("return_pos", [])
 GameState.minigame = {"return_pos": Vector2(float(pos[0]), float(pos[1])) if pos.size() == 2 else Vector2.INF}
 Router.goto(str(s.get("return", Router.FONDO)), "_mg")

func _montaggio_request(azione: String, dati: Dictionary) -> void:
 if finishing or Ui.busy: return
 if azione in ["insert", "edit", "move", "remove", "draft_cut", "facts"]: visuale.riproduzione = false
 match azione:
  "select":
   p["source"] = int(dati["source"])
   p["cut"] = false
   msg = ""
  "draft_cut":
   p["cut"] = bool(dati["cut"])
   msg = ""
  "insert": msg = B.insert_news_clip(int(dati["source"]), int(dati["index"]))
  "edit": msg = B.edit_news_clip(int(dati["index"]), bool(dati["cut"]))
  "move": msg = B.move_news_clip(int(dati["from"]), int(dati["to"]))
  "remove": msg = B.remove_news_clip(int(dati["index"]))
  "facts":
   _act("facts"); return
  "exit":
   _act("exit"); return
  "broadcast":
   _act("broadcast"); return
  "focus_confirm":
   selected = 0
   buttons = visuale.bersagli()
   return
 B.checkpoint(floor)
 _sync_visuale()
 Sound.sfx("deny" if msg != "" else "blip")


func _fascicoli_request(azione: String, dati: Dictionary) -> void:
 if finishing or Ui.busy or visuale.consegnando: return
 match azione:
  "place": msg = B.place_document_piece(int(dati["piece"]), int(dati["slot"]))
  "remove": msg = B.remove_document_piece(int(dati["piece"]))
  "stamp": msg = B.stamp_document(int(dati["stamp"]))
  "exit":
   _act("exit"); return
  "focus_confirm":
   selected = 0
   buttons = visuale.bersagli()
   return
  "submit":
   msg = B.prepared_document_error()
   if msg == "":
    await visuale.anima_consegna()
    msg = B.submit_prepared_document()
    if str(B.state(floor).get("status")) == "done": _finish(); return
    selected = 0
 _sync_visuale()
 if msg != "": Sound.sfx("deny")

func _etichette_request(azione: String, dati: Dictionary) -> void:
 if finishing or Ui.busy or visuale.consegnando: return
 match azione:
  "set": msg = B.set_market_value(str(dati["key"]), int(dati["value"]))
  "print": msg = B.print_market_label()
  "move": msg = B.move_market_sticker(str(dati["kind"]), dati["point"])
  "hide": msg = B.hide_market_conditions()
  "exit":
   _act("exit"); return
  "focus_confirm":
   selected = 0
   buttons = visuale.bersagli()
   return
  "submit":
   msg = B.prepared_market_error()
   if msg == "":
    await visuale.anima_applicazione()
    msg = B.submit_prepared_market()
    if int(p["round"]) == 3:
     B.finish_market(); _finish(); return
    selected = 0
 _sync_visuale()
 if msg != "": Sound.sfx("deny")

func _calendario_request(azione: String, dati: Dictionary) -> void:
 if finishing or Ui.busy or visuale.consegnando: return
 match azione:
  "set": msg = B.set_contract_value(str(dati["key"]), int(dati["value"]))
  "copy": msg = B.set_contract_copy(bool(dati["visible"]))
  "exit":
   _act("exit"); return
  "focus_confirm":
   selected = 0
   buttons = visuale.bersagli()
   return
  "submit":
   if int(B.contract_preview(p)["monthly"]) > 6500:
    msg = "La rata supera 65 €. Allunga il calendario."
   else:
    await visuale.anima_invio()
    msg = B.finish_contract()
    if msg == "": _finish(); return
 _sync_visuale()
 Sound.sfx("deny" if msg != "" else "blip")
