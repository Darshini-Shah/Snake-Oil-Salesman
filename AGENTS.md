# AI Coding Agent Instructions

This repository is a Godot 4.x game called **Snake Oil Salesman**.

These instructions are intended for autonomous coding agents and should be treated as project-level constraints.

---

## 1. Understand the Authority Boundary

The most important architectural rule is:

> **Godot game systems are authoritative. The LLM is not.**

The LLM may:

- interpret player text;
- role-play an NPC;
- estimate conversational intent;
- propose changes to social variables;
- choose from a fixed list of conversational outcomes;
- generate short dialogue;
- surface relevant memories from supplied context.

The LLM must NOT directly:

- add or remove Kurtos;
- add/remove inventory items;
- teleport characters;
- unlock doors;
- skip time;
- mark a quest complete;
- change arbitrary NPC statistics;
- create money from nothing;
- create arbitrary items;
- execute GDScript;
- call engine APIs;
- directly edit files at runtime.

All actual effects must pass through deterministic Godot systems.

---

## 2. Never Trust Raw LLM Output

Treat model output as untrusted text.

Preferred response flow:

```text
LLM output
   ↓
JSON extraction
   ↓
Schema validation
   ↓
Enum validation
   ↓
Numeric clamping
   ↓
Rule validation
   ↓
Game-state mutation
```

Malformed, missing, or unsafe responses must degrade gracefully.

The game must remain playable if inference fails.

---

## 3. Keep AI Calls Small

The target deployment includes Android and potentially low-end hardware.

Use:

- short system prompts;
- compact NPC state summaries;
- small conversation windows;
- summarized long-term memories;
- structured output;
- short NPC replies.

Do not dump the entire save file or world state into an LLM prompt.

---

## 4. Prefer Deterministic Math for Game Mechanics

For values such as trust, suspicion, money, scam difficulty, and daily spending caps, use explicit formulas or rules in Godot.

Example:

```text
trust_delta = base_delta
             + personality_modifier
             + evidence_modifier
             + item_modifier
             - suspicion_penalty
```

Do not ask the LLM to invent the numeric result of a transaction.

The model may classify the conversational quality or intent; the game rules determine the exact numeric effect.

---

## 5. Source-of-Truth Files

Use these documents as the project specification:

- `README.md`
- `docs/GAME_DESIGN.md`
- `docs/STORY.md`
- `docs/NPC_AI.md`
- `docs/TECHNICAL_ARCHITECTURE.md`
- `docs/DATA_SCHEMAS.md`
- `docs/CONTENT_GUIDE.md`
- `docs/ROADMAP.md`
- `ai/LOCAL_MODEL_PLAN.md`

When implementing a feature, read the relevant document first.

If code conflicts with documentation, do not silently change the game design. Update the documentation and implementation together when the intended design has changed.

---

## 6. Code Organization

Avoid putting all gameplay logic inside `NPC.gd`.

Use focused systems such as:

```text
GameState
TimeManager
TownManager
NPCController
NPCSocialState
NPCMemory
DialogueManager
LocalLLM
PromptBuilder
LLMResponseParser
ScamManager
InventoryManager
EconomyManager
SaveManager
```

One class should have one clear responsibility.

---

## 7. Data-Driven Content

NPCs, items, scams, and locations should be data-driven wherever practical.

Do not hard-code every NPC's personality in GDScript.

Prefer Godot `Resource` classes or validated JSON data.

This allows AI coding agents and content creators to add content without touching core systems.

---

## 8. NPC State Must Be Persistable

A save file should preserve meaningful changes to NPCs.

At minimum, persist:

- trust;
- suspicion;
- relationship/familiarity;
- discovered player lies;
- scam history;
- major memories;
- daily spending used;
- important gifts/items exchanged;
- house access state where relevant;
- important story flags.

Do not persist temporary UI state such as current textbox animation progress.

---

## 9. Testing Requirements

When changing gameplay systems, add or update tests for deterministic logic.

At minimum test:

- trust changes;
- daily spending caps;
- scam eligibility;
- item effects;
- memory creation;
- memory persistence;
- malformed LLM responses;
- invalid action rejection;
- day rollover;
- 30-day end condition.

A game feature is not considered complete merely because it works visually.

---

## 10. Performance Requirements

Avoid inference from `_process()` or `_physics_process()`.

Inference should be event-driven:

```text
player_submits_message
        ↓
request_npc_response()
```

Use asynchronous/threaded inference where the selected local runtime supports it.

Never freeze the main game loop for an LLM generation.

---

## 11. Fallback Behavior

The game must remain functional without an AI model.

Recommended fallback:

```text
Local model unavailable
        ↓
Use deterministic canned response / fallback dialogue
        ↓
Keep normal gameplay systems active
```

This is particularly important for first launch, unsupported Android hardware, model loading failure, and development builds.

---

## 12. UI/UX Rules

Conversation UI should clearly show:

- NPC name;
- NPC portrait or visual identity;
- current conversation;
- player's typed message;
- NPC response;
- optional subtle trust/suspicion feedback where appropriate.

Do not expose internal AI JSON, raw prompts, or developer diagnostics in the normal player UI.

---

## 13. What Agents Should Avoid

Do not introduce:

- a cloud API dependency without explicit approval;
- a large model when a small model is sufficient;
- hidden global state;
- circular dependencies between core managers;
- direct singleton access everywhere;
- magic numbers without documentation;
- gameplay decisions based solely on LLM text;
- mechanics that cannot be saved and restored.

---

## 14. Before Opening a Pull Request / Completing a Task

Verify:

```text
[ ] Project opens without parser errors
[ ] No new hard-coded gameplay constants without explanation
[ ] LLM calls are asynchronous
[ ] LLM output is validated
[ ] Game state remains authoritative
[ ] New state is saveable when persistent
[ ] Feature has fallback behavior where appropriate
[ ] Relevant documentation is updated
[ ] Existing mechanics were not silently changed
```

---

## 15. Definition of Done

A feature is complete when:

1. it works in-game;
2. it survives at least one relevant edge case;
3. it follows the authority boundary;
4. it is compatible with offline/local inference assumptions;
5. it is documented enough for another agent to extend.
