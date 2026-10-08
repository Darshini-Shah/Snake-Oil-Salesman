extends SceneTree

## Automated test for LocalLLM connection and live inference.

var llm: LocalLLM
var test_done: bool = false
var timeout_timer: float = 15.0

func _init() -> void:
	print("\n=======================================================")
	print("🧪 RUNNING LOCAL LLM INTEGRATION TEST")
	print("=======================================================\n")
	
	llm = LocalLLM.new()
	root.add_child(llm)
	llm.connection_status_changed.connect(_on_connection_status_changed)
	llm.response_generated.connect(_on_response_generated)
	llm.response_error.connect(_on_response_error)


func _process(delta: float) -> bool:
	timeout_timer -= delta
	if timeout_timer <= 0 and not test_done:
		print("❌ FAIL: LocalLLM test timed out after 15 seconds.")
		quit(1)
	return false


func _on_connection_status_changed(connected: bool, status_text: String) -> void:
	print("  📡 Connection status changed: connected=%s, status='%s'" % [connected, status_text])
	if connected:
		print("  ✅ PASS: LocalLLM connected successfully to %s" % llm.active_backend_name)
		print("  🚀 Testing live request_reply for Barnaby...")
		var profile = {
			"name": "Barnaby",
			"occupation": "Merchant",
			"personality": "Greedy merchant",
			"speech_style": "Friendly salesman",
			"kurtos": 500,
			"trust": 40,
			"suspicion": 15
		}
		var history = []
		llm.request_reply(profile, "Hello Barnaby, do you have any fine wine for sale?", history)
	else:
		print("  ⚠️ Warning: LLM reported offline status: %s" % status_text)


func _on_response_generated(result: Dictionary) -> void:
	test_done = true
	print("  📥 Response received from LLM:")
	print("     - response: \"%s\"" % result.get("response", ""))
	print("     - intent: %s" % result.get("intent", ""))
	print("     - credibility: %s" % result.get("credibility", 0))
	print("     - proposed_kurtos: %s" % result.get("proposed_kurtos", 0))
	
	if not result.has("response") or str(result.get("response", "")).is_empty():
		print("  ❌ FAIL: Response text was empty.")
		quit(1)
		return
	
	print("\n=======================================================")
	print("🏁 LOCAL LLM INTEGRATION TEST: ALL PASSED")
	print("=======================================================\n")
	quit(0)


func _on_response_error(err: String) -> void:
	test_done = true
	print("  ❌ FAIL: LLM returned error: %s" % err)
	quit(1)
