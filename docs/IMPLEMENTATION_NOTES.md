# Implementation Notes

This file is a scratch-to-implementation bridge for coding agents.

## Suggested First Classes

```text
scripts/game/game_state.gd
scripts/game/time_manager.gd
scripts/game/economy_manager.gd
scripts/game/inventory_manager.gd
scripts/npc/npc_controller.gd
scripts/npc/npc_social_state.gd
scripts/npc/npc_memory.gd
scripts/dialogue/dialogue_manager.gd
scripts/dialogue/conversation_resolver.gd
scripts/ai/local_llm.gd
scripts/ai/prompt_builder.gd
scripts/ai/llm_response_parser.gd
scripts/save/save_manager.gd
```

These are suggestions rather than strict filenames.

## First Vertical Slice

Implement exactly this before expanding scope:

```text
Town Square
   ↓
NPC: Marla
   ↓
Player types message
   ↓
LLM generates response
   ↓
Trust changes
   ↓
Player asks for 100 Kurtos
   ↓
Deterministic economy checks daily cap
   ↓
Money transferred
   ↓
Memory recorded
   ↓
Player can talk again
   ↓
Save and reload
```

This vertical slice validates almost the entire architecture.

## Development Toggle

Add a setting like:

```text
use_local_llm = true
```

and a development-only mode:

```text
use_mock_llm = true
```

The mock model should return deterministic canned JSON so tests do not depend on inference availability.

## Important Architectural Test

The following must be possible:

```text
mock LLM
   ↓
rest of game still works
```

and:

```text
real LLM
   ↓
rest of game uses the same response contract
```

That is the cleanest way to keep development fast.
