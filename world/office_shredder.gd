@tool
extends Node2D
## Piccolo tritacarte sul reticolo dei mobili: 12×18, senza ingrandimenti.

func _draw() -> void:
	draw_rect(Rect2(4,-18,7,6),Color("373445"))
	draw_rect(Rect2(5,-17,5,5),Color("e9e5d5"))
	draw_rect(Rect2(6,-16,3,1),Color("a4a1a9"))
	draw_rect(Rect2(2,-14,12,14),Color("373445"))
	draw_rect(Rect2(3,-13,10,12),Color("858796"))
	draw_rect(Rect2(4,-10,8,8),Color("656674"))
	draw_rect(Rect2(4,-13,8,2),Color("31303c"))
	draw_rect(Rect2(5,-9,1,5),Color("cbc9c9"))
	draw_rect(Rect2(7,-8,1,5),Color("eeeadc"))
	draw_rect(Rect2(9,-9,1,5),Color("cbc9c9"))
	draw_rect(Rect2(4,-2,8,1),Color("a3a3af"))
