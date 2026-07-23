# T73: Panel Input Lock

## Goal

When a main UI panel is open, the player should not walk, spend stamina, use tools, harvest, or eat items through the world controls.

## Scope

- `scripts/autoload/ui_state_manager.gd`
- `scripts/world/player.gd`

## Implementation

1. Add a small query helper to `UIStateManager` for checking whether a panel is active.
2. Make `player.gd` listen to `EventBus.ui_panel_changed`.
3. Keep dialogue/fishing locks separate from panel locks so one signal does not accidentally clear the other.
4. Reuse the existing lock path in `_physics_process()` and `_unhandled_input()`.

## Acceptance

- Opening inventory/shop/collection/cooking freezes player movement.
- While a panel is open, pressing tool/harvest/eat shortcuts has no world-side effect.
- Closing the panel restores player movement.
- Dialogue and fishing locks still work independently.
