extends Node2D
const B := preload("res://scripts/boss_missions.gd")
const PRODOTTI := preload("res://scripts/product_art.gd")
@export var piano := "-4"
@export var durata_spostamento := 0.3
var azioni: Array[String] = []
var origine_foglio := Vector2.ZERO
func _ready() -> void:
	origine_foglio = $Documento.position if has_node("Documento") else Vector2.ZERO
	$Aiuto.text = "Tocca una scelta. SALVA ED ESCI conserva il lavoro." if TouchControls.enabled else "FRECCE: scegli. INVIO o clic: usa. SALVA ED ESCI conserva il lavoro."
func aggiorna(p: Dictionary, messaggio: String) -> void:
	$Esito.text = messaggio
	match piano:
		"-4":
			azioni.assign(["doc_0", "doc_1", "doc_2", "doc_3", "exit"])
			var i := mini(3, int(p["document"]))
			var d: Dictionary = B.DOCUMENTS[i]
			$Stato.text = "Leggi il fascicolo e scegli come procedere."
			$Documento/Contenuto.text = "%s · %d/4\n%s\n\n%s" % [d["id"], i + 1, d["title"], d["body"]]
		"-3":
			azioni.assign(["rate", "reference", "units", "visible", "submit", "exit"])
			var v := B.market_preview(p)
			$Stato.text = "Etichetta %d/3 · Controlla sconto, quantità e condizioni." % (int(p["round"]) + 1)
			$Acqua.visible = str(v["product"]) == "acqua"
			$Prodotto.visible = not $Acqua.visible
			if $Prodotto.visible: $Prodotto.texture = PRODOTTI.texture(str(v["product"]))
			$Cartellino/Percentuale.text = str(v["product"]).to_upper() + "\n-%d%%" % int(v["rate"])
			$Cartellino/Condizioni.text = ("%d pezzi × %s\nRiferimento %s" % [int(v["units"]), B.cash(int(v["each"])), B.cash(int(v["ref"]))]) if bool(p["visible"]) else "Condizioni al terminale."
			$Cassa/Totale.text = "ALLA CASSA\n%d pezzi · %s" % [int(v["units"]), B.cash(int(v["basket"]))]
			$Azioni.get_child(0).text = "Sconto: %d%%" % int(p["rate"])
			$Azioni.get_child(1).text = "Riferimento: " + ("oggi" if int(p["reference"]) == 0 else "futuro")
			$Azioni.get_child(2).text = "Quantità minima: %d" % int(p["units"])
			$Azioni.get_child(3).text = "Condizioni: " + ("leggibili" if bool(p["visible"]) else "al terminale")
		"-2":
			azioni.assign(["months", "apr", "fee", "visible", "proposal", "exit"])
			var v := B.contract_preview(p)
			$Stato.text = "Controlla rata e totale. È una proposta, non una firma."
			$Interno/Dati.text = "PRESTITO · COPIA INTERNA\n1.200 € · max 65 €/mese\nRata %s · %d mesi\nUltima %s\nInteressi %s\nCommissione %d €\nTOTALE %s" % [B.cash(int(v["monthly"])), int(v["months"]), B.cash(int(v["last"])), B.cash(int(v["interest"])), int(p["fee"]), B.cash(int(v["total"]))]
			if messaggio != "": $Stato.text = ""
			$Olga/Dati.text = "OLGA LEGGE\nRata %s\n%d mesi" % [B.cash(int(v["monthly"])), int(v["months"])]
			$Olga/Condizioni.text = "Interessi %s\nCommissione %d €\nTotale %s" % [B.cash(int(v["interest"])), int(p["fee"]), B.cash(int(v["total"]))]
			$Olga/Copertura.visible = not bool(p["visible"])
			$Azioni.get_child(0).text = "Durata: %d mesi" % int(p["months"])
			$Azioni.get_child(1).text = "Tasso annuo: %d%%" % int(p["apr"])
			$Azioni.get_child(2).text = "Commissione: %d €" % int(p["fee"])
			$Azioni.get_child(3).text = "Riepilogo: " + ("in prima pagina" if bool(p["visible"]) else "solo interno")
		"0":
			azioni.assign(["source", "cut", "add", "facts", "undo", "broadcast", "exit"])
			var fonti := B.news_sources()
			if fonti.is_empty():
				$Intera/Testo.text = "Prima raccogli le registrazioni in piazza."
				return
			var s: Dictionary = fonti[posmod(int(p["source"]), fonti.size())]
			$Stato.text = "Tre fonti diverse, entro 60 secondi. Decidi cosa va in onda."
			if messaggio != "": $Stato.text = ""
			$Intera/Testo.text = "REGISTRAZIONE · %s\n«%s»\n\nCONTESTO: %s" % [s["who"], s["quote"], s["context"]]
			$Televisore/Testo.text = ("IN ONDA · " + B.cut_headline(str(s["id"])) + "\n«" + B.cut_quote(s) + "»\nCONTESTO ESCLUSO") if bool(p["cut"]) else ("IN ONDA · " + str(s["who"]) + "\n«" + str(s["quote"]) + "»\n" + str(s["context"]))
			$Televisore.modulate = Color("ffc9bb") if bool(p["cut"]) else Color.WHITE
			$Durata.value = B.news_time(p)
			$Minuti.text = "%d/60 secondi · Fatti verificati: %s" % [B.news_time(p), "10s inclusi" if bool(p["facts"]) else "esclusi"]
			$Azioni.get_child(1).text = "Montaggio: " + ("tagliato" if bool(p["cut"]) else "integrale")
			$Azioni.get_child(3).text = "Fatti verificati: " + ("sì" if bool(p["facts"]) else "no")
func bersagli() -> Array:
	var out: Array = []
	var figli := $Azioni.get_children()
	for i in mini(azioni.size(), figli.size()):
		out.append({"rect": figli[i].get_global_rect(), "action": azioni[i]})
	return out
func evidenzia(i: int) -> void:
	var figli := $Azioni.get_children()
	for k in figli.size():
		figli[k].modulate = Color("ffe49d") if k == i and not TouchControls.enabled else Color.WHITE
func anima(azione: String) -> void:
	if piano == "-4" and azione.begins_with("doc_"):
		var i := azione.trim_prefix("doc_").to_int()
		var foglio := $Documento.duplicate()
		add_child(foglio)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(foglio, "position", $Azioni.get_child(i).position, durata_spostamento)
		tw.tween_property(foglio, "scale", Vector2(0.2, 0.2), durata_spostamento)
		tw.chain().tween_callback(foglio.queue_free)
	elif piano == "-3" and azione == "submit":
		$Cassa.modulate = Color("ffe49d")
		Sound.sfx("stamp")
		await get_tree().create_timer(durata_spostamento).timeout
		$Cassa.modulate = Color.WHITE
