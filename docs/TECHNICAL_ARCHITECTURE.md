# Technical Architecture

## 1. Engine

Target engine: **Godot 4.x**.

Target presentation: 2D top-down.

Target platforms:

- desktop for development;
- Android for deployment.

Offline/local AI is the preferred AI architecture.

---

## 2. High-Level Architecture

```text
                    ┌─────────────────────┐
                    │       Godot         │
                    │      Main Loop      │
                    └──────────┬──────────┘
                               │
            ┌──────────────────┼──────────────────┐
            │                  │                  │
            ▼                  ▼                  ▼
       World Systems       UI Systems       Game Systems
            │                  │                  │
            │                  ▼                  │
            │            Dialogue UI             │
            │                  │                  │
            └──────────┬───────┴─────────┬────────┘
                       ▼                 ▼
                 DialogueManager    NPCController
                       │                 │
                       ▼                 ▼
                  PromptBuilder    NPCSocialState
                       │                 │
                       ▼                 ▼
                    LocalLLM       NPCMemory
                       │
                       ▼
                Structured Response
                       │
                       ▼
                LLMResponseParser
                       │
                       ▼
                Gameplay Resolution
```

---

## 3. Core Managers

### GameState

Global run-level state.

Suggested responsibilities:

- current day;
- current time segment;
- player Kurtos;
- player reputation;
- story flags;
- run completion state.

### TimeManager

Responsible for:

- day progression;
- time-of-day changes;
- triggering daily resets;
- notifying NPC schedules.

### NPCManager

Responsible for:

- loading NPC definitions;
- finding NPCs by ID;
- maintaining active NPC instances;
- save/load of persistent NPC state.

### DialogueManager

Responsible for:

- starting conversations;
- maintaining current conversation context;
- sending player messages to the AI layer;
- forwarding validated responses to gameplay systems.

### LocalLLM

Responsible only for model lifecycle and inference.

It should expose a small interface such as:

```gdscript
func load_model(path: String) -> void
func is_ready() -> bool
func generate(prompt: String) -> String
func unload_model() -> void
```

The actual API depends on the chosen runtime/integration.

### PromptBuilder

Builds compact prompts from game state.

It should not perform gameplay mutation.

### LLMResponseParser

Converts raw model output into a validated internal object.

### ScamManager

Determines:

- which scam is being attempted;
- prerequisites;
- target eligibility;
- reward;
- consequences.

### EconomyManager

Authoritative owner of Kurtos transactions.

### InventoryManager

Authoritative owner of item acquisition and removal.

### MemoryManager / NPCMemory

Handles structured and narrative memories.

### SaveManager

Serializes player, NPC, day, inventory, and story state.

---

## 4. Scene Architecture

Possible layout:

```text
Main.tscn
├── World
│   ├── TileMap / TileMapLayer
│   ├── Buildings
│   ├── NPCs
│   └── Interactables
├── Player
├── UI
│   ├── HUD
│   ├── DialoguePanel
│   ├── InventoryPanel
│   └── DayPanel
└── Systems
    ├── GameState
    ├── TimeManager
    ├── DialogueManager
    └── LocalLLM
```

The final structure can differ, but gameplay managers should remain independent of UI nodes where possible.

---

## 5. Recommended Autoloads

Keep the number of global singletons small.

Reasonable candidates:

```text
GameState
SaveManager
TimeManager
NPCManager
DialogueManager
```

Do not make every helper an autoload.

---

## 6. Event-Driven Communication

Prefer signals/events for loosely coupled systems.

Example:

```gdscript
signal day_started(day: int)
signal day_ended(day: int)
signal conversation_started(npc_id: String)
signal conversation_finished(npc_id: String)
signal npc_state_changed(npc_id: String)
```

Avoid deeply nested manager-to-manager calls.

---

## 7. Conversation Lifecycle

```text
player interacts with NPC
        ↓
DialogueManager.start_conversation(npc)
        ↓
UI opens
        ↓
player types message
        ↓
DialogueManager.submit_message()
        ↓
PromptBuilder.build()
        ↓
LocalLLM.generate_async()
        ↓
LLMResponseParser.parse()
        ↓
GameplayResolver.resolve()
        ↓
NPC state changes
        ↓
MemoryManager records meaningful event
        ↓
NPC response shown
```

---

## 8. Gameplay Resolver

The resolver should bridge AI interpretation and game effects.

Example:

```gdscript
class_name ConversationResolver

func resolve(npc_state, llm_result, player_state) -> ConversationOutcome:
    var outcome := ConversationOutcome.new()

    outcome.intent = llm_result.intent
    outcome.trust_delta = TrustRules.calculate_delta(npc_state, llm_result)
    outcome.suspicion_delta = SuspicionRules.calculate_delta(npc_state, llm_result)

    return outcome
```

Do not put these rules in the model prompt as the only source of logic.

---

## 9. Resource/Data Architecture

For authored content, use data files that can be loaded independently from gameplay code.

Example categories:

```text
NPCDefinition
ItemDefinition
ScamDefinition
LocationDefinition
DialogueRuleDefinition
```

Godot `Resource` is a good default for editor-friendly data.

JSON can be useful for large datasets and external generation tools.

---

## 10. Android Considerations

The AI runtime should be isolated behind a single interface.

Recommended abstraction:

```text
LocalLLM interface
   ├── DesktopLLM implementation
   └── AndroidLLM implementation
```

The rest of the game should not know whether inference is running through CPU, GPU, or another native runtime.

This prevents platform-specific code from leaking into NPC logic.

---

## 11. Saving

Save at minimum:

```text
run seed
current day
current time
player position
player kurtos
player inventory
player reputation
NPC persistent states
NPC memories
story flags
major discovered secrets
ending-related flags
```

The local model file itself should not be copied into save data.

---

## 12. Seeded World Generation

Use a run seed if procedural generation is later introduced.

The initial MVP can use a fixed town layout.

The seed should affect only systems intentionally designed as procedural.

NPC identities and authored story facts should remain stable unless procedural variation is an explicit feature.

---

## 13. Debug Mode

Create a developer/debug overlay that can show:

```text
NPC ID
Trust
Suspicion
Relationship
Daily spend remaining
Last scam
Known lies
Memory count
Current schedule state
AI latency
Model status
```

This should be disabled or hidden in release builds.

---

## 14. Performance Targets

Initial target assumptions:

- 2D rendering should remain inexpensive;
- no continuous LLM generation;
- one active conversation model invocation at a time per player;
- small output lengths;
- asynchronous inference;
- model loaded once and reused for multiple NPCs where possible.

The same model should serve all NPCs. NPC identity exists in context/data, not as a separate model per character.
