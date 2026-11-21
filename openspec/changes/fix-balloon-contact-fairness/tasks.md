# Tasks

## 1. Player Wall and Jump Behavior

- [x] 1.1 Restrict wall-jump and climb probes to arena wall surfaces, and ensure grounded jumps beside walls use the normal jump; add regression cases and verify `godot --headless --path . --script res://tests/test_player_jump.gd`, `godot --headless --path . --script res://tests/test_player_wall_climb.gd`, and `godot --headless --path . --script res://tests/test_player_collision.gd` pass.

## 2. Dash Rescue Deduplication

- [x] 2.1 Share one rescue-hit state across the active dash zone and its afterimages without removing the visual trail; add overlap/tail-contact regression cases and verify `godot --headless --path . --script res://tests/test_dash_rescue.gd` and `godot --headless --path . --script res://tests/test_player_dash_afterimages.gd` pass.

## 3. Match Contact and Fault Resolution

- [x] 3.1 Keep downward-hit faults pending until floor contact or the two-second expiry, cancel them on a valid opponent contact, and add the configurable dash turn-grace handling; test both contact callback orders and verify `godot --headless --path . --script res://tests/test_balloon_turns.gd`, `godot --headless --path . --script res://tests/test_balloon_contact_impulse.gd`, and `godot --headless --path . --script res://tests/test_round_scoring.gd` pass.
- [x] 3.2 Add the brief white fault flash and ensure both players are reset before opening balloon contact, with no spawn overlap against the non-serving player; add visual and stale-position regressions and verify `godot --headless --path . --script res://tests/test_visual_feedback.gd` and `godot --headless --path . --script res://tests/test_balloon_spawn.gd` pass.

## 4. Integration Verification

- [x] 4.1 Run the full-match regression and headless scene startup after the contact changes; verify `godot --headless --path . --script res://tests/test_full_match.gd` and `godot --headless --path . --quit-after 5` both complete successfully.
