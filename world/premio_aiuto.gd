extends Node2D
## Il premio che si vede: resta nella stanza dopo che hai vinto il minigioco di qualcuno
## (la lampadina calda sopra Mina, le scatole di Bulbo in ordine...). Si disegna nell'editor, come
## figli di questo nodo; si vede solo se hai vinto ("stelle_<npc_id>" in GameState.flags, lo scrive
## scenes/minigame/risposta.gd). Resta anche quando la stanza diventa grigia.

## L'id della persona (in data/npcs.json) che hai aiutato.
@export var npc_id := ""
## I nodi che spariscono quando c'è il premio (per esempio le lampadine in disordine).
@export var al_posto_di: Array[NodePath] = []


func _ready() -> void:
	var vinto := int(GameState.flags.get("stelle_" + npc_id, 0)) > 0
	visible = vinto
	for p in al_posto_di:
		var n := get_node_or_null(p) as CanvasItem
		if n:
			n.visible = not vinto
