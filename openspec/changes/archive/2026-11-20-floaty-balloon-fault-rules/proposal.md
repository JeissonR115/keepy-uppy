# Proposal

## Why

The balloon currently feels heavy and its launch does not fully express the player's movement. The rally also has no alternating-touch fault, and the arena's extra platforms interrupt the intended floor-only play.

## What Changes

- Tune the balloon for a lighter, floatier feel while keeping its physics bounded and configurable.
- Make a valid hit's launch direction and speed respond to the touching player's movement and contact direction.
- Start each point with the balloon above the server (the coin-toss winner for the opening point, then the previous point winner).
- Enforce alternating contacts: the serve counts as the server's first touch, then only the other player may touch; each valid touch changes the expected player.
- Award the point to the opponent for touching out of turn or for a contact that sends the balloon downward.
- Keep ordinary ground contact as a point-ending fault for the last toucher and show a balloon burst when it hits the floor.
- Remove the extra floating platforms from the arena, leaving the floor and arena boundaries.

## Capabilities

### New Capabilities

- `arena-layout`: restrict the playable collision surfaces to the floor and arena boundaries by removing the floating platforms.

### Modified Capabilities

- `balloon-interaction`: floatier bounded physics, velocity-aware launches, and downward-hit fault detection.
- `round-scoring`: server-relative spawn, alternating-touch enforcement, and fault/ground scoring with a floor burst.

## Impact

Affected systems include `balloon_controller.gd`, `match_manager.gd`, the arena and balloon scenes, and balloon, interaction, and match-scoring tests. The existing coin-toss selection, previous-point-winner serve rotation, dash-rescue behavior, and score/set progression remain the basis for the updated rules.
