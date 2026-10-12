extends Node
## Registra i comandi da tastiera all'avvio, così non serve configurarli a mano nell'editor.

const BINDINGS := {
	"move_up": [KEY_UP, KEY_W],
	"move_down": [KEY_DOWN, KEY_S],
	"move_left": [KEY_LEFT, KEY_A],
	"move_right": [KEY_RIGHT, KEY_D],
	"confirm": [KEY_Z, KEY_ENTER, KEY_SPACE],
	"cancel": [KEY_X, KEY_SHIFT, KEY_ESCAPE],
	"menu": [KEY_C],
}


func _ready() -> void:
	for action: String in BINDINGS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: int in BINDINGS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
