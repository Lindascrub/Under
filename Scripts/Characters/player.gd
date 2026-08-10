extends CharacterBody2D

@export var speed = 200

func _physics_process(delta):
	var input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input * speed
	move_and_slide()
	
	# Animazione semplice (ruota il quadrato nella direzione)
	if input != Vector2.ZERO:
		rotation = input.angle()
