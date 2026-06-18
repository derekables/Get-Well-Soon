# Get Well Soon

**Get Well Soon** is a narrative-driven street survival RPG prototype with roguelike pressure. The player is not trying to “beat addiction” in a single moralized arc; they are trying to survive another day while hunger, sleep, addiction, trauma, luck, crime, kindness, relationships, money, reputation, hope, and identity all push against each other.

This repository is the source-of-truth copy that can move between Codex, GitHub, and the Godot Web Editor.

## North-star vision

> Create a game where surviving one more day is meaningful, every choice leaves a scar, every person has a story, and even failure becomes part of the legend.

The long-term target is closer to a mix of:

- **Fallout 1/2 moral ambiguity** where choices have consequences without a sermon.
- **Earthbound visual clarity** with readable, stylized spaces and characters.
- **Roguelike replayability** through randomized starts, encounters, city states, and legacies.
- **The Sims-style needs** where physical and psychological meters shape decisions.
- **Project Zomboid-style long-term consequences** where the world keeps changing whether the player is ready or not.

Recovery should be one possible path among many. A player might become a recovering addict, career criminal, community leader, musician, entrepreneur, activist, mentor, con artist, survivor, legend, or a forgotten name in the city’s memory.

## Design principles

1. **Every system matters.** Hunger, thirst, sleep, hygiene, warmth, safety, belonging, purpose, self-worth, hope, money, reputation, addiction, and relationships should all matter without any one mechanic dominating the whole game.
2. **Failure creates stories.** Arrest, relapse, injury, homelessness, betrayal, and loss should open new branches where possible instead of acting only as hard fail states.
3. **No moral judgement.** The game should not lecture. It should model consequences and let players decide what those consequences mean.
4. **The world does not wait.** Every day should be able to change businesses, NPC availability, crime pressure, economic conditions, seasonal events, and opportunity.
5. **Identity is earned.** The game should quietly track repeated behavior — helping, lying, creating art, using violence, building relationships, taking responsibility, avoiding responsibility — so NPCs and endings respond to who the player has become.

## Current playable prototype

- **Engine target:** Godot 4.x, GDScript, Compatibility renderer friendly.
- **Main scene:** `res://scenes/main.tscn`
- **Controls:** WASD or Arrow Keys to move, `Space`/`J` to interact or attack, `Shift`/`K` to dash, `R` to restart.
- **World scale:** the old single-screen arena has been expanded into a larger scrollable city block with a camera following the player.
- **Core loop:** use each day to scavenge enough Fet-D, food, weapons, gear, and flexible supplies to qualify for the next night, then survive until dawn.
- **Day/night progression:** every new day raises the next night’s requirements and every new night increases pressure zones, enemy counts, and danger scaling.
- **Prototype systems:** health, stamina, grit, hunger, thirst, sleep, hygiene, warmth, safety, belonging, purpose, self-worth, visible hope trend, hidden hope, hidden identity, reputation tracks, background/traits, day/night timers, survival inventory, supply requirements, enemy health bars, random item generation, psychosis, withdrawal, insomnia, and temporary weapon buffs.
- **Narrative seeds:** blue story nodes can be interacted with to produce small choices that affect resources, needs, reputation, hidden hope, and hidden identity.

## Project map

```text
project.godot              Godot project settings and input actions
icon.svg                   Simple project icon
scenes/main.tscn           Large scrollable city block, UI, procedural setup, containers
scenes/player.tscn         Player scene with melee/interact area and Camera2D
scenes/enemy.tscn          Wave enemy scene with health bar
scenes/item_pickup.tscn    Random pickup scene
scenes/supply_cache.tscn   Supply cache collectible scene
scenes/pressure_zone.tscn  Contact pressure-zone scene
scripts/game.gd            World loop, waves, items, story nodes, needs, identity, UI
scripts/player.gd          Movement, attacks, dash, health, stamina, grit, statuses
scripts/enemy.gd           Enemy chase/attack/take-hit behavior
scripts/item_pickup.gd     Item pickup configuration and pickup signal
scripts/supply_cache.gd    Supply cache pickup behavior
scripts/pressure_zone.gd   Pressure-zone touch behavior
```

## Systems now represented in code

### Attributes, background, and traits

Each run rolls a starting background and three traits. These currently affect starting health, stamina, grit, survival inventory, hidden hope, reputation, and daily need drift. The present data is intentionally lightweight so it can be expanded later into character creation.

### Needs

The prototype tracks physical and psychological needs:

- Physical: hunger, thirst, sleep, hygiene, warmth, safety.
- Psychological: belonging, purpose, self-worth.
- Hope: tracked as a hidden value but summarized in the UI as a trend.

Needs decay over time, and low needs can damage health, stamina, grit, hope, and status effects. Food, gear, coffee, supplies, caches, and story choices can push needs back up.

### Reputation and identity

Separate reputation tracks now exist for street, criminal, recovery, employment, and community standing. Hidden identity tracks record repeated behavior: helping strangers, lying, creating art, using violence, building relationships, taking responsibility, avoiding responsibility, sharing resources, chasing resources, changing factions, surviving alone, surviving days, and keeping purpose alive.

### Story nodes

The first interactive story nodes are in place as simple blue markers. They are not final quest content; they prove the loop for environmental narrative choices that can alter resources, needs, reputation, hope, and identity. The game now derives hidden identity titles such as The Shepherd, The Provider, The Dreamer, The Wolf, The Ghost, The Hustler, The Chameleon, and The Survivor from repeated behavior; the UI only exposes this as a rumor once the city starts recognizing a pattern.

## Near-term roadmap

- Replace prototype polygons and markers with sprites, animations, portraits, and more readable environmental art.
- Split background, trait, item, need, reputation, and story-node definitions into data resources once the lists grow.
- Add explicit choice UI so story nodes can present multiple options instead of one default interaction.
- Add NPC memory records for promises, betrayals, gifts, favors, conversations, rumors, and behavior-derived identity titles.
- Add shelters, clinics, local businesses, recovery meetings, criminal contacts, and street-family hubs.
- Turn hard failure states into story branches such as jail, hospital, shelter intake, debt, or rescue.
- Add legacy persistence so future characters can encounter consequences of previous runs.

## How to open this in the Godot Web Editor

1. Go to <https://editor.godotengine.org/>.
2. Choose **Import** or **Open Project**.
3. Upload a ZIP of this repository, or upload the project folder if your browser allows it.
4. Open `project.godot`.
5. Press the **Play** button to run the main scene.

## How we should sync changes

Because the Web Editor stores files inside the browser, treat GitHub/this repo as the permanent save.

### From Codex/GitHub to the Web Editor

1. Download this repository as a ZIP from GitHub.
2. Open the ZIP/project in the Godot Web Editor.
3. Make your experiment in Godot.

### From the Web Editor back to this repo

1. In Godot Web Editor, use **Project → Tools → Download Project Source**.
2. Save the ZIP somewhere safe, such as Google Drive or a USB drive.
3. Upload or copy that ZIP into this repo workflow so Codex can inspect the changed files.
4. Tell Codex what you changed or what broke, then we can continue from there.
