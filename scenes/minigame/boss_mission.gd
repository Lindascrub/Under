extends Control
const B := preload("res://scripts/boss_missions.gd")
const FONT := preload("res://fonts/PixeloidSans-Bold.otf")
const BG := Color("171e2a")
const PAPER := Color("f3eddc")
const INK := Color("302d3c")
const GOLD := Color("ffe14d")
var floor := "-3"
var p: Dictionary = {}
var buttons: Array = []
var selected := 0
var msg := ""
var finishing := false

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 floor = str(GameState.minigame.get("boss_floor", GameState.floor_id))
 Ui.show_hud(false)
 Sound.music("capo")
 p = B.progress(floor)
 if str(B.state(floor).get("status")) == "done":
  _return_world()
 queue_redraw()

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
 buttons.clear()
 draw_rect(Rect2(0, 0, 640, 360), BG)
 draw_rect(Rect2(16, 14, 4, 30), GOLD)
 text_line(str(B.TITLES.get(floor, "INCARICO")), 28, 29, 16, GOLD)
 text_line("CAPO / " + GameState.floor_name(floor), 28, 45, 8, Color("abb9c7"))
 if finishing and str(B.state(floor).get("status")) == "done":
  text_line("INCARICO CONSEGNATO", 28, 110, 20, GOLD)
  _wrap_text("Il lavoro è stato consegnato. Al piano restano le persone che ne sentiranno gli effetti.", Rect2(28, 132, 530, 65), 11)
  return
 if floor == "-3": _draw_market()
 if floor == "-5": _draw_energy()
 if floor == "-4": _draw_documents()
 if floor == "-2": _draw_contract()
 if floor == "0": _draw_news()
 if msg != "": _wrap_text(msg, Rect2(24, 291, 592, 28), 8, GOLD)
 text_line("TOCCA PER SCEGLIERE E USARE" if TouchControls.enabled else "FRECCE: SCEGLI   INVIO O CLIC: USA", 24, 350, 8, Color("abb9c7"))
 button(Rect2(462, 320, 154, 22), "SALVA ED ESCI", "exit")

func _draw_market() -> void:
 var v := B.market_preview(p)
 draw_rect(Rect2(24, 62, 274, 218), PAPER)
 text_line("ETICHETTA %d / 3" % (int(p["round"]) + 1), 36, 82, 10, INK)
 text_line(str(v["product"]).to_upper(), 36, 105, 17, INK)
 text_line("OGGI: " + B.cash(int(v["base"])), 36, 124, 9, INK)
 text_line("RIFERIMENTO: " + B.cash(int(v["ref"])), 36, 141, 9, INK)
 text_line("-%d%%" % int(v["rate"]), 36, 175, 26, Color("b33b50"))
 text_line("ALLA CASSA: " + B.cash(int(v["basket"])), 36, 198, 11, INK)
 text_line("%d PEZZI X %s" % [int(v["units"]), B.cash(int(v["each"]))], 36, 215, 9, INK)
 _wrap_text("SUL CARTELLINO: " + ("prezzo, quantità e riferimento leggibili" if bool(p["visible"]) else "solo la percentuale in grande; condizioni al terminale"), Rect2(36, 225, 246, 48), 9, INK)
 button(Rect2(314, 62, 302, 33), "SCONTO: %d%% (0 / 10 / 50)" % int(p["rate"]), "rate")
 button(Rect2(314, 101, 302, 33), "RIFERIMENTO: " + ("OGGI" if int(p["reference"]) == 0 else "PREZZO FUTURO"), "reference")
 button(Rect2(314, 140, 302, 33), "QUANTITÀ MINIMA: %d" % int(p["units"]), "units")
 button(Rect2(314, 179, 302, 33), "CONDIZIONI: " + ("SUL CARTELLINO" if bool(p["visible"]) else "AL TERMINALE"), "visible")
 button(Rect2(314, 224, 302, 48), "APPLICA ETICHETTA", "submit")

func touch_scheme() -> String:
 return "point" if not finishing else ""
func touch_point(pos: Vector2, step: int) -> void:
 if step != 0 or finishing or Ui.busy: return
 for i in buttons.size():
  if (buttons[i]["rect"] as Rect2).has_point(pos):
   selected = i; _act(str(buttons[i]["action"])); return
func _unhandled_input(event: InputEvent) -> void:
 if Ui.busy or finishing: return
 if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not TouchControls.enabled:
  touch_point(event.position, 0)
 elif floor == "-4" and selected <= 4 and (event.is_action_pressed("move_up") or event.is_action_pressed("move_down") \
   or event.is_action_pressed("move_left") or event.is_action_pressed("move_right")):
  # I fascicoli si spostano fra quattro vaschette disposte come sulla scrivania,
  # quindi anche la tastiera segue quella geometria invece di una lista verticale.
  if event.is_action_pressed("move_left"):
   selected = (selected ^ 1) if selected < 4 else 3
  elif event.is_action_pressed("move_right"):
   selected = (selected ^ 1) if selected < 4 else 0
  elif event.is_action_pressed("move_up"):
   selected = selected - 2 if selected in [2, 3] else (2 if selected == 4 else 4)
  else:
   selected = selected + 2 if selected in [0, 1] else (0 if selected == 4 else 4)
  Sound.sfx("arcade/select_2", 1.0, 4.0)
  queue_redraw()
 elif event.is_action_pressed("move_up") or event.is_action_pressed("move_left"):
  selected = posmod(selected - 1, maxi(1, buttons.size())); queue_redraw()
 elif event.is_action_pressed("move_down") or event.is_action_pressed("move_right"):
  selected = posmod(selected + 1, maxi(1, buttons.size())); queue_redraw()
 elif event.is_action_pressed("confirm") and selected < buttons.size():
  _act(str(buttons[selected]["action"]))

func _act(action: String) -> void:
 if finishing: return
 if action == "exit":
  B.checkpoint(floor); _return_world(); return
 if floor == "-5":
  match action:
   "intensity": p["intensity"] = posmod(int(p["intensity"]), 3) + 1
   "extra": p["extra"] = posmod(int(p["extra"]) + 5, 25)
   "decor": p["decor"] = posmod(int(p["decor"]) + 1, 3)
   "simulate":
    msg = B.finish_energy()
    if msg == "": _finish(); return
 if floor == "-4" and action.begins_with("doc_"):
  msg = B.submit_document(action.trim_prefix("doc_").to_int())
  if str(B.state(floor).get("status")) == "done": _finish(); return
 if floor == "-2":
  match action:
   "months": p["months"] = [12, 24, 36][posmod([12, 24, 36].find(int(p["months"])) + 1, 3)]
   "apr": p["apr"] = [4, 8, 12][posmod([4, 8, 12].find(int(p["apr"])) + 1, 3)]
   "fee": p["fee"] = posmod(int(p["fee"]) + 60, 180)
   "visible": p["visible"] = not bool(p["visible"])
   "proposal":
    msg = B.finish_contract()
    if msg == "": _finish(); return
 if floor == "0":
  match action:
   "source": p["source"] = posmod(int(p["source"]) + 1, maxi(1, B.news_sources().size()))
   "cut": p["cut"] = not bool(p["cut"])
   "facts":
    p["facts"] = not bool(p["facts"])
    if B.news_time(p) > 60: p["facts"] = false; msg = "Il cartello verificato richiede 10 secondi liberi."
   "add": msg = B.add_news_clip()
   "undo":
    if not (p["clips"] as Array).is_empty(): (p["clips"] as Array).pop_back()
   "broadcast":
    msg = B.finish_news()
    if msg == "": _finish(); return
 if floor == "-3":
  match action:
   "rate": p["rate"] = [0, 10, 50][posmod([0, 10, 50].find(int(p["rate"])) + 1, 3)]
   "reference": p["reference"] = 1 - int(p["reference"])
   "units": p["units"] = 3 - int(p["units"])
   "visible": p["visible"] = not bool(p["visible"])
   "submit":
    msg = B.submit_market()
    if int(p["round"]) == 3:
     B.finish_market(); _finish(); return
 B.checkpoint(floor)
 Sound.sfx("arcade/computer_1" if floor == "-4" else "blip")
 queue_redraw()

func _finish() -> void:
 finishing = true
 Sound.sfx("arcade/chime", 1.0, 2.0)
 queue_redraw()
 if floor == "0":
  for clip: Dictionary in B.state("0").get("result", {}).get("clips", []):
   await Ui.say(["* " + str(clip["headline"]), "* Registrazione: " + str(clip["who"]) + '.', '"' + str(clip["broadcast_quote"]) + '"'], "Notiziario CHEAP")
   if not bool(clip["cut"]): await Ui.say(["* " + str(clip["context"])], "Notiziario CHEAP")
  if bool(p.get("facts", false)):
   await Ui.say(["* FATTI VERIFICATI: la Casa Comune rischia la chiusura. La vetrina è rotta. L'autore del danno non è stato identificato."], "Notiziario CHEAP")
 await Ui.say(B.result_lines(floor))
 _return_world()

func _return_world() -> void:
 finishing = true
 var s := B.state(floor)
 var pos: Array = s.get("return_pos", [])
 GameState.minigame = {"return_pos": Vector2(float(pos[0]), float(pos[1])) if pos.size() == 2 else Vector2.INF}
 Router.goto(str(s.get("return", "res://scenes/world/home.tscn")), "_mg")

func _draw_energy() -> void:
 var v := B.energy_preview(p)
 draw_rect(Rect2(24, 62, 300, 218), Color("293544"))
 text_line("DINAMO / SERVIZI + FESTA", 36, 83, 11, GOLD)
 text_line("PRODUZIONE %d / DOMANDA %d" % [int(v["production"]), int(v["demand"])], 36, 108, 10)
 draw_rect(Rect2(36, 122, 264, 14), Color("101723"))
 draw_rect(Rect2(36, 122, minf(264, float(v["production"]) * 2), 14), Color("68b9a5"))
 text_line("CARICO DI FERMO: %d" % int(v["fatigue"]), 36, 163, 11)
 text_line("PAUSA RIMASTA: %d MIN" % int(v["rest"]), 36, 186, 11, GOLD)
 _wrap_text("Gli essenziali richiedono 60. Le decorazioni aggiungono 0, 15 o 30. Più ritmo e minuti producono energia, ma la pausa e il fiato sono di Fermo.", Rect2(36, 205, 272, 65), 9)
 button(Rect2(340, 62, 276, 40), "INTENSITÀ: %d / 3" % int(p["intensity"]), "intensity")
 button(Rect2(340, 112, 276, 40), "DURATA EXTRA: %d MIN" % int(p["extra"]), "extra")
 button(Rect2(340, 162, 276, 40), "DECORAZIONI: %d / 2" % int(p["decor"]), "decor")
 button(Rect2(340, 226, 276, 46), "SIMULA E CONFERMA", "simulate")

func _draw_documents() -> void:
 var doc: Dictionary = B.DOCUMENTS[mini(3, int(p["document"]))]
 draw_rect(Rect2(24, 62, 592, 218), Color("59483f"))
 draw_rect(Rect2(34, 72, 330, 198), PAPER)
 draw_rect(Rect2(42, 80, 330, 198), Color("d8d0bd"))
 draw_rect(Rect2(34, 72, 330, 198), PAPER)
 text_line("FASCICOLO %s / %d DI 4" % [doc["id"], int(p["document"]) + 1], 46, 92, 10, INK)
 _wrap_text(str(doc["title"]), Rect2(46, 103, 306, 38), 12, INK)
 _wrap_text(str(doc["body"]), Rect2(46, 145, 306, 112), 9, INK)
 text_line("SCEGLI LA VASCHETTA", 386, 78, 9, GOLD)
 var labels := ["CONTABILITÀ", "PERSONALE", "CHIEDI INTEGRAZIONE", "SEGNA RISOLTA"]
 var trays := [Rect2(382, 88, 108, 76), Rect2(500, 88, 108, 76), Rect2(382, 176, 108, 76), Rect2(500, 176, 108, 76)]
 for i in 4:
  button(trays[i], labels[i], "doc_%d" % i)
 text_line("Sposta il fascicolo in una vaschetta.", 386, 270, 8, Color("eadfca"))

func _draw_contract() -> void:
 var r := B.contract_preview(p)
 draw_rect(Rect2(24, 62, 302, 218), PAPER)
 text_line("OLGA / PROPOSTA DA VALUTARE", 36, 82, 10, INK)
 text_line("CAPITALE: 1.200,00 €", 36, 104, 12, INK)
 text_line("BUDGET MENSILE: 65,00 €", 36, 123, 9, INK)
 text_line("RATA: " + B.cash(int(r["monthly"])), 36, 153, 17, Color("a53d50"))
 text_line("%d MESI / ULTIMA %s" % [int(r["months"]), B.cash(int(r["last"]))], 36, 174, 10, INK)
 text_line("INTERESSI: " + B.cash(int(r["interest"])), 36, 198, 10, INK)
 text_line("COSTO TOTALE: " + B.cash(int(r["total"])), 36, 218, 11, INK)
 _wrap_text("Il totale include capitale, interessi e commissione iniziale. Allungare abbassa la rata, ma aumenta gli interessi.", Rect2(36, 232, 277, 40), 8, INK)
 button(Rect2(342, 62, 274, 32), "DURATA: %d MESI" % int(p["months"]), "months")
 button(Rect2(342, 100, 274, 32), "TASSO ANNUO: %d%%" % int(p["apr"]), "apr")
 button(Rect2(342, 138, 274, 32), "COMMISSIONE INIZIALE: %d €" % int(p["fee"]), "fee")
 button(Rect2(342, 176, 274, 42), "RIEPILOGO: " + ("IN PRIMA PAGINA" if bool(p["visible"]) else "SOLO NELLA COPIA INTERNA"), "visible")
 button(Rect2(342, 232, 274, 40), "INVIA PROPOSTA", "proposal")

func _draw_news() -> void:
 var sources := B.news_sources()
 if sources.size() < 3:
  _wrap_text("Le registrazioni si raccolgono in piazza, dopo la manifestazione.", Rect2(24, 100, 500, 100))
  return
 var source: Dictionary = sources[posmod(int(p["source"]), sources.size())]
 draw_rect(Rect2(24, 62, 320, 162), PAPER)
 text_line("REGISTRAZIONE: " + str(source["who"]).to_upper(), 36, 82, 10, INK)
 _wrap_text('"' + (B.cut_quote(source) if bool(p["cut"]) else str(source["quote"])) + '"', Rect2(36, 95, 296, 55), 11, INK)
 _wrap_text("CONTESTO VERIFICATO: " + str(source["context"]), Rect2(36, 155, 296, 63), 9, INK)
 if bool(p["cut"]):
  draw_rect(Rect2(24, 152, 320, 72), Color("ead6c8"))
  _wrap_text("IN ONDA: " + B.cut_headline(str(source["id"])) + " / Il contesto viene tolto. Il titolo suggerisce una colpa non verificata.", Rect2(36, 160, 296, 59), 9, INK)
 text_line("TIMELINE: %d / 60 SECONDI" % B.news_time(p), 24, 244, 11, GOLD)
 var x := 24.0
 for clip: Dictionary in p["clips"]:
  var width := int(clip["duration"]) * 4.6
  draw_rect(Rect2(x, 255, width - 2, 24), Color("b65c5a") if bool(clip["cut"]) else Color("548f89"))
  text_line(str(clip["who"]).substr(0, 5), x + 3, 270, 8)
  x += width
 button(Rect2(360, 62, 256, 32), "CAMBIA FONTE / ORDINE", "source")
 button(Rect2(360, 100, 256, 42), "MONTAGGIO: " + ("TAGLIO + TITOLO DI SCONTRO" if bool(p["cut"]) else "PAROLE NEL LORO CONTESTO"), "cut")
 button(Rect2(360, 148, 256, 32), "AGGIUNGI ALLA TIMELINE", "add")
 button(Rect2(360, 186, 256, 32), "FATTI VERIFICATI (10s): " + ("SÌ" if bool(p["facts"]) else "NO"), "facts")
 button(Rect2(360, 224, 120, 48), "TOGLI ULTIMO", "undo")
 button(Rect2(488, 224, 128, 48), "TRASMETTI", "broadcast")

