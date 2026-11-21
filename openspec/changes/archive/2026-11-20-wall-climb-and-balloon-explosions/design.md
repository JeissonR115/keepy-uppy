# Design

## Context

See `proposal.md` for motivation and the spec deltas for required behavior. The player controller updates facing from horizontal input before its climb-state handling; the normal movement branch also considers starting a climb before a buffered wall jump. The balloon currently uses a shared polygon tween for floor and spike impacts, but only the spike path hides the balloon. The supplied effect sheet is 768×1472 pixels, exactly 12×23 cells at 64×64.

## Goals / Non-Goals

**Goals:**

- Keep intentional wall jumps responsive at floor contact while preserving the no-automatic-rebound behavior for passive wall collision.
- Prevent input-driven facing changes during the climb state.
- Play one shared, one-shot balloon explosion while stopping and hiding the balloon itself.
- Reuse the supplied sheet without creating duplicate cropped images.

**Non-Goals:**

- Change scoring, serve, spike-penalty, or contact-priority rules.
- Change the wall-jump impulse, climb stamina, or wall-slide tuning.
- Add a new asset dependency or alter the source sprite sheet.

## Decisions

1. **Resolve explicit wall-jump input before entering a new climb.** Keep the existing buffered-jump and wall-direction mechanics, but ensure a requested wall jump wins over starting a climb when the player is grounded beside a wall. Passive contact remains non-bouncing. This preserves existing wall-jump tuning and avoids adding a separate grounded-jump path.
2. **Gate facing updates on the climb state.** Ignore horizontal facing changes while `movement_state` is `CLIMB`; retain the current horizontal-input behavior in other states so normal turning resumes after the player leaves the wall.
3. **Represent the explosion as a `SpriteFrames` animation backed by atlas regions.** Follow the existing animation-resource pattern and create nine `AtlasTexture` regions from the supplied image: row 1, 1-based columns 4–12, each 64×64. Use a non-looping animation at 12 frames per second, then hide it on completion. This keeps the original asset intact and makes the selected frames explicit.
4. **Use one impact-start path for floor and spike contacts.** Keep their existing distinct signals and scoring behavior, but route both through the same idempotent visual/physics shutdown: hide the balloon's `Visual`, stop its motion, disable collision and player contacts, and play the explosion child. Reset restores the balloon and stops/hides any prior animation. Keep the effect as a separate child so hiding the balloon visual does not hide the explosion.

## Risks / Trade-offs

- [The wall-jump path could still be masked by floor or climb-state transitions] → Add a focused grounded wall-jump regression test, alongside the existing passive wall-contact test.
- [A hidden balloon could continue moving or accept contacts during the animation] → Stop/freeze its motion and disable collision/contact handling in the shared impact path; verify round reset restores those states.
- [Atlas coordinates or frame order could be off by one] → Test the animation's nine frame textures and exact 64×64 regions against the specified row and columns.
- [The new animation lasts longer than the old polygon tween] → Let tests wait for animation completion rather than relying on the old fixed tween duration.

## Migration Plan

No data migration is needed. Replace the existing burst presentation in the balloon scene, preserve the current contact signals, and restore visual, collision, and animation state through the existing round-reset path. Reverting the change restores the prior polygon effect.
