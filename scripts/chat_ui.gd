class_name ChatUI
extends Control

## In-game Chat interface for interacting with NPCs.
## Features bottom dialogue window with persistent conversation log,
## live social & wallet stats, scam pitching, and refusal checks.

signal conversation_started(npc: Node2D)
signal conversation_ended(npc: Node2D)

@onready var chat_prompt_btn: Button = %ChatPromptBtn
@onready var chat_window: PanelContainer = %ChatWindow
@onready var npc_avatar: ColorRect = %NPCAvatar
@onready var target_label: Label = %TargetLabel
@onready var npc_stats_label: Label = %NPCStatsLabel
@onready var dialogue_scroll: ScrollContainer = %DialogueScroll
@onready var dialogue_text: RichTextLabel = %DialogueText
@onready var message_input: LineEdit = %MessageInput
@onready var pitch_btn: Button = %PitchBtn
@onready var send_btn: Button = %SendBtn
@onready var close_btn: Button = %CloseBtn
@onready var local_llm: Node = %LocalLLM

var active_npc: Node2D = null
var is_chatting: bool = false
var conversation_history: Array = []
var _last_sent_text: String = ""


func _ready() -> void:
	chat_window.visible = false
	chat_prompt_btn.visible = false
	
	chat_prompt_btn.pressed.connect(_on_chat_prompt_pressed)
	send_btn.pressed.connect(_on_send_pressed)
	close_btn.pressed.connect(_on_close_pressed)
	pitch_btn.pressed.connect(_on_pitch_pressed)
	message_input.text_submitted.connect(_on_message_submitted)
	
	if local_llm:
		local_llm.connect("response_generated", Callable(self, "_on_llm_response_generated"))
		local_llm.connect("response_error", Callable(self, "_on_llm_response_error"))
	
	_connect_npc_signals()


func _connect_npc_signals() -> void:
	for node in get_tree().get_nodes_in_group("npcs"):
		_bind_npc(node)


func _bind_npc(npc: Node2D) -> void:
	if npc.has_signal("player_entered_interaction"):
		if not npc.is_connected("player_entered_interaction", Callable(self, "_on_npc_range_entered")):
			npc.connect("player_entered_interaction", Callable(self, "_on_npc_range_entered"))
	if npc.has_signal("player_exited_interaction"):
		if not npc.is_connected("player_exited_interaction", Callable(self, "_on_npc_range_exited")):
			npc.connect("player_exited_interaction", Callable(self, "_on_npc_range_exited"))
	if npc.has_signal("social_state_changed"):
		if not npc.is_connected("social_state_changed", Callable(self, "_on_npc_social_state_changed")):
			npc.connect("social_state_changed", Callable(self, "_on_npc_social_state_changed"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_chatting:
		end_conversation()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E and active_npc != null and not is_chatting:
			start_conversation(active_npc)


func _on_npc_range_entered(npc: Node2D) -> void:
	active_npc = npc
	if not is_chatting:
		_update_prompt_button()


func _on_npc_range_exited(npc: Node2D) -> void:
	if active_npc == npc:
		if is_chatting:
			end_conversation()
		active_npc = null
		chat_prompt_btn.visible = false


func _on_npc_social_state_changed(npc: Node2D) -> void:
	if active_npc == npc:
		if is_chatting:
			_update_header_stats()
		else:
			_update_prompt_button()


func _update_prompt_button() -> void:
	if active_npc == null:
		chat_prompt_btn.visible = false
		return
	
	var name_str: String = str(active_npc.get("npc_name")) if "npc_name" in active_npc else "Resident"
	var is_refusing: bool = bool(active_npc.get("is_refusing_to_talk")) if "is_refusing_to_talk" in active_npc else false
	
	if is_refusing:
		var timer_sec: int = int(ceil(float(active_npc.get("refusal_timer")))) if "refusal_timer" in active_npc else 0
		chat_prompt_btn.text = "🚫 %s refuses to talk (%ds)" % [name_str, timer_sec]
	else:
		chat_prompt_btn.text = "💬 Chat with %s" % name_str
	chat_prompt_btn.visible = true


func _on_chat_prompt_pressed() -> void:
	if active_npc:
		start_conversation(active_npc)


func start_conversation(npc: Node2D) -> void:
	active_npc = npc
	
	# Check refusal lock-out
	var is_refusing: bool = bool(npc.get("is_refusing_to_talk")) if "is_refusing_to_talk" in npc else false
	if is_refusing:
		var name_str: String = str(npc.get("npc_name")) if "npc_name" in npc else "Resident"
		if npc.has_method("show_speech"):
			npc.show_speech("I told you to leave me alone, swindler!", name_str)
		return
	
	is_chatting = true
	chat_prompt_btn.visible = false
	
	# Disable player movement during dialogue
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.can_player_move = false
	
	# Hide virtual joystick to avoid overlapping dialogue box
	for joy in get_tree().get_nodes_in_group("virtual_joystick"):
		if joy is CanvasItem:
			joy.visible = false
	
	var name_str: String = str(npc.get("npc_name")) if "npc_name" in npc else "Resident"
	var occ_str: String = str(npc.get("npc_title")) if "npc_title" in npc else "Townsperson"
	target_label.text = "💬 %s (%s)" % [name_str, occ_str]
	
	if npc_avatar and "npc_color" in npc:
		npc_avatar.color = npc.get("npc_color")
		
	_update_header_stats()
	
	# Determine initial in-character greeting
	var greeting := "Hello traveler. What can I do for you today?"
	var npc_id: String = ""
	if npc.has_method("get_full_profile"):
		npc_id = str(npc.get_full_profile().get("id", ""))
	
	match npc_id:
		"npc_marla_baker":
			greeting = "Welcome to the bakery! The morning loaves are fresh out of the oven. What brings you to our square?"
		"npc_cedric_aristocrat":
			greeting = "Yes? Be brief. A gentleman of my standing has pressing affairs."
		"npc_arthur_elder":
			greeting = "Mind your step, traveler. Dark omens linger in the wind today... what do you seek?"
		"npc_barnaby_merchant", _:
			greeting = "Good day, traveler! Barnaby's Curiosities has the finest oddities in the realm. Looking for a bargain?"
	
	# Clear dialogue log and show opening line in the chatbox
	dialogue_text.text = "[color=#f5d76e][b]%s[/b]:[/color] \"%s\"" % [name_str, greeting]
	
	message_input.text = ""
	message_input.placeholder_text = "Type your message or pitch a con to %s..." % name_str
	chat_window.visible = true
	message_input.grab_focus()
	
	if npc.has_method("show_speech"):
		npc.show_speech(greeting, name_str)
	emit_signal("conversation_started", npc)


func _update_header_stats() -> void:
	if active_npc == null:
		return
	var trust: int = int(active_npc.get("trust")) if "trust" in active_npc else 50
	var susp: int = int(active_npc.get("suspicion")) if "suspicion" in active_npc else 10
	var max_spend: int = int(active_npc.get("max_daily_spend")) if "max_daily_spend" in active_npc else 200
	var spent: int = int(active_npc.get("spent_today")) if "spent_today" in active_npc else 0
	var gold: int = int(active_npc.get("gold")) if "gold" in active_npc else 500
	var remaining := mini(maxi(0, max_spend - spent), gold)
	
	npc_stats_label.text = "Trust: %d%% | Suspicion: %d%% | Daily Budget: %d / %d Kurtos" % [
		trust, susp, remaining, max_spend
	]


func end_conversation() -> void:
	is_chatting = false
	chat_window.visible = false
	message_input.release_focus()
	
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.can_player_move = true
	
	# Restore virtual joystick
	for joy in get_tree().get_nodes_in_group("virtual_joystick"):
		if joy is CanvasItem:
			joy.visible = true
	
	if active_npc:
		if active_npc.has_method("hide_speech"):
			active_npc.hide_speech()
		if active_npc.get("is_player_in_range"):
			_update_prompt_button()
		emit_signal("conversation_ended", active_npc)


func _on_close_pressed() -> void:
	end_conversation()


func _on_message_submitted(_text: String) -> void:
	_on_send_pressed()


## Suggested pitch button tailored to the active NPC's identity & player items
func _on_pitch_pressed() -> void:
	if active_npc == null:
		return
	
	var npc_id: String = ""
	if active_npc.has_method("get_full_profile"):
		npc_id = str(active_npc.get_full_profile().get("id", ""))
	
	var suggested := ""
	match npc_id:
		"npc_marla_baker":
			suggested = "My family is stricken with terrible illness and fever! Could you spare some Kurtos for medicine?"
		"npc_arthur_elder":
			suggested = "I possess a miracle tonic sample to cure ancient curses and ward off midnight omens!"
		"npc_cedric_aristocrat":
			suggested = "Greetings, my Lord. I represent a prestigious royal investment society with exclusive privileges."
		"npc_barnaby_merchant", _:
			suggested = "I have an exclusive wholesale trade deal with double profit margins for your shop!"
	
	message_input.text = suggested
	message_input.grab_focus()


func _on_send_pressed() -> void:
	var text := message_input.text.strip_edges()
	if text.is_empty() or active_npc == null:
		return
	
	# Block message if NPC is refusing to talk
	if bool(active_npc.get("is_refusing_to_talk")):
		end_conversation()
		return
	
	_last_sent_text = text
	conversation_history.append("PLAYER: \"%s\"" % text)
	message_input.text = ""
	
	var name_str: String = str(active_npc.get("npc_name")) if "npc_name" in active_npc else "Resident"
	
	# Append player message into the visible chatbox log
	dialogue_text.text += "\n\n[color=#70c0ff][b]You:[/b][/color] \"%s\"" % text
	dialogue_text.text += "\n[color=#888888][i]%s is considering your words...[/i][/color]" % name_str
	_scroll_dialogue_to_bottom()
	
	if active_npc.has_method("show_thinking"):
		active_npc.show_thinking()
	
	var profile: Dictionary = active_npc.get_full_profile() if active_npc.has_method("get_full_profile") else {}
	if local_llm and local_llm.has_method("request_reply"):
		local_llm.request_reply(profile, text, conversation_history)


func _on_llm_response_generated(result: Dictionary) -> void:
	if active_npc == null:
		return
	
	# Execute deterministic scam resolution through ScamManager & EconomyManager FIRST
	var eval_res := _resolve_interaction(result)
	var transferred: int = int(eval_res.get("actual_transferred", 0))
	var outcome = eval_res.get("outcome")
	
	var reply: String = str(result.get("response", "..."))
	var proposed: int = int(result.get("proposed_kurtos", 0))
	
	# Synchronize dialogue text with the actual transferred money
	if proposed > 0 and transferred != proposed:
		if transferred > 0:
			reply = reply.replace("%d Kurtos" % proposed, "%d Kurtos" % transferred)
			reply = reply.replace(str(proposed) + " Kurtos", str(transferred) + " Kurtos")
		else:
			reply = "I cannot spare any Kurtos right now."
	
	var name_str: String = str(active_npc.get("npc_name")) if "npc_name" in active_npc else "Resident"
	
	# Strip temporary "is considering your words..." text
	var thinking_tag := "\n[color=#888888][i]%s is considering your words...[/i][/color]" % name_str
	dialogue_text.text = dialogue_text.text.replace(thinking_tag, "")
	
	# Display reply in the chatbox log
	dialogue_text.text += "\n\n[color=#f5d76e][b]%s:[/b][/color] \"%s\"" % [name_str, reply]
	
	if transferred > 0:
		dialogue_text.text += "\n[color=#55ff77]💰 Deal Concluded: Received +%d Kurtos![/color]" % transferred
	elif outcome == ScamManager.ScamOutcome.FAILED_EXPOSED:
		dialogue_text.text += "\n[color=#ff5555]⚠️ Bluff Caught: Suspicion escalated![/color]"
	
	_scroll_dialogue_to_bottom()
	
	# Also update world-space speech bubble if visible
	if active_npc.has_method("show_speech"):
		active_npc.show_speech(reply, name_str)
	conversation_history.append("NPC: \"%s\"" % reply)
	
	if is_chatting:
		_update_header_stats()
		message_input.grab_focus()


func _resolve_interaction(llm_result: Dictionary) -> Dictionary:
	if active_npc == null:
		return {}
	
	var game_state = get_node_or_null("/root/GameState")
	var inventory: Array[Dictionary] = game_state.inventory if game_state else []
	var overall_trust: int = game_state.overall_trust if game_state else 25
	
	var profile: Dictionary = active_npc.get_full_profile() if active_npc.has_method("get_full_profile") else {}
	var eval_res := ScamManager.evaluate_pitch(profile, _last_sent_text, llm_result, inventory, overall_trust)
	
	var transfer_amount: int = int(eval_res.get("transfer_amount", 0))
	var trust_delta: int = int(eval_res.get("trust_delta", 0))
	var susp_delta: int = int(eval_res.get("suspicion_delta", 0))
	var will_refuse: bool = bool(eval_res.get("will_refuse", false))
	var outcome = eval_res.get("outcome")
	
	# Update authoritative trust and suspicion
	var cur_trust: int = int(active_npc.get("trust")) if "trust" in active_npc else 50
	var cur_susp: int = int(active_npc.get("suspicion")) if "suspicion" in active_npc else 10
	active_npc.set("trust", clampi(cur_trust + trust_delta, 0, 100))
	active_npc.set("suspicion", clampi(cur_susp + susp_delta, 0, 100))
	
	var actual_transferred := 0
	# Money transfer execution
	if transfer_amount > 0:
		actual_transferred = EconomyManager.transfer_kurtos_from_npc(active_npc, transfer_amount, str(eval_res.get("reason", "Scam")))
		if actual_transferred > 0:
			if "successful_scam_count" in active_npc:
				active_npc.set("successful_scam_count", int(active_npc.get("successful_scam_count")) + 1)
			if active_npc.has_method("add_memory"):
				active_npc.add_memory("Gave player %d Kurtos after being convinced by pitch." % actual_transferred)
			if game_state and game_state.has_method("modify_overall_trust"):
				game_state.modify_overall_trust(+2)
	else:
		if outcome == ScamManager.ScamOutcome.FAILED_EXPOSED:
			if "failed_scam_count" in active_npc:
				active_npc.set("failed_scam_count", int(active_npc.get("failed_scam_count")) + 1)
			if active_npc.has_method("add_memory"):
				active_npc.add_memory("Caught player attempting deception.")
			if game_state and game_state.has_method("modify_overall_trust"):
				game_state.modify_overall_trust(-1)
	
	eval_res["actual_transferred"] = actual_transferred
	
	# Trigger refusal if suspicion reached lock-out threshold
	if will_refuse:
		if active_npc.has_method("trigger_refusal"):
			active_npc.trigger_refusal(35.0)
		end_conversation()
	
	return eval_res


func _scroll_dialogue_to_bottom() -> void:
	if dialogue_scroll:
		await get_tree().process_frame
		var v_bar := dialogue_scroll.get_v_scroll_bar()
		if v_bar:
			dialogue_scroll.scroll_vertical = int(v_bar.max_value)


func _on_llm_response_error(err: String) -> void:
	if active_npc:
		var name_str: String = str(active_npc.get("npc_name")) if "npc_name" in active_npc else "Resident"
		if active_npc.has_method("show_speech"):
			active_npc.show_speech("...", name_str)
	print("[ChatUI] LLM Error: ", err)
