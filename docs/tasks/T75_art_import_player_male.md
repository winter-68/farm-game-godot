# T75: Art Import - Default Player

## Goal

Import the first final-style default player sprite set.

## Source Image

- `bada37c4c2ff8b3b51acb38897bca34d.png`: male player character sheet.

## Imported Assets

Default player stand frames:

- `assets/sprites/characters/player/player_stand_down.png`
- `assets/sprites/characters/player/player_stand_up.png`
- `assets/sprites/characters/player/player_stand_left.png`
- `assets/sprites/characters/player/player_stand_right.png`

Default player walk frames:

- `assets/sprites/characters/player/player_walk_down_0.png`
- `assets/sprites/characters/player/player_walk_down_1.png`
- `assets/sprites/characters/player/player_walk_up_0.png`
- `assets/sprites/characters/player/player_walk_up_1.png`
- `assets/sprites/characters/player/player_walk_left_0.png`
- `assets/sprites/characters/player/player_walk_left_1.png`
- `assets/sprites/characters/player/player_walk_right_0.png`
- `assets/sprites/characters/player/player_walk_right_1.png`

## Notes

- All imported runtime assets are `16x24` transparent PNG files.
- Existing `resources/player_art_default.tres` references were reused.
- This task imports one default player only. A future character select task should add a second `PlayerArtData` resource for the female player and save the selected art id in new-game/load flow.
