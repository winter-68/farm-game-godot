# T76: Art Import - NPCs

## Goal

Import final-style art for the two existing NPC slots.

## Source Images

- `961b8a44ebf2790e55918805aa90a306.png`: used for Villager A.
- `d50726ce37924010f4b6004d13299f24.png`: used for Villager B.

## Imported Assets

NPC walking/world sprites:

- `assets/sprites/characters/npcs/npc_villager_a_sprite.png`
- `assets/sprites/characters/npcs/npc_villager_b_sprite.png`

NPC dialogue portraits:

- `assets/sprites/portraits/npc_villager_a_portrait_neutral.png`
- `assets/sprites/portraits/npc_villager_b_portrait_neutral.png`

## Notes

- World sprites are `16x24` transparent PNG files.
- Portraits are `64x64` transparent PNG files.
- Existing NPC resource references were reused, so no gameplay or scene data changed.
- The remaining two NPC source sheets can be imported later after adding new NPCData resources and spawn entries.
