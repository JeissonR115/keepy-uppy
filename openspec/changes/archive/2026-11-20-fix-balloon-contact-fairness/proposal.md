# Proposal

## Why

Current player and balloon contacts can create unfair or unintended outcomes: grounded wall contact can produce a wall jump, the other player can act as a wall, dash interactions can count more than once, and downward-hit faults resolve before their outcome is clear. Match startup can also register an unintended contact when a player occupies the balloon's spawn area.

## What Changes

- Restrict wall-jump and wall-climb sensing to arena surfaces while preserving physical player-to-player collisions; grounded contact with a wall must not trigger a wall jump.
- Treat downward-directed balloon contacts as pending faults: confirm only if the balloon reaches the floor within two seconds, and cancel if the opponent makes a valid touch or the window expires.
- Prevent one dash activation from producing duplicate hits through its rescue zone and afterimage trail. Add a brief, configurable contact-resolution grace window after a dash so an opponent's timely touch is not incorrectly faulted.
- Flash the balloon white when a fault is confirmed, while keeping the existing automatic point/replay resolution rather than adding a new opponent-choice control.
- Reset both players to their round positions before enabling the balloon's opening contact, and prevent an unintended contact caused by stale or overlapping spawn positions.

## Capabilities

### New Capabilities

### Modified Capabilities

- `balloon-interaction`: Define single-hit dash activation, independent dash visuals, and fault feedback on the balloon.
- `player-control`: Keep player collisions while preventing players from acting as climbable or wall-jump surfaces; prevent grounded wall contact from triggering a wall jump.
- `round-scoring`: Define the pending downward-fault window, dash contact grace handling, and safe player/balloon round initialization.

## Impact

Expected code and regression-test areas include `src/models/player/player_controller.gd`, `src/models/player/player_dash_techniques.gd`, `src/models/player/player_climb_techniques.gd`, `src/models/player/player_presentation_controller.gd`, `src/models/balloon/balloon_controller.gd`, and `src/managers/match_manager.gd`, with coverage in the player collision/jump, dash rescue, balloon turn/spawn, and round-scoring tests. Existing score progression, collision response, dash visuals, and serve rules should remain intact.
