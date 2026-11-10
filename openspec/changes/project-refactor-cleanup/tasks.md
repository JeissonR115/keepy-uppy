# Tasks

## 1. Baseline and ownership map

- [x] 1.1 Record the current automated test results and headless main-scene launch result; verify the complete existing test runner and launch command are documented in the change notes or README. Baseline: all 22 scripts passed with Godot 4.7.2 and the headless main scene started; Godot printed sandbox log-file write errors, but each process exited successfully.
- [x] 1.2 Trace and document scene ownership, script references, signals, dynamic calls, node paths, and duplicated configuration across `src/`; verify the map accounts for all runtime scripts and their owning scenes in the Ownership Map section of `design.md`.

## 2. Control metadata and dependencies

- [x] 2.1 Consolidate player action identifiers, default bindings, and labels into one control-domain definition used by the settings manager, settings UI, input reader, player color display, and player-one menu navigation; verify control settings tests pass and InputMap action names, labels, defaults, and persisted bindings remain unchanged.
- [x] 2.2 Replace brittle or string-based cross-script lookups with typed scene-owned references where initialization order permits; verify manager, pause, and settings scene tests pass and menu input/navigation remain unchanged.

## 3. Runtime responsibility review

- [x] 3.1 Review responsibility boundaries in the ownership map; retain match/scoring, player movement, balloon physics, and UI construction in their current cohesive owners because no independent extraction was justified, and verify match, player, and balloon tests pass with physics values and signal order unchanged.
- [x] 3.2 Remove confirmed dead state and simplify repeated logic without changing runtime decisions; delete the write-only `current_bindings` cache and verify affected input/settings tests pass with save/load behavior unchanged.

## 4. Shared values and project guidance

- [x] 4.1 Replace meaningful repeated literals with descriptive constants and centralize only presentation values that have multiple real consumers; share the player identity colors through the action catalog, retain feature-specific layout values locally, and verify both menu scenes and player presentation retain their existing visible layout and colors.
- [x] 4.2 Review README and keep it unchanged because organization and verification commands remain the same; verify every documented test and launch command remains accurate.

## 5. Integration verification

- [x] 5.1 Run the full 22-script automated suite and headless main-scene launch; verify all pass and no game behavior, control settings compatibility, scene entry point, or visible menu behavior changed. Godot 4.7.2 completed all 22 tests and the launch check with successful exit codes.
- [x] 5.2 Review the final diff for accidental resource/scene changes, unused declarations, new dependencies, settings format changes, and unexplained literals; verify `git diff --check` succeeds and all intentional internal moves are reflected in the ownership map. No scene/resource formats or dependencies changed; remaining dictionary access reads the balloon's queued contact payload.
