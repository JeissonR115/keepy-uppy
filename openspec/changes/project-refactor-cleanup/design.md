# Design

## Context

See `proposal.md` for motivation and scope. This audit is based on the project files currently present, including the user's staged work. It is a planning snapshot; implementation must refresh the baseline before editing because other changes may land in the meantime.

### Runtime ownership and flow

- `project.godot` selects `src/scenes/main/main.tscn`, configures the engine InputMap, GUI theme, audio bus, and `AudioManager` autoload.
- `main.tscn` owns `ControlSettingsManager`, the persistent `arena.tscn`, and `PlayerCountMenu`.
- `arena.tscn` owns both player instances, balloon, `MatchManager`, `LevelManager`, `MapRoot`, shared camera, and scoreboard. `LevelManager` replaces map geometry under `MapRoot` and applies arena spawns, physics multipliers, and camera bounds.
- `ArenaCatalog` exposes ordered `ArenaData` resources. `PlayerCountMenu` reads catalog entries and presents name, description, size/player metadata, and preview before the match restarts.
- `PlayerController` owns `CharacterBody2D` movement integration; its scene also owns `PlayerInputReader`, `CPUController`, cape, collision shapes, visual nodes, and dash rescue area. `PlayerMovementConstants` contains shared movement tuning. `PlayerActionCatalog` owns shared control metadata.
- `BalloonController` owns rigid-body motion, contact cooldowns, pending contact impulses, impact feedback, trampoline response, and scoring-ground notification. `MatchManager` consumes player/balloon signals, resolves point/round/match state, and applies queued contacts.
- `Scoreboard` connects match events to `PauseMenu`, `ControlSettings`, and `PlayerCountMenu`. The UI scripts construct controls and route keyboard navigation; navigation helpers are under `src/scenes/ui/components` and `src/scenes/ui/utils`.
- `AudioManager` loads `audio/sound_presets.json`, creates music/effect players, and handles local/network sound dispatch. It is globally available through the configured autoload.
- The 39 scripts in `tests/` are standalone `SceneTree` checks. README documents a shell loop over them and a headless main-scene launch; there is no project test framework, linter, formatter, or test CI workflow configured.

### Initial verified size inventory (before refactor implementation)

The current first-party GDScript files over 400 lines are:

| File | Lines | Current responsibility mix / proposed seam |
|---|---:|---|
| `src/models/player/player_controller.gd` | 764 | Physics orchestration, movement/jump, dash and corner correction, climbing/wall movement, surface contacts, player collision events, visual state, cape updates, touch pixels, and footsteps. Keep the CharacterBody orchestration here; extract cohesive dash, climb, and presentation responsibilities behind explicit owner APIs, then ensure the controller is at most 400 lines. |
| `src/models/player/cpu_controller.gd` | 406 | Bot state/turn decisions and a 97-line interception simulation (`predict_interception`, lines 131–227). Move the prediction routine into a focused predictor with explicit inputs/outputs; leave decision policy in `CPUController`. |
| `tests/test_player_controller.gd` | 496 | One large `_run_test()` routine exercises controller configuration and movement behavior. Partition its existing assertions into focused scripts by behavior, reusing current dash, climb, and movement tests where they already cover the same contract. |

No `.tscn` in the inspected source tree exceeds 400 lines; the largest reported scene is `scoreboard.tscn` at 230 lines. Keep the cap in force for future scene changes.

### Regression baseline before this refactor

Recorded with Godot 4.7.2 on the current worktree before any refactor implementation. All 39 `tests/test_*.gd` scripts were run individually with engine logs directed to `/tmp` so the sandbox's default `user://logs` restriction did not affect process results. **27 scripts exited 0; 12 exited 1.** The headless main scene (`--quit-after 5`) exited 0, with an ObjectDB leak warning.

Baseline failures to preserve and report separately from regressions:

- `test_balloon_contact_impulse.gd`: dash rescue impulse did not scale with movement (`base=311.13`, `moving=218.61`, cap `360`).
- `test_balloon_physics.gd`: ground contact was not re-armed for the next round.
- `test_balloon_spawn.gd`: next point did not spawn above its winner-server.
- `test_cpu_prediction.gd`: predictor returned an interception below the scoring-ground boundary.
- `test_dash.gd`: dynamic dash traveled `51.67 px`, below the test's substantial-improvement expectation.
- `test_match_menu_audio.gd`: Player 1 point and set wins did not trigger their sounds.
- `test_player_audio.gd`: player did not settle on the floor for footstep checks.
- `test_player_cape.gd`: landing did not restore only the landing player's vivid cape.
- `test_player_controller.gd`: players did not register physical collisions.
- `test_player_interaction.gd`: local bot did not steer toward the balloon during its turn.
- `test_visual_assets.gd`: player did not match the basic-rectangle/procedural-cape assertion.
- `test_visual_feedback.gd`: opening priority was not indicated visually.

`test_balloon_burst.gd` exits 0 but logs a missing `ScoringGround` node lookup; this diagnostic is also part of the baseline. Several tests log leaked ObjectDB/resource warnings on exit. Do not silently repair these as part of the refactor. Final verification compares against this recorded per-script baseline and requires that no previously passing script becomes failing; the main-scene launch must continue to exit 0.

### Confirmed maintenance findings

- `PlayerController._ready()` defines run/rise/fall colors inline while `PlayerActionCatalog` already holds player identity colors. Move colors only if the catalog remains an appropriate cohesive owner; add tests that preserve exact current values.
- `PlayerController.show_touch_pixel()` and `BalloonController.show_contact_pixel()` duplicate pixel creation/fade logic. `src/scenes/ui/components/touch_pixel.tscn` was unused. Both controllers now instantiate it, preserving world-to-parent-local positioning, z-index 5, white 4×4 geometry, and the existing two-second fade. Keep this shared scene/script as the effect owner.
- Arena boundaries and known services still use some string-based node lookup and dynamic calls. `ArenaCatalog`, `LevelManager`, and menu code expose `Resource` and `.get()`/`.call()` access even when the resource/script type is known. Replace only stable known contracts with typed references; retain data-driven strings for group names and input action identifiers where those are the intended interface.
- `README.md` describes 22 tests, eight configurable actions, boost controls, and `tests/test_accelerate.gd`, while the current tree has 39 test scripts and that test file is absent. Update the affected verification/control guidance to match the code and current acceptance tests.

### Unreferenced candidates (not approved deletions)

Repository-wide source/resource-reference searches found no runtime reference to these candidates:

- `src/scenes/levels/ancient_ruins.tscn` is not in `arena_catalog.tres` and is not the main scene.
- `src/models/environment/platform.tscn` is not instantiated by project scenes.
- `src/scenes/ui/components/keyboard_menu.gd` and `keyboard_menu.tscn` are not used by active scenes; the current menus use `MenuKeyboardNavigator` directly.
- `src/scenes/ui/components/touch_pixel.gd` and `touch_pixel.tscn` are not instantiated; current effects are built in the two controllers above.
- 365 tracked files under `assets/sprites/player/Animations/` have no runtime path references in source, scenes, project configuration, README, or module docs; the active presentation uses polygons/rectangles and a procedural cape.
- `config-music.js` has no in-repository runtime or command reference. It may be an external authoring utility, so check its intended use before archiving.

These findings establish candidates, not proof that the files have no external/editor workflow value. A second reference check confirmed the candidate scenes, scripts, 365 animation frames, and `config-music.js` remain tracked and unmodified. They are retained because no ownership confirmation establishes they are disposable; the unused scene/script candidates and representative player art load from the project, and no files were deleted. Do not remove `.uid`, `.import`, source artwork, or resources solely because the runtime does not load them; retain source materials with licensing or future-art value unless the owner explicitly approves archival/removal.

## Goals / Non-Goals

**Goals:**

- Capture the current architecture and concrete file-level follow-up work.
- Reduce the large controller/test modules using cohesive responsibilities and clear dependencies.
- Make the 400-line rule mechanically checkable without adding external packages.
- Keep runtime contracts and visible behavior unchanged.

**Non-Goals:**

- Change movement, scoring, match flow, arena behavior, controls, audio behavior, UI, networking, or saved settings.
- Change the intended product behavior represented by the user's current staged work.
- Delete any candidate file before its use and ownership are confirmed.
- Rewrite the project architecture, add a general-purpose utility layer, or add dependencies.

## Decisions

1. **Use the existing source layout.** Keep modules in their current `src/models`, `src/managers`, `src/resources`, and `src/scenes` domains. Add a new script beside its current owner only when it represents a stable responsibility with a clear API. Do not move files merely to satisfy a line count.

2. **Keep `PlayerController` as the physics owner and orchestration point.** Extract dash state/techniques, climbing state/stamina, and visual/presentation effects only where each component can own its data and expose a small API. Pass required state through typed references or explicit method arguments; avoid circular callbacks between helpers and the player. Recheck scene ownership and initialization order after each extraction.

3. **Separate CPU prediction from CPU policy.** Make the predictor receive the balloon state, target, bounds, and prediction horizon explicitly and return a typed result (or a single documented result structure). Keep turn selection, obstruction, evasion, and difficulty behavior in `CPUController`. Preserve simulation step rate, physics formulas, bounds handling, and deterministic test setup.

4. **Treat tests as source for the size rule.** Apply the 400-line cap to first-party `.gd` files under `src/` and `tests/`, and first-party `.tscn` scene files in the project. Exclude `.godot/`, imported/generated files, external dependencies, and binary/resource data such as `.tres`, images, audio, and fonts. `scripts/check_source_line_limits.sh` uses only Bash and `find`/`wc`; no linter or formatter is present to extend.

5. **Preserve behavior with the existing direct-run test suite.** Before refactoring, record the installed Godot version, run all current `tests/test_*.gd` scripts using the README loop, and launch the main scene headlessly. After each responsibility extraction, run the affected scripts; at integration, rerun the complete suite and scene launch. Do not treat a previously documented 22-test result as the current baseline.

6. **Use static typing only at known boundaries.** Type arena resources/catalog and known manager/controller references where the script class and scene ownership are stable. Keep flexible dictionaries at parsed JSON or queued physics-event boundaries unless a cohesive typed model improves validation without altering timing or semantics. Keep dynamic loading only where resources are intentionally selected from data.

7. **Make cleanup evidence-led.** For each candidate, search source, `.tscn`/`.tres`, project settings, tests, docs, and repository history. Determine whether it is a runtime dependency, test fixture, source asset, or external authoring tool. Archive only candidates with confirmed internal and external non-use; document the decision and verify the project still imports and launches.

8. **Correct docs in the same task group as the related code.** Update README's controls, current test count/run instructions, and stale boost/test references alongside validation tasks. Keep module docs and OpenSpec artifacts consistent with the current staged behavior; do not rewrite historical proposals unless they are still presented as current instructions.

## Risks / Trade-offs

- [Splitting physics across nodes can change processing order, collision state, or movement timing] → Keep `PlayerController` as the sole `move_and_slide()` owner; extract state calculations/actions incrementally and compare movement, dash, climb, collision, cape, and audio tests after each split.
- [Extracting CPU prediction can change floating-point steps or arena-edge outcomes] → Preserve the current 60 Hz-derived step, caps, rebound formulas, horizon, and return semantics; compare seeded prediction/CPU tests before and after extraction.
- [The 400-line rule can encourage artificial fragmentation] → Require every new file to own cohesive data/behavior and a direct test seam; do not split a small helper just to reduce a count.
- [Removing apparently unused scenes or art can break editor workflows or future content] → Treat the listed files only as candidates; record owner approval and verify internal references before removal or archival.
- [Existing README statements may describe historical behavior rather than current requirements] → Update only instructions that claim to describe the active build; preserve historical proposal material or label it clearly as historical.
- [The existing tests may not cover all visuals/timing] → Keep public node names, signals, input actions, saved settings, and scene entry points stable; use manual in-editor review for visuals after structural changes.

## Migration Plan

1. Refresh Git/worktree state and the OpenSpec inventory; record the actual Godot version, current 39-or-current-count test files, results of the direct-run suite, and headless main-scene startup before code changes.
2. Complete the second-pass reference audit for the unreferenced candidates and record retain/archive/remove decisions before any deletions.
3. Split the oversized player-controller tests along existing behaviors and confirm every old assertion remains represented once.
4. Extract CPU interception prediction behind an explicit, typed boundary; run CPU prediction, difficulty, opponent-turn, and full-match checks.
5. Extract player dash, climb, and presentation responsibilities in small changes, keeping physics integration and signal ownership in `PlayerController`; run focused tests after each extraction.
6. Type the arena catalog/data boundary and known service dependencies; consolidate the touch-pixel effect or remove its unused scene, based on the chosen implementation, and verify visuals.
7. Update README and affected module docs to the current project behavior and exact runnable commands.
8. Verify no first-party `.gd` or `.tscn` exceeds 400 lines, run all `tests/test_*.gd` scripts and the headless main-scene launch, inspect `git diff --check`, and review changed files for altered public behavior or unexplained removals.

Rollback is a revert of the isolated extraction or cleanup commit. No saved-data migration is planned; `user://controls.cfg`, InputMap names/defaults, scene entry points, signal contracts, and gameplay values must remain unchanged.

## Open Questions

- The only assets requiring an ownership decision are the unreferenced candidates listed above, especially the 365 player animation files and `config-music.js`. Until their intended future/editor use is confirmed, they remain retained. `touch_pixel.tscn` is the exception among candidates: it is now the shared runtime effect scene and has focused coverage for placement, z-order, geometry, and lifetime.


### Post-split test reachability notes

Splitting `test_player_controller.gd` allows formerly unreachable later assertions to run. The original monolithic test stopped at the player collision assertion, a baseline failure. Independently run partitions expose additional movement assertions that were not reached in the baseline run: held-jump height, rapid ground acceleration, and entering climb. These are recorded as inherited behavior findings for this refactor; the new partitions preserve those assertions without changing physics to force them to pass.


### Player controller modules added during implementation

`PlayerController` remains the only caller of `move_and_slide()` and retains physics callback order. Cohesive helper APIs now live in `player_presentation_controller.gd`, `player_dash_techniques.gd`, `player_climb_techniques.gd`, `player_surface_techniques.gd`, and `player_jump_techniques.gd`; `player_input_reader.gd` converts human/bot decisions into action intents. The helpers receive a `CharacterBody2D` and tuning/input values explicitly and do not preload `PlayerController`, so the dependency graph stays one-way. The controller is exactly 400 lines; the global size checker passes.

### Final integration verification

- Godot 4.7.2: all 47 current `tests/test_*.gd` scripts were run individually. **33 exited 0 and 14 exited 1.** The 14 failing scripts are `test_balloon_contact_impulse`, `test_balloon_physics`, `test_balloon_spawn`, `test_cpu_prediction`, `test_dash`, `test_match_menu_audio`, `test_player_audio`, `test_player_cape`, `test_player_horizontal_movement`, `test_player_interaction`, `test_player_jump`, `test_player_wall_climb`, `test_visual_assets`, and `test_visual_feedback`.
- Eleven of the original 12 failing areas still fail on their previously recorded assertions. The split collision assertion passes when isolated; its original monolithic run had failed after the movement/remapping setup. The three split movement assertions that were unreachable after that earlier failure are now independently observable: jump height, rapid ground acceleration, and entering climb. They fail in the focused scripts and remain outside this behavior-preserving refactor.
- No script that passed in the 39-script pre-refactor baseline became failing. All eight new test files, plus the refactored movement partition, were run: predictor; movement, collision, jump, horizontal, and wall/climb partitions; palette; retained candidate loads; touch-pixel effect. The predictor, movement, collision, palette, retained-resource, and touch-effect checks pass; the three newly reachable behavior assertions above fail.
- `--headless --path . --quit-after 5` exits 0; Godot reports the same ObjectDB leak warning observed in the pre-refactor launch.
- `scripts/check_source_line_limits.sh` passes across first-party `.gd` and `.tscn` files; `PlayerController` is exactly 400 lines. `git diff --check` passes. No external dependency was added.
