# Proposal

## Why

The current player controller provides basic acceleration, a short variable-height jump, dash, and boost, but it does not provide the precise momentum, wall interaction, climbing, dash-refill, or visual feedback described for the game. This change replaces that basic motion with a configurable Celeste-inspired local multiplayer moveset and adds a simulated, player-colored cape that communicates dash availability.

## What Changes

- Replace the current movement loop with a physics-tick state machine for normal movement, dash, and climb, including momentum-preserving run acceleration, gravity, variable jump, coyote time, jump buffering, wall movement, dash, super/hyper/ultra, and corner correction.
- Centralize movement, timing, and cape tuning values as named constants; use the documented 320x180 project scale and 60 Hz physics step.
- Add the remappable grab action for each local player while retaining independent player input, the existing boost action, balloon dash-rescue behavior, and player-to-player collision/push gameplay.
- Add a generated Verlet cape with two mirrored anchors, pixel-rounded geometry, and a player-color indicator that is vivid when dash is available and muted after dash until the player lands.
- Add automated movement and cape tests plus reproducible acceptance checks for the timing, distances, stamina, collision, and visual criteria in `KEEPY_UPPY_MOTION_PLAYERS.md`.
- Adapt the guide's networking and no-player-collision assumptions to the current project: keep the feature local-only and preserve the existing bump mechanic; do not add `MultiplayerSynchronizer`, remote interpolation, network authority, or remove player collisions.

## Capabilities

### New Capabilities
- `player-movement`: Local player motion, jump assistance, dash and chained movement techniques, wall interaction, climbing, and stamina.
- `player-cape`: Generated cape simulation, player-color presentation, and dash-availability feedback.

### Modified Capabilities
- `player-control`: Extend independent, remappable local actions for grab and preserve the existing player collision and bump behavior while movement changes.

## Impact

- `src/models/player/player_controller.gd`, `player_input_reader.gd`, and `player_placeholder.tscn` for the controller, actions, and player-owned visual nodes.
- `project.godot` and `player_action_catalog.gd` for the physics rate and remappable grab bindings.
- New player movement constants and cape scene/script under `src/models/player/`.
- Player controller, dash, collision, and new cape tests; `docs/modules/player.md` and the player-control OpenSpec capability.
- No networking layer or external dependencies are introduced.
