class_name PannelloRighe
extends CanvasLayer
## Un pannello che compare sopra il gioco e scrive delle righe una alla volta (le rivelazioni del primo gradino).
## La scena ha `Pannello` (quello che compare e sparisce) e dentro `Righe`: le Label sono già impostate
## nella scena (font, colore, dimensione, distanza). Lo script cambia solo il testo e quando compaiono.
## Se servono più righe di quelle nella scena, copia l'ultima. `Simboli` (facoltativo) compaiono uno alla volta.

## Secondi perché il pannello compaia e sparisca.
@export var durata_comparsa := 0.6
@export var durata_scomparsa := 0.8
## Secondi fra una riga e la successiva.
@export var pausa_tra_righe := 0.7
## Secondi di attesa dopo l'ultima riga.
@export var pausa_dopo_righe := 1.2
## Secondi fra un simbolo e il successivo.
@export var pausa_tra_simboli := 0.5
## Il colore delle righe importanti (le altre hanno il colore della Label nella scena).
@export var colore_evidenza := Color("ff5a50")

@onready var pannello: CanvasItem = $Pannello
@onready var righe: Node = $Pannello/Righe
## Il colore normale delle righe: quello della prima Label nella scena.
var _colore_riga := Color.WHITE


func _ready() -> void:
	pannello.modulate.a = 0.0
	_colore_riga = (righe.get_child(0) as Label).get_theme_color("font_color")
	for c in righe.get_children():
		(c as CanvasItem).visible = false
	var simboli := get_node_or_null("Pannello/Simboli")
	if simboli:
		for c in simboli.get_children():
			(c as CanvasItem).visible = false


func appari() -> void:
	var tw := create_tween()
	tw.tween_property(pannello, "modulate:a", 1.0, durata_comparsa)
	await tw.finished


## Scrive le righe una alla volta. `evidenziate`: gli indici delle righe col colore_evidenza.
func scrivi(lines: Array, evidenziate: Array = []) -> void:
	for i in lines.size():
		var l: Label
		if i < righe.get_child_count():
			l = righe.get_child(i) as Label
		else:
			l = righe.get_child(righe.get_child_count() - 1).duplicate() as Label
			righe.add_child(l)
		l.text = str(lines[i])
		l.add_theme_color_override("font_color", colore_evidenza if i in evidenziate else _colore_riga)
		l.visible = true
		Sound.sfx("blip", 1.3)
		await get_tree().create_timer(pausa_tra_righe).timeout
	await get_tree().create_timer(pausa_dopo_righe).timeout


func mostra_simboli() -> void:
	var simboli := get_node_or_null("Pannello/Simboli")
	if simboli == null:
		return
	for i in simboli.get_child_count():
		(simboli.get_child(i) as CanvasItem).visible = true
		Sound.sfx("blip", 1.0 + i * 0.1)
		await get_tree().create_timer(pausa_tra_simboli).timeout


func scompari() -> void:
	var tw := create_tween()
	tw.tween_property(pannello, "modulate:a", 0.0, durata_scomparsa)
	await tw.finished
	queue_free()
