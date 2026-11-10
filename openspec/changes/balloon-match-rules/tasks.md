# Tasks

## 1. Balloon physics and contact handling

- [ ] 1.1 Expose gravity, horizontal damping, separate horizontal/vertical speed caps, rebound, impact range, same-player contact interval, and collision-zone dimensions using the suggested defaults in `design.md`; extend `test_balloon_physics.gd` and README checks, then verify bounded motion, velocity-scaled normal impact, distinct dash rescue, and one ground event per point.

## 2. Serve, priority, and player interactions

- [ ] 2.1 Initialize each point with the server as opening priority and last valid toucher, and keep the approved same-tick dash-rescue and non-priority tie-break rules deterministic; extend `test_player_interaction.gd` and README checks, then verify service counts as the opening contact and priority resets to the next server.
- [ ] 2.2 Keep priority and non-priority push strengths configurable, cap resulting player speed, and add arena side bounds that prevent players being pushed out; extend interaction tests and document manual wall/push checks, then verify both players remain movable inside the arena.

## 3. Point, set, and match scoring

- [ ] 3.1 Present the proposed attribution rule (point to the opponent of the last valid toucher, with serve recorded as first touch) for explicit owner approval; update the scoring spec/design with the decision before implementing point attribution.
- [ ] 3.2 After attribution approval, extend the single match coordinator to resolve exactly one point per ground contact, play sets to five points, win the match at three sets, reset points while retaining sets, and omit win-by-two; add automated tests for serve attribution, duplicate ground events, 4-4, set reset, and match termination, update README scoring checks, then verify a point winner serves the next point including after a set.
- [ ] 3.3 Perform one coin toss per match, show its result, and use the selected player as the first server; add a test seam or deterministic test for both toss outcomes and update README checks, then verify there is no toss between sets.

## 4. Match presentation and integration

- [ ] 4.1 Extend the HUD to display points, sets, next server, current priority, coin-toss result, point/set results, and match winner; add scoreboard tests and README visual checks, then verify the HUD remains legible at the configured viewport without covering active play.
- [ ] 4.2 Run all balloon, priority, and match tests; launch the main scene and complete the README acceptance checklist through a full best-of-three match, fixing failures before recording the final reproducible results.
