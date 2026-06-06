extends Node

# Queste sono le variabili (i cassetti della memoria del gioco)
var debito = 100.0
var fame = 100.0 # 100 significa pancia piena, 0 significa che stai morendo di fame

# Questo è il tempo: ogni secondo che passa, succedono queste cose
func _process(delta):
	# Se la fame è maggiore di zero, il tempo scorre!
	if fame > 0:
		debito = debito + (0.5 * delta) # Il debito sale di 50 centesimi al secondo per gli interessi
		fame = fame - (0.2 * delta)    # La fame scende (il personaggio ha sempre più fame)
	else:
		fame = 0
		# Qui in futuro metteremo il Game Over per fame!
