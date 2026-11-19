# Proposal

## Why

Set transitions can leave a player in the balloon's serve area, allowing an unintended touch when the next set begins. Ground-contact scoring currently awards the point to the opponent of the last toucher, but the intended rule is that the last valid toucher earns the point if the other player fails to rescue the balloon. The warning visual and grounded jump response also fail to communicate or prioritize the expected action.

## What Changes

- Keep the balloon unavailable through set and round reset until players have been repositioned and their placement has settled; only then position and arm it for the next serve.
- Award a ground-contact point to the last valid toucher. If neither player touched the balloon, preserve the opening-server fallback rule.
- When a downward-touch warning expires, show the color of the player whose turn is next instead of leaving the balloon white or restoring an unrelated base color.
- Give a grounded jump priority over a wall-jump response or player bump displacement. Preserve wall jumps for airborne wall contact.

## Capabilities

### New Capabilities

### Modified Capabilities

- `round-scoring`: award ground-contact points to the last valid toucher and make set transitions use safe staged serve setup.
- `balloon-interaction`: restore the current turn color when the downward-touch warning ends.
- `player-control`: prioritize grounded jumping beside walls or the opponent while preserving airborne wall jumps.

## Impact

Affected code includes `match_manager.gd`, `balloon_controller.gd`, `player_controller.gd`, and player collision handling. The scoring change is externally visible and updates the existing ground-contact scoring contract.
