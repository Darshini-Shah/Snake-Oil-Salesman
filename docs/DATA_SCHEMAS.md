# Data Schemas

These schemas are conceptual and should be adapted to Godot `Resource`, GDScript classes, or JSON as implementation proceeds.

## 1. NPC Definition

```json
{
  "id": "npc_marla_baker",
  "name": "Marla",
  "occupation": "baker",
  "wealth_class": "moderate",
  "personality": {
    "trusting": 0.72,
    "skeptical": 0.31,
    "empathetic": 0.89,
    "greedy": 0.25,
    "status_sensitive": 0.34,
    "superstitious": 0.61
  },
  "values": ["family", "kindness", "honesty"],
  "goals": ["keep the bakery profitable", "protect her children"],
  "fears": ["losing the bakery", "food shortages"],
  "background": "...",
  "possessions": ["bakery_key", "silver_necklace"],
  "max_daily_spend": 220,
  "daily_schedule": {
    "morning": "bakery",
    "afternoon": "market",
    "evening": "home",
    "night": "home"
  }
}
```

## 2. NPC Persistent State

```json
{
  "npc_id": "npc_marla_baker",
  "trust": 61,
  "suspicion": 14,
  "relationship": 33,
  "spent_today": 50,
  "house_access": false,
  "known_player_lies": ["claimed_to_know_a_physician"],
  "successful_scam_count": 0,
  "failed_scam_count": 1,
  "memories": [],
  "flags": {}
}
```

## 3. Memory

```json
{
  "id": "memory_001",
  "day": 4,
  "type": "PLAYER_LIE",
  "importance": 0.82,
  "text": "The player claimed to know a famous physician in the capital.",
  "tags": ["lie", "medicine", "player"]
}
```

## 4. Item

```json
{
  "id": "item_beggars_robe",
  "name": "Beggar's Robe",
  "description": "An old robe that makes the wearer look significantly poorer.",
  "effects": [
    {
      "condition": "npc.empathy > 0.6",
      "effect": "increase_empathy_response"
    }
  ]
}
```

The exact effect system should remain deterministic.

## 5. Scam

```json
{
  "id": "scam_fake_medicine",
  "name": "Fake Medicine",
  "risk": 0.55,
  "requirements": {
    "min_trust": 40,
    "required_items": ["medicine_bottle"]
  },
  "target_tags": ["empathetic", "health_anxious"],
  "reward": {
    "type": "money",
    "base_amount": 250
  },
  "failure": {
    "trust_delta": -10,
    "suspicion_delta": 15
  }
}
```

## 6. Conversation Result

```json
{
  "intent": "ASK_FOR_MONEY",
  "tone": "DESPERATE",
  "credibility": 0.68,
  "memory_worthy": true,
  "relationship_signal": "POSITIVE",
  "response": "I suppose I can spare a little."
}
```

## 7. Daily State

```json
{
  "day": 12,
  "period": "afternoon",
  "player_kurtos": 183450,
  "player_reputation": 42,
  "world_flags": {},
  "active_events": []
}
```

## 8. Schema Principles

1. IDs must be stable across save files.
2. Human-facing names can change without breaking save data.
3. Runtime state must not be mixed with immutable definition data.
4. Numeric game state should be validated and clamped.
5. LLM output is never directly written into persistent state without validation.
