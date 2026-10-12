extends Node
## Stato della partita: soldi, debito, giorni e le scelte morali del giocatore.
## Le regole dei tre finali sono in route().

signal changed

const SAVE_PATH := "user://cheap_save.json"
const START_DEBT := 48000
const DAILY_INTEREST := 0.01
const MIN_PAYMENT := 400
const LATE_FEE := 250
const LAST_DAY := 7
const FREE_TIME_PER_DAY := 3

const RANKS: Array[String] = [
	"Stagista", "Impiegato", "Supervisore", "Responsabile", "Manager",
	"Direttore", "Amministratore Delegato", "Presidente",
]

## Quello che dicono le persone sostituite da robot. Sempre gentili, sempre uguali.
const ROBOT_LINES: Array[String] = [
	"Buongiorno, {rank}.",
	"Ottimo lavoro, {rank}. Il suo successo è il nostro successo.",
	"Tutto procede secondo i parametri.",
	"Le auguro una giornata produttiva, {rank}.",
	"Sono molto felice. Grazie per avermelo chiesto.",
]

var day := 1
var money := 0
var debt := START_DEBT
var rank := 0
var exploited := 0
var hard_work := 0
var refused := 0
var helped := 0
var robots: Array[String] = []
var helped_ids: Array[String] = []
var helped_today: Array[String] = []
var flags: Dictionary = {}
var worked_today := false
var free_time := FREE_TIME_PER_DAY
## Righe da mostrare appena il giocatore entra nella prossima stanza.
var pending_lines: Array = []

var _npcs: Dictionary = {}
var _jobs: Array = []


func _ready() -> void:
	_npcs = _load_json("res://data/npcs.json", {})
	_jobs = _load_json("res://data/jobs.json", [])


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
	money = 0
	debt = START_DEBT
	rank = 0
	exploited = 0
	hard_work = 0
	refused = 0
	helped = 0
	robots.clear()
	helped_ids.clear()
	helped_today.clear()
	flags.clear()
	worked_today = false
	free_time = FREE_TIME_PER_DAY
	pending_lines.clear()
	changed.emit()


# --- dati -------------------------------------------------------------------

func npc_data(id: String) -> Dictionary:
	return _npcs.get(id, {})


func npc_ids() -> Array:
	return _npcs.keys()


func job_today() -> Dictionary:
	if _jobs.is_empty():
		return {}
	return _jobs[clampi(day - 1, 0, _jobs.size() - 1)]


func rank_name() -> String:
	return RANKS[mini(rank, RANKS.size() - 1)]


func is_robot(id: String) -> bool:
	return id in robots


func robot_line(id: String) -> String:
	return ROBOT_LINES[posmod(id.hash() + day, ROBOT_LINES.size())]


# --- lavoro -----------------------------------------------------------------

## Il lavoro facile paga sempre di più: ogni firma ti rende più "prezioso".
func easy_pay() -> int:
	return int(round(1500.0 * pow(1.7, exploited)))


## Firmare: un secondo di fatica, una persona in meno.
func do_easy_job() -> int:
	var pay := easy_pay()
	money += pay
	exploited += 1
	rank = mini(rank + 1, RANKS.size() - 1)
	var victim := str(job_today().get("victim", ""))
	if victim != "" and victim not in robots:
		robots.append(victim)
	worked_today = true
	changed.emit()
	return pay


func finish_hard_job(pay: int) -> void:
	money += pay
	hard_work += 1
	worked_today = true
	free_time = maxi(free_time - 1, 0)
	changed.emit()


func refuse_work() -> void:
	if worked_today:
		return
	refused += 1
	worked_today = true
	changed.emit()


# --- aiutare le persone -----------------------------------------------------

func can_help(id: String) -> bool:
	return id not in helped_today and id not in robots


func help(id: String, kind: String, cost: int) -> bool:
	if kind == "money":
		if money < cost:
			return false
		money -= cost
	else:
		if free_time <= 0:
			return false
		free_time -= 1
	helped += 1
	helped_today.append(id)
	if id not in helped_ids:
		helped_ids.append(id)
	changed.emit()
	return true


# --- debito e giorni --------------------------------------------------------

func pay_debt(amount: int) -> int:
	var paid := mini(amount, mini(money, debt))
	money -= paid
	debt -= paid
	changed.emit()
	return paid


func end_day(paid_minimum: bool) -> void:
	if not paid_minimum and debt > 0:
		debt += LATE_FEE
	debt += int(round(debt * DAILY_INTEREST))
	day += 1
	worked_today = false
	free_time = FREE_TIME_PER_DAY
	helped_today.clear()
	changed.emit()


## Quale finale ha "meritato" il giocatore.
func route() -> String:
	if exploited >= 4:
		return "ricco"
	if refused >= 3 and helped >= 4:
		return "ribelle"
	return "onesto"


## Nico è l'unico personaggio che si accorge di come stai cambiando.
func nico_lines() -> Array:
	if exploited >= 4:
		return [
			"Ehi, {rank}! ...Scusa, ora ti chiamano tutti così, no?",
			"Non ti vedo più qui sotto.",
			"A dire il vero non vedo più nessuno, qui sotto. Solo gente che sorride sempre uguale.",
		]
	if exploited >= 2:
		return [
			"Sempre di corsa, eh? Bel vestito.",
			"Il signor Bruno dice che l'hai salutato come se non lo conoscessi.",
			"...Sarà la stanchezza. Prenditi un caffè.",
		]
	if refused >= 2:
		flags["rebel_hint"] = true
		return [
			"Ho sentito che hai detto di no al capo. Ah!",
			"Sai quanti siamo, qui, a non poterne più?",
			"La sera, al parcheggio, ci scambiamo roba. Pane, riparazioni, favori. Senza soldi.",
			"Pensaci.",
		]
	if helped >= 2:
		return [
			"Ho saputo che hai dato una mano a mezzo quartiere.",
			"Non ti farà diventare ricco. Però ti fa dormire, no?",
		]
	var by_day := [
		["Il caffè di oggi sa di bruciato. Come il mio conto in banca."],
		["Sai qual è il trucco per non pensare ai debiti?", "...Se lo scopri dimmelo."],
		["La CHEAP ha comprato anche il bar all'angolo. Ora il caffè costa il doppio e lo fa una macchina."],
		["Ieri ho fatto due conti. Poi ho smesso, che mi veniva da piangere."],
	]
	return by_day[clampi(day - 1, 0, by_day.size() - 1)]


# --- testo ------------------------------------------------------------------

func fmt(text: String) -> String:
	return text.replace("{rank}", rank_name()) \
		.replace("{debt}", euros(debt)) \
		.replace("{money}", euros(money)) \
		.replace("{day}", str(day)) \
		.replace("{last_day}", str(LAST_DAY))


static func euros(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out + " €"


# --- salvataggio ------------------------------------------------------------

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var data := {
		"day": day, "money": money, "debt": debt, "rank": rank,
		"exploited": exploited, "hard_work": hard_work, "refused": refused, "helped": helped,
		"robots": robots, "helped_ids": helped_ids, "flags": flags,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


func load_game() -> bool:
	if not has_save():
		return false
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(d) != TYPE_DICTIONARY:
		return false
	new_game()
	day = int(d.get("day", 1))
	money = int(d.get("money", 0))
	debt = int(d.get("debt", START_DEBT))
	rank = int(d.get("rank", 0))
	exploited = int(d.get("exploited", 0))
	hard_work = int(d.get("hard_work", 0))
	refused = int(d.get("refused", 0))
	helped = int(d.get("helped", 0))
	robots.assign(d.get("robots", []))
	helped_ids.assign(d.get("helped_ids", []))
	flags = d.get("flags", {})
	changed.emit()
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
