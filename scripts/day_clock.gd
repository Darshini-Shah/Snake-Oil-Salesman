class_name DayClockManager
extends Node

## Authoritative real-time → in-game time-of-day clock for Snake Oil Salesman.
##
## A single in-game day is divided into 4 periods:
##   0: Morning
##   1: Afternoon
##   2: Evening
##   3: Night
##
## Real-time duration of the whole day is controlled by day_real_seconds.
## Signals notify listeners whenever period changes or the clock ticks.
## Integrates with GameState to advance the day when Night completes.

signal period_changed(period_index: int, period_name: String)
signal clock_ticked(period_index: int, period_progress: float)
signal day_completed()

enum Period {
	MORNING = 0,
	AFTERNOON = 1,
	EVENING = 2,
	NIGHT = 3
}

const PERIOD_NAMES: Array[String] = ["Morning", "Afternoon", "Evening", "Night"]

## Real-world seconds per full in-game day (4 periods = day_real_seconds / 4 per period)
## Default: 240 seconds = 4 minutes (60 seconds per period)
@export var day_real_seconds: float = 240.0
@export var auto_advance_day_on_cycle: bool = true

var current_period: int = Period.MORNING
var elapsed_seconds: float = 0.0
var is_paused: bool = false


func _ready() -> void:
	add_to_group("day_clock")


func _process(delta: float) -> void:
	if is_paused:
		return

	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		# Pause clock if game is over
		if game_state.is_game_over:
			return

	elapsed_seconds += delta

	var period_duration: float = day_real_seconds / 4.0
	if period_duration <= 0.0:
		period_duration = 60.0

	var new_period: int = clampi(int(elapsed_seconds / period_duration), 0, 3)
	var period_progress: float = clampf(fmod(elapsed_seconds, period_duration) / period_duration, 0.0, 1.0)

	if new_period != current_period:
		current_period = new_period
		emit_signal("period_changed", current_period, get_period_name())

	emit_signal("clock_ticked", current_period, period_progress)

	# Full day completed
	if elapsed_seconds >= day_real_seconds:
		elapsed_seconds = 0.0
		current_period = Period.MORNING
		emit_signal("day_completed")
		emit_signal("period_changed", current_period, get_period_name())
		if auto_advance_day_on_cycle:
			if game_state and game_state.has_method("advance_day"):
				game_state.advance_day()


func get_period_name() -> String:
	if current_period >= 0 and current_period < PERIOD_NAMES.size():
		return PERIOD_NAMES[current_period]
	return "Morning"


func get_period_index() -> int:
	return current_period


func get_period_progress() -> float:
	var period_duration: float = day_real_seconds / 4.0
	if period_duration <= 0.0:
		return 0.0
	return clampf(fmod(elapsed_seconds, period_duration) / period_duration, 0.0, 1.0)


func reset_day() -> void:
	elapsed_seconds = 0.0
	var old_period := current_period
	current_period = Period.MORNING
	if old_period != current_period:
		emit_signal("period_changed", current_period, get_period_name())
	emit_signal("clock_ticked", current_period, 0.0)


func set_period(target_period: int) -> void:
	target_period = clampi(target_period, 0, 3)
	var period_duration: float = day_real_seconds / 4.0
	elapsed_seconds = target_period * period_duration
	if current_period != target_period:
		current_period = target_period
		emit_signal("period_changed", current_period, get_period_name())


func pause_clock() -> void:
	is_paused = true


func resume_clock() -> void:
	is_paused = false
