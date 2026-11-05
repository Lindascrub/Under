extends Node2D
## Una carica e un rilascio: forza moderata, quando Ercole sta chiudendo gli occhi.
## Posizioni e immagini nella scena; soglie e tempi nell'Inspector.
signal colpo(perfetto: bool)
signal errore
signal finito(vinto: bool)

@export_group("Gomitata")
@export var durata_carica := 1.2
@export_range(0.0, 1.0) var forza_minima := 0.38
@export_range(0.0, 1.0) var forza_massima := 0.72
@export_range(0.0, 1.0) var occhi_si_chiudono := 0.78
@export_range(0.0, 1.0) var colpo_utile := 0.42
@export var gomitate_richieste := 4
@export var errori_massimi := 3
@export_group("Sonno")
@export var secondi_per_addormentarsi := 3.6
@export var sonno_iniziale := 0.08
@export var recupero := 0.4
@export_group("Animazione")
@export var inclinazione_sonno := 22.0
@export var inclinazione_carica := -16.0
@export var inclinazione_colpo := 16.0

@onready var corpo: Sprite2D = $Ercole/Corpo
@onready var braccio: Sprite2D = $Giocatore/Corpo
@onready var ispettore: Sprite2D = $Ispettore/Corpo
@onready var sonnellino: Label = $Ercole/Sonno
@onready var carica_barra: ProgressBar = $Forza
@onready var sonno_barra: ProgressBar = $Stanchezza
@onready var aiuto: Label = $Aiuto
@onready var stato: Label = $Stato
@onready var risultato: Label = $Esito
@onready var bersaglio: Marker2D = $Ercole/Impatto

var attivo := false
var premuto := false
var fonte := ""
var carica := 0.0
var sonno := 0.08
var riuscite := 0
var errori := 0
var pausa := 0.0
var esito_t := 0.0
var prova_libera := false


func _ready() -> void:
	aiuto.text = "Tieni premuto, poi lascia: una gomitata leggera." if TouchControls.enabled else "Tieni premuto INVIO o il mouse, poi lascia."
	if get_parent() == get_tree().root:
		avvia()


func avvia() -> void:
	riuscite = 0
	errori = 0
	sonno = sonno_iniziale
	if prova_libera: sonno = occhi_si_chiudono
	carica = 0.0
	pausa = 0.0
	attivo = true
	premuto = false
	fonte = ""
	ispettore.flip_h = false
	risultato.text = ""
	visible = true
	_aggiorna()


func _process(delta: float) -> void:
	if attivo and not Ui.busy:
		passo(delta)


func passo(delta: float) -> void:
	if not attivo:
		return
	esito_t = maxf(0.0, esito_t - delta)
	if esito_t == 0.0:
		risultato.text = ""
	if pausa > 0.0:
		pausa = maxf(0.0, pausa - delta)
	else:
		if not prova_libera: sonno += delta * sqrt(1.0 + riuscite * 0.18) / maxf(0.1, secondi_per_addormentarsi)
		if premuto:
			carica += delta / maxf(0.1, durata_carica)
			if carica > forza_massima + 0.18:
				_troppo_forte()
				return
		if sonno >= 1.0:
			risultato.text = "Si è addormentato."
			_chiudi(false)
	_aggiorna()


func premi(origine := "tasto") -> void:
	if not attivo or premuto or pausa > 0.0:
		return
	premuto = true
	fonte = origine
	carica = 0.0


func lascia(origine := "tasto") -> void:
	if not attivo or not premuto or origine != fonte:
		return
	premuto = false
	fonte = ""
	if carica > forza_massima:
		_troppo_forte()
		return
	var utile := carica >= forza_minima and sonno >= colpo_utile
	var perfetto := utile and sonno >= occhi_si_chiudono
	if prova_libera and not utile:
		carica = 0.0
		risultato.text = "Riprova: carica fino alla zona verde, poi lascia."
		esito_t = 1.5
		return
	if prova_libera:
		prova_libera = false
		perfetto = true
	var tw := create_tween()
	tw.tween_property(braccio, "rotation_degrees", inclinazione_colpo, 0.06)
	tw.tween_property(braccio, "rotation_degrees", 0.0, 0.18).set_trans(Tween.TRANS_BACK)
	if utile:
		riuscite += 1
		sonno = sonno_iniziale
		risultato.text = "Al momento giusto!" if perfetto else "Sveglio, ma troppo presto."
		if not perfetto:
			errori += 1
		colpo.emit(perfetto)
	else:
		errori += 1
		risultato.text = "Troppo piano." if carica < forza_minima else "È ancora sveglio."
		corpo.modulate = Color(1.0, 0.65, 0.55)
		errore.emit()
	esito_t = 0.65
	carica = 0.0
	pausa = recupero
	if errori >= errori_massimi:
		risultato.text = "Ercole si è arrabbiato."
		_chiudi(false)
	elif riuscite >= gomitate_richieste:
		risultato.text = "Ispezione finita. Ercole è sveglio."
		_chiudi(true)
	_aggiorna()


func _troppo_forte() -> void:
	if prova_libera:
		premuto = false
		fonte = ""
		carica = 0.0
		risultato.text = "Troppo forte. Riprova: lascia nella zona verde."
		esito_t = 1.5
		return
	errori += 1
	ispettore.flip_h = true
	corpo.rotation_degrees = -inclinazione_sonno
	risultato.text = "Troppo forte! L'ispettore si gira."
	errore.emit()
	_chiudi(false)


func _chiudi(vinto: bool) -> void:
	attivo = false
	premuto = false
	fonte = ""
	finito.emit(vinto)


func _aggiorna() -> void:
	var zona: Control = $Forza/ZonaGiusta
	zona.position.x = carica_barra.size.x * forza_minima
	zona.size.x = carica_barra.size.x * (forza_massima - forza_minima)
	carica_barra.value = clampf(carica, 0.0, 1.0) * 100.0
	sonno_barra.value = clampf(sonno, 0.0, 1.0) * 100.0
	sonno_barra.modulate.a = 0.55 if sonno >= occhi_si_chiudono and int(Time.get_ticks_msec() / 140) % 2 == 0 else 1.0
	var lampadine := $Errori.get_children()
	for i in lampadine.size():
		lampadine[i].modulate = Color(0.25, 0.25, 0.3) if i < errori else Color.WHITE
	sonnellino.text = "Z Z Z" if sonno >= occhi_si_chiudono else ("z z" if sonno >= colpo_utile else "")
	corpo.rotation_degrees = sonno * inclinazione_sonno
	if premuto:
		braccio.rotation_degrees = carica * inclinazione_carica
	if pausa == 0.0:
		corpo.modulate = Color.WHITE
	stato.text = "Sveglio: %d/%d" % [riuscite, gomitate_richieste]


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		premuto = false
		fonte = ""
		carica = 0.0


func input_event(event: InputEvent) -> bool:
	if not attivo or Ui.busy:
		return false
	if event is InputEventKey and event.echo:
		return false
	if event.is_action_pressed("confirm"):
		premi()
		return true
	if event.is_action_released("confirm"):
		lascia()
		return true
	# (solo PC) mouse: stessa carica della tastiera, senza sommare due pressioni.
	if not TouchControls.enabled and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			premi("mouse")
		else:
			lascia("mouse")
		return true
	return false


## Permette anche di provare questa scena da sola con F6 nell'editor.
func _unhandled_input(event: InputEvent) -> void:
	if get_tree().current_scene == self and input_event(event):
		get_viewport().set_input_as_handled()


func touch_scheme() -> String:
	return "point" if attivo else ""


func touch_point(_pos: Vector2, step: int) -> void:
	if step == 0:
		premi("dito")
	elif step == 2:
		lascia("dito")
