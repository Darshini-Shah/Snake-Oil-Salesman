class_name ChatUI
extends Control

## In-game Chat interface for interacting with NPCs.
## Features a convenient top-of-screen input bar (mobile keyboard friendly),
## a proximity Chat button, an exit 'X' button, and integration with LocalLLM.

signal conversation_started(npc: Node2D)
signal conversation_ended(npc: Node2D)

@onready var chat_prompt_btn: Button = %ChatPromptBtn
@onready var top_bar: PanelContainer = %TopBar
@onready var target_label: Label = %TargetLabel
@onready var message_input: LineEdit = %MessageInput
@onready var send_btn: Button = %SendBtn
@onready var close_btn: Button = %CloseBtn
@onready var local_llm: Node = %LocalLLM

var active_npc: Node2D = null
var is_chatting: bool = false
var conversation_history: Array = []


func _ready() -> void:
	top_bar.visible = false
	chat_prompt_btn.visible = false
	
	chat_prompt_btn.pressed.connect(_on_chat_prompt_pressed)
	send_btn.pressed.connect(_on_send_pressed)
	close_btn.pressed.connect(_on_close_pressed)
	message_input.text_submitted.connect(_on_message_submitted)
	
	if local_llm:
		local_llm.connect("response_generated", Callable(self, "_on_llm_response_generated"))
		local_llm.connect("response_error", Callable(self, "_on_llm_response_error"))
	
	# Connect to all NPCs currently in scene
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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_chatting:
		end_conversation()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E and active_npc != null and not is_chatting:
			start_conversation(active_npc)


func _on_npc_range_entered(npc: Node2D) -> void:
	active_npc = npc
	if not is_chatting:
		var name_str: String = str(npc.get("npc_name")) if "npc_name" in npc else "Resident"
		chat_prompt_btn.text = "💬 Chat with %s" % name_str
		chat_prompt_btn.visible = true


func _on_npc_range_exited(npc: Node2D) -> void:
	if active_npc == npc:
		if is_chatting:
			end_conversation()
		active_npc = null
		chat_prompt_btn.visible = false


func _on_chat_prompt_pressed() -> void:
	if active_npc:
		start_conversation(active_npc)


func start_conversation(npc: Node2D) -> void:
	active_npc = npc
	is_chatting = true
	chat_prompt_btn.visible = false
	
	var name_str: String = str(npc.get("npc_name")) if "npc_name" in npc else "Resident"
	target_label.text = "💬 %s:" % name_str
	message_input.text = ""
	message_input.placeholder_text = "Say something to %s..." % name_str
	top_bar.visible = true
	message_input.grab_focus()
	
	# Initial greeting in speech bubble
	if npc.has_method("show_speech"):
		npc.show_speech("Hello! What brings you here today?", name_str)
	emit_signal("conversation_started", npc)


func end_conversation() -> void:
	is_chatting = false
	top_bar.visible = false
	message_input.release_focus()
	
	if active_npc:
		if active_npc.has_method("hide_speech"):
			active_npc.hide_speech()
		if active_npc.get("is_player_in_range"):
			chat_prompt_btn.visible = true
		emit_signal("conversation_ended", active_npc)


func _on_close_pressed() -> void:
	end_conversation()


func _on_message_submitted(_text: String) -> void:
	_on_send_pressed()


func _on_send_pressed() -> void:
	var text := message_input.text.strip_edges()
	if text.is_empty() or active_npc == null:
		return
	
	# Record to conversation history
	conversation_history.append("PLAYER: \"%s\"" % text)
	message_input.text = ""
	
	# Visual indication near NPC that model is thinking
	if active_npc.has_method("show_thinking"):
		active_npc.show_thinking()
	
	# Send prompt to LocalLLM
	var profile: Dictionary = active_npc.get_full_profile() if active_npc.has_method("get_full_profile") else {}
	if local_llm and local_llm.has_method("request_reply"):
		local_llm.request_reply(profile, text, conversation_history)


func _on_llm_response_generated(result: Dictionary) -> void:
	if active_npc == null:
		return
	
	var reply: String = str(result.get("response", "..."))
	var intent: String = str(result.get("intent", "NORMAL_CONVERSATION"))
	var credibility: float = float(result.get("credibility", 0.5))
	var signal_type: String = str(result.get("relationship_signal", "NEUTRAL"))
	
	var name_str: String = str(active_npc.get("npc_name")) if "npc_name" in active_npc else "Resident"
	
	# Show NPC's logical reply in the speech bubble near the NPC
	if active_npc.has_method("show_speech"):
		active_npc.show_speech(reply, name_str)
	conversation_history.append("NPC: \"%s\"" % reply)
	
	# Apply Godot-authoritative deterministic rule adjustments
	_apply_conversation_impact(intent, credibility, signal_type)
	
	# Refocus text input for seamless typing
	if is_chatting:
		message_input.grab_focus()


func _on_llm_response_error(err: String) -> void:
	if active_npc:
		var name_str: String = str(active_npc.get("npc_name")) if "npc_name" in active_npc else "Resident"
		if active_npc.has_method("show_speech"):
			active_npc.show_speech("...", name_str)
	print("[ChatUI] LLM Error: ", err)


## Deterministic social state update according to Godot authority boundary (AGENTS.md Rule 1 & 4)
func _apply_conversation_impact(intent: String, credibility: float, signal_type: String) -> void:
	if active_npc == null:
		return
	
	var trust_delta: int = 0
	var susp_delta: int = 0
	
	if signal_type == "POSITIVE":
		trust_delta += 2
	elif signal_type == "NEGATIVE":
		trust_delta -= 1
		susp_delta += 2
	
	if credibility < 0.4:
		susp_delta += 3
	elif credibility > 0.7:
		trust_delta += 1
	
	match intent:
		"ASK_FOR_MONEY":
			susp_delta += 2
		"MAKE_CLAIM":
			if credibility < 0.4:
				susp_delta += 5
		"LIE":
			susp_delta += 8
	
	var current_trust: int = int(active_npc.get("trust")) if "trust" in active_npc else 50
	var current_susp: int = int(active_npc.get("suspicion")) if "suspicion" in active_npc else 10
	
	active_npc.set("trust", clampi(current_trust + trust_delta, 0, 100))
	active_npc.set("suspicion", clampi(current_susp + susp_delta, 0, 100))
	
	var name_str: String = str(active_npc.get("npc_name")) if "npc_name" in active_npc else "Resident"
	print("[ChatUI] %s State updated -> Trust: %d (delta %d), Suspicion: %d (delta %d)" % [
		name_str, active_npc.get("trust"), trust_delta, active_npc.get("suspicion"), susp_delta
	])
