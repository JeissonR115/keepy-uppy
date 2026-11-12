# Tasks

## 1. Confirm the player animation asset contract

- [ ] 1.1 Inventory all body and `player_sweat` PNG frames and confirm the paths, frame counts, dimensions, empty frames, and GIF preview timing against `design.md`; verify by generating or reviewing an asset inventory report.
- [ ] 1.2 Review each animation in Godot and confirm the state/effect mappings in `design.md`, including whether `fallPose` and `still` are appropriate; verify the approved and intentionally unused clips are recorded in the manifest.

## 2. Add sprite resources and migrate the player scene

- [ ] 2.1 Create body and effect `SpriteFrames` resources from the ordered PNG sequences; verify all manifest animations load with the expected frame counts and no missing resources.
- [ ] 2.2 Replace only the `Visual` body polygon with `AnimatedSprite2D`, add the non-colliding effect layer, and preserve the player root, capsule, cape, and priority indicator; verify the scene hierarchy and collision dimensions match the existing scene.
- [ ] 2.3 Update visual asset tests and `docs/modules/player.md` for the sprite resource, frame dimensions, baseline offset, and retained collision/cape contract; verify the focused visual and cape tests pass and the changed `.gd`/`.tscn` files remain at or below 400 lines.

## 3. Connect state and action events to presentation

- [ ] 3.1 Update the presentation component to select one primary animation from the existing post-physics movement snapshot and mirror it from `facing_direction`; verify tests cover idle, both run speeds, jump, airborne fall, dash, climb, and wall slide without changing movement values.
- [ ] 3.2 Trigger jump, climb, and existing bump effects only on their event/state edges and enforce the documented secondary-effect priority; verify tests cover one-shot non-restart, loop behavior, completion, and hidden idle/empty effects.
- [ ] 3.3 Update presentation feedback tests to assert animation selection and preserve balloon impact, dash, priority, and cape behavior; verify the focused feedback and cape test suites pass.

## 4. Validate integration

- [ ] 4.1 Run the project's Godot import and full test commands, then launch the arena and inspect facing, sprite-floor alignment, state transitions, effect timing, and collision behavior; record any pre-existing baseline failures separately from regressions.
- [ ] 4.2 Confirm all added or changed `.gd` and complex `.tscn` files are no longer than 400 lines and that the project contains no missing animation resource references; verify with a line-count check and Godot import output.
