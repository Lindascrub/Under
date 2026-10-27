class_name Seat
extends Interactable
## Un posto dove sedersi (sedia, divano, panchina, sgabello): toccandolo ti siedi, muovendoti ti alzi.
## Il nodo sta sul bordo in basso del sedile; `dir` è dove guardi da seduto:
## left/right di profilo, down su una sedia vista di fronte, up di spalle (dietro lo schienale).

@export var dir := "down"
## Quanto è alto il sedile, in pixel.
@export var lift := 6.0
## Cosa si dice sedendosi (vuoto: niente, ti siedi e basta).
@export var line := ""


func interact() -> void:
	var p := get_tree().get_first_node_in_group("player") as Player
	if p == null or p.seated:
		return
	p.sit(global_position, dir, lift)
	Sound.sfx("select", 0.8)
	if line != "":
		await Ui.say([line])
