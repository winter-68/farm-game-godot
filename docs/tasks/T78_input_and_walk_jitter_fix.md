# T78: Input And Walk Jitter Fix

## Goal

Fix regressions found after the visual readability pass.

## Issues

- Player walking frames looked like they were flickering.
- Inventory toggle stopped responding reliably.
- Debug sleep stopped responding reliably.

## Changes

- Re-cut player and NPC world frames using one consistent scale per character sheet.
- Keep all world character frames at `32x48` with a common bottom alignment.
- Move inventory, shop, collection, hotbar, and debug sleep shortcuts from `_unhandled_input` to `_input` so they respond before world/UI event handling can consume them.

## Acceptance

- Walking no longer flashes or changes apparent character size between frames.
- `Tab` opens and closes the inventory.
- `Enter` triggers debug sleep.
- Hotbar number keys still switch selected slots.
- Main scene loads without errors.
