# Tasks

## 1. Versioned arena graphs and loading

- [x] 1.1 Copy the four generated sibling graph JSON files into `data/nav_graphs/` and add provenance with source repository/path, source revision when available, and copy date; verify each JSON parses and its `level` matches its filename and catalog id.
- [x] 1.2 Add per-arena graph loading through `NavGraph.load_graph`, with validation and local-brain fallback for missing/invalid data; add a headless graph-loading/fallback test and verify it with `godot --headless --path . --script res://tests/test_cpu_test_graph_loading.gd`.

## 2. Autonomous CPU decisions

- [x] 2.1 Extend or factor the interception predictor to expose a trajectory using balloon gravity scale, damping, rebound and limits without duplicating runtime physics constants; add prediction tests for crossings, boundaries and bounded motion and run `godot --headless --path . --script res://tests/test_cpu_interception_predictor.gd`.
- [x] 2.2 Implement deterministic target-node selection from reachable graph nodes, stable tie-breaking and route recalculation only when the target node changes; add destination-selection tests and run `godot --headless --path . --script res://tests/test_cpu_test_target_selection.gd`.
- [x] 2.3 Implement the Test CPU brain FSM (SERVE, POSITION, HIT, AVOID), safe-hit gate, turn checks and local fallback behavior; add scripted turn/FSM/fault tests and run `godot --headless --path . --script res://tests/test_cpu_test_brain.gd`.

## 3. Decision telemetry and visualization

- [x] 3.1 Add a UI-independent per-tick decision snapshot with state, reason, target, current node, active and previous route, active edge, intent and route-change reason; add snapshot tests and run `godot --headless --path . --script res://tests/test_cpu_decision_telemetry.gd`.
- [x] 3.2 Extend the debug overlay and add a live side panel with independently toggleable graph, route, prior route, target and predicted trajectory layers plus CPU state label; add visibility/data-binding tests and run `godot --headless --path . --script res://tests/test_cpu_test_overlay.gd`.

## 4. Test CPU menu and simulation controls

- [x] 4.1 Add an isolated Test CPU branch to the main menu using the arena catalog, starting player versus CPU with debug UI and returning cleanly to the menu; add menu/mode-isolation tests and run `godot --headless --path . --script res://tests/test_cpu_test_mode_menu.gd`.
- [x] 4.2 Add debug controls for layer toggles, pause, exactly one physics tick, slow motion and exit; restore previous pause/time-scale state on exit and test these controls with `godot --headless --path . --script res://tests/test_cpu_test_controls.gd`.

## 5. Integration regression

- [x] 5.1 Run the new CPU Test scripts and relevant existing CPU, navigation, match and menu headless scripts, then run every `tests/test_*.gd` script; fix regressions and verify player-vs-player and ordinary one-player modes have no Test CPU overlay or changed behavior.
