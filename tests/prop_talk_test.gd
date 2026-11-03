extends Node
## Verifica isolata delle interazioni automatiche con mobili, decorazioni e sedute.

var checks := 0
var failures: Array[String] = []
var room: Node2D
var mondo: Node2D
var decori: Node2D


func _ready() -> void:
	_build_fixture()
	PropTalk.apply(room)
	_test_generic_prop()
	_test_physical_prop()
	_test_composite_prop()
	_test_story_interaction_wins()
	_test_seat()
	_test_bank_chair_key()
	_test_idempotence()
	print("PROP TALK TEST: %d verifiche, errori %s" % [checks, str(failures)])
	get_tree().quit(failures.size())


func _build_fixture() -> void:
	room = load("res://tests/fixtures/prop_room.gd").new()
	room.name = "StanzaFinta"
	add_child(room)
	mondo = Node2D.new()
	mondo.name = "Mondo"
	room.add_child(mondo)
	decori = Node2D.new()
	decori.name = "Decori"
	room.add_child(decori)

	var plant := _sprite("PiantaDiPlastica", _test_texture(16, 24), Vector2(20, 30))
	mondo.add_child(plant)

	var table := _sprite("TavoloSoloFisico", load("res://art/c5/tavolo_lungo.png"), Vector2(70, 30))
	mondo.add_child(table)

	var composite := Node2D.new()
	composite.name = "ScaffaleComposto"
	composite.position = Vector2(120, 30)
	decori.add_child(composite)
	composite.add_child(_sprite("ParteAlta", _test_texture(16, 16), Vector2(0, -8)))
	composite.add_child(_sprite("ParteBassa", _test_texture(16, 16), Vector2(0, 8)))

	var story_prop := _sprite("ComputerDellaStoria", _test_texture(16, 16), Vector2(170, 30))
	mondo.add_child(story_prop)
	var special := Interactable.new()
	special.name = "InterazioneScrittaAMano"
	special.position = story_prop.position
	special.action = func() -> void: pass
	mondo.add_child(special)

	var chair := _sprite("SediaUfficio", load("res://assets/limezu/props/office_chair.png"), Vector2(220, 30))
	mondo.add_child(chair)

	var bank_chair := _sprite("PoltroncinaBanca", load("res://assets/limezu/bank/Conference_Hall_Singles_57.png"), Vector2(270, 30))
	mondo.add_child(bank_chair)


func _test_generic_prop() -> void:
	var prop := _inspect_for_key("")
	check(prop != null, "un oggetto senza scheda riceve un'interazione")
	if prop:
		check(prop.get_meta("inspect_prop_category") == "plant", "il nome riconosce la categoria pianta")
		check(prop.reach >= 12.0, "l'oggetto è raggiungibile senza precisione eccessiva")
		check(prop.interaction_bounds.has_area(), "si può usare tutta la sagoma visibile")


func _test_physical_prop() -> void:
	var prop := _inspect_for_key("art/c5/tavolo_lungo.png")
	check(prop != null, "un mobile con solo ingombro riceve anche una descrizione")
	check(not mondo.get_node("TavoloSoloFisico").find_children("*", "StaticBody2D", true, false).is_empty(), "l'interazione non elimina l'ingombro del tavolo")


func _test_composite_prop() -> void:
	var found := 0
	for prop in _inspect_props():
		if prop.global_position.x > 110.0 and prop.global_position.x < 140.0:
			found += 1
	check(found == 1, "un mobile composto riceve un solo punto d'esame")


func _test_story_interaction_wins() -> void:
	var found := 0
	for prop in _inspect_props():
		if prop.global_position.distance_to(Vector2(170, 30)) < 20.0:
			found += 1
	check(found == 0, "un'interazione narrativa non viene coperta da quella generica")


func _test_seat() -> void:
	var seats := mondo.find_children("*", "Seat", true, false)
	var office: Seat = null
	for seat: Seat in seats:
		if seat.global_position.distance_to(Vector2(220, 30)) < 30.0:
			office = seat
			break
	check(office != null, "la sedia da ufficio si può usare")
	if office:
		check(office.line != "", "la prima seduta ha una battuta")
		check(office.repeat_line != "", "la seconda seduta ha una risposta diversa")


func _test_bank_chair_key() -> void:
	var prop := _inspect_for_key("bank/Conference_Hall_Singles_57.png")
	check(prop != null, "la poltroncina della Banca usa la sua descrizione specifica")
	var near_seat := false
	for seat: Seat in mondo.find_children("*", "Seat", true, false):
		if seat.global_position.distance_to(Vector2(270, 30)) < 30.0:
			near_seat = true
	check(near_seat, "la poltroncina della Banca permette anche di sedersi")


func _test_idempotence() -> void:
	var before := _inspect_props().size() + mondo.find_children("*", "Seat", true, false).size()
	PropTalk.apply(room)
	var after := _inspect_props().size() + mondo.find_children("*", "Seat", true, false).size()
	check(after == before, "riapplicare il sistema non duplica le interazioni")


func _inspect_props() -> Array[Interactable]:
	var found: Array[Interactable] = []
	for node in get_tree().get_nodes_in_group("interactable"):
		if node is Interactable and node.get_meta("inspect_prop", false):
			found.append(node)
	return found


func _inspect_for_key(key: String) -> Interactable:
	for prop in _inspect_props():
		if str(prop.get_meta("inspect_prop_key", "")) == key:
			return prop
	return null


func _sprite(label: String, texture: Texture2D, at: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = label
	sprite.texture = texture
	sprite.position = at
	return sprite


func _test_texture(width: int, height: int) -> ImageTexture:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)
