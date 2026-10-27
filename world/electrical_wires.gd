@tool
extends Node2D

const Art := preload("res://scripts/minigame_art.gd")
## Loose insulated leads with visible copper ends, rather than party ribbons.

func _draw() -> void:
	var routes := [
		[Vector2(1, 9), Vector2(4, 5), Vector2(9, 3), Vector2(17, 3), Vector2(23, 7), Vector2(25, 13), Vector2(22, 18), Vector2(15, 20), Vector2(9, 17), Vector2(9, 12), Vector2(16, 10), Vector2(28, 12), Vector2(39, 17)],
		[Vector2(4, 22), Vector2(10, 24), Vector2(18, 24), Vector2(26, 20), Vector2(30, 15), Vector2(28, 8), Vector2(22, 5), Vector2(17, 8), Vector2(17, 14), Vector2(23, 18), Vector2(33, 18), Vector2(40, 21)],
		[Vector2(2, 16), Vector2(6, 11), Vector2(12, 9), Vector2(20, 11), Vector2(24, 17), Vector2(22, 22), Vector2(15, 25), Vector2(7, 23)],
		[Vector2(35, 4), Vector2(29, 2), Vector2(24, 4), Vector2(22, 9), Vector2(25, 14), Vector2(33, 15), Vector2(39, 11), Vector2(39, 6), Vector2(35, 3)],
	]
	var colors := [Color("ba5155"), Color("548fae"), Color("d8b565"), Color("538c72")]
	for i in routes.size():
		Art.cable(self, PackedVector2Array(routes[i]), colors[i], 1.0, true)
