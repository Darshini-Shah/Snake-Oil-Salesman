class_name ScamManager
extends Node

## Deterministic Scam & Social Outcome Resolver.
## Adheres to AGENTS.md Rule 4 (prefer deterministic math) and docs/GAME_DESIGN.md.

enum ScamOutcome {
	SUCCESS,
	PARTIAL,
	FAILED_MILD,
	FAILED_EXPOSED
}

const REFUSAL_SUSPICION_THRESHOLD: int = 70


## Evaluates a player's pitch/message against the target NPC's identity, trust, and suspicion.
static func evaluate_pitch(
	npc_data: Dictionary,
	player_message: String,
	llm_result: Dictionary,
	inventory_items: Array[Dictionary],
	overall_trust: int
) -> Dictionary:
	var trust: int = int(npc_data.get("trust", 50))
	var suspicion: int = int(npc_data.get("suspicion", 10))
	var past_scams: int = int(npc_data.get("successful_scam_count", 0)) + int(npc_data.get("failed_scam_count", 0))
	var personality: Dictionary = npc_data.get("personality", {})
	
	var credibility: float = float(llm_result.get("credibility", 0.5))
	var intent: String = str(llm_result.get("intent", "NORMAL_CONVERSATION")).to_upper()
	
	var lower_msg := player_message.to_lower()
	
	# 1. Backstory affinity check
	var affinity_bonus: float = 0.0
	var matched_susceptible: Array = []
	var susceptible_topics: Array = npc_data.get("susceptible_topics", [])
	for topic in susceptible_topics:
		if lower_msg.contains(str(topic).to_lower()):
			affinity_bonus += 18.0
			matched_susceptible.append(topic)
	
	var skepticism_penalty: float = 0.0
	var matched_skeptical: Array = []
	var skeptical_topics: Array = npc_data.get("skeptical_topics", [])
	for topic in skeptical_topics:
		if lower_msg.contains(str(topic).to_lower()):
			skepticism_penalty += 25.0
			matched_skeptical.append(topic)
	
	# 2. Inventory Items Owned
	var has_beggars_robe := false
	var has_monocle := false
	var has_fabric := false
	var has_tonic := false
	var has_patent := false
	for it in inventory_items:
		var item_id: String = str(it.get("id", ""))
		if item_id == "beggars_robe":
			has_beggars_robe = true
		elif item_id == "monocle":
			has_monocle = true
		elif item_id == "fabric_sample":
			has_fabric = true
		elif item_id == "miracle_tonic_sample":
			has_tonic = true
		elif item_id == "forged_patent":
			has_patent = true

	# 2b. Pitch Archetype Classification
	var is_fabric_pitch: bool = (
		lower_msg.contains("fabric") or lower_msg.contains("cloth") or lower_msg.contains("garment") or
		lower_msg.contains("seamster") or lower_msg.contains("textile") or lower_msg.contains("silk") or
		lower_msg.contains("tailor") or lower_msg.contains("swatch") or lower_msg.contains("designer")
	)
	
	var is_tonic_pitch: bool = (
		lower_msg.contains("tonic") or lower_msg.contains("elixir") or lower_msg.contains("potion") or
		lower_msg.contains("cure") or lower_msg.contains("remedy") or lower_msg.contains("miracle") or
		lower_msg.contains("snake oil") or lower_msg.contains("ward") or lower_msg.contains("omen") or
		lower_msg.contains("curse") or lower_msg.contains("spirit")
	)
	
	var is_poverty_pitch: bool = (
		lower_msg.contains("sick") or lower_msg.contains("fever") or lower_msg.contains("child") or
		lower_msg.contains("starv") or lower_msg.contains("hungry") or lower_msg.contains("hunger") or
		lower_msg.contains("poor") or lower_msg.contains("beggar") or lower_msg.contains("rags") or
		lower_msg.contains("charity") or lower_msg.contains("alms") or lower_msg.contains("orphan") or
		lower_msg.contains("medicine") or lower_msg.contains("illness") or lower_msg.contains("mother") or
		lower_msg.contains("pity") or lower_msg.contains("spare") or lower_msg.contains("destitute")
	)
	
	var is_nobility_pitch: bool = (
		lower_msg.contains("noble") or lower_msg.contains("aristocrat") or lower_msg.contains("royal") or
		lower_msg.contains("prestige") or lower_msg.contains("privilege") or lower_msg.contains("high society") or
		lower_msg.contains("monocle") or lower_msg.contains("king") or lower_msg.contains("queen") or
		lower_msg.contains("princess") or lower_msg.contains("court") or lower_msg.contains("charter") or
		lower_msg.contains("patent") or lower_msg.contains("patronage") or lower_msg.contains("highborn")
	)
	
	var is_asking_money: bool = (
		lower_msg.contains("money") or lower_msg.contains("kurtos") or lower_msg.contains("coin") or
		lower_msg.contains("gold") or lower_msg.contains("lend") or lower_msg.contains("donate") or
		lower_msg.contains("invest") or lower_msg.contains("give me")
	)

	# 2c. Item Gating & Synergy Resolution
	var item_bonus: float = 0.0
	var missing_item_penalty: float = 0.0
	var force_fail: bool = false
	var gating_reason: String = ""
	
	# Fabric Pitch Gating
	if is_fabric_pitch:
		if not has_fabric:
			force_fail = true
			missing_item_penalty = 50.0
			gating_reason = "Target demanded to inspect fabric swatches, but player carries no fabric sample!"
		else:
			item_bonus += 35.0
			if personality.get("greedy", 0.5) >= 0.6:
				item_bonus += 15.0

	# Tonic / Remedy Pitch Gating
	elif is_tonic_pitch:
		if not has_tonic:
			force_fail = true
			missing_item_penalty = 50.0
			gating_reason = "Target demanded to see the miracle remedy, but player carries no tonic or potion bottle!"
		else:
			item_bonus += 35.0
			if personality.get("superstitious", 0.5) >= 0.6:
				item_bonus += 15.0

	# Poverty / Charity Pitch Gating
	elif is_poverty_pitch:
		if not has_beggars_robe:
			force_fail = true
			missing_item_penalty = 50.0
			gating_reason = "Target noticed the player is wearing clean clothes and lacks a beggar's ragged robe to substantiate poverty!"
		else:
			item_bonus += 30.0
			if personality.get("empathetic", 0.5) >= 0.6:
				item_bonus += 15.0

	# Nobility / Aristocratic Pitch Gating
	elif is_nobility_pitch:
		if not (has_monocle or has_patent):
			force_fail = true
			missing_item_penalty = 50.0
			gating_reason = "Target scoffed at the player's lack of a gentleman's monocle or aristocratic credentials!"
		else:
			item_bonus += 30.0
			if personality.get("status_sensitive", 0.4) >= 0.5:
				item_bonus += 15.0

	# Unspecified Money Demand Gating
	elif is_asking_money:
		force_fail = true
		missing_item_penalty = 30.0
		gating_reason = "Target refused to part with coins without seeing merchandise, credentials, or proof of hardship."

	# 3. Base Score Formula
	var base_score: float = (trust * 0.35) \
		+ (credibility * 25.0) \
		+ (overall_trust * 0.20) \
		+ affinity_bonus \
		+ item_bonus \
		- missing_item_penalty \
		- skepticism_penalty \
		- (suspicion * 0.45) \
		- (past_scams * 12.0)
	
	var outcome: ScamOutcome = ScamOutcome.FAILED_MILD
	var trust_delta: int = 0
	var susp_delta: int = 0
	var money_ratio: float = 0.0
	var reason_text: String = ""
	
	var is_convinced: bool = bool(llm_result.get("convinced", false))
	
	if force_fail:
		money_ratio = 0.0
		if base_score < 25.0 or missing_item_penalty >= 45.0:
			outcome = ScamOutcome.FAILED_EXPOSED
			trust_delta = -5
			susp_delta = +26
		else:
			outcome = ScamOutcome.FAILED_MILD
			trust_delta = -1
			susp_delta = +10
		reason_text = gating_reason
	else:
		# Evaluate against thresholds when not force failed
		if base_score >= 48.0 or (is_convinced and base_score >= 35.0):
			outcome = ScamOutcome.SUCCESS
			money_ratio = 1.0 # 100% of remaining daily spend
			trust_delta = +3
			susp_delta = +4
			reason_text = "Target was thoroughly convinced by the pitch and supporting items!"
		elif base_score >= 30.0 or (is_convinced and base_score >= 20.0):
			outcome = ScamOutcome.PARTIAL
			money_ratio = 0.50 # 50% of daily budget
			trust_delta = +1
			susp_delta = +8
			reason_text = "Target was somewhat sympathetic and offered a modest sum."
		elif base_score >= 15.0:
			outcome = ScamOutcome.FAILED_MILD
			money_ratio = 0.0
			trust_delta = -1
			susp_delta = +10
			reason_text = "Target politely declined to part with their Kurtos."
		else:
			outcome = ScamOutcome.FAILED_EXPOSED
			money_ratio = 0.0
			trust_delta = -5
			susp_delta = +26
			reason_text = "Target saw right through the story and suspected deception!"
	
	# Calculate proposed transfer amount based on remaining budget
	var remaining_budget := EconomyManager.get_remaining_daily_budget(npc_data)
	var transfer_amount := int(round(remaining_budget * money_ratio))
	
	# Check refusal trigger
	var new_suspicion: int = clampi(suspicion + susp_delta, 0, 100)
	var will_refuse: bool = (new_suspicion >= REFUSAL_SUSPICION_THRESHOLD) or (outcome == ScamOutcome.FAILED_EXPOSED and new_suspicion >= 50)
	
	return {
		"outcome": outcome,
		"score": base_score,
		"transfer_amount": transfer_amount,
		"trust_delta": trust_delta,
		"suspicion_delta": susp_delta,
		"will_refuse": will_refuse,
		"reason": reason_text,
		"matched_susceptible": matched_susceptible,
		"matched_skeptical": matched_skeptical,
		"item_bonus": item_bonus
	}
