extends "res://scenes/minigame/rifatti/base.gd"
@export var pausa_timbro := 0.75
var indice := 0
var selezione := 0
var in_attesa := false
var pratiche: Array = []
func avvia(c: Dictionary) -> void:
	super.avvia(c)
	pratiche = GameState.bank.get("teo", {}).get("pratiche", [])
	$Aiuto.text = "Confronta i due documenti. Indica il dettaglio che non torna."
	_mostra()
func _mostra() -> void:
	var p: Dictionary = pratiche[indice]
	var tipo := int(p.get("tipo", 0))
	var righe: Array = p.get("righe", [])
	var sinistra: Array = righe.duplicate()
	var destra: Array = righe.duplicate()
	# Stessi dati canonici, accostati alla prova pertinente.
	if tipo == 1:
		sinistra[0] = "Documento richiesto:\nidentità valida"
		destra[0] = "Allegato identità:\nMANCANTE"
	if tipo == 2:
		sinistra[2] = righe[1]
	if tipo == 3:
		sinistra[2] = "Allegati richiesti:\nuna busta di maggio"
		destra[2] = "Seconda copia:\nbusta di maggio"
	if tipo == 4:
		sinistra[3] = righe[2]
	$Stato.text = "Pratica %s · %s · %d/%d · Errori %d/%d" % [p.get("id", ""), p.get("nome", ""), indice + 1, pratiche.size(), errori, int(configurazione.get("misses", 2))]
	$Timbro.visible = false
	for i in 4:
		var a: Label = $Sinistra/Campi.get_child(i)
		var b: Button = $Destra/Campi.get_child(i)
		a.text = str(sinistra[i])
		b.text = str(destra[i])
		a.modulate = Color.WHITE
		b.modulate = Color.WHITE
	_evidenzia()
func _evidenzia() -> void:
	for i in 4:
		$Destra/Campi.get_child(i).modulate = Color("ffe49d") if i == selezione and not TouchControls.enabled else Color.WHITE
	$Nessuna.modulate = Color("ffe49d") if selezione == 4 and not TouchControls.enabled else Color.WHITE
func scegli(k: int) -> void:
	if not attivo or in_attesa: return
	var corretto := int(pratiche[indice].get("riga", -1))
	var scelto := -1 if k == 4 else k
	if scelto != corretto:
		errori += 1
		$Esito.text = "Confronta la stessa voce nei due fogli."
		Sound.sfx("deny")
		if errori >= int(configurazione.get("misses", 2)): chiudi(false)
		return
	in_attesa = true
	if k < 4:
		$Sinistra/Campi.get_child(k).modulate = Color("9ee6b2")
		$Destra/Campi.get_child(k).modulate = Color("9ee6b2")
	$Timbro.visible = true
	$Esito.text = "Nessuna anomalia." if k == 4 else "Prova individuata. Si richiede il controllo di questa voce."
	Sound.sfx("stamp")
	await get_tree().create_timer(pausa_timbro).timeout
	if not is_inside_tree() or not attivo: return
	indice += 1
	in_attesa = false
	selezione = 0
	if indice == pratiche.size(): chiudi(true)
	else: _mostra()
func input_event(e: InputEvent) -> void:
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
