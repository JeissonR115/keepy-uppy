# Design

## Context

See proposal.md for motivation. The balloon is a `RigidBody2D`; its controller currently clamps velocity in `_integrate_forces`, applies contact impulses, and emits contact signals after applying them. `MatchManager` owns point progression and queues contacts for deterministic processing. The arena scene currently instances three floating platform scenes in addition to the floor and side walls.

## Goals / Non-Goals

**Goals:**
- Keep the match manager authoritative for server, expected contact, fault, and point state.
- Preserve bounded balloon speed, dash rescue, existing score/set progression, and one coin toss per match.
- Make physics values adjustable in the balloon scene/controller so the floaty feel can be tuned without changing scoring logic.

**Non-Goals:**
- Change match/set targets, player movement controls, or player collision priority behavior.
- Add a new engine dependency or replace Godot's 2D physics.
- Add courts, nets, or other obstacles to replace the removed platforms.

## Decisions

1. **Track expected toucher separately from collision priority.** `MatchManager` will own an `expected_balloon_player` state. At point start it is the server; the server's first accepted contact is the serve and switches expectation to the opponent. Each later accepted normal or dash-rescue contact alternates expectation. Existing `priority_player` remains a distinct advantage/presentation state because it currently represents the last selected toucher and affects player displacement. If the balloon reaches the floor before the serve, the existing fallback still awards the opponent of the server.

2. **Validate contacts before they change physics or attribution.** Normal-hit and dash-rescue contacts will be submitted to match resolution before their impulse is applied. The manager accepts only the expected player. An out-of-turn contact ends the active point and awards one point to the opponent of the offending player; it must not alter last-valid-touch state. This keeps the two contact paths under the same turn rule. Contact candidates should be collected per physics tick so simultaneous reports have deterministic handling; any reported out-of-turn touch is a fault.

3. **Use the player's velocity in the launch vector.** A shared impact calculation will combine an upward base with the player's movement vector and the balloon/player contact normal, then clamp impulse and resulting velocity to exported limits. The direction check uses Godot's positive-Y-down coordinate system: a contact that produces a downward launch is reported as a fault and resolves the point for the opponent. Keep the contact interval to prevent repeated overlap callbacks from applying multiple hits.

4. **Tune float without removing bounds.** Lower configurable gravity and weaker horizontal damping will increase hang time; speed caps remain in place. Rebound from the floor should be reduced so a ground collision resolves the point rather than creating a playable bounce. Exact exported defaults are selected by playtesting, while behavior remains reproducible through exported properties and physics tests.

5. **Place the next serve over the server.** At initial match setup and after each point intermission, derive the balloon spawn X from the selected server and place it at a configurable vertical offset above that player. The coin-toss winner serves first; each point winner remains the next server under current rules. The server is the first expected toucher. Reset velocity and contact cooldowns as part of the spawn reset.

6. **Resolve all faults through one point-award path.** Ground contact faults the last valid toucher; out-of-turn and downward-hit faults identify the offending player directly. Each route transitions the match out of ACTIVE before any deferred work, awards exactly one point to the opponent, and then uses existing round/set/match progression. A short balloon burst presentation is triggered by scoring-floor contact; an immediate non-ground fault need not fake a floor impact.

7. **Remove only elevated platforms.** Delete the three platform instances and their scene resource from the arena. Keep the scoring floor and existing side walls as arena boundaries.

## Risks / Trade-offs

- [Velocity-based hits can feel inconsistent at very high player speed] → Clamp the calculated impulse and resulting balloon velocity, and tune base/upward contribution with repeatable tests.
- [Simultaneous normal and dash contacts can make turns appear callback-order dependent] → Collect candidates for a physics tick, resolve eligibility deterministically, and test both callback orders.
- [The burst may obscure the point result or make it look like play continues] → Keep it brief, stop match physics on resolution, and begin the existing intermission immediately.
- [Removing platforms changes routes and player jump usefulness] → Preserve player jump controls and test full-arena movement, balloon serves, wall rebounds, and floor scoring in the floor-only layout.
