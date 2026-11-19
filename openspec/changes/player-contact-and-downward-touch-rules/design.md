# Design

## Context

See `proposal.md` for the user-facing problems and intended behavior. The match manager currently receives normal and dash contacts in separate queues and resolves them per physics tick. The balloon controller owns impact visuals and ground notifications. Point restart currently relocates both players and the balloon in one synchronous sequence. Downward hits currently resolve immediately; the existing repeated-fault policy replays the first fault and deducts a point from the same player's score on a second consecutive fault.

## Goals / Non-Goals

**Goals:**
- Keep movement, contact validation, warning visuals, and point resolution coordinated across their current owners.
- Ensure the balloon is not physically available until player placement has settled.
- Preserve the existing double-touch and consecutive downward-fault policies while applying the new warning window.

**Non-Goals:**
- Rebalance dash speed, balloon impulse strength, or player interference strength.
- Replace the match's point, set, or serve rules beyond the ground-contact cases in the delta specs.

## Decisions

- Treat each dash activation as a unique contact source. Mark it consumed as soon as any supported balloon-contact path is accepted, and reset the marker only when a new dash starts. This avoids treating the trail and rescue area as independent hits; a shared activation identifier is preferable to adding unrelated cooldowns.
- Keep the warning timer and visual transition with balloon presentation, while the match manager decides ground-contact outcomes. On a downward hit, start a 1.5-second exported timer and flash white with the color of the player whose hit started the warning. A valid later contact cancels the warning before normal turn/fault resolution; a same-player illegal repeat remains a double-touch fault.
- During an active warning, ground contact enters the existing downward-fault replay path. Preserve its current policy: the first consecutive fault replays the point, while the same player's second consecutive warning-ground fault deducts one point from that player's score and serves the opponent. Ground contact after warning expiry awards the point to the last valid toucher because the opponent failed to rescue the balloon.
- Make serve setup a staged operation: disable gameplay outcomes and balloon contact, reset/reposition both players, clear buffered gameplay input, await a physics frame so transforms/collisions settle, then position and arm the stationary balloon. Only after setup completes should the round accept gameplay contacts. Guard the deferred continuation against match restart or match completion.
- For grounded wall response, retain standard collision resolution and remove outward horizontal velocity at a wall; do not apply wall-jump or bounce impulses unless the player has explicitly initiated the applicable action.

## Risks / Trade-offs

- [A warning visual may obscure the turn color or become hard to read during other impact effects] → Give the warning its own cancellable presentation state and restore the normal color on touch, timeout, and point resolution.
- [A delayed serve setup can overlap a restart or scene transition] → Check the round state/generation after the awaited physics frame before arming the balloon.
- [Contacts can arrive in the same physics tick through several callbacks] → Deduplicate by dash activation before queueing a valid contact, while retaining the existing per-tick simultaneous-contact resolution.

## Migration Plan

Update the movement and contact flow, then route warning-ground contacts through the existing replay path. Verify the default and configured warning duration, spawn setup ordering, menu start input, and contact deduplication in gameplay. No save-data migration is needed. Reverting the code restores the previous immediate downward-hit behavior.
