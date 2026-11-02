class_name Serranda
extends Node2D
## Una serranda che scende e chiude un passaggio per sempre.
## Telo: l'immagine (si srotola dall'alto). Muro: la collisione, accesa solo da chiusa.
## Avviso: la zona davanti; se ci vai contro da chiusa, dice `frase`.

@export_multiline var frase := "* Dietro di te, Teo e Olga ti fanno segno: vai."
## Secondi per scendere.
@export var durata := 0.6

var chiusa := false

@onready var _telo := $Telo as Sprite2D
@onready var _muro := $Muro/Forma as CollisionShape2D


func _ready() -> void:
	_telo.scale.y = 0.0
	_telo.visible = false
	_muro.set_deferred("disabled", true)
	($Avviso as Area2D).body_entered.connect(func(b: Node2D) -> void:
		if chiusa and b is Player and not Ui.blocks_input():
			Ui.say([frase])
	)


## Chiude la serranda. Con `anima` scende piano e sbatte; senza, è già giù.
func chiudi(anima := true) -> void:
	chiusa = true
	_muro.set_deferred("disabled", false)
	_telo.visible = true
	if not anima:
		_telo.scale.y = 1.0
		return
	Sound.sfx("strap", 0.6)
	var tw := create_tween()
	tw.tween_property(_telo, "scale:y", 1.0, durata).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await tw.finished
	Sound.sfx("crash", 0.7)
	var cam := get_viewport().get_camera_2d()
	if cam:
		var t2 := create_tween()
		# solo in orizzontale: l'altezza della telecamera la sposta già il riquadro del testo
		for i in 4:
			t2.tween_property(cam, "offset:x", 2.0 if i % 2 == 0 else -2.0, 0.04)
		t2.tween_property(cam, "offset:x", 0.0, 0.04)
		await t2.finished
