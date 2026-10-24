extends Node2D
## La pagella di fine capitolo 1: compare la prima volta che sali le scale del Fondo.
## Una riga per ogni scelta, con un commento ironico, poi si prosegue al piano -4.

const NEXT := "res://scenes/world/sottoufficio.tscn"
const YELLOW := Color("ffe14d")
const GREY := Color("8a8494")

var _rows: Array[Array] = []


func _ready() -> void:
	Ui.show_hud(false)
	Sound.music("")
	if GameState.flags.get("c1_pagella", false):
		Router.goto.call_deferred(NEXT, "from_below")
		return
	GameState.flags["c1_pagella"] = true
	var bg := ColorRect.new()
	bg.color = Color("0b0a10")
	bg.size = Vector2(640, 360)
	add_child(bg)
	_label("CAPITOLO 1", Vector2(0, 26), 13, GREY)
	_label("IL FONDO", Vector2(0, 44), 26, YELLOW)
	if Ui.transitioning:
		await Ui.faded_in
	await get_tree().create_timer(0.6).timeout
	var y := 82.0
	for r in _report():
		var a := _label(str(r[0]), Vector2(36, y), 11, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		a.size = Vector2(250, 24)
		var b := _label(str(r[1]), Vector2(296, y), 10, GREY, HORIZONTAL_ALIGNMENT_LEFT)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.size = Vector2(310, 26)
		Sound.sfx("stamp", 1.2)
		y += 28.0
		await get_tree().create_timer(0.7).timeout
	var verdict := _verdict()
	_label(verdict, Vector2(0, y + 6), 13, YELLOW)
	Sound.sfx("spare")
	await get_tree().create_timer(0.8).timeout
	await Ui.say(["* Fine del capitolo 1. Le scale salgono verso il piano -4."])
	Router.goto(NEXT, "from_below", ["Piano -4."])


func _label(text: String, pos: Vector2, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(640, size + 12)
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	add_child(l)
	return l


## Le righe della pagella: [cosa, commento].
func _report() -> Array:
	var rows: Array = []
	var hours := GameState.hard_work * 10
	rows.append(["Ore di cyclette: %d" % hours,
		"Nessuna. La festa ti ha visto e basta." if hours == 0 else ("Le luci di sopra ringraziano. Non sanno chi sei." if hours < 30 else "Instancabile. Proprio quello che volevano.")])
	var helped: Array = []
	for id: String in GameState.floor_people("-5"):
		if id in GameState.helped_ids:
			helped.append(str(GameState.npc_data(id).get("name", id)))
	rows.append(["Aiutati: " + (", ".join(helped) if not helped.is_empty() else "nessuno"),
		"Avevi fretta. Si capisce." if helped.is_empty() else ("Tutti. Nives se lo ricorderà." if helped.size() >= GameState.floor_people("-5").size() else "Qualcuno, qui sotto, ha un colore in più.")])
	if GameState.is_robot("fermo"):
		rows.append(["Il quaderno di Fermo: tuo", "Adesso Fermo sorride. Come i palloncini."])
	else:
		rows.append(["Il quaderno di Fermo: suo", "Le idee di Fermo restano di Fermo. Per ora."])
	var how := "comprato"
	if GameState.flags.get("gift_-5", false):
		how = "regalato da Nives"
	elif int(GameState.flags.get("contracts", 0)) > 0:
		how = "a rate, col Signor Rata"
	rows.append(["Badge del -4: " + how, {"comprato": "Una rata del debito, con un nastrino.", "regalato da Nives": "La prima cosa gratis della torre.", "a rate, col Signor Rata": "Clausola tre: la scoprirai."}[how]])
	var truths := 0
	for id in ["fermo", "mina", "bulbo"]:
		if GameState.flags.get("svelato_" + id, false):
			truths += 1
	if GameState.flags.get("c1_sbarrato", false):
		rows.append(["Verità sul Fondo: 0 su 3", "Sei salito senza voltarti. La scala, dietro, è sbarrata."])
	else:
		rows.append(["Verità sul Fondo: %d su 3" % truths, "Adesso sai di chi sono i colori." if truths >= 3 else "Qualcosa l'hai capito. Qualcosa no."])
	rows.append(["Autostima: %d" % GameState.self_esteem, "Si vede dal modo in cui sali le scale." if GameState.self_esteem > 0 else "Sali a testa bassa."])
	return rows


func _verdict() -> String:
	if GameState.is_robot("fermo"):
		return "GIUDIZIO: PROMETTENTE. LA CHEAP È FIERA DI TE."
	if GameState.flags.get("gift_-5", false):
		return "GIUDIZIO: INSUFFICIENTE IN EGOISMO."
	return "GIUDIZIO: UN BRAVO INGRANAGGIO."
