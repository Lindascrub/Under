class_name Crediti
## Chi ha fatto cosa (grafica, musica, caratteri...): il testo è in data/crediti.json.
## Lo usano la pagina Crediti del menu iniziale (scenes/crediti.tscn) e i titoli di coda del finale.

const FILE := "res://data/crediti.json"


static func sezioni() -> Array:
	var f := FileAccess.open(FILE, FileAccess.READ)
	if f == null:
		return []
	var data: Variant = JSON.parse_string(f.get_as_text())
	return (data as Dictionary).get("sezioni", []) if data is Dictionary else []


## Le sezioni di una colonna (0 = tutte), una riga per credito e il titolo in maiuscolo.
static func testo(colonna := 0) -> String:
	var blocks: Array[String] = []
	for s: Dictionary in sezioni():
		if colonna != 0 and int(s.get("colonna", 1)) != colonna:
			continue
		var lines: Array[String] = [str(s.get("titolo", "")).to_upper()]
		for r: Variant in s.get("righe", []):
			lines.append(str(r))
		blocks.append("\n".join(lines))
	return "\n\n".join(blocks)
