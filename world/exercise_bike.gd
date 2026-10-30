@tool
extends Node2D
## Cyclette compatta sul reticolo del gioco: telaio, volano, sella e pedali leggibili a 1×.

const EDGE=Color("393647")
const STEEL=Color("9a9baa")

func _draw() -> void:
	draw_rect(Rect2(5,-2,20,2),EDGE)
	draw_rect(Rect2(7,-3,3,1),STEEL)
	draw_rect(Rect2(21,-3,3,1),STEEL)
	_link(Vector2(9,-3),Vector2(12,-17))
	_link(Vector2(12,-17),Vector2(19,-7))
	_link(Vector2(19,-7),Vector2(22,-21))
	_link(Vector2(10,-4),Vector2(19,-7))
	draw_polygon(PackedVector2Array([Vector2(12,-12),Vector2(19,-12),Vector2(23,-8),Vector2(23,-4),Vector2(19,-1),Vector2(12,-1),Vector2(9,-4),Vector2(9,-8)]),PackedColorArray([EDGE]))
	draw_rect(Rect2(12,-10,7,7),Color("777c8e"))
	draw_rect(Rect2(14,-9,4,5),Color("c4ad82"))
	draw_rect(Rect2(15,-7,2,2),EDGE)
	draw_rect(Rect2(7,-20,9,3),EDGE)
	draw_rect(Rect2(8,-20,7,1),Color("7d7584"))
	_link(Vector2(22,-21),Vector2(18,-23))
	draw_rect(Rect2(17,-24,5,2),EDGE)
	draw_rect(Rect2(9,-7,6,2),EDGE)
	draw_rect(Rect2(8,-5,4,2),Color("bbb6b0"))

func _link(a:Vector2,b:Vector2) -> void:
	draw_line(a,b,EDGE,3,false)
	draw_line(a,b,STEEL,1,false)
