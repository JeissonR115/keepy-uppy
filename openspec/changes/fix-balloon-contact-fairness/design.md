# Design

## Context

See proposal.md for motivation. Player movement uses shared wall-probe helpers: the wall-jump probe accepts any collision, while the climb probe accepts a collision tagged as climbable. Dash rescue currently has separate hit latches for the active zone and the afterimage trail. `MatchManager` batches balloon contacts and owns turns and downward-fault replay state, but resolves downward-directed hits immediately. Match and round setup already reset both players before placing the balloon, so the startup fix must preserve that ordering while preventing stale or overlapping contacts from being registered.

## Goals / Non-Goals

**Goals:**
- Keep the manager authoritative for contact eligibility, pending faults, and point progression.
- Reuse existing movement, dash, and round-reset flows while making their edge cases explicit and testable.
- Preserve player collision response, dash appearance, serve placement, and existing automatic fault resolution.

**Non-Goals:**
- Add a player action or menu for choosing whether to replay a fault.
- Change scoring targets, ordinary ground-contact scoring, or the configured arena/player spawn locations.
- Remove the dash trail or change its visual presentation.

## Decisions

1. **Filter wall probes rather than player collision.** Wall-jump and climb eligibility will rely on arena wall surfaces, not collisions with another player. Normal movement and dash collision masks remain unchanged so the players still block and push one another. Grounded jump handling takes precedence over wall-jump handling, preventing the nearby-wall probe from replacing a normal jump with a lateral impulse. This is preferred to disabling player collisions, which would remove the intended physical interaction.

2. **Use one hit latch per dash activation.** The active rescue zone and afterimages currently have separate paths into balloon rescue. They will share the activation's hit state so whichever path reaches the balloon first consumes the single allowed rescue; subsequent overlap or tail contact from that activation cannot move the balloon again. Afterimages remain visual and may still exist for their configured lifetime.

3. **Keep fault timing in the match manager.** A downward launch records the faulting player and a two-second deadline without ending the point. A valid contact by the opponent cancels that pending fault and proceeds through normal turn validation. Scoring-ground contact confirms it only while the deadline is active; expiry clears it. Confirmed faults continue through the existing automatic replay/penalty path, and the balloon receives a separate brief white flash that does not alter scoring.

4. **Defer only dash turn enforcement during a short grace interval.** Apply an accepted dash rescue once, but delay faulting a contact from the opponent until a short configurable grace interval has elapsed. A valid opponent contact during that interval is accepted and becomes the new last toucher/turn basis; without one, ordinary alternating-turn enforcement resumes. This avoids callback-order-dependent faults without extending the dash's one-rescue limit.

5. **Reset before accepting opening contact.** Round setup will clear pending contacts and reset both players' positions and movement state before exposing the balloon to contact detection. The balloon remains in its existing waiting-for-first-touch state at the selected server's serve position; the non-serving player's reset position must not overlap that spawn. This keeps serve selection intact while ensuring a prior position cannot trigger the next round.

6. **Test at the behavior boundaries.** Extend the existing player jump/collision, dash rescue, balloon turn/spawn, and scoring tests. Include both callback orders for dash contacts, floor contact before and after the downward-fault deadline, opponent cancellation, and a reset where a player starts at the prior balloon position. This is preferred to relying on a manual playtest for timing-sensitive regressions.

## Risks / Trade-offs

- [Collision probes may include arena objects that are not valid wall surfaces] → Use the arena's existing wall/climbable classifications and keep wall-jump and climb eligibility checks aligned.
- [A grace interval that is too long may make turn changes feel unresponsive] → Keep it short, configurable, and test the boundary immediately before and after expiry.
- [A pending downward fault can race with ground contact or another player contact in one frame] → Resolve both through the manager's existing candidate batching and give an eligible opponent contact precedence over pending fault confirmation.
- [The balloon's regular contact-color tween may overlap a fault flash] → Make fault feedback cancel or supersede the current visual tween, then restore the default color.
- [Invalid configured spawn geometry can still place the non-serving player in the balloon area] → Cover the configured spawn pair in tests and report/fix the layout rather than accepting an automatic contact.

## Migration Plan

No persisted data or external interfaces require migration. Implement the movement and contact changes, add regression tests, then run the focused Godot tests for player collision/jump, dash rescue, balloon turn/spawn, and round scoring. Rollback consists of reverting the code changes; no user data or match state needs conversion.
