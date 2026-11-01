class_name SguardoIndietro
extends CanvasLayer
## Le scritte dello sguardo indietro di fine capitolo (world/sguardo_indietro.tscn): la frase in basso sulla
## striscia scura, poi il buio, qualche riga di premessa (facoltativa), il capitolo dopo e il suo titolo.
## Posizioni, font e colori sono nei nodi della scena; i tempi sono qui sotto, nell'Inspector.

## Secondi di silenzio sulla stanza inquadrata, prima della frase.
@export var attesa_iniziale := 0.8
## Quanto è scura la striscia sotto la frase (0 trasparente, 1 nera).
@export var opacita_striscia := 0.75
@export var comparsa_frase := 1.2
@export var attesa_frase := 4.0
@export var sparizione_frase := 0.8
@export var durata_buio := 1.0
@export var comparsa_premessa := 0.9
@export var pausa_premessa := 1.0
@export var attesa_premessa := 1.5
@export var sparizione_premessa := 0.8
@export var comparsa_titolo := 0.8
@export var pausa_sottotitolo := 0.4
@export var comparsa_sottotitolo := 1.0
@export var attesa_titolo := 2.0
@export var attesa_titolo_con_sottotitolo := 2.5

@onready var _striscia: ColorRect = $Striscia
@onready var _buio: ColorRect = $Buio
@onready var _frase: Label = $Frase
@onready var _premessa: Container = $Premessa
@onready var _capitolo: Label = $Capitolo
@onready var _titolo: Label = $Titolo
@onready var _sottotitolo: Label = $Sottotitolo


func _ready() -> void:
	_striscia.color.a = 0.0
	_buio.color.a = 0.0
	for l: CanvasItem in [_frase, _capitolo, _titolo, _sottotitolo]:
		l.modulate.a = 0.0
	for c in _premessa.get_children():
		(c as CanvasItem).visible = false


func frase(line: String) -> void:
	await get_tree().create_timer(attesa_iniziale).timeout
	_frase.text = line
	var a := create_tween().set_parallel()
	a.tween_property(_striscia, "color:a", opacita_striscia, comparsa_frase)
	a.tween_property(_frase, "modulate:a", 1.0, comparsa_frase)
	await a.finished
	await get_tree().create_timer(attesa_frase).timeout


func buio() -> void:
	var b := create_tween()
	b.tween_property(_frase, "modulate:a", 0.0, sparizione_frase)
	b.tween_property(_buio, "color:a", 1.0, durata_buio)
	await b.finished


## Qualche riga sul buio prima del titolo: la prima ha lo stile di Premessa/Prima, le altre di Premessa/Altra.
func premessa(lines: Array) -> void:
	var first := _premessa.get_child(0) as Label
	var other := _premessa.get_child(1) as Label
	var shown: Array[Label] = []
	for i in lines.size():
		var l: Label = first if i == 0 else (other if i == 1 else other.duplicate() as Label)
		if i > 1:
			_premessa.add_child(l)
		l.text = str(lines[i])
		l.modulate.a = 0.0
		l.visible = true
		shown.append(l)
	for l in shown:
		var f := create_tween()
		f.tween_property(l, "modulate:a", 1.0, comparsa_premessa)
		Sound.sfx("blip", 0.8)
		await f.finished
		await get_tree().create_timer(pausa_premessa).timeout
	await get_tree().create_timer(attesa_premessa).timeout
	var g := create_tween().set_parallel()
	for l in shown:
		g.tween_property(l, "modulate:a", 0.0, sparizione_premessa)
	await g.finished


func titolo(chapter: String, title: String, subtitle := "") -> void:
	_capitolo.text = chapter
	_titolo.text = title
	_sottotitolo.text = subtitle
	var c := create_tween()
	c.tween_property(_capitolo, "modulate:a", 1.0, comparsa_titolo)
	c.tween_property(_titolo, "modulate:a", 1.0, comparsa_titolo)
	Sound.sfx("stamp", 0.8)
	if subtitle != "":
		c.tween_interval(pausa_sottotitolo)
		c.tween_property(_sottotitolo, "modulate:a", 1.0, comparsa_sottotitolo)
	await c.finished
	await get_tree().create_timer(attesa_titolo_con_sottotitolo if subtitle != "" else attesa_titolo).timeout
