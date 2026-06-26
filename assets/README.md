# Get Well Soon - Graphics Assets

This directory contains all visual assets for the game, organized by category.

## Directory Structure

```
assets/
├── sprites/           # Character and entity sprites (isometric/Earthbound style)
├── portraits/         # NPC character portraits with emotion variants
├── ui/               # UI icons, buttons, and HUD elements
├── tileset/          # World tileset and landmark visuals
└── generated/        # Placeholder procedurally-generated or simple graphics
```

## Asset Guidelines

### Sprites
- **Style**: Earthbound-inspired isometric perspective (slight z-axis shift for depth)
- **Resolution**: 64x64 or 96x96 pixels for main characters
- **Palette**: Gritty, desaturated color palette reflecting urban/street life
- **No pixel art requirement**: Vector or painted styles acceptable

### Portraits
- **Resolution**: 256x256 or 320x240 pixels
- **Emotions**: neutral, happy, sad, angry, scared, embarrassed, tired, thinking
- **Detail Level**: Much higher detail than sprites to convey personality

### UI
- **Resolution**: 32x32 or 48x48 pixels
- **Items**: food, weapons, gear, fet-d, supplies, bandages
- **Status Effects**: psychosis, withdrawal, well, armed, insomnia, indications of needs

## Sprite Animation Guide

### Player
- Idle (4 frames)
- Walk (8 frames, 4 directions)
- Attack (6 frames)
- Dash (4 frames)
- Hit (2 frames)

### Enemies
- Idle (4 frames)
- Walk (8 frames)
- Attack (6 frames)
- Hit (2 frames)
- Death (4 frames)

### NPCs (for story interactions)
- Idle/stand (2 frames)
- Talk (4 frames)
- Emotion response (varies)

## Color Palette (Suggested)

**Primary (Urban Grit)**
- #2C1B1B (dark brown)
- #4A3E3E (warm brown)
- #7A6E6E (tan)

**Accents**
- #E84C3D (red - health/danger)
- #F4B942 (gold - items/rewards)
- #4ECDC4 (teal - energy/stamina)
- #95E1D3 (light teal - healing)

**Needs Indicators**
- Hunger: #D4A574
- Thirst: #3A9FD8
- Sleep: #5C4D8C
- Warmth: #E67E22
- Safety: #C0392B
- Belonging: #8E44AD
- Purpose: #2ECC71

## Current Status

All assets should be generated or created during initial development phase. This is a placeholder system to organize them.
