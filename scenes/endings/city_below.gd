extends Room
## Finale ricco: quello che si vede dalla finestra dell'attico.
## La stessa città, ma senza nessuno che la pulisca: spazzatura, baracche, gente seduta per terra.

const CITY := "tiles/city_terrains.png"
const SITTERS := [
	["char_14", Vector2i(4, 9), "sit_right"], ["char_15", Vector2i(10, 10), "sit_left"],
	["char_16", Vector2i(12, 9), "sit_right"], ["char_17", Vector2i(18, 10), "sit_left"],
	["char_18", Vector2i(19, 9), "sit_right"], ["char_19", Vector2i(6, 13), "sit_left"],
	["char_20", Vector2i(14, 13), "sit_right"],
]


func build() -> void:
	Ui.cutscene = true
	music = ""
	var rows: Array = []
	for y in 16:
		var row := ""
		for x in 24:
			var ch := "s"
			if y == 11:
				ch = "C"
			elif y == 12:
				ch = "r"
			row += ch
		rows.append(row)
	var sidewalk := {"tex": CITY, "at": func(c: Vector2i) -> Vector2i: return Vector2i(9 + c.x % 4, c.y % 4)}
	paint(rows, {
		"s": sidewalk,
		"C": {"tex": CITY, "at": Vector2i(1, 3)},
		"r": {"tex": CITY, "at": Vector2i(2, 5)},
		"_floor": sidewalk,
	})
	camera_top = 64
	add_prop("buildings/condo_dirty.png", Vector2i(1, 7), 0, Vector2i(96, 192))
	add_prop("street/shack.png", Vector2i(8, 7), 0, Vector2i(96, 96))
	add_prop("buildings/condo_dirty.png", Vector2i(15, 7), 0, Vector2i(96, 192))
	add_prop("street/dumpster_graffiti.png", Vector2i(21, 7), 0, Vector2i(32, 32))
	add_prop("street/trash_pile_1.png", Vector2i(6, 10), 0, Vector2i(64, 32))
	add_prop("street/trash_pile_2.png", Vector2i(13, 10), 0, Vector2i(64, 32))
	add_prop("street/trash_pile_3.png", Vector2i(20, 10), 0, Vector2i(64, 32))
	add_prop("street/car_wreck.png", Vector2i(2, 14), 0, Vector2i(64, 48))
	add_prop("street/scrap.png", Vector2i(17, 14), 0, Vector2i(80, 48))
	add_prop("street/trash_bags.png", Vector2i(10, 14), 0, Vector2i(32, 32))
	add_prop("street/trash_can_full.png", Vector2i(22, 14), 0, Vector2i(32, 48))
	for s: Array in SITTERS:
		add_prop("street/cardboard.png", s[1], 0, Vector2i(16, 16), [], Vector2(0, 2))
		var p := AnimatedSprite2D.new()
		p.sprite_frames = Assets.character(s[0])
		p.centered = false
		p.offset = Vector2(-8, -36)
		p.position = cell_feet(s[1]) + Vector2(0, 3)
		p.modulate = Color(0.8, 0.8, 0.85)
		p.play(s[2])
		world.add_child(p)
	var night := CanvasModulate.new()
	night.color = Color(0.5, 0.52, 0.7)
	add_child(night)
	spawns["default"] = cell_feet(Vector2i(12, 12))


func _ready() -> void:
	super()
	player.visible = false


func enter() -> void:
	await Ui.say([
		"* Sotto la torre, la città.",
		"* La spazzatura non la ritira più nessuno: il servizio è stato \"ottimizzato\".",
		"* Gente che dorme sui cartoni. Gente seduta per terra che non chiede più niente.",
		"* Sono le facce che salutavi ogni mattina. Quelle vere.",
	])
	Ui.cutscene = false
	Router.goto(Router.ENDING)
