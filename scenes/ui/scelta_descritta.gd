extends Control
## Una scelta con la spiegazione sempre accanto al comando, usata per il mandato della Cima.
signal scelta(indice: int)
signal puntata(indice: int)
var indice := 0
var conclusa := false
@onready var righe: VBoxContainer = $Righe

func _ready() -> void:
	$Aiuto.text = "Tocca una scelta per confermarla." if TouchControls.enabled else "SU/GIÙ per scegliere. INVIO per confermare."
	for i in righe.get_child_count():
		var b := righe.get_child(i) as Button
		b.pressed.connect(_conferma.bind(i))
		b.focus_entered.connect(func() -> void: indice = i; puntata.emit(i))
	(righe.get_child(0) as Button).grab_focus()

func imposta(titolo: String, opzioni: Array) -> void:
	$Titolo.text = titolo
	for i in opzioni.size():
		var b := righe.get_child(i)
		b.get_node("Titolo").text = opzioni[i][0]
		b.get_node("Descrizione").text = opzioni[i][1]

func _conferma(i: int) -> void:
	if conclusa:
		return
	conclusa = true
	Sound.sfx("select")
	scelta.emit(i)

func seleziona(i: int) -> void:
	indice = i
	(righe.get_child(i) as Button).grab_focus()

func indice_a(pos: Vector2) -> int:
	for i in righe.get_child_count():
		if (righe.get_child(i) as Button).get_global_rect().has_point(pos):
			return i
	return -1
