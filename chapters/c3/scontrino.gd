extends CanvasLayer
## Lo scontrino che scende dalla fessura e si srotola sullo schermo (chapters/c3/scontrino.tscn).
## Carta e testo sono nodi della scena: larghezza, colori, font e posizione orizzontale si cambiano lì.
## L'altezza dipende da quante righe ha lo scontrino.

## Secondi per scendere.
@export var durata_discesa := 3.0
## Dove si ferma il bordo in alto della carta (pixel dall'alto dello schermo).
@export var arrivo_y := 8.0
## Secondi per sparire.
@export var durata_scomparsa := 0.8
## Altezza di ogni riga di testo, e spazio bianco sopra e sotto il testo (in tutto).
@export var altezza_riga := 15.0
@export var spazio_carta := 24.0

@onready var _carta: Control = $Carta
@onready var _testo: Label = $Carta/Testo


func srotola(lines: Array) -> void:
	_testo.text = "\n".join(lines)
	_carta.size.y = spazio_carta + lines.size() * altezza_riga
	_testo.size.y = _carta.size.y - (spazio_carta - 4.0)
	_carta.position.y = -_carta.size.y
	var tw := create_tween()
	tw.tween_property(_carta, "position:y", arrivo_y, durata_discesa).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func scompari() -> void:
	var tw := create_tween()
	tw.tween_property(_carta, "modulate:a", 0.0, durata_scomparsa)
	await tw.finished
	queue_free()
