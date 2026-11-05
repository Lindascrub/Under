extends Node2D
## Il genitore gestisce premi e salvataggi; ogni scena possiede regole e nodi.
signal finito(vinto: bool, parziale: bool)
var attivo := true
var errori := 0
var configurazione: Dictionary = {}
func avvia(c: Dictionary) -> void:
	configurazione = c
func chiudi(vinto: bool, parziale := false) -> void:
	if not attivo: return
	attivo = false
	finito.emit(vinto, parziale)
func input_event(_event: InputEvent) -> void:
	pass
func punta(_pos: Vector2, _step: int) -> void:
	pass
func ferma() -> void:
	attivo = false
	set_process(false)
func istruzione(tel: String, pc: String) -> void:
	$Aiuto.text = tel if TouchControls.enabled else pc
