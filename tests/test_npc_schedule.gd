extends SceneTree

## Integration test for DayClock, NPCSchedule, and HUD time-of-day integration.
const DayClockScript = preload("res://scripts/day_clock.gd")
const NPCScheduleScript = preload("res://scripts/npc_schedule.gd")

var checks := 0
var failures := 0


func _init() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)


func run() -> void:
	print("--- Running NPC Schedule & DayClock Integration Tests ---")

	# 1. Test DayClock Autoload
	var clock = root.get_node_or_null("DayClock")
	if clock == null:
		clock = DayClockScript.new()
		clock.name = "DayClock"
		root.add_child(clock)

	check(clock != null, "DayClock instance is valid")
	check(clock.current_period == DayClockScript.Period.MORNING, "DayClock starts in Morning")
	check(clock.get_period_name() == "Morning", "Period name is 'Morning'")

	# Signal tracking
	var period_signals := []
	var period_changed_cb = func(idx: int, pname: String):
		period_signals.append({"idx": idx, "name": pname})
	clock.period_changed.connect(period_changed_cb)

	# Test period switching
	clock.set_period(DayClockScript.Period.AFTERNOON)
	check(clock.current_period == DayClockScript.Period.AFTERNOON, "Switched to Afternoon")
	check(clock.get_period_name() == "Afternoon", "Period name is 'Afternoon'")
	check(period_signals.size() == 1 and period_signals[0].name == "Afternoon", "period_changed signal fired")

	clock.set_period(DayClockScript.Period.EVENING)
	check(clock.current_period == DayClockScript.Period.EVENING, "Switched to Evening")
	check(clock.get_period_name() == "Evening", "Period name is 'Evening'")

	clock.set_period(DayClockScript.Period.NIGHT)
	check(clock.current_period == DayClockScript.Period.NIGHT, "Switched to Night")
	check(clock.get_period_name() == "Night", "Period name is 'Night'")

	# 2. Test GameState advance_day integration
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		var gs_script = load("res://scripts/game_state.gd")
		game_state = gs_script.new()
		game_state.name = "GameState"
		root.add_child(game_state)

	var initial_day = game_state.current_day
	game_state.advance_day()
	check(game_state.current_day == initial_day + 1, "GameState.advance_day() incremented day")
	check(clock.current_period == DayClockScript.Period.MORNING, "advance_day() reset DayClock to Morning")

	# 3. Test NPC with NPCSchedule
	var npc_scene = load("res://assets/characters/npc.tscn")
	check(npc_scene != null, "npc.tscn loads")
	var npc: TownNPC = npc_scene.instantiate()
	npc.character_id = "npc_barnaby_merchant"
	npc.position = Vector2(1850, 1140)
	root.add_child(npc)
	await process_frame

	var sched = npc.get_node_or_null("NPCSchedule") as NPCScheduleScript
	check(sched != null, "NPCSchedule automatically mounted on NPC")
	check(sched.current_activity.length() > 0, "NPC schedule has an active activity: " + sched.current_activity)

	# Test period change updates NPC routine
	clock.set_period(DayClockScript.Period.AFTERNOON)
	check(sched.current_period == DayClockScript.Period.AFTERNOON, "NPCSchedule detected Afternoon period")
	check(sched.current_activity.find("plaza") != -1 or sched.current_activity.find("goods") != -1, "Barnaby routine updated to plaza browsing")

	# 4. Test Schedule Suspension when Player in range
	check(not sched.is_movement_suspended(), "Movement not suspended when player absent")
	npc.is_player_in_range = true
	check(sched.is_movement_suspended(), "Movement suspended when player in range")
	check(npc.is_schedule_suspended(), "npc.is_schedule_suspended() returns true")

	# Simulate physics tick while suspended
	npc.velocity = Vector2(100, 100)
	npc._process(0.016)
	check(npc.velocity == Vector2.ZERO, "Velocity clamped to ZERO while player in range")

	# Player leaves
	npc.is_player_in_range = false
	check(not sched.is_movement_suspended(), "Movement suspension lifted when player leaves")

	# 5. Test HUD displays time of day
	var hud_scene = load("res://scenes/ui/hud.tscn")
	if hud_scene:
		var hud: GameHUD = hud_scene.instantiate()
		root.add_child(hud)
		await process_frame
		check(hud.day_label.text.find("Afternoon") != -1, "HUD DayLabel reflects current time-of-day: " + hud.day_label.text)
		
		clock.set_period(DayClockScript.Period.MORNING)
		await process_frame
		check(hud.day_label.text.find("Morning") != -1, "HUD DayLabel updated to Morning: " + hud.day_label.text)
		hud.free()

	# Cleanup
	npc.free()
	print("--- Test Complete: %d checks, %d failures ---" % [checks, failures])
	quit(0 if failures == 0 else 1)
