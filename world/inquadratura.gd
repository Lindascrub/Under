@tool
class_name Inquadratura
extends Marker2D
## Un punto dove la telecamera va a guardare in una scena animata. Il centro dello schermo è qui.
## Nell'editor si vede il rettangolo inquadrato: spostalo e cambia lo zoom per cambiare la ripresa.

## Quanto si avvicina: 2 è lo zoom normale del gioco, più alto è più vicino.
@export_range(0.5, 6.0, 0.05) var zoom := 3.0:
	set(v):
		zoom = v
		queue_redraw()
## Secondi per arrivare qui.
@export_range(0.0, 10.0, 0.05) var durata := 0.75
## Secondi per tornare al giocatore.
@export_range(0.0, 10.0, 0.05) var durata_ritorno := 0.65
## Se la ripresa segue qualcuno che cammina (Nives che esce dallo sportello): quanto in fretta lo segue.
@export_range(0.0, 30.0, 0.5) var velocita_inseguimento := 7.0


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var view := Vector2(ProjectSettings.get_setting("display/window/size/viewport_width", 640),
		ProjectSettings.get_setting("display/window/size/viewport_height", 360)) / maxf(zoom, 0.01)
	draw_rect(Rect2(-view / 2.0, view), Color(1.0, 0.85, 0.2, 0.9), false, 1.0)
