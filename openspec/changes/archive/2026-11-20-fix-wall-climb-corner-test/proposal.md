# Proposal

## Why

`test_player_wall_climb.gd` fails its ceiling corner-correction assertion because its setup does not produce ceiling contact. The same failure occurs before `cpu-ai-bridge`, so the test setup—not the bridge's CPU input changes—is the issue.

## What Changes

- Adjust the corner-correction test setup so the player ascends into the ceiling edge and exercises the existing correction.
- Preserve the current assertions for upward movement and horizontal correction bounded by `MovementConstants.CEILING_CORNER_CORRECTION`.
- Make no production-code or player/bot behavior changes.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a test-only setup correction; no player-control requirements change.

## Impact

- `tests/test_player_wall_climb.gd`
- Validate the related Godot player, CPU-intent, navigation, bridge, simulation, episode-event, movement-probe, and arena-surface tests, plus the three `test_cpu_bridge*.py` tests.
