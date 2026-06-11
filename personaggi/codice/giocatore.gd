extends CharacterBody2D

const SPEED = 200.0

func _physics_process(_delta: float) -> void:
	# Il giocatore risponde sempre ai comandi, fin dal primo secondo!
	var direction = Vector2.ZERO
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		
	velocity = direction * SPEED
	move_and_slide()
