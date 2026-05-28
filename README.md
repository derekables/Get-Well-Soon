# Get Well Soon

**Get Well Soon** is a tiny Godot learning project: collect all 10 hearts, dodge the germs, and make it back to full health.

This repository is meant to be the source-of-truth copy that can move between Codex, GitHub, and the Godot Web Editor.

## Current starting build

- **Engine target:** Godot 4.x, GDScript, Compatibility renderer friendly.
- **Main scene:** `res://scenes/main.tscn`
- **Controls:** WASD or Arrow Keys to move, `R` to restart.
- **Goal:** collect every heart without touching the germs.
- **Learning focus:** scenes, nodes, scripts, collision areas, signals, labels, and simple game state.

## Project map

```text
project.godot          Godot project settings and input actions
icon.svg               Simple project icon
scenes/main.tscn       Main level and UI
scenes/player.tscn     Player scene
scenes/heart.tscn      Collectible heart scene
scenes/germ.tscn       Hazard scene
scripts/game.gd        Score, win state, restart, and signal wiring
scripts/player.gd      Player movement and play-area clamping
scripts/coin.gd        Heart pickup behavior
scripts/hazard.gd      Germ touch behavior
```

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

- Add a start screen with a **Play** button.
- Add simple moving germs.
- Add a timer.
- Add a health counter instead of instantly resetting to bed.
- Replace the shape art with sprites you draw yourself.
- Add sound effects for heart pickup and germ touch.
