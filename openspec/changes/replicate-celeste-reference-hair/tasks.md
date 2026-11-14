# Tasks

## 1. Pin and audit the reference

- [x] 1.1 Pin the `main-4.x` reference commit and document `Hair.gd`, `Player.gd`, `Player.tscn`, pivot key tracks, `Outline.gdshader`, `haipixelr.png`, and `hair.png` in `docs/reference-celeste-demo-comparison.md`; verify the recorded algorithm, values, node paths, and source revision against that checkout.
- [x] 1.2 Verify whether documented permission covers importing and redistributing both hair textures in this project; record the evidence and attribution in `docs/reference-celeste-demo-comparison.md`, and verify the task stops before importing them if permission is not established.

## 2. Port the position-trail simulation

- [x] 2.1 Replace the current improvised strands and polygon cap with the reference six-position history, rounded-velocity movement detection, `fakeHairCount` idle extension, and backward per-axis `max_width = 2` constraint pass; extend `tests/test_player_hair.gd` for movement, reversal, bounded idle settling and reset, and verify it passes for P1 and P2.
- [x] 2.2 Keep the history sampler in the hair presentation component and feed it the existing player's global position, velocity and facing without moving or duplicating `move_and_slide()`; verify hair updates across render frames, pauses correctly during local dash freeze, and creates no collision nodes or gameplay signals.

## 3. Rebuild the pixel hair rig

- [x] 3.1 Recreate the 24×24 transparent viewport, textured six-pixel line and width curve, base sprite, output sprite and one-pixel outline shader from the reference; include `hair.png` and `haipixelr.png` only when task 1.2 establishes permission, and verify nearest-filtered rendering at the configured game scale.
- [x] 3.2 Add the reference hair color states (default `#ad4045`, dash `#51b5ff`, white landing flash for 0.1 s, and 0.2-per-frame interpolation) to the separate hair component; extend `tests/test_player_hair.gd` to verify dash, landing, ground return and reset transitions for both profiles.

## 4. Match reference pivot animation and integrate both profiles

- [x] 4.1 Translate each reference `Hairpivot` animation track to a pose map synchronized to the current `AnimatedSprite2D` animation/frame and mirror pivot X on facing changes; add deterministic tests for every active body animation and both facing directions, verifying no head detachment or pose drift.
- [x] 4.2 Configure P1 and P2 profiles to instantiate the same hair rig and color-state behavior without changing body `SpriteFrames`, player collision geometry, dash afterimage rescue or CPU movement; extend `tests/test_visual_assets.gd` and verify simultaneous two-player instancing.
- [x] 4.3 Update `docs/modules/player.md` and `docs/modules/player_animation_assets.md` with the final algorithm, rig dimensions/parameters, pose mapping, colors, resource paths and asset permission decision; verify documentation paths match the scene resources and regression commands.

## 5. Verify visual and gameplay isolation

- [x] 5.1 Run `tests/test_player_hair.gd`, `tests/test_visual_assets.gd`, `tests/test_visual_feedback.gd`, `tests/test_player_dash_afterimages.gd` and `tests/test_dash_rescue.gd`; verify hair is visible and attached at rest and in every movement state while dash trails, rescue count, hitboxes and game rules remain unchanged.
- [x] 5.2 Run `scripts/check_source_line_limits.sh` and `openspec validate replicate-celeste-reference-hair`; verify the hair module remains under the source-line limit and all proposal, spec, design and task artifacts validate.
