extends Node

func _ready() -> void:
	await get_tree().process_frame
	var work := load("res://scenes/minigame/work.gd").new() as Node2D
	var failures: Array[String] = []
	for data in [[0.0,0,0.0],[3.0,1,0.4],[10.0,2,1.0],[12.0,0,1.25]]:
		work.set("score",data[0]);work.set("mistakes",data[1]);work.set("game","cassa")
		var lines: Array=work.call("result_lines",float(data[2]),120)
		var text:=" ".join(PackedStringArray(lines)).to_lower()
		if "perfett" in text:failures.append("False perfection claim")
		if float(data[0])==0 and not "non hai completato" in text:failures.append("Idle shift pretends activities were completed")
		if not ("errori registrati: %d" % int(data[1])) in text:failures.append("Errors missing from result")
	work.set("game","pedal");work.set("score",9.5)
	if not "Secondi nella fascia corretta: 9" in str(work.call("result_lines",0.8,120)):failures.append("Pedaling seconds counted as operations")
	work.free()
	print("WORK RESULTS: 4 outcomes + pedal units, failures=",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
