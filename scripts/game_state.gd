class_name GameStateManager
extends Node

## Central authoritative GameState for Snake Oil Salesman.
## Tracks player currency, 30-day timeline, overall reputation, and inventory items.

signal kurtos_changed(new_amount: int, delta: int)
signal day_changed(new_day: int)
signal overall_trust_changed(new_value: int, delta: int)
signal item_added(item: Dictionary)
signal game_ended(won: bool, message: String)

@export var player_kurtos: int = 50
@export var goal_kurtos: int = 1_000_000
@export var current_day: int = 1
@export var max_days: int = 30
@export var overall_trust: int = 25 # 0 to 100
@export var can_player_move: bool = true

var inventory: Array[Dictionary] = []
var is_game_over: bool = false
var has_won: bool = false


func _ready() -> void:
	pass


func add_kurtos(amount: int) -> void:
	if amount <= 0:
		return
	player_kurtos += amount
	emit_signal("kurtos_changed", player_kurtos, amount)
	_check_win_condition()


func spend_kurtos(amount: int) -> bool:
	if amount <= 0:
		return false
	if player_kurtos >= amount:
		player_kurtos -= amount
		emit_signal("kurtos_changed", player_kurtos, -amount)
		return true
	return false


func modify_overall_trust(delta: int) -> void:
	var prev := overall_trust
	overall_trust = clampi(overall_trust + delta, 0, 100)
	if overall_trust != prev:
		emit_signal("overall_trust_changed", overall_trust, overall_trust - prev)


func advance_day() -> void:
	if is_game_over:
		return
	
	current_day += 1
	emit_signal("day_changed", current_day)
	
	# Notify all NPCs in the town about day rollover (resets daily spend & cools down anger)
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc.has_method("on_day_rollover"):
			npc.on_day_rollover(current_day)
	
	# Check 30-day limit
	if current_day > max_days:
		_evaluate_ending()


func has_item(item_id: String) -> bool:
	for item in inventory:
		if item.get("id", "") == item_id:
			return true
	return false


func add_item(item_id: String, item_name: String, description: String = "") -> void:
	if has_item(item_id):
		return
	var item_dict := {
		"id": item_id,
		"name": item_name,
		"description": description
	}
	inventory.append(item_dict)
	emit_signal("item_added", item_dict)


func remove_item(item_id: String) -> bool:
	for i in range(inventory.size()):
		if inventory[i].get("id", "") == item_id:
			inventory.remove_at(i)
			return true
	return false


func _check_win_condition() -> void:
	if player_kurtos >= goal_kurtos and not is_game_over:
		is_game_over = true
		has_won = true
		var msg := "You accumulated 1,000,000 Kurtos in %d days! You approach the King to claim the Princess's hand in marriage..." % current_day
		emit_signal("game_ended", true, msg)


func _evaluate_ending() -> void:
	is_game_over = true
	if player_kurtos >= goal_kurtos:
		has_won = true
		var msg := "Day 30 has arrived! You amassed %d Kurtos! The King summons you to court..." % player_kurtos
		emit_signal("game_ended", true, msg)
	else:
		has_won = false
		var msg := "Day 30 has elapsed. You only collected %d / %d Kurtos. The King's guards arrest you for being an impoverished pretender!" % [player_kurtos, goal_kurtos]
		emit_signal("game_ended", false, msg)


func reset_game() -> void:
	player_kurtos = 50
	current_day = 1
	overall_trust = 25
	is_game_over = false
	has_won = false
	inventory.clear()
	add_item("miracle_tonic_sample", "Miracle Tonic Sample", "A small bottle of colored sugar water.")
	emit_signal("kurtos_changed", player_kurtos, 0)
	emit_signal("day_changed", current_day)
	emit_signal("overall_trust_changed", overall_trust, 0)
