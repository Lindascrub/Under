class_name Room
extends Node2D
## Base di tutte le stanze. Una stanza figlia scrive build() usando:
##   paint(righe, legenda)  -> disegna la mappa da una griglia di caratteri
##   add_prop / add_npc / add_spot / add_exit / block
## e può scrivere enter() per i dialoghi all'ingresso.

const T := 16
## Area visibile del mondo con lo zoom 2x della camera.
const VIEW := Vector2(320, 180)

var map_size := Vector2i.ZERO
## Caratteri della mappa non presenti in legenda: carattere -> celle (per piazzare cose).
var markers: Dictionary = {}
## Punti di arrivo: nome -> posizione dei piedi del giocatore.
var spawns: Dictionary = {}
var spawn_facing: Dictionary = {}
## Quanto la camera può salire sopra la mappa (per mostrare edifici alti).
@export var camera_top := 0
## Cosa può inquadrare la telecamera (in pixel): mai il nero fuori dalla mappa.
## Se resta vuoto si usa tutta la mappa (più camera_top sopra).
var cam_rect := Rect2()
## Sposta la visuale verso l'alto (per vedere gli edifici sullo sfondo), in pixel.
@export var camera_lift := 0
## La visuale sale quando il giocatore è sopra questa riga di caselle...
@export var camera_lift_riga := 10.0
## ...e arriva al massimo dopo queste righe.
@export var camera_lift_righe := 4.0
## Musica della stanza (vedi Sound.music) e se è all'aperto (la luce cambia con l'ora).
var music := "quartiere"
var outdoor := false
## Il piano della torre in cui si trova la stanza ("" per le stanze fuori dalla torre).
var floor_id := ""
var player: Player
## Contenitore con y-sort: oggetti e persone si coprono nel giusto ordine.
var world: Node2D

var _tiles: TileMapLayer
var _tileset: TileSet
var _sources: Dictionary = {}
var _solids: StaticBody2D
var _light: CanvasModulate
## Caselle bloccate da muri e oggetti, e caselle già occupate da persone (per non sovrapporle).
var _blocked_cells := {}
var _people_cells := {}
var _grey_rect: ColorRect
var _stairs_up_pos := Vector2.INF
var _stairs_down_pos := Vector2.INF
## Dove finiscono gli scalini: si esce dritti fin lì, poi si gira.
var _stairs_up_exit := Vector2.INF
var _stairs_down_exit := Vector2.INF
## Le scale (per abbassare la luce mentre le fai) e i tornelli chiusi.
var _stair_zones: Array[Dictionary] = []
var _stair_gates: Array[Dictionary] = []
var _descending_stairs := false
const BadgeBoothScript = preload("res://world/badge_booth.gd")
const BadgeBoothScene = preload("res://world/badge_booth.tscn")
const StairsUpScene = preload("res://world/stairs_up.tscn")
## Il giocatore: una scena vera (sprite, ombra, collisione e telecamera si cambiano lì).
const PLAYER_SCENE := "res://scripts/player.tscn"
const StairsDownScene = preload("res://world/stairs_down.tscn")
const TicketGateScript = preload("res://world/ticket_gate.gd")
var _badge_booth: BadgeBoothScript


func _ready() -> void:
	_tiles = TileMapLayer.new()
	_tileset = TileSet.new()
	_tileset.tile_size = Vector2i(T, T)
	_tiles.tile_set = _tileset
	add_child(_tiles)
	_solids = StaticBody2D.new()
	add_child(_solids)
	# le stanze fatte nell'editor hanno già il loro nodo "Mondo" (ordinato per y)
	if has_node("Mondo"):
		world = get_node("Mondo")
	else:
		world = Node2D.new()
		world.y_sort_enabled = true
		add_child(world)
	build()
	GameState.room_floor = floor_id
	if floor_id != "":
		GameState.enter_floor(floor_id)
	_spawn_player()
	after_spawn()
	# ogni oggetto si può guardare, ogni sedia usare (data/props.json)
	PropTalk.apply(self)
	var arrive_to := _prepare_arrival()
	Ui.show_hud(true)
	Sound.music(music)
	_grey_world()
	if outdoor:
		_light = CanvasModulate.new()
		add_child(_light)
		_update_light()
		GameState.changed.connect(_update_light)
	if Ui.transitioning:
		await Ui.faded_in
	if arrive_to != Vector2.INF:
		await _do_arrival(arrive_to)
	enter()


func build() -> void:
	pass


## Subito dopo aver messo il giocatore nella stanza, prima che lo schermo si accenda.
func after_spawn() -> void:
	pass


## Più alto è il LV, più il mondo perde colore. I dialoghi e l'HUD restano a colori.
func _grey_world() -> void:
	if GameState.exploited <= 0 or player == null:
		return
	grey_world_to(minf(0.85, GameState.exploited * 0.22))


## Porta il grigio del mondo a `amount` (0 = colori, 1 = tutto grigio), piano piano se `time` > 0.
const GREY_Z := 100


func grey_world_to(amount: float, time := 0.0) -> void:
	if _grey_rect == null:
		# Attaccato alla telecamera e sopra a tutto il mondo (ma sotto l'interfaccia, che sta in un altro strato).
		var rect := ColorRect.new()
		rect.size = VIEW + Vector2(8, 8)
		rect.position = -rect.size / 2.0
		rect.z_index = GREY_Z
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/grey_world.gdshader")
		mat.set_shader_parameter("amount", 0.0)
		rect.material = mat
		add_child(rect)
		_grey_rect = rect
		if player:
			_grey_rect.global_position = player.camera.get_screen_center_position() - _grey_rect.size / 2.0
	var m := _grey_rect.material as ShaderMaterial
	amount = maxf(amount, float(m.get_shader_parameter("amount")))
	if time <= 0.0:
		m.set_shader_parameter("amount", amount)
	else:
		create_tween().tween_property(m, "shader_parameter/amount", amount, time)


## Il filtro grigio segue quello che inquadra la telecamera (anche ai bordi della mappa).
func _process(_delta: float) -> void:
	if is_instance_valid(_clerk_camera_actor) and is_instance_valid(player):
		player.camera.global_position = player.camera.global_position.lerp(_clerk_camera_actor.global_position + _clerk_camera_offset, minf(1.0, _delta * _clerk_camera_speed))
	if player and not _descending_stairs and not _stair_zones.is_empty():
		var shade := 0.0
		for z: Dictionary in _stair_zones:
			var r: Rect2 = z["rect"]
			if r.grow(2).has_point(player.position):
				var f := (r.end.y - player.position.y) / r.size.y if z["up"] else (player.position.y - r.position.y) / r.size.y
				shade = maxf(shade, clampf(f, 0.0, 1.0))
		player.set_shade(shade)
	if camera_lift > 0 and player and not player.camera.top_level:
		var t := clampf((camera_lift_riga * T - player.position.y) / (camera_lift_righe * T), 0.0, 1.0)
		player.camera.offset.y = lerpf(player.camera.offset.y, -camera_lift * t, 0.1)
	if _grey_rect and player:
		_grey_rect.global_position = player.camera.get_screen_center_position() - _grey_rect.size / 2.0


func _update_light() -> void:
	if _light:
		_light.color = GameState.daylight()


func enter() -> void:
	await show_pending()


func show_pending() -> void:
	if not GameState.pending_lines.is_empty():
		var lines := GameState.pending_lines.duplicate()
		GameState.pending_lines.clear()
		await Ui.say(lines)
	if GameState.boss_call_pending():
		var score := Sound.capture_music()
		Sound.music("capo")
		await _boss_call()
		if Ui.transitioning:
			return
		Sound.restore_music(score)
	if floor_id != "" and GameState.pity_pending():
		await _pity_offer()
	await _floor_gift()


## Il posto di lavoro del lavoro assegnato oggi, se si trova in questa stanza.
func add_station(room_key: String) -> void:
	for j: Dictionary in GameState.jobs_available():
		if j.get("room", "") != room_key:
			continue
		add_station_at(j, Vector2i(int(j["station"][0]), int(j["station"][1])))


## Il posto di lavoro: la scena world/posto_turno.tscn (nei piani fatti nell'editor è già nella scena).
const POSTO_TURNO := "res://world/posto_turno.tscn"
const STELLINA := "res://world/stellina.tscn"
## Le persone: la scena scripts/npc.tscn.
const NPC_SCENE := "res://scripts/npc.tscn"


## Un posto di lavoro in una casella precisa (per le stanze fatte col codice).
func add_station_at(j: Dictionary, cell: Vector2i) -> void:
	var posto := load(POSTO_TURNO).instantiate() as PostoTurno
	posto.job = str(j.get("id", ""))
	posto.position = Vector2(cell * T)
	add_child(posto)
	use_station(posto, j)


## Accende un posto di lavoro: la targhetta "TURNO" resta sempre, gialla e dondolante finché
## c'è da lavorare, grigia e ferma quando il turno di oggi è finito.
func use_station(posto: PostoTurno, j: Dictionary) -> void:
	var mark := posto.get_node("Targhetta") as Label
	mark.add_theme_color_override("font_color", posto.colore_fatto if GameState.worked_today else posto.colore_da_fare)
	if not GameState.worked_today:
		var tw := mark.create_tween().set_loops()
		tw.tween_property(mark, "position:y", mark.position.y - posto.dondolio, posto.durata_dondolio)
		tw.tween_property(mark, "position:y", mark.position.y, posto.durata_dondolio)
	var jj := j
	var spot := add_spot((posto.get_node("PuntoUso") as Node2D).global_position, func() -> void: _station(jj))
	spot.set_meta("job_id", str(j.get("id", "")))
	spot.approach = posto.direzione_avvicinamento()
	spot.facing_required = posto.verso_richiesto()


func _station(j: Dictionary) -> void:
	var missions = load("res://scripts/boss_missions.gd")
	if missions.active(GameState.floor_id):
		var action: int = await Ui.choose("Postazione di lavoro / incarico del Capo in sospeso.", ["Riprendi l'incarico", "TURNO ordinario", "Indietro"])
		if action == 0:
			missions.launch(self, GameState.floor_id)
			return
		if action == 2:
			return
	if GameState.worked_today:
		await Ui.say(["* " + str(j.get("station_text", "Un posto di lavoro.")),
			"* (Per oggi hai già dato. Il prossimo turno è domani: tocca una stellina e scegli di lasciar passare la notte.)"])
		return
	var c: int = await Ui.choose(str(j.get("station_text", "")) + "\nIniziare il turno? (10 ore)", ["Inizia", "Non ancora"])
	if c != 0:
		return
	start_job(j)


## Parte il turno (il minigioco, o la battaglia col caporeparto). Senza domande: le fa _station().
func start_job(j: Dictionary) -> void:
	var cfg: Dictionary = (j.get("battle", {}) as Dictionary).duplicate(true)
	if j.has("game"):
		# la paga cresce un po' a ogni piano, tranne nei lavori a paga fissa ("pay_fixed": la cassa del -3)
		var pay := int(cfg.get("pay", 300))
		if not j.get("pay_fixed", false):
			pay = int(pay * (1.0 + 0.1 * GameState.floor_index(GameState.floor_id)))
		GameState.minigame = {
			"kind": "work", "game": j["game"], "name": str(j.get("title", "Il turno")),
			"pay": pay, "job": cfg,
			"intro": [str(cfg.get("intro", "* Si comincia."))],
			"tired": str(cfg.get("tired", "* Ti fa male tutto.")),
			"return": scene_file_path, "return_pos": player.global_position,
		}
		Router.goto(Router.WORK)
		return
	# ogni tanto il caporeparto ti sta addosso: il turno diventa una battaglia
	cfg["intro"] = "* Oggi il caporeparto ti sta addosso. Ogni tuo movimento è un problema.\n" + str(cfg.get("intro", ""))
	cfg["kind"] = "work"
	cfg["return"] = scene_file_path
	cfg["return_pos"] = player.global_position
	Router.battle(cfg)


## Chi, su ogni piano, ha pena di te: [nome, foglio, frasi, fregatura]. La fregatura è quello che
## la pietà ti costa (Vito vuole aiuto gratis, il Signor Tasso la chiama "contributo" ma è un prestito).
const PITY := {
	"-5": ["Fermo", "cheap_fermo", [
		"Ti ho visto. Tre giorni. Pedali, cadi, ti rialzi, cadi.",
		"Tieni. Sono i soldi della mia cassetta. Li tenevo per il funerale.",
		"Tanto, a quanto pare, non mi serve un funerale. Mi serve che almeno uno di noi salga.",
	], "fermo"],
	"-4": ["Signora Agenda", "char_20", [
		"Oh, poverino! Tre giorni senza finire un turno. Mi si stringe il cuore. Davvero. Ce l'ho, un cuore.",
		"Tieni: è la cassa dei premi di produzione. Tanto nessuno li vince mai.",
		"Lo scriverò nel registro, però: \"Aiutato per pietà\". Lo scrivo sempre. Lo leggono tutti.",
	], "registro"],
	"-3": ["Vito", "char_03", [
		"Ehi, tu. Ti ho visto crollare tre volte. Al mio banco si dice: chi cade tre volte, o è stupido o è sfortunato.",
		"Tu mi sembri sfortunato. Tieni, l'incasso di oggi.",
		"Ma da domani, quando passi, mi dai una mano al banco. Gratis. Così siamo pari. Più o meno.",
	], "vito"],
	"-2": ["Signor Tasso", "char_04", [
		"La banca ha notato le sue... difficoltà. La banca nota tutto.",
		"Le concediamo un contributo di solidarietà. Firmi qui. E qui.",
		"È un prestito, naturalmente. Ma lo chiamiamo contributo: suona più caldo.",
	], "prestito"],
	"0": ["Giulia", "", [
		"Senti. Prendili e non dire niente a nessuno.",
		"Quassù la pietà è vietata dal regolamento. Articolo dodici: \"Non si aiutano i deboli, li si ottimizza\".",
		"Se lo scoprono, la prossima che crolla sono io.",
	], "giulia"],
}


## Dopo tre giorni di seguito di turni falliti: qualcuno del piano ti offre i soldi che mancano,
## e il Signor Rata, dell'ufficio contratti, ti offre il badge subito, in cambio di una firma.
func _pity_offer() -> void:
	var need := GameState.floor_above()
	var missing := GameState.money_missing()
	var cost := GameState.badge_cost(need)
	var p: Array = PITY.get(floor_id, PITY["-5"])
	var who := str(p[0])
	await Ui.say(["* %s ti chiama. Ha la faccia di chi ti guarda da tre giorni." % who])
	await Ui.say(p[2], who, str(p[1]))
	# il Signor Rata arriva sempre al momento giusto. Cioè quello peggiore.
	# (world/signor_rata.tscn: il nodo è dove sei tu, lo Sprite è dove compare lui)
	var rata := load("res://world/signor_rata.tscn").instantiate() as Node2D
	rata.position = player.position
	rata.modulate.a = 0.0
	world.add_child(rata)
	var tw := rata.create_tween()
	tw.tween_property(rata, "modulate:a", 1.0, 0.4)
	Sound.sfx("stamp")
	await Ui.say(["...Oppure.", "Signor Rata, ufficio contratti. Lei è {name}, lo so: so il nome di tutti quelli che firmano. Somiglio al Dottor Prezzi, lo so. Me lo dicono tutti. Forse siamo parenti. Forse no.",
		"Perché accettare la pietà, che è umiliante, quando può firmare un contratto, che è dignitoso?",
		"Il badge del %s, adesso, subito. Senza un centesimo." % GameState.floor_name(need),
		"Clausola uno: il prezzo, più la metà, va sul suo debito. Clausola due: gli interessi di ogni notte salgono un pochino. Pochino.",
		"Clausola tre la trova in fondo. Scritta piccola. Piccolissima. Non la legge nessuno."], "Signor Rata", "char_18")
	var c: int = await Ui.choose("Cosa fai? Ti mancano %s per il badge (%s)." % [GameState.euros(missing), GameState.euros(cost)],
		["Accetta i soldi di %s" % who, "Firma il contratto del Signor Rata", "Rifiuta tutti e due"])
	GameState.flags["fail_streak"] = 0
	match c:
		0:
			GameState.money += missing
			GameState.flags["pity_" + str(p[3])] = true
			GameState.flags["pity_count"] = int(GameState.flags.get("pity_count", 0)) + 1
			if str(p[3]) == "prestito":
				GameState.debt += missing
			Sound.sfx("coin")
			await Ui.say(["...Bene. Lei ha scelto la pietà. Ci rivedremo, quando la pietà sarà finita. Finisce sempre."], "Signor Rata", "char_18")
			await Ui.say(["* Hai ricevuto %s. Ora puoi comprare il badge." % GameState.euros(missing)])
		1:
			GameState.sign_contract()
			Sound.sfx("stamp")
			await Ui.say(["Firmato! Ecco il suo badge. Le sta benissimo.", "Clausola tre: \"Il firmatario riconosce che salire in fretta ha un prezzo. Il prezzo lo decidiamo noi. Dopo.\"",
				"Arrivederci. Ci vediamo al prossimo piano. Ci vediamo sempre al prossimo piano."], "Signor Rata", "char_18")
			await Ui.say(["* Hai il badge del %s. Debito: {debt}." % GameState.floor_name(need)])
		_:
			await Ui.say(["Rifiuta? Interessante. Nessuno rifiuta mai tutti e due.", "Lo scriverò da qualche parte. Non si preoccupi: io scrivo sempre da qualche parte."], "Signor Rata", "char_18")
			GameState.flags["pity_refused"] = int(GameState.flags.get("pity_refused", 0)) + 1
	var tw2 := rata.create_tween()
	tw2.tween_property(rata, "modulate:a", 0.0, 0.5)
	tw2.tween_callback(rata.queue_free)


## La promozione è un furto: copiare il lavoro di `victim` quando non guarda (minigioco "steal").
## `extra` sovrascrive la configurazione (per esempio "intro", o "win_flag": allora vincere non
## promuove subito, ma accende quel flag e la stanza decide cosa succede dopo).
func start_steal(victim: String, promo: Dictionary, extra := {}) -> void:
	var data := GameState.npc_data(victim)
	var who := str(data.get("name", promo.get("victim_name", "il collega")))
	GameState.minigame = {
		"kind": "steal", "game": "steal", "name": str(promo.get("title", "Il merito degli altri")),
		"victim": victim, "victim_name": who, "victim_sheet": str(data.get("sheet", promo.get("victim_sheet", "char_02"))),
		"seated": victim == "fermo",
		"item": str(promo.get("item", "il lavoro di " + who)),
		"intro": ["* %s è alla sua scrivania. Davanti a lui, %s." % [who, str(promo.get("item", "il suo lavoro"))],
			"* Nessuno ti ha visto entrare. Per ora."],
		"return": scene_file_path, "return_pos": player.global_position,
	}
	GameState.minigame.merge(extra, true)
	Router.goto(Router.WORK)


## Se hai aiutato tutti quelli del piano, l'addetta ai badge te lo regala (e il tornello si apre).
var _clerk_camera_actor: Node2D
var _clerk_camera_offset := Vector2.ZERO
var _clerk_camera_speed := 7.0


func _floor_gift() -> void:
	if floor_id == "" or not GameState.floor_all_helped(floor_id):
		return
	var need := GameState.floor_above(floor_id)
	if need == "" or GameState.has_badge(need) or GameState.flags.get("gift_" + floor_id, false):
		return
	GameState.flags["gift_" + floor_id] = true
	var who := "Addetta ai badge"
	var first_friend: bool = not GameState.flags.get("clerk_friend", false)
	GameState.flags["clerk_friend"] = true
	GameState.badges.append(need)
	GameState.self_esteem += 3
	GameState.changed.emit()
	Sound.sfx("spare")
	var previous_cutscene := Ui.cutscene
	Ui.cutscene = true
	var clerk_path: Array[Vector2] = []
	var score := Sound.capture_music()
	Sound.music("nives")
	Sound.sfx("ding")
	var clerk_shot: Dictionary = {}
	if is_instance_valid(_badge_booth):
		var clerk_frame := _badge_booth.get_node("InquadraturaAddetta") as Inquadratura
		clerk_shot = await FocusShot.begin(self, clerk_frame)
		await Ui.say(["Ehi, {name}! Un momento. Vengo io da te."], who, BADGE_CLERK)
		_clerk_camera_actor = _badge_booth.clerk
		_clerk_camera_offset = clerk_frame.global_position - _badge_booth.clerk.global_position
		_clerk_camera_speed = clerk_frame.velocita_inseguimento
		# da quando esce a quando rientra, tu e chi le sta vicino vi girate verso di lei
		_watch_actor(_badge_booth.clerk)
		await _badge_booth.come_out()
		clerk_path = _clerk_path(_badge_booth.clerk.global_position)
		for point in clerk_path:
			await _badge_booth.walk_to(point)
		var delta: Vector2 = player.global_position - _badge_booth.clerk.global_position
		_badge_booth.clerk.play("idle_" + ("right" if delta.x > 0 else "left") if absf(delta.x) > absf(delta.y) else "idle_" + ("down" if delta.y > 0 else "up"))
	if first_friend:
		await Ui.say(["* L'addetta dello sportello ti viene incontro con un badge in mano.",
			"Ho sentito. Hai dato una mano a tutti, qui. A tutti.",
			"Sai quante persone l'hanno fatto, in vent'anni? Nessuna. Io, per esempio, no.",
			"Questo badge te lo regalo io. E il tornello te lo apro io. Siamo amici, adesso. Io mi chiamo Nives, a proposito. Nessuno me l'aveva mai chiesto."], who, BADGE_CLERK)
	else:
		await Ui.say(["{name}! L'ho saputo: anche qui hai aiutato tutti.",
			"Siamo tutte uguali, noi addette. Ma io mi ricordo di te. Tieni: offre Nives."], who, BADGE_CLERK)
	open_turnstiles()
	await Ui.say(["* Hai ricevuto il badge del %s. La tua autostima sale: %d." % [GameState.floor_name(need), GameState.self_esteem]])
	if is_instance_valid(_badge_booth):
		clerk_path.reverse()
		for point in clerk_path:
			await _badge_booth.walk_to(point)
		await _badge_booth.go_inside()
	_watched = null
	_clerk_camera_actor = null
	if not clerk_shot.is_empty():
		await FocusShot.restore(self, clerk_shot)
	Sound.restore_music(score)
	Ui.cutscene = previous_cutscene



## Chi è vicino (e il giocatore) guarda `actor` finché `_watched` resta lui (Nives che arriva e se ne va).
const WATCH_RANGE := 112.0
var _watched: Node2D


func _watch_actor(actor: Node2D) -> void:
	_watched = actor
	while is_instance_valid(actor) and _watched == actor and is_inside_tree():
		var lookers: Array = [player] if is_instance_valid(player) else []
		for n in get_tree().get_nodes_in_group("npc"):
			if n is Npc and n != actor and (n as Npc).global_position.distance_to(actor.global_position) < WATCH_RANGE:
				lookers.append(n)
		for who: Node2D in lookers:
			var d := actor.global_position - who.global_position
			if d.length() < 2.0:
				continue
			var dir := ("right" if d.x > 0 else "left") if absf(d.x) > absf(d.y) else ("down" if d.y > 0 else "up")
			if who is Player:
				if (who as Player).facing != dir:
					(who as Player).face(dir)
			elif (who as Npc).sprite.animation != "idle_" + dir:
				(who as Npc).face(dir)
		await get_tree().process_frame


## Il capo telefona dopo il turno: una promozione, cioè prendersi il merito di qualcuno che conosci.
func _boss_call() -> void:
	if load("res://scripts/boss_missions.gd").uses(GameState.floor_id):
		await load("res://scripts/boss_missions.gd").offer(self)
		return
	GameState.flags["boss_call_done_%d" % GameState.day] = true
	GameState.flags["boss_call_floor_" + GameState.floor_id] = true
	var victim := GameState.promotion_victim()
	var promo := GameState.promotion(victim)
	if victim == "" or promo.is_empty():
		return
	Sound.sfx("alarm", 0.7)
	await Ui.say(["* Il telefono vibra. È il capo."])
	await Ui.say(promo.get("desc", []), "Il capo")
	var c: int = await Ui.choose("Prenditi il merito, e sei promosso. (+%s)" % GameState.euros(GameState.easy_pay()),
		["Accetta", "Rifiuta"], "Il capo")
	if c != 0:
		GameState.flags["promotions_refused"] = int(GameState.flags.get("promotions_refused", 0)) + 1
		await Ui.say(["Peccato. Ci sono altri cento come lei, sa? Ci pensi."], "Il capo")
		return
	var data := GameState.npc_data(victim)
	start_steal(victim, promo)
	return
	@warning_ignore("unreachable_code")
	Router.battle({
		"kind": "sign",
		"promotion": true,
		"id": victim,
		"name": str(data.get("name", "Qualcuno")),
		"sheet": str(data.get("sheet", "char_02")),
		"intro": "* Davanti a te, la pratica di %s: %s.\n* Tutti i pulsanti dicono FIRMA. Qualunque cosa tu scelga, la risposta è sempre la stessa." % [str(data.get("name", "qualcuno")), str(promo.get("title", "una pratica")).to_lower()],
		"return": scene_file_path,
		"return_pos": player.global_position,
	})


# --- mappa ------------------------------------------------------------------

## Ogni voce di legenda: {"tex": percorso, "at": Vector2i o Callable(cella) -> Vector2i, "solid": bool}.
## La voce "_floor" viene usata sotto i caratteri sconosciuti (che finiscono in markers).
func paint(rows: Array, legend: Dictionary) -> void:
	map_size = Vector2i(str(rows[0]).length(), rows.size())
	# il bordo "#" è scuro e sembra il fuori-mappa: la telecamera resta sulle righe e colonne
	# piene per almeno metà (così i corridoi stretti verso le porte non allargano l'inquadratura)
	var full_rows: Array[int] = []
	var full_cols: Array[int] = []
	for y in rows.size():
		if str(rows[y]).replace("#", "").length() * 2 >= map_size.x:
			full_rows.append(y)
	for x in map_size.x:
		var n := 0
		for r in rows:
			n += 0 if str(r)[x] == "#" else 1
		if n * 2 >= rows.size():
			full_cols.append(x)
	if not full_rows.is_empty() and not full_cols.is_empty() and (full_rows.size() < rows.size() or full_cols.size() < map_size.x):
		var top := -float(camera_top) if camera_top > 0 else float(full_rows[0] * T)
		var bottom := float((full_rows[-1] + 1) * T)
		cam_rect = Rect2(full_cols[0] * T, top, (full_cols[-1] + 1 - full_cols[0]) * T, bottom - top)
	for y in rows.size():
		var row := str(rows[y])
		for x in row.length():
			var ch := row[x]
			var cell := Vector2i(x, y)
			if legend.has(ch):
				_paint_cell(cell, legend[ch])
			else:
				_paint_cell(cell, legend["_floor"])
				if not markers.has(ch):
					markers[ch] = []
				markers[ch].append(cell)


func _paint_cell(cell: Vector2i, def: Dictionary) -> void:
	var at: Variant = def["at"]
	var coords: Vector2i = at.call(cell) if at is Callable else at
	put(cell, def["tex"], coords)
	if def.get("solid", false):
		block(Rect2i(cell, Vector2i.ONE))


func put(cell: Vector2i, rel: String, coords: Vector2i) -> void:
	var sid := _source(rel)
	var src := _tileset.get_source(sid) as TileSetAtlasSource
	var size := src.texture.get_size()
	if (coords.x + 1) * T > size.x or (coords.y + 1) * T > size.y:
		coords = Vector2i.ZERO
	if not src.has_tile(coords):
		src.create_tile(coords)
	_tiles.set_cell(cell, sid, coords)


func _source(rel: String) -> int:
	if _sources.has(rel):
		return _sources[rel]
	var src := TileSetAtlasSource.new()
	src.texture = Assets.tex(rel)
	src.texture_region_size = Vector2i(T, T)
	var sid := _tileset.add_source(src)
	_sources[rel] = sid
	return sid


## Rende solido un rettangolo preciso in pixel (per oggetti più piccoli di una casella).
func block_px(r: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = r.size
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = r.get_center()
	_solids.add_child(col)


## Panchina laterale (16x48): solo la seduta blocca il passaggio.
func add_side_bench(bottom: Vector2i, text: Array = []) -> void:
	add_prop("street/bench_side.png", bottom, 0, Vector2i(16, 48), text)
	block_px(Rect2(bottom.x * T + 3, (bottom.y - 2) * T + 22, 10, 24))


## Rende solide le celle del rettangolo.
func block(r: Rect2i) -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(r.size * T)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(r.position * T) + shape.size / 2.0
	_solids.add_child(col)
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_blocked_cells[Vector2i(x, y)] = true


# --- contenuto --------------------------------------------------------------

func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * T + T / 2.0, cell.y * T + T / 2.0)


func cell_feet(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * T + T / 2.0, (cell.y + 1) * T - 2)


## Piazza un oggetto con l'angolo in basso a sinistra sulla cella indicata.
## Le ultime `solid_rows` righe di celle occupate diventano solide.
## `text`: cosa dice l'oggetto quando lo guardi (Z). `nudge`: spostamento fine in pixel.
func add_prop(rel: String, bottom_left: Vector2i, solid_rows := 1, fallback := Vector2i(16, 32),
		text: Array = [], nudge := Vector2.ZERO) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Assets.tex(rel, fallback)
	s.centered = false
	s.offset = Vector2(0, -s.texture.get_height())
	s.position = Vector2(bottom_left.x * T, (bottom_left.y + 1) * T) + nudge
	world.add_child(s)
	# chi passa davanti o dietro si decide alla base vera del disegno (il vaso), non alle righe vuote sotto
	var base := s.position
	var gap := _bottom_gap(s.texture)
	s.position.y -= gap
	s.offset.y += gap
	var w := int(ceil(s.texture.get_width() / float(T)))
	if solid_rows > 0:
		# Blocca solo i pixel veri della base dell'oggetto (il palo, il tronco), non tutta la casella.
		var r := _solid_rect(s.texture, solid_rows)
		if r.size.x > 0:
			block_px(Rect2(base + r.position, r.size))
			for cx in range(int(floor((base.x + r.position.x) / T)), int(ceil((base.x + r.end.x) / T))):
				for cy in range(int(floor((base.y + r.position.y) / T)), int(ceil((base.y + r.end.y) / T))):
					_blocked_cells[Vector2i(cx, cy)] = true
		else:
			block(Rect2i(bottom_left.x, bottom_left.y - solid_rows + 1, w, solid_rows))
	if not text.is_empty():
		examine(Vector2(bottom_left.x * T + s.texture.get_width() / 2.0, (bottom_left.y + 1) * T - 8) + nudge, text)
	return s


static var _solid_cache := {}


## Quante righe trasparenti ci sono sotto il disegno (0 se non si può leggere l'immagine).
func _bottom_gap(tex: Texture2D) -> int:
	var img := tex.get_image()
	if img == null:
		return 0
	if img.is_compressed():
		img.decompress()
	var used := img.get_used_rect()
	return 0 if used.size.y == 0 else img.get_height() - used.end.y


## Rettangolo dei pixel non trasparenti nelle ultime `rows` righe di caselle dello sprite,
## relativo all'angolo in basso a sinistra (le y sono negative). Vuoto se non si può leggere l'immagine.
func _solid_rect(tex: Texture2D, rows: int) -> Rect2:
	var key := "%d_%d" % [tex.get_rid().get_id(), rows]
	if _solid_cache.has(key):
		return _solid_cache[key]
	var out := Rect2()
	var img := tex.get_image()
	if img:
		if img.is_compressed():
			img.decompress()
		var h := img.get_height()
		# Oggetti con una riga sola: se la base è larga (tavoli, cassette, auto) conta mezza casella,
		# se è stretta (lampioni, tronchi) solo i "piedi" dell'oggetto.
		var foot := 6
		if rows == 1:
			var lo := img.get_width()
			var hi := -1
			for x in img.get_width():
				for y in range(maxi(0, h - 4), h):
					if img.get_pixel(x, y).a > 0.3:
						lo = mini(lo, x)
						hi = maxi(hi, x)
			if hi - lo > 24:
				foot = 12
		var top := maxi(0, h - (rows * T if rows > 1 else foot))
		var minx := img.get_width()
		var maxx := -1
		var miny := h
		var maxy := -1
		for y in range(top, h):
			for x in img.get_width():
				if img.get_pixel(x, y).a > 0.3:
					minx = mini(minx, x)
					maxx = maxi(maxx, x)
					miny = mini(miny, y)
					maxy = maxi(maxy, y)
		if maxx >= 0:
			out = Rect2(minx, miny - h, maxx - minx + 1, maxy - miny + 1)
	_solid_cache[key] = out
	return out


## Punto di salvataggio: una stellina che brilla (world/stellina.tscn). Salva stanza, posizione e ora, e ridà energia.
func add_save_point(cell: Vector2i) -> void:
	var star := load(STELLINA).instantiate() as Stellina
	star.position = Vector2(cell * T)
	world.add_child(star)
	use_save_point(star)


func use_save_point(star: Stellina) -> void:
	var here := (star.get_node("Risveglio") as Node2D).global_position
	var spot := add_spot((star.get_node("Tocco") as Node2D).global_position, func() -> void: _save_here(here))
	# chi sta sopra la stellina parla con lei, non con la scrivania accanto
	spot.interaction_bounds = star.zona_tocco


## La stellina salva, ridà energia e, se vuoi, fa passare la notte (così il giorno dopo si può
## lavorare di nuovo). La notte però costa: gli interessi corrono. `here`: dove ti ritrovi.
func _save_here(here: Vector2) -> void:
	GameState.restore(GameState.MAX_ENERGY)
	var c: int = await Ui.choose("* (Una stellina brilla a mezz'aria. Guardarla ti fa tornare la voglia di andare avanti.)",
		["Salva", "Salva e lascia passare la notte", "Lascia stare"])
	if c == 2:
		return
	if c == 1:
		GameState.spend(GameState.MIDNIGHT - GameState.minutes)
		GameState.save_game(scene_file_path, here)
		Sound.sfx("spare")
		Router.save_pos = here
		Router.goto(scene_file_path, "_save", ["Ti siedi vicino alla stellina e chiudi gli occhi.", "La notte passa. Da qualche parte, sopra di te, qualcuno conta gli interessi.", "{floor}, ore {clock}."])
		return
	GameState.save_game(scene_file_path, here)
	Sound.sfx("spare")
	await Ui.say(["* Energia al massimo. Partita salvata: {floor}, ore {clock}."])


## Un punto che, guardato, mostra una descrizione.
func examine(pos: Vector2, text: Array) -> Interactable:
	return add_spot(pos, func() -> void: Ui.say(text))


## Mette nella stanza le persone che oggi, secondo data/npcs.json, si trovano qui.
func spawn_people(room_key: String) -> void:
	var items := Quests.items_in(room_key)
	for it: Dictionary in items:
		_people_cells[it["cell"]] = true
	for id: String in GameState.npc_ids():
		var place := GameState.npc_place(id)
		if place.get("room", "") != room_key:
			continue
		var cell: Array = place.get("cell", [1, 1])
		add_npc(id, Vector2i(int(cell[0]), int(cell[1])), str(place.get("anim", "idle_down")))
	for it: Dictionary in items:
		_add_quest_item(it["quest"], it["cell"])


## L'oggetto nascosto di una missione: un gatto che dorme (world/gatto.tscn) o un paio di occhiali
## per terra (world/occhiali.tscn). Nelle scene: `Sprite` è il disegno, `Tocco` il punto da cui lo raccogli.
const QUEST_ITEMS := {"cat": "res://world/gatto.tscn", "glasses": "res://world/occhiali.tscn"}


func _add_quest_item(q: Dictionary, cell: Vector2i) -> void:
	var node := load(QUEST_ITEMS["cat"] if q.get("item") == "cat" else QUEST_ITEMS["glasses"]).instantiate() as Node2D
	node.position = cell_feet(cell)
	world.add_child(node)
	var holder: Array = []
	holder.append(add_spot((node.get_node("Tocco") as Node2D).global_position, func() -> void:
		node.queue_free()
		for h: Node in holder:
			h.queue_free()
		await Quests.pick_up(q)
	))


## Ritaglia un pezzo da un foglio grande (per esempio un edificio intero).
func add_region(rel: String, sheet_size: Vector2i, region: Rect2, bottom_left: Vector2i) -> Sprite2D:
	var at := AtlasTexture.new()
	at.atlas = Assets.tex(rel, sheet_size)
	at.region = region
	var s := Sprite2D.new()
	s.texture = at
	s.centered = false
	s.offset = Vector2(0, -region.size.y)
	s.position = Vector2(bottom_left.x * T, (bottom_left.y + 1) * T)
	world.add_child(s)
	return s


## Un cartello su due pali piantati a terra: `foot` è il punto a terra sotto il centro del cartello,
## `post` l'altezza dei pali. Va nel mondo ordinato per y, così ci si passa dietro.
func add_signpost(path: String, foot: Vector2, post := 14) -> void:
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	var holder := Node2D.new()
	holder.position = foot
	for k in 2:
		var pole := ColorRect.new()
		pole.color = Color("5a3e2b")
		pole.size = Vector2(2, post + 2)
		pole.position = Vector2(-tex.get_width() / 2.0 + 4 + k * (tex.get_width() - 10), -post - 2)
		holder.add_child(pole)
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = Vector2(-tex.get_width() / 2.0, -post - tex.get_height())
	holder.add_child(s)
	world.add_child(holder)
	var x0 := int(foot.x - tex.get_width() / 2.0 + 4) / T
	var x1 := int(foot.x + tex.get_width() / 2.0 - 5) / T
	block(Rect2i(x0, int(foot.y - 1) / T, x1 - x0 + 1, 1))


## Casella libera più vicina a quella voluta: niente muri e nessun'altra persona attaccata.
## Chi è seduto resta sulla sua panchina.
func free_cell(cell: Vector2i, keep := false) -> Vector2i:
	if keep:
		_people_cells[cell] = true
		return cell
	for r in 6:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := cell + Vector2i(dx, dy)
				if c.x < 0 or c.y < 0 or (map_size != Vector2i.ZERO and (c.x >= map_size.x or c.y >= map_size.y)):
					continue
				if _blocked_cells.has(c) or _near_person(c):
					continue
				_people_cells[c] = true
				return c
	_people_cells[cell] = true
	return cell


func _near_person(c: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if _people_cells.has(c + Vector2i(dx, dy)):
				return true
	return false


func add_npc(id: String, cell: Vector2i, activity := "idle_down") -> Npc:
	var n := load(NPC_SCENE).instantiate() as Npc
	n.id = id
	n.activity = activity if activity.contains("_") or activity in ["phone", "read", "wander"] else "idle_" + activity
	cell = free_cell(cell, n.activity.begins_with("sit"))
	n.position = cell_feet(cell)
	world.add_child(n)
	return n


## Uno sprite dalla cartella art/ (grafica fatta per Cheap), con l'angolo in basso a sinistra sulla cella.
func add_art(path: String, bottom_left: Vector2i, solid_rows := 0, nudge := Vector2.ZERO) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = false
	s.offset = Vector2(0, -s.texture.get_height())
	s.position = Vector2(bottom_left.x * T, (bottom_left.y + 1) * T) + nudge
	world.add_child(s)
	if solid_rows > 0:
		var r := _solid_rect(s.texture, solid_rows)
		if r.size.x > 0:
			block_px(Rect2(s.position + r.position, r.size))
			_blocked_cells[bottom_left] = true
	return s


## Le scale di legno del foglio "Generic" di LimeZu (2 caselle di larghezza, 4 di altezza).
const GENERIC := "tiles/generic.png"
const GENERIC_SIZE := Vector2i(256, 1248)
const STAIRS_REGION := Rect2(168, 864, 32, 64)
## La scrivania bianca con il computer, sempre dal foglio "Generic".
const DESK_REGION := Rect2(96, 8, 16, 40)


var _turnstiles: Array[TicketGateScript] = []


## Scale che salgono al piano di sopra, dentro al muro, con il tornello accanto: si passa
## solo con il badge di quel piano. `bottom_left` è il primo gradino (sul pavimento).
## Nelle stanze fatte nell'editor le scale sono la scena world/stairs_up.tscn (nel livello
## "Decori"); qui la si mette per le stanze fatte col codice.
func add_stairs_up(bottom_left: Vector2i, path: String, spawn_name: String, need: String) -> void:
	var st: Node2D = StairsUpScene.instantiate()
	st.set("target", path)
	st.set("spawn", spawn_name)
	st.set("need", need)
	st.position = Vector2(bottom_left * T)
	add_child(st)
	move_child(st, world.get_index())
	use_stairs_up(st)
	_setup_children(st)


## Collega le scale (nodi della scena) al gioco: tornello, cartello, primo gradino e cambio di piano.
func use_stairs_up(st: Node2D) -> void:
	var o := to_local(st.global_position)
	var bottom_left := Vector2i((o / T).round())
	var path: String = st.get("target")
	var spawn_name: String = st.get("spawn")
	var need: String = st.get("need")
	_stairs_up_pos = o + Vector2(T, -T)
	_stairs_up_exit = o + Vector2(T, T + 10)
	# gli scalini si salgono a piedi: il muro dietro le scale non è più solido
	unblock(Rect2i(bottom_left.x, bottom_left.y - 2, 2, 2))
	# più sali, più la luce del piano di sotto resta indietro
	_stair_zones.append({"rect": Rect2(o.x, o.y - 2 * T, 2 * T, 3 * T), "up": true})
	var turn := st.get_node("Tornello") as TicketGateScript
	_turnstiles.append(turn)
	var gate := st.get_node("Sbarra")
	if GameState.has_badge(need):
		turn.unlock(false)
		gate.queue_free()
	else:
		_stair_gates.append({"node": gate, "need": need})
	# chi sbatte contro il tornello chiuso legge il cartello
	(st.get_node("Cartello") as Area2D).body_entered.connect(func(b: Node2D) -> void:
		if not (b is Player) or Ui.blocks_input() or GameState.has_badge(need):
			return
		Sound.sfx("deny")
		await Ui.say(["* Il tornello lampeggia rosso. \"Badge del %s richiesto.\"" % GameState.floor_name(need),
			"* (Il badge si compra allo sportello: %s, a scalare dal debito.)" % GameState.euros(GameState.badge_cost(need))])
	)
	var look := st.get_node_or_null("GuardaTornello") as Examine
	if look and look.lines.is_empty():
		look.lines = PackedStringArray(["* Il tornello. Sopra il lettore c'è scritto: \"%s. Solo con badge\"." % GameState.floor_name(need)])
	# sul primo gradino (col badge) la stanza può far succedere qualcosa: on_stairs_step()
	(st.get_node("PrimoGradino") as Area2D).body_entered.connect(func(b: Node2D) -> void:
		if b is Player and not Ui.blocks_input() and GameState.has_badge(need):
			on_stairs_step(b as Player, need)
	)
	# in cima agli scalini si cambia piano
	(st.get_node("Cima") as Area2D).body_entered.connect(func(b: Node2D) -> void:
		if not (b is Player) or Ui.transitioning:
			return
		if on_stairs_top(b as Player):
			return
		var key := "stairs_" + need
		var lines: Array = []
		if not GameState.flags.get(key, false):
			GameState.flags[key] = true
			lines = ["I gradini sono consumati al centro, da tutti quelli che sono passati prima.", GameState.floor_name(need) + "."]
		Router.goto(path, spawn_name, lines)
	)


## Per le scene messe dal codice: i figli (le frasi) si collegano alla stanza come nell'editor.
func _setup_children(node: Node) -> void:
	for n in node.find_children("*", "", true, false):
		if n.has_method("setup_in_room"):
			n.call("setup_in_room", self)




## Scala sottile del condominio LimeZu, a misura originale (32×64).
func _stairs_sprite(bottom_left: Vector2i) -> Node2D:
	return add_region("themes/condominium.png", Vector2i(256, 1664), Rect2(16, 0, 32, 64), bottom_left)


## Da scrivere nelle stanze che vogliono fare qualcosa in cima alle scale, al posto di cambiare
## piano subito (il Fondo: lo sguardo indietro). Restituisce true se ci pensa la stanza.
func on_stairs_top(_p: Player) -> bool:
	return false


## Da scrivere nelle stanze dove il badge non basta pagarlo (il Sottoufficio: serve il B-4).
## Se restituisce false, lo sportello non lo vende (e la stanza ha già spiegato perché).
func badge_allowed(_need: String) -> bool:
	return true


## Da scrivere nelle stanze che vogliono un momento speciale sul primo gradino (il Fondo).
func on_stairs_step(_p: Player, _need: String) -> void:
	pass


## Il tornello si apre (appena compri il badge, senza dover cambiare stanza).
func open_turnstiles() -> void:
	for g: Dictionary in _stair_gates:
		if GameState.has_badge(str(g["need"])) and is_instance_valid(g["node"]):
			(g["node"] as Node).queue_free()
	for n in _turnstiles:
		if is_instance_valid(n):
			n.unlock()


## Toglie i muri (le caselle solide) in un rettangolo di caselle.
func unblock(r: Rect2i) -> void:
	# nelle stanze fatte nell'editor i muri sono tessere del livello "Muri"
	if has_node("Muri"):
		var walls := get_node("Muri") as TileMapLayer
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				walls.erase_cell(Vector2i(x, y))
	var area := Rect2(r.position * T, r.size * T)
	for c in _solids.get_children():
		if c is CollisionShape2D and area.has_point((c as CollisionShape2D).position):
			c.queue_free()
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_blocked_cells.erase(Vector2i(x, y))


## La versione corta della scala, vista dal piano superiore (32×32). Nelle stanze fatte
## nell'editor è la scena world/stairs_down.tscn (livello "Decori"); qui la si mette dal codice.
func add_stairs_down(bottom_left: Vector2i, path: String, spawn_name: String) -> void:
	var st: Node2D = StairsDownScene.instantiate()
	st.set("target", path)
	st.set("spawn", spawn_name)
	st.position = Vector2(bottom_left * T)
	add_child(st)
	move_child(st, world.get_index())
	use_stairs_down(st)


## Collega le scale per il piano di sotto (nodi della scena): si scende toccando il primo gradino.
func use_stairs_down(st: Node2D) -> void:
	var o := to_local(st.global_position)
	var path: String = st.get("target")
	var spawn_name: String = st.get("spawn")
	var top := o.y - T
	var bottom := o.y + T
	var center := o.x + T
	_stairs_down_pos = Vector2(center, bottom - 6)
	_stairs_down_exit = Vector2(center, top - 2)
	_stair_zones.append({"rect": Rect2(o.x, top, 32, 32), "up": false})
	(st.get_node("Discesa") as Area2D).body_entered.connect(func(body: Node2D) -> void:
		if body is Player and not Ui.blocks_input() and not _descending_stairs:
			_descend_stairs(body as Player, Vector2(center, top - 2), Vector2(center, bottom - 6), path, spawn_name)
	)


func _descend_stairs(p: Player, entry: Vector2, finish: Vector2, path: String, spawn_name: String) -> void:
	_descending_stairs = true
	Ui.cutscene = true
	p.velocity = Vector2.ZERO
	p.set_physics_process(false)
	await p.walk_to(entry)
	await p.climb(finish, "down", true)
	Ui.cutscene = false
	Router.goto(path, spawn_name)


## La scrivania bianca con il computer (16x40): il piano e le gambe bloccano il passaggio.
func add_computer_desk(bottom_left: Vector2i, text: Array = []) -> Sprite2D:
	var s := add_region(GENERIC, GENERIC_SIZE, DESK_REGION, bottom_left)
	block_px(Rect2(bottom_left.x * T + 1, (bottom_left.y + 1) * T - 30, T - 2, 28))
	_blocked_cells[bottom_left] = true
	if not text.is_empty():
		examine(cell_center(bottom_left), text)
	return s


## Arrivando dalle scale, il personaggio sale fuori dalla botola o scende dagli scalini.
func _prepare_arrival() -> Vector2:
	# arrivando dalle scale si compare dove finiscono gli scalini, già in piedi
	var at := Vector2.INF
	if Router.spawn == "from_below":
		at = _stairs_down_exit
	elif Router.spawn == "from_above":
		at = _stairs_up_exit
	if at != Vector2.INF and player:
		player.position = at
		player.face("up" if Router.spawn == "from_below" else "down")
	return Vector2.INF


func _do_arrival(_to: Vector2) -> void:
	pass


## Biglietteria dei badge originale, con la porta da cui esce l'addetta. Se la stanza ha già
## la scena world/badge_booth.tscn (messa nell'editor), si usa quella; altrimenti la si mette qui.
func add_badge_machine(cell: Vector2i) -> void:
	var booth: Node2D = BadgeBoothScene.instantiate()
	booth.name = "BiglietteriaBadge"
	booth.position = Vector2((cell.x - 2) * T, (cell.y + 2) * T)
	world.add_child(booth)
	use_badge_booth(booth)


## Lo sportello davanti al vetro, dove si compra il badge.
func use_badge_booth(booth: Node2D) -> void:
	_badge_booth = booth
	var spot := add_spot(to_local(booth.global_position) + Vector2(40, 6), _badge_machine)
	spot.name = "SportelloBadgeInterazione"
	spot.interaction_bounds = Rect2(-40, -8, 64, 8)
	spot.approach = Vector2.DOWN
	spot.facing_required = "up"


const BADGE_CLERK := "char_13"


func _badge_machine() -> void:
	var need := GameState.floor_above()
	if need == "":
		await Ui.say(["* Il distributore è spento. Più su di così non si va."])
		return
	var cost := GameState.badge_cost(need)
	var who := "Addetta ai badge"
	if GameState.has_badge(need):
		await Ui.say(["Hai già il badge del %s. Le scale sono lì. Buona salita." % GameState.floor_name(need)], who, BADGE_CLERK)
		return
	# la stanza può chiedere qualcosa in più prima del badge (al -4: il Modulo B-4)
	if not await badge_allowed(need):
		return
	if GameState.flags.get("clerk_friend", false):
		await Ui.say(["Ciao, {name}! Sono io, Nives. Cioè: una Nives. Ma quella che ti conosce."], who, BADGE_CLERK)
	elif not GameState.flags.get("badge_clerk_intro", false):
		GameState.flags["badge_clerk_intro"] = true
		await Ui.say(["Sportello badge. Senza badge il tornello non ti fa salire le scale.",
			"Sì, ci sono io su ogni piano. Siamo una per piano. Siamo tutte uguali. Non chiedere."], who, BADGE_CLERK)
	await Ui.say(["Il badge del %s costa %s. Va tutto a scalare dal tuo debito." % [GameState.floor_name(need), GameState.euros(cost)]], who, BADGE_CLERK)
	var c: int = await Ui.choose("Comprare il badge? Hai %s." % GameState.euros(GameState.money), ["Compra (%s)" % GameState.euros(cost), "Non ora"], who)
	if c != 0:
		return
	if not GameState.buy_badge(need):
		Sound.sfx("deny")
		await Ui.say(["Non bastano. Torna quando avrai lavorato abbastanza. Cioè sempre un po' di più di adesso."], who, BADGE_CLERK)
		return
	Sound.sfx("coin")
	Sound.sfx("stamp")
	open_turnstiles()
	await Ui.say(["Ecco il badge. Ancora caldo, come un biglietto della lotteria che hai già perso.",
		"Debito: {debt}. Il tornello adesso ha la lucina verde."], who, BADGE_CLERK)
	if need == "cima":
		Sound.sfx("ding")
		await Ui.say(["* Dietro di te, un \"din\". Le porte dell'ascensore si aprono da sole.",
			"Oh! Hanno appena aggiustato l'ascensore. Proprio adesso che hai il badge. Che tempismo, eh?",
			"Qui le cose si aggiustano sempre quando servono a qualcuno di importante. Congratulazioni: adesso sei qualcuno."], who, BADGE_CLERK)
		if has_method("_open_elevator"):
			call("_open_elevator")
		await Ui.say(["* Le porte dell'ascensore sono aperte, con la luce verde. Basta entrarci."])
	for n in _turnstiles:
		if is_instance_valid(n):
			n.unlock()


func add_spot(pos: Vector2, action: Callable) -> Interactable:
	var i := Interactable.new()
	i.position = pos
	i.action = action
	add_child(i)
	return i


## Zona che porta in un'altra scena quando il giocatore ci cammina sopra.
func add_exit(r: Rect2i, path: String, spawn_name: String) -> void:
	var a := Area2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(r.size * T)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(r.position * T) + shape.size / 2.0
	a.add_child(col)
	add_child(a)
	a.body_entered.connect(func(b: Node2D) -> void:
		if b is Player and not Ui.blocks_input():
			Router.goto(path, spawn_name)
	)


func _spawn_player() -> void:
	player = load(PLAYER_SCENE).instantiate() as Player
	if Router.spawn == "_back" and GameState.battle.has("return_pos"):
		spawns["_back"] = GameState.battle["return_pos"]
	if Router.spawn == "_mg" and GameState.minigame.has("return_pos"):
		spawns["_mg"] = GameState.minigame["return_pos"]
	if Router.spawn == "_save" and Router.save_pos != Vector2.INF:
		spawns["_save"] = Router.save_pos
	var key := Router.spawn if spawns.has(Router.spawn) else "default"
	player.position = spawns.get(key, Vector2(map_size * T) / 2.0)
	player.facing = spawn_facing.get(key, "down")
	world.add_child(player)
	var cam := player.camera
	if cam_rect.size == Vector2.ZERO:
		cam_rect = Rect2(0, -camera_top, map_size.x * T, map_size.y * T + camera_top)
	# se la stanza è più piccola dello schermo, si avvicina la telecamera invece di mostrare il nero
	var z := maxf(cam.zoom.x, maxf(VIEW.x * 2.0 / cam_rect.size.x, VIEW.y * 2.0 / cam_rect.size.y))
	cam.zoom = Vector2(z, z)
	cam.limit_left = int(cam_rect.position.x)
	cam.limit_right = int(ceil(cam_rect.end.x))
	cam.limit_top = int(cam_rect.position.y)
	cam.limit_bottom = int(ceil(cam_rect.end.y))



## Percorso dell'addetta: controlla lo spazio reale, inclusi mobili e persone.
func _clerk_path(start: Vector2) -> Array[Vector2]:
	const GRID := 8
	var from := Vector2i(start / GRID)
	var queue: Array[Vector2i] = [from]
	var parents := {from: from}
	var found := from
	var closest := INF
	var shape := RectangleShape2D.new(); shape.size = Vector2(9,5)
	var query := PhysicsShapeQueryParameters2D.new(); query.shape = shape; query.collision_mask = 1
	query.exclude = [player.get_rid()]
	var cursor := 0
	while cursor < queue.size():
		var cell := queue[cursor]; cursor += 1
		var point := Vector2(cell * GRID) + Vector2(4,4)
		var distance := point.distance_to(player.global_position)
		if distance < closest:
			closest = distance; found = cell
		if distance <= 28 and distance >= 16: break
		for direction: Vector2i in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			var next := cell + direction
			if parents.has(next) or next.x < 0 or next.y < 0 or next.x >= map_size.x * 2 or next.y >= map_size.y * 2: continue
			query.transform = Transform2D(0, Vector2(next * GRID) + Vector2(4,1))
			if not get_world_2d().direct_space_state.intersect_shape(query).is_empty(): continue
			parents[next] = cell; queue.append(next)
	var cells: Array[Vector2] = []
	while found != from:
		cells.append(Vector2(found * GRID) + Vector2(4,4)); found = parents[found]
	cells.reverse()
	var path: Array[Vector2] = []
	for i in cells.size():
		if i == 0 or i == cells.size()-1 or (cells[i]-cells[i-1]).normalized() != (cells[i+1]-cells[i]).normalized(): path.append(cells[i])
	return path
