extends Node
## Stato della partita: soldi, debito, ora del giorno, energia, oggetti e scelte morali.
## Si sale la torre un piano alla volta: per passare al piano di sopra serve il suo badge,
## che si compra pagando una parte del debito (vedi FLOORS). I giorni non sono contati:
## il tempo passa, e ogni notte il debito cresce un po'.
## I finali li sceglie chapters/c6/finali.gd.

signal changed

const SAVE_PATH := "user://cheap_save.json"
## Dove si salva: i test usano un file a parte, per non toccare la partita vera.
var save_path := SAVE_PATH
const START_DEBT := 7_000_000_000
const DAILY_INTEREST := 0.02
const MIN_PAYMENT := 150
const MAX_ENERGY := 20
## La giornata va dalle 7:00 a mezzanotte. Il tempo è in minuti dall'inizio del giorno.
const DAY_START := 7 * 60
const MIDNIGHT := 24 * 60

## Da quest'ora le persone seguono gli orari serali (campo "evening" in npcs.json).
const EVENING := 18 * 60
## Quanto costano le azioni, in minuti.
const COST_EASY_JOB := 60
const COST_HARD_JOB := 10 * 60
const COST_LISTEN := 60
const COST_HELP_TIME := 60
const COST_REST := 60
const COST_WALK := 10

const RANKS: Array[String] = [
	"Stagista", "Impiegato", "Supervisore", "Responsabile", "Manager",
	"Direttore", "Amministratore Delegato", "Presidente",
]
const DAY_NAMES: Array[String] = ["Lun", "Mar", "Mer", "Gio", "Ven", "Sab", "Dom"]

## Quello che dicono le persone sostituite da robot. Sempre gentili, sempre uguali.
const ROBOT_LINES: Array[String] = [
	"Buongiorno, {rank}.",
	"Ottimo lavoro, {rank}. Il suo successo è il nostro successo.",
	"Tutto procede secondo i parametri.",
	"Le auguro una giornata produttiva, {rank}.",
	"Sono molto felice. Grazie per avermelo chiesto.",
]

const ITEMS := {
	"Panino": {"energy": 12, "text": "* Mangi il panino. Un po' schiacciato, ma buono."},
	"Barretta": {"energy": 5, "text": "* Mangi la barretta. Sa di cartone al cioccolato."},
	"Acqua economica": {"energy": 3, "text": "* Bevi l'acqua economica. Sa di plastica e di niente. Però era bagnata."},
	"Biscotti di Leda": {"energy": 6, "text": "* Mangi i biscotti di Leda. Scadevano domani. Oggi sono ancora buoni."},
}

## Dal piano più profondo alla cima. "badge" è quanto costa il badge per salire a quel piano.
const FLOORS: Array[Dictionary] = [
	{"id": "-5", "name": "Piano -5", "badge": 0},
	{"id": "-4", "name": "Piano -4", "badge": 500},
	{"id": "-3", "name": "Piano -3", "badge": 1000},
	{"id": "-2", "name": "Piano -2", "badge": 2000},
	{"id": "0", "name": "Piano terra", "badge": 4000},
	{"id": "cima", "name": "La Cima", "badge": 8000},
]

var day := 1
var minutes := DAY_START
## Il piano in cui ti trovi adesso (lo imposta ogni stanza) e i badge che hai già.
var floor_id := "-5"
var badges: Array[String] = []
## Il piano della stanza in cui sei adesso ("" in città: strada, parco, casa).
var room_floor := ""
## L'autostima: sale ogni volta che aiuti qualcuno (e quando un piano intero ti vuole bene).
var self_esteem := 0
## Come si chiama il giocatore (lo chiede il menu quando si comincia).
var player_name := "Tu"
var money := 0
var debt := START_DEBT
## Di quanto è salito il debito nell'ultima notte: l'HUD lo mostra in rosso e poi lo rimette a 0.
var debito_salito_stanotte := 0
var energy := MAX_ENERGY
var rank := 0
var exploited := 0
var hard_work := 0
var helped := 0
var items: Array[String] = []
var robots: Array[String] = []
var helped_ids: Array[String] = []
var met_today: Array[String] = []
## Chi hai aiutato oggi: per il resto della giornata fa altro (campo "after_help").
var helped_today: Array[String] = []
var flags: Dictionary = {}
## Persone che hanno smesso di lavorare (i finali ne tengono conto).
var freed: Array[String] = []
var worked_today := false
## Righe da mostrare appena il giocatore entra nella prossima stanza.
var pending_lines: Array = []
## Configurazione del prossimo minigioco (vedi scenes/minigame/minigame.gd).
var minigame: Dictionary = {}

var _npcs: Dictionary = {}
var _worklist: Array = []
var _promotions: Dictionary = {}
## Il Mercato (capitolo 3): prezzi prima e dopo l'aggiornamento, premi, fatture.
var market: Dictionary = {}
## La Banca (capitolo 4): premio del capo, conti di Olga, pratiche dello sportello e di Teo.
var bank: Dictionary = {}
## La Città (capitolo 5): le stanze di Ada, il percorso di Nadir, il TURNO, i bilanci della Casa Comune.
var city: Dictionary = {}


func _ready() -> void:
	_npcs = _load_json("res://data/npcs.json", {})
	_worklist = _load_json("res://data/worklist.json", [])
	_promotions = _load_json("res://data/promotions.json", {})
	market = _load_json("res://data/market.json", {})
	bank = _load_json("res://data/bank.json", {})
	city = _load_json("res://data/city.json", {})


func _load_json(path: String, fallback: Variant) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("File mancante: " + path)
		return fallback
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null:
		push_error("JSON non valido: " + path)
		return fallback
	return parsed


func new_game() -> void:
	day = 1
	minutes = DAY_START
	floor_id = "-5"
	badges.clear()
	self_esteem = 0
	money = 0
	debt = START_DEBT
	energy = MAX_ENERGY
	rank = 0
	exploited = 0
	hard_work = 0
	helped = 0
	items.assign(["Panino"])
	robots.clear()
	helped_ids.clear()
	met_today.clear()
	helped_today.clear()
	flags.clear()
	flags["boss_missions_version"] = 2
	# il numero della partita (per la memoria di Nives): lo dà il menu con "Nuova partita"
	flags["run_id"] = ""
	minigame.clear()
	freed.clear()
	worked_today = false
	pending_lines.clear()
	changed.emit()


# --- dati -------------------------------------------------------------------

func npc_data(id: String) -> Dictionary:
	return _npcs.get(id, {})


func npc_ids() -> Array:
	return _npcs.keys()


## Dove si trova una persona adesso: {"room", "cell", "anim"}. Di sera può cambiare posto.
func npc_place(id: String) -> Dictionary:
	var data := npc_data(id)
	if id in freed and data.has("freed_place"):
		return data["freed_place"]
	if id in helped_today and data.has("after_help"):
		return data["after_help"]
	var schedule: Array = data.get("schedule", [])
	if minutes >= EVENING and data.has("evening"):
		schedule = data["evening"]
	if schedule.is_empty():
		return {}
	return schedule[clampi(day - 1, 0, schedule.size() - 1)]


func rank_name() -> String:
	return RANKS[mini(rank, RANKS.size() - 1)]


func is_robot(id: String) -> bool:
	return id in robots


func robot_line(id: String) -> String:
	# chi ha frasi da robot sue (campo "robot_lines") le ripete a giro; "robot_lines_if" ne
	# aggiunge altre quando un flag è vero (Amir, se sapevi del suo sogno)
	var own: Array = npc_data(id).get("robot_lines", [])
	if not own.is_empty():
		var extra: Dictionary = npc_data(id).get("robot_lines_if", {})
		if not extra.is_empty() and flags.get(str(extra.get("flag", "")), false):
			own = own + extra.get("lines", [])
		var k := int(flags.get("robot_talks_" + id, 0))
		flags["robot_talks_" + id] = k + 1
		return str(own[k % own.size()])
	return ROBOT_LINES[posmod(id.hash() + day, ROBOT_LINES.size())]


## Il prezzo di oggi di una cosa del Mercato: dopo l'aggiornamento (flag c3_prezzi) quello nuovo.
func market_price(key: String) -> int:
	var p: Array = market.get("prezzi", {}).get(key, {}).get("prezzo", [0, 0])
	return int(p[1] if flags.get("c3_prezzi", false) else p[0])


# --- tempo ------------------------------------------------------------------

func clock() -> String:
	var m := mini(minutes, MIDNIGHT)
	return "%02d:%02d" % [m / 60 % 24, m % 60]


func day_name() -> String:
	return DAY_NAMES[clampi(day - 1, 0, DAY_NAMES.size() - 1)]


func hours_left() -> float:
	return maxf(0.0, (MIDNIGHT - minutes) / 60.0)


## I giorni non sono contati: il tempo c'è sempre. Costa, però: ogni notte il debito cresce.
func has_time(_cost: int) -> bool:
	return true


## Fa passare il tempo. Se passa la mezzanotte comincia un altro giorno (e gli interessi corrono).
## Restituisce true se è cominciato un giorno nuovo.
func spend(cost: int) -> bool:
	minutes += cost
	var rolled := false
	while minutes >= MIDNIGHT:
		minutes -= MIDNIGHT - DAY_START
		_new_day()
		rolled = true
	changed.emit()
	return rolled


func _new_day() -> void:
	var before := debt
	debt += int(round(debt * interest_rate()))
	debito_salito_stanotte = debt - before
	day += 1
	worked_today = false
	met_today.clear()
	helped_today.clear()
	energy = MAX_ENERGY
	pending_lines.append("* È passata un'altra notte, da qualche parte sopra di te. Gli interessi no: il debito è salito di %s." % euros(debt - before))


## Colore della luce in base all'ora (per le scene all'aperto).
func daylight() -> Color:
	var h := minutes / 60.0
	if h < 17.0:
		return Color.WHITE
	if h < 20.0:
		return Color.WHITE.lerp(Color(1.0, 0.78, 0.6), (h - 17.0) / 3.0)
	if h < 22.0:
		return Color(1.0, 0.78, 0.6).lerp(Color(0.45, 0.5, 0.78), (h - 20.0) / 2.0)
	return Color(0.45, 0.5, 0.78)


# --- energia e oggetti ------------------------------------------------------

func restore(amount: int) -> void:
	energy = mini(MAX_ENERGY, energy + amount)
	changed.emit()


func use_item(index: int) -> String:
	var name := items[index]
	items.remove_at(index)
	var data: Dictionary = ITEMS.get(name, {"energy": 5, "text": "* Usi l'oggetto."})
	var before := energy
	restore(int(data["energy"]))
	var after := "* Energia al massimo!" if energy >= MAX_ENERGY else "* Hai recuperato %d di energia." % (energy - before)
	return str(data["text"]) + "\n" + after


func give_item(name: String) -> void:
	items.append(name)
	changed.emit()


# --- lavoro -----------------------------------------------------------------

## Il lavoro facile paga sempre di più: ogni firma ti rende più "prezioso".
func easy_pay() -> int:
	return int(round(900.0 * pow(1.7, exploited)))


## Sfruttare qualcuno: la persona viene sostituita da un robot.
func exploit(victim: String, pay: int) -> void:
	money += pay
	exploited += 1
	pending_level_up = true
	rank = mini(rank + 1, RANKS.size() - 1)
	if victim != "" and victim not in robots:
		robots.append(victim)
	changed.emit()


func finish_hard_job(pay: int) -> void:
	money += pay
	hard_work += 1
	flags["fail_streak"] = 0
	flags["boss_call_day"] = day
	# prima passano le 10 ore, poi si segna il turno: se il turno finisce dopo mezzanotte,
	# conta per il giorno nuovo (prima il giorno nuovo cancellava il segno e si lavorava due volte)
	spend(COST_HARD_JOB)
	worked_today = true
	changed.emit()


# --- aiutare le persone -----------------------------------------------------

func can_meet(id: String) -> bool:
	return id not in met_today and id not in robots


func help(id: String, kind: String, cost: int) -> bool:
	if kind == "money":
		if money < cost:
			return false
		money -= cost
	else:
		if not has_time(COST_HELP_TIME):
			return false
		spend(COST_HELP_TIME)
	helped += 1
	if id not in helped_ids:
		self_esteem += 1
	var unlock: Dictionary = npc_data(id).get("help", {}).get("unlock", {})
	if not unlock.is_empty() and not flags.get(unlock.get("flag", ""), false):
		flags[unlock["flag"]] = true
		pending_lines.append_array(unlock.get("lines", []))
	if id not in helped_today:
		helped_today.append(id)
	if id not in helped_ids:
		helped_ids.append(id)
		# il primo aiuto a questa persona: il suo numero nell'ordine delle azioni (per le reazioni)
		Storia.segna("aiuto_" + id)
	changed.emit()
	return true


# --- debito e giorni --------------------------------------------------------

func pay_debt(amount: int) -> int:
	var paid := mini(amount, mini(money, debt))
	money -= paid
	debt -= paid
	changed.emit()
	return paid


# --- LV, stati delle persone, massa critica ---------------------------------

## Come il LV di Undertale: sale quando sfrutti. La promozione è il "level up".
func lv() -> int:
	return 1 + exploited


## Diventa vero a ogni sfruttamento: chi mostra il messaggio "LEVEL UP" lo rimette a false.
var pending_level_up := false


func level_up_line() -> String:
	pending_level_up = false
	return "* LEVEL UP! Il tuo LV è salito a %d. Il mondo ti sembra un po' più grigio." % lv()


## Stato di una persona: "sfruttato" (robot), "libero" (ha smesso) o "ingranaggio" (lavora come sempre).
func npc_state(id: String) -> String:
	if is_robot(id):
		return "sfruttato"
	if id in freed:
		return "libero"
	return "ingranaggio"


# --- piani e badge ------------------------------------------------------------

func floor_index(id: String) -> int:
	for i in FLOORS.size():
		if FLOORS[i]["id"] == id:
			return i
	return 0


func floor_name(id := "") -> String:
	return str(FLOORS[floor_index(floor_id if id == "" else id)]["name"])


## Il piano subito sopra a `id` ("" se sei già in cima).
func floor_above(id := "") -> String:
	var i := floor_index(floor_id if id == "" else id) + 1
	return str(FLOORS[i]["id"]) if i < FLOORS.size() else ""


func badge_cost(id: String) -> int:
	return int(FLOORS[floor_index(id)]["badge"])


func has_badge(id: String) -> bool:
	return id == "-5" or id in badges


## Compra il badge di un piano: i soldi vanno tutti nel debito. Restituisce false se non bastano.
func buy_badge(id: String) -> bool:
	var cost := badge_cost(id)
	if has_badge(id) or money < cost:
		return false
	money -= cost
	debt = maxi(0, debt - cost)
	badges.append(id)
	flags["badge_day_" + id] = day
	changed.emit()
	return true


## Entrando in un piano nuovo: ricorda quando ci sei arrivato e quante persone avevi conosciuto
## (chi sale troppo in fretta, senza conoscere nessuno, avrà il finale brutto).
func enter_floor(id: String) -> void:
	floor_id = id
	if not flags.has("floor_day_" + id):
		flags["floor_day_" + id] = day
		flags["floor_met_" + id] = met_count()
	changed.emit()


# --- pietà e contratti -----------------------------------------------------------

## Il turno è andato male (sei crollato o l'hai mollato a metà). Conta i giorni di seguito.
func work_failed() -> void:
	var last := int(flags.get("fail_day", 0))
	if last == day:
		return
	var streak := int(flags.get("fail_streak", 0))
	flags["fail_streak"] = streak + 1 if last == day - 1 else 1
	flags["fail_day"] = day


## Dopo tre giorni di seguito di turni falliti, qualcuno ha pena di te (o ne approfitta).
func pity_pending() -> bool:
	var need := floor_above()
	return int(flags.get("fail_streak", 0)) >= 3 and need != "" and not has_badge(need) and money < badge_cost(need)


## Quanto ti manca per il badge del piano di sopra.
func money_missing() -> int:
	var need := floor_above()
	return 0 if need == "" else maxi(0, badge_cost(need) - money)


## Gli interessi di ogni notte: salgono un po' per ogni contratto firmato col Signor Rata.
func interest_rate() -> float:
	return DAILY_INTEREST + 0.005 * int(flags.get("contracts", 0))


## Il contratto del Signor Rata: il badge subito, il prezzo (più la metà) sul debito.
func sign_contract() -> void:
	var need := floor_above()
	if need == "" or has_badge(need):
		return
	badges.append(need)
	debt += int(round(badge_cost(need) * 1.5))
	flags["contracts"] = int(flags.get("contracts", 0)) + 1
	flags["badge_day_" + need] = day
	flags["fail_streak"] = 0
	changed.emit()


## Le persone che lavorano su un piano (quelle che si possono aiutare).
const FLOOR_ROOM := {"-5": "fondo", "-4": "sottoufficio", "-3": "mercato", "-2": "banca", "0": "office"}


func floor_people(id := "") -> Array:
	var room := str(FLOOR_ROOM.get(floor_id if id == "" else id, ""))
	var out: Array = []
	for n: String in npc_ids():
		var sched: Array = npc_data(n).get("schedule", [])
		if not sched.is_empty() and str(sched[0].get("room", "")) == room and npc_data(n).has("help"):
			out.append(n)
	return out


## Hai aiutato tutti quelli del piano? Allora il piano ti apre la porta.
func floor_all_helped(id := "") -> bool:
	var people := floor_people(id)
	if people.is_empty():
		return false
	for n: String in people:
		if n not in helped_ids:
			return false
	return true


## Quante persone hai conosciuto davvero (parlato almeno una volta).
func met_count() -> int:
	var n := 0
	for k: String in flags:
		if k.begins_with("met_") and flags[k] == true:
			n += 1
	return n


# --- la lista dei lavori peggiori del mondo ---------------------------------

## I lavori della lista (ogni piano ha i suoi posti di lavoro).
func jobs_available() -> Array:
	return _worklist.duplicate()


func job(id: String) -> Dictionary:
	for j: Dictionary in _worklist:
		if j["id"] == id:
			return j
	return {}


# --- la telefonata del capo: le promozioni ----------------------------------

## Dopo un turno il capo ti chiama per proporti una promozione: sfruttare qualcuno.
## Serve solo ai salvataggi vecchi (senza gli incarichi del Capo, scripts/boss_missions.gd):
## sceglie qualcuno che hai conosciuto su questo piano, così la scelta fa male.
func promotion_victim() -> String:
	# prima di tutto qualcuno che hai conosciuto qui, su questo piano (al Fondo: Fermo)
	var here: Array = []
	if floor_id == "-5":
		here.append("fermo")
	here.append_array(floor_people())
	for id: String in here:
		if flags.get("met_" + id, false) and not is_robot(id) and id not in freed and not promotion(id).is_empty():
			return id
	# se non hai ancora parlato con nessuno, il capo sceglie comunque qualcuno di questo piano
	for id: String in here:
		if not is_robot(id) and id not in freed and not promotion(id).is_empty():
			return id
	return ""


func promotion(id: String) -> Dictionary:
	return _promotions.get(id, {})


## Firmare una promozione: un'ora, una persona in meno.
func do_promotion(victim: String) -> int:
	var pay := easy_pay()
	exploit(victim, pay)
	spend(COST_EASY_JOB)
	return pay


## Il capo telefona dopo un turno, ma una volta sola per piano: l'idea da rubare è una.
func boss_call_pending() -> bool:
	if floor_id == "0" and load("res://scripts/boss_missions.gd").uses("0") and not flags.get("c5_protesta", false):
		return false
	return int(flags.get("boss_call_day", 0)) == day and not flags.get("boss_call_done_%d" % day, false) 		and not flags.get("boss_call_floor_" + floor_id, false)


# --- il tempo, cioè la vera valuta ------------------------------------------

# --- testo ------------------------------------------------------------------

## Una frase che comincia con [PC] si vede solo sul computer, con [TEL] solo sul telefono
## (la scritta tra parentesi non compare). Per l'altro dispositivo torna "".
static func per_dispositivo(text: String) -> String:
	for tag: String in ["[PC]", "[TEL]"]:
		if text.begins_with(tag):
			var mio := (tag == "[TEL]") == TouchControls.enabled
			return text.substr(tag.length()).strip_edges(true, false) if mio else ""
	return text


func fmt(text: String) -> String:
	text = per_dispositivo(text)
	if TouchControls.enabled:
		# sul telefono si gioca col dito: le vecchie istruzioni da tastiera diventano tocchi
		text = text.replace("Premi {ok}", "Tocca lo schermo").replace("premi {ok}", "tocca lo schermo") 			.replace("con le frecce", "col dito")
	return text.replace("{rank}", rank_name()) \
		.replace("{debt}", euros(debt)) \
		.replace("{money}", euros(money)) \
		.replace("{day}", str(day)) \
		.replace("{day_name}", day_name()) \
		.replace("{clock}", clock()) \
		.replace("{floor}", floor_name()) \
		.replace("{name}", player_name) \
		.replace("{ok}", "OK" if TouchControls.enabled else "INVIO")


## Le cifre enormi (il debito) scritte corte: "7,00 mld €".
## Le domande già fatte a qualcuno non tornano nel menu la volta dopo (flag "chiesto_<chiave>").
func chiesto(key: String) -> bool:
	return bool(flags.get("chiesto_" + key, false))


func segna_chiesto(key: String) -> void:
	flags["chiesto_" + key] = true


## Le domande di un menu che non hai ancora fatto: [[chiave, testo], ...] -> solo quelle nuove.
func domande_nuove(domande: Array) -> Array:
	return domande.filter(func(q: Array) -> bool: return not chiesto(str(q[0])))


static func euros_short(n: int) -> String:
	if absi(n) >= 1_000_000_000:
		return ("%.2f mld €" % (n / 1e9)).replace(".", ",")
	if absi(n) >= 1_000_000:
		return ("%.2f mln €" % (n / 1e6)).replace(".", ",")
	return euros(n)


static func euros(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out + " €"


# --- salvataggio ------------------------------------------------------------

func has_save() -> bool:
	return FileAccess.file_exists(save_path)


## Salva tutto: anche stanza, posizione e ora (punti di salvataggio e letto).
func save_game(room := "res://chapters/c1/fondo.tscn", pos := Vector2.INF) -> void:
	var data := {
		"save_version": 2, "day": day, "minutes": minutes, "money": money, "debt": debt, "energy": energy, "rank": rank,
		"exploited": exploited, "hard_work": hard_work, "helped": helped,
		"items": items, "robots": robots, "helped_ids": helped_ids, "met_today": met_today, "helped_today": helped_today,
		"worked_today": worked_today, "flags": flags,
		"freed": freed, "room": room,
		"floor_id": floor_id, "badges": badges, "player_name": player_name, "self_esteem": self_esteem,
		"pos": [pos.x, pos.y] if pos != Vector2.INF else [],
	}
	var target := ProjectSettings.globalize_path(save_path)
	var tmp := target + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if not file:
		push_error("Impossibile creare il salvataggio temporaneo.")
		return
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	if not JSON.parse_string(FileAccess.get_file_as_string(tmp)) is Dictionary:
		push_error("Salvataggio temporaneo non valido: originale conservato.")
		return
	var had_valid_save := false
	if FileAccess.file_exists(target):
		had_valid_save = JSON.parse_string(FileAccess.get_file_as_string(target)) is Dictionary
		if had_valid_save and DirAccess.copy_absolute(target, target + ".bak") != OK:
			push_error("Impossibile conservare il precedente salvataggio.")
			return
		# Su Windows rename_absolute non sostituisce un file già esistente.
		# Il vecchio salvataggio valido è già al sicuro nel .bak.
		if DirAccess.remove_absolute(target) != OK:
			push_error("Impossibile preparare la sostituzione del salvataggio.")
			return
	# rename_absolute resta inaffidabile su Windows anche dopo la rimozione della
	# destinazione. La copia parte da un JSON già validato e il .bak permette il ripristino.
	if DirAccess.copy_absolute(tmp, target) != OK:
		if had_valid_save and FileAccess.file_exists(target + ".bak"):
			DirAccess.copy_absolute(target + ".bak", target)
		push_error("Salvataggio non sostituito: precedente e temporaneo conservati.")
		return
	DirAccess.remove_absolute(tmp)


## Carica il salvataggio. Restituisce {"room", "pos"} per sapere dove ricomparire, oppure {} se non c'è.
func load_game() -> Dictionary:
	if not has_save():
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if typeof(d) != TYPE_DICTIONARY:
		d = JSON.parse_string(FileAccess.get_file_as_string(save_path + ".bak")) if FileAccess.file_exists(save_path + ".bak") else null
	if typeof(d) != TYPE_DICTIONARY:
		return {}
	new_game()
	day = int(d.get("day", 1))
	minutes = int(d.get("minutes", DAY_START))
	money = int(d.get("money", 0))
	debt = int(d.get("debt", START_DEBT))
	energy = int(d.get("energy", MAX_ENERGY))
	rank = int(d.get("rank", 0))
	exploited = int(d.get("exploited", 0))
	hard_work = int(d.get("hard_work", 0))
	helped = int(d.get("helped", 0))
	items.assign(d.get("items", []))
	robots.assign(d.get("robots", []))
	helped_ids.assign(d.get("helped_ids", []))
	met_today.assign(d.get("met_today", []))
	helped_today.assign(d.get("helped_today", []))
	worked_today = bool(d.get("worked_today", false))
	flags = d.get("flags", {})
	# un salvataggio di prima della memoria di Nives: è una partita sola, sempre la stessa
	if not flags.has("run_id"):
		flags["run_id"] = MemoriaNives.LEGACY
	freed.assign(d.get("freed", []))
	floor_id = str(d.get("floor_id", "-5"))
	badges.assign(d.get("badges", []))
	player_name = capital(str(d.get("player_name", "Tu")))
	self_esteem = int(d.get("self_esteem", 0))
	load("res://scripts/boss_missions.gd").migrate(int(d.get("save_version", 0)) < 2)
	changed.emit()
	var pos: Array = d.get("pos", [])
	return {
		"room": str(d.get("room", "res://chapters/c1/fondo.tscn")),
		"pos": Vector2(float(pos[0]), float(pos[1])) if pos.size() == 2 else Vector2.INF,
	}


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


## Il nome comincia sempre con la maiuscola ("linda" -> "Linda"); il resto resta com'è.
static func capital(t: String) -> String:
	return t.left(1).to_upper() + t.substr(1) if t != "" else t
