extends Node
## Garanzia PC / telefono: legge TUTTE le frasi del gioco (script, data/*.json, scene) e controlla
## che sul telefono non ci sia niente del PC (frecce, INVIO, tasti, clic, mouse, ESC...) e sul PC
## niente del telefono (tocca, dito, scorri...).
## Per sapere dove si vede una frase guarda come è scritta:
##   "A" if TouchControls.enabled else "B"  -> A solo telefono, B solo PC
##   dentro  if TouchControls.enabled: ... else: ...  -> come sopra
##   [TEL] ... / [PC] ...  -> solo quel dispositivo (GameState.per_dispositivo)
##   dopo un commento "# (solo PC)" fino alla fine della funzione -> solo PC
##   un file in SOLO_PC / SOLO_TEL -> solo quel dispositivo
##   tutto il resto -> si vede su tutti e due
## Le frasi passano da GameState.fmt, come nel gioco ("Premi {ok}" sul telefono diventa "Tocca lo schermo").
## Le eccezioni (un "clic" che è un rumore, "tocca a te"...) sono in tests/testi_dispositivo_eccezioni.txt.
## Esegui:  Godot --headless --path . res://tests/testi_dispositivo_test.tscn
## Alla fine stampa "TESTI DISPOSITIVO OK" oppure le frasi sbagliate.

const CARTELLE := ["res://autoload", "res://chapters", "res://scenes", "res://scripts", "res://world", "res://data"]
## pagine che esistono solo su un dispositivo
const SOLO_PC := ["res://scenes/comandi.tscn", "res://scenes/chiudi_gioco.tscn"]
const SOLO_TEL := ["res://scenes/comandi_telefono.tscn", "res://autoload/touch_controls.gd"]
const ECCEZIONI := "res://tests/testi_dispositivo_eccezioni.txt"

## parole che sul telefono non devono comparire (minuscole e maiuscole)
const NO_TEL := "\\b(frecce|freccia|invio|tastiera|mouse|clic|clicca|cliccare|cliccando|click|esc|shift|f11|tasto|tasti|pc)\\b"
## nomi dei tasti scritti in maiuscolo, che sul telefono non hanno senso ("a SINISTRA" è una direzione: va bene)
const NO_TEL_TASTI := "(?<!\\ba )(?<!\\bin )\\b(SU|GIÙ|SINISTRA|DESTRA)\\b"
## parole che sul PC non devono comparire
const NO_PC := "\\b(tocca|tocchi|toccare|toccando|dito|dita|scorri|scorrere|scorrendo|touch)\\b"

var _no_tel := RegEx.create_from_string("(?i)" + NO_TEL)
var _no_tel_tasti := RegEx.create_from_string(NO_TEL_TASTI)
var _no_pc := RegEx.create_from_string("(?i)" + NO_PC)
var _stringa := RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"")
var _eccezioni: Array[String] = []
var _errori: Array[String] = []
var _frasi := 0


func _ready() -> void:
	_leggi_eccezioni()
	var file: Array[String] = []
	for c: String in CARTELLE:
		_trova(c, file)
	for f in file:
		if f.ends_with(".gd"):
			_script(f)
		elif f.ends_with(".json"):
			_json(f)
		elif f.ends_with(".tscn"):
			_scena(f)
	TouchControls.enabled = false
	print("TESTI DISPOSITIVO: %d file, %d frasi controllate" % [file.size(), _frasi])
	if _errori.is_empty():
		print("TESTI DISPOSITIVO OK")
	else:
		for e in _errori:
			printerr(e)
		print("TESTI DISPOSITIVO: %d frasi sbagliate" % _errori.size())
	get_tree().quit(0 if _errori.is_empty() else 1)


func _leggi_eccezioni() -> void:
	var f := FileAccess.open(ECCEZIONI, FileAccess.READ)
	if f == null:
		return
	while not f.eof_reached():
		var r := f.get_line().strip_edges()
		if r != "" and not r.begins_with("#"):
			_eccezioni.append(r.get_slice("|", 0).strip_edges())


func _trova(dir: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for sub in d.get_directories():
		_trova(dir.path_join(sub), out)
	for f in d.get_files():
		if f.get_extension() in ["gd", "json", "tscn"]:
			out.append(dir.path_join(f))


## Un blocco "if TouchControls.enabled:" vale per il telefono, il suo "else:" per il PC.
func _script(path: String) -> void:
	var righe := FileAccess.get_file_as_string(path).split("\n")
	var blocchi: Array = []   # [rientro, "tel"/"pc"]
	var file_dove := "pc" if path in SOLO_PC else ("tel" if path in SOLO_TEL else "tutti")
	var solo_pc := false
	for n in righe.size():
		var riga := righe[n]
		var testo := riga.strip_edges()
		if riga.begins_with("func "):
			solo_pc = false
		if testo.begins_with("# (solo PC)"):
			solo_pc = true
		if testo == "" or testo.begins_with("#"):
			continue
		var rientro := riga.length() - riga.lstrip("\t ").length()
		while not blocchi.is_empty() and rientro <= int(blocchi[-1][0]) and not (testo.begins_with("else") and rientro == int(blocchi[-1][0])):
			blocchi.pop_back()
		if testo.begins_with("else:") and not blocchi.is_empty() and rientro == int(blocchi[-1][0]):
			blocchi[-1][1] = "pc" if blocchi[-1][1] == "tel" else "tel"
			continue
		var dove := file_dove if blocchi.is_empty() else str(blocchi[-1][1])
		if solo_pc:
			dove = "pc"
		if testo.begins_with("if TouchControls.enabled:") or testo.begins_with("elif TouchControls.enabled:"):
			blocchi.append([rientro, "tel"])
			continue
		if testo.begins_with("if not TouchControls.enabled:"):
			blocchi.append([rientro, "pc"])
			continue
		if testo.begins_with("##") or testo.contains("push_error") or testo.contains("print("):
			continue
		var split := riga.find("if TouchControls.enabled else")
		for m in _stringa.search_all(riga):
			var s := m.get_string(1).c_unescape()
			var qui := dove
			if split >= 0:
				qui = "tel" if m.get_start() < split else "pc"
			_controlla(s, qui, "%s:%d" % [path, n + 1])


func _json(path: String) -> void:
	var dati: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_json_valore(dati, path)


func _json_valore(v: Variant, path: String) -> void:
	if v is String:
		_controlla(v, "tutti", path)
	elif v is Array:
		for x: Variant in v:
			_json_valore(x, path)
	elif v is Dictionary:
		for k: Variant in v:
			_json_valore(v[k], path)


func _scena(path: String) -> void:
	var dove := "pc" if path in SOLO_PC else ("tel" if path in SOLO_TEL else "tutti")
	var righe := FileAccess.get_file_as_string(path).split("\n")
	for n in righe.size():
		var riga := righe[n]
		if riga.begins_with("text = ") or riga.begins_with("placeholder_text = ") or riga.begins_with("tooltip_text = "):
			for m in _stringa.search_all(riga):
				_controlla(m.get_string(1).c_unescape(), dove, "%s:%d" % [path, n + 1])


func _controlla(frase: String, dove: String, origine: String) -> void:
	# solo le frasi vere: niente percorsi, nomi di suoni, azioni
	if frase.length() < 3 or frase.begins_with("res://") or not frase.contains(" ") and frase.to_lower() == frase:
		return
	_frasi += 1
	if dove != "pc":
		TouchControls.enabled = true
		var t := GameState.fmt(frase)
		var m := _no_tel.search(t)
		if m == null:
			m = _no_tel_tasti.search(t)
		if t != "" and m != null and not _eccezione(frase):
			_errori.append("TELEFONO  %s  \"%s\"  (parola: %s)" % [origine, t, m.get_string()])
	if dove != "tel":
		TouchControls.enabled = false
		var t := GameState.fmt(frase)
		var m := _no_pc.search(t)
		if t != "" and m != null and not _eccezione(frase):
			_errori.append("PC  %s  \"%s\"  (parola: %s)" % [origine, t, m.get_string()])


func _eccezione(frase: String) -> bool:
	for e in _eccezioni:
		# "=FRASE": solo la frase intera, non un pezzo
		if frase == e.substr(1) if e.begins_with("=") else frase.contains(e):
			return true
	return false
