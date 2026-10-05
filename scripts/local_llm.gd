class_name LocalLLM
extends Node

## Local LLM Manager for NPC Dialogue.
## Supports local llama.cpp / HTTP inference servers with deterministic fallback.
## Adheres strictly to the Snake Oil Salesman AI specification in docs/NPC_AI.md.

signal response_generated(result: Dictionary)
signal response_error(error_message: String)

@export var server_url: String = "http://127.0.0.1:8080/completion"
@export var temperature: float = 0.7
@export var max_tokens: int = 120
@export var request_timeout_seconds: float = 6.0

var _http_request: HTTPRequest
var _pending_npc_data: Dictionary = {}
var _pending_player_message: String = ""


func _ready() -> void:
	_http_request = HTTPRequest.new()
	_http_request.timeout = request_timeout_seconds
	add_child(_http_request)
	_http_request.request_completed.connect(_on_http_request_completed)


## Builds compact prompt from NPC data and initiates asynchronous generation
func request_reply(npc_data: Dictionary, player_message: String, history: Array = []) -> void:
	_pending_npc_data = npc_data
	_pending_player_message = player_message
	
	var prompt := _build_prompt(npc_data, player_message, history)
	
	var body_dict := {
		"prompt": prompt,
		"temperature": temperature,
		"n_predict": max_tokens,
		"stop": ["\nPLAYER:", "\nNPC:", "</s>", "<|im_end|>"]
	}
	
	var json_payload := JSON.stringify(body_dict)
	var headers := ["Content-Type: application/json"]
	
	var err := _http_request.request(server_url, headers, HTTPClient.METHOD_POST, json_payload)
	if err != OK:
		# If local server is not running, degrade gracefully to intelligent fallback
		_use_fallback_response(npc_data, player_message)


func _on_http_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		# Fallback to deterministic dialogue if local LLM server is offline or fails
		_use_fallback_response(_pending_npc_data, _pending_player_message)
		return
	
	var response_text := body.get_string_from_utf8()
	var parsed_data := _parse_and_validate_response(response_text)
	
	if parsed_data.is_empty():
		_use_fallback_response(_pending_npc_data, _pending_player_message)
	else:
		emit_signal("response_generated", parsed_data)


func _build_prompt(npc: Dictionary, player_msg: String, history: Array) -> String:
	var npc_name: String = npc.get("name", "Townsperson")
	var npc_occupation: String = npc.get("occupation", "Resident")
	var personality: Dictionary = npc.get("personality", {})
	var values: Array = npc.get("values", [])
	var goals: Array = npc.get("goals", [])
	var fears: Array = npc.get("fears", [])
	var trust: int = npc.get("trust", 50)
	var suspicion: int = npc.get("suspicion", 10)
	
	var p_str := "trusting: %.2f, skeptical: %.2f, empathetic: %.2f, greedy: %.2f" % [
		personality.get("trusting", 0.5),
		personality.get("skeptical", 0.5),
		personality.get("empathetic", 0.5),
		personality.get("greedy", 0.5)
	]
	
	var prompt := """You are role-playing an NPC in a comedic medieval social simulation game called Snake Oil Salesman.
Stay in character. Return ONLY a single valid JSON object matching this schema:
{
  "intent": "NORMAL_CONVERSATION",
  "tone": "FRIENDLY",
  "credibility": 0.7,
  "relationship_signal": "POSITIVE",
  "response": "short reply in character"
}
Allowed intents: NORMAL_CONVERSATION, ASK_FOR_MONEY, ASK_FOR_ITEM, ASK_FOR_ACCESS, OFFER_ITEM, OFFER_SERVICE, MAKE_CLAIM, LIE.

NPC PROFILE:
NAME: %s
JOB: %s
PERSONALITY: %s
VALUES: %s
GOALS: %s
FEARS: %s
TRUST: %d / 100
SUSPICION: %d / 100

""" % [npc_name, npc_occupation, p_str, ", ".join(values), ", ".join(goals), ", ".join(fears), trust, suspicion]

	if not history.is_empty():
		prompt += "RECENT CONVERSATION:\n"
		for line in history.slice(-4):
			prompt += line + "\n"

	prompt += "\nPLAYER:\n\"%s\"\n\nRESPONSE (valid JSON only):\n" % player_msg
	return prompt


func _parse_and_validate_response(raw_text: String) -> Dictionary:
	# Strip markdown code blocks if wrapped by model
	var clean_text := raw_text.strip_edges()
	
	# If server wraps in {"content": "..."}
	var outer_json = JSON.parse_string(clean_text)
	if outer_json is Dictionary and outer_json.has("content"):
		clean_text = str(outer_json["content"]).strip_edges()
	
	var start_idx := clean_text.find("{")
	var end_idx := clean_text.rfind("}")
	if start_idx == -1 or end_idx == -1 or end_idx <= start_idx:
		return {}
	
	var json_str := clean_text.substr(start_idx, end_idx - start_idx + 1)
	var parsed = JSON.parse_string(json_str)
	if not (parsed is Dictionary):
		return {}
	
	# Validate and clamp fields
	var result := {}
	result["intent"] = str(parsed.get("intent", "NORMAL_CONVERSATION")).to_upper()
	result["tone"] = str(parsed.get("tone", "NEUTRAL")).to_upper()
	result["credibility"] = clampf(float(parsed.get("credibility", 0.5)), 0.0, 1.0)
	result["relationship_signal"] = str(parsed.get("relationship_signal", "NEUTRAL")).to_upper()
	
	var reply_text: String = str(parsed.get("response", parsed.get("reply", ""))).strip_edges()
	if reply_text.is_empty():
		return {}
	result["response"] = reply_text
	
	return result


## Intelligent, persona-driven fallback when local LLM server is offline (AGENTS.md Rule 11)
func _use_fallback_response(npc: Dictionary, player_msg: String) -> void:
	var npc_name: String = npc.get("name", "Merchant")
	var personality: Dictionary = npc.get("personality", {})
	var trust: int = npc.get("trust", 50)
	var suspicion: int = npc.get("suspicion", 10)
	
	var is_trusting: bool = personality.get("trusting", 0.5) > 0.6
	var is_skeptical: bool = personality.get("skeptical", 0.5) > 0.5 or suspicion > 30
	var is_greedy: bool = personality.get("greedy", 0.5) > 0.5
	
	var lower_msg := player_msg.to_lower()
	var intent := "NORMAL_CONVERSATION"
	var tone := "NEUTRAL"
	var rel_signal := "NEUTRAL"
	var credibility := 0.6
	var reply := ""
	
	# Determine logical intent & reply based on message keywords and NPC persona
	if lower_msg.contains("money") or lower_msg.contains("kurtos") or lower_msg.contains("coin") or lower_msg.contains("gold") or lower_msg.contains("lend") or lower_msg.contains("borrow"):
		intent = "ASK_FOR_MONEY"
		if is_skeptical or trust < 40:
			tone = "DEFENSIVE"
			rel_signal = "NEGATIVE"
			credibility = 0.3
			reply = "Money? I work hard for my Kurtos, stranger. I'm not handing out coins to someone I barely know."
		elif is_trusting and trust >= 60:
			tone = "EMPATHETIC"
			rel_signal = "POSITIVE"
			credibility = 0.8
			reply = "Times are tough, I know. I might be able to spare a few Kurtos if you help me out in return."
		else:
			tone = "CAUTIOUS"
			credibility = 0.5
			reply = "Every Kurto counts in this town. You'll need to convince me you're good for it first."

	elif lower_msg.contains("oil") or lower_msg.contains("tonic") or lower_msg.contains("cure") or lower_msg.contains("elixir") or lower_msg.contains("potion") or lower_msg.contains("miracle"):
		intent = "MAKE_CLAIM"
		if is_skeptical:
			tone = "DOUBTFUL"
			rel_signal = "NEGATIVE"
			credibility = 0.25
			reply = "Miracle cures? Sounds like snake oil to me. What are you really selling?"
		elif is_greedy:
			tone = "INTRIGUED"
			rel_signal = "POSITIVE"
			credibility = 0.7
			reply = "A tonic with those kinds of profits? Tell me more... but don't try swindling me."
		else:
			tone = "CURIOUS"
			credibility = 0.55
			reply = "An exotic remedy, you say? I've heard strange tales, but I'd need proof before believing that."

	elif lower_msg.contains("treasury") or lower_msg.contains("vault") or lower_msg.contains("restricted") or lower_msg.contains("guard") or lower_msg.contains("key") or lower_msg.contains("door"):
		intent = "ASK_FOR_ACCESS"
		tone = "NERVOUS"
		rel_signal = "NEGATIVE"
		credibility = 0.4
		reply = "Keep your voice down! The Royal Treasury is strictly guarded. You shouldn't even be asking about that."

	elif lower_msg.contains("hello") or lower_msg.contains("hi") or lower_msg.contains("hey") or lower_msg.contains("greetings") or lower_msg.contains("good day"):
		intent = "NORMAL_CONVERSATION"
		tone = "FRIENDLY"
		rel_signal = "POSITIVE"
		credibility = 0.75
		reply = "Good day to you, traveler! Welcome to my shop. Looking for honest trade or just passing through?"

	elif lower_msg.contains("princess") or lower_msg.contains("king") or lower_msg.contains("marry") or lower_msg.contains("rich"):
		intent = "NORMAL_CONVERSATION"
		tone = "AMUSED"
		credibility = 0.65
		reply = "Marrying the Princess? Ha! You and half the realm! You'll need a million Kurtos before the King even glances your way."

	elif lower_msg.contains("help") or lower_msg.contains("work") or lower_msg.contains("job"):
		intent = "OFFER_SERVICE"
		tone = "INTERESTED"
		rel_signal = "POSITIVE"
		credibility = 0.7
		reply = "Looking for work? Keep your eyes and ears open in town. Folks always have problems that need... creative solutions."

	else:
		intent = "NORMAL_CONVERSATION"
		if is_trusting:
			tone = "WARM"
			rel_signal = "POSITIVE"
			credibility = 0.65
			reply = "Interesting thought. Living in this town taught me there's always an angle to every story."
		else:
			tone = "NEUTRAL"
			credibility = 0.5
			reply = "I hear you, stranger. But around here, words are cheap and Kurtos don't grow on trees."

	var result := {
		"intent": intent,
		"tone": tone,
		"credibility": credibility,
		"relationship_signal": rel_signal,
		"response": reply
	}
	
	# Defer emission so callers can connect cleanly
	call_deferred("emit_signal", "response_generated", result)
