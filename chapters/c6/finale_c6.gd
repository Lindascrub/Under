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
	sm = RULES.summary(FINALI.turn_state())
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
			pres.queue_free()
			Sound.sfx("door")
			await Ui.say(["* La Presidente lascia l'ufficio. Non si volta."])
			if var_ == "A2":
				_actor("char_13", 420, true, false, "idle_left")
				await Ui.say(["* Più tardi entra Nives. Ha un badge in mano, per abitudine."])
				await Ui.say(["Posso chiederti una cosa?", "Quando non ci sarai più…", "Chi deciderà al posto tuo?"], NIVES)
			else:
				await Ui.say(["IL TUO TEMPO È ORA COMPLETAMENTE TUO!"], VOICE)
				await Ui.say(["HAI 137 DECISIONI IN ATTESA."], VOICE)
				Sound.sfx("drring")
				await Ui.say(["* Il telefono squilla."])
		"B":
			await Ui.say(["Davvero non vuoi restare?"], PRES)
			await Ui.choose("Cosa rispondi?", ["Ho già lavorato abbastanza.", "Voglio fare qualcos'altro.", "Non voglio decidere per tutti."], PRES)
			await Ui.say(["Capisco.", "Vorrei poterti dire che fuori sarà tutto più semplice."], PRES)
			_clear()
			_floor_strip(Color("2c3a4a"))
			_actor(PLAYER_SHEET, 300, false, false, "idle_right")
			await Ui.say(["* La stazione. Un binario, un tabellone che per una volta non dice PREMIUM."])
			await Ui.say(_departure_lines())
			if var_ == "B2":
				var c: int = await Ui.choose("COSA VUOI FARE DOMANI?", ["Dormire fino a tardi.", _visit_option(), "Quella cosa che volevo fare prima di salire."])
				await Ui.say([["* Domani dormi. Fino a tardi. Nessuno ti chiama.", _visit_line(), "* Domani ricominci da quella cosa. Piano. Senza un badge."][c]])
		_:
			await Ui.say(["Quindi…", "Vorresti che le persone che lavorano qui decidessero anche come funziona il posto?", "Interessante.",
				"Le riunioni saranno terribili."], PRES)
			await Ui.say(_roles_lines())
			match var_:
				"C2":
					_clear()
					_floor_strip(Color("3a2450"))
					var t := TextureRect.new()
					t.texture = load(ART + "tavoli_condivisi.png")
					t.position = Vector2(272, 150)
					t.scale = Vector2(2, 2)
					stage.add_child(t)
					await Ui.say(["* Nel corso dei mesi la vecchia scrivania viene smontata. Al suo posto, tavoli condivisi."])
					_actor("char_13", 200, true)
					await Ui.say(["Quindi adesso chi firma?"], NIVES)
					if FINALI.bonded("teo") and not GameState.is_robot("teo"):
						_actor(_sheet("teo"), 440, true, false, "idle_down", "teo")
						await Ui.say(["Dipende da cosa dobbiamo firmare."], "Teo")
					else:
						await Ui.say(["* Qualcuno, dal fondo: \"Dipende da cosa dobbiamo firmare.\""])
					await Ui.say(["Sapevo che sarebbe diventato complicato."], NIVES)
				"C3":
					await Ui.say(["* L'assemblea si fa. Nell'ufficio enorme, per una volta, le sedie non bastano.",
						"* Si parla per ore. Non si raggiunge un accordo generale."])
					await Ui.say(["Non avete deciso."], PRES)
					_actor("char_13", 200, true)
					await Ui.say(["Non ancora."], NIVES)
				_:
					await Ui.say(["* Nasce un progetto: piccolo, indipendente, in un piano che nessuno usava. La Torre continua a funzionare, lì accanto.",
						"* Chi entra, decide. Chi decide, poi pulisce."])
					if FINALI.met("leda") and not GameState.is_robot("leda"):
						_actor(_sheet("leda"), 440, true, false, "idle_down", "leda")
						await Ui.say(["Non saprei.", "Però oggi qualcuno mi ha aiutato a chiudere il negozio."], "Leda")
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


## B: cosa ti porti alla stazione (soldi, prove, persone vere) e cosa succede al debito.
func _departure_lines() -> Array:
	var lines: Array = ["* In tasca: %s." % GameState.euros(GameState.money)]
	var ev := RULES.evidence()
	if str(out.get("debt_status", "")) == "contestato":
		lines.append("* Nella borsa: " + ", ".join(ev) + ".")
		lines.append("* All'ufficio reclami della stazione c'è un modulo: CONTESTAZIONE DI QUOTA NON FIRMATA. Lo compili con le prove.")
		lines.append("* La pratica è aperta. Il debito resta, sospeso fino alla risposta. Per la prima volta, la risposta la deve qualcun altro.")
	else:
		lines.append("* Il debito viene con te: %s. Senza prove da allegare, non c'è niente da contestare. Per ora." % GameState.euros(GameState.debt))
	var b := FINALI.bonds()
	if not b.is_empty():
		var names: Array = []
		for id: String in b:
			names.append(_name(id))
		lines.append("* Sul telefono, qualche numero nuovo: " + ", ".join(names) + ".")
	return lines


func _visit_option() -> String:
	var b := FINALI.bonds()
	return "Passare da %s." % _name(b[0]) if not b.is_empty() else "Passare dalla Casa Comune."


func _visit_line() -> String:
	var b := FINALI.bonds()
	return "* Domani passi da %s. Senza un motivo. È il motivo." % _name(b[0]) if not b.is_empty() else "* Domani passi dalla Casa Comune. Senza un motivo."


func _roles_lines() -> Array:
	var roles: Dictionary = d["final_decision"].get("roles", {})
	var lines: Array = ["* La tua proposta, scritta su un foglio:"]
	for r: String in ["conti", "servizi", "turni"]:
		var id := str(roles.get(r, ""))
		lines.append("* %s: %s." % [FINALI.ROLES[r]["name"], _name(id) if id != "" else "nessuno, per ora"])
	if bool(d["boss"]["global_credit_accepted"]):
		lines.append("* In fondo al foglio, stampata, la tua firma sull'attribuzione globale. Qualcuno la indica. Nessuno dice niente. Per ora.")
	return lines


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
	# Nonno Mina e Bulbo (al Fondo): la frase del calendario solo a chi lavora ancora
	if robot:
		return {"lines": ["DINAMO IN FUNZIONE. ENERGIA GARANTITA."]}
	if nm == "Nonno Mina":
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
