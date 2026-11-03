extends Node
## Rapporto di collisioni e profondità di tutte le mappe (vedi audit_mappa.gd). Non fallisce: stampa.
##   Godot --headless --path . res://tests/collisioni/rapporto.tscn [-- --solo=citta]

const MAPPE := {
	"fondo": "res://chapters/c1/fondo.tscn", "sottoufficio": "res://chapters/c2/sottoufficio.tscn",
	"mercato": "res://chapters/c3/mercato.tscn", "banca": "res://chapters/c4/banca.tscn",
	"citta": "res://chapters/c5/citta.tscn", "casa_comune": "res://chapters/c5/casa_comune.tscn",
	"cima": "res://chapters/c6/cima.tscn",
	"ufficio_capo": "res://scenes/world/boss_office.tscn",
}

var frame := 0


func _ready() -> void:
	await get_tree().process_frame
	GameState.save_path = "user://collisioni_rapporto.json"
	var solo := ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--solo="):
			solo = a.trim_prefix("--solo=")
	for nome: String in MAPPE:
		if solo != "" and nome not in solo.split(","):
			continue
		var room: Room = await MappaAperta.apri(self, MAPPE[nome])
		if room == null:
			print("MAPPA ", nome, ": non si apre")
			continue
		var a := AuditMappa.new(room)
		var starts: Array = room.spawns.values()
		starts.append(room.player.position)
		a.flood(starts)
		a.check()
		print("MAPPA ", nome, ": ", a.reach.size(), " punti raggiunti, ", a.count(), " problemi, uscite raggiunte ", a.exits_reached.size(), "/", a.exits.size())
		print(a.report())
		await MappaAperta.chiudi(self, room)
	get_tree().quit(0)


func _process(_delta: float) -> void:
	frame += 1
	MappaAperta.salta_dialoghi(frame)
