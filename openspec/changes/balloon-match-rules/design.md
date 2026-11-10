# Design

## Context

See [proposal.md](./proposal.md) for motivation and scope. The project already has a `RigidBody2D` balloon, a `MatchManager` that tracks one first-to-target match, a one-shot ground event, normal-hit and dash-rescue signals, per-contact priority collection, and a scoreboard showing points and the current server/result. There are no canonical specs under `openspec/specs/`; related baseline contracts are in the still-pending `keepy-uppy-prototype` change. This change keeps the current scene and single state authority while adding the new set format.

## Goals / Non-Goals

**Goals:**
- Keep balloon physics tunable and bounded while allowing normal and dash contacts to feel different.
- Keep point winner, next server, and current priority as separate match values.
- Make point, set, and match transitions deterministic and testable.
- Present the competitive state without covering the action.

**Non-Goals:**
- Replace the approved dash rescue area with collision on the rendered trail; the trail stays visual and separate.
- Add an online/matchmaking architecture or multiple local teams.
- Finalize balance values without playtesting.

## Decisions

### Keep the RigidBody2D balloon and separate contact acceptance from match attribution

Retain the existing `RigidBody2D`, locked rotation, collision body, player contact `Area2D`, and scoring-ground signal. Keep physics response in the balloon model and send accepted-contact events to the match coordinator with player and contact type. Clamp horizontal and vertical velocity independently in the physics integration path. Apply normal impacts from the contact direction and approach speed, clamped to configured minimum/maximum impulses. Dash rescue continues to apply an upward-biased impulse based on dash direction.

Use a per-player repeat-contact timer so one player's overlap cannot generate repeated hits inside the configured interval, while allowing the opponent's valid contact to be accepted immediately. A dash activation remains one rescue maximum. This avoids a global cooldown suppressing a legitimate counter-contact.

**Alternative considered:** Convert the balloon to a scripted `CharacterBody2D`. That would make each rebound manually deterministic, but it would discard the already implemented collision response and require custom contact resolution. Retain the rigid body unless playtests show the configured bounds cannot make it predictable.

### Start with explicit, configurable physics defaults

Use these as playtest defaults, not fixed requirements:

| Parameter | Suggested initial value | Basis |
|---|---:|---|
| Gravity scale | 0.7 | Existing scene setting |
| Horizontal damping | 0.25 | Existing scene setting |
| Maximum horizontal speed | 360 px/s | New axis-specific cap; test against 320x180 arena |
| Maximum vertical speed | 420 px/s | Preserves the current total-speed ceiling as a vertical cap |
| Rebound | 0.55 | Existing physics material |
| Normal impact impulse | 120–240 | Velocity-scaled range around current 180 impulse |
| Dash rescue impulse | 300 | Existing controller value |
| Same-player contact interval | 0.10 s | Suppresses collision chatter without blocking the other player |
| Balloon body radius | 9 px | Existing collision shape |
| Normal contact radius | 16 px | Existing player contact zone |
| Dash rescue zone | 44x20 px | Existing 22x10 half-extents, oriented to dash trajectory |

Expose these on their owning models or focused resources. Adjust after a complete match, keeping the arena bounds and set rules unchanged.

### Use the dash rescue zone as the physical rescue contact

The active dash creates the existing configurable `Area2D` rescue zone along its trajectory; it expands the effective rescue area to make saves easier. It is distinct from the rendered `Line2D` trail, and one activation can rescue the balloon at most once. Normal body contact while dashing remains a normal contact unless the rescue zone itself accepts the rescue; if both contact types arrive in the same physics tick, the already approved dash-rescue priority policy decides priority and attribution.

**Alternative considered:** Give the visible trail its own collision. That couples art width and animation to gameplay reach and duplicates the existing rescue zone, so it is excluded.

### Extend the existing match coordinator into an explicit state machine

Keep one match coordinator as the authority for coin toss, point/set/match state, server, priority, attribution, and scores. Model the user-facing sequence as `MATCH_START`, `COIN_TOSS`, `POINT_START`, `POINT_ACTIVE`, `POINT_RESULT`, `SET_RESULT`, and `MATCH_RESULT`; avoid creating separate score and turn managers that would need to synchronize overlapping state.

Perform one random toss at match start only, display heads/tails, and map heads to P1 and tails to P2 as previously approved. At point setup, initialize priority and last valid toucher to the server: the user's clarification says the service is itself a balloon contact. On later points, the previous point winner serves; that same rule applies after a set. New sets reset only point scores and retain set wins.

### Use confirmed last-touch scoring and deterministic tie rules

Award each point to the opponent of the last valid toucher. The owner clarified that the serve itself is a valid contact, so the server is the opening last toucher and an untouched serve that falls awards the point to the receiver. This decision resolves the approval gate before scoring implementation.

For accepted same-tick contacts, gather events before resolution. A dash rescue takes priority over a normal hit; for same-type simultaneous contacts, the player who did not hold priority before the tick wins the tie-break. The selected player becomes current priority and last-touch attribution. Player displacement strengths remain configurable and capped; add left/right arena colliders so pushes cannot launch players off the stage.

### Show point, set, and match status in the existing HUD

Extend the scoreboard with a separate set score and compact server/priority indicators. Present the coin-toss result at match start, the point winner during intermission, the set winner at set transition, and the match winner at completion. Use the existing HUD layer and player colors; keep text and indicators within the viewport margins so the balloon and players remain visible. Keep the HUD listening to coordinator signals rather than reading internal state every frame.

**Alternative considered:** Replace the existing HUD with a new menu framework. There is no menu framework in the project, and the current scoreboard already receives all result signals; extend it locally.

### Separate point and set thresholds

Use exported set-point and match-set targets, initially 5 points per set and 3 sets per match. A player at 4 points wins the set on the next point; there is no win-by-two condition. On a set result, reset point scores, keep set scores, and begin the next point with the last point winner serving. Do not rerun the coin toss between sets.

## Risks / Trade-offs

- [Rigid-body simulation may vary slightly with frame/contact order] → Bound both velocity axes, keep accepted-contact resolution deterministic, and retain automated tests for thresholds and duplicate ground events.
- [Velocity-based hits may feel too weak or too strong] → Expose the impact range and tune from complete-match playtests.
- [Set HUD may crowd the 320x180 logical viewport] → Use compact labels and check the full display at the configured integer scale.
- [Contact events can be missed during simultaneous transitions] → Record the serve as the opening touch and resolve accepted contacts before scoring each ground event.
- [Added arena side bounds can change movement feel] → Place them at the existing playable edges and verify both normal movement and push collisions.

## Migration Plan

1. Extend balloon tuning/contact reporting and preserve the existing scene resources; add targeted physics tests and manual checks.
2. Extend priority and serve initialization, including the serve contact record and side bounds; verify normal, dash, tie, and reset cases.
3. Implement confirmed last-touch attribution, recording the serve as the opening contact for each point.
4. Add point/set/match state and set counters, then extend the HUD and scoring tests.
5. Run the full acceptance list and update README steps. No save-data migration is needed because match state is not persisted.

Rollback can restore the current single target-score state and HUD, remove set counters and side bounds, and retain the existing balloon model. No external service or user data format is involved.
