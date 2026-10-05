# Game Design Document (GDD)

## 1. Game Overview

**Working title:** Snake Oil Salesman

**Genre:** 2D top-down social simulation / comedy / immersive-sim-lite

**Core hook:** Convince AI-driven NPCs to give you money, possessions, access, or favors.

**Primary input:** Free-form typed conversation.

**Primary goal:** Earn **1,000,000 Kurtos within 30 days**.

**Primary fantasy:** Be a clever con artist who reads people, improvises believable stories, discovers weaknesses, and turns small favors into elaborate scams.

---

## 2. Player Objective

The player begins poor and must accumulate enough money to satisfy the king's condition.

The intended objective is not merely to farm the richest NPC repeatedly. The player should learn:

- who is wealthy;
- who is trusting;
- who talks to whom;
- which NPCs have useful possessions;
- which scams require setup;
- which NPCs become suspicious quickly;
- which lies can be maintained across multiple conversations;
- when to stop exploiting a target.

---

## 3. Core Resources

### Kurtos

The primary currency.

Used for:

- tracking progress toward 1,000,000;
- potentially buying legitimate supplies/cover stories;
- interacting with some systems if later added.

### Time

The player has 30 days.

Time is limited and should matter.

Potential time units:

```text
Morning
Afternoon
Evening
Night
```

Exact minutes can be introduced later if needed.

### Trust

A social resource representing how positively an NPC currently views the player.

High trust should generally make requests and scams easier.

### Suspicion

Represents how much an NPC believes the player may be deceptive or dangerous.

Suspicion and trust should be related but not identical.

An NPC can:

- trust the player but still refuse a large request;
- distrust the player but be curious;
- like the player while recognizing that something is suspicious.

### Reputation

Optional town-level social stat.

It should represent how the broader town perceives the player.

A useful design is to keep three layers:

```text
Personal trust      = this NPC likes/trusts me
Suspicion            = this NPC thinks I may be dishonest
Town reputation      = what other people have heard about me
```

---

## 4. NPC Archetypes

NPCs should vary significantly.

Potential archetypes include:

| Archetype | Typical traits |
|---|---|
| Gullible Merchant | Friendly, optimistic, money-focused |
| Suspicious Guard | Hard to deceive, observant, rule-driven |
| Lonely Widow | Values companionship and empathy |
| Wealthy Noble | High spending limit, socially protected |
| Poor Beggar | Low spending limit, useful information/items |
| Superstitious Farmer | Vulnerable to omens and supernatural claims |
| Scholar | Harder to fool with factual claims, interested in clever arguments |
| Drunk Aristocrat | Rich but inconsistent |
| Kind Priest | Values honesty, but may possess useful moral leverage |
| Con Artist Rival | Recognizes common scams and can counter the player |

Archetypes are starting points, not rigid behaviors.

---

## 5. NPC Personalization

Every important NPC should have a unique combination of:

- background;
- occupation;
- financial status;
- personality traits;
- values;
- fears;
- desires;
- relationships;
- secrets;
- habits;
- possessions;
- daily schedule;
- scam resistance;
- current trust;
- current suspicion;
- memory of the player.

The same argument should therefore produce different outcomes for different NPCs.

---

## 6. Conversations

The player enters free-form text.

Example:

> "My brother is sick and the physician says we need medicine urgently."

The NPC responds based on their context.

The game should not require the player to phrase messages in predefined keywords.

However, the LLM should map natural language to structured intent internally.

### Suggested conversation pipeline

```text
Typed message
      ↓
Conversation history
      ↓
NPC context
      ↓
Small local LLM
      ↓
Intent + emotional interpretation + response draft
      ↓
Deterministic rules
      ↓
Trust/suspicion updates
      ↓
NPC response displayed
```

---

## 7. Trust System

Suggested baseline scale:

```text
0   = hostile / completely untrusted
25  = skeptical stranger
50  = neutral/acquainted
75  = trusted acquaintance
100 = extremely trusting
```

Do not make trust a simple universal gate.

A request should depend on multiple variables.

Example:

```text
request_score =
    trust
  + relationship_bonus
  + relevant_item_bonus
  + story_consistency_bonus
  - suspicion
  - request_size_penalty
  - personality_resistance
```

The exact formula is implementation-tunable.

---

## 8. Suspicion System

Suspicion should rise from:

- contradictory stories;
- aggressive requests;
- implausible claims;
- repeated scams;
- visible suspicious behavior;
- other NPC warnings;
- failed lies;
- exploiting the NPC too frequently.

Suspicion can fall through:

- time;
- honest interactions;
- beneficial favors;
- gifts;
- consistent behavior;
- third-party validation.

The player should not always know the exact suspicion value.

---

## 9. Daily Spending Cap

Every NPC has a maximum amount of money they can lose/give/spend through the player per day.

Example:

```text
wealth = 25,000 Kurtos
max_daily_spend = 1,500 Kurtos
spent_today = 1,200 Kurtos
remaining_today = 300 Kurtos
```

This prevents repeatedly draining a wealthy NPC in a single session.

The cap can depend on:

- wealth;
- occupation;
- personality;
- transaction type;
- whether money is considered a gift, purchase, loan, investment, donation, etc.

At day rollover:

```text
spent_today = 0
```

Persistent long-term wealth can still be tracked if desired.

---

## 10. Scam System

A scam is a deliberate gameplay action with:

- prerequisites;
- target requirements;
- possible approach vectors;
- expected reward;
- risk;
- failure consequences;
- possible follow-up paths.

Examples:

### Simple street scam

No special requirements.

Low reward, low setup cost.

### Fake medicine

Requires:

- believable cover story;
- medicinal-looking item;
- NPC who values health/safety;
- sufficient trust.

### House inspection scam

Requires convincing NPC to let the player inside.

May unlock:

- more valuable loot;
- private information;
- environmental interaction;
- special scam opportunities.

---

## 11. Entering NPC Houses

Houses are progression spaces rather than simple interiors.

The player may need to convince an NPC to:

- invite them in;
- ask them for help;
- inspect something;
- deliver an item;
- perform a service;
- perform a supposedly urgent task.

House entry should therefore be a social achievement.

Once inside, additional mechanics can become available:

- inspect objects;
- discover personal information;
- find valuables;
- manipulate the environment;
- stage a scam;
- meet another character;
- discover secrets.

---

## 12. Items

Items should primarily modify the social sandbox rather than act as traditional combat equipment.

Example items:

### Beggar's Robe

Potential effects:

- increases empathy from certain NPCs;
- lowers perceived wealth/status;
- enables specific conversation angles;
- makes some characters more willing to help.

### Monocle

Potential effects:

- increases perceived intelligence/status;
- gives access to scholar/noble conversation options;
- may make certain NPCs take claims more seriously.

Items should not grant unconditional bonuses.

A particular NPC may react negatively to an item.

---

## 13. Memory

NPC memory should contain only meaningful events.

Good memory:

> "On Day 3 the player claimed to be a physician. They asked me for 500 Kurtos."

Bad memory:

> "Player walked left."

Memory categories:

- first meeting;
- favors;
- lies;
- successful scams;
- failed scams;
- gifts;
- promises;
- insults;
- major purchases;
- house visits;
- important secrets.

Long-term memory should be summarized to prevent unbounded context growth.

---

## 14. Scam Repeat Protection

The same scam should become less effective after repeated use on the same NPC.

Possible mechanics:

```text
first attempt  → normal effectiveness
second attempt → suspicion increase
third attempt  → severe resistance
known scam     → counter-dialogue / automatic recognition
```

NPCs can also warn others, creating emergent town-wide consequences.

---

## 15. Failure States

Failure should not necessarily mean game over.

Possible consequences:

- loss of trust;
- increased suspicion;
- loss of access to house;
- NPC warns neighbors;
- loss of item;
- loss of opportunity;
- temporary town reputation hit;
- guard attention;
- target becomes unavailable for part of the day.

Hard failure can exist for major story arcs.

---

## 16. The 30-Day Structure

Suggested progression:

### Days 1–5

Teach exploration, free-form conversation, basic trust, and low-risk scams.

### Days 6–10

Introduce useful items and multi-step opportunities.

### Days 11–20

Introduce deeper NPC relationships, town reputation, house scams, and interconnected characters.

### Days 21–27

Raise stakes. NPCs may know of the player's behavior.

### Days 28–29

Endgame preparation.

### Day 30

Final king sequence.

---

## 17. Win/Loss Structure

### Primary success condition

Reach 1,000,000 Kurtos by the end of Day 30.

### Potential secondary conditions

- king recognizes the player as trustworthy;
- princess still wants the player;
- no severe town-wide alert;
- certain NPCs remain loyal;
- a particular secret has been uncovered;
- special item acquired;
- low suspicion/reputation condition.

These can determine the ending.

---

## 18. Endings

The game should support multiple endings.

Initial set:

### Ending A — The Successful Con

Player reaches the money goal and has fooled enough important people.

### Ending B — Rich but Exposed

Player reaches 1,000,000 Kurtos but the king knows the money came from scams.

### Ending C — Genuine Redemption

Player earns enough money but helped enough townspeople that the king judges them favorably.

### Ending D — Jail

Player is exposed and arrested.

### Ending E — Princess Rejects the Deal

The player gets the money but loses the princess for another reason.

### Ending F — Hidden Ending

A special chain of NPC interactions reveals a way to resolve the royal conflict without simply paying the king.

---

## 19. MVP Scope

The first playable prototype should contain:

- one small town map;
- 5–8 NPCs;
- 3–5 item types;
- basic movement;
- textbox input;
- local LLM conversation;
- trust and suspicion;
- daily money cap;
- one simple scam;
- one house-access sequence;
- day progression;
- save/load;
- a simple end-of-demo condition.

Do not build 100 NPCs before the core loop is fun.
