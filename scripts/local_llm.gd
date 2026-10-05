class_name LocalLLM
extends Node

## Local LLM Manager for NPC Dialogue with intelligent persona-driven fallback.
## Strictly adheres to AGENTS.md: LLM proposes conversational interpretation;
## Godot engine systems remain authoritative over game state and currency.

signal response_generated(result: Dictionary)
signal response_error(error_message: String)

@export var server_url: String = "http://127.0.0.1:8080/completion"
@export var temperature: float = 0.7
@export var max_tokens: int = 140
@export var request_timeout_seconds: float = 4.0

var _http_request: HTTPRequest
var _pending_npc_data: Dictionary = {}
var _pending_player_message: String = ""


func _ready() -> void:
	_http_request = HTTPRequest.new()
	_http_request.timeout = request_timeout_seconds
	add_child(_http_request)
	_http_request.request_completed.connect(_on_http_request_completed)


## Builds compact prompt and dispatches asynchronous generation
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
		# If HTTP client fails or server not running, use deterministic fallback
		_use_fallback_response(npc_data, player_message)


func _on_http_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
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
	var background: String = npc.get("background", "")
	var values: Array = npc.get("values", [])
	var fears: Array = npc.get("fears", [])
	var trust: int = int(npc.get("trust", 50))
	var suspicion: int = int(npc.get("suspicion", 10))
	var remaining_budget := EconomyManager.get_remaining_daily_budget(npc)
	
	var game_state = get_node_or_null("/root/GameState")
	var inv_names: Array = []
	if game_state:
		for it in game_state.inventory:
			inv_names.append(str(it.get("name", "Item")))
	var inv_str := ", ".join(inv_names) if not inv_names.is_empty() else "EMPTY HANDS (No items)"

	var prompt := """You are role-playing an NPC in a comedic medieval social simulation game called Snake Oil Salesman.
Stay in character. Output ONLY a valid JSON object matching this schema:
{
  "intent": "NORMAL_CONVERSATION", // or PITCH_SCAM, ASK_FOR_MONEY, MAKE_CLAIM, LIE, ASK_INFORMATION
  "tone": "FRIENDLY", // FRIENDLY, SKEPTICAL, EMPATHETIC, ANGRY, INTRIGUED
  "credibility": 0.7, // 0.0 to 1.0
  "relationship_signal": "POSITIVE", // POSITIVE, NEUTRAL, NEGATIVE
  "convinced": false, // true if persuaded to give Kurtos/help
  "proposed_kurtos": 0, // amount NPC is willing to part with
  "response": "1-2 sentences reply in character"
}

NPC PROFILE:
NAME: %s
OCCUPATION: %s
BACKGROUND: %s
VALUES: %s
FEARS: %s
TRUST: %d / 100
SUSPICION: %d / 100
DAILY_BUDGET_REMAINING: %d Kurtos

PLAYER HELD INVENTORY:
%s
(MANDATORY INVENTORY GATING RULES:
- If player pitches poverty / charity / sick child, check if they have 'Beggar's Robe'. If NOT, notice clean clothes, refuse them, convinced=false, proposed_kurtos=0!
- If player pitches nobility / royal favor / high society, check if they have 'Gentleman's Monocle'. If NOT, scoff at commoner attire, refuse them, convinced=false, proposed_kurtos=0!
- If player pitches designer fabric / tailoring, check if they have 'Vibrant Silk Swatch' (fabric_sample). If NOT, call out empty hands, refuse them, convinced=false, proposed_kurtos=0!
- If player pitches miracle cures / tonics / elixirs, check if they have 'Miracle Tonic Sample' (miracle_tonic_sample). If NOT, call out lack of vials, refuse them, convinced=false, proposed_kurtos=0!
)

""" % [npc_name, npc_occupation, background, ", ".join(values), ", ".join(fears), trust, suspicion, remaining_budget, inv_str]

	var memories: Array = npc.get("memories", [])
	if not memories.is_empty():
		prompt += "PAST MEMORIES:\n"
		for mem in memories.slice(-3):
			if mem is Dictionary:
				prompt += "- %s\n" % str(mem.get("text", ""))
			else:
				prompt += "- %s\n" % str(mem)

	if not history.is_empty():
		prompt += "\nRECENT CHAT:\n"
		for line in history.slice(-4):
			prompt += line + "\n"

	prompt += "\nPLAYER:\n\"%s\"\n\nRESPONSE (valid JSON only):\n" % player_msg
	return prompt


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
	# If server wraps in {"content": "..."}
	if parsed.has("content") and parsed.size() == 1:
		return _parse_and_validate_response(str(parsed["content"]))
	
	var result := {}
	result["intent"] = str(parsed.get("intent", "NORMAL_CONVERSATION")).to_upper()
	result["tone"] = str(parsed.get("tone", "NEUTRAL")).to_upper()
	result["credibility"] = clampf(float(parsed.get("credibility", 0.5)), 0.0, 1.0)
	result["relationship_signal"] = str(parsed.get("relationship_signal", "NEUTRAL")).to_upper()
	result["convinced"] = bool(parsed.get("convinced", false))
	result["proposed_kurtos"] = maxi(0, int(parsed.get("proposed_kurtos", 0)))
	
	var reply_text: String = str(parsed.get("response", parsed.get("reply", ""))).strip_edges()
	if reply_text.is_empty():
		return {}
	result["response"] = reply_text
	
	return result


## Intelligent, character-specific fallback dialogue adhering to individual NPC identities
func _use_fallback_response(npc: Dictionary, player_msg: String) -> void:
	var npc_id: String = str(npc.get("id", ""))
	var npc_name: String = str(npc.get("name", "Resident"))
	var trust: int = int(npc.get("trust", 50))
	var suspicion: int = int(npc.get("suspicion", 10))
	var remaining_budget: int = EconomyManager.get_remaining_daily_budget(npc)
	
	var susceptible: Array = npc.get("susceptible_topics", [])
	var skeptical: Array = npc.get("skeptical_topics", [])
	
	var lower_msg := player_msg.to_lower()
	var has_susceptible_hit := false
	for topic in susceptible:
		if lower_msg.contains(str(topic).to_lower()):
			has_susceptible_hit = true
			break
			
	var has_skeptical_hit := false
	for topic in skeptical:
		if lower_msg.contains(str(topic).to_lower()):
			has_skeptical_hit = true
			break
	
	var intent := "NORMAL_CONVERSATION"
	var tone := "NEUTRAL"
	var rel_signal := "NEUTRAL"
	var credibility := 0.55
	var convinced := false
	var proposed_kurtos := 0
	var reply := ""
	
	var game_state = get_node_or_null("/root/GameState")
	var has_beggars_robe: bool = game_state != null and game_state.has_item("beggars_robe")
	var has_monocle: bool = game_state != null and (game_state.has_item("monocle") or game_state.has_item("forged_patent"))
	var has_fabric: bool = game_state != null and game_state.has_item("fabric_sample")
	var has_tonic: bool = game_state != null and game_state.has_item("miracle_tonic_sample")
	
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
	
	if is_fabric_pitch or is_tonic_pitch or is_poverty_pitch or is_nobility_pitch or is_asking_money:
		intent = "PITCH_SCAM"
	
	# Character-specific personality and item evaluation
	match npc_id:
		"npc_marla_baker":
			if is_poverty_pitch:
				if has_beggars_robe:
					convinced = true
					proposed_kurtos = remaining_budget
					tone = "EMPATHETIC"
					credibility = 0.90
					rel_signal = "POSITIVE"
					reply = "Oh heavens! Look at your ragged robe and hollow cheeks... You and your poor family are in utter misery! Please, take these %d Kurtos from today's bread sales to buy medicine!" % proposed_kurtos
				else:
					convinced = false
					proposed_kurtos = 0
					tone = "SKEPTICAL"
					credibility = 0.20
					rel_signal = "NEGATIVE"
					reply = "You speak of starving children and bitter poverty, stranger... but look at your clothes! They are clean, well-tailored, and in fine repair. You don't have a single tattered stitch or beggar's robe on you! I reserve my hard-earned Kurtos for the truly destitute who wear rags."
			elif is_fabric_pitch:
				if has_fabric:
					convinced = true
					proposed_kurtos = remaining_budget
					tone = "INTRIGUED"
					credibility = 0.88
					rel_signal = "POSITIVE"
					reply = "My goodness, what a splendid cloth! The colors are truly lovely. I would gladly support your tailoring business with %d Kurtos!" % proposed_kurtos
				else:
					convinced = false
					proposed_kurtos = 0
					tone = "CONFUSED"
					credibility = 0.20
					rel_signal = "NEGATIVE"
					reply = "A design of the fabric? But dear... your hands are completely empty. You aren't holding any cloth at all! Are you feeling faint?"
			elif is_tonic_pitch:
				if has_tonic:
					convinced = true
					proposed_kurtos = int(remaining_budget * 0.5)
					tone = "FRIENDLY"
					credibility = 0.75
					rel_signal = "POSITIVE"
					reply = "A soothing herbal tonic? My sister has had a nagging cough... I suppose I can spare %d Kurtos for a bottle." % proposed_kurtos
				else:
					convinced = false
					proposed_kurtos = 0
					tone = "SKEPTICAL"
					credibility = 0.20
					rel_signal = "NEGATIVE"
					reply = "A miracle tonic? But you aren't carrying any vials or draughts, stranger."
			elif is_nobility_pitch:
				convinced = false
				proposed_kurtos = 0
				tone = "SKEPTICAL"
				credibility = 0.30
				rel_signal = "NEUTRAL"
				reply = "A royal enterprise? I am just a simple baker, traveler. Court affairs are far above my station."
			elif has_skeptical_hit:
				tone = "ANGRY"
				credibility = 0.15
				rel_signal = "NEGATIVE"
				reply = "Threats? Cruelty? You ought to be ashamed of yourself! Leave my bakery this instant!"
			elif is_asking_money:
				tone = "CAUTIOUS"
				credibility = 0.35
				rel_signal = "NEUTRAL"
				reply = "I give bread to the truly needy, stranger. I cannot simply hand coins to someone I do not know."
			else:
				tone = "FRIENDLY"
				rel_signal = "POSITIVE"
				reply = "Welcome to the bakery! The morning loaves are fresh out of the oven. What brings you to our square?"
		
		"npc_cedric_aristocrat":
			if is_nobility_pitch:
				if has_monocle:
					convinced = true
					proposed_kurtos = remaining_budget
					tone = "INTRIGUED"
					credibility = 0.88
					rel_signal = "POSITIVE"
					reply = "Ah, that gilded monocle... a gentleman of discerning pedigree! An exclusive royal venture indeed. Here is %d Kurtos—ensure my dividend is paid promptly." % proposed_kurtos
				else:
					convinced = false
					proposed_kurtos = 0
					tone = "ANGRY"
					credibility = 0.15
					rel_signal = "NEGATIVE"
					reply = "Royal investments? Aristocratic circles? Ha! Look at your pedestrian attire! You do not even possess a gentleman's monocle or crest. How dare an unadorned commoner speak to me of high society! Get out of my sight!"
			elif is_fabric_pitch:
				if has_fabric:
					convinced = true
					proposed_kurtos = remaining_budget
					tone = "INTRIGUED"
					credibility = 0.88
					rel_signal = "POSITIVE"
					reply = "Hmm... hand that swatch here. Indeed, that texture rivals the grand court modistes! Perhaps you truly were an apprentice of merit. I shall invest %d Kurtos into your enterprise." % remaining_budget
				else:
					convinced = false
					proposed_kurtos = 0
					tone = "ANGRY"
					credibility = 0.15
					rel_signal = "NEGATIVE"
					reply = "Look at its color? Are you mocking me, vagrant? You are waving your empty palms at me! A noble modiste carries genuine swatches, not invisible air! Get out of my sight!"
			elif is_poverty_pitch or has_skeptical_hit:
				convinced = false
				proposed_kurtos = 0
				tone = "ANGRY"
				credibility = 0.15
				rel_signal = "NEGATIVE"
				reply = "Ugh! A wretched beggar daring to solicit me? Don't breathe near my velvet cape, peasant!"
			elif is_tonic_pitch:
				convinced = false
				proposed_kurtos = 0
				tone = "SKEPTICAL"
				credibility = 0.20
				rel_signal = "NEGATIVE"
				reply = "Peasant superstitions and snake oil? Keep your foul concoctions far away from my presence!"
			elif is_asking_money:
				convinced = false
				proposed_kurtos = 0
				tone = "SKEPTICAL"
				credibility = 0.25
				rel_signal = "NEGATIVE"
				reply = "Kurtos? Do you take me for an alms-house? Unless you have royal patents or rare treasures, move along."
			else:
				tone = "SKEPTICAL"
				reply = "Yes? Be brief. A gentleman of my standing has pressing affairs with the King's ministers."

		"npc_barnaby_merchant":
			if is_fabric_pitch:
				if has_fabric:
					convinced = true
					proposed_kurtos = remaining_budget
					tone = "INTRIGUED"
					credibility = 0.88
					rel_signal = "POSITIVE"
					reply = "By the merchant ledger, let me feel that silk! That vibrant dye and delicate weave is magnificent! If this is the designer fabric your business produces, I'll gladly invest %d Kurtos into your venture!" % proposed_kurtos
				else:
					convinced = false
					proposed_kurtos = 0
					tone = "ANGRY"
					credibility = 0.15
					rel_signal = "NEGATIVE"
					reply = "Look at it? Look at what? Your hands are completely empty! You claim to show me noble designer fabric, but you're gesturing with thin air! What kind of amateur con is this? Come back when you actually have samples to show!"
			elif is_tonic_pitch:
				if has_tonic:
					convinced = true
					proposed_kurtos = remaining_budget
					tone = "INTRIGUED"
					credibility = 0.80
					rel_signal = "POSITIVE"
					reply = "A glowing amber elixir? Now that's an eye-catching novelty! I can turn a tidy margin retailing this to superstitious townsfolk. Here is %d Kurtos for the batch!" % proposed_kurtos
				else:
					convinced = false
					proposed_kurtos = 0
					tone = "SKEPTICAL"
					credibility = 0.20
					rel_signal = "NEGATIVE"
					reply = "You want me to invest in tonics you don't even have on hand? I don't buy unseen vapor, friend."
			elif is_nobility_pitch:
				if has_monocle:
					convinced = true
					proposed_kurtos = remaining_budget
					tone = "INTRIGUED"
					credibility = 0.80
					rel_signal = "POSITIVE"
					reply = "A gentleman of stature! If you have royal trading concessions, I would gladly partner with you for %d Kurtos." % proposed_kurtos
				else:
					convinced = false
					proposed_kurtos = 0
					tone = "SKEPTICAL"
					credibility = 0.25
					rel_signal = "NEGATIVE"
					reply = "You claim connections with royal modistes, yet you lack even a monocle or merchant charter. Sounds like hot air to me."
			elif is_poverty_pitch:
				convinced = false
				proposed_kurtos = 0
				tone = "CAUTIOUS"
				credibility = 0.30
				rel_signal = "NEUTRAL"
				reply = "Charity? This is a market stall, not a cathedral alms-box. Come back with goods to trade."
			elif has_skeptical_hit:
				tone = "ANGRY"
				credibility = 0.15
				rel_signal = "NEGATIVE"
				reply = "An audit? Taxes? I pay my royal dues fair and square! You don't look like any authorized bailiff to me!"
			elif is_asking_money:
				tone = "SKEPTICAL"
				credibility = 0.30
				reply = "Kurtos don't grow on trees in my stall, friend. Show me real merchandise or make a sound investment pitch."
			else:
				tone = "FRIENDLY"
				rel_signal = "POSITIVE"
				reply = "Good day, traveler! Barnaby's Curiosities has the finest oddities in the realm. Care to strike a bargain?"

		"npc_arthur_elder", _:
			if is_tonic_pitch:
				if has_tonic:
					convinced = true
					proposed_kurtos = remaining_budget
					tone = "INTRIGUED"
					credibility = 0.90
					rel_signal = "POSITIVE"
					reply = "By the ancient signs! Look at that glowing amber tonic... the vapors smell of sacred herbs! Take my %d Kurtos, give me the miraculous draught to ward off the midnight spirits!" % proposed_kurtos
				else:
					convinced = false
					proposed_kurtos = 0
					tone = "SKEPTICAL"
					credibility = 0.15
					rel_signal = "NEGATIVE"
					reply = "Take what? A miracle tonic? Your palms are bare! You carry no vial, no elixir! Don't mock the ancient omens with imaginary cures!"
			elif is_fabric_pitch:
				if has_fabric:
					convinced = true
					proposed_kurtos = remaining_budget
					tone = "INTRIGUED"
					credibility = 0.85
					rel_signal = "POSITIVE"
					reply = "Such rich purple hue... like the royal mantle of old. I can spare %d Kurtos to see fine robes crafted in our town." % proposed_kurtos
				else:
					convinced = false
					proposed_kurtos = 0
					tone = "SKEPTICAL"
					credibility = 0.20
					rel_signal = "NEGATIVE"
					reply = "Where is it? An invisible weave? Spirits protect me, unless that cloth is woven from ghostly spectres, your hands hold nothing but air!"
			elif is_poverty_pitch:
				if has_beggars_robe:
					convinced = true
					proposed_kurtos = remaining_budget
					tone = "EMPATHETIC"
					credibility = 0.85
					rel_signal = "POSITIVE"
					reply = "The suffering of the humble does not escape the spirits. Take these %d Kurtos, poor soul, and find shelter." % proposed_kurtos
				else:
					convinced = false
					proposed_kurtos = 0
					tone = "SKEPTICAL"
					credibility = 0.25
					rel_signal = "NEGATIVE"
					reply = "You claim to be destitute, but your boots are sound and your coat has no tears. The spirits abhor a false cry of suffering."
			elif is_nobility_pitch:
				convinced = false
				proposed_kurtos = 0
				tone = "CAUTIOUS"
				reply = "Nobles and kings... their gold cannot protect them from the raven's call or the midnight bell."
			elif has_skeptical_hit:
				tone = "SKEPTICAL"
				credibility = 0.20
				rel_signal = "NEGATIVE"
				reply = "Bah! A cold skeptic blind to the supernatural world. The spirits will have their vengeance on your arrogance!"
			elif is_asking_money:
				tone = "NERVOUS"
				credibility = 0.35
				reply = "Coins cannot buy peace from the spirits, and I need what little I have to buy salt and protective talismans."
			else:
				tone = "FRIENDLY"
				reply = "Mind your step, traveler. The ravens gathered on the church bell this morning... dark omens linger in the wind."

	var result := {
		"intent": intent,
		"tone": tone,
		"credibility": credibility,
		"relationship_signal": rel_signal,
		"convinced": convinced,
		"proposed_kurtos": proposed_kurtos,
		"response": reply
	}
	
	call_deferred("emit_signal", "response_generated", result)
