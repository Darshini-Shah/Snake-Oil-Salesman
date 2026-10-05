class_name EconomyManager
extends Node

## Authoritative manager for Kurtos economy and transactions.
## Adheres strictly to AGENTS.md Rule 1: Godot game systems are authoritative.

signal transaction_completed(npc_name: String, amount: int, reason: String)
signal transaction_denied(npc_name: String, reason: String)


## Checks how much an NPC can still spend today
static func get_remaining_daily_budget(npc_data: Dictionary) -> int:
	var max_spend: int = int(npc_data.get("max_daily_spend", 200))
	var spent_today: int = int(npc_data.get("spent_today", 0))
	var gold: int = int(npc_data.get("gold", 500))
	var remaining_budget := maxi(0, max_spend - spent_today)
	return mini(remaining_budget, gold)


## Deterministically executes a money transfer from an NPC to the player
static func transfer_kurtos_from_npc(npc_node: Node2D, requested_amount: int, reason: String = "Scam Pitch") -> int:
	if npc_node == null or requested_amount <= 0:
		return 0
	
	var max_spend: int = int(npc_node.get("max_daily_spend")) if "max_daily_spend" in npc_node else 200
	var spent_today: int = int(npc_node.get("spent_today")) if "spent_today" in npc_node else 0
	var gold: int = int(npc_node.get("gold")) if "gold" in npc_node else 500
	var npc_name: String = str(npc_node.get("npc_name")) if "npc_name" in npc_node else "Resident"
	
	var remaining_budget := maxi(0, max_spend - spent_today)
	var available_from_npc := mini(remaining_budget, gold)
	
	if available_from_npc <= 0:
		return 0
	
	# Clamp requested amount to what the NPC can afford and has left in their daily cap
	var actual_amount := mini(requested_amount, available_from_npc)
	
	# Mutate NPC state deterministically
	if "spent_today" in npc_node:
		npc_node.set("spent_today", spent_today + actual_amount)
	if "gold" in npc_node:
		npc_node.set("gold", gold - actual_amount)
	
	# Credit player in GameState
	var game_state = npc_node.get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("add_kurtos"):
		game_state.add_kurtos(actual_amount)
	
	return actual_amount
