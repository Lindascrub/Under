extends Node
## Controlla le playlist e gli effetti importati senza attraversare le mappe dei capitoli.

var checks := 0
var failures: Array[String] = []


func _ready() -> void:
	_test_buses()
	_test_playlists()
	_test_arcade_effects()
	Sound.music("")
	print("AUDIO TEST: %d verifiche, errori %s" % [checks, str(failures)])
	get_tree().quit(failures.size())


func _test_buses() -> void:
	check(AudioServer.get_bus_index("Music") >= 0, "bus Music presente")
	check(AudioServer.get_bus_index("SFX") >= 0, "bus SFX presente")


func _test_playlists() -> void:
	var long_moods := ["festa", "attesa", "mercato", "banca", "citta", "quartiere", "cima", "presidente"]
	for mood: String in long_moods:
		check((Sound.PLAYLISTS[mood] as Array).size() >= 2, "%s alterna almeno due brani" % mood)
	var owners := {}
	for mood: String in Sound.PLAYLISTS:
		for track: String in Sound.PLAYLISTS[mood]:
			check(not owners.has(track), "%s non è riciclato fra %s e %s" % [track, owners.get(track, ""), mood])
			owners[track] = mood
			check(ResourceLoader.exists(Sound.MUSIC_DIR + track + ".ogg"), "brano presente: " + track)
	for mood: String in long_moods:
		Sound.music(mood)
		var first := Sound.current_track()
		Sound.call("_on_music_finished")
		check(Sound.current_track() != first, "%s cambia brano a fine traccia" % mood)


func _test_arcade_effects() -> void:
	for effect: String in ["select_2", "confirm_2", "blocked", "collect_3", "computer_1", "chime"]:
		var path := "res://audio/arcade/%s.wav" % effect
		check(ResourceLoader.exists(path), "effetto presente: " + effect)
		var stream := load(path) as AudioStreamWAV
		check(stream != null and stream.get_length() > 0.0 and stream.get_length() < 2.0, "effetto breve e valido: " + effect)


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)
