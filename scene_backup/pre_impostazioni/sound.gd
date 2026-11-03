extends Node
## Effetti sonori e musica. I file sono in res://audio/ (generati da tools/make_audio.py).
## Uso: Sound.sfx("coin")  /  Sound.music("quartiere")
## La musica vera sta in res://assets/music/ (vedi PLAYLISTS); gli effetti in res://audio/.

const SFX_PLAYERS := 6

var _sfx: Array[AudioStreamPlayer] = []
var _blip: AudioStreamPlayer
var _next := 0
var _music: AudioStreamPlayer
var _music_name := ""
var _cache := {}


const SETTINGS := "user://impostazioni.cfg"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus)
			AudioServer.set_bus_send(idx, "Master")
	for i in SFX_PLAYERS:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx.append(p)
	# la voce dei dialoghi ha un canale tutto suo: si zittisce appena salti avanti
	_blip = AudioStreamPlayer.new()
	_blip.bus = "SFX"
	add_child(_blip)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -8.0
	_music.bus = "Music"
	_music.finished.connect(_on_music_finished)
	add_child(_music)
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		_apply("Music", float(cfg.get_value("audio", "Music", 1.0)))
		_apply("SFX", float(cfg.get_value("audio", "SFX", 1.0)))


## Volume di un canale ("Music" o "SFX"), da 0 a 1.
func volume(bus: String) -> float:
	var idx := AudioServer.get_bus_index(bus)
	if idx == -1 or AudioServer.is_bus_mute(idx):
		return 0.0
	return snappedf(db_to_linear(AudioServer.get_bus_volume_db(idx)), 0.01)


func set_volume(bus: String, v: float) -> void:
	_apply(bus, v)
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("audio", bus, clampf(v, 0.0, 1.0))
	cfg.save(SETTINGS)


func _apply(bus: String, v: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx == -1:
		return
	v = clampf(v, 0.0, 1.0)
	AudioServer.set_bus_mute(idx, v <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.001)))


func _load(file: String) -> AudioStream:
	if _cache.has(file):
		return _cache[file]
	var path := "res://audio/%s.wav" % file
	var stream: AudioStream = load(path) if ResourceLoader.exists(path) else null
	_cache[file] = stream
	return stream


func sfx(name: String, pitch := 1.0) -> void:
	var stream := _load(name)
	if stream == null:
		return
	var p := _sfx[_next]
	_next = (_next + 1) % _sfx.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.play()


## Il "bip" delle lettere, con un tono diverso per ogni personaggio.
func blip(pitch := 1.0) -> void:
	var stream := _load("blip")
	if stream == null:
		return
	_blip.stream = stream
	_blip.pitch_scale = pitch
	_blip.play()


## Zittisce la voce dei dialoghi (quando il testo viene saltato o finisce).
func stop_blip() -> void:
	_blip.stop()


## Rallenta (o riporta normale) la musica: 1.0 = normale.
func music_pitch(p: float, time := 2.0) -> void:
	var tw := create_tween()
	tw.tween_property(_music, "pitch_scale", p, time)


## La musica si spegne piano piano (poi resta il silenzio, come Sound.music("")).
func music_fade_out(time := 4.0) -> void:
	_fade = create_tween()
	_fade.tween_property(_music, "volume_db", -60.0, time).set_ease(Tween.EASE_IN)
	_fade.tween_callback(music.bind(""))


var _fade: Tween


## Le canzoni vere (pacchetti comprati/scaricati, in res://assets/music/, esclusi da git come LimeZu).
## Ogni atmosfera è una scaletta: finita una canzone ne parte un'altra (mai la stessa due volte di fila).
## Se i file mancano si usa il vecchio segnaposto audio/music_<nome>.wav. Elenco: docs/ASSET_LIST.md.
const MUSIC_DIR := "res://assets/music/"
const PLAYLISTS := {
	# i piani: una canzone ciascuno
	"festa": ["gettinsillywithit"],
	"attesa": ["superretrolounge"],
	"mercato": ["waitingroomennui"],
	"banca": ["vacationdayadventure"],
	"citta": ["metropolitancosmopolitan"],
	"quartiere": ["wood_forest_town"],
	"cima": ["royal_castle"],
	"presidente": ["magic_temple"],
	"ascensore": ["nighttownwaltz"],
	# i turni: uno per piano (scenes/minigame/work.gd, JOB_MUSIC)
	"turno_dinamo": ["pkmngoldluckycornerioweitalltoyou"],
	"turno_callcenter": ["sugarrushzoomies"],
	"turno_cassa": ["lifeishardbase"],
	"turno_sportello": ["alleycat"],
	"turno_smistamento": ["pkmngoldluckycornerioweitalltoyou"],
	"lavoro": ["pkmngoldluckycornerioweitalltoyou"],
	# il capo: quando telefona, e nel furto che ti chiede
	"capo": ["metropolitancosmopolitan"],
	# i minigiochi d'aiuto: una canzone per persona (campo "music" del minigioco in data/npcs.json)
	"aiuto_mina": ["hewillneverbetheapeescapesoundtrack"],
	"aiuto_bulbo": ["hewillneverbetheapeescapesoundtrack"],
	"aiuto_tilde": ["jestersdistraction"],
	"aiuto_ercole": ["jestersdistraction"],
	"aiuto_leda": ["mischiefgroove"],
	"aiuto_amir": ["mischiefgroove"],
	"aiuto_olga": ["distantskyline"],
	"aiuto_teo": ["distantskyline"],
	"aiuto_ada": ["hewillneverbetheapeescapesoundtrack"],
	"aiuto_nadir": ["hewillneverbetheapeescapesoundtrack"],
	"aiuto": ["hewillneverbetheapeescapesoundtrack"],
	# il resto
	"epilogo": ["long_journey", "holy_sanctuary", "melancholic_bittersweet_groovycavejourney"],
	"notte": ["nighttownwaltz"],
	"nives": ["lively_city"],
	"fondo": ["dripstonecave"],
	"battaglia": ["battle_theme_i", "battle_theme_ii", "haveyoueverplayedgrimdawn"],
	"tensione": ["tension1", "tension2"],
}

## Atmosfere nuove senza un segnaposto loro: quale vecchio .wav usare se mancano le canzoni.
const OLD_PLACEHOLDER := {"nives": "aiuto", "mercato": "festa", "tensione": "presidente"}

var _playlist: Array = []
var _track := ""


func music(name: String) -> void:
	if name == _music_name:
		return
	_music_name = name
	_music.pitch_scale = 1.0
	# una canzone nuova (o il silenzio) interrompe la dissolvenza e torna al volume normale
	if _fade and _fade.is_valid():
		_fade.kill()
	_music.volume_db = -8.0
	_playlist = []
	_track = ""
	if name == "":
		_music.stop()
		return
	for t: String in PLAYLISTS.get(name, []):
		if ResourceLoader.exists(MUSIC_DIR + t + ".ogg"):
			_playlist.append(t)
	if not _playlist.is_empty():
		_next_track()
		return
	var stream := _load("music_" + str(OLD_PLACEHOLDER.get(name, name))) as AudioStreamWAV
	if stream == null:
		_music.stop()
		return
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	_music.stream = stream
	_music.play()


## La canzone dopo nella scaletta (a caso, ma non quella appena finita).
func _next_track() -> void:
	var pool := _playlist.filter(func(t: String) -> bool: return t != _track)
	if pool.is_empty():
		pool = _playlist
	_track = str(pool.pick_random())
	var stream := load(MUSIC_DIR + _track + ".ogg") as AudioStreamOggVorbis
	if stream == null:
		return
	# una canzone sola: si ripete; se ce ne sono di più, alla fine si cambia
	stream.loop = _playlist.size() == 1
	_music.stream = stream
	_music.play()


func _on_music_finished() -> void:
	if not _playlist.is_empty():
		_next_track()


## La canzone che suona adesso ("" se è un segnaposto o niente). Per i test.
func current_track() -> String:
	return _track


## Temporary cinematic music restores the exact stream, position, pitch and silence.
func capture_music() -> Dictionary:
	return {"name": _music_name, "track": _track, "playlist": _playlist.duplicate(),
		"stream": _music.stream, "position": _music.get_playback_position(), "playing": _music.playing,
		"pitch": _music.pitch_scale, "volume": _music.volume_db}

func restore_music(saved: Dictionary) -> void:
	_music.stop()
	_music_name = str(saved.get("name", ""))
	_track = str(saved.get("track", ""))
	_playlist = saved.get("playlist", []).duplicate()
	_music.stream = saved.get("stream")
	_music.pitch_scale = float(saved.get("pitch", 1.0))
	_music.volume_db = float(saved.get("volume", -8.0))
	if bool(saved.get("playing", false)) and _music.stream:
		_music.play(float(saved.get("position", 0.0)))
