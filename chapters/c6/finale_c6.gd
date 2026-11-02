extends Node2D
## Capitolo 6 — il finale, gli epiloghi, il sogno, i titoli di coda. Una scena sola, a passi:
##   passo 0       il finale (famiglia e variante decise da finali.gd, salvate in chapter_6.outcome)
##   passi 1-5     SEI MESI DOPO: la Città, la Banca, il Mercato, il Sottoufficio, il Fondo (dall'alto in basso)
##   passo 6       Nives, per ultima
##   passo 7       il sogno: "Prima di arrivare qui, cosa volevi fare?"
##   passo 8       CHEAP. "Quanto costa una vita?" FINE, e i titoli di coda
## Dopo ogni passo si salva (la partita ricomincia da qui, dal passo dopo): niente scene ripetute, niente stati a metà.

const CIMA_LOGIC := preload("res://chapters/c6/cima_c6.gd")
const RULES := preload("res://chapters/c6/direzione_regole.gd")
const FINALI := preload("res://chapters/c6/finali.gd")
const C5 := preload("res://chapters/c5/citta_c5.gd")
const SELF := "res://chapters/c6/finale.tscn"
const CIMA := "res://chapters/c6/cima.tscn"
const MENU := "res://scenes/main_menu.tscn"
const ART := "res://art/c6/"
const PRES := "La Presidente"
const NIVES := "Nives"
const VOICE := "Voce CHEAP"
const GOLD := Color("ffe14d")
## Il protagonista (lo stesso foglio di Player).
const PLAYER_SHEET := "char_01"
const DIM := Color("8a8494")
## I piani degli epiloghi, dall'alto verso il basso: [titolo, banda nella torre, persone, colore].
const SEGMENTS := [
	["LA CITTÀ", 1, ["ada", "nadir", "rina"], Color("2c4a5e")],
	["LA BANCA", 2, ["olga", "teo"], Color("4a2026")],
	["IL MERCATO", 3, ["leda", "amir"], Color("24402a")],
	["IL SOTTOUFFICIO", 4, ["tilde", "ercole"], Color("26283e")],
	["IL FONDO", 5, ["fermo", "bulbo", "mina"], Color("231e2a")],
]
const DREAMS := ["Creare qualcosa.", "Studiare.", "Viaggiare.", "Stare con qualcuno.", "Avere tempo per me.", "Non lo so."]
const DREAM_IDS := ["creare", "studiare", "viaggiare", "qualcuno", "tempo", "non_so"]

var d: Dictionary
var out: Dictionary
var sm: Dictionary
var stage: Node2D
var layer: CanvasLayer
var bg: ColorRect
## Per i test: non aspettare le pause lunghe.
var fast := false


func _ready() -> void:
	d = CIMA_LOGIC.c6()
	if not d["final_decision"]["confirmed"]:
		Router.goto(CIMA, "desk")
		return
	out = d["outcome"]
	# un salvataggio fatto prima delle regole nuove: il finale si ricalcola con quello che il salvataggio sa
	if not out.has("engine"):
		out = FINALI.decide(str(d["final_decision"].get("selected", out.get("family", "B"))))
		out["engine"] = 2
		d["outcome"] = out
	sm = FINALI.effective_summary(str(out.get("family", "")), str(out.get("variant", "")))
	Ui.cutscene = true
	Ui.show_hud(false)
	layer = CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	bg = ColorRect.new()
	bg.size = Vector2(640, 360)
	bg.color = Color.BLACK
	layer.add_child(bg)
	stage = Node2D.new()
	layer.add_child(stage)
	await get_tree().process_frame
	if Ui.transitioning:
		await _until_faded()
	await run()


func _until_faded() -> void:
	while Ui.transitioning:
		await get_tree().process_frame


func _step() -> int:
	return int(d["epilogue"].get("step", 0))


func _advance() -> void:
	d["epilogue"]["step"] = _step() + 1
	GameState.save_game(SELF)


func run() -> void:
	if d["completed"]:
		MemoriaNives.record(out, sm)
		await _credits()
		return
	while _step() <= 8:
		match _step():
			0:
				await family_scene()
			1, 2, 3, 4, 5:
				d["epilogue"]["started"] = true
				await epilogue_segment(_step() - 1)
			6:
				await nives_scene()
			7:
				await dream_scene()
			8:
				d["completed"] = true
				d["epilogue"]["completed"] = true
				GameState.save_game(SELF)
				# arrivati ai titoli di coda: adesso, e solo adesso, Nives se lo ricorda
				MemoriaNives.record(out, sm)
				await _credits()
				return
		_advance()


func _wait(t: float) -> void:
	if not fast:
		await get_tree().create_timer(t).timeout


# --- il palco: sfondo, persone, scritte --------------------------------------------------------------

func _clear() -> void:
	for c in stage.get_children():
		c.queue_free()


func _label(text: String, pos: Vector2, size: Vector2, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.text = text
	l.position = pos
	l.size = size
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	stage.add_child(l)
	return l


func _actor(sheet: String, x: float, grey := true, robot := false, anim := "idle_down", person := "") -> CharSprite:
	var s := CharSprite.new()
	s.sheet = sheet
	s.person = "" if robot else person
	s.anim = anim
	s.grey = grey and not robot
	s.scale = Vector2(3, 3)
	s.position = Vector2(x, 228)
	stage.add_child(s)
	if robot:
		C5._antenna(s)
	return s


func _sheet(id: String) -> String:
	return str(GameState.npc_data(id).get("sheet", "char_02"))


func _name(id: String) -> String:
	return str(GameState.npc_data(id).get("name", id.capitalize()))


func _floor_strip(col: Color) -> void:
	bg.color = col
	var floor_rect := ColorRect.new()
	floor_rect.color = col.darkened(0.4)
	floor_rect.position = Vector2(0, 220)
	floor_rect.size = Vector2(640, 40)
	stage.add_child(floor_rect)


func _fade_title(top: String, title: String) -> void:
	_clear()
	bg.color = Color.BLACK
	var a := _label(top, Vector2(0, 130), Vector2(640, 24), 13, DIM)
	var b := _label(title, Vector2(0, 156), Vector2(640, 40), 24, GOLD)
	a.modulate.a = 0.0
	b.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(a, "modulate:a", 1.0, 0.6 if not fast else 0.01)
	tw.tween_property(b, "modulate:a", 1.0, 0.6 if not fast else 0.01)
	await tw.finished
	await _wait(1.6)
	_clear()


# --- passo 0: il finale ------------------------------------------------------------------------------
# Le scene seguono docs/STORIA_BANCA_CIMA.md, sezioni 5 e 6. Cosa vale davvero nella Torre lo dice
# FINALI.effective_summary(): le decisioni dei cicli solo in A e C2, altrimenti le regole di prima.

func family_scene() -> void:
	var fam := str(out.get("family", "B"))
	var var_ := str(out.get("variant", "B1"))
	Sound.music("cima")
	_floor_strip(Color("3a2450"))
	var pres := _actor("char_20", 380, true, false, "idle_left", "presidente")
	_actor(PLAYER_SHEET, 260, false, false, "idle_right")
	match fam:
		"A":
			await Ui.say(["Congratulazioni."], PRES)
			Sound.sfx("stamp")
			var s := TextureRect.new()
			s.texture = load(ART + "timbro_annullato.png")
			s.position = Vector2(272, 60)
			stage.add_child(s)
			await Ui.say(["* La Presidente timbra il documento.", "* DEBITO PERSONALE: 0 €."])
			await Ui.say(["SEI LIBERO!"], VOICE)
			await Ui.say(["Mi raccomando.", "La macchina del caffè funziona soltanto se la colpisci due volte."], PRES)
			match var_:
				"A2":
					pres.queue_free()
					Sound.sfx("door")
					await Ui.say(["* La Presidente lascia l'ufficio. Non si volta."])
					await Ui.say([printer_line(str(sm["debt_rule"]))] + debt_lines())
					_actor("char_13", 420, true, false, "idle_left")
					await Ui.say(["* Più tardi entra Nives. Ha un badge in mano, per abitudine."])
					await Ui.say(["Posso chiederti una cosa?", "Quando non ci sarai più…", "Chi deciderà al posto tuo?"], NIVES)
				"A1":
					await Ui.say(["* L'ufficio. Il tuo debito: annullato. Il timbro ANNULLATO è sulla scrivania, usato una volta.",
						"* La Presidente esce con una scatola."])
					await Ui.say(["Le chiavi del salottino. I cuscini sono ancora nella plastica."], PRES)
					pres.queue_free()
					Sound.sfx("blip", 0.6)
					await Ui.say(["* Vrrr. La stampante butta fuori un fascicolo. OBBLIGO DI ESISTENZA. Un nome nuovo. 7.000.000.000 €.",
						"* Il telefono ha un solo tasto: FONDO. Lo premi.",
						"* Dall'altra parte qualcuno respira forte, come chi ha appena pedalato.", "* \"...Pronto?\""])
					await Ui.choose("", ["È tutto molto semplice!"])
					await Ui.say(["* Nero."])
				_:
					pres.queue_free()
					var a3: Array = ["* L'ufficio. Il tuo debito: annullato. " + printer_line(str(sm["debt_rule"])).trim_prefix("* ")]
					if bool(d["boss"]["global_credit_accepted"]):
						a3.append("* Sui registri del lavoro della Torre c'è il tuo nome. Su tutti.")
					a3.append("* Sei solo alla scrivania. La Presidente ha lasciato le chiavi del salottino. I cuscini sono ancora nella plastica.")
					await Ui.say(a3)
					Sound.sfx("drring")
					await Ui.say(["* Il telefono suona. Tasto FONDO.", "* Rispondi. \"Pronto?\" Dall'altra parte qualcuno parla a lungo.",
						"* Non dici \"È tutto molto semplice\". Non dici niente. Prendi una penna.", "* Nero."])
		"B":
			await Ui.say(["Davvero non vuoi restare?"], PRES)
			await Ui.choose("Cosa rispondi?", ["Ho già lavorato abbastanza.", "Voglio fare qualcos'altro.", "Non voglio decidere per tutti."], PRES)
			await Ui.say(["Capisco.", "Vorrei poterti dire che fuori sarà tutto più semplice."], PRES)
			_clear()
			_floor_strip(Color("2c3a4a"))
			_actor(PLAYER_SHEET, 300, false, false, "idle_right")
			await Ui.say(["* La stazione. Un binario, un tabellone che per una volta non dice PREMIUM."])
			await Ui.say(_departure_lines())
			await _b_scene()
		_:
			await Ui.say(["Quindi…", "Vorresti che le persone che lavorano qui decidessero anche come funziona il posto?", "Interessante.",
				"Le riunioni saranno terribili."], PRES)
			await Ui.say(_roles_lines())
			match var_:
				"C2":
					await _c2_scene()
				"C3":
					await _c3_scene()
				_:
					await _c1_scene()
	await _final_line(final_line(var_))


static func final_line(variant: String) -> String:
	match variant:
		"A1":
			return "Avevi comprato la libertà. Adesso dovevi trovare il tempo per usarla."
		"A2":
			return "Avevi cambiato molte regole. Restava da capire chi avrebbe potuto cambiarle dopo di te."
		"B2":
			return "Non avevi guadagnato tutto quello che volevi. Avevi ricominciato a fare qualcosa che desideravi."
		"C1":
			return "Non avevate costruito un mondo nuovo. Avevate trovato un modo diverso di abitare un pezzo di quello vecchio."
		"C2":
			return "La Torre era ancora lì. Ma non serviva più arrivare in cima per farsi ascoltare."
		"C3":
			return "Avevi scoperto che decidere insieme non significava essere sempre d'accordo."
	return "Non sapevi se sarebbe stato facile. Per la prima volta, però, il tuo prossimo passo non era una scala."


func _final_line(line: String) -> void:
	_clear()
	bg.color = Color.BLACK
	var l := _label(line, Vector2(60, 130), Vector2(520, 100), 15, Color.WHITE)
	l.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 1.2 if not fast else 0.01)
	await tw.finished
	await _wait(4.0)
	var tw2 := create_tween()
	tw2.tween_property(l, "modulate:a", 0.0, 0.8 if not fast else 0.01)
	await tw2.finished


# --- la stampante e i due debiti (sezione 5) ---------------------------------------------------------

## La stampante segue la regola che vale davvero.
static func printer_line(rule: String) -> String:
	match rule:
		"interessi":
			return "* La stampante: vrrr regolare. Sui fascicoli: \"interessi 0,5%\"."
		"revisione":
			return "* La stampante è ferma. Un cartello: \"In revisione\". La pila non cresce."
		"alternative":
			return "* La stampante: vrrr regolare. Accanto, una bacheca con le reti vere."
	return "* La stampante: vrrr regolare, fascicolo dopo fascicolo."


## Il tuo debito e quello degli altri: due righe separate, in tutti i finali.
func debt_lines() -> Array:
	var mine: String = {"annullato": "ANNULLATO", "in_revisione": "IN REVISIONE", "contestato": "CONTESTATO"}.get(str(out.get("debt_status", "")), "REGISTRATO")
	var others: String = {"interessi": "registrati, con gli interessi allo 0,5%", "revisione": "in revisione"}.get(
		FINALI.others_debts(str(out.get("family", "")), str(out.get("variant", ""))), "registrati, come prima")
	return ["* Il tuo debito: %s." % mine, "* I debiti degli altri: %s." % others]


# --- B: IL TEMPO CHE RESTA (ogni pezzo dalla sua fonte) ------------------------------------------------

const WORK_TEXT := {"nadir": "del turno corto alla zona industriale", "leda": "degli ordini condivisi", "amir": "delle consegne"}


## B: cosa ti porti alla stazione e cosa succede al debito (contestato solo con la contestazione alla Cima).
func _departure_lines() -> Array:
	var lines: Array = ["* In tasca: %s." % GameState.euros(GameState.money)]
	if str(out.get("debt_status", "")) == "contestato":
		lines.append("* Nella borsa, la contestazione registrata dalla Presidente. Il debito resta, sospeso fino alla risposta.")
	else:
		lines.append("* Il debito viene con te: %s." % GameState.euros(GameState.debt))
	var b := FINALI.bonds()
	if not b.is_empty():
		var names: Array = []
		for id: String in b:
			names.append(_name(id))
		lines.append("* Sul telefono, qualche numero nuovo: " + ", ".join(names) + ".")
	return lines


## Il foglio della Banca, se c'è: il riepilogo o la ricevuta della richiesta (un vecchio salvataggio: niente).
static func bank_paper() -> String:
	if GameState.flags.get("c4_riepilogo", false):
		return "il riepilogo della Banca"
	if GameState.flags.get("c4_verifica", false):
		return "la ricevuta della Banca"
	return ""


## Le righe del finale B (anche per i test): casa, frigo, calendario, chi scrive. Niente casa o lavoro
## senza il dialogo che li ha offerti; se manca, il suo ripiego.
func b_lines() -> Dictionary:
	var homes := FINALI.offers(FINALI.HOME_OFFERS)
	var works := FINALI.offers(FINALI.WORK_OFFERS)
	var sender := FINALI.evening_sender()
	var contested := str(out.get("debt_status", "")) == "contestato"
	var paper := bank_paper()
	var lines: Array = []
	if homes.is_empty() and works.is_empty() and FINALI.bonds().is_empty():
		lines.append("* Una stanza in affitto, per un mese. La valigia è ancora mezza piena.")
		if contested:
			lines.append("* Sul frigo: \"Debito: CONTESTATO. Pratica in attesa.\"")
		lines.append("* Sul tavolo: " + (paper + " e un annuncio cerchiato." if paper != "" and not contested else "un annuncio cerchiato."))
		lines.append("* Sotto la porta qualcuno ha infilato un volantino: \"Stasera cena di chi è appena arrivato. Porta una sedia.\"")
		return {"lines": lines, "sender": "", "alone": true, "home": "", "work": ""}
	lines.append("* Sei mesi dopo. Una cucina piccola, " + ("nella stanza che ti ha trovato %s." % _name(homes[0]) if not homes.is_empty() \
		else "in un posto letto in affitto, per un mese.") + " Dalla finestra si vede la Torre, ancora accesa.")
	if contested:
		lines.append("* Sul frigo: \"Debito: CONTESTATO. Pratica in attesa.\"")
	elif paper != "":
		lines.append("* In un cassetto, %s." % paper)
	if not works.is_empty():
		lines.append("* Il calendario: i giorni del lavoro %s sono cerchiati. Gli altri sono vuoti. Vuoti apposta." % WORK_TEXT[works[0]])
	else:
		lines.append("* Sul calendario, un annuncio cerchiato, ancora senza risposta.")
	return {"lines": lines, "sender": sender, "alone": false, "home": homes[0] if not homes.is_empty() else "",
		"work": works[0] if not works.is_empty() else ""}


func _b_scene() -> void:
	var b := b_lines()
	_clear()
	_floor_strip(Color("3a3226"))
	_actor(PLAYER_SHEET, 300, false, false, "idle_down")
	await Ui.say(b["lines"])
	var sender := str(b["sender"])
	if sender != "":
		await Ui.say(["* Il telefono vibra. %s:" % _name(sender)])
		await Ui.say(["Ci sei stasera?"], _name(sender))
	else:
		await Ui.say(["* Sul pianerottolo, una vicina che non conosci:"])
		await Ui.say(["Ci sei stasera?"], "Una vicina")
	await Ui.choose("", ["Sì."])
	await Ui.say(["* Non sai ancora se resterai. Prendi la sedia."] if bool(b["alone"]) else ["* Prendi le chiavi."])


# --- C: NESSUNO SALE DA SOLO -------------------------------------------------------------------------

func _roles_lines() -> Array:
	var roles: Dictionary = d["final_decision"].get("roles", {})
	var lines: Array = ["* La tua proposta, scritta su un foglio:"]
	for r: String in ["conti", "servizi", "turni"]:
		var id := str(roles.get(r, ""))
		lines.append("* %s: %s." % [FINALI.ROLES[r]["name"], _name(id) if id != "" else "nessuno, per ora"])
	if bool(d["boss"]["global_credit_accepted"]):
		lines.append("* In fondo al foglio, stampata, la tua firma sull'attribuzione globale. Qualcuno la indica. Nessuno dice niente. Per ora.")
	elif int(FINALI.turn_state().get("centralized", 0)) >= 2:
		lines.append("* Due bilanci sono passati con la tua firma unica. I rappresentanti chiedono che la prima decisione condivisa sia restituire il loro diritto di intervenire.")
	return lines


func _role(r: String) -> String:
	return str(d["final_decision"].get("roles", {}).get(r, ""))


## Le decisioni del tavolo in C2 (sezione 5): stipendi, servizi, Casa Comune. Solo quelle che si vedono.
func policy_lines() -> Array:
	var out_: Array = []
	if sm["wages_cover"]:
		out_.append("prezzi coperti")
	elif sm["wages_up"]:
		out_.append("metà dei prezzi coperti")
	if sm["services_up"]:
		out_.append("servizi allargati")
	elif sm["services_paid"]:
		out_.append("servizi a pagamento")
	out_.append("Casa Comune " + ("aperta" if RULES.casa_open(str(sm["casa"])) else ("riconvertita" if str(sm["casa"]).begins_with("riconvertita") else "chiusa")))
	return out_


## Fermo nella scena: "umano" (alla cyclette), "robot", "libero", o "" se non l'hai conosciuto.
static func fermo_state() -> String:
	if not FINALI.met("fermo"):
		return ""
	if GameState.is_robot("fermo"):
		return "robot"
	if "fermo" in GameState.freed:
		return "libero"
	return "umano"


func _c2_scene() -> void:
	_clear()
	_floor_strip(Color("231e2a"))
	var turni := _role("turni")
	var fermo := fermo_state()
	var lines: Array = []
	if turni == "fermo":
		lines.append("* Il Fondo. Sopra la cyclette, l'orologio segna la fine del turno. Arriva il cambio, puntuale: è sul foglio dei TURNI di Fermo.")
	else:
		lines.append("* Il Fondo. Sopra la cyclette, l'orologio segna la fine del turno. Arriva %s, puntuale." % _name(turni))
	await Ui.say(lines)
	if turni != "fermo":
		await Ui.say(["Tocca a me."], _name(turni))
	match fermo:
		"umano":
			await Ui.say(["* Fermo scende dalla cyclette. Le gambe tremano un po'. Sale."])
		"robot":
			await Ui.say(["* Chi pedalava scende. Sulla cyclette accanto, Fermo continua a pedalare. Ha l'antenna."])
		"libero":
			await Ui.say(["* Chi pedalava scende. Fermo è venuto da fuori a vedere il cambio."])
		_:
			await Ui.say(["* Chi pedalava scende. Le gambe tremano un po'."])
	_clear()
	_floor_strip(Color("3a2450"))
	var t := TextureRect.new()
	t.texture = load(ART + "tavoli_condivisi.png")
	t.position = Vector2(272, 150)
	t.scale = Vector2(2, 2)
	stage.add_child(t)
	var c: Array = ["* I tavoli condivisi. %s ha il quaderno. %s sposta le sedie." % [_name(_role("conti")), _name(_role("servizi"))],
		"* Su un foglio: le decisioni del tavolo. " + ", ".join(policy_lines()) + "."]
	if int(FINALI.turn_state().get("backlog", 0)) >= RULES.BREAKDOWN_AT:
		c.append("* Sul muro: \"Caldaia: mancano…\". Sotto, alcuni nomi a matita.")
	c.append("* Il tuo fascicolo è sul tavolo. " + debt_lines()[0].trim_prefix("* "))
	if fermo == "umano":
		c.append("* Una sedia vuota. Fermo ci si siede.")
	await Ui.say(c)
	if fermo == "umano":
		await Ui.say(["È la prima volta che mi siedo prima che faccia buio."], "Fermo")


func _c1_scene() -> void:
	var where := "alla Casa Comune" if str(GameState.flags.get("c5_esito", "")) == "comunitaria" else "nella bottega di Rina"
	var nets := RULES.networks()
	var roles: Array = []
	for r: String in ["conti", "servizi", "turni"]:
		roles.append("%s: %s" % [FINALI.ROLES[r]["name"], _name(_role(r)) if _role(r) != "" else "?"])
	await Ui.say(["* La festa c'è, %s. Non ci sono tutti." % where,
		"* Su un foglio: quello che la comunità fa davvero. " + (", ".join(nets) + "." if not nets.is_empty() else "Per ora, il foglio stesso."),
		"* I ruoli: " + ", ".join(roles) + "."])
	match fermo_state():
		"umano":
			await Ui.say(["* Al Fondo, la dinamo gira ancora. Qualcuno scende con un piatto per Fermo."])
			await Ui.say(["Mangio pedalando. Ma oggi qualcuno è sceso."], "Fermo")
			await Ui.say(["* Il piatto torna su vuoto."])
		"robot":
			await Ui.say(["* Al Fondo, la dinamo gira ancora. Qualcuno scende con un piatto per Fermo."])
			await Ui.say(["MANGIARE NON È PREVISTO DAL TURNO."], "Fermo")
		"libero":
			await Ui.say(["* Al Fondo, la cyclette la pedala un'altra persona."])
			await Ui.say(["Sono venuto da fuori. Mi hanno detto che c'erano le sedie."], "Fermo")
		_:
			await Ui.say(["* Al Fondo, la dinamo gira ancora."])


func _c3_scene() -> void:
	var names: Array = []
	for r: String in ["conti", "servizi", "turni"]:
		if _role(r) != "":
			names.append(_name(_role(r)))
	await Ui.say(["* Una stanza con sei sedie. Ne avete portate due.",
		"* Sul foglio dei ruoli: CONTI, SERVIZI, TURNI. " + (", ".join(names) + ", il resto è vuoto." if not names.is_empty() else "Il resto è vuoto."),
		"* Il tuo fascicolo è ancora nella borsa. " + debt_lines()[0].trim_prefix("* ")])
	var who := NIVES
	var b := FINALI.bonds()
	if not b.is_empty():
		who = _name(b[0])
	else:
		for id: String in GameState.freed:
			if FINALI.met(id):
				who = _name(id)
				await Ui.say(["* %s è venuto da fuori." % who])
				break
	await Ui.say(["Domani ne portiamo un'altra."], who)
	await Ui.say(["* Sistemate le due sedie una davanti all'altra. Per ora basta per parlare."])


# --- passi 1-5: sei mesi dopo, piano per piano -------------------------------------------------------

func _tower_to(band: int) -> void:
	var tower := TextureRect.new()
	tower.texture = load(ART + "torre_sezione.png")
	tower.position = Vector2(220, 80 - (band - 1) * 100)
	stage.add_child(tower)
	var tw := create_tween()
	tw.tween_property(tower, "position:y", 80.0 - band * 100.0, 1.2 if not fast else 0.01)
	await tw.finished
	await _wait(0.6)
	_clear()


func epilogue_segment(i: int) -> void:
	var seg: Array = SEGMENTS[i]
	if i == 0:
		Sound.music("epilogo")
		await _fade_title("", "SEI MESI DOPO")
	await _tower_to(int(seg[1]))
	if i == 0:
		# la Torre vista dall'alto: la stampante e i due debiti
		await Ui.say([printer_line(str(sm["debt_rule"]))] + debt_lines())
	_floor_strip(seg[3])
	_label(str(seg[0]), Vector2(0, 16), Vector2(640, 24), 14, GOLD)
	var ids: Array = []
	for id: String in seg[2]:
		if FINALI.met(id):
			ids.append(id)
	for k in ids.size():
		var id: String = ids[k]
		_actor(_sheet(id), 160 + (k + 0.5) * 320.0 / ids.size(), true, GameState.is_robot(id), "idle_down", id)
	if ids.is_empty():
		await Ui.say([_floor_fallback(str(seg[0]))])
	else:
		await Ui.say([_floor_intro(str(seg[0]))])
		for id: String in ids:
			if id in d["epilogue"]["seen_character_ids"]:
				continue
			var r := reaction_for(id)
			if not r.is_empty():
				await Ui.say(r, _name(id))
			var e := epilogue_for(id)
			await Ui.say(e["lines"], str(e.get("speaker", "")))
			(d["epilogue"]["seen_character_ids"] as Array).append(id)
	_clear()


func _floor_intro(title: String) -> String:
	match title:
		"LA CITTÀ":
			var casa := str(sm["casa"]) if str(sm["casa"]) != "" else RULES.casa_after("niente")
			return "* La piazza. " + str({"riconvertita_con_accessi": "Il tornello della Casa Comune ha un cartello: OGGI GRATIS. Anche domani.",
				"riconvertita": "Il tornello della Casa Comune luccica.", "chiusa": "La Casa Comune ha le finestre chiuse."}.get(casa,
				"La Casa Comune ha le finestre aperte."))
		"LA BANCA":
			return "* Lo sportello. " + ("Sulla vetrata, un foglio: PRATICHE SENZA FIRMA SOSPESE." if str(sm["debt_rule"]) == "revisione" \
				else "Il numero sul display è ancora il 4.")
		"IL MERCATO":
			return "* Il tabellone dei prezzi. " + ("Cambia ancora, ma gli stipendi, stavolta, gli corrono dietro." if sm["wages_cover"] \
				else "Cambia ogni minuto. Sempre in su.")
		"IL SOTTOUFFICIO":
			return "* Le pile di moduli. " + ("Più basse di una spanna. Qualcuno ha misurato." if str(out.get("family", "")) == "C" or str(sm["debt_rule"]) == "revisione" \
				else "Alte come sempre.")
	return "* La festa. " + ("La dinamo gira più piano. Le luci tengono lo stesso." if sm["maintenance_ok"] else "Le luci sfarfallano. Si pedala di più.")


static func _floor_fallback(title: String) -> String:
	match title:
		"LA CITTÀ":
			return "* La piazza è piena di gente che non conosci. Va avanti benissimo anche senza di te. È normale. È anche un po' strano."
		"LA BANCA":
			return "* Allo sportello, facce che non hai mai visto. Il display chiama un numero. Non è il tuo."
		"IL MERCATO":
			return "* Al Mercato le casse battono scontrini. Nessuno ti saluta: non c'era nessuno da salutare."
		"IL SOTTOUFFICIO":
			return "* Al -4 i moduli continuano. Nessuno ti ricorda: non ti eri fermato a farti ricordare."
	return "* Al Fondo la festa continua. Ci sono persone che non hai mai guardato. Pedalano."


## Prima dell'epilogo, il ricordo di un torto (e di un aiuto o di una riparazione), se c'è.
func reaction_for(id: String) -> Array:
	var fam := str(out.get("family", ""))
	var var_ := str(out.get("variant", ""))
	return Storia.reazione(id, FINALI.in_force(fam, var_), bool(sm["wages_up"]), var_ == "C2" and _role("turni") != "")


## L'epilogo di una persona: righe coerenti col suo stato (robot, liberata, aiutata) e con le scelte finali.
func epilogue_for(id: String) -> Dictionary:
	var nm := _name(id)
	var fam := str(out.get("family", ""))
	var robot := GameState.is_robot(id)
	var helped: bool = id in GameState.helped_ids
	var f := GameState.flags
	if id in GameState.freed and not robot:
		return {"lines": ["* %s non lavora più qui. Passa ogni tanto, per salutare chi è rimasto." % nm]}
	match id:
		"ada":
			if robot:
				return {"lines": ["* Ada sistema le sedie della sala. Sempre nello stesso ordine.", "ARREDAMENTO OTTIMIZZATO."], "speaker": ""}
			if RULES.casa_open(str(sm["casa"])):
				return {"lines": ["Mi dai una mano?", "Aspetta.", "Forse dovrei imparare a sistemarla da sola."], "speaker": "Ada"}
			return {"lines": ["* Ada studia al tavolo di una cucina non sua. Il vecchio avviso di chiusura è attaccato al frigo.",
				"Per ricordarmi da dove vengo. E dove non voglio tornare."], "speaker": "Ada"}
		"nadir":
			if robot:
				return {"lines": ["PERCORSO OTTIMIZZATO. ARRIVO PREVISTO: SEMPRE."]}
			if sm["services_up"]:
				return {"lines": ["Il bus arriva in orario, adesso.", "Ho sette minuti in più ogni mattina.", "Li passo a guardare un merlo. Ha un nome. Non te lo dico."], "speaker": "Nadir"}
			if f.get("c5_nadir_rete", false):
				return {"lines": ["La rete dei pendolari ha un gruppo. Si chiama \"Sei minuti\".", "È sempre in ritardo anche lui."], "speaker": "Nadir"}
			return {"lines": ["* Nadir aspetta alla fermata. Il tabellone dice sei minuti. Lui non ci crede più, e aspetta lo stesso."]}
		"rina":
			if f.get("c5_vetrina_aiuto", false):
				return {"lines": ["La vetrina nuova è uguale a quella vecchia.", "Il cartone l'ho tenuto. Non si sa mai."], "speaker": "Rina"}
			return {"lines": ["* La bottega di Rina ha una saracinesca nuova. Più robusta. Più cara. Rina la guarda come si guarda un debito."]}
		"olga":
			if str(sm["debt_rule"]) in ["revisione", "interessi"]:
				return {"lines": ["Ho ricevuto un'altra lettera.", "Questa volta non mi chiedevano soldi.", "L'ho incorniciata."], "speaker": "Olga"}
			if f.get("c4_olga_risposta", false):
				return {"lines": ["* La risposta alla contestazione è ancora sul frigo di Olga. Una lettera vera. Rara."]}
			return {"lines": ["* Olga legge un estratto conto con la lente. Poi con due lenti."]}
		"teo":
			if robot:
				return {"lines": ["* Teo timbra. Il quaderno di fumetti è ancora nel cassetto della scrivania. Incompleto."]}
			if f.get("c4_teo_sogno", false) and (sm["wages_up"] or fam == "C" or str(sm["debt_rule"]) == "revisione"):
				var lines: Array = ["* Teo ha in mano un fascicolo spillato. In copertina, un supereroe con una borsetta.", "TEO: È il primo numero."]
				if FINALI.met("olga") and not GameState.is_robot("olga"):
					lines.append_array(["OLGA: È meglio del secondo.", "TEO: Non l'ho ancora disegnato!", "OLGA: Appunto."])
				return {"lines": lines}
			return {"lines": ["* Teo controlla pratiche. Di sera disegna. Poco. Ma disegna."]}
		"leda":
			if robot:
				return {"lines": ["SCAFFALE RIFORNITO. CLIENTE SERVITO. PREZZO AGGIORNATO."]}
			if sm["wages_cover"]:
				return {"lines": ["Ho chiuso il mese in pari.", "Non mi era mai successo. Ho dovuto ricontare tre volte."], "speaker": "Leda"}
			if f.get("c3_leda_ordini", false):
				return {"lines": ["Gli ordini condivisi adesso sono undici famiglie.", "La dodicesima chiede sempre lo sconto."], "speaker": "Leda"}
			if helped:
				return {"lines": ["Mi hai dato una mano. Lo so.", "Ma domani arriva un'altra fattura."], "speaker": "Leda"}
			return {"lines": ["* Leda conta gli scontrini della giornata. Li conta due volte."]}
		"amir":
			if robot:
				return {"lines": ["CONSEGNA COMPLETATA.", "CLIENTE SODDISFATTO."]}
			if f.get("c3_amir_sogno", false) and (sm["wages_cover"] or fam == "C" or RULES.casa_open(str(sm["casa"]))):
				return {"lines": ["* Amir ha un fornello in un angolo della Casa Comune. Due tavoli, sei sedie spaiate.", "Vuoi assaggiare?",
					"Avevo detto che ero bravo."], "speaker": "Amir"}
			return {"lines": ["* Amir fa ancora le consegne. Nella borsa termica, sotto i pacchi, un quaderno di ricette."]}
		"tilde":
			if robot:
				return {"lines": ["MODULO COMPILATO. MODULO SUCCESSIVO."]}
			if fam == "C" or str(sm["debt_rule"]) == "revisione":
				return {"lines": ["* Al -4 hanno tolto metà dei timbri. Tilde ne ha tenuto uno, per ricordo.",
					"Le procedure sono cambiate. Mi sento quasi disoccupata. Di moduli."], "speaker": "Tilde"}
			return {"lines": ["Ho inventato un modulo nuovo.", "Serve a chiedere di eliminare i moduli inutili.", "È di quarantadue pagine."], "speaker": "Tilde"}
		"ercole":
			if robot:
				return {"lines": ["SONNO NON PREVISTO. SONNO RIMOSSO."]}
			return {"lines": ["* Ercole dorme alla scrivania. Ma adesso c'è un cuscino. Qualcuno ce l'ha messo." if helped else "* Ercole timbra, sbadiglia, timbra."]}
		"fermo":
			if robot:
				return {"lines": ["LA FESTA È OBBLIGATORIA. DIVERTITEVI."]}
			return {"lines": ["* Fermo organizza ancora la festa. Adesso, ogni tanto, la festa è vera." if sm["wages_up"] or fam == "C" \
				else "* Fermo organizza ancora la festa. Sorride per tutti. Qualcuno, adesso, sorride anche per lui."]}
	# Mina e Bulbo (al Fondo): la frase del calendario solo a chi lavora ancora
	if robot:
		return {"lines": ["DINAMO IN FUNZIONE. ENERGIA GARANTITA."]}
	if id == "bulbo":
		return {"lines": ["Quando ero giovane pensavo che a quest'età avrei avuto un sacco di tempo libero.", "Devo aver sbagliato calendario."], "speaker": nm}
	return {"lines": ["* %s cambia una lampadina. Poi un'altra. Al Fondo le lampadine durano poco, e lui di più." % nm]}


# --- passo 6: Nives ----------------------------------------------------------------------------------

func nives_scene() -> void:
	await _tower_to(0)
	_floor_strip(Color("3a2450"))
	_label("NIVES", Vector2(0, 16), Vector2(640, 24), 14, GOLD)
	_actor("char_13", 320, true)
	var fam := str(out.get("family", ""))
	match fam:
		"A":
			await Ui.say(["* Nives è al banco dei badge. Da quando la Torre ha un responsabile solo, ne vende di più."])
		"C":
			await Ui.say(["* Nives ha una sedia al tavolo condiviso. Non sa ancora cosa firma. Lo chiede, ogni volta."] if str(out.get("variant", "")) == "C2" \
				else ["* Nives è al banco dei badge. Il martedì sera va alle riunioni. Dice che ci va per il caffè."])
		_:
			await Ui.say(["* Nives è al banco dei badge. Come sempre. Quasi."])
	await Ui.say(["Sai…", "Per anni ho pensato che il mio lavoro fosse aprire le porte.", "Poi ho cominciato a chiedermi perché fossero chiuse."], NIVES)
	# dalla seconda partita conclusa in poi
	await MemoriaNives.epilogue(out)
	(d["epilogue"]["seen_character_ids"] as Array).append("nives")
	_clear()


# --- passo 7: il sogno -------------------------------------------------------------------------------

func dream_scene() -> void:
	Sound.music("")
	_clear()
	bg.color = Color.BLACK
	await _wait(1.0)
	var c: int = await Ui.choose("Prima di arrivare qui, cosa volevi fare?", DREAMS)
	d["dream"]["selected"] = DREAM_IDS[c]
	await Ui.say([dream_line(DREAM_IDS[c], str(out.get("family", "")))])
	d["dream"]["final_scene_seen"] = true


## La scena personale: cambia solo questa. Il sogno non cambia il finale.
static func dream_line(dream: String, family: String) -> String:
	var when: String = {"A": "Tra una decisione e l'altra, la sera tardi.", "B": "Domani mattina. Senza fretta.", "C": "Dopo la riunione. Che è stata terribile."}.get(family, "Domani.")
	match dream:
		"creare":
			return "* %s Un foglio bianco. La prima riga di qualcosa. Non sai ancora cosa. Va bene così." % when
		"studiare":
			return "* %s Un libro preso in prestito. \"Restituzione: quando puoi.\"" % when
		"viaggiare":
			return "* %s Un biglietto per un posto senza torri. Solo andata, per ora." % when
		"qualcuno":
			return "* %s Un messaggio: \"Ci sei stasera?\". Rispondi subito. Non hai turni." % when
		"tempo":
			return "* %s Un pomeriggio intero, senza un prezzo. Non sai cosa farci. Lo impari." % when
	return "* %s Non lo sai ancora. Per la prima volta, nessuno te lo chiede entro le nove." % when


# --- passo 8: i titoli di coda -----------------------------------------------------------------------

func _credits() -> void:
	_clear()
	bg.color = Color.BLACK
	Sound.music("epilogo")
	var title := _label("CHEAP", Vector2(0, 120), Vector2(640, 50), 36, GOLD)
	var sub := _label("Quanto costa una vita?", Vector2(0, 176), Vector2(640, 30), 15, Color.WHITE)
	title.modulate.a = 0.0
	sub.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(title, "modulate:a", 1.0, 1.2 if not fast else 0.01)
	tw.tween_property(sub, "modulate:a", 1.0, 1.2 if not fast else 0.01)
	await tw.finished
	await _wait(3.0)
	_clear()
	var fine := _label("FINE", Vector2(0, 150), Vector2(640, 50), 30, Color.WHITE)
	await _wait(3.0)
	fine.queue_free()
	var credits := [
		"CHEAP", "",
		"Un gioco di Linda", "",
		"Storia, personaggi e direzione", "Linda", "",
		"Grafica dei personaggi e degli ambienti", "LimeZu — Modern Interiors, Modern Exteriors", "",
		"Comparse", "LimeZu — Modern Interiors, versione RPG Maker", "",
		"Carattere", "Pixeloid Sans — GGBotNet (SIL Open Font License)", "",
		"Grafica personalizzata", "segnaposto, in attesa dei disegni veri", "",
		"Motore", "Godot Engine", "",
		"%s, da %s di debito." % [GameState.player_name, GameState.euros(GameState.START_DEBT)],
		"Grazie per essere salito. E per esserti voltato.",
	]
	var roll := _label("\n".join(credits), Vector2(80, 380), Vector2(480, 640), 13, Color.WHITE)
	roll.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var r := create_tween()
	r.tween_property(roll, "position:y", -660.0, 24.0 if not fast else 0.05)
	await r.finished
	Ui.cutscene = false
	Ui.show_hud(true)
	Router.goto(MENU)
