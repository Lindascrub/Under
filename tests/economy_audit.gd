extends Node
const B := preload("res://scripts/boss_missions.gd")
func _ready() -> void:
 GameState.save_path = "user://test_boss_economy.json"
 var scenarios := [
  {"name": "sempre premio", "accept": [0, 1, 2, 3, 4]},
  {"name": "sempre alternativa", "accept": []},
  {"name": "misto", "accept": [0, 2, 4]},
  {"name": "nessun aiuto NPC, rata minima", "accept": [], "minimum": true},
  {"name": "tutti aiutati", "accept": [], "gifts": true},
  {"name": "saldo zero, rata minima", "accept": [1, 3], "minimum": true},
  {"name": "debito moltiplicato per dieci", "accept": [], "minimum": true, "debt": 70000000000},
 ]
 var report: Array = []
 var failures := 0
 for scenario: Dictionary in scenarios:
  GameState.new_game()
  GameState.debt = int(scenario.get("debt", GameState.START_DEBT))
  var turns: Array = []
  var total_turns := 0
  for i in 5:
   GameState.floor_id = str(GameState.FLOORS[i]["id"])
   var id: String = ["dinamo", "callcenter", "cassa_mercato", "sportello_banca", "pratiche_citta"][i]
   var job := GameState.job(id)
   if job.is_empty():
    # City identifier is data-owned, not guessed.
    for candidate: Dictionary in GameState.jobs_available():
     if str(candidate.get("room", "")) == "citta": job = candidate
   var pay := int(job.get("battle", {}).get("pay", 0))
   if not bool(job.get("pay_fixed", false)): pay = int(pay * (1.0 + 0.1 * i))
   var target := 0 if bool(scenario.get("gifts", false)) else GameState.badge_cost(GameState.floor_above()) + (300 if i == 1 else 0)
   var n := 0
   while n == 0 or GameState.money < target:
    if GameState.worked_today:
     if bool(scenario.get("minimum", false)):
      GameState.pay_debt(GameState.MIN_PAYMENT)
      GameState.end_day(true)
     else: GameState.end_day(false)
    n += 1; total_turns += 1
    GameState.finish_hard_job(pay)
    if n == 1 and i in scenario["accept"]: GameState.money += int(B.PRIZES[GameState.floor_id])
    if n > 30: failures += 1; break
   if target > 0: GameState.money -= target
   turns.append({"floor": GameState.floor_id, "pay": pay, "turns": n, "target": target})
  report.append({"scenario": scenario["name"], "turns": total_turns, "days": GameState.day, "balance": GameState.money, "debt": GameState.debt, "floors": turns})
  if total_turns > 40 or GameState.money < 0: failures += 1
 print("ECONOMY ", JSON.stringify(report))
 print("ECONOMY ERRORS ", failures)
 # Inventory every installed music stream; no purchased media is copied into deliverables.
 var music: Array = []
 for file: String in DirAccess.get_files_at("res://assets/music"):
  if file.ends_with(".ogg"):
   var stream: AudioStream = load("res://assets/music/" + file)
   music.append({"track": file, "seconds": snappedf(stream.get_length(), 0.1)})
 print("MUSIC INVENTORY ", JSON.stringify(music))
 get_tree().quit(failures)
