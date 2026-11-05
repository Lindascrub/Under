extends Node2D
## Dimostrazioni dei primi aiuti del Fondo. Immagini e punti del gesto nella scena.
signal finita
@export var durata := 4.2
@export var durata_riprova := 1.0
@export var colori_fili: Array[Color] = [Color("d23b3b"), Color("39b6ff"), Color("ffe14d"), Color("3ddc84")]
@onready var testo: Label = $Testo
@onready var lampadina: Sprite2D = $Lampadina
@onready var puntatore: Sprite2D = $Indicatore
@onready var cavo: Line2D = $Cavo
@onready var centro: Marker2D = $Centro
@onready var buone: Marker2D = $Buone
@onready var rotte: Marker2D = $Rotte
@onready var avvita: Marker2D = $Avvita
var tipo := ""
var demo := false
var tempo := 0.0
var riprova_t := 0.0
var ordine: Array = []
var filo := 0


func mostra(gioco: String, colori: Array) -> void:
	tipo = gioco
	ordine = colori.duplicate()
	filo = 0
	tempo = 0.0
	demo = true
	visible = true


func aggiorna(gioco: String, stato: String, colori: Array, fatti: Array) -> void:
	if demo:
		return
	tipo = gioco
	ordine = colori.duplicate()
	for i in 4:
		if i not in fatti:
			filo = i
			break
	visible = true
	lampadina.visible = false
	cavo.visible = false
	if riprova_t > 0.0:
		return
	if tipo == "bulbs":
		match stato:
			"fioca": testo.text = "Scorri su o giù finché resta accesa." if TouchControls.enabled else "Premi SU o GIÙ finché resta accesa."
			"rotta": testo.text = "Scorri a sinistra: nelle ROTTE." if TouchControls.enabled else "SINISTRA: mettila nelle ROTTE."
			_: testo.text = "Scorri a destra: nelle BUONE." if TouchControls.enabled else "DESTRA: mettila nelle BUONE."
		puntatore.position = avvita.position if stato == "fioca" else (rotte.position if stato == "rotta" else buone.position)
		puntatore.rotation = -PI / 2.0 if stato == "fioca" else (PI if stato == "rotta" else 0.0)
	else:
		testo.text = "Trascina il filo sul colore uguale. Poi lascia." if TouchControls.enabled else "Trascina col mouse sul colore uguale. Rilascia."


func riprova() -> void:
	riprova_t = durata_riprova
	testo.text = "Riprova: questa prima prova è senza penalità."


func _process(delta: float) -> void:
	if not visible:
		return
	tempo += delta
	riprova_t = maxf(0.0, riprova_t - delta)
	puntatore.modulate.a = 0.65 + 0.35 * sin(tempo * 5.0)
	if tipo == "wires" and ordine.size() == 4:
		var da: Vector2 = get_node("FiliSinistra/%d" % filo).position
		var a: Vector2 = get_node("FiliDestra/%d" % ordine.find(filo)).position
		var k := minf(1.0, fmod(tempo / durata, 1.0) * 1.4)
		puntatore.position = da.lerp(a, k)
		puntatore.rotation = (a - da).angle()
		if demo:
			cavo.visible = true
			cavo.points = PackedVector2Array([da, puntatore.position])
			cavo.default_color = colori_fili[filo]
	if not demo:
		return
	if tipo == "bulbs":
		lampadina.visible = true
		var k := clampf(tempo / durata, 0.0, 1.0)
		if k < 0.65:
			lampadina.position = centro.position
			lampadina.modulate = Color.WHITE if k > 0.4 or int(tempo * 6.0) % 2 == 0 else Color(0.25, 0.25, 0.3)
			lampadina.rotation = sin(tempo * 8.0) * 0.16
			puntatore.position = avvita.position
			puntatore.rotation = -PI / 2.0
			testo.text = "Scorri su o giù finché resta accesa." if TouchControls.enabled else "Premi SU o GIÙ finché resta accesa."
		else:
			lampadina.modulate = Color.WHITE
			lampadina.rotation = 0.0
			lampadina.position = centro.position.lerp(buone.position, (k - 0.65) / 0.35)
			puntatore.position = buone.position
			puntatore.rotation = 0.0
			testo.text = "Accesa: ora va nelle BUONE."
	else:
		testo.text = "Trascina il filo sul colore uguale. Poi lascia." if TouchControls.enabled else "Trascina col mouse sul colore uguale. Rilascia."
	if tempo >= durata:
		demo = false
		lampadina.visible = false
		cavo.visible = false
		finita.emit()
