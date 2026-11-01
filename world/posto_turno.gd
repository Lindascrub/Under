class_name PostoTurno
extends Node2D
## Un posto di lavoro (world/posto_turno.tscn). Il nodo è l'angolo in alto a sinistra della casella.
##   PuntoUso    il punto da cui si comincia il turno
##   Targhetta   la scritta TURNO (font, grandezza e bordo si cambiano nella Label)
## Nei piani i figli sono modificabili: trascina PuntoUso e Targhetta dove servono.

## Il lavoro (id in data/worklist.json).
@export var job := ""
## Da che parte ci si deve avvicinare (per esempio "su": da sopra, dietro al bancone).
@export_enum("libero", "su", "giu", "sinistra", "destra") var avvicinamento := "libero"
## Dove deve guardare il giocatore per usarlo.
@export_enum("qualsiasi", "up", "down", "left", "right") var guarda_verso := "qualsiasi"
## Il colore della scritta finché c'è da lavorare, e quando il turno di oggi è finito.
@export var colore_da_fare := Color("ffe14d")
@export var colore_fatto := Color("8a8494")
## Di quanti pixel dondola la scritta, e in quanti secondi va su (e poi giù).
@export var dondolio := 3.0
@export var durata_dondolio := 0.4

const DIREZIONI := {"su": Vector2.UP, "giu": Vector2.DOWN, "sinistra": Vector2.LEFT, "destra": Vector2.RIGHT}


func direzione_avvicinamento() -> Vector2:
	return DIREZIONI.get(avvicinamento, Vector2.ZERO)


func verso_richiesto() -> String:
	return "" if guarda_verso == "qualsiasi" else guarda_verso


func setup_in_room(room: Room) -> void:
	var j := GameState.job(job)
	if j.is_empty():
		queue_free()
		return
	room.use_station(self, j)
