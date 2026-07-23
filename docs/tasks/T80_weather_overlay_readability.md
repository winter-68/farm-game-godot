# T80: Weather Overlay Readability

## Goal

Fix the weather overlay making player and NPC sprites look transparent after the fullscreen readability pass.

## Changes

- Reduce rain, snow, and cloudy tint opacity so character sprites remain visually solid.
- Keep weather particles visible but less opaque.
- Update rain and snow particle emission width for the `640x360` viewport.

## Acceptance

- During rain/snow/cloudy weather, the player no longer looks transparent.
- Weather still reads on screen through particles and the daily weather notice.
- Main scene loads without errors.
