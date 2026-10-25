extends Node
## Effetti sonori e musica. I file sono in res://audio/ (generati da tools/make_audio.py).
## Uso: Sound.sfx("coin")  /  Sound.music("quartiere")

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


func music(name: String) -> void:
	if name == _music_name:
		return
	_music_name = name
	_music.pitch_scale = 1.0
	if name == "":
		_music.stop()
		return
	var stream := _load("music_" + name) as AudioStreamWAV
	if stream == null:
		_music.stop()
		return
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	_music.stream = stream
	_music.play()
