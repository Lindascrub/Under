extends CharSprite
## Comparsa seduta: il corpo resta solido e si può parlare senza occupare la sua sedia.
@export var battute: PackedStringArray = []
@export var nome := "Cliente in attesa"
func setup_in_room(_room: Room) -> void:
	var body := StaticBody2D.new()
	body.name = "CorpoSeduto"
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 9)
	shape.shape = rect
	shape.position = Vector2(0, -2)
	body.add_child(shape)
	add_child(body)
	var punto := Interactable.new()
	punto.name = "Parla"
	punto.interaction_bounds = Rect2(-7, -13, 14, 20)
	punto.reach = 14
	punto.action = func() -> void: await Ui.say(Array(battute), nome)
	add_child(punto)
	punto.add_to_group("walker")
