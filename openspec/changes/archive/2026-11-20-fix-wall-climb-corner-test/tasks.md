# Tasks

## 1. Correct the corner fixture

- [x] 1.1 Change only the ceiling-corner test spawn from `x=155` to the verified edge-contact position `x=159`; keep the existing trajectory and `MovementConstants.CEILING_CORNER_CORRECTION` assertions unchanged, then run `tests/test_player_wall_climb.gd` headless and confirm it passes.

## 2. Verify regressions

- [ ] 2.1 Run `tests/test_player_controller.gd`, `tests/test_cpu_intent_actions.gd`, `tests/test_nav_graph_brain.gd`, `tests/test_cpu_remote_brain.gd`, `tests/test_cpu_simulation_control.gd`, `tests/test_cpu_episode_events.gd`, `tests/test_cpu_movement_probe.gd`, and `tests/test_arena_surface_interactions.gd` with the project's Godot 4.7.2 headless executable; confirm all pass.
- [ ] 2.2 Run `python3 -m unittest discover -s tests -p 'test_cpu_bridge*.py'`; confirm all three bridge test cases pass.
