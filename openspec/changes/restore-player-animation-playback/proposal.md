# Proposal

## Why

The character animations appear frozen because the shared `Visual` AnimatedSprite2D has `speed_scale = 0.0` in `player_placeholder.tscn`. A frozen one-shot such as `flip` cannot reach `animation_finished`, leaving the presentation controller's one-shot gate active and preventing later movement clips from taking over. Restore normal frame playback and protect the animation state flow from this regression.

## What Changes

- Restore a nonzero playback scale for the shared player body sprite while preserving the imported `SpriteFrames` and their per-animation timing.
- Ensure movement-state changes and one-shot completion continue to select the appropriate body clip for P1 and P2, including after jump and climb entry.
- Add regression coverage that confirms body frames advance, one-shots complete, and subsequent idle/run/fall/dash clips can play.
- Preserve the current requested draw order: arena backgrounds at `-100`, hair at `8`, body at `10`, and action effects above the body.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `pixel-art-presentation`: player movement-state animations must advance through their frames and one-shot playback must return control to subsequent state clips.

## Impact

- `src/models/player/player_placeholder.tscn` and `src/models/player/player_presentation_controller.gd`.
- `tests/test_visual_feedback.gd` and `tests/test_visual_assets.gd`.
- `docs/modules/player.md` if playback configuration or one-shot behavior needs documentation.
- No changes to movement, frame resources, collision geometry, player tint, hair position, or requested render-layer values.
