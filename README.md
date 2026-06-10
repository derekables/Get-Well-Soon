# Get Well Soon

**Get Well Soon** is becoming a fast real-time Godot survival/fighting prototype about making it through a rough street-level night while managing health, stamina, supplies, and unstable buffs/debuffs.

This repository is meant to be the source-of-truth copy that can move between Codex, GitHub, and the Godot Web Editor.

## Current prototype build

- **Engine target:** Godot 4.x, GDScript, Compatibility renderer friendly.
- **Main scene:** `res://scenes/main.tscn`
- **Controls:** WASD or Arrow Keys to move, `Space`/`J` to attack, `Shift`/`K` to dash, `R` to restart.
- **Core loop:** collect supplies, fight wave-based street threats, grab random items, and survive risky status effects.
- **Combat feel:** fast melee hitboxes, short attack cooldowns, stamina pressure, dash invulnerability, knockback, and escalating waves.
- **Prototype systems:** health, stamina, grit, supplies, enemy health bars, random item generation, psychosis, withdrawal, insomnia, and temporary weapon buffs.

## Project map

```text
project.godot              Godot project settings and input actions
icon.svg                   Simple project icon
scenes/main.tscn           Main arena, UI, supply pickups, hazards, enemy/item containers
scenes/player.tscn         Player scene with melee attack area
scenes/enemy.tscn          Wave enemy scene with health bar
scenes/item_pickup.tscn    Random pickup scene
scenes/heart.tscn          Supply collectible scene
scenes/germ.tscn           Contact hazard scene
scripts/game.gd            Combat loop, waves, item generation, UI, restart, signal wiring
scripts/player.gd          Movement, attacks, dash, health, stamina, grit, statuses
scripts/enemy.gd           Enemy chase/attack/take-hit behavior
scripts/item_pickup.gd     Item pickup configuration and pickup signal
scripts/coin.gd            Supply pickup behavior
scripts/hazard.gd          Hazard touch behavior
```

## Combat/status notes for customization

- **Grit** rises when fighting and collecting supplies; it increases attack damage over time.
- **Stamina** fuels attacks and dashes. Insomnia boosts regen/speed; withdrawal slows regen and causes damage ticks.
- **Psychosis** currently makes movement less stable, raises incoming damage, and adds offensive damage.
- **Random items** are defined in `scripts/game.gd` in `ITEM_TABLE`, then spawned as `scenes/item_pickup.tscn` instances.
- **Enemy scaling** happens in `scripts/enemy.gd::setup()`, which increases health, speed, damage, and reward by wave.

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

## Good next learning tasks

- Tune attack range, cooldown, dash cost, and enemy speed until the fight feels right.
- Replace placeholder polygons with sprites and animations.
- Split item/status definitions into data resources once the list grows.
- Add ranged enemies, blocking, heavy attacks, and item inventory choices.
- Add sound effects and camera shake for hit confirmation.
