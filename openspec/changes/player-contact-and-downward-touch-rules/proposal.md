# Proposal

## Why

Players can rebound from arena walls while grounded, buffered jump input can fire when gameplay begins from the menu, and a player standing at the balloon spawn can touch it before the serve is ready. Dash contacts can also register as unintended extra touches. The current downward-hit rule immediately ends the point; a timed warning state would give the other player a rescue chance and make the fault easier to read.

## What Changes

- Make grounded wall contacts slide without adding an unintended rebound.
- Prevent menu or inactive gameplay input from carrying a buffered jump into a new round.
- Reposition players first, allow their physics placement to settle, and then place and enable the balloon for the serve.
- Count at most one balloon contact per dash activation across the dash zone, trail, and normal player contact paths.
- Replace the immediate downward-hit fault with a configurable warning window (1.5 seconds by default) where the balloon flashes white and the active player's color. A ground touch during the window is a downward-touch fault; outside it, the last valid toucher receives the point because the opponent did not rescue the balloon.
- Clear the warning on any valid subsequent touch or when a point is resolved. A valid opponent touch rescues play; an offending repeat touch follows the existing double-touch fault rule.
- Keep the existing consecutive downward-fault handling, clarifying when its penalty is applied in the new warning-window flow.

## Capabilities

### New Capabilities

### Modified Capabilities

- `player-control`: grounded wall response and gameplay input buffering at match and round transitions.
- `balloon-interaction`: dash-contact deduplication and the timed downward-touch warning presentation/state.
- `round-scoring`: serve setup order and ground-contact outcomes during and outside the warning window.

## Impact

Affected systems include `player_controller.gd` and dash techniques, `balloon_controller.gd`, `match_manager.gd`, the scoreboard/presentation for warning feedback, and the corresponding player-control, balloon-interaction, and round-scoring specifications. The warning duration should be an exported/configurable match or balloon setting, defaulting to 1.5 seconds.
