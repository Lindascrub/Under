class_name Seat
extends Interactable
## Un posto dove sedersi (sedia, divano, panchina, sgabello): toccandolo ti siedi, muovendoti ti alzi.
## Il nodo sta sul bordo in basso del sedile; `dir` è dove guardi da seduto:
## left/right di profilo, down su una sedia vista di fronte, up di spalle (dietro lo schienale).

@export var dir := "down"
## Quanto è alto il sedile, in pixel.
@export var lift := 6.0
@export var low_pose := false
## Cosa si dice sedendosi (vuoto: niente, ti siedi e basta).
@export var line := ""
## Risposta breve dalle volte successive; vuoto: dopo la prima volta ci si siede senza dialogo.
@export var repeat_line := ""
var _used := false


## Le sedie stanno spesso dentro un divano o una fila di sedili: si toccano da un po' più lontano
## degli oggetti (14 invece di 8), se no non ci si arriva.
func _init() -> void:
	reach = 14.0


func interact() -> void:
	var p := get_tree().get_first_node_in_group("player") as Player
	if p == null or p.seated:
		return
	p.sit(global_position, dir, lift, low_pose)
	Sound.sfx("select", 0.8)
	var use := repeat_line if _used else line
	_used = true
	if use != "":
		await Ui.say([use])
