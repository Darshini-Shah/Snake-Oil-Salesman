# Development Roadmap

## Phase 0 — Foundation

Goal: get the base Godot project organized.

Tasks:

- player movement;
- basic top-down map;
- interaction detection;
- scene organization;
- game state singleton;
- day/time system stub;
- basic NPC scene.

Exit condition: player can walk around and interact with an NPC.

---

## Phase 1 — Deterministic Social Prototype

Before integrating an LLM, prove the game loop without AI.

Tasks:

- NPC definitions;
- trust;
- suspicion;
- daily spending cap;
- money transactions;
- inventory;
- basic canned dialogue;
- one scam;
- day rollover;
- save/load.

Exit condition: the game is mechanically fun with canned dialogue.

This phase prevents the project from hiding bad game design behind an LLM.

---

## Phase 2 — Local LLM Prototype

Goal: replace canned NPC dialogue with a small local model.

Tasks:

- abstract `LocalLLM` interface;
- desktop model loading;
- prompt builder;
- structured response parser;
- fallback response system;
- asynchronous inference;
- NPC conversation history;
- basic memory.

Exit condition: player can type arbitrary sentences and NPCs respond consistently.

---

## Phase 3 — AI/Game Integration

Tasks:

- intent classification;
- credibility scoring signal;
- trust updates;
- suspicion updates;
- memory creation;
- scam resolution;
- scam repeat detection;
- house-access resolution.

Exit condition: free-form conversation meaningfully changes gameplay.

---

## Phase 4 — Town Sandbox

Tasks:

- multiple NPCs;
- schedules;
- homes;
- market;
- town square;
- item acquisition;
- rumors;
- NPC relationships;
- town reputation.

Exit condition: player can pursue several different money-making strategies.

---

## Phase 5 — Narrative Layer

Tasks:

- princess storyline;
- king storyline;
- major NPC arcs;
- secret chains;
- multiple endings;
- final 30-day sequence.

Exit condition: the game has a complete beginning-to-end run.

---

## Phase 6 — Android

Tasks:

- native local LLM integration;
- model packaging;
- memory/RAM profiling;
- inference latency profiling;
- low-end fallback mode;
- touch UI refinement;
- save migration testing.

Exit condition: a complete run is playable offline on the target Android device class.

---

## Phase 7 — Polish

Tasks:

- UI animation;
- sound effects;
- music;
- portraits;
- environmental detail;
- onboarding;
- tutorialization;
- balancing;
- performance optimization.
