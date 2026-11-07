extends Node2D
## Scena narrativa senza punteggi: l'interfaccia dialoghi possiede la scelta.
const ART := preload("res://scripts/minigame_art.gd")
var destinazione := -1
var animata := false

func _ready() -> void:
	$Foglio.position = Vector2(310, 202)
	queue_redraw()

func consegna(indice: int) -> void:
	destinazione = indice
	var arrivo: Vector2 = [Vector2(110, 123), Vector2(310, 73), Vector2(510, 145)][indice]
	var tw := create_tween().set_parallel(true)
	tw.tween_property($Foglio, "position", arrivo, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if indice < 2:
		tw.tween_property($Foglio, "scale", Vector2(0.45, 0.45), 0.55)
		tw.tween_property($Foglio, "modulate:a", 0.0, 0.55)
	await tw.finished
	animata = true
	Sound.sfx("stamp" if indice == 0 else ("blip" if indice == 1 else "arcade/computer_1"))
	queue_redraw()

func testo(t: String, at: Vector2, size := 12, colore := ART.CREAM) -> void:
	draw_string(Assets.font(), at, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colore)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.05, 0.08, 0.9))
	ART.panel(self, Rect2(16, 12, 608, 228), Color("413b3f"), Color("a6a18d"))
	testo("CENTRALINO · LA TUA RICHIESTA", Vector2(34, 38), 17, ART.GOLD)
	# Cassetto: un volume fisico con bocca e maniglia, il foglio entra nella fessura.
	ART.panel(self, Rect2(64, 78, 92, 59), Color("626d78"))
	draw_rect(Rect2(73, 115, 74, 12), Color("1a202b"))
	draw_rect(Rect2(96, 91, 28, 5), Color("b5b9ae"))
	testo("ARCHIVIO", Vector2(76, 158), 12)
	# Tubo verso l'alto: invia il documento alla Direzione, non lo annulla.
	draw_rect(Rect2(295, 49, 30, 64), Color("202b35"))
	draw_rect(Rect2(301, 49, 18, 57), Color("80a3a2"))
	draw_rect(Rect2(284, 102, 52, 30), Color("516e78"))
	draw_rect(Rect2(290, 109, 40, 14), Color("15232e"))
	draw_polygon(PackedVector2Array([Vector2(304, 73), Vector2(316, 73), Vector2(316, 64), Vector2(322, 64), Vector2(310, 53), Vector2(298, 64), Vector2(304, 64)]), PackedColorArray([ART.CREAM]))
	testo("DIREZIONE", Vector2(275, 158), 12)
	# Stampante con carta in ingresso, rullo e vassoio: la copia esce da qui.
	draw_rect(Rect2(492, 62, 34, 36), ART.INK)
	draw_rect(Rect2(494, 64, 30, 33), ART.CREAM)
	for y in [71, 77, 83]: draw_rect(Rect2(498, y, 20, 2), Color("7b8b90"))
	draw_polygon(PackedVector2Array([Vector2(473, 97), Vector2(483, 88), Vector2(537, 88), Vector2(547, 97)]), PackedColorArray([Color("9ca8ad")]))
	ART.panel(self, Rect2(473, 96, 74, 37), Color("657784"))
	draw_rect(Rect2(483, 113, 54, 12), ART.INK)
	draw_rect(Rect2(488, 122, 44, 5), Color("a8b3b3"))
	draw_rect(Rect2(535, 102, 5, 4), Color("65d8c2"))
	testo("LA PORTO IO", Vector2(465, 158), 12)
	if animata:
		testo(["ARCHIVIATA", "INVIATA", "COPIA PER TE"][destinazione], Vector2(66 + destinazione * 197, 182), 11, ART.GOLD)
	else:
		testo("La proposta del sistema: ARCHIVIO.", Vector2(34, 225), 11, ART.GOLD)
