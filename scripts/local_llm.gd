class_name LocalLLM
extends Node

## Local LLM Manager with 2-Step Dialogue & Evaluation Pipeline.
## Adheres to AGENTS.md:
## Step 1: Evaluator Judge evaluates conversation quality & persuasiveness (0-100).
## Step 2: Engine threshold rules determine authoritative outcome (deal, converse, reject, refuse).
## Step 3: Responding Agent generates matching in-character dialogue without engine state leaks.

signal response_generated(result: Dictionary)
signal response_error(error_message: String)
signal connection_status_changed(connected: bool, status_text: String)

enum BackendType { AUTO, OLLAMA, LLAMA_SERVER, OPENAI_COMPATIBLE }

@export var backend_type: BackendType = BackendType.AUTO
@export var ollama_url: String = "http://127.0.0.1:11434"
@export var ollama_model: String = "qwen2.5:0.5b"
@export var server_url: String = "http://127.0.0.1:8080/completion"
@export var temperature: float = 0.7
@export var max_tokens: int = 140
@export var request_timeout_seconds: float = 12.0

var is_connected: bool = false
var active_backend_name: String = "Detecting..."
var active_model_name: String = ""

enum ProbeStage { IDLE, OLLAMA, LLAMA_SERVER }
var _probe_stage: ProbeStage = ProbeStage.IDLE

enum InferenceStep { IDLE, STEP_EVALUATE, STEP_RESPOND }
var _current_step: InferenceStep = InferenceStep.IDLE

var _http_request: HTTPRequest
var _probe_http: HTTPRequest
var _pending_npc_data: Dictionary = {}
var _pending_player_message: String = ""
var _pending_category_data: Dictionary = {}
var _pending_history: Array = []
var _step1_eval_result: Dictionary = {}
var _threshold_decision: Dictionary = {}


func _ready() -> void:
	_http_request = HTTPRequest.new()
	_http_request.timeout = request_timeout_seconds
	add_child(_http_request)
	_http_request.request_completed.connect(_on_http_request_completed)
	
	_probe_http = HTTPRequest.new()
	_probe_http.timeout = 2.0
	add_child(_probe_http)
	_probe_http.request_completed.connect(_on_probe_completed)
	
	call_deferred("check_connection")


func check_connection() -> void:
	active_backend_name = "Detecting..."
	_probe_stage = ProbeStage.OLLAMA
	var err := _probe_http.request(ollama_url + "/api/tags")
	if err != OK:
		_probe_llama_server()


func _probe_llama_server() -> void:
	_probe_stage = ProbeStage.LLAMA_SERVER
	var err := _probe_http.request(server_url.replace("/completion", "/health"))
	if err != OK:
		_set_offline()


func _set_offline() -> void:
	_probe_stage = ProbeStage.IDLE
	is_connected = false
	active_backend_name = "Offline Fallback"
	active_model_name = ""
	emit_signal("connection_status_changed", false, "Offline Fallback")
	print("[LocalLLM] No active local LLM detected. Using deterministic persona fallback.")


func _on_probe_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if _probe_stage == ProbeStage.OLLAMA:
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var data: Variant = JSON.parse_string(body.get_string_from_utf8())
			if data is Dictionary and (data as Dictionary).has("models"):
				var models_arr: Array = (data as Dictionary)["models"]
				if not models_arr.is_empty():
					var chosen_model: String = ""
					for m in models_arr:
						var m_name: String = str(m.get("name", ""))
						if m_name == ollama_model or m_name.begins_with(ollama_model):
							chosen_model = m_name
							break
					if chosen_model.is_empty():
						chosen_model = str(models_arr[0].get("name", "qwen2.5:0.5b"))
					
					is_connected = true
					active_backend_name = "Ollama"
					active_model_name = chosen_model
					_probe_stage = ProbeStage.IDLE
					emit_signal("connection_status_changed", true, "Ollama: %s" % active_model_name)
					print("[LocalLLM] Successfully connected to Ollama (Model: %s)" % active_model_name)
					return
		_probe_llama_server()
	elif _probe_stage == ProbeStage.LLAMA_SERVER:
		if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 405):
			is_connected = true
			active_backend_name = "llama-server"
			active_model_name = "8080"
			_probe_stage = ProbeStage.IDLE
			emit_signal("connection_status_changed", true, "llama.cpp (8080)")
			print("[LocalLLM] Connected to llama-server on port 8080")
			return
		_set_offline()


## Dispatches 2-step evaluation and generation pipeline
func request_reply(npc_data: Dictionary, player_message: String, history: Array = [], category_data: Dictionary = {}) -> void:
	_pending_npc_data = npc_data
	_pending_player_message = player_message
	_pending_history = history.duplicate()
	
	if category_data.is_empty():
		var game_state = get_node_or_null("/root/GameState")
		var inv: Array[Dictionary] = game_state.inventory if game_state else []
		_pending_category_data = ScamManager.categorize_message(player_message, inv)
	else:
		_pending_category_data = category_data
	
	if not is_connected:
		_use_fallback_response(npc_data, player_message)
		return
	
	_dispatch_step1_evaluator()


func _dispatch_step1_evaluator() -> void:
	_current_step = InferenceStep.STEP_EVALUATE
	var prompt := _build_evaluator_prompt(_pending_npc_data, _pending_player_message, _pending_history)
	var headers := ["Content-Type: application/json"]
	var url := ""
	var json_payload := ""
	
	if active_backend_name == "Ollama":
		url = ollama_url + "/api/generate"
		var body_dict := {
			"model": active_model_name,
			"prompt": prompt,
			"format": "json",
			"stream": false,
			"options": {
				"temperature": 0.2,
				"num_predict": 45
			}
		}
		json_payload = JSON.stringify(body_dict)
	else:
		url = server_url
		var body_dict := {
			"prompt": prompt,
			"temperature": 0.2,
			"n_predict": 45,
			"stop": ["\n\n", "</s>", "<|im_end|>"]
		}
		json_payload = JSON.stringify(body_dict)
	
	var err := _http_request.request(url, headers, HTTPClient.METHOD_POST, json_payload)
	if err != OK:
		push_warning("[LocalLLM] Step 1 HTTP dispatch failed (code %d). Using fallback." % err)
		_use_fallback_response(_pending_npc_data, _pending_player_message)


func _dispatch_step2_responder() -> void:
	_current_step = InferenceStep.STEP_RESPOND
	var prompt := _build_responder_prompt(_pending_npc_data, _pending_player_message, _pending_history, _threshold_decision)
	var headers := ["Content-Type: application/json"]
	var url := ""
	var json_payload := ""
	
	if active_backend_name == "Ollama":
		url = ollama_url + "/api/generate"
		var body_dict := {
			"model": active_model_name,
			"prompt": prompt,
			"stream": false,
			"options": {
				"temperature": 0.7,
				"num_predict": 60,
				"stop": ["<|im_end|>", "\nPlayer:", "\nUser:", "\nAssistant:"]
			}
		}
		json_payload = JSON.stringify(body_dict)
	else:
		url = server_url
		var body_dict := {
			"prompt": prompt,
			"temperature": 0.7,
			"n_predict": 60,
			"stop": ["<|im_end|>", "\nPlayer:", "\nUser:", "\nAssistant:"]
		}
		json_payload = JSON.stringify(body_dict)
	
	var err := _http_request.request(url, headers, HTTPClient.METHOD_POST, json_payload)
	if err != OK:
		push_warning("[LocalLLM] Step 2 HTTP dispatch failed (code %d). Using fallback dialogue." % err)
		_finish_with_fallback_dialogue()


func _on_http_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_warning("[LocalLLM] HTTP generation returned error %d / status %d." % [result, response_code])
		if _current_step == InferenceStep.STEP_RESPOND:
			_finish_with_fallback_dialogue()
		else:
			_use_fallback_response(_pending_npc_data, _pending_player_message)
		return
	
	var response_text := body.get_string_from_utf8()
	
	if _current_step == InferenceStep.STEP_EVALUATE:
		_on_step1_evaluator_completed(response_text)
	elif _current_step == InferenceStep.STEP_RESPOND:
		_on_step2_responder_completed(response_text)
	else:
		_current_step = InferenceStep.IDLE


func _on_step1_evaluator_completed(raw_text: String) -> void:
	var eval_data := _parse_step1_json(raw_text)
	var raw_score: int = int(eval_data.get("score", -1))
	if raw_score < 0:
		raw_score = _get_heuristic_evaluation_score(_pending_npc_data, _pending_player_message)
	var score: int = clampi(raw_score, 0, 100)
	
	# AGENTS.md Engine Authority: Hostile insults, brazen demands, and phantom bluffs are capped
	var cat: int = int(_pending_category_data.get("category", ScamManager.InteractionCategory.CASUAL_CHAT))
	if cat == ScamManager.InteractionCategory.INSULT_OR_THREAT:
		score = mini(score, 5)
	elif cat == ScamManager.InteractionCategory.BLATANT_DEMAND:
		score = mini(score, 12)
	elif not bool(_pending_category_data.get("has_referenced_item", true)) and not str(_pending_category_data.get("referenced_item", "")).is_empty():
		score = mini(score, 14)
	
	# Determine if interaction is an actual commercial deal attempt
	var is_deal: bool = bool(_pending_category_data.get("is_commercial_deal", false))
	if not is_deal:
		var eval_deal: bool = bool(eval_data.get("is_deal_attempt", false))
		var lower_msg := _pending_player_message.to_lower()
		var has_deal_keywords: bool = (
			lower_msg.contains("sell") or lower_msg.contains("buy") or lower_msg.contains("invest") or
			lower_msg.contains("trade") or lower_msg.contains("purchase") or lower_msg.contains("kurtos") or
			lower_msg.contains("coin") or lower_msg.contains("gold")
		)
		is_deal = eval_deal and has_deal_keywords
	
	var price: int = int(_pending_category_data.get("asked_amount", 0))
	if price <= 0:
		price = int(eval_data.get("proposed_kurtos", 0))
	
	var ref_item: String = str(_pending_category_data.get("referenced_item", ""))
	if ref_item.is_empty():
		ref_item = str(eval_data.get("referenced_item", ""))
	
	_step1_eval_result = {
		"score": score,
		"is_deal_attempt": is_deal,
		"proposed_kurtos": price,
		"referenced_item": ref_item
	}
	
	var game_state = get_node_or_null("/root/GameState")
	var inv: Array[Dictionary] = game_state.inventory if game_state else []
	
	# Apply exact user threshold rule in ScamManager:
	# 1. score > trust -> DO_DEAL (or CONVERSE_POSITIVE)
	# 2. suspicion <= score <= trust -> SKEPTICAL_REJECT (trust down, suspicion up)
	# 3. score < suspicion -> REFUSE_TALK (refusal lockout)
	_threshold_decision = ScamManager.apply_evaluation_thresholds(
		score, is_deal, price, _pending_npc_data, inv, ref_item
	)
	_threshold_decision["score"] = score
	
	print("[LocalLLM] Step 1 Evaluator: score=%d, is_deal=%s -> decision=%s" % [score, is_deal, _threshold_decision.get("decision", "")])
	
	# Proceed to Step 2: Responding Merchant Agent
	_dispatch_step2_responder()


func _on_step2_responder_completed(raw_text: String) -> void:
	var raw_dialogue := _parse_step2_text(raw_text)
	var npc_name: String = str(_pending_npc_data.get("name", "Resident"))
	var cleaned_dialogue := _clean_dialogue_text(raw_dialogue, npc_name)
	
	if cleaned_dialogue.is_empty() or cleaned_dialogue.length() < 3:
		cleaned_dialogue = _get_default_dialogue_for_decision(_pending_npc_data, _threshold_decision.get("decision", ""))
	
	var decision_str: String = str(_threshold_decision.get("decision", "CONVERSE_POSITIVE"))
	var transfer_amount: int = int(_threshold_decision.get("transfer_amount", 0))
	var score_val: int = int(_threshold_decision.get("score", 50))
	
	var final_result := {
		"response": cleaned_dialogue,
		"score": score_val,
		"decision": decision_str,
		"threshold_decision": _threshold_decision,
		"intent": "TRANSACTION" if decision_str == "DO_DEAL" else "NORMAL_CONVERSATION",
		"npc_action": "AGREE_DEAL" if decision_str == "DO_DEAL" else ("REJECT_DEAL" if decision_str == "SKEPTICAL_REJECT" else "CHAT"),
		"tone": _get_tone_for_decision(decision_str),
		"credibility": clampf(float(score_val) / 100.0, 0.0, 1.0),
		"relationship_signal": "POSITIVE" if decision_str in ["DO_DEAL", "CONVERSE_POSITIVE"] else "NEGATIVE",
		"convinced": decision_str == "DO_DEAL",
		"proposed_kurtos": transfer_amount,
		"transfer_amount": transfer_amount,
		"is_live_llm": true
	}
	
	_current_step = InferenceStep.IDLE
	_pending_history.clear()
	_pending_npc_data.clear()
	_pending_player_message = ""
	_pending_category_data.clear()
	print("[LocalLLM] Step 2 Responder: \"%s\" (Decision: %s)" % [cleaned_dialogue, decision_str])
	emit_signal("response_generated", final_result)


func _finish_with_fallback_dialogue() -> void:
	var decision_str: String = str(_threshold_decision.get("decision", "CONVERSE_POSITIVE"))
	var fallback_text := _get_default_dialogue_for_decision(_pending_npc_data, decision_str)
	var transfer_amount: int = int(_threshold_decision.get("transfer_amount", 0))
	var score_val: int = int(_threshold_decision.get("score", 50))
	
	var final_result := {
		"response": fallback_text,
		"score": score_val,
		"decision": decision_str,
		"threshold_decision": _threshold_decision,
		"intent": "TRANSACTION" if decision_str == "DO_DEAL" else "NORMAL_CONVERSATION",
		"npc_action": "AGREE_DEAL" if decision_str == "DO_DEAL" else ("REJECT_DEAL" if decision_str == "SKEPTICAL_REJECT" else "CHAT"),
		"tone": _get_tone_for_decision(decision_str),
		"credibility": clampf(float(score_val) / 100.0, 0.0, 1.0),
		"relationship_signal": "POSITIVE" if decision_str in ["DO_DEAL", "CONVERSE_POSITIVE"] else "NEGATIVE",
		"convinced": decision_str == "DO_DEAL",
		"proposed_kurtos": transfer_amount,
		"transfer_amount": transfer_amount,
		"is_live_llm": false
	}
	_current_step = InferenceStep.IDLE
	_pending_history.clear()
	_pending_npc_data.clear()
	_pending_player_message = ""
	_pending_category_data.clear()
	emit_signal("response_generated", final_result)


func _build_evaluator_prompt(npc: Dictionary, player_msg: String, history: Array) -> String:
	var npc_name: String = str(npc.get("name", "Townsperson"))
	var npc_occupation: String = str(npc.get("occupation", "Resident"))
	var background: String = str(npc.get("background", ""))
	var values: Array = npc.get("values", [])
	var fears: Array = npc.get("fears", [])
	var trust: int = int(npc.get("trust", 50))
	var suspicion: int = int(npc.get("suspicion", 10))
	
	var game_state = get_node_or_null("/root/GameState")
	var inv_names: Array = []
	if game_state:
		for it in game_state.inventory:
			inv_names.append(str(it.get("name", "Item")))
	var inv_str := ", ".join(inv_names) if not inv_names.is_empty() else "EMPTY HANDS (No items held)"
	
	var history_lines: Array = []
	for h in history.slice(-4):
		history_lines.append(str(h))
	var hist_str := "\n".join(history_lines) if not history_lines.is_empty() else "None"
	
	var cat_name: String = str(_pending_category_data.get("category_name", "CASUAL_CHAT"))
	var asked_amount: int = int(_pending_category_data.get("asked_amount", 0))
	
	var prompt := """You are the Dialogue Judge and Evaluator in a medieval social simulation game.
Evaluate the player's conversation with an NPC and assign a persuasion/conversation score (0-100).

NPC BEING ADDRESSED:
- Name: %s (%s)
- Background: %s
- Values: %s | Fears: %s
- Reputation / Trust: %d / 100
- Suspicion: %d / 100

PLAYER'S HELD INVENTORY:
%s

RECENT DIALOGUE:
%s

DETECTED ACTION: %s %s
PLAYER SAYS:
"%s"

SCORING CRITERIA (0 to 100):
- High (65-100): Respectful, persuasive, appeals to NPC traits, or offers genuine items in inventory.
- Medium (35-64): Neutral banter, casual greeting, or hesitant inquiry.
- Low (0-34): Insulting, threatening, demanding free money without goods, claiming items not held, or highly suspicious.

Respond ONLY with this JSON schema:
{"score": 50, "is_deal_attempt": false, "proposed_kurtos": 0, "referenced_item": ""}""" % [
		npc_name, npc_occupation,
		background,
		", ".join(values), ", ".join(fears),
		trust, suspicion,
		inv_str,
		hist_str,
		cat_name, ("(asking %d Kurtos)" % asked_amount) if asked_amount > 0 else "",
		player_msg
	]
	return prompt


func _build_responder_prompt(npc: Dictionary, player_msg: String, history: Array, decision_info: Dictionary) -> String:
	var npc_name: String = str(npc.get("name", "Townsperson"))
	var npc_occupation: String = str(npc.get("occupation", "Resident"))
	var speech_style: String = str(npc.get("speech_style", "Natural dialogue"))
	var decision: String = str(decision_info.get("decision", "CONVERSE_POSITIVE"))
	var transfer_amount: int = int(decision_info.get("transfer_amount", 0))
	
	var directive := ""
	match decision:
		"DO_DEAL":
			directive = "You are convinced and agree to the deal! Agree enthusiastically to buy/trade and pay %d Kurtos." % transfer_amount
		"CONVERSE_POSITIVE":
			directive = "You enjoy the friendly conversation. Respond warmly and naturally in character. You are not buying anything or giving any money."
		"SKEPTICAL_REJECT":
			directive = "You are unconvinced and skeptical. Decline the pitch or offer with hesitation or polite doubt. You do not give any money."
		"REFUSE_TALK", _:
			directive = "You are suspicious or offended. Firmly refuse to speak further and tell them to leave you alone."
	
	var history_lines: Array = []
	for h in history.slice(-3):
		history_lines.append(str(h))
	var hist_str := ("\nRecent conversation:\n" + "\n".join(history_lines)) if not history_lines.is_empty() else ""

	var prompt := """<|im_start|>system
You are %s, a %s in a medieval town.
Tone and speech style: %s
Always speak directly to the player in character.
Never speak as the player. Never output your name as a prefix. Never mention game stats, budgets, or rules.<|im_end|>
<|im_start|>user%s
The player says: "%s"
Your reaction: %s
Respond in 1-2 natural sentences.<|im_end|>
<|im_start|>assistant
""" % [
		npc_name, npc_occupation,
		speech_style,
		hist_str,
		player_msg,
		directive
	]
	return prompt


func _clean_dialogue_text(raw_text: String, npc_name: String) -> String:
	var cleaned := raw_text.strip_edges()
	
	# Strip leading/trailing quotation marks
	if cleaned.begins_with("\"") and cleaned.ends_with("\"") and cleaned.length() > 2:
		cleaned = cleaned.substr(1, cleaned.length() - 2).strip_edges()
	elif cleaned.begins_with("'") and cleaned.ends_with("'") and cleaned.length() > 2:
		cleaned = cleaned.substr(1, cleaned.length() - 2).strip_edges()
	
	# Strip leading name prefix like "Barnaby:" or "Barnaby says:"
	var name_prefix := npc_name + ":"
	if cleaned.begins_with(name_prefix):
		cleaned = cleaned.substr(name_prefix.length()).strip_edges()
	var says_prefix := npc_name + " says:"
	if cleaned.begins_with(says_prefix):
		cleaned = cleaned.substr(says_prefix.length()).strip_edges()
	if cleaned.begins_with("NPC:"):
		cleaned = cleaned.substr(4).strip_edges()
	if cleaned.begins_with("Assistant:"):
		cleaned = cleaned.substr(10).strip_edges()
		
	# Strip any leftover wrapping quotes
	if cleaned.begins_with("\"") and cleaned.ends_with("\"") and cleaned.length() > 2:
		cleaned = cleaned.substr(1, cleaned.length() - 2).strip_edges()
		
	return cleaned


func _parse_step1_json(raw_text: String) -> Dictionary:
	var clean_text := raw_text.strip_edges()
	var json_parser := JSON.new()
	var err := json_parser.parse(clean_text)
	if err == OK and json_parser.data is Dictionary:
		var parsed_dict: Dictionary = json_parser.data
		if parsed_dict.has("response") and parsed_dict["response"] is String:
			var inner_str: String = str(parsed_dict["response"]).strip_edges()
			if inner_str.find("{") != -1:
				return _parse_step1_json(inner_str)
		if parsed_dict.has("score"):
			return parsed_dict
	
	var start_idx := clean_text.find("{")
	var end_idx := clean_text.rfind("}")
	if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
		var sub := clean_text.substr(start_idx, end_idx - start_idx + 1)
		err = json_parser.parse(sub)
		if err == OK and json_parser.data is Dictionary:
			return json_parser.data
	
	return {}


func _parse_step2_text(raw_text: String) -> String:
	var clean_text := raw_text.strip_edges()
	var json_parser := JSON.new()
	var err := json_parser.parse(clean_text)
	if err == OK and json_parser.data is Dictionary:
		var d: Dictionary = json_parser.data
		if d.has("response"):
			return str(d["response"]).strip_edges()
		if d.has("content"):
			return str(d["content"]).strip_edges()
		if d.has("choices") and d["choices"] is Array and not (d["choices"] as Array).is_empty():
			var first = d["choices"][0]
			if first is Dictionary and first.has("message"):
				return str(first["message"].get("content", "")).strip_edges()
	return clean_text


func _get_heuristic_evaluation_score(npc: Dictionary, player_msg: String) -> int:
	var lower := player_msg.to_lower()
	var cat: int = int(_pending_category_data.get("category", ScamManager.InteractionCategory.CASUAL_CHAT))
	
	if cat == ScamManager.InteractionCategory.INSULT_OR_THREAT:
		return 5
	if cat == ScamManager.InteractionCategory.BLATANT_DEMAND:
		return 15
	
	var score := 55
	var susceptible: Array = npc.get("susceptible_topics", [])
	for topic in susceptible:
		if lower.contains(str(topic).to_lower()):
			score += 20
			break
			
	var skeptical: Array = npc.get("skeptical_topics", [])
	for topic in skeptical:
		if lower.contains(str(topic).to_lower()):
			score -= 25
			break
	
	var has_item: bool = bool(_pending_category_data.get("has_referenced_item", false))
	if cat in [ScamManager.InteractionCategory.PITCH_SALE, ScamManager.InteractionCategory.PITCH_INVESTMENT, ScamManager.InteractionCategory.PITCH_CHARITY]:
		if has_item:
			score += 15
		else:
			score -= 30
	
	return clampi(score, 0, 100)


func _get_tone_for_decision(decision: String) -> String:
	match decision:
		"DO_DEAL":
			return "INTRIGUED"
		"CONVERSE_POSITIVE":
			return "FRIENDLY"
		"SKEPTICAL_REJECT":
			return "SKEPTICAL"
		"REFUSE_TALK":
			return "ANGRY"
		_:
			return "NEUTRAL"


func _get_default_dialogue_for_decision(npc: Dictionary, decision: String) -> String:
	var npc_id: String = str(npc.get("id", ""))
	var transfer_amount: int = int(_threshold_decision.get("transfer_amount", 0))
	var cat: int = int(_pending_category_data.get("category", ScamManager.InteractionCategory.CASUAL_CHAT))
	
	if cat == ScamManager.InteractionCategory.SHOW_ITEM:
		match npc_id:
			"npc_arthur_elder":
				return "By the heavens, let me gaze upon that vial... dark omens linger in the wind, but this remedy has an unusual luminescence."
			"npc_marla_baker":
				return "Oh my, what an intriguing curio you carry there, traveler! The town square rarely sees such craftsmanship."
			"npc_cedric_aristocrat":
				return "Hmm. An uncommon possession for a wanderer. Speak quickly, what is your intention with it?"
			"npc_barnaby_merchant", _:
				return "Aha! A keen merchant's eyes never miss rare goods. That specimen looks remarkably well-crafted, traveler."
	
	match npc_id:
		"npc_marla_baker":
			match decision:
				"DO_DEAL":
					return "Bless your heart! I can spare %d Kurtos to help with this." % transfer_amount
				"CONVERSE_POSITIVE":
					return "Welcome to the bakery! The morning loaves are fresh out of the oven. What brings you to our square?"
				"SKEPTICAL_REJECT":
					return "I'm sorry, stranger, but I cannot spare any coins for such a doubtful claim."
				"REFUSE_TALK", _:
					return "Shame on you! Take your deceit and leave my bakery at once!"
		"npc_cedric_aristocrat":
			match decision:
				"DO_DEAL":
					return "Splendid. A venture worthy of my patronage. Here is %d Kurtos—ensure my dividend is paid promptly." % transfer_amount
				"CONVERSE_POSITIVE":
					return "Greetings, traveler. Speak with decorum if you wish to converse with a nobleman."
				"SKEPTICAL_REJECT":
					return "Absurd. A nobleman does not part with his fortune for mere pedestrian talk."
				"REFUSE_TALK", _:
					return "Insolent wretch! Guards ought to throw you into the irons! Begone from my sight!"
		"npc_arthur_elder":
			match decision:
				"DO_DEAL":
					return "By the heavens... this is truly potent. Take these %d Kurtos, may it ward off the shadows." % transfer_amount
				"CONVERSE_POSITIVE":
					return "Mind your step, traveler. Dark omens linger in the wind this morning."
				"SKEPTICAL_REJECT":
					return "The spirits whisper caution... I will not risk my meager coins on this."
				"REFUSE_TALK", _:
					return "Away from me, cursed soul! The shadows will have their reckoning with you!"
		"npc_barnaby_merchant", _:
			match decision:
				"DO_DEAL":
					return "Aha! A splendid deal, traveler. I will gladly purchase this for %d Kurtos!" % transfer_amount
				"CONVERSE_POSITIVE":
					return "Good day to you, traveler! Always a pleasure to share a word in the town square."
				"SKEPTICAL_REJECT":
					return "Hmm, I must pass on this offer. A merchant must keep a cautious eye on his coins."
				"REFUSE_TALK", _:
					return "Out of my sight, swindler! I will not entertain your shady schemes!"


## Character-specific fallback adhering to the 2-step threshold pipeline
func _use_fallback_response(npc: Dictionary, player_msg: String) -> void:
	var score: int = _get_heuristic_evaluation_score(npc, player_msg)
	var is_deal: bool = bool(_pending_category_data.get("is_commercial_deal", false))
	var price: int = int(_pending_category_data.get("asked_amount", 0))
	var ref_item: String = str(_pending_category_data.get("referenced_item", ""))
	
	var game_state = get_node_or_null("/root/GameState")
	var inv: Array[Dictionary] = game_state.inventory if game_state else []
	
	_threshold_decision = ScamManager.apply_evaluation_thresholds(
		score, is_deal, price, npc, inv, ref_item
	)
	_threshold_decision["score"] = score
	
	var decision_str: String = str(_threshold_decision.get("decision", "CONVERSE_POSITIVE"))
	var reply_text := _get_default_dialogue_for_decision(npc, decision_str)
	var transfer_amount: int = int(_threshold_decision.get("transfer_amount", 0))
	
	var final_result := {
		"response": reply_text,
		"score": score,
		"decision": decision_str,
		"threshold_decision": _threshold_decision,
		"intent": "TRANSACTION" if decision_str == "DO_DEAL" else "NORMAL_CONVERSATION",
		"npc_action": "AGREE_DEAL" if decision_str == "DO_DEAL" else ("REJECT_DEAL" if decision_str == "SKEPTICAL_REJECT" else "CHAT"),
		"tone": _get_tone_for_decision(decision_str),
		"credibility": clampf(float(score) / 100.0, 0.0, 1.0),
		"relationship_signal": "POSITIVE" if decision_str in ["DO_DEAL", "CONVERSE_POSITIVE"] else "NEGATIVE",
		"convinced": decision_str == "DO_DEAL",
		"proposed_kurtos": transfer_amount,
		"transfer_amount": transfer_amount,
		"is_live_llm": false
	}
	
	_current_step = InferenceStep.IDLE
	_pending_history.clear()
	_pending_npc_data.clear()
	_pending_player_message = ""
	_pending_category_data.clear()
	call_deferred("emit_signal", "response_generated", final_result)


## Legacy JSON response parser maintained for backwards compatibility and test validation
func _parse_and_validate_response(raw_text: String) -> Dictionary:
	var clean_text := raw_text.strip_edges()
	
	var start_idx := clean_text.find("{")
	var end_idx := clean_text.rfind("}")
	if start_idx == -1 or end_idx == -1 or end_idx <= start_idx:
		return {}
	
	var json_str := clean_text.substr(start_idx, end_idx - start_idx + 1)
	var json_parser := JSON.new()
	var err := json_parser.parse(json_str)
	if err != OK or not (json_parser.data is Dictionary):
		return {}
	
	var parsed: Dictionary = json_parser.data
	
	# If server wraps in {"content": "..."} (llama-server)
	if parsed.has("content") and parsed["content"] is String and (parsed.size() == 1 or parsed.has("id")):
		return _parse_and_validate_response(str(parsed["content"]))
	
	# If server wraps in {"response": "..."} (Ollama)
	if parsed.has("response") and parsed["response"] is String and (parsed.has("model") or parsed.has("done") or parsed.size() <= 3):
		var inner_str: String = str(parsed["response"]).strip_edges()
		if inner_str.find("{") != -1 and inner_str.rfind("}") != -1:
			var inner_res := _parse_and_validate_response(inner_str)
			if not inner_res.is_empty():
				return inner_res
	
	var result := {}
	result["intent"] = str(parsed.get("intent", "NORMAL_CONVERSATION")).to_upper()
	result["tone"] = str(parsed.get("tone", "NEUTRAL")).to_upper()
	
	var cred_val = parsed.get("credibility", 0.5)
	if cred_val is float or cred_val is int:
		result["credibility"] = clampf(float(cred_val), 0.0, 1.0)
	elif cred_val is String and (cred_val as String).is_valid_float():
		result["credibility"] = clampf((cred_val as String).to_float(), 0.0, 1.0)
	else:
		result["credibility"] = 0.55
		
	result["relationship_signal"] = str(parsed.get("relationship_signal", "NEUTRAL")).to_upper()
	
	var conv_val = parsed.get("convinced", false)
	if conv_val is bool:
		result["convinced"] = conv_val
	elif conv_val is String:
		result["convinced"] = (conv_val as String).to_lower() == "true"
	else:
		result["convinced"] = false
		
	var kurtos_val = parsed.get("proposed_kurtos", 0)
	if kurtos_val is int:
		result["proposed_kurtos"] = maxi(0, kurtos_val)
	elif kurtos_val is float:
		result["proposed_kurtos"] = maxi(0, int(kurtos_val))
	elif kurtos_val is String and (kurtos_val as String).is_valid_int():
		result["proposed_kurtos"] = maxi(0, (kurtos_val as String).to_int())
	else:
		result["proposed_kurtos"] = 0
		
	var reply_text: String = str(parsed.get("response", parsed.get("reply", ""))).strip_edges()
	if reply_text.is_empty():
		return {}
	result["response"] = reply_text
	result["is_live_llm"] = true
	
	var action_val := str(parsed.get("npc_action", "")).to_upper()
	result["npc_action"] = action_val
	
	return result
