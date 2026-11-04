extends Node2D
## L'incarico del Capo al -5, "Ancora cinque minuti" (scenes/minigame/capo_dinamo.tscn).
## Una leva sola. Più la tiri giù, più la festa è accesa, ma Fermo pedala più forte, diventa rosso,
## suda e la sua pausa si accorcia. La scelta si vede su di lui, non si legge in una tabella.
## Ogni tacca della leva è (ritmo 1-3, minuti in più): si cambiano qui sotto, nell'editor.
## I conti (energia, premio, conseguenze nella storia) restano in scripts/boss_missions.gd.
## Lo apre scenes/minigame/boss_mission.gd, che riceve i segnali.

signal cambiato(scelta: Dictionary)
signal confermato(scelta: Dictionary)
signal esci

const B := preload("res://scripts/boss_missions.gd")

## Le tacche della leva, dall'alto in basso: x = ritmo di Fermo (1-3), y = minuti in più.
@export var tacche: Array[Vector2i] = [Vector2i(2, 0), Vector2i(2, 10), Vector2i(3, 0), Vector2i(3, 10)]
## Quanto pedala Fermo (fotogrammi al secondo) per ritmo 0, 1, 2, 3.
@export var pedalate: Array[float] = [0.0, 3.0, 6.0, 11.0]
## Il colore di Fermo quando è stanchissimo.
@export var colore_stanco := Color(1.0, 0.42, 0.38)
## Il colore delle lampadine spente.
@export var luce_spenta := Color(0.22, 0.22, 0.3)
## Da quale tacca si parte.
@export var tacca := 0

@onready var _corpo: Sprite2D = $Fermo/Corpo
@onready var _sudore: CPUParticles2D = $Fermo/Sudore
@onready var _pausa: Label = $Pausa
@onready var _binario: Control = $Leva/Binario
@onready var _manico: Control = $Leva/Manico
@onready var _area: Control = $Leva/Area
@onready var _luci: Node = $Festa/Luci
@onready var _premio: Label = $Premio
@onready var _aiuto: Label = $Aiuto
@onready var conferma: Control = $Conferma
@onready var esci_tasto: Control = $Esci

var _t := 0.0
var _tira := false
var _riga_corpo := 0.0


func _ready() -> void:
	_riga_corpo = _corpo.region_rect.position.y
	_aiuto.text = "Trascina la leva. Poi tocca CONFERMA." if TouchControls.enabled else "SU e GIÙ, o trascina la leva col mouse. INVIO: conferma."
	_aggiorna()


## Parte dalla scelta salvata (se c'è una tacca uguale).
func imposta(p: Dictionary) -> void:
	var i := tacche.find(Vector2i(int(p.get("intensity", 2)), int(p.get("extra", 0))))
	tacca = i if i >= 0 else 0
	_aggiorna()


## La scelta di adesso, come la vuole scripts/boss_missions.gd: le luci della festa accese sono
## quelle che l'energia di Fermo riesce a tenere.
func scelta() -> Dictionary:
	var s := tacche[clampi(tacca, 0, tacche.size() - 1)]
	for decor in [2, 1, 0]:
		var p := {"intensity": s.x, "extra": s.y, "decor": decor}
		if bool(B.energy_preview(p)["valid"]):
			return p
	return {"intensity": s.x, "extra": s.y, "decor": 0}


## Un avviso in basso (per esempio se una tacca dell'editor non basta nemmeno per i servizi).
func avviso(testo: String) -> void:
	_aiuto.text = testo


func _process(delta: float) -> void:
	var s := tacche[clampi(tacca, 0, tacche.size() - 1)]
	_t += delta * pedalate[clampi(s.x, 0, pedalate.size() - 1)]
	var r := _corpo.region_rect
	r.position = Vector2((int(_t) % 6) * 16, _riga_corpo)
	_corpo.region_rect = r


func _aggiorna() -> void:
	if not is_node_ready():
		return
	var p := scelta()
	var v := B.energy_preview(p)
	var stanco := clampf((float(v["fatigue"]) - 40.0) / 40.0, 0.0, 1.0)
	_corpo.modulate = Color.WHITE.lerp(colore_stanco, stanco)
	_sudore.emitting = bool(v["overwork"])
	_sudore.speed_scale = 0.6 + stanco
	_pausa.text = "Pausa: %d min" % int(v["rest"])
	_premio.visible = bool(v["overwork"])
	_premio.text = "+" + GameState.euros(int(B.PRIZES["-5"]))
	# le luci della festa: metà per ogni livello di decorazioni
	var luci := _luci.get_children()
	var per := ceili(luci.size() / 2.0)
	for i in luci.size():
		(luci[i] as CanvasItem).modulate = Color.WHITE if i < int(p["decor"]) * per else luce_spenta
	# il manico scende lungo il binario
	var k := float(tacca) / maxf(1.0, tacche.size() - 1)
	_manico.position.y = _binario.position.y + _binario.size.y * k - _manico.size.y / 2.0


func _metti(n: int) -> void:
	n = clampi(n, 0, tacche.size() - 1)
	if n == tacca:
		return
	Sound.sfx("move", 0.9 + 0.12 * n)
	tacca = n
	_aggiorna()
	cambiato.emit(scelta())


func _conferma() -> void:
	Sound.sfx("select")
	confermato.emit(scelta())


## Un dito (o il mouse) in `pos`. step: 0 = giù, 1 = trascina, 2 = su.
func punta(pos: Vector2, step: int) -> void:
	if step == 0:
		if _area.get_global_rect().has_point(pos):
			_tira = true
		elif conferma.get_global_rect().has_point(pos):
			_conferma()
			return
		elif esci_tasto.get_global_rect().has_point(pos):
			esci.emit()
			return
	if _tira:
		var r := _binario.get_global_rect()
		_metti(roundi(clampf((pos.y - r.position.y) / r.size.y, 0.0, 1.0) * (tacche.size() - 1)))
	if step == 2:
		_tira = false


func _unhandled_input(event: InputEvent) -> void:
	if Ui.busy or not visible:
		return
	if event.is_action_pressed("move_down") or event.is_action_pressed("move_right"):
		_metti(tacca + 1)
	elif event.is_action_pressed("move_up") or event.is_action_pressed("move_left"):
		_metti(tacca - 1)
	elif event.is_action_pressed("confirm"):
		_conferma()
	elif TouchControls.enabled:
		return
	# (solo PC) da qui in giù: il mouse
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		punta((event as InputEventMouseButton).position, 0 if event.pressed else 2)
	elif event is InputEventMouseMotion and _tira:
		punta((event as InputEventMouseMotion).position, 1)
	else:
		return
	get_viewport().set_input_as_handled()
