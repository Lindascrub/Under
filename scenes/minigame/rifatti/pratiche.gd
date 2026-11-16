extends "res://scenes/minigame/rifatti/base.gd"
@export var pausa_timbro := 0.75
var indice := 0
var selezione := 0
var in_attesa := false
var pratiche: Array = []
var scelte_escluse: Array[int] = []
func avvia(c: Dictionary) -> void:
	super.avvia(c)
	pratiche = GameState.bank.get("teo", {}).get("pratiche", [])
	$Aiuto.text = "Tocca la riga diversa." if TouchControls.enabled else "Clicca la riga diversa. Oppure FRECCE e INVIO."
	_mostra()
func _mostra() -> void:
	scelte_escluse.clear()
	$Esito.text = ""
	var p: Dictionary = pratiche[indice]
	var tipo := int(p.get("tipo", 0))
	var righe: Array = p.get("righe", [])
	# Una parola e un valore per riga, uguali sui due fogli: al massimo una riga è diversa.
	var paga := _valore(str(righe[1]))
	var etichette := ["IDENTITÀ", "PAGA", "REDDITI", "RICHIESTA"]
	var sinistra := ["SÌ", paga, paga if tipo in [3, 4] else _valore(str(righe[2])), _valore(str(righe[3]))]
	var destra: Array = sinistra.duplicate()
	if tipo == 1:
		destra[0] = "MANCA"
	if tipo == 2:
		sinistra[2] = paga
		destra[2] = _valore(str(righe[2]))
	if tipo == 3:
		etichette[2] = "BUSTE PAGA"
		sinistra[2] = "1"
		destra[2] = "2 UGUALI"
	if tipo == 4:
		sinistra[3] = _valore(str(righe[2]))
		destra[3] = _valore(str(righe[3]))
	for i in 4:
		sinistra[i] = "%s
%s" % [etichette[i], sinistra[i]]
		destra[i] = "%s
%s" % [etichette[i], destra[i]]
	$Stato.text = "%d/%d · Errori %d/%d" % [indice + 1, pratiche.size(), errori, int(configurazione.get("misses", 2))]
	$Timbro.visible = false
	for i in 4:
		var a: Label = $Sinistra/Campi.get_child(i)
		var b: Button = $Destra/Campi.get_child(i)
		a.text = str(sinistra[i])
		b.text = str(destra[i])
		a.modulate = Color.WHITE
		b.modulate = Color.WHITE
	_evidenzia()
## Il valore di una riga di data/bank.json: quello che sta dopo i due punti, senza «al mese».
func _valore(riga: String) -> String:
	var v := riga.get_slice(": ", 1) if ": " in riga else riga
	return v.replace(" al mese", "").strip_edges()
func _evidenzia() -> void:
	for i in 4:
		var focused := i == selezione and not TouchControls.enabled
		$Sinistra/Campi.get_child(i).modulate = Color("ffe49d") if focused else Color.WHITE
		$Destra/Campi.get_child(i).modulate = Color("ffb0a0") if i in scelte_escluse else (Color("ffe49d") if focused else Color.WHITE)
	$Nessuna.modulate = Color("ffe49d") if selezione == 4 and not TouchControls.enabled else Color.WHITE
func scegli(k: int) -> void:
	if not attivo or in_attesa or k < 0 or k > 4 or k in scelte_escluse: return
	var corretto := int(pratiche[indice].get("riga", -1))
	var scelto := -1 if k == 4 else k
	if scelto != corretto:
		scelte_escluse.append(k)
		errori += 1
		$Esito.text = "No: quella è uguale."
		_evidenzia()
		Sound.sfx("deny")
		if errori >= int(configurazione.get("misses", 2)): chiudi(false)
		return
	in_attesa = true
	if k < 4:
		$Sinistra/Campi.get_child(k).modulate = Color("9ee6b2")
		$Destra/Campi.get_child(k).modulate = Color("9ee6b2")
	$Timbro.visible = true
	$Esito.text = "Giusto: tutto uguale." if k == 4 else "Trovata."
	Sound.sfx("stamp")
	await get_tree().create_timer(pausa_timbro).timeout
	if not is_inside_tree() or not attivo: return
	indice += 1
	in_attesa = false
	selezione = 0
	if indice == pratiche.size(): chiudi(true)
	else: _mostra()
func input_event(e: InputEvent) -> void:
	if not attivo or in_attesa: return
	if e is InputEventKey and e.echo: return
	if e.is_action_pressed("move_up") or e.is_action_pressed("move_left"):
		selezione = posmod(selezione - 1, 5)
	elif e.is_action_pressed("move_down") or e.is_action_pressed("move_right"):
		selezione = posmod(selezione + 1, 5)
	elif e.is_action_pressed("confirm"): scegli(selezione)
	_evidenzia()
func punta(pos: Vector2, step: int) -> void:
	if step != 0: return
	for i in 4:
		if $Destra/Campi.get_child(i).get_global_rect().has_point(pos) or $Sinistra/Campi.get_child(i).get_global_rect().has_point(pos):
			scegli(i)
			return
	if $Nessuna.get_global_rect().has_point(pos): scegli(4)
