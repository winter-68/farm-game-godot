# T77: Visual Readability Fix

## Goal

Improve the first art-import playtest feedback: small window, cramped HUD, blurry pixel art, and sliding NPC movement.

## Changes

- Start the game in fullscreen.
- Raise the internal viewport from `320x180` to `640x360`.
- Disable default canvas texture filtering for sharper pixel art.
- Move stamina and watering-can HUD panels away from the bottom hotbar.
- Re-export player and NPC world sprites at `32x48`.
- Keep sprite feet aligned with the original collision position by offsetting world sprites upward.
- Add optional 4-direction NPC standing and walking frame fields.
- Make `NPCController` animate NPC walking frames by movement direction.

## Acceptance

- Game starts fullscreen.
- Stamina and watering-can UI no longer overlaps the hotbar.
- Player and NPC sprites are clearer than the first imported `16x24` pass.
- NPCs visibly step through walking frames instead of sliding as a static sprite.
- Main scene loads without errors.
