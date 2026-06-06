extends CharacterBody2D

# Velocità di movimento dell'omino
const SPEED = 200.0

func _physics_process(delta: float) -> void:
	# 1. Creiamo un vettore per capire dove vuole andare il giocatore
	var direction = Vector2.ZERO
	
	# 2. Controlliamo i tasti premuti (Freccette o WASD)
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	# 3. Normalizziamo il movimento (evita che l'omino vada più veloce in diagonale)
	if direction != Vector2.ZERO:
		direction = direction.normalized()
	
	# 4. Applichiamo la velocità e muoviamo il personaggio
	velocity = direction * SPEED
	move_and_slide()
