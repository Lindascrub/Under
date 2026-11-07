extends Node
const B:=preload("res://scripts/boss_missions.gd")
var n:Node
var tel:=false
var checks:=0
var errori:Array[String]=[]
var tempo:=0.0
func check(ok:bool,testo:String)->void:
	checks+=1
	if not ok:errori.append(testo);push_error(testo)
func _process(dt:float)->void:
	tempo+=dt
	if tempo>120:push_error("Timeout Fermo");get_tree().quit(1)
func frames()->void:
	await get_tree().process_frame;await get_tree().process_frame
func evento(pos:Vector2,fase:int)->void:
	pos=get_viewport().get_screen_transform()*n.get_global_transform_with_canvas()*pos
	if tel:
		if fase==1:
			var e:=InputEventScreenDrag.new();e.index=0;e.position=pos;Input.parse_input_event(e)
		else:
			var e:=InputEventScreenTouch.new();e.index=0;e.position=pos;e.pressed=fase==0;Input.parse_input_event(e)
	else:
		if fase==1:
			var e:=InputEventMouseMotion.new();e.position=pos;e.button_mask=MOUSE_BUTTON_MASK_LEFT;Input.parse_input_event(e)
		else:
			var e:=InputEventMouseButton.new();e.position=pos;e.global_position=pos;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=fase==0;Input.parse_input_event(e)
	await frames()
func clic(pos:Vector2)->void:
	await evento(pos,0);await evento(pos,2)
func drag(da:Vector2,a:Vector2)->void:
	await evento(da,0);await evento(a,1);await evento(a,2)
func key(nome:String)->void:
	var e:=InputEventAction.new();e.action=nome;e.pressed=true;Input.parse_input_event(e)
	await frames()
	e=InputEventAction.new();e.action=nome;Input.parse_input_event(e)
	await frames()
func crea(fresh:=true)->void:
	if fresh:
		GameState.new_game();GameState.floor_id="-5"
		B.state("-5").merge({"status":"active","return":Router.FONDO},true)
	GameState.minigame={"boss_floor":"-5"}
	n=Control.new();n.set_script(load("res://tests/spia_fermo.gd"))
	get_tree().root.add_child(n);get_tree().current_scene=n
	await frames()
func chiudi()->void:
	n.queue_free();get_tree().current_scene=self;await frames()
func _ready()->void:
	GameState.save_path="user://fermo_circuiti_test.json"
	await frames()
	# Tutte le vecchie combinazioni si aprono identiche, anche quelle fuori dalle vecchie tacche.
	await crea()
	for ritmo in [1,2,3]:
		for extra in [0,5,10,15,20]:
			for decor in [0,1,2]:
				var p:={"intensity":ritmo,"extra":extra,"decor":decor}
				n.dinamo.imposta(p)
				check(n.dinamo.scelta()==p and n.dinamo.v==B.energy_preview(p),"Ripresa conserva ritmo, extra e luci senza scelte automatiche")
	await chiudi()
	for size in [Vector2i(640,360),Vector2i(1280,720),Vector2i(1000,600)]:
		get_window().size=size
		for touch in [false,true]:
			for extra in [false,true]:
				tel=touch;TouchControls.enabled=touch;await crea()
				var d:Node=n.dinamo
				await clic(d.rett("Invia").get_center())
				check(not d.conferma_aperta and B.active("-5"),"Non si conferma la festa senza energia sufficiente")
				await clic(d.rett("Festa/Scelta0").get_center())
				check(int(n.p.decor)==0 and int(n.p.intensity)==2 and int(n.p.extra)==0 and d.v.valid,"Spegnere le luci lascia i servizi e la pausa senza aumentare il ritmo")
				var bin:Rect2=d.rett("Leva/Binario")
				await drag(bin.get_center(),Vector2(bin.get_center().x,bin.end.y-1))
				check(int(n.p.intensity)==3 and int(n.p.extra)==0 and int(n.p.decor)==0,"Trascinare la leva cambia solo il ritmo")
				await drag(Vector2(bin.get_center().x,bin.end.y-1),Vector2(630,350))
				check(int(n.p.intensity)==3,"Rilasciare la leva fuori restituisce il ritmo di partenza")
				await clic(bin.get_center())
				var before:Dictionary=n.p.duplicate(true)
				d._process(3.0)
				check(n.p==before and int(d.v.rest)==15,"L'animazione non consuma pausa o modifica la scelta")
				await drag(Vector2(40,304),Vector2(235,304))
				check(int(n.p.extra)==15 and int(n.p.intensity)==2 and int(n.p.decor)==0 and int(d.v.rest)==0,"Il cartellino sposta solo i minuti extra")
				await clic(d.rett("Festa/Scelta2").get_center())
				check(int(n.p.decor)==2 and int(d.v.production)==90 and d.v.valid,"Le sei luci richiedono energia dopo i servizi")
				await drag(Vector2(235,304),Vector2(70,350))
				check(int(n.p.extra)==15,"Rilasciare il cartellino fuori restituisce la scelta di partenza")
				if not extra:
					await clic(d.rett("Festa/Scelta0").get_center())
					await drag(Vector2(235,304),Vector2(40,304))
				var snap:Dictionary=n.p.duplicate(true)
				await chiudi();GameState.load_game();await crea(false);d=n.dinamo
				check(n.p==JSON.parse_string(JSON.stringify(snap)) and d.scelta()==snap and GameState.money==0,"Ripresa reale senza premio e senza riaccendere le decorazioni")
				await clic(d.rett("Invia").get_center())
				check(d.conferma_aperta and not n.completato,"Anche la scelta senza premio si può rivedere")
				await clic(d.rett("Invia").get_center())
				check(d.conferma_aperta and not n.completato,"Doppio tocco sul vecchio bottone non applica")
				await clic(d.rett("Conferma/Indietro").get_center())
				check(not d.conferma_aperta and B.active("-5"),"Rivedi torna ai tre controlli")
				await clic(d.rett("Invia").get_center())
				await clic(d.rett("Conferma/Applica").get_center())
				await clic(d.rett("Conferma/Applica").get_center())
				check(n.completato and B.state("-5").status=="done" and GameState.money==(600 if extra else 0),"Il premio previsto si accredita una sola volta")
				check(not GameState.is_robot("fermo") and int(GameState.flags.get("boss_fermo_extra",-1))==(15 if extra else 0),"Restano le conseguenze originali per Fermo")
				await chiudi()
	tel=false;TouchControls.enabled=false;await crea()
	n.dinamo.focus=0;await key("move_right")
	check(int(n.p.intensity)==3 and int(n.p.extra)==0,"Tastiera regola il ritmo senza prendere minuti")
	await key("move_down");await key("move_right")
	check(int(n.p.extra)==5 and int(n.p.intensity)==3,"Tastiera regola il cartellino separatamente")
	await key("move_down");await key("confirm")
	check(int(n.p.decor)==0,"Tastiera seleziona il circuito spento")
	n.dinamo._conferma();await key("ui_cancel")
	check(not n.dinamo.conferma_aperta and B.active("-5"),"Annulla chiude la conferma")
	await evento(Vector2(105,304),0);await evento(Vector2(235,304),1);await key("ui_cancel");await evento(Vector2(235,304),2)
	check(int(n.p.extra)==5,"Annulla durante il trascinamento restituisce i minuti e ignora il rilascio")
	await chiudi()
	print("FERMO CIRCUITI: %d controlli, errori %s" % [checks,errori])
	get_tree().quit(errori.size())
