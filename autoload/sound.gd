extends Node
## Effetti sonori e musica. I file sono in res://audio/ (generati da tools/make_audio.py).
## Uso: Sound.sfx("coin")  /  Sound.music("quartiere")

const SFX_PLAYERS := 6

var _sfx: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _music_name := ""
var _cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in SFX_PLAYERS:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -8.0
	add_child(_music)


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
	sfx("blip", pitch)


func music(name: String) -> void:
	if name == _music_name:
		return
	_music_name = name
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
