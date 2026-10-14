class_name NPCSchedule
extends Node

## Manages daily routines, patrol waypoints, and timed movement for NPCs.
## Attaches as a child of TownNPC (or any CharacterBody2D).
##
## Features:
##   - Desynchronized / staggered departure timings so NPCs do not move in unison.
##   - Varied walk speeds per character archetype.
##   - Dynamic dwell times at waypoints to prevent lockstep patrols.
##   - Differentiated schedules across Morning, Afternoon, Evening, and Night.
##   - Stationary worker archetypes so only a small realistic subset is traveling at any given moment.

@export var enabled: bool = true
@export var walk_speed: float = 60.0
@export var arrival_threshold: float = 8.0
@export var default_dwell_time: float = 6.0

## Current active schedule entry and activity name
var current_activity: String = "Idle"
var current_period: int = 0

## Internal movement state
var _waypoints: Array[Vector2] = []
var _target_facings: Array[String] = []
var _waypoint_index: int = 0
var _dwell_timer: float = 0.0
var _is_dwelling: bool = false
var _departure_delay: float = 0.0
var _stuck_timer: float = 0.0
var _last_pos: Vector2 = Vector2.ZERO

## Reference to parent NPC
var _npc: CharacterBody2D = null
var _home_pos: Vector2 = Vector2.ZERO
var _home_facing: String = "down"
var _hash_val: int = 0

## Pre-authored schedules keyed by character_id
static var DEFAULT_SCHEDULES: Dictionary = {
	"npc_barnaby_merchant": [
		# Morning: Stays at shop counter stocking shelves
		{"period": 0, "activity": "Tending merchant shop", "waypoints": [Vector2(1850, 1140)], "facing": "down", "dwell": 12.0, "delay": 2.0},
		# Afternoon: Strolls to Plaza Fountain at mid-day
		{"period": 1, "activity": "Browsing goods at plaza", "waypoints": [Vector2(1950, 1130), Vector2(2010, 1130)], "facing": "right", "dwell": 10.0, "delay": 8.0},
		# Evening: Visits tavern for a drink
		{"period": 2, "activity": "Socializing at tavern", "waypoints": [Vector2(1120, 1960), Vector2(1150, 1960)], "facing": "up", "dwell": 12.0, "delay": 5.0},
		# Night: Resting at shop
		{"period": 3, "activity": "Resting at shop", "waypoints": [Vector2(1850, 1140)], "facing": "down", "dwell": 0.0, "delay": 3.0}
	],
	"npc_doctor_hawthorne": [
		# Morning: Clinic work
		{"period": 0, "activity": "Preparing remedies at clinic", "waypoints": [Vector2(2270, 1140)], "facing": "down", "dwell": 15.0, "delay": 1.0},
		# Afternoon: Departs later for house calls across the plaza
		{"period": 1, "activity": "House calls across plaza", "waypoints": [Vector2(2120, 1140), Vector2(1980, 1140)], "facing": "left", "dwell": 9.0, "delay": 12.0},
		# Evening: Meets with Mayor Vance at Town Hall
		{"period": 2, "activity": "Meeting with Mayor Vance", "waypoints": [Vector2(2080, 930)], "facing": "left", "dwell": 10.0, "delay": 7.0},
		# Night: Resting at clinic
		{"period": 3, "activity": "Resting at clinic", "waypoints": [Vector2(2270, 1140)], "facing": "down", "dwell": 0.0, "delay": 2.0}
	],
	"npc_watchmaker_tock": [
		# Morning: Workshop tinkering
		{"period": 0, "activity": "Calibrating pocket watches", "waypoints": [Vector2(1850, 1370)], "facing": "down", "dwell": 18.0, "delay": 0.0},
		# Afternoon: Checks the central plaza clock after a long delay
		{"period": 1, "activity": "Checking plaza clock timing", "waypoints": [Vector2(2040, 1160), Vector2(2070, 1160)], "facing": "up", "dwell": 14.0, "delay": 16.0},
		# Evening: Walks west near artisan forge
		{"period": 2, "activity": "Evening walk by forge", "waypoints": [Vector2(1620, 1310)], "facing": "right", "dwell": 8.0, "delay": 9.0},
		# Night: Workshop rest
		{"period": 3, "activity": "Resting at workshop", "waypoints": [Vector2(1850, 1370)], "facing": "down", "dwell": 0.0, "delay": 1.0}
	],
	"npc_mayor_vance": [
		# Morning: Stays at Town Hall desk
		{"period": 0, "activity": "Reviewing town decrees", "waypoints": [Vector2(2056, 920)], "facing": "down", "dwell": 15.0, "delay": 0.0},
		# Afternoon: Mid-afternoon inspection of fountain plaza
		{"period": 1, "activity": "Inspecting central plaza", "waypoints": [Vector2(2056, 1080), Vector2(2056, 1150)], "facing": "down", "dwell": 11.0, "delay": 6.0},
		# Evening: Dinner conference with Lord Cedric
		{"period": 2, "activity": "Consulting with Lord Cedric", "waypoints": [Vector2(2250, 1370)], "facing": "right", "dwell": 12.0, "delay": 11.0},
		# Night: Resting at manor
		{"period": 3, "activity": "Resting at manor", "waypoints": [Vector2(2056, 920)], "facing": "down", "dwell": 0.0, "delay": 2.0}
	],
	"npc_cedric_aristocrat": [
		# Morning: Stays inside manor
		{"period": 0, "activity": "Reviewing estate ledgers", "waypoints": [Vector2(2270, 1370)], "facing": "down", "dwell": 20.0, "delay": 0.0},
		# Afternoon: Late stroll to show off wealth in plaza
		{"period": 1, "activity": "Promenading across plaza", "waypoints": [Vector2(2120, 1200), Vector2(2056, 1128)], "facing": "down", "dwell": 10.0, "delay": 14.0},
		# Evening: Strolls near archive library
		{"period": 2, "activity": "Discussing patronage at library", "waypoints": [Vector2(2480, 1370)], "facing": "right", "dwell": 9.0, "delay": 4.0},
		# Night: Retired to manor
		{"period": 3, "activity": "Resting at manor", "waypoints": [Vector2(2270, 1370)], "facing": "down", "dwell": 0.0, "delay": 1.0}
	],
	"npc_librarian_elena": [
		# Morning: Cataloguing archive scrolls
		{"period": 0, "activity": "Sorting library archives", "waypoints": [Vector2(2520, 1370)], "facing": "down", "dwell": 14.0, "delay": 0.0},
		# Afternoon: Departs early to visit chapel
		{"period": 1, "activity": "Visiting parish chapel", "waypoints": [Vector2(1650, 890)], "facing": "up", "dwell": 12.0, "delay": 3.0},
		# Evening: Reading old manuscripts
		{"period": 2, "activity": "Reading old manuscripts", "waypoints": [Vector2(2520, 1370)], "facing": "right", "dwell": 15.0, "delay": 8.0},
		# Night: Library quarters
		{"period": 3, "activity": "Resting at library", "waypoints": [Vector2(2520, 1370)], "facing": "down", "dwell": 0.0, "delay": 1.0}
	],
	"npc_jester_pip": [
		# Morning: Juggling tricks near fountain (starts right away)
		{"period": 0, "activity": "Juggling by fountain", "waypoints": [Vector2(1990, 1128), Vector2(2030, 1120)], "facing": "right", "dwell": 4.0, "delay": 1.0},
		# Afternoon: Prancing around the marketplace
		{"period": 1, "activity": "Prancing through market", "waypoints": [Vector2(1940, 1200), Vector2(2056, 1200), Vector2(1990, 1128)], "facing": "down", "dwell": 5.0, "delay": 4.0},
		# Evening: Early arrival at the tavern
		{"period": 2, "activity": "Joking at the tavern", "waypoints": [Vector2(1120, 1940)], "facing": "right", "dwell": 8.0, "delay": 3.0},
		# Night: Curled up by fountain
		{"period": 3, "activity": "Sleeping near fountain", "waypoints": [Vector2(1990, 1128)], "facing": "down", "dwell": 0.0, "delay": 1.0}
	],
	"npc_bard_lyra": [
		# Morning: Tuning lute by fountain
		{"period": 0, "activity": "Singing morning melodies", "waypoints": [Vector2(2120, 1128), Vector2(2080, 1128)], "facing": "left", "dwell": 7.0, "delay": 2.0},
		# Afternoon: Leisurely walk to florist gardens
		{"period": 1, "activity": "Playing ballads near florist", "waypoints": [Vector2(1420, 1070), Vector2(1400, 1050)], "facing": "down", "dwell": 9.0, "delay": 9.0},
		# Evening: Singing ballads at tavern
		{"period": 2, "activity": "Performing tavern music", "waypoints": [Vector2(1140, 1960)], "facing": "up", "dwell": 14.0, "delay": 6.0},
		# Night: Musician cottage
		{"period": 3, "activity": "Resting at cottage", "waypoints": [Vector2(1850, 1630)], "facing": "down", "dwell": 0.0, "delay": 2.0}
	],
	"npc_citizen_clara": [
		# Morning: Strolling outside home
		{"period": 0, "activity": "Morning plaza air", "waypoints": [Vector2(1940, 1220), Vector2(1970, 1220)], "facing": "up", "dwell": 8.0, "delay": 5.0},
		# Afternoon: Bakery shopping run
		{"period": 1, "activity": "Buying fresh bread", "waypoints": [Vector2(1100, 1050), Vector2(1130, 1050)], "facing": "up", "dwell": 8.0, "delay": 11.0},
		# Evening: Visiting florist garden
		{"period": 2, "activity": "Admiring garden blossoms", "waypoints": [Vector2(1400, 1050)], "facing": "left", "dwell": 10.0, "delay": 7.0},
		# Night: Resting at home
		{"period": 3, "activity": "Resting at home", "waypoints": [Vector2(1940, 1220)], "facing": "down", "dwell": 0.0, "delay": 2.0}
	],
	"npc_citizen_hugo": [
		# Morning: Stroll around plaza
		{"period": 0, "activity": "Morning plaza stroll", "waypoints": [Vector2(2170, 1220), Vector2(2120, 1220)], "facing": "left", "dwell": 7.0, "delay": 3.0},
		# Afternoon: Visits the blacksmith forge
		{"period": 1, "activity": "Watching blacksmith forge", "waypoints": [Vector2(1115, 1400)], "facing": "up", "dwell": 9.0, "delay": 7.0},
		# Evening: Drinks ale at tavern
		{"period": 2, "activity": "Drinking evening ale", "waypoints": [Vector2(1100, 1960)], "facing": "right", "dwell": 12.0, "delay": 4.0},
		# Night: Home
		{"period": 3, "activity": "Resting at home", "waypoints": [Vector2(2170, 1220)], "facing": "down", "dwell": 0.0, "delay": 2.0}
	],
	"npc_priest_joseph": [
		# Morning: Chapel prayer (stays inside chapel)
		{"period": 0, "activity": "Morning sermon at chapel", "waypoints": [Vector2(1620, 890)], "facing": "down", "dwell": 20.0, "delay": 0.0},
		# Afternoon: Blessing townsfolk in plaza
		{"period": 1, "activity": "Blessing townsfolk in plaza", "waypoints": [Vector2(1950, 1140), Vector2(2056, 1140)], "facing": "right", "dwell": 12.0, "delay": 10.0},
		# Evening: Returns to parish chapel
		{"period": 2, "activity": "Evening prayer", "waypoints": [Vector2(1620, 890)], "facing": "up", "dwell": 15.0, "delay": 5.0},
		# Night: Parish quarters
		{"period": 3, "activity": "Resting in parish", "waypoints": [Vector2(1620, 890)], "facing": "down", "dwell": 0.0, "delay": 1.0}
	],
	"npc_tavernkeeper_maggie": [
		# Morning: Stocking tavern
		{"period": 0, "activity": "Stocking cellar and kegs", "waypoints": [Vector2(1100, 1960)], "facing": "down", "dwell": 14.0, "delay": 0.0},
		# Afternoon: Prepping tables
		{"period": 1, "activity": "Setting up tavern tables", "waypoints": [Vector2(1100, 1960), Vector2(1130, 1960)], "facing": "right", "dwell": 10.0, "delay": 4.0},
		# Evening: Busy serving patrons
		{"period": 2, "activity": "Serving thirsty patrons", "waypoints": [Vector2(1100, 1960), Vector2(1140, 1960)], "facing": "down", "dwell": 8.0, "delay": 2.0},
		# Night: Locking up
		{"period": 3, "activity": "Locking tavern doors", "waypoints": [Vector2(1100, 1960)], "facing": "up", "dwell": 0.0, "delay": 1.0}
	],
	"npc_blacksmith_boros": [
		# Morning: Stoking forge fires (doesn't leave forge)
		{"period": 0, "activity": "Stoking forge fires", "waypoints": [Vector2(1115, 1400)], "facing": "up", "dwell": 20.0, "delay": 0.0},
		# Afternoon: Hammering at anvil
		{"period": 1, "activity": "Hammering at anvil", "waypoints": [Vector2(1115, 1400), Vector2(1135, 1400)], "facing": "down", "dwell": 9.0, "delay": 5.0},
		# Evening: Steps outside for cool air
		{"period": 2, "activity": "Cooling down outside shop", "waypoints": [Vector2(1115, 1430)], "facing": "down", "dwell": 14.0, "delay": 8.0},
		# Night: Resting
		{"period": 3, "activity": "Resting after hard work", "waypoints": [Vector2(1115, 1400)], "facing": "down", "dwell": 0.0, "delay": 1.0}
	],
	"npc_florist_lily": [
		# Morning: Watering flowers
		{"period": 0, "activity": "Watering vibrant blooms", "waypoints": [Vector2(1400, 1050), Vector2(1430, 1050)], "facing": "up", "dwell": 8.0, "delay": 2.0},
		# Afternoon: Sells bouquets at plaza
		{"period": 1, "activity": "Selling flowers at plaza", "waypoints": [Vector2(2010, 1150)], "facing": "right", "dwell": 12.0, "delay": 7.0},
		# Evening: Pruning flower beds
		{"period": 2, "activity": "Pruning flower beds", "waypoints": [Vector2(1400, 1050)], "facing": "left", "dwell": 10.0, "delay": 6.0},
		# Night: Resting at cottage
		{"period": 3, "activity": "Resting at cottage", "waypoints": [Vector2(1400, 1050)], "facing": "down", "dwell": 0.0, "delay": 2.0}
	],
	"npc_fisherman_finn": [
		# Morning: Fishing at pier
		{"period": 0, "activity": "Casting nets by the pier", "waypoints": [Vector2(656, 1050)], "facing": "down", "dwell": 16.0, "delay": 0.0},
		# Afternoon: Bringing fish catch to market
		{"period": 1, "activity": "Selling fresh catch at plaza", "waypoints": [Vector2(1900, 1150)], "facing": "right", "dwell": 11.0, "delay": 10.0},
		# Evening: Relaxing at tavern
		{"period": 2, "activity": "Tavern ale with sailors", "waypoints": [Vector2(1100, 1960)], "facing": "right", "dwell": 13.0, "delay": 5.0},
		# Night: Fisherman shack
		{"period": 3, "activity": "Resting at fishing shack", "waypoints": [Vector2(656, 1050)], "facing": "down", "dwell": 0.0, "delay": 1.0}
	],
	"npc_lumberjack_karl": [
		# Morning & Afternoon: Works at lumber lodge
		{"period": 0, "activity": "Splitting firewood", "waypoints": [Vector2(1400, 510)], "facing": "down", "dwell": 18.0, "delay": 0.0},
		{"period": 1, "activity": "Stacking timber logs", "waypoints": [Vector2(1400, 510), Vector2(1430, 510)], "facing": "left", "dwell": 10.0, "delay": 6.0},
		# Evening: Walk to tavern
		{"period": 2, "activity": "Evening drink at tavern", "waypoints": [Vector2(1100, 1960)], "facing": "up", "dwell": 12.0, "delay": 8.0},
		# Night: Lodge
		{"period": 3, "activity": "Sleeping at lodge", "waypoints": [Vector2(1400, 510)], "facing": "down", "dwell": 0.0, "delay": 2.0}
	]
}


func _ready() -> void:
	_npc = get_parent() as CharacterBody2D
	if _npc:
		_home_pos = _npc.global_position
		_home_facing = _npc.get("current_facing") if "current_facing" in _npc else "down"
		_last_pos = _home_pos

		var char_id: String = str(_npc.get("character_id")) if "character_id" in _npc else ""
		_hash_val = abs(char_id.hash() if not char_id.is_empty() else _npc.get_instance_id())

		# Vary movement speeds naturally across individuals (46 to 68 px/s)
		# Fast characters (jesters, children)
		if char_id.contains("pip") or char_id.contains("child"):
			walk_speed = 72.0
		elif char_id.contains("elder") or char_id.contains("sage") or char_id.contains("king"):
			walk_speed = 44.0
		else:
			walk_speed = 48.0 + float(_hash_val % 18)

	# Connect to DayClock singleton
	var clock = get_node_or_null("/root/DayClock")
	if clock:
		clock.period_changed.connect(_on_period_changed)
		current_period = clock.current_period

	_load_schedule_for_period(current_period)
	# Initial dwell so NPCs don't step immediately on scene load
	_is_dwelling = true
	_dwell_timer = default_dwell_time + float(_hash_val % 8)


func _on_period_changed(new_period: int, _period_name: String) -> void:
	current_period = new_period
	_load_schedule_for_period(current_period)


func _load_schedule_for_period(period_idx: int) -> void:
	if not _npc:
		return

	var char_id: String = str(_npc.get("character_id")) if "character_id" in _npc else ""
	var authored: Array = DEFAULT_SCHEDULES.get(char_id, [])
	var match_entry: Dictionary = {}

	for entry in authored:
		if entry.get("period", -1) == period_idx:
			match_entry = entry
			break

	var delay: float = 0.0

	if not match_entry.is_empty():
		current_activity = str(match_entry.get("activity", "Scheduled Routine"))
		_waypoints.clear()
		_target_facings.clear()
		var pts: Array = match_entry.get("waypoints", [])
		for pt in pts:
			if pt is Vector2:
				_waypoints.append(pt)
		var f: String = str(match_entry.get("facing", "down"))
		_target_facings.append(f)
		default_dwell_time = float(match_entry.get("dwell", 6.0))
		delay = float(match_entry.get("delay", 2.0))
	else:
		# Dynamic fallback routine based on character archetype
		delay = _create_fallback_routine(period_idx)

	_waypoint_index = 0
	_stuck_timer = 0.0

	# Apply staggered departure delay so not all NPCs walk at the same second!
	if delay > 0.0:
		_is_dwelling = true
		_dwell_timer = delay
	else:
		_is_dwelling = false
		_dwell_timer = 0.0


func _create_fallback_routine(period_idx: int) -> float:
	_waypoints.clear()
	_target_facings.clear()

	# Classify generic NPCs into 3 natural archetypes using hash:
	# 1. Stationary Workers (~45%): stay at home/work node across all periods.
	# 2. Local Roamers (~35%): take a stroll only in the afternoon.
	# 3. Evening Strollers (~20%): take a short stroll only in the evening.
	var archetype := _hash_val % 10
	var departure_delay := 1.5 + float((_hash_val / 3) % 12) * 1.3

	if archetype < 5:
		# Stationary worker / shopkeeper / sentry
		current_activity = "Stationary duties"
		_waypoints = [_home_pos]
		# Vary facing with time of day
		var facings := ["down", "right", "left", _home_facing]
		_target_facings = [facings[period_idx % facings.size()]]
		default_dwell_time = 0.0
		return 0.0

	elif archetype < 8:
		# Local roamer: only walks during Afternoon (period 1)
		match period_idx:
			0: # Morning: stays at home
				current_activity = "Morning preparation"
				_waypoints = [_home_pos]
				_target_facings = [_home_facing]
				default_dwell_time = 0.0
				return 0.0
			1: # Afternoon: takes a gentle stroll around home
				current_activity = "Afternoon walk"
				var offset_dir := Vector2.ZERO
				match (_hash_val % 4):
					0: offset_dir = Vector2(0, 24)
					1: offset_dir = Vector2(24, 0)
					2: offset_dir = Vector2(0, -20)
					3: offset_dir = Vector2(-22, 0)
				_waypoints = [_home_pos + offset_dir, _home_pos]
				_target_facings = ["down", _home_facing]
				default_dwell_time = 8.0 + float(_hash_val % 6)
				return departure_delay
			2: # Evening: stays at home
				current_activity = "Evening rest"
				_waypoints = [_home_pos]
				_target_facings = ["down"]
				default_dwell_time = 0.0
				return 0.0
			3: # Night: resting
				current_activity = "Sleeping"
				_waypoints = [_home_pos]
				_target_facings = [_home_facing]
				default_dwell_time = 0.0
				return 0.0

	else:
		# Evening stroll archetype: only walks during Evening (period 2)
		match period_idx:
			0, 1: # Morning & Afternoon: stays at station
				current_activity = "Working at post"
				_waypoints = [_home_pos]
				_target_facings = [_home_facing]
				default_dwell_time = 0.0
				return 0.0
			2: # Evening: stroll
				current_activity = "Evening walk"
				var offset_dir := Vector2.ZERO
				match (_hash_val % 4):
					0: offset_dir = Vector2(20, 20)
					1: offset_dir = Vector2(-20, 15)
					2: offset_dir = Vector2(18, -18)
					3: offset_dir = Vector2(-18, -15)
				_waypoints = [_home_pos + offset_dir, _home_pos]
				_target_facings = ["left", _home_facing]
				default_dwell_time = 9.0 + float(_hash_val % 7)
				return departure_delay
			3: # Night
				current_activity = "Resting"
				_waypoints = [_home_pos]
				_target_facings = [_home_facing]
				default_dwell_time = 0.0
				return 0.0

	return 0.0


func _physics_process(delta: float) -> void:
	if not enabled or not _npc or _waypoints.is_empty():
		return

	# Check if schedule movement is suspended
	if is_movement_suspended():
		_npc.velocity = Vector2.ZERO
		if _npc.has_method("update_walk_animation"):
			_npc.update_walk_animation(delta, false)
		return

	# Handle dwelling at a waypoint or waiting for staggered departure
	if _is_dwelling:
		_npc.velocity = Vector2.ZERO
		if _npc.has_method("update_walk_animation"):
			_npc.update_walk_animation(delta, false)

		if _dwell_timer > 0.0:
			_dwell_timer -= delta
			if _dwell_timer <= 0.0:
				_is_dwelling = false
				# Only advance to next waypoint if there are multiple waypoints
				if _waypoints.size() > 1:
					_waypoint_index = (_waypoint_index + 1) % _waypoints.size()
				_stuck_timer = 0.0
		return

	# Move towards current target waypoint
	var target: Vector2 = _waypoints[_waypoint_index]
	var diff: Vector2 = target - _npc.global_position
	var dist: float = diff.length()

	if dist <= arrival_threshold:
		# Arrived at waypoint
		_npc.global_position = target
		_npc.velocity = Vector2.ZERO

		var facing_str := "down"
		if _target_facings.size() > _waypoint_index:
			facing_str = _target_facings[_waypoint_index]
		elif not _target_facings.is_empty():
			facing_str = _target_facings[0]

		if _npc.has_method("set_facing"):
			_npc.set_facing(facing_str)
		if _npc.has_method("update_walk_animation"):
			_npc.update_walk_animation(delta, false)

		_is_dwelling = true
		# Varied dwell time so multiple NPCs don't depart waypoints in sync
		var variance: float = float((_hash_val + _waypoint_index * 7) % 6)
		_dwell_timer = default_dwell_time + variance
		_stuck_timer = 0.0
	else:
		# Walking toward target
		var dir: Vector2 = diff.normalized()
		_npc.velocity = dir * walk_speed
		_npc.move_and_slide()

		if _npc.has_method("update_walk_animation"):
			_npc.update_walk_animation(delta, true)

		# Anti-stuck watchdog: If NPC hasn't made progress for 3 seconds, proceed to dwell
		var pos_delta := (_npc.global_position - _last_pos).length()
		if pos_delta < 2.0:
			_stuck_timer += delta
			if _stuck_timer >= 3.0:
				_stuck_timer = 0.0
				_is_dwelling = true
				_dwell_timer = 3.0
		else:
			_stuck_timer = 0.0
		_last_pos = _npc.global_position


func is_movement_suspended() -> bool:
	if not _npc:
		return false

	# 1. Player is in interaction range
	if _npc.get("is_player_in_range") == true:
		return true

	# 2. NPC has an explicit suspension method
	if _npc.has_method("is_schedule_suspended") and _npc.is_schedule_suspended():
		return true

	# 3. Global dialogue / typing suspension
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		if not game_state.can_player_move:
			return true
		if game_state.is_game_over:
			return true

	# 4. Refusing to talk (stand firm)
	if _npc.get("is_refusing_to_talk") == true:
		return true

	return false
