@tool
extends Node2D

@export var broken := false:
	set(value):broken=value;queue_redraw()

@export_enum("sorridi","modulo","attesa") var kind := "sorridi":
	set(value):kind=value;queue_redraw()

## Le righe scritte sul manifesto (vuoto = quelle del tipo). Se una riga non ci sta, il carattere si rimpicciolisce.
@export var righe: PackedStringArray = []:
	set(value):righe=value;queue_redraw()

## Grandezza del carattere (si abbassa da sola se il testo non ci sta).
@export_range(5, 16) var carattere := 8:
	set(value):carattere=value;queue_redraw()

func paper_size() -> Vector2:
	return Vector2(72,32) if kind=="modulo" else Vector2(64 if kind=="attesa" else 56,24)

func _ready() -> void:
	z_index = 0
	# la collisione è il figlio "PareteManifesto" nella scena (si vede e si cambia nell'editor);
	# se manca (un manifesto aggiunto a mano) la crea qui
	if Engine.is_editor_hint() or has_node("PareteManifesto"):return
	var size := paper_size()
	var body := StaticBody2D.new()
	body.name = "PareteManifesto"
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	shape.position = Vector2(size.x/2,-size.y/2)
	body.add_child(shape);add_child(body)

func _draw() -> void:
	var size := paper_size()
	var paper := Color("e4d5a5")
	var ink := Color("5a3740")
	var lines: Array[String] = ["SORRIDI!","È GRATIS"]
	if kind=="modulo":
		paper=Color("c4d5d5");ink=Color("354e5d")
		lines=["UN MODULO AL","GIORNO TOGLIE","IL PENSIERO"]
	elif kind=="attesa":
		paper=Color("ddbbb2");ink=Color("5b3c4d")
		lines=["RESTI","IN LINEA!"]
	var area := Rect2(Vector2(0,-size.y),size)
	draw_rect(area,Color("393745"))
	draw_rect(area.grow(-1),paper)
	draw_rect(Rect2(2,-size.y+2,size.x-4,2),ink)
	draw_rect(Rect2(2,-2,size.x-4,1),ink)
	# I chiodini restano al loro posto anche nella versione consumata.
	for x in [3.0,size.x-5]:
		draw_rect(Rect2(x,-size.y+1,2,2),Color("807a70"))
		draw_rect(Rect2(x,-size.y+1,1,1),Color("e9e1c9"))
	if not righe.is_empty():
		lines.assign(righe)
	# il carattere più grande con cui tutte le righe stanno dentro la carta (sotto la striscia in alto)
	var font := Assets.font()
	var fs := carattere
	while fs > 5:
		var wide := false
		for line in lines:
			wide = wide or font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x > size.x-6
		if not wide and _text_height(lines.size(),fs,fs) <= size.y:
			break
		fs -= 1
	# righe staccate di un pixel, se c'è posto
	var step := fs+1 if _text_height(lines.size(),fs,fs+1) <= size.y else fs
	var baseline := -size.y+fs+3
	for line in lines:
		draw_string(font,Vector2(3,baseline),line,HORIZONTAL_ALIGNMENT_CENTER,size.x-6,fs,ink)
		baseline += step
	if broken:
		# Angoli sfrangiati, piega e abrasioni: nessuna caduta o rotazione.
		draw_rect(Rect2(0,-5,2,5),Color("77766f"))
		draw_rect(Rect2(2,-2,3,2),Color("77766f"))
		draw_line(Vector2(size.x-6,-size.y+5),Vector2(size.x-8,-4),paper.darkened(0.22),1)
		draw_rect(Rect2(size.x-4,-size.y+5,2,3),paper.darkened(0.3))
		for at in [Vector2(4,-size.y+7),Vector2(size.x-5,-7),Vector2(7,-5)]:
			draw_rect(Rect2(at,Vector2(2,1)),paper.darkened(0.35))

## Quanto è alto il testo, dalla striscia in alto alla riga in basso.
func _text_height(n:int,fs:int,step:int) -> int:
	return fs+3+(n-1)*step+4
