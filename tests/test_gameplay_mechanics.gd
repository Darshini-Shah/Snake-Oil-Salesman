extends SceneTree

## Automated test suite for Snake Oil Salesman gameplay mechanics.
## Verifies AGENTS.md Rule 9 deterministic rules and authority boundary.

var passed_count: int = 0
var failed_count: int = 0


func _init() -> void:
	print("\n=======================================================")
	print("🧪 RUNNING SNAKE OIL SALESMAN MECHANICS TEST SUITE")
	print("=======================================================\n")
	
	test_game_state_kurtos_and_limits()
	test_economy_spending_caps()
	test_scam_backstory_affinity_matching()
	test_inventory_item_synergies()
	test_suspicion_escalation_and_refusal_state()
	test_day_rollover_resets()
	test_malformed_llm_response_parsing()
	test_phantom_item_detection_and_physical_evidence()
	
	print("\n-------------------------------------------------------")
	print("🏁 TEST RESULTS: %d PASSED, %d FAILED" % [passed_count, failed_count])
	print("-------------------------------------------------------\n")
	
	quit(0 if failed_count == 0 else 1)


func assert_true(condition: bool, test_name: String) -> void:
	if condition:
		print("  ✅ PASS: %s" % test_name)
		passed_count += 1
	else:
		print("  ❌ FAIL: %s" % test_name)
		failed_count += 1


func assert_eq(actual, expected, test_name: String) -> void:
	if actual == expected:
		print("  ✅ PASS: %s" % test_name)
		passed_count += 1
	else:
		print("  ❌ FAIL: %s (Expected: %s, Got: %s)" % [test_name, str(expected), str(actual)])
		failed_count += 1


func test_game_state_kurtos_and_limits() -> void:
	print("▶ Testing GameState Kurtos Arithmetic & End Conditions...")
	var gs := GameStateManager.new()
	root.add_child(gs)
	
	assert_eq(gs.player_kurtos, 50, "Initial player Kurtos should be 50")
	assert_eq(gs.current_day, 1, "Initial day should be 1")
	
	gs.add_kurtos(450)
	assert_eq(gs.player_kurtos, 500, "Adding 450 Kurtos results in 500")
	
	var spent := gs.spend_kurtos(200)
	assert_true(spent, "Spending valid amount should succeed")
	assert_eq(gs.player_kurtos, 300, "Spending 200 Kurtos leaves 300")
	
	var overspend := gs.spend_kurtos(1000)
	assert_true(not overspend, "Spending more Kurtos than owned should fail")
	assert_eq(gs.player_kurtos, 300, "Failed spend does not deduct currency")
	
	# Win condition test
	gs.add_kurtos(1_000_000)
	assert_true(gs.is_game_over, "Reaching 1M Kurtos triggers game over")
	assert_true(gs.has_won, "Reaching 1M Kurtos triggers victory")
	
	gs.queue_free()


func test_economy_spending_caps() -> void:
	print("\n▶ Testing EconomyManager Daily Spending Caps & Clamping...")
	
	var mock_npc := {
		"name": "TestNPC",
		"gold": 1000,
		"max_daily_spend": 300,
		"spent_today": 0
	}
	
	var budget_initial := EconomyManager.get_remaining_daily_budget(mock_npc)
	assert_eq(budget_initial, 300, "Remaining daily budget equals max_daily_spend when 0 spent")
	
	# Simulate spending 120
	mock_npc["spent_today"] = 120
	var budget_after_spend := EconomyManager.get_remaining_daily_budget(mock_npc)
	assert_eq(budget_after_spend, 180, "Remaining daily budget correctly subtracts spent_today")
	
	# Spending cap when NPC total gold is lower than daily cap
	mock_npc["gold"] = 50
	mock_npc["spent_today"] = 0
	var budget_low_gold := EconomyManager.get_remaining_daily_budget(mock_npc)
	assert_eq(budget_low_gold, 50, "Remaining daily budget is capped by NPC's total available gold")


func test_scam_backstory_affinity_matching() -> void:
	print("\n▶ Testing Backstory Susceptibility & Skepticism Matching with Item Gating...")
	
	# Arthur (Elder): susceptible to cures/curses
	var arthur_data := {
		"name": "Old Arthur",
		"trust": 55,
		"suspicion": 10,
		"gold": 400,
		"max_daily_spend": 180,
		"spent_today": 0,
		"personality": {"superstitious": 0.95, "skeptical": 0.2},
		"susceptible_topics": ["curse", "omen", "miracle", "tonic", "elixir"],
		"skeptical_topics": ["skeptic", "logic"]
	}
	
	var llm_response_arthur := {"intent": "PITCH_SCAM", "credibility": 0.85, "relationship_signal": "POSITIVE"}
	var empty_inv: Array[Dictionary] = []
	
	# Case 1: Arthur with empty inventory (no tonic bottle) -> REJECTED!
	var res_arthur_empty := ScamManager.evaluate_pitch(
		arthur_data,
		"I have a miracle elixir to protect your home from dark omens and ancient curses!",
		llm_response_arthur,
		empty_inv,
		25
	)
	assert_true(res_arthur_empty.outcome != ScamManager.ScamOutcome.SUCCESS, "Arthur rejects elixir pitch without tonic sample in inventory")
	assert_eq(res_arthur_empty.transfer_amount, 0, "No Kurtos transferred when player has no tonic vial")
	
	# Case 2: Arthur WITH miracle tonic sample in inventory -> SUCCEEDS!
	var inv_with_tonic: Array[Dictionary] = [{"id": "miracle_tonic_sample", "name": "Miracle Tonic Sample"}]
	var res_arthur_with_tonic := ScamManager.evaluate_pitch(
		arthur_data,
		"I have a miracle elixir to protect your home from dark omens and ancient curses!",
		llm_response_arthur,
		inv_with_tonic,
		25
	)
	assert_eq(res_arthur_with_tonic.outcome, ScamManager.ScamOutcome.SUCCESS, "Arthur is convinced when player holds genuine tonic sample")
	assert_true(res_arthur_with_tonic.transfer_amount > 0, "Arthur donates Kurtos on successful pitch with tonic sample")
	
	# Marla (Baker): susceptible to sick family
	var marla_data := {
		"name": "Marla",
		"trust": 65,
		"suspicion": 10,
		"gold": 650,
		"max_daily_spend": 220,
		"spent_today": 0,
		"personality": {"empathetic": 0.90, "trusting": 0.75},
		"susceptible_topics": ["sick", "fever", "illness", "child", "family", "charity"],
		"skeptical_topics": ["threat", "extort", "robbery"]
	}
	
	var llm_response_marla := {"intent": "PITCH_SCAM", "credibility": 0.85, "relationship_signal": "POSITIVE"}
	
	# Case 1: Marla with empty inventory (clean clothes, no beggar's robe) -> REJECTED!
	var res_marla_empty := ScamManager.evaluate_pitch(
		marla_data,
		"My family has fallen sick with a terrible fever, our child needs medicine! Please spare charity!",
		llm_response_marla,
		empty_inv,
		25
	)
	assert_true(res_marla_empty.outcome != ScamManager.ScamOutcome.SUCCESS, "Marla rejects sob story when player lacks beggar's robe")
	assert_eq(res_marla_empty.transfer_amount, 0, "Zero Kurtos transferred when player has clean clothes and no beggar's robe")
	
	# Case 2: Marla WITH Beggar's Robe -> SUCCEEDS!
	var inv_with_robe: Array[Dictionary] = [{"id": "beggars_robe", "name": "Beggar's Robe"}]
	var res_marla_with_robe := ScamManager.evaluate_pitch(
		marla_data,
		"My family has fallen sick with a terrible fever, our child needs medicine! Please spare charity!",
		llm_response_marla,
		inv_with_robe,
		25
	)
	assert_eq(res_marla_with_robe.outcome, ScamManager.ScamOutcome.SUCCESS, "Marla is deeply moved when player is wearing Beggar's Robe")
	assert_eq(res_marla_with_robe.transfer_amount, 220, "Marla gives full daily budget when player wears Beggar's Robe")


func test_inventory_item_synergies() -> void:
	print("\n▶ Testing Inventory Item Synergies & Gating Across All NPC Personas...")
	
	var marla_data := {
		"name": "Marla",
		"trust": 40,
		"suspicion": 20,
		"gold": 600,
		"max_daily_spend": 200,
		"spent_today": 0,
		"personality": {"empathetic": 0.9},
		"susceptible_topics": ["charity"],
		"skeptical_topics": []
	}
	
	var llm_response := {"intent": "PITCH_SCAM", "credibility": 0.5, "relationship_signal": "NEUTRAL"}
	
	# Without Beggar's Robe
	var res_no_item := ScamManager.evaluate_pitch(marla_data, "Please spare charity for a starving beggar", llm_response, [], 20)
	assert_eq(res_no_item.transfer_amount, 0, "Charity pitch without Beggar's Robe transfers 0 Kurtos")
	
	# With Beggar's Robe
	var inv_with_robe: Array[Dictionary] = [{"id": "beggars_robe", "name": "Beggar's Robe"}]
	var res_with_robe := ScamManager.evaluate_pitch(marla_data, "Please spare charity for a starving beggar", llm_response, inv_with_robe, 20)
	assert_true(res_with_robe.score > res_no_item.score, "Beggar's Robe increases pitch score with empathetic NPC")
	assert_eq(res_with_robe.item_bonus, 45.0, "Beggar's Robe grants +45 item bonus (+30 base +15 empathetic)")
	
	# Cedric Monocle gating test
	var cedric_data := {
		"name": "Lord Cedric",
		"trust": 35,
		"suspicion": 15,
		"gold": 5000,
		"max_daily_spend": 1000,
		"spent_today": 0,
		"personality": {"status_sensitive": 0.95, "skeptical": 0.7},
		"susceptible_topics": ["royal", "noble", "prestige"],
		"skeptical_topics": ["beggar"]
	}
	var noble_pitch := "I represent high nobility with an exclusive royal investment opportunity!"
	var llm_noble := {"intent": "PITCH_SCAM", "credibility": 0.85, "relationship_signal": "POSITIVE", "convinced": true}
	
	# Without Monocle
	var res_cedric_no_monocle := ScamManager.evaluate_pitch(cedric_data, noble_pitch, llm_noble, [], 20)
	assert_true(res_cedric_no_monocle.outcome != ScamManager.ScamOutcome.SUCCESS, "Cedric rejects royal pitch without gentleman's monocle")
	assert_eq(res_cedric_no_monocle.transfer_amount, 0, "Cedric transfers 0 Kurtos without monocle")
	
	# With Monocle
	var inv_with_monocle: Array[Dictionary] = [{"id": "monocle", "name": "Gentleman's Monocle"}]
	var res_cedric_with_monocle := ScamManager.evaluate_pitch(cedric_data, noble_pitch, llm_noble, inv_with_monocle, 20)
	assert_eq(res_cedric_with_monocle.outcome, ScamManager.ScamOutcome.SUCCESS, "Cedric accepts royal pitch when player wears gentleman's monocle")
	assert_true(res_cedric_with_monocle.transfer_amount > 0, "Cedric transfers Kurtos when monocle is present")


func test_suspicion_escalation_and_refusal_state() -> void:
	print("\n▶ Testing Suspicion Escalation & Refusal Lock-out...")
	
	var cedric_data := {
		"name": "Lord Cedric",
		"trust": 20,
		"suspicion": 55, # Already somewhat suspicious
		"gold": 5000,
		"max_daily_spend": 1000,
		"spent_today": 0,
		"personality": {"skeptical": 0.8, "status_sensitive": 0.95},
		"susceptible_topics": ["royal"],
		"skeptical_topics": ["beggar", "peasant", "spare coin"]
	}
	
	# Rude beggar message triggers skeptical topic and low credibility
	var llm_bad_pitch := {"intent": "LIE", "credibility": 0.15, "relationship_signal": "NEGATIVE"}
	var res_cedric := ScamManager.evaluate_pitch(
		cedric_data,
		"Hey peasant noble, hand over a spare coin for this beggar!",
		llm_bad_pitch,
		[],
		20
	)
	
	assert_eq(res_cedric.outcome, ScamManager.ScamOutcome.FAILED_EXPOSED, "Insulting beggar claim is exposed as failed con")
	assert_true(res_cedric.suspicion_delta >= 20, "Exposed con adds high suspicion (+26)")
	assert_true(res_cedric.will_refuse, "Suspicion escalation triggers refusal lock-out")


func test_day_rollover_resets() -> void:
	print("\n▶ Testing Day Rollover Daily Spend Reset & Cooldowns...")
	
	var npc := TownNPC.new()
	npc.max_daily_spend = 300
	npc.spent_today = 300
	npc.suspicion = 80
	npc.trigger_refusal(60.0)
	
	assert_true(npc.is_refusing_to_talk, "NPC enters refusal state")
	
	# Advance day
	npc.on_day_rollover(2)
	
	assert_eq(npc.spent_today, 0, "Day rollover resets spent_today to 0")
	assert_eq(npc.suspicion, 60, "Day rollover cools down suspicion by 20 points")
	assert_true(not npc.is_refusing_to_talk, "Day rollover clears refusal state")
	
	npc.queue_free()


func test_malformed_llm_response_parsing() -> void:
	print("\n▶ Testing LLM Response Validation & Fallback Safety...")
	
	var llm := LocalLLM.new()
	root.add_child(llm)
	
	# Valid JSON
	var valid_json := '{"intent": "PITCH_SCAM", "tone": "FRIENDLY", "credibility": 0.85, "relationship_signal": "POSITIVE", "convinced": true, "proposed_kurtos": 250, "response": "Sounds marvelous!"}'
	var parsed_valid := llm._parse_and_validate_response(valid_json)
	assert_eq(parsed_valid.intent, "PITCH_SCAM", "Parses valid intent")
	assert_eq(parsed_valid.credibility, 0.85, "Parses and clamps credibility")
	assert_eq(parsed_valid.proposed_kurtos, 250, "Parses proposed Kurtos")
	
	# Malformed / gibberish string
	var malformed := "I am an AI and here is my answer: [not json]"
	var parsed_bad := llm._parse_and_validate_response(malformed)
	assert_true(parsed_bad.is_empty(), "Malformed LLM output safely evaluates to empty Dictionary for fallback")
	
	# Clamping out-of-range credibility
	var extreme_json := '{"intent": "NORMAL_CONVERSATION", "credibility": 99.9, "response": "Yes"}'
	var parsed_extreme := llm._parse_and_validate_response(extreme_json)
	assert_eq(parsed_extreme.credibility, 1.0, "Excessive credibility clamped to 1.0")
	
	llm.queue_free()


func test_phantom_item_detection_and_physical_evidence() -> void:
	print("\n▶ Testing Physical Merchandise Verification & Phantom Item Bluff Detection...")
	
	var barnaby_data := {
		"name": "Barnaby",
		"trust": 45,
		"suspicion": 15,
		"gold": 1200,
		"max_daily_spend": 350,
		"spent_today": 0,
		"personality": {"greedy": 0.75, "skeptical": 0.50},
		"susceptible_topics": ["profit", "trade", "deal"],
		"skeptical_topics": ["tax"]
	}
	
	var fabric_pitch := "Hi, invest in my designer fabric business! Here is a design of the fabric. Look at its color!!"
	var llm_response := {"intent": "PITCH_SCAM", "credibility": 0.5, "relationship_signal": "NEUTRAL"}
	
	# Case 1: Player has NO fabric sample in inventory (empty hands bluff)
	var empty_inv: Array[Dictionary] = []
	var res_phantom := ScamManager.evaluate_pitch(barnaby_data, fabric_pitch, llm_response, empty_inv, 25)
	assert_true(res_phantom.outcome != ScamManager.ScamOutcome.SUCCESS, "Phantom fabric pitch without sample fails")
	assert_true(res_phantom.suspicion_delta >= 18, "Claiming to show fabric with empty hands incurs heavy suspicion (+18)")
	
	# Case 2: Player HAS the fabric sample in inventory
	var inv_with_fabric: Array[Dictionary] = [{"id": "fabric_sample", "name": "Vibrant Silk Swatch"}]
	var llm_response_backed := {"intent": "PITCH_SCAM", "credibility": 0.85, "convinced": true, "relationship_signal": "POSITIVE"}
	var res_backed := ScamManager.evaluate_pitch(barnaby_data, fabric_pitch, llm_response_backed, inv_with_fabric, 25)
	assert_true(res_backed.score > res_phantom.score, "Backing up pitch with genuine physical inventory sample gives massive score boost")
	assert_eq(res_backed.outcome, ScamManager.ScamOutcome.SUCCESS, "Pitch with physical merchandise in inventory succeeds")
