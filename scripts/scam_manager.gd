class_name ScamManager
extends Node

## Deterministic Scam, Social & Categorized Interaction Resolver.
## Adheres to AGENTS.md Rule 4 (prefer deterministic math) and docs/GAME_DESIGN.md.

enum ScamOutcome {
	SUCCESS,
	PARTIAL,
	FAILED_MILD,
	FAILED_EXPOSED,
	SOCIAL_CHAT
}

enum InteractionCategory {
	CASUAL_CHAT,
	PROBE_BACKGROUND,
	SHOW_ITEM,
	PITCH_SALE,
	PITCH_INVESTMENT,
	PITCH_CHARITY,
	BLATANT_DEMAND,
	INSULT_OR_THREAT
}

const REFUSAL_SUSPICION_THRESHOLD: int = 70


## Analyzes and categorizes player message prior to LLM submission.
## Detects intent, requested currency amount, and referenced items.
static func categorize_message(player_message: String, inventory_items: Array[Dictionary]) -> Dictionary:
	var lower := player_message.to_lower().strip_edges()
	
	# 1. Check for Insults, Hostility or Threats
	var is_insult: bool = (
		lower.contains("idiot") or lower.contains("fool") or lower.contains("shut up") or
		lower.contains("hate you") or lower.contains("kill") or lower.contains("die ") or
		lower.contains("threat") or lower.contains("steal") or lower.contains("rob you") or
		lower.contains("ugly") or lower.contains("scum") or lower.contains("liar") or
		lower.contains("stupid") or lower.contains("get lost") or lower.contains("curse you")
	)
	if is_insult:
		return {
			"category": InteractionCategory.INSULT_OR_THREAT,
			"category_name": "INSULT_OR_THREAT",
			"asked_amount": 0,
			"referenced_item": "",
			"has_referenced_item": false,
			"is_commercial_deal": false
		}
	
	# 2. Extract requested currency amount if specified (e.g. "40 kurtos", "for 50 coins", "cost 30")
	var asked_amount := 0
	var reg := RegEx.new()
	var _compile_res := reg.compile("(?:([0-9]+)\\s*(?:kurtos|coin|coins|gold))|(?:(?:for|price|cost|give|pay|lend|charge)\\s*([0-9]+))")
	var m := reg.search(lower)
	if m:
		var s1 := m.get_string(1)
		var s2 := m.get_string(2)
		if not s1.is_empty():
			asked_amount = s1.to_int()
		elif not s2.is_empty():
			asked_amount = s2.to_int()
	
	# 3. Detect referenced item archetype
	var referenced_item := ""
	if lower.contains("tonic") or lower.contains("elixir") or lower.contains("potion") or \
	   lower.contains("cure") or lower.contains("remedy") or lower.contains("snake oil"):
		referenced_item = "miracle_tonic_sample"
	elif lower.contains("fabric") or lower.contains("cloth") or lower.contains("garment") or \
		 lower.contains("seamster") or lower.contains("textile") or lower.contains("silk") or \
		 lower.contains("swatch") or lower.contains("tailor") or lower.contains("designer"):
		referenced_item = "fabric_sample"
	elif lower.contains("monocle") or lower.contains("royal") or lower.contains("noble") or \
		 lower.contains("aristocrat") or lower.contains("high society") or lower.contains("patent"):
		referenced_item = "monocle"
	elif lower.contains("beggar") or lower.contains("robe") or lower.contains("rags") or \
		 lower.contains("poverty") or lower.contains("destitute"):
		referenced_item = "beggars_robe"
	
	var has_referenced_item := false
	if not referenced_item.is_empty():
		for it in inventory_items:
			var it_id: String = str(it.get("id", ""))
			if it_id == referenced_item or (referenced_item == "monocle" and it_id == "forged_patent"):
				has_referenced_item = true
				break
	
	# 4. Check for Blatant Demand (Asking for money with zero offer or context)
	var is_demand_keywords: bool = (
		lower.contains("give me") or lower.contains("hand over") or lower.contains("pay me") or
		lower.contains("gimme") or (lower.contains("spare") and lower.contains("kurtos"))
	)
	var has_context: bool = (
		referenced_item != "" or lower.contains("sell") or lower.contains("buy") or
		lower.contains("invest") or lower.contains("trade") or lower.contains("child") or
		lower.contains("sick") or lower.contains("charity") or lower.contains("partner")
	)
	if is_demand_keywords and not has_context:
		return {
			"category": InteractionCategory.BLATANT_DEMAND,
			"category_name": "BLATANT_DEMAND",
			"asked_amount": asked_amount,
			"referenced_item": "",
			"has_referenced_item": false,
			"is_commercial_deal": false
		}
	
	# 5. Check for Charity / Poverty Pitch
	var is_poverty: bool = (
		lower.contains("sick") or lower.contains("fever") or lower.contains("child") or
		lower.contains("starv") or lower.contains("hungry") or lower.contains("hunger") or
		lower.contains("poor") or lower.contains("charity") or lower.contains("alms") or
		lower.contains("orphan") or lower.contains("destitute") or lower.contains("pity") or
		(lower.contains("spare") and (lower.contains("medicine") or lower.contains("food") or lower.contains("alms") or lower.contains("family")))
	)
	if is_poverty:
		return {
			"category": InteractionCategory.PITCH_CHARITY,
			"category_name": "PITCH_CHARITY",
			"asked_amount": asked_amount,
			"referenced_item": "beggars_robe",
			"has_referenced_item": has_referenced_item,
			"is_commercial_deal": true
		}
	
	# 6. Check for Investment Pitch
	var is_investment: bool = (
		lower.contains("invest") or lower.contains("investment") or lower.contains("venture") or
		lower.contains("partnership") or lower.contains("exclusive privilege") or
		lower.contains("royal society") or lower.contains("double profit") or
		lower.contains("trade deal") or lower.contains("wholesale trade") or
		lower.contains("exclusive wholesale") or lower.contains("business")
	)
	if is_investment:
		return {
			"category": InteractionCategory.PITCH_INVESTMENT,
			"category_name": "PITCH_INVESTMENT",
			"asked_amount": asked_amount,
			"referenced_item": referenced_item if referenced_item != "" else "monocle",
			"has_referenced_item": has_referenced_item,
			"is_commercial_deal": true
		}
	
	# 7. Check for Commercial Sale Pitch (Explicit sell / buy / price proposal)
	var is_sale_action: bool = (
		lower.contains("sell") or lower.contains("buy") or lower.contains("purchase") or
		lower.contains("cost") or lower.contains("charge") or lower.contains("price") or
		lower.contains("for only") or lower.contains("take this for") or
		lower.contains("bargain") or (asked_amount > 0 and referenced_item != "")
	)
	if is_sale_action and referenced_item != "":
		return {
			"category": InteractionCategory.PITCH_SALE,
			"category_name": "PITCH_SALE",
			"asked_amount": asked_amount,
			"referenced_item": referenced_item,
			"has_referenced_item": has_referenced_item,
			"is_commercial_deal": true
		}
	
	# 8. Check for Showing an Item (Inspection / Bragging / Display without asking for money)
	var is_showing: bool = (
		lower.contains("look at") or lower.contains("see this") or lower.contains("check out") or
		lower.contains("behold") or lower.contains("here is") or lower.contains("i possess") or
		lower.contains("have here") or lower.contains("look here") or lower.contains("examine") or
		lower.contains("witness") or lower.begins_with("look ") or lower.begins_with("see ")
	)
	if is_showing and referenced_item != "":
		return {
			"category": InteractionCategory.SHOW_ITEM,
			"category_name": "SHOW_ITEM",
			"asked_amount": 0,
			"referenced_item": referenced_item,
			"has_referenced_item": has_referenced_item,
			"is_commercial_deal": false
		}
	
	# 9. Check for Probing Background / Lore / Fears (genuine inquiry into backstory or dark lore)
	var is_probe: bool = (
		lower.contains("trouble") or lower.contains("fear") or lower.contains("worry") or
		lower.contains("omen") or lower.contains("curse") or lower.contains("spirit") or
		lower.contains("secret") or lower.contains("rumor") or lower.contains("midnight") or
		lower.contains("darkness") or lower.contains("superstition") or lower.contains("why do you") or
		lower.contains("tell me about") or lower.contains("what happened") or lower.contains("your past")
	)
	if is_probe:
		return {
			"category": InteractionCategory.PROBE_BACKGROUND,
			"category_name": "PROBE_BACKGROUND",
			"asked_amount": 0,
			"referenced_item": referenced_item,
			"has_referenced_item": has_referenced_item,
			"is_commercial_deal": false
		}
	
	# 10. Default: Casual Chat
	return {
		"category": InteractionCategory.CASUAL_CHAT,
		"category_name": "CASUAL_CHAT",
		"asked_amount": 0,
		"referenced_item": "",
		"has_referenced_item": false,
		"is_commercial_deal": false
	}


## Resolves any categorized interaction with strict per-category money, trust, suspicion, and reputation rules.
static func resolve_interaction(
	cat_info: Dictionary,
	npc_data: Dictionary,
	player_message: String,
	llm_result: Dictionary,
	inventory_items: Array[Dictionary],
	overall_trust: int
) -> Dictionary:
	var category: int = int(cat_info.get("category", InteractionCategory.CASUAL_CHAT))
	var trust: int = int(npc_data.get("trust", 50))
	var suspicion: int = int(npc_data.get("suspicion", 10))
	var past_scams: int = int(npc_data.get("successful_scam_count", 0)) + int(npc_data.get("failed_scam_count", 0))
	var personality: Dictionary = npc_data.get("personality", {})
	var npc_name: String = str(npc_data.get("npc_name", npc_data.get("name", "Resident")))
	var remaining_budget := EconomyManager.get_remaining_daily_budget(npc_data)
	
	var lower_msg := player_message.to_lower()
	var llm_response_text: String = str(llm_result.get("response", "")).to_lower()
	
	# Scan for explicit refusal markers in LLM reply to prevent dialogue/engine desync
	var dialogue_refused: bool = (
		llm_response_text.contains("can't spare") or llm_response_text.contains("cannot afford") or
		llm_response_text.contains("for free") or llm_response_text.contains("no coin") or
		llm_response_text.contains("leave me") or llm_response_text.contains("swindler") or
		llm_response_text.contains("cannot spare") or llm_response_text.contains("not interested") or
		llm_response_text.contains("too expensive") or llm_response_text.contains("keep your")
	)
	
	# -------------------------------------------------------------
	# CATEGORY 1: INSULT OR THREAT
	# -------------------------------------------------------------
	if category == InteractionCategory.INSULT_OR_THREAT:
		var susp_delta := +28
		var trust_delta := -10
		var rep_delta := -2
		var will_refuse: bool = (suspicion + susp_delta >= REFUSAL_SUSPICION_THRESHOLD) or true
		return {
			"category": category,
			"outcome": ScamOutcome.FAILED_EXPOSED,
			"score": 0.0,
			"transfer_amount": 0,
			"trust_delta": trust_delta,
			"suspicion_delta": susp_delta,
			"reputation_delta": rep_delta,
			"will_refuse": will_refuse,
			"reason": "%s was deeply insulted and threatened by your hostility!" % npc_name,
			"feedback_message": "[%s is outraged by your hostility! (+28 Suspicion, -10 Trust)]" % npc_name,
			"item_bonus": 0.0,
			"matched_susceptible": [],
			"matched_skeptical": []
		}
	
	# -------------------------------------------------------------
	# CATEGORY 2: BLATANT DEMAND (Asking for coins with no goods or reason)
	# -------------------------------------------------------------
	if category == InteractionCategory.BLATANT_DEMAND:
		var susp_delta := +18
		var trust_delta := -4
		var rep_delta := -1
		var will_refuse: bool = (suspicion + susp_delta >= REFUSAL_SUSPICION_THRESHOLD)
		return {
			"category": category,
			"outcome": ScamOutcome.FAILED_MILD,
			"score": 10.0,
			"transfer_amount": 0,
			"trust_delta": trust_delta,
			"suspicion_delta": susp_delta,
			"reputation_delta": rep_delta,
			"will_refuse": will_refuse,
			"reason": "%s refused your brazen demand for free coins." % npc_name,
			"feedback_message": "[%s scoffed at your demand for free coins! (+18 Suspicion)]" % npc_name,
			"item_bonus": 0.0,
			"matched_susceptible": [],
			"matched_skeptical": []
		}
	
	# -------------------------------------------------------------
	# CATEGORY 3: SHOW ITEM (Inspection / Boast without selling)
	# -------------------------------------------------------------
	if category == InteractionCategory.SHOW_ITEM:
		var has_item: bool = bool(cat_info.get("has_referenced_item", false))
		var ref_id: String = str(cat_info.get("referenced_item", ""))
		
		if has_item:
			# Genuine item shown! Builds rapport, strictly 0 Kurtos transferred
			var t_delta := +2
			var feedback := "[%s examines your item with interest. (+2 Trust)]" % npc_name
			
			if ref_id == "miracle_tonic_sample" and personality.get("superstitious", 0.5) >= 0.6:
				t_delta = +4
				feedback = "[%s stares with superstitious awe at your tonic sample! (+4 Trust)]" % npc_name
			elif ref_id == "fabric_sample" and personality.get("greedy", 0.5) >= 0.6:
				t_delta = +4
				feedback = "[%s admires the fine texture of your silk swatch! (+4 Trust)]" % npc_name
			elif ref_id == "monocle" and personality.get("status_sensitive", 0.4) >= 0.5:
				t_delta = +4
				feedback = "[%s observes your gentleman's monocle with respect. (+4 Trust)]" % npc_name
			
			return {
				"category": category,
				"outcome": ScamOutcome.SOCIAL_CHAT,
				"score": 40.0,
				"transfer_amount": 0,
				"trust_delta": t_delta,
				"suspicion_delta": 0,
				"reputation_delta": 0,
				"will_refuse": false,
				"reason": "%s inspected your displayed merchandise." % npc_name,
				"feedback_message": feedback,
				"item_bonus": 25.0,
				"matched_susceptible": [],
				"matched_skeptical": []
			}
		else:
			# Phantom item boast! Claimed to show something with empty hands!
			var s_delta := +18
			var t_delta := -3
			var r_delta := -1
			var will_refuse: bool = (suspicion + s_delta >= REFUSAL_SUSPICION_THRESHOLD)
			return {
				"category": category,
				"outcome": ScamOutcome.FAILED_EXPOSED,
				"score": 5.0,
				"transfer_amount": 0,
				"trust_delta": t_delta,
				"suspicion_delta": s_delta,
				"reputation_delta": r_delta,
				"will_refuse": will_refuse,
				"reason": "You claimed to show an item, but your hands are empty!",
				"feedback_message": "[Bluff Caught: You claim to show an item, but your hands are empty! (+18 Suspicion)]",
				"item_bonus": 0.0,
				"matched_susceptible": [],
				"matched_skeptical": []
			}
	
	# -------------------------------------------------------------
	# CATEGORY 4: PROBE BACKGROUND (Questions about lore, fears, gossip)
	# -------------------------------------------------------------
	if category == InteractionCategory.PROBE_BACKGROUND:
		var susceptible: Array = npc_data.get("susceptible_topics", [])
		var skeptical: Array = npc_data.get("skeptical_topics", [])
		var matched_susc: Array = []
		var matched_skep: Array = []
		
		for t in susceptible:
			if lower_msg.contains(str(t).to_lower()):
				matched_susc.append(t)
		for t in skeptical:
			if lower_msg.contains(str(t).to_lower()):
				matched_skep.append(t)
		
		var t_delta := +1
		var s_delta := 0
		var r_delta := 0
		var feedback := ""
		
		if not matched_susc.is_empty():
			t_delta = +3
			r_delta = +1
			feedback = "[%s opens up to your question about %s (+3 Trust)]" % [npc_name, ", ".join(matched_susc)]
		elif not matched_skep.is_empty():
			s_delta = +6
			t_delta = -1
			feedback = "[%s becomes guarded when asked about %s (+6 Suspicion)]" % [npc_name, ", ".join(matched_skep)]
		
		return {
			"category": category,
			"outcome": ScamOutcome.SOCIAL_CHAT,
			"score": 30.0,
			"transfer_amount": 0,
			"trust_delta": t_delta,
			"suspicion_delta": s_delta,
			"reputation_delta": r_delta,
			"will_refuse": false,
			"reason": "Discussed background and town lore.",
			"feedback_message": feedback,
			"item_bonus": 0.0,
			"matched_susceptible": matched_susc,
			"matched_skeptical": matched_skep
		}
	
	# -------------------------------------------------------------
	# CATEGORY 5: CASUAL CHAT (Greetings and small talk)
	# -------------------------------------------------------------
	if category == InteractionCategory.CASUAL_CHAT:
		var s_delta := -1 if suspicion > 15 else 0
		return {
			"category": category,
			"outcome": ScamOutcome.SOCIAL_CHAT,
			"score": 25.0,
			"transfer_amount": 0,
			"trust_delta": +1,
			"suspicion_delta": s_delta,
			"reputation_delta": 0,
			"will_refuse": false,
			"reason": "Engaged in friendly casual conversation.",
			"feedback_message": "",
			"item_bonus": 0.0,
			"matched_susceptible": [],
			"matched_skeptical": []
		}
	
	# -------------------------------------------------------------
	# CATEGORIES 6, 7, 8: COMMERCIAL DEALS & PITCHES
	# (PITCH_SALE, PITCH_INVESTMENT, PITCH_CHARITY)
	# -------------------------------------------------------------
	var credibility: float = float(llm_result.get("credibility", 0.5))
	var is_convinced: bool = bool(llm_result.get("convinced", false))
	if dialogue_refused:
		is_convinced = false
	
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
	
	# 2. Inventory item physical presence check
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
	
	var item_bonus: float = 0.0
	var missing_item_penalty: float = 0.0
	var force_fail: bool = false
	var gating_reason: String = ""
	var default_tier_price: int = 35
	var tier_cap: int = 50
	
	if category == InteractionCategory.PITCH_SALE:
		var ref_id: String = str(cat_info.get("referenced_item", "miracle_tonic_sample"))
		if ref_id == "fabric_sample":
			default_tier_price = 45
			tier_cap = 65
			if not has_fabric:
				force_fail = true
				missing_item_penalty = 50.0
				gating_reason = "Target demanded to inspect fabric swatches, but player carries no fabric sample!"
			else:
				item_bonus += 35.0
				if personality.get("greedy", 0.5) >= 0.6:
					item_bonus += 15.0
		else:
			# Tonic / remedy
			default_tier_price = 35
			tier_cap = 50
			if not has_tonic:
				force_fail = true
				missing_item_penalty = 50.0
				gating_reason = "Target demanded to see the miracle remedy, but player carries no tonic sample!"
			else:
				item_bonus += 35.0
				if personality.get("superstitious", 0.5) >= 0.6:
					item_bonus += 15.0
	
	elif category == InteractionCategory.PITCH_CHARITY:
		default_tier_price = 20
		tier_cap = 35
		if not has_beggars_robe:
			force_fail = true
			missing_item_penalty = 50.0
			gating_reason = "Target noticed the player is wearing clean clothes and lacks a beggar's ragged robe to substantiate poverty!"
		else:
			item_bonus += 30.0
			if personality.get("empathetic", 0.5) >= 0.6:
				item_bonus += 15.0
	
	elif category == InteractionCategory.PITCH_INVESTMENT:
		default_tier_price = 70
		tier_cap = 120
		if not (has_monocle or has_patent or has_fabric):
			force_fail = true
			missing_item_penalty = 50.0
			gating_reason = "Target scoffed at the player's lack of investment credentials or product samples!"
		else:
			item_bonus += 30.0
			if has_fabric and personality.get("greedy", 0.5) >= 0.6:
				item_bonus += 15.0
			elif (has_monocle or has_patent) and personality.get("status_sensitive", 0.4) >= 0.5:
				item_bonus += 15.0
	
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
	var rep_delta: int = 0
	var transfer_amount: int = 0
	var reason_text: String = ""
	var feedback: String = ""
	
	if force_fail:
		outcome = ScamOutcome.FAILED_EXPOSED
		trust_delta = -5
		susp_delta = +26
		rep_delta = -2
		transfer_amount = 0
		reason_text = gating_reason
		feedback = "[Bluff Caught: %s saw right through your unsupported claims! (+26 Suspicion)]" % npc_name
	
	elif dialogue_refused or base_score < 35.0:
		outcome = ScamOutcome.FAILED_MILD
		trust_delta = -1
		susp_delta = +8
		rep_delta = 0
		transfer_amount = 0
		reason_text = "%s declined your offer." % npc_name
		feedback = "[Offer Declined: %s cannot spare coins for this offer.]" % npc_name
	
	else:
		# Deal Accepted!
		outcome = ScamOutcome.SUCCESS
		var asked: int = int(cat_info.get("asked_amount", 0))
		var target_price := asked if asked > 0 else default_tier_price
		# Transfer is bounded by requested price, reasonable item tier cap, and NPC remaining budget
		if cat_info.get("legacy_mode", false) and asked <= 0:
			transfer_amount = int(round(remaining_budget * (1.0 if base_score >= 48.0 else 0.5)))
		else:
			transfer_amount = mini(target_price, mini(tier_cap, remaining_budget))
		trust_delta = +3
		susp_delta = +3
		rep_delta = +1
		reason_text = "Target agreed to the deal and transferred %d Kurtos." % transfer_amount
		feedback = "[Deal Concluded: Received +%d Kurtos!]" % transfer_amount
	
	var new_suspicion: int = clampi(suspicion + susp_delta, 0, 100)
	var will_refuse: bool = (new_suspicion >= REFUSAL_SUSPICION_THRESHOLD) or (outcome == ScamOutcome.FAILED_EXPOSED and new_suspicion >= 50)
	
	return {
		"category": category,
		"outcome": outcome,
		"score": base_score,
		"transfer_amount": transfer_amount,
		"trust_delta": trust_delta,
		"suspicion_delta": susp_delta,
		"reputation_delta": rep_delta,
		"will_refuse": will_refuse,
		"reason": reason_text,
		"feedback_message": feedback,
		"matched_susceptible": matched_susceptible,
		"matched_skeptical": matched_skeptical,
		"item_bonus": item_bonus
	}


## Backward-compatible wrapper for evaluate_pitch
static func evaluate_pitch(
	npc_data: Dictionary,
	player_message: String,
	llm_result: Dictionary,
	inventory_items: Array[Dictionary],
	overall_trust: int
) -> Dictionary:
	var cat_info := categorize_message(player_message, inventory_items)
	cat_info["legacy_mode"] = true
	
	# If called directly via evaluate_pitch with pitch wording, ensure pitch category
	if not cat_info.get("is_commercial_deal", false) and \
	   cat_info["category"] != InteractionCategory.INSULT_OR_THREAT and \
	   cat_info["category"] != InteractionCategory.BLATANT_DEMAND:
		var lower := player_message.to_lower()
		if lower.contains("tonic") or lower.contains("elixir") or lower.contains("potion") or lower.contains("cure"):
			cat_info["category"] = InteractionCategory.PITCH_SALE
			cat_info["is_commercial_deal"] = true
			cat_info["referenced_item"] = "miracle_tonic_sample"
		elif lower.contains("fabric") or lower.contains("cloth") or lower.contains("silk"):
			cat_info["category"] = InteractionCategory.PITCH_SALE
			cat_info["is_commercial_deal"] = true
			cat_info["referenced_item"] = "fabric_sample"
		elif lower.contains("charity") or lower.contains("beggar") or lower.contains("poor"):
			cat_info["category"] = InteractionCategory.PITCH_CHARITY
			cat_info["is_commercial_deal"] = true
			cat_info["referenced_item"] = "beggars_robe"
		elif lower.contains("royal") or lower.contains("noble") or lower.contains("monocle"):
			cat_info["category"] = InteractionCategory.PITCH_INVESTMENT
			cat_info["is_commercial_deal"] = true
			cat_info["referenced_item"] = "monocle"
	
	return resolve_interaction(cat_info, npc_data, player_message, llm_result, inventory_items, overall_trust)


## Applies the 2-agent threshold evaluation formula:
## 1. score > trust -> DO_DEAL (or CONVERSE_POSITIVE)
## 2. suspicion <= score <= trust -> SKEPTICAL_REJECT (trust down, suspicion up)
## 3. score < suspicion -> REFUSE_TALK (refusal lockout)
static func apply_evaluation_thresholds(
	score: int,
	is_deal_attempt: bool,
	proposed_price: int,
	npc_data: Dictionary,
	inventory_items: Array[Dictionary],
	referenced_item_id: String = ""
) -> Dictionary:
	var trust: int = int(npc_data.get("trust", 50))
	var suspicion: int = int(npc_data.get("suspicion", 10))
	var remaining_budget := EconomyManager.get_remaining_daily_budget(npc_data)
	var npc_name: String = str(npc_data.get("npc_name", npc_data.get("name", "Resident")))
	
	# Physical item check if proposing a deal with a referenced item
	var has_item := true
	if is_deal_attempt and not referenced_item_id.is_empty():
		has_item = false
		for it in inventory_items:
			var it_id: String = str(it.get("id", ""))
			if it_id == referenced_item_id or (referenced_item_id == "monocle" and it_id == "forged_patent"):
				has_item = true
				break
	
	# Condition 1: score > trust
	if score > trust:
		if is_deal_attempt:
			if not has_item:
				var susp_delta := +26
				var trust_delta := -5
				var will_refuse: bool = (suspicion + susp_delta >= REFUSAL_SUSPICION_THRESHOLD)
				return {
					"outcome": ScamOutcome.FAILED_EXPOSED,
					"decision": "REFUSE_TALK",
					"transfer_amount": 0,
					"trust_delta": trust_delta,
					"suspicion_delta": susp_delta,
					"reputation_delta": -2,
					"will_refuse": will_refuse,
					"reason": "Caught bluffing with missing inventory item!",
					"feedback_message": "[Bluff Caught: %s noticed you lack the item! (+26 Suspicion)]" % npc_name
				}
			else:
				var target_price := proposed_price if proposed_price > 0 else 40
				var transfer_amount := mini(target_price, mini(75, remaining_budget))
				return {
					"outcome": ScamOutcome.SUCCESS,
					"decision": "DO_DEAL",
					"transfer_amount": transfer_amount,
					"trust_delta": +3,
					"suspicion_delta": +2,
					"reputation_delta": +1,
					"will_refuse": false,
					"reason": "Score %d exceeded trust %d: Deal accepted!" % [score, trust],
					"feedback_message": "[Deal Concluded: Received +%d Kurtos!]" % transfer_amount
				}
		else:
			return {
				"outcome": ScamOutcome.SOCIAL_CHAT,
				"decision": "CONVERSE_POSITIVE",
				"transfer_amount": 0,
				"trust_delta": +2,
				"suspicion_delta": -1 if suspicion > 10 else 0,
				"reputation_delta": 0,
				"will_refuse": false,
				"reason": "Score %d exceeded trust %d: Positive conversation." % [score, trust],
				"feedback_message": ""
			}
	
	# Condition 2: suspicion <= score <= trust
	elif score >= suspicion:
		var trust_delta := -3
		var susp_delta := +6
		var will_refuse: bool = (suspicion + susp_delta >= REFUSAL_SUSPICION_THRESHOLD)
		return {
			"outcome": ScamOutcome.FAILED_MILD,
			"decision": "SKEPTICAL_REJECT",
			"transfer_amount": 0,
			"trust_delta": trust_delta,
			"suspicion_delta": susp_delta,
			"reputation_delta": -1,
			"will_refuse": will_refuse,
			"reason": "Score %d between suspicion %d and trust %d: Lowered reputation & increased suspicion." % [score, suspicion, trust],
			"feedback_message": "[%s is skeptical and grows more suspicious. (-3 Trust, +6 Suspicion)]" % npc_name
		}
	
	# Condition 3: score < suspicion
	else:
		return {
			"outcome": ScamOutcome.FAILED_EXPOSED,
			"decision": "REFUSE_TALK",
			"transfer_amount": 0,
			"trust_delta": -10,
			"suspicion_delta": +25,
			"reputation_delta": -2,
			"will_refuse": true,
			"reason": "Score %d below suspicion %d: Refused to talk!" % [score, suspicion],
			"feedback_message": "[%s refuses to talk to you any further! (+25 Suspicion)]" % npc_name
		}

