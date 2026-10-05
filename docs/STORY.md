# Story Bible

## 1. Premise

The player is a poor adventurer with an enormous romantic ambition: they want to marry a princess.

The king refuses because the player has no money or standing.

Instead of accepting this, the player decides to become rich enough that the king has no choice but to take the proposal seriously.

The target is absurd:

> **1,000,000 Kurtos in 30 days.**

The player's chosen method is equally absurd:

> Sell stories, promises, fake opportunities, invented expertise, and increasingly elaborate schemes to the people of a nearby town.

The comedy comes from the mismatch between the player's grand romantic motivation and increasingly ridiculous behavior.

---

## 2. Tone

Target tone:

- comedic;
- mischievous;
- slightly absurd;
- character-driven;
- occasionally sincere;
- suitable for a stylized indie game.

Avoid making every character sound like the same comedian.

A sad widow, paranoid guard, rich merchant, enthusiastic farmer, and arrogant scholar should have noticeably different voices.

---

## 3. Main Character

The protagonist should be largely player-defined.

The game should establish a few facts:

- poor;
- ambitious;
- willing to bend the truth;
- deeply motivated by the princess;
- clever enough to improvise.

Do not over-write the protagonist's personality. The player's typed messages are their personality.

---

## 4. The Princess

The princess is the emotional reason for the journey.

She should not simply be a trophy.

Possible characterization:

- curious about ordinary life;
- skeptical of court politics;
- genuinely likes the protagonist;
- amused by the protagonist's confidence;
- potentially unaware of the extent of the scams.

Her relationship to the player can influence endings.

---

## 5. The King

The king is the final authority and the source of the initial challenge.

He should believe that wealth and social standing are evidence of responsibility, while the player may interpret his demand as a challenge to exploit.

The final meeting should evaluate more than the raw money total.

Potential king variables:

```text
money_brought
player_reputation
town_testimonies
major_deeds
scam_exposure
princess_affection
```

---

## 6. Town

The town should feel like a network of people rather than a list of isolated quests.

Potential districts:

- Town Square
- Market
- Residential Street
- Tavern
- Shrine / Chapel
- Wealthy District
- Poor District
- Docks / Warehouse
- Town Hall
- Forest Road

Each district should host different NPCs and opportunities.

---

## 7. NPC Story Philosophy

Each important NPC needs a life independent of the player.

An NPC should have:

```text
Who am I?
What do I want?
What do I fear?
What do I value?
Who do I know?
What do I own?
What do I believe?
What would make me trust a stranger?
What would make me suspicious?
What secret do I hide?
```

The LLM uses these facts to role-play.

It should never be allowed to invent core facts that contradict the data definition.

---

## 8. Sample NPC Concepts

These are examples, not mandatory final characters.

### Marla — The Baker

- modest wealth;
- warm and social;
- highly values family;
- trusts people who appear hungry or helpful;
- knows half the town through customers;
- could become an information hub.

Potential story:

The player earns her trust by helping with deliveries, then uses her recommendations to reach other NPCs.

---

### Alden — The Merchant

- wealthy;
- business-minded;
- confident;
- difficult to fool with basic sales pitches;
- vulnerable to opportunities that sound profitable;
- keeps records of transactions.

Potential story:

A small legitimate favor can lead to a much larger investment scam.

---

### Bronn — The Guard

- poor-to-moderate wealth;
- suspicious;
- duty-oriented;
- difficult to deceive;
- knows which town residents have recently complained about suspicious behavior.

Potential story:

The player may either manipulate him or genuinely earn his respect.

---

### Elira — The Widow

- moderate savings;
- lonely;
- empathetic;
- highly responsive to personal stories;
- possesses an item tied to her late husband.

Potential story:

The player's interactions here can become morally uncomfortable, which creates one of the game's opportunities for non-monetary character development.

---

### Pip — The Beggar

- almost no money;
- extremely observant;
- knows town rumors;
- can provide useful disguises or information;
- surprisingly difficult to fool.

Potential story:

Pip can become one of the player's best information sources despite being one of the least wealthy NPCs.

---

## 9. Story Progression Through Systems

The story should emerge through:

- NPC conversations;
- rumors;
- changing schedules;
- discoveries;
- items;
- relationships;
- house access;
- town reputation;
- repeated scams.

Avoid forcing a quest marker for every important discovery.

---

## 10. Secrets

Secrets should create leverage rather than act only as lore.

Examples:

- merchant secretly owes money;
- guard is afraid of losing his job;
- noble is hiding gambling debt;
- farmer believes their field is cursed;
- scholar is desperate to prove a theory;
- beggar knows an embarrassing secret about the mayor.

A secret can create several possible uses:

```text
discover → build trust → exploit → protect → trade → reveal
```

---

## 11. Final Act

At the end of Day 30, the player reaches the king.

The king asks where the money came from.

The game should be able to assemble evidence from the player's actions.

Examples:

- NPC complaints;
- NPC praise;
- suspicious transactions;
- legitimate favors;
- known scams;
- player reputation;
- whether any NPC would testify in their favor.

The final scene should feel like a consequence of the player's 30-day history rather than a generic cutscene.
