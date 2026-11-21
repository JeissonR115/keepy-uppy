# Tasks

## 1. Movement Foundation and Inputs

- [x] 1.1 Add the centralized player movement and cape tuning constants, explicitly configure 60 physics ticks per second, document the tuning source in `docs/modules/player.md`, and verify the configured values with the player-controller tests.
- [x] 1.2 Add independent remappable Grab actions for both players using the reserved defaults (P1 `R`, P2 `4`), update the control documentation, and verify isolation/remapping with `godot --headless --path . --script res://tests/test_input_map.gd` and `godot --headless --path . --script res://tests/test_control_settings_validation.gd`.

## 2. Player Movement State Machine

- [x] 2.1 Implement momentum-based horizontal motion, gravity and fast-fall behavior, variable-height jump, coyote time, jump buffering, and ceiling correction; document the controls and tuning in `docs/modules/player.md` and verify timing and movement with `godot --headless --path . --script res://tests/test_player_controller.gd`.
- [x] 2.2 Implement single-charge eight-direction dash, per-player freeze, cooldown/refill, dash exit velocity, ducking, corner correction, super/hyper/ultra, and wall bounce; document transitions and verify dash directions, distances, charge, and rescue integration with `godot --headless --path . --script res://tests/test_dash.gd` and `godot --headless --path . --script res://tests/test_dash_rescue.gd`.
- [x] 2.3 Implement wall slide, wall jump, climb, stamina costs/refill, and tired feedback; document wall behavior and verify wall timing, stamina, and jump buffering with the player-controller tests.
- [x] 2.4 Preserve arena/player collisions, priority-scaled bumps, balloon rescue, boost, and bot control while integrating the new states; document the retained interaction contracts and verify them with `godot --headless --path . --script res://tests/test_player_interaction.gd`, `godot --headless --path . --script res://tests/test_dash_rescue.gd`, and the full-match test.

## 3. Player Cape

- [x] 3.1 Add the player-owned cape scene, mirrored anchors, global-coordinate Verlet simulation, tapered polygon and outline, pixel rounding, freeze handling, and safe reset behavior; document its simulation and verify anchor, geometry, reset, and stability behavior with a new cape test.
- [x] 3.2 Derive vivid and muted cape colors from each player's identity color and dash availability, and integrate dash/landing transitions; document the palette behavior and verify hue, saturation, brightness, visibility, and independent player updates with cape and player-scene tests.

## 4. Acceptance and Integration

- [x] 4.1 Add reproducible acceptance coverage for start/stop under 0.1 s, full jump near 28 px, dash near 36 px, retained 325 px/s hyper speed, climb stamina durations, 4 px corner correction, cape length within 15 percent, and the guide's local two-player interactions; verify with the targeted player, dash, interaction, and cape tests.
- [x] 4.2 Run the complete automated test set documented in `README.md` and launch the project headlessly with `godot --headless --path . --quit-after 5`; resolve regressions in physics timing, menus/control remapping, collisions, and scene loading before marking the change complete.
