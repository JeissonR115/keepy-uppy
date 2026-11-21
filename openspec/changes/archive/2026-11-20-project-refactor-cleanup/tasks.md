# Tasks

## 1. Baseline and ownership map (completed in the original cleanup)

- [x] 1.1 Record the earlier automated test results and headless main-scene launch; verify the original test runner and launch command were documented. Historical baseline: 22 scripts passed with Godot 4.7.2; this is not the current baseline.
- [x] 1.2 Trace the original scene ownership, script references, signals, dynamic calls, node paths, and duplicated configuration; document the initial map in `design.md`.

## 2. Control metadata and dependencies (completed in the original cleanup)

- [x] 2.1 Consolidate player action identifiers, default bindings, and labels into `PlayerActionCatalog`; verify settings tests and InputMap names/defaults/persisted bindings.
- [x] 2.2 Replace brittle cross-script lookups with typed scene-owned references where initialization order permits; verify manager, pause, settings, and menu navigation checks.

## 3. Runtime responsibility review (completed in the original cleanup)

- [x] 3.1 Review match, player, balloon, and UI ownership; retain cohesive owners and verify physics values and signal order.
- [x] 3.2 Remove the confirmed write-only settings cache; verify save/load behavior remains unchanged.

## 4. Shared values and project guidance (completed in the original cleanup)

- [x] 4.1 Centralize only shared player identity colors and retain feature-specific layout values; verify menus and player presentation.
- [x] 4.2 Review the then-current README and test/launch commands.

## 5. Original integration verification (completed in the original cleanup)

- [x] 5.1 Run the original 22-script suite and headless main-scene launch; verify the prior cleanup did not alter behavior or settings compatibility.
- [x] 5.2 Review the original diff for resource changes, unused declarations, dependencies, settings format, and whitespace errors.

## 6. Refresh the audit and enforce file-size policy

- [x] 6.1 Refresh the ownership map, source references, candidate list, and line-count inventory against the current project; verify the updated evidence is recorded in `design.md` and distinguish candidates from approved deletions.
- [x] 6.2 Add `scripts/check_source_line_limits.sh`, a dependency-free source-size check for first-party `.gd` files under `src/` and `tests/` and project `.tscn` files; verify a 400-line fixture passes, a 401-line fixture fails, and the current three oversized scripts are reported.
- [x] 6.3 Record the current Godot version and run all current `tests/test_*.gd` scripts plus `godot --headless --path . --quit-after 5` before implementation; verify each process exit status is recorded as the new regression baseline. Baseline: Godot 4.7.2; 27/39 scripts exited 0, 12/39 exited 1, and the main-scene launch exited 0. Failure details are in `design.md`.

## 7. Split CPU prediction and oversized player tests

- [x] 7.1 Extract `CPUController.predict_interception()` into `CPUInterceptionPredictor` with explicit balloon/player/bounds/target/horizon inputs and a documented result contract; verify the step rate, physics formulas, bounds, horizon, and fallback positions remain unchanged. CPU state, difficulty, opponent-turn, and full-match checks pass; the prediction ground-boundary failure matches the recorded baseline.
- [x] 7.2 Add `test_cpu_interception_predictor.gd` coverage for non-finite input, invalid horizon, first-touch wait, horizontal/ceiling rebound, ground cutoff, and crossing-time interpolation; verify the new focused test passes. Preserve the separate legacy ground-boundary failure in `test_cpu_prediction.gd` as recorded baseline.
- [x] 7.3 Split `tests/test_player_controller.gd` into cohesive behavior scripts, keeping each existing assertion represented once and reusing `test_dash.gd` and `test_climbable_walls.gd` coverage where appropriate; verify every resulting test runs independently.
- [x] 7.4 Verify `src/models/player/cpu_controller.gd`, the predictor, and each split player test are at most 400 lines using the new size check.

## 8. Modularize player movement responsibilities

- [x] 8.1 Extract dash state/techniques and corner correction from `PlayerController` behind a cohesive API; verify dash, rescue, wall-correction, and movement tests preserve velocity, timing, and collision behavior.
- [x] 8.2 Extract climb/wall-slide state and stamina behind an explicit owner API; verify climb, stamina, wall-jump, and ordinary-wall filtering checks preserve current behavior.
- [x] 8.3 Extract visual state, cape update coordination, and repeated touch-effect presentation only where they form a cohesive component; verify visual feedback, cape, footstep timing, and pixel placement remain unchanged.
- [x] 8.4 Keep `PlayerController` as the sole owner of `move_and_slide()` and physics callback order; verify every new player module has no circular dependency and every first-party GDScript remains at or below 400 lines.

## 9. Tighten arena contracts and resolve candidate components

- [x] 9.1 Use typed `ArenaData`/`ArenaCatalog` references at catalog, level-manager, and menu boundaries where initialization permits; verify invalid catalog entries still warn and selection, bounds, spawns, and multipliers are unchanged.
- [x] 9.2 Decide whether the touch-pixel effect should use the existing scene or a shared component; remove duplicate construction or the unused scene/script only after verifying both player and balloon effects retain timing, z-order, and world position.
- [x] 9.3 Recheck references and owner/editor use for `ancient_ruins.tscn`, `platform.tscn`, `keyboard_menu.gd/.tscn`, `touch_pixel.gd/.tscn`, `assets/sprites/player/`, and `config-music.js`; archive/remove only confirmed unused items and verify all retained scenes/resources import and load.
- [x] 9.4 Centralize run/rise/fall colors only if the player action catalog remains their cohesive owner; verify exact player 1/player 2 color values and all presentation-state tests.

## 10. Documentation and integration verification

- [x] 10.1 Update `README.md` controls and verification sections to match the current action set, test count, and available test files; verify every documented path and command exists and runs as written.
- [x] 10.2 Update affected module docs and the ownership map for any new modules or retained/archive decisions; verify all referenced script, scene, resource, group, and test paths exist.
- [x] 10.3 Run the complete current `tests/test_*.gd` suite and headless main-scene launch; compare per-script results with the pre-refactor baseline in `design.md`, verify no previously passing script becomes failing and the main scene still exits 0, and report the 12 existing failures without changing their behavior in this refactor.
- [x] 10.4 Run the source-size check and `git diff --check`; verify no first-party `.gd` or `.tscn` exceeds 400 lines, no external dependency was added, and the final diff preserves input names/defaults, save format, scene entry points, signals, physics values, and visible behavior.
