@tool
extends Node2D
## Thin partition, short entrance return and full pier beside the stairwell.
## Dimensions match the native 16px room grid; caps expose the wall depth.
const INK := Color("34313f")
const CAP := Color("f4f2ee")
const FACE := Color("aaaeb3")
const SIDE := Color("7e828b")
const WALLS := [Rect2(368, 0, 6, 144), Rect2(368, 176, 6, 48), Rect2(368, 128, 32, 16), Rect2(496, 0, 16, 96)]

func _ready() -> void:
 set_meta("prop_talk_skip", true)
 z_index = 0
 for r: Rect2 in WALLS:
  var body := StaticBody2D.new()
  var collision := CollisionShape2D.new()
  var shape := RectangleShape2D.new()
  shape.size = r.size
  collision.shape = shape
  collision.position = r.get_center()
  body.add_child(collision)
  add_child(body)
 queue_redraw()

func _draw() -> void:
 # A six-pixel cut cap separates the rooms. The return has a visible front face.
 for r: Rect2 in WALLS:
  draw_rect(r, INK)
  draw_rect(r.grow(-1), CAP)
  if r.size.x >= 16:
   draw_rect(Rect2(r.position + Vector2(2, 6), r.size - Vector2(4, 7)), FACE)
   draw_rect(Rect2(r.position + Vector2(r.size.x - 3, 6), Vector2(2, r.size.y - 7)), SIDE)
   draw_line(r.position + Vector2(1, 5), r.position + Vector2(r.size.x - 2, 5), INK, 1)
