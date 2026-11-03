extends Node
## Registra i comandi da tastiera all'avvio, così non serve configurarli a mano nell'editor.
## Tiene anche lo schermo intero (F11, o dalle Impostazioni), salvato con le altre impostazioni.

const BINDINGS := {
	"move_up": [KEY_UP, KEY_W],
	"move_down": [KEY_DOWN, KEY_S],
	"move_left": [KEY_LEFT, KEY_A],
	"move_right": [KEY_RIGHT, KEY_D],
	"confirm": [KEY_Z, KEY_ENTER, KEY_SPACE],
	"cancel": [KEY_X, KEY_SHIFT, KEY_ESCAPE],
	"menu": [KEY_C],
	"fullscreen": [KEY_F11],
}


func _ready() -> void:
	for action: String in BINDINGS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: int in BINDINGS[action]:
			_add_key_binding(action, key)
	var cfg := ConfigFile.new()
	if cfg.load(Sound.SETTINGS) == OK and bool(cfg.get_value("schermo", "intero", false)):
		_apply_fullscreen(true)


## Registra sia la posizione fisica sia il tasto logico. La prima mantiene WASD
## coerente su layout diversi; il secondo supporta tastiere virtuali, controllo
## remoto e strumenti di accessibilità che non forniscono un physical_keycode.
func _add_key_binding(action: StringName, key: int) -> void:
	var physical := InputEventKey.new()
	physical.physical_keycode = key
	InputMap.action_add_event(action, physical)

	var logical := InputEventKey.new()
	logical.keycode = key
	InputMap.action_add_event(action, logical)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		get_viewport().set_input_as_handled()
		set_fullscreen(not is_fullscreen())


## Lo schermo intero si può cambiare solo sul computer (sul telefono il gioco è sempre a tutto schermo).
static func can_fullscreen() -> bool:
	return not OS.has_feature("mobile") and DisplayServer.get_name() != "headless"


static func is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


static func set_fullscreen(on: bool) -> void:
	if not can_fullscreen():
		return
	_apply_fullscreen(on)
	var cfg := ConfigFile.new()
	cfg.load(Sound.SETTINGS)
	cfg.set_value("schermo", "intero", on)
	cfg.save(Sound.SETTINGS)


static func _apply_fullscreen(on: bool) -> void:
	if can_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)
