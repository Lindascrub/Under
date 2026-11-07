extends Node2D

const B := preload("res://scripts/boss_missions.gd")
## Capitolo 6 — il TURNO di Direzione: uno schermo, un turno solo.
## Non c'è uno stipendio: si dividono 100 unità fra stipendi, servizi, manutenzione e riserve,
## poi si decide della Casa Comune, poi della regola dei debiti. Tutto nello stesso turno.
## Le regole sono in direzione_regole.gd; la scena fisica è in direzione_tavolo.tscn.
## Qui restano il flusso narrativo e l'applicazione del turno.
## Alla fine lo stato comune va in GameState.flags["chapter_6"]["director_turn"] (i tre "cycle_N_completed"
## diventano veri insieme), poi si torna alla Cima.

const RULES := preload("res://chapters/c6/direzione_regole.gd")
const CIMA := "res://chapters/c6/cima.tscn"
const PRES := "La Presidente"
const VOICE := "Voce CHEAP"


var cycle := 1
var st: Dictionary = {}
var alloc: Dictionary = {}
## "alloc" (si dividono le unità), "casa" (la Casa Comune), "debiti" (la regola dei debiti), "done"
var phase := "intro"
var msg := ""
var options: Array = []
var choice_id := ""
## La scelta sulla Casa Comune, tenuta da parte finché non si decide anche dei debiti.
var casa_id := ""
var visuale: Node
const TAVOLO := preload("res://chapters/c6/direzione_tavolo.tscn")


func _ready() -> void:
	cycle = 1
	var dt := _dt()
	if dt.get("cycle_3_completed", false):
		# già fatto (un caricamento, un tocco di troppo): niente doppioni
		Router.goto(CIMA, "desk")
		return
	st = (dt.get("state", {}) as Dictionary).duplicate(true)
	if st.is_empty():
		st = RULES.new_state()
	st["cycle"] = cycle
	alloc = RULES.start_alloc(st)
	var draft: Dictionary = dt.get("draft", {})
	if int(draft.get("cycle", 0)) != cycle: draft = {}
	if int(draft.get("cycle", 0)) == cycle:
		alloc = draft.get("alloc", alloc).duplicate(true)
	st["mandate"] = str(draft.get("mandate", ""))
	casa_id = str(draft.get("casa_id", ""))
	visuale = TAVOLO.instantiate()
	add_child(visuale)
	visuale.richiesta.connect(_richiesta_tavolo)
	Ui.show_hud(false)
	Sound.music("cima")
	queue_redraw()
	await get_tree().process_frame
	if str(draft.get("phase", "alloc")) not in ["casa", "debiti"]: await _intro()
	phase = str(draft.get("phase", "alloc"))
	if phase not in ["alloc", "casa", "debiti"]: phase = "alloc"
	if phase == "casa": options = RULES.casa_options(st, alloc)
	elif phase == "debiti":
		var after := st.duplicate(true)
		RULES.apply_casa(after, casa_id)
		options = RULES.debt_options(after, alloc)
	_sync_view()
	queue_redraw()


func _dt() -> Dictionary:
	var c6: Dictionary = GameState.flags.get("chapter_6", {})
	if not c6.has("director_turn"):
		c6["director_turn"] = {}
	GameState.flags["chapter_6"] = c6
	return c6["director_turn"]


## Cosa c'è sul tavolo: 1 i soldi (con le spese già annunciate), 2 la Casa Comune, 3 i debiti.
func situation(part := 1) -> Array:
	var out: Array = []
	match part:
		1:
			out = ["I lavoratori chiedono un aumento.", "La manutenzione richiede fondi.", "E naturalmente dobbiamo mantenere delle riserve."]
		2:
			out = ["La Casa Comune, i trasporti, gli sportelli: chi li paga, chi li usa, chi li decide."]
			match RULES.casa_state():
				"riconversione":
					out.append("La Casa Comune è un centro CHEAP, con il tornello. Si può comprare l'accesso, o rinegoziare.")
				"comunitaria":
					out.append("La Casa Comune la gestisce chi la usa. Si può darle risorse, o lasciarla fare da sola.")
				_:
					out.append("La Casa Comune è sospesa: la chiusura è stata rinviata. Si può prorogare, o proporre un altro modello.")
		3:
			out = ["Il debito di tutti: le regole con cui la Torre si paga il futuro."]
	var d := RULES.due(st) if part == 1 else 0
	if d > 0:
		out.append("Da pagare in questo ciclo: %d (%s)." % [d, "la bolletta della dinamo" if cycle == 2 and not st.get("bill_paid", false) else "il guasto annunciato"])
	return out


func _intro() -> void:
	phase = "intro"
	if B.uses("cima") and not _dt().get("boss_brief_1", false):
		_dt()["boss_brief_1"] = true
		_save_draft()
		await Ui.say(["OTTIMIZZAZIONE FINALE.",
			"Il bilancio deve tornare. Puoi far pagare cinque unità a chi usa i servizi. Le chiami tariffe, non tagli.", "È tutto molto semplice!"], "Il Capo")
	await Ui.say(situation(1), PRES)
	if not _dt().get("rules_seen", false):
		_dt()["rules_seen"] = true
		await Ui.say(["* Sposta i gettoni fra le quattro destinazioni. Guarda che cosa cambia prima di proseguire.",
			"* GETTONE cambia la quantità: 5 oppure 1. DETTAGLI apre tutti i conti. Dopo scegli la Casa Comune e i debiti."], PRES)


# Le aree e il disegno sono nella scena del tavolo, senza duplicare i conti.
func minus_button(i: int) -> Rect2:
	return visuale.minus_button(i)
func plus_button(i: int) -> Rect2:
	return visuale.plus_button(i)
func confirm_button() -> Rect2:
	return visuale.rett("Conferma")
func rules_button() -> Rect2:
	return visuale.rett("Regole")
func option_button(i: int) -> Rect2:
	return visuale.option_button(i)
func _sync_view() -> void:
	if visuale == null: return
	var view_state := st.duplicate(true)
	if phase == "debiti": RULES.apply_casa(view_state, casa_id)
	visuale.aggiorna(view_state, alloc, phase, options, msg)
func _draw() -> void:
	_sync_view()
func touch_scheme() -> String:
	return "point" if phase in ["alloc", "casa", "debiti"] else ""
func touch_center() -> Vector2:
	return Vector2(320, 180)
func touch_point(pos: Vector2, step: int) -> void:
	if Ui.busy or phase not in ["alloc", "casa", "debiti"]: return
	visuale.punta(pos, step)
func _unhandled_input(event: InputEvent) -> void:
	if Ui.busy or phase not in ["alloc", "casa", "debiti"]: return
	if not TouchControls.enabled:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			touch_point(event.position, 0 if event.pressed else 2); return
		if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			touch_point(event.position, 1); return
	visuale.tastiera(event)
func _richiesta_tavolo(azione: String, dati: Dictionary) -> void:
	if Ui.busy or phase not in ["alloc", "casa", "debiti"]: return
	match azione:
		"nudge": _nudge(int(dati.index), int(dati.dir), int(dati.amount))
		"transfer":
			if phase != "alloc": return
			var before := alloc.duplicate()
			alloc = RULES.transfer(st, alloc, int(dati.from), int(dati.to), int(dati.amount))
			msg = "" if before != alloc else "Nessuna unità disponibile: controlla i contratti e lo spazio rimasto."
			if before != alloc:
				var quanti := int(before[RULES.CATS[int(dati.from)]]) - int(alloc[RULES.CATS[int(dati.from)]]) if int(dati.from) >= 0 else int(alloc[RULES.CATS[int(dati.to)]]) - int(before[RULES.CATS[int(dati.to)]])
				visuale.anima(int(dati.from), int(dati.to), quanti)
			Sound.sfx("blip" if msg == "" else "deny")
			_save_draft()
		"regole": _show_rules()
		"conferma":
			if phase == "alloc": _confirm()
		"select_option":
			msg = ""
		"scegli":
			if phase in ["casa", "debiti"]: _pick(visuale.scelta)
		"esci":
			_save_draft()
			phase = "leaving"
			Router.goto(CIMA, "desk")
	_sync_view()
	queue_redraw()

func _nudge(i: int, d: int, amount := 5) -> void:
	var c: String = RULES.CATS[i]
	var before := int(alloc[c])
	alloc = RULES.allocate(st, alloc, c, before + d * amount)
	if int(alloc[c]) == before:
		if d > 0:
			msg = "Togline da un'altra destinazione: sul tavolo non restano unità." if RULES.total(alloc) >= RULES.TOTAL else "Questa destinazione è già al massimo di 60."
		else:
			msg = "Gli stipendi non scendono sotto %d." % RULES.minimum(st, c) if c == "stipendi" else "Questa destinazione è già vuota."
		Sound.sfx("deny")
	else:
		msg = ""
		Sound.sfx("blip", 1.0 + 0.05 * d)
	_save_draft()
	queue_redraw()


func _show_rules() -> void:
	await Ui.say(["STIPENDI: sotto 30 non si coprono i contratti. Un aumento è per sempre. Al -3 i prezzi sono saliti di un terzo: con 55 l'aumento li copre.",
		"SERVIZI: sotto 15 diventano a pagamento, da 25 si allargano. Più persone li usano, più si consumano: +5 alla manutenzione che serve dopo.",
		"MANUTENZIONE: servono 25 unità. Quello che manca diventa lavoro arretrato. Con 10 di arretrato è previsto un guasto dopo questa prova.",
		"RISERVE: restano in cassa. Coprono le spese annunciate. Quando non bastano, si prende dai servizi."])


func _confirm() -> void:
	if phase != "alloc" or Ui.busy: return
	var bad := RULES.invalid(st, alloc)
	if bad != "":
		msg = bad
		Sound.sfx("deny")
		queue_redraw()
		return
	if B.uses("cima"):
		phase = "mandate"
		await Ui.say(["Prima della conferma scegli chi sostiene i costi e chi partecipa. Il bilancio resta di cento unità."], "La Presidente")
		var mode: int = await Ui.choose_described("Chi paga e chi decide?", [
			["Mantieni le tutele", "Rispetti i minimi per stipendi e servizi. Nessuna tariffa aggiunta ai lavoratori."],
			["Tariffe ai lavoratori", "Le riserve ricevono 5 unità. A pagarle sono i lavoratori."],
			["Firma unica", "Sposti 5 dai servizi alle riserve. Decidi senza i rappresentanti."],
			["Decisione con i rappresentanti", "I rappresentanti partecipano prima dell'applicazione. Coordinarsi costa 5 unità."]])
		st["mandate"] = ["tutele", "tariffe", "accentrata", "condivisa"][mode]
		var issue := RULES.invalid(st, alloc)
		if issue != "":
			msg = issue
			st["mandate"] = ""
			phase = "alloc"
			queue_redraw()
			return
		await Ui.say(RULES.hints(st, alloc))
		if mode == 3:
			await Ui.say(["Non possiamo fissare i turni senza sapere chi accompagna i bambini. I rappresentanti portano gli orari, noi dobbiamo rispettare il bilancio.", "La consultazione non crea soldi. Cambia chi può contestare una decisione prima che venga applicata."], "Rappresentante dei servizi")
		var accept: int = await Ui.choose("Applica questo bilancio e questo mandato?", ["Conferma", "Rivedi il bilancio"])
		if accept != 0:
			st["mandate"] = ""; phase = "alloc"; queue_redraw(); return
	Sound.sfx("stamp")
	# i soldi sono divisi: adesso la Casa Comune
	phase = "intro"
	await Ui.say(situation(2), PRES)
	options = RULES.casa_options(st, alloc)
	phase = "casa"
	visuale.scelta = 0
	_save_draft()
	msg = ""
	queue_redraw()


func _pick(i: int) -> void:
	if phase not in ["casa", "debiti"] or Ui.busy or i < 0 or i >= options.size(): return
	var o: Array = options[i]
	var closed := str(o[o.size() - 1])
	if closed != "":
		msg = closed
		Sound.sfx("deny")
		queue_redraw()
		return
	Sound.sfx("stamp")
	if phase == "casa":
		# la Casa è decisa: adesso la regola dei debiti, con le riserve che restano dopo la Casa
		casa_id = str(o[0])
		phase = "intro"
		queue_redraw()
		var after := st.duplicate(true)
		RULES.apply_casa(after, casa_id)
		await Ui.say(situation(3), PRES)
		await Ui.say(["ATTENZIONE.", "La stabilità economica è importante.", "Soprattutto per chi è già stabile."], VOICE)
		options = RULES.debt_options(after, alloc)
		phase = "debiti"
		visuale.scelta = 0
		_save_draft()
		msg = ""
		queue_redraw()
		return
	choice_id = str(o[0])
	await _finish()


## Il turno è deciso: lo stato comune si aggiorna una volta, si salva, e si torna alla Cima.
func _finish() -> void:
	if phase == "done":
		return
	phase = "done"
	queue_redraw()
	var lines := RULES.apply(st, alloc)
	RULES.apply_casa(st, casa_id)
	lines.append("La Casa Comune: " + _casa_text(str(st["casa"])))
	st["debt_rule"] = choice_id
	# per il finale A1: "Conserva" scelto mentre almeno un'altra regola era aperta (una scelta, non un obbligo)
	st["debt_other_open"] = options.any(func(o: Array) -> bool: return str(o[0]) != "conservare" and str(o[o.size() - 1]) == "")
	lines.append("La regola dei debiti: " + _debt_text(choice_id))
	var dt := _dt()
	dt["state"] = st
	for n in range(1, 4):
		dt["cycle_%d_completed" % n] = true
	var decisions: Array = dt.get("decisions", [])
	decisions.append({"cycle": cycle, "alloc": alloc.duplicate(), "casa": casa_id, "choice": choice_id})
	dt["decisions"] = decisions
	dt["pending"] = 3
	dt.erase("draft")
	GameState.save_game(CIMA, Vector2(520, 158))
	await Ui.say(lines)
	Router.goto(CIMA, "desk")


static func _casa_text(c: String) -> String:
	match c:
		"riconvertita_con_accessi":
			return "resta un centro CHEAP, ma con accessi gratuiti pagati dalla Torre."
		"contratto_rinegoziato":
			return "il contratto torna al canone vecchio. Si riapre, con i conti in mano."
		"comunitaria_sostenuta":
			return "la gestiscono loro, con risorse della Torre."
		"comunitaria_autonoma":
			return "la gestiscono loro, da soli. Nessuno controlla, nessuno paga."
		"prorogata":
			return "la chiusura è rinviata di un anno. Pagato dalle riserve."
		"nuovo_modello":
			return "si riapre come l'aveva organizzata Ada: studio, laboratorio, incontri."
		"riconvertita":
			return "resta un centro CHEAP. Con il tornello."
	return "chiude. Nessuno ha deciso niente: è bastato."


static func _debt_text(c: String) -> String:
	match c:
		"interessi":
			return "interessi ridotti allo 0,5% a notte."
		"revisione":
			return "i debiti senza firma sono sospesi e in revisione."
		"alternative":
			return "le reti che già funzionano pagano una parte dei servizi."
	return "tutto come prima."


func _save_draft() -> void:
	if phase == "done": return
	if B.uses("cima"):
		_dt()["draft"] = {"cycle": cycle, "alloc": alloc.duplicate(true), "phase": phase, "casa_id": casa_id, "mandate": str(st.get("mandate", ""))}
		GameState.save_game(CIMA, Vector2(520, 158))

