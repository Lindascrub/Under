extends "res://scenes/minigame/rifatti/base.gd"
@export var attesa_lettura := 8.0
@export var velocita_carta := 7.0
var selezione := 0
var riposo := 0.0
var inizio := Vector2.ZERO
var ultimo := Vector2.ZERO
var trascinato := false
var premuto := false
var righe: Array = []
func avvia(c: Dictionary) -> void:
	super.avvia(c)
	$Timbro.visible = false
	righe = GameState.bank.get("olga", {}).get("estratto", {}).get("righe", [])
	$Aiuto.text = "Una sola commissione di 35 € per il ritardo della rata 63."
	$Prova.text = "CONTRATTO · Rata 63\nGestione del ritardo: 35 €, una volta sola."
	for i in righe.size():
		var r: Array = righe[i]
		var b: Button = $Carta/Elenco/Righe.get_child(i)
		var evento := " · RATA 63" if i < 4 else ""
		b.text = "%s   %s €\n%s%s" % [r[0], int(r[2]), r[1], evento]
	riposo = attesa_lettura
	_aggiorna()
func _process(dt: float) -> void:
	if not attivo or Ui.busy or premuto: return
	riposo -= dt
	if riposo <= 0:
		var s: ScrollContainer = $Carta/Elenco
		s.scroll_vertical += 1
		riposo = 1.0 / velocita_carta
func _aggiorna() -> void:
	for i in righe.size():
		$Carta/Elenco/Righe.get_child(i).modulate = Color("ffe49d") if i == selezione and not TouchControls.enabled else Color.WHITE
func scegli(i: int) -> void:
	if not attivo: return
	riposo = attesa_lettura
	var doppie: Array = GameState.bank.get("olga", {}).get("estratto", {}).get("doppie", [])
	if not doppie.any(func(k): return int(k) == i):
		errori += 1
		$Esito.text = "Questa voce è unica. Cerca lo stesso ritardo addebitato due volte."
		Sound.sfx("deny")
		return
	$Timbro.visible = true
	$Esito.text = "18 e 19 giugno: due commissioni per la rata 63. Prova da contestare."
	Sound.sfx("stamp")
	attivo = false
	await get_tree().create_timer(1.0).timeout
	attivo = true
	chiudi(true)
func input_event(e: InputEvent) -> void:
	if e is InputEventKey and e.echo: return
	if e.is_action_pressed("move_up"): selezione = posmod(selezione - 1, righe.size())
	elif e.is_action_pressed("move_down"): selezione = posmod(selezione + 1, righe.size())
	elif e.is_action_pressed("confirm"): scegli(selezione)
	$Carta/Elenco.ensure_control_visible($Carta/Elenco/Righe.get_child(selezione))
	riposo = attesa_lettura
	_aggiorna()
func punta(pos: Vector2, step: int) -> void:
	if not attivo: return
	riposo = attesa_lettura
	if step == 0:
		premuto = true
		inizio = pos
		ultimo = pos
		trascinato = false
	elif step == 1:
		trascinato = trascinato or pos.distance_to(inizio) > 12.0
		$Carta/Elenco.scroll_vertical += int(ultimo.y - pos.y)
		ultimo = pos
	elif step == 2:
		premuto = false
		if not trascinato and $Carta/Elenco.get_global_rect().has_point(pos):
			for i in righe.size():
				if $Carta/Elenco/Righe.get_child(i).get_global_rect().has_point(pos):
					scegli(i)
					return
