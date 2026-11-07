extends Node

const BASE := "res://tests/fixtures/"
var checks := 0
var failures: Array[String] = []
var npcs: Dictionary

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func press(n: Node, action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	if n.has_method("input_event"): n.input_event(e)
	else: n._unhandled_input(e)

func game(id: String, practice := false) -> Node:
	GameState.flags.clear()
	var c: Dictionary = npcs[id].help.minigame.duplicate(true)
	c["intro"] = []
	c["id"] = id
	c["prima_prova"] = practice
	GameState.minigame = c
	var n: Node = load("res://scenes/minigame/minigame.tscn").instantiate()
	n.set_script(load(BASE + "personaggi_probe.gd"))
	add_child(n)
	await get_tree().process_frame
	n.set_process(false)
	if n.visivo != null: n.visivo.set_process(false)
	return n

func remove(n: Node) -> void:
	n.queue_free()
	await get_tree().process_frame

func _ready() -> void:
	GameState.save_path = "user://personaggi_revisione_test.json"
	GameState.new_game()
	Ui.show_hud(false)
	npcs = JSON.parse_string(FileAccess.get_file_as_string("res://data/npcs.json"))
	get_tree().create_timer(55).timeout.connect(func():
		push_error("Timeout verifica personaggi")
		get_tree().quit(2))
	for tel in [false, true]:
		TouchControls.enabled = tel
		await wires(tel)
		await inventory()
		await sequence(tel)
		await receipts()
		await documents()
		await leaflets(tel)
		await transit(tel)
		await bulbs()
		await ercole()
	TouchControls.enabled = false
	print("PERSONAGGI: %d controlli, errori %s" % [checks, failures])
	get_tree().quit(0 if failures.is_empty() else 1)

func wires(tel: bool) -> void:
	var n := await game("bulbo")
	n.touch_point(Vector2(20, 10), 0)
	check(n.wire_pick == -1, "Mina: premere fuori dal pannello non prende un filo")
	# la tastiera non collega niente: i fili si fanno solo trascinando (mouse o dito)
	press(n, "confirm")
	press(n, "move_down")
	press(n, "confirm")
	check(n.wire_done.is_empty() and n.wire_pick == -1, "Mina: la tastiera non collega fili")
	for panel in 3:
		for color in 4:
			var at: int = n.wire_right.find(color)
			var from := Vector2(210, 146 + color * 98.0/3.0)
			var to := Vector2(430, 146 + at * 98.0/3.0)
			n.touch_point(from, 0)
			n.touch_point(to, 1)
			n.touch_point(to, 2)
		check(n.wire_round == panel + 1, "Mina: pannello completo trascinando " + ("col dito" if tel else "col mouse"))
	check(n.risultato_test == [true, false] and n.misses == 0, "Mina: tre pannelli, nessun errore")
	await remove(n)

func inventory() -> void:
	var n := await game("leda", true)
	var time: float = n.time_left
	n._process(10)
	check(n.time_left == time, "Leda: il primo prodotto non consuma tempo")
	var count: int = n.inv_queue.size()
	var c: int = n.inv_queue[0][1]
	n.touch_point(n._inv_product_rect().get_center(), 0)
	n.touch_point(Vector2(20, 20), 2)
	check(n.inv_queue.size() == count and n.misses == 0, "Leda: lasciare fuori annulla senza consumare un prodotto")
	for i in count:
		c = n.inv_queue[0][1]
		n.touch_point(n._inv_product_rect().get_center(), 0)
		n.touch_point(n._inv_shelf(c).get_center(), 1)
		n.touch_point(n._inv_shelf(c).get_center(), 2)
	check(n.risultato_test == [true, false] and n.inv_done == count and n.inv_sistemati.reduce(func(a, b): return a+b, 0) == count, "Leda: i prodotti trascinati riempiono gli scaffali una volta sola")
	await get_tree().create_timer(0.35).timeout
	await remove(n)

func sequence(tel: bool) -> void:
	var n := await game("tilde")
	var original: Array = n.seq.duplicate()
	var crossed: Array = n.seq_rosse.duplicate()
	n.phase = "play"
	var expected: Array = n._da_dire()
	var wrong: String = "down" if expected[0] != "down" else "up"
	press(n, "move_" + wrong)
	check(n.misses == 1 and n.seq == original and n.seq_rosse == crossed and n.round_n == 1 and n.phase == "show", "Tilde: dopo l'errore riascolti lo stesso copione")
	for round_index in 2:
		n.phase = "play"
		expected = n._da_dire()
		for a: String in expected:
			if tel: n.touch_point(n._seq_pad(a).get_center(), 0)
			else: press(n, "move_" + a)
	check(n.risultato_test == [true, false] and n.misses == 1, "Tilde: due copioni completabili con frecce o tasti a schermo")
	await remove(n)

func receipts() -> void:
	var n := await game("olga", true)
	var v: Node = n.visivo
	for r in v.ricevute: r.queue_free()
	v.ricevute.clear()
	v.prossima = 0
	v.ultima = null
	v.selezionata = null
	var cards: Array[Control] = []
	for i in 4:
		var r: Control = v.crea_ricevuta()
		r.position.x = 380 - (3-i)*172
		cards.append(r)
	v._process(10)
	check(v.guida and cards[3].position.x == 380 and v.errori == 0, "Olga: il primo doppio ferma il nastro per imparare")
	v.seleziona(cards[3])
	check(v.riferimento.text.contains("Commissione bonifico") and v.riferimento.text.contains("03/06"), "Olga: il riferimento mostra davvero la voce precedente")
	press(v, "confirm")
	check(v.timbrati == 1 and not v.guida, "Olga: il doppio si timbra anche da tastiera e fa partire la prova")
	v.timbra(cards[1])
	v.timbra(cards[1])
	check(v.errori == 1 and v.timbrati == 1, "Olga: insistere sulla stessa voce non conta più errori")
	v.timbra(cards[3])
	check(v.timbrati == 1, "Olga: nessun doppio timbro")
	await get_tree().create_timer(0.35).timeout
	await remove(n)

func documents() -> void:
	var n := await game("teo")
	var v: Node = n.visivo
	v.pausa_timbro = 0.01
	v.scegli(0)
	v.scegli(0)
	check(v.errori == 1, "Teo: un errore ripetuto non consuma tutte le possibilità")
	for k in [4, 2, 0, 2, 3, 4]:
		v.scegli(k)
		await get_tree().create_timer(0.03).timeout
	check(n.risultato_test == [true, false], "Teo: sei pratiche, comprese quelle senza anomalie")
	await remove(n)

func leaflets(tel: bool) -> void:
	var n := await game("ada", true)
	var v: Node = n.visivo
	var p: Node = v.crea_persona()
	p.position.x = 350
	var time: float = v.tempo
	v._process(10)
	v.consegna(p, 1)
	if tel: check(v.guida_t > 0 and v.get_node("Guida").visible, "Ada: il gesto di esempio si anima anche con il tempo fermo")
	check(v.tempo == time and p.position.x == 350 and v.errori == 0, "Ada: prima consegna senza tempo né penalità")
	var correct: int = p.get_meta("interesse")
	if tel:
		v.punta(v.get_node("Pile").get_child(correct).get_global_rect().get_center(), 0)
		v.punta(p.position - Vector2(0, 20), 1)
		v.punta(p.position - Vector2(0, 20), 2)
	else:
		v.pila = correct
		press(v, "confirm")
	await get_tree().create_timer(0.3).timeout
	check(v.dati == 1 and not v.prima_consegna and v.errori == 0, "Ada: gesto pila-persona o tastiera consegna una sola volta")
	for i in 7:
		p = v.crea_persona()
		if not p.get_meta("disponibile"):
			p = v.crea_persona()
		p.position.x = 350
		v.consegna(p, p.get_meta("interesse"))
		await get_tree().create_timer(0.26).timeout
	check(n.risultato_test == [true, false] and GameState.flags.get("c5_volantini", 0) == 8, "Ada: gli otto volantini mantengono l'esito della storia")
	await remove(n)

func transit(tel: bool) -> void:
	var n := await game("nadir")
	var lines: Array = n._cz_targets()
	var bus: Dictionary = lines[1]
	var before: Array = n.cz_path.duplicate()
	var preview: String = n._cz_preview(bus)
	check(preview.contains("6:45 > 7:10") and preview.contains("2/6") and n.cz_path == before, "Nadir: anteprima di orario e costo senza prendere una corsa")
	if tel:
		var curve: PackedVector2Array = n._cz_curve(bus)
		n.touch_point(curve[0], 0)
		for pos in curve: n.touch_point(pos, 1)
		n.touch_point(curve[-1], 2)
	else:
		n.cz_focus = 1
		press(n, "confirm")
	check(n.cz_at == 1 and n.cz_now == 430, "Nadir: la prima tratta segue la linea selezionata")
	for line: Variant in n._cz_targets():
		if line is Dictionary and line.linea == "Bus 30":
			n._cz_take(line)
			break
	check(n.risultato_test == [true, false] and n._cz_cost() == 2 and n.cz_now == 478, "Nadir: itinerario valido sotto budget e prima delle otto")
	await remove(n)

func bulbs() -> void:
	var n := await game("mina")
	n.bulb = "fioca"
	press(n, "move_up")
	press(n, "move_down")
	check(n.bulb == "buona" and n.bulb_fixed and n.misses == 0, "Bulbo: la lampadina riparata si accende prima dello smistamento")
	press(n, "move_right")
	check(n.bulb_done == 1, "Bulbo: la riparata va nelle BUONE")
	await remove(n)

func ercole() -> void:
	var n := await game("ercole")
	var v: Node = n.get_node("ErcoleGomitata")
	v.set_process(false)
	v.sonno = 0.8
	v.premi()
	v.carica = 0.55
	v._aggiorna()
	check(v.risultato.text == "LASCIA ORA!", "Ercole: segnale leggibile quando sonno e forza sono giusti")
	v.lascia()
	check(v.riuscite == 1 and v.errori == 0, "Ercole: il rilascio al momento giusto risveglia senza richiami")
	await get_tree().create_timer(0.3).timeout
	await remove(n)
