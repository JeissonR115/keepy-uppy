# Design

## Context

See `proposal.md` for motivation and `specs/pixel-art-presentation/spec.md` for the externally visible contract. The current player scene is a `CharacterBody2D` with a radius-6, height-24 capsule, a procedural `Polygon2D` at `Visual`, a separate priority indicator, and a procedural cape. `player_controller.gd` owns movement and calls `player_presentation_controller.gd` after movement/collision resolution. The presentation controller currently changes polygon color, scale, and rotation for movement feedback. The art is organized as 32×32 PNG frames, with GIF previews alongside many sequences.

The project already has a stable asset contract requirement. This design records the exact animation folders, frame counts, intended state mapping, and use before any scene begins depending on this artwork.

## Goals / Non-Goals

**Goals:**

- Route a read-only movement-state snapshot from the existing player controller to an isolated animation presenter.
- Replace only the body polygon with an animated sprite and place action effects in a separate, non-colliding visual layer.
- Preserve the existing player root, collision capsule, priority indicator, cape, and physics code path.
- Make animation selection, playback priority, facing, and sprite anchoring deterministic and testable.

**Non-Goals:**

- Changing input, movement, dash, climb, collision, balloon scoring, or arena physics.
- Adding gameplay states that do not already exist.
- Drawing replacement artwork, scaling the art into a sprite sheet, or loading GIFs as gameplay resources.

## Decisions

### Keep the player scene and collision ownership stable

Retain `CharacterBody2D`, `CollisionShape2D`, and the `Visual` child path. Change `Visual` from `Polygon2D` to `AnimatedSprite2D`, and change the presentation controller's visual type accordingly. Keep the collision capsule exactly as authored; the 32×32 artwork may extend beyond it visually. Keep the priority indicator and cape as separate children, with the cape behind the body and the indicator legible above it. The visual node must not be used as a physics or hit-test source.

An `AnimatedSprite2D` is preferred over a hand-built frame-changing `_draw()` implementation because frame playback is native Godot presentation behavior and remains separate from the `CharacterBody2D` physics. The sprite's centered origin is offset upward by 4 pixels: with a 32-pixel frame, this aligns the image bottom at the existing capsule's lower edge (12 pixels below the root origin). The cape's current anchors remain untouched. Flip the body and effect sprites horizontally from the existing `facing_direction`; do not infer facing from texture pixels or alter movement direction.

### Build one reusable SpriteFrames resource from PNG frames

Create a single `SpriteFrames` resource for the body and a separate one for the effects. Populate each animation from the naturally sorted `fN.png` sequence in its folder. Preserve the supplied dimensions and pixel filtering settings. GIFs are references for the authored animation and timing only; they are not runtime resources. Where timing is needed, use the GIF's observed frame duration or a documented equivalent in SpriteFrames and visually verify the loop. Godot's documented `AnimatedSprite2D`/`SpriteFrames` flow supports multi-frame playback; its image import documentation lists PNG but not GIF as a project texture format ([AnimatedSprite2D](https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html), [2D sprite animation](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html), [importing images](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html)).

#### Body animation manifest

All body paths below are relative to `res://assets/sprites/player/Animations/player/`. For each `<animation>` row, the exact frame paths are `<animation>/f0.png` through `<animation>/fN.png` (numeric order, where N is frame count minus one), and the exact preview path is `<animation>/<animation>.gif`. Each PNG is 32×32; each listed folder has a GIF preview with the same number of frames.

| Animation | PNG/GIF frames | Playback and state mapping |
|---|---:|---|
| `idle` | 66 / 66 | Loop while grounded and without horizontal movement. |
| `runSlow` | 12 / 12 | Loop while grounded and moving below the existing high-speed run threshold. |
| `runFast` | 12 / 12 | Loop while grounded and moving at/above that threshold. The threshold is visual-only and reads velocity; it does not change acceleration. |
| `flip` | 8 / 8 | One-shot on the existing jump/takeoff transition; then select the appropriate airborne state. |
| `fall` | 8 / 8 | Loop during ordinary descent. |
| `fallFast` | 2 / 2 | Loop during the existing fast-fall condition, if exposed by the movement state; otherwise use `fall`. |
| `fallPose` | 11 / 11 | One-shot on an existing landing/contact transition only if visual review confirms it reads as a landing pose; otherwise keep available but unused. |
| `dangling` | 10 / 10 | Loop during a neutral airborne rise/float state when neither `flip` nor a fall state applies. |
| `dash` | 4 / 4 | Play during the existing dash state, restarting only on a new dash event. |
| `wallslide` | 1 / 1 | Hold as the wall-slide pose while the existing wall-slide timer/state is active. |
| `climbPull` | 4 / 4 | Loop while existing climb motion pulls the player toward/onto the wall. |
| `climbPush` | 4 / 4 | Loop for the opposite existing climb motion. |
| `climbup` | 6 / 6 | One-shot for the existing upward climb transition, then return to the appropriate climb loop. |

The GIF previews report per-frame durations of 40 ms for climb sequences and `flip`, 50 ms for `runFast`, 60 ms for `fall`, 70 ms for `runSlow`, 90 ms for `dash`, 100 ms for `fallFast`, `fallPose`, `idle`, and climb-up, and 110 ms for `dangling`. The static `wallslide` frame remains held. These timings are initial visual values; implementation may tune playback for readability without changing any game timing.

#### Effect animation manifest

All effect paths below are relative to `res://assets/sprites/player/Animations/player_sweat/`. For each `<animation>` row, the exact frame paths are `<animation>/f0.png` through `<animation>/fN.png` (numeric order, where N is frame count minus one), and the exact preview path is `<animation>/<animation>.gif` where a GIF exists. The frames are transparent 32×32 overlays. They render above the body, mirror with it, and never own collision.

| Animation | PNG/GIF frames | Trigger and playback |
|---|---:|---|
| `jump` | 4 / 4 | One-shot on the existing takeoff transition. |
| `climb` | 2 / 2 | One-shot when the existing climb state begins. |
| `climbLoop` | 6 / 6 | Loop while the player remains in the existing climb state. |
| `still` | 6 / 6 | Loop as a secondary idle accent while grounded and stationary, if visual review confirms the supplied sparse effect is intentional. |
| `danger` | 6 / 6 | One-shot on the existing `player_bumped` interaction; it must not create or infer a new danger condition. |
| `idle` | 1 / 1 | Exclude from playback: its supplied PNG frame is fully transparent. |

The effect layer has one active animation at a time. Priority is event one-shots (`danger` above `jump` above `climb`) followed by active-state loops (`climbLoop` above `still`). An effect completion returns to the active state's loop or hides the overlay. A one-shot must not replay every physics frame; trigger it on state/event edges. If the current controller does not expose an existing transition/event needed for a mapping, add a presentation-only event notification at that point, without adding new state detection or altering the underlying gameplay transition.

### Derive presentation from a single post-physics snapshot

The player controller remains the source of truth. After `move_and_slide()` and its existing collision/state updates, pass the presentation controller the current movement state, grounded status, horizontal speed, vertical direction/fast-fall condition, facing, dash/climb/wall-slide state, and action transition edges. The presenter resolves exactly one body animation using this order:

1. Dash.
2. Climb or wall slide (the current active state decides the specific clip).
3. Jump takeoff one-shot.
4. Airborne rise/neutral/fall/fast-fall pose.
5. Grounded run-fast/run-slow.
6. Idle.

The controller should expose only state already maintained by gameplay code. Do not add velocity damping, thresholds that feed back into physics, or new gameplay state. Retain the current presentation entry point where practical, but replace polygon color/scale/rotation feedback with animation playback and preserve separate non-body feedback (cape, priority indicator, balloon interaction).

### Keep every source file within the repository's 400-line ceiling

All changed or new `.gd` and `.tscn` files must remain at or below 400 lines. Keep frame resource declarations out of the player controller; put animation resource ownership in the scene/resource or a focused presentation component. If a component would exceed the ceiling, split animation catalog/setup from state resolution rather than growing the controller.

### Verify the existing test contract migration

Update visual tests that assert `Polygon2D` type, point count, or polygon bounds to assert the animated sprite resource, frame inventory, dimensions, centered offset, and unchanged capsule. Update presentation tests to check selected animation, priority, one-shot edge handling, effect timing, and facing. Retain cape ordering/anchor checks and unrelated project shader/UI checks. The existing player visual test's old four-point polygon assertion is already inconsistent with the current seven-point scene polygon; record that as a pre-existing baseline failure and change only assertions made obsolete by this proposal. Do not weaken unrelated tests to conceal that existing failure.

## Risks / Trade-offs

- [Sprite frames or offsets can shift the character relative to its capsule] → Use the 32×32 frame center with the calculated -4 pixel Y offset and validate the feet against the unchanged capsule and floor.
- [Long idle sequence or authored timing can feel too slow/fast in gameplay] → Keep playback tuning visual-only, review each loop in Godot, and preserve gameplay timers.
- [One-shot effects can restart continuously if driven by a held state] → Trigger one-shots only on transition edges and add a regression assertion for a single playback start per event.
- [Some animation names may not correspond to a distinct runtime state] → Leave unmatched clips in the documented resource manifest but do not invent gameplay states to force their use.
- [The current polygon assertion fails before this change] → Track the identified assertion as a pre-existing baseline issue and validate the new sprite contract independently.

## Migration Plan

1. Add the two SpriteFrames resources and visual nodes while retaining the player scene's collision and helper nodes.
2. Switch presentation selection from polygon transforms/colors to the state-driven animation/effect layers.
3. Migrate visual tests and player module documentation, then run the focused Godot tests and inspect the animation states in the project.
4. Rollback is limited to restoring the previous `Visual` polygon and presentation controller behavior; the player root, collision shape, and gameplay logic remain compatible throughout.
