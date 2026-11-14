# Design

## Context

See `proposal.md` for the motivation and `specs/pixel-art-presentation/spec.md` for observable requirements.

The reference is branch `main-4.x` of `Eneskp3441/Godot-Celeste-Movement-Demo`, configured for Godot 4.1. Its `Hair.gd` is a position-history trail, not a gravity or Verlet simulation: the scene sets `Length = 6`, the script uses `max_width = 2`, samples the parent character's global position while rounded velocity is nonzero, limits the history to `Length`, and constrains adjacent points per axis. When movement stops, `fakeHairCount` adds up to six points offset opposite `characterDirection` and downward by the count. The hair script itself does not apply gravity or collision.

The reference `Player.tscn` binds that script to a `Hair` node with a 24×24 `SubViewport` (`Length * 4`), a textured six-pixel `Line2D` with a width curve, a 9×9 `hair.png` base and `Hairpivot`, then presents the viewport through a `Sprite2D` using `Hair/Outline.gdshader`. The line texture is `haipixelr.png`. The player's `AnimationPlayer` keys the pivot across idle, climb, edge, fall, flip, jump and run animations; `Hair.gd` mirrors keyed X values when `onTurned` fires and reapplies facing when an animation begins. `Player.gd` colors the hair default `#ad4045`, dash blue `#51b5ff`, flashes white on landing for 0.1 seconds, and interpolates color toward its target by 0.2 per frame.

This project is Godot 4.7 and uses `CharacterBody2D`, shared `PlayerController`, `AnimatedSprite2D`/`SpriteFrames`, and profiles for both players. It has no body `AnimationPlayer`; the current `PlayerHair` scene is dynamically attached through `PlayerPresentationController`. The adaptation must preserve the existing body sprites, controller authority, collision nodes, and dash afterimage/rescue component. The reference repository has no root license file in the inspected archive; its README says the Celeste assets belong to EXOK and are used with permission, which does not document this project's redistribution rights.

## Goals / Non-Goals

**Goals:**

- Port the reference hair trail mechanics and composition to the current player scale and scene ownership.
- Keep hair processing modular and cosmetic for both P1 and P2.
- Preserve animation-specific hair pivoting, facing mirroring, and dash/landing color transitions without replacing body `SpriteFrames` or adding a second body-animation authority.
- Include the two reference textures only if applicable permission is verified and recorded.

**Non-Goals:**

- Replacing player sprites, movement, collision, dash afterimages, rescue, CPU, or round flow.
- Adding gravity-driven strands, multiple arbitrary strands, oscillation, or random hair motion.
- Importing the full reference player scene, movement controller, plugin, or unrelated assets.

## Decisions

### Keep position-history hair as a separate per-player presentation component

`PlayerHair` remains a child of the current player and owns sampling, six-point history, `fakeHairCount`, the `max_width = 2` backward constraint pass, the hair pivot and color state. It samples the existing `CharacterBody2D` position, velocity, facing, dash state and grounded transitions at render cadence, matching the reference's `_process()` timing. The controller/presentation layer only configures the profile and forwards any state edge that cannot be derived reliably from the parent. Reset/respawn clears the history and seeds all points from the current position.

This preserves the upstream algorithm, including its small bounded downward idle extension; it does not reinterpret that extension as gravity. The line and base are rendered in a fixed-size viewport so that the reference composition stays compact and clipped to its pixel canvas at the project's player scale.

**Alternative considered:** retain Verlet or damped segment physics. Rejected because neither is present in the reference and both produced the drooping behavior this change is meant to remove.

### Rebuild the reference viewport composition without replacing player art

The hair scene will contain a 24×24 transparent `SubViewport`, the reference `Line2D` texture/width curve, the static base sprite, a `Hairpivot`, and a viewport-output sprite with the one-pixel outline shader. Nearest filtering and whole-pixel snapping remain enabled. The viewport size and line count derive from the same six-point length so they cannot drift apart.

The current `AnimatedSprite2D` does not expose the reference `AnimationPlayer` tracks. Translate the reference pivot key values into a small hair-pose map keyed to the current body animation and normalized frame phase. Sample that map alongside `visual.animation`/`visual.frame`, then mirror only the pivot X coordinate for facing. This recreates the source's animation-specific attachment without driving or replacing the existing body animation playback.

**Alternative considered:** attach a new `AnimationPlayer` and duplicate the body animation timeline. Rejected because it creates a second playback authority and can desynchronize with `SpriteFrames`.

### Keep reference color transitions in the hair component

Use the source palette (`#ad4045` default, `#51b5ff` dash blue, white landing flash), 0.1-second landing hold, and 0.2-per-frame target interpolation. Grounded non-dashing state returns the target to the default color. P1/P2 profiles may override the default/base tint while sharing the same state transitions.

**Alternative considered:** retain static profile color or reuse dash afterimage tint. Rejected because the source changes the hair itself independently of both body tint and dash-trail tint.

### Gate imported textures on documented rights

First inspect the exact upstream commit and any applicable asset license or permission. If permission covers use and redistribution in this project, add only `hair.png` and `haipixelr.png`, preserve source attribution, and document that permission. If it does not, do not import those files; record the missing permission and use a project-owned equivalent only after the asset decision is resolved. The line algorithm and shader setup remain independent of that gate.

**Alternative considered:** copy both textures immediately because the upstream README says the demo uses them with permission. Rejected because that statement does not establish that the permission extends to this project.

## Risks / Trade-offs

- [The six-point trail and viewport can look misplaced against this project's differently offset sprites] → Calibrate per-animation pivot points against the existing 32×32 frames and verify P1/P2 at rest, movement, turn, dash, and landing before accepting the adaptation.
- [The original per-frame color interpolation varies with render frame rate] → Preserve the source behavior for fidelity and lock expected color transitions in deterministic tests; document any Godot 4.7 timing adaptation if exact per-frame parity proves unstable.
- [Reference texture permission may be unavailable] → Keep the permission audit as an explicit task gate; do not import unlicensed textures, and surface an unresolved art dependency rather than silently substituting an unapproved asset.
- [SubViewport output can introduce filtering or outline clipping artifacts] → Use nearest filtering, the reference viewport dimensions and shader margins, and a visual regression check at the game's configured scale.

## Migration Plan

1. Pin the inspected `main-4.x` commit and record source paths, engine version, algorithm parameters, shader setup, texture provenance and applicable rights evidence.
2. Rebuild the hair scene and trail component while keeping the player and body animation resources unchanged; add the pose map for all active body animation clips.
3. Integrate state/color updates for both profiles and preserve reset, dash freeze, afterimage rescue and collision ownership.
4. Run deterministic hair tests and render checks for idle, horizontal/vertical motion, reversal, animation pose, dash, landing, reset, both players together, viewport clipping and no collision side effects.
5. Update the player and asset-manifest documentation with final parameters, resource paths, attribution/permission decision and test commands.

**Rollback:** Restore the previous `player_hair.gd`/`.tscn`, profile hair fields and presentation wiring as a single visual-only change. Do not roll back or alter player movement, dash afterimages/rescue, collision geometry or arena data.

## Open Questions

None. Texture import remains conditional on the permission audit specified above.
