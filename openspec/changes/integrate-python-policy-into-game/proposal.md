# Proposal

## Why

The adaptive Python policy is currently used by the headless `run-episode` simulation, while the normal `1 PLAYER | VS BOT` game path still selects Godot's `LocalBrain`. Connect the Python policy to normal matches so its decisions are visible in the playable game, without making Python startup or bridge failures stop a match.

## What Changes

- Start a configured Python AI client and the existing loopback bridge when a player starts a normal match against the bot; use the remote brain for the bot while preserving the current local brain as fallback.
- Add a live-client mode to the sibling Python AI project so it can consume game observations and return actions without owning or stepping the simulation.
- Make the Python policy prefer a safe position about one dash away from the balloon by default (currently about 60 world pixels from `DASH_SPEED * DASH_TIME`), while keeping the distance configurable.
- Improve policy routing to treat the moving opponent as a dynamic obstacle, reassessing whether pushing through or going around is faster as the opponent moves, and predict balloon rebounds from exported arena and tile collision geometry.
- Show actionable status when the Python process cannot start, connect, or respond; keep the match playable with the local brain in those cases.
- Preserve player-versus-player controls and the existing local `Test CPU` mode.

## Capabilities

### New Capabilities

- `python-cpu-opponent`: Run a configured Python policy as the CPU in a normal interactive match, with bridge lifecycle, policy behavior, configuration, and local fallback.

### Modified Capabilities

None. Existing movement, collision, contact, and scoring requirements remain unchanged.

## Impact

- Godot: normal match/menu startup, `CPUController`, `RemoteBrain`, bridge lifecycle, configuration, status reporting, and integration tests.
- Sibling Python AI project: a live attach/client entry point, configurable dash-range spacing, opponent-aware route choice, and tile-collision balloon trajectory prediction.
- No new gameplay collision or scoring rules; actions continue through the existing player movement and match rules.
