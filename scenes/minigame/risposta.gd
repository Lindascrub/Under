class_name Risposta
extends Node2D
## La risposta ai colpi dei minigiochi d'aiuto (scenes/minigame/risposta.tscn), uguale per tutti:
##   giusto     (piccolo): scintille, "+1" che sale, suono che sale di tono con i colpi di fila
##   di fila    (medio):   ogni `fila_ogni` giusti di fila compare "3 DI FILA!"
##   sbagliato  (medio):   scossa leggera, suono basso; la fila ricomincia da zero
##   vittoria   (grande):  un attimo fermo, scossa, coriandoli, poi le stelline una alla volta
## Le stelline vengono dalla bravura (gli errori; il tempo solo se tempo_per_3 > 0), non da quanto premi.
## Tutto si cambia nell'editor: i numeri qui sotto, e i nodi (Scintille, Coriandoli, Stelle...).

@export_group("Scossa")
## Quanto scuote lo schermo un errore (0 = niente, 1 = il massimo).
@export_range(0.0, 1.0) var scossa_sbagliato := 0.35
## Quanto scuote lo schermo la vittoria.
@export_range(0.0, 1.0) var scossa_vittoria := 0.6
## Quanto in fretta smette di scuotere (al secondo).
@export var calo_scossa := 1.8
## Di quanti pixel si sposta al massimo.
@export var spostamento_max := Vector2(7, 5)

@export_group("Colpi")
## Ogni quanti giusti di fila compare la scritta.
@export var fila_ogni := 3
## Quanto sale il tono del suono a ogni giusto di fila.
@export var tono_per_colpo := 0.06
## Quanti secondi la vittoria resta "ferma" prima dei coriandoli.
@export var fermo_vittoria := 0.12

@export_group("Stelline")
## Tre stelline: al massimo questi errori...
@export var errori_per_3 := 0
## ...e almeno questa parte del tempo ancora da usare (0 = non conta: tutto perfetto = tre stelline).
@export_range(0.0, 1.0) var tempo_per_3 := 0.0
## Due stelline: al massimo questi errori.
@export var errori_per_2 := 1
## Quanto restano le stelline sullo schermo (si saltano con OK / un tocco).
@export var durata_stelle := 2.2
@export var scritte := PackedStringArray(["Ce l'hai fatta", "Bene!", "Benissimo!"])
## Le stelline: accesa (presa) e spenta, con gli occhi a X (quelle che non hai preso).
@export var stella_accesa: Texture2D
@export var stella_spenta: Texture2D
## Quanto è scura la stellina spenta.
@export var colore_spenta := Color(0.25, 0.25, 0.3)
## La scritta quando perdi: le tre stelline restano tutte spente.
@export var scritta_zero := "0 stelle"

@export_group("Soldi")
## Se perdi, chi hai aiutato ti dà lo stesso questi euro.
@export var soldi_se_perdi := 5


## Il premio secondo le stelline: 1 stellina = un terzo, 2 = due terzi, 3 = tutto.
func soldi(premio: int, quante: int) -> int:
	return int(round(premio * clampi(quante, 0, 3) / 3.0))

@onready var _camera: Camera2D = $Camera
@onready var _scintille: CPUParticles2D = $Scintille
@onready var _coriandoli: CPUParticles2D = $Coriandoli
@onready var _numerino: Label = $Numerino
@onready var _fila_scritta: Label = $Fila
@onready var _stelle: Node2D = $Stelle

var fila := 0
var _trauma := 0.0
var _t := 0.0
var _salta := false


func _ready() -> void:
	_numerino.visible = false
	_fila_scritta.visible = false
	_stelle.visible = false
	# la scossa passa dalla telecamera del minigioco (anche se ce n'è un'altra in giro)
	_camera.make_current()


func _process(delta: float) -> void:
	if _trauma <= 0.0:
		_camera.offset = Vector2.ZERO
		return
	_trauma = maxf(_trauma - calo_scossa * delta, 0.0)
	var s := _trauma * _trauma
	_t += delta * 30.0
	_camera.offset = Vector2(spostamento_max.x * s * sin(_t * 1.7), spostamento_max.y * s * sin(_t * 2.3))


func scuoti(quanto: float) -> void:
	_trauma = clampf(_trauma + quanto, 0.0, 1.0)


## Un colpo giusto in `pos`. `suono`: quello del gioco (sale di tono con la fila).
func giusto(pos: Vector2, suono := "coin") -> void:
	fila += 1
	Sound.sfx(suono, 1.0 + tono_per_colpo * mini(fila - 1, 8))
	_scintille.position = pos
	_scintille.restart()
	_sale(_numerino, pos + Vector2(0, -10), "+1")
	if fila_ogni > 0 and fila % fila_ogni == 0:
		_sale(_fila_scritta, _fila_scritta.position, "%d DI FILA!" % fila, true)
		Sound.sfx("select", 1.2 + tono_per_colpo * mini(fila, 8))


## Un errore: la fila ricomincia. Se dai `pos`, lì compare il divieto rosso (il nodo Divieto).
func sbagliato(pos := Vector2.INF) -> void:
	fila = 0
	scuoti(scossa_sbagliato)
	Sound.sfx("deny", 0.85)
	if pos.is_finite():
		var d: Sprite2D = $Divieto.duplicate()
		add_child(d)
		d.position = pos
		d.visible = true
		d.scale = Vector2(1.6, 1.6)
		var tw := create_tween()
		tw.tween_property(d, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(d, "modulate:a", 0.0, 0.3).set_delay(0.35)
		tw.tween_callback(d.queue_free)


## Quante stelline (1-3): `errori`, e la parte di tempo che resta (0-1; -1 se il gioco non ha tempo).
func stelle(errori: int, tempo_rimasto := -1.0) -> int:
	if errori <= errori_per_3 and (tempo_rimasto < 0.0 or tempo_rimasto >= tempo_per_3):
		return 3
	return 2 if errori <= errori_per_2 else 1


## La festa della vittoria, poi le stelline. Il record di ogni gioco resta in GameState.flags.
func vittoria(quante: int, id: String) -> void:
	var chiave := "stelle_" + id
	var prima := int(GameState.flags.get(chiave, 0))
	if quante > prima:
		GameState.flags[chiave] = quante
	# un attimo fermo, che "pesa" (il timer conta il tempo vero anche a gioco rallentato)
	Engine.time_scale = 0.05
	await get_tree().create_timer(fermo_vittoria, true, false, true).timeout
	Engine.time_scale = 1.0
	scuoti(scossa_vittoria)
	_coriandoli.restart()
	_stelle.visible = true
	var scritta: Label = _stelle.get_node("Scritta")
	var record: Label = _stelle.get_node("Record")
	scritta.text = scritte[clampi(quante - 1, 0, scritte.size() - 1)]
	record.visible = false
	for i in 3:
		var spenta: Sprite2D = _stelle.get_node("Stella%d" % (i + 1))
		spenta.texture = stella_spenta
		spenta.modulate = colore_spenta
	_stelle.scale = Vector2(0.6, 0.6)
	create_tween().tween_property(_stelle, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_salta = false
	for i in quante:
		await get_tree().create_timer(0.28).timeout
		var st: Node2D = _stelle.get_node("Stella%d" % (i + 1))
		(st as Sprite2D).texture = stella_accesa
		st.modulate = Color.WHITE
		st.scale = Vector2(1.6, 1.6)
		create_tween().tween_property(st, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Sound.sfx("coin", 1.1 + 0.15 * i)
	if quante > prima and prima > 0:
		record.visible = true
		Sound.sfx("spare", 1.3)
	var resta := durata_stelle
	while resta > 0.0 and not _salta:
		await get_tree().process_frame
		resta -= get_process_delta_time()
	_stelle.visible = false



## Hai perso: le tre stelline compaiono lo stesso, tutte spente (0 stelle).
func zero() -> void:
	_stelle.visible = true
	(_stelle.get_node("Scritta") as Label).text = scritta_zero
	_stelle.get_node("Record").visible = false
	for i in 3:
		var spenta: Sprite2D = _stelle.get_node("Stella%d" % (i + 1))
		spenta.texture = stella_spenta
		spenta.modulate = colore_spenta
	_stelle.scale = Vector2(0.6, 0.6)
	create_tween().tween_property(_stelle, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_salta = false
	var resta := durata_stelle
	while resta > 0.0 and not _salta:
		await get_tree().process_frame
		resta -= get_process_delta_time()
	_stelle.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not _stelle.visible:
		return
	if event.is_action_pressed("confirm") or (event is InputEventScreenTouch and event.pressed) \
			or (event is InputEventMouseButton and event.pressed):
		_salta = true


## Una scritta che salta fuori e sale sparendo (la copia di un nodo modello, che resta nascosto).
func _sale(modello: Label, pos: Vector2, testo: String, grande := false) -> void:
	var l: Label = modello.duplicate()
	add_child(l)
	l.text = testo
	l.visible = true
	l.position = pos - l.size / 2.0 if not grande else pos
	l.pivot_offset = l.size / 2.0
	l.scale = Vector2(1.5, 1.5) if grande else Vector2.ONE
	var tw := create_tween().set_parallel()
	tw.tween_property(l, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y - (14.0 if grande else 18.0), 0.7).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.35).set_delay(0.45)
	tw.chain().tween_callback(l.queue_free)
