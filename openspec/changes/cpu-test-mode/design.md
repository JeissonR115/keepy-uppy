# Design

## Context

`CPUController` owns a swappable `CPUBrain`; `LocalBrain` predicts a balloon interception but also applies reaction delay, seeded prediction error, and rival obstruction. `NavGraphBrain` can follow an externally selected `AStar2D` route, while `NavGraphOverlay` currently draws a graph and one route. `CPUInterceptionPredictor` already steps the balloon with gravity scale, air resistance, horizontal damping, rebound, and velocity limits. `LevelManager` and `ArenaCatalog` select runtime arenas. See `proposal.md` for motivation and `specs/cpu-test-mode/spec.md` for observable behavior.

## Goals / Non-Goals

**Goals:**

- Compose the current movement, match rules, graph pathfinding and predictor into a deterministic, observable practice mode.
- Keep CPU decision data independent of drawing and menu controls.
- Reuse catalog and match flow while isolating debug behavior behind an explicit Test CPU mode.

**Non-Goals:**

- Training, a Python runtime dependency, remote brain actions, opponent obstruction, or adding `WALL_JUMP` graph edges.
- Changing normal `LocalBrain`, player-vs-player rules, balloon physics, or match scoring.

## Decisions

1. **Add a dedicated deterministic navigation brain, selected only by Test CPU mode.** It can compose `NavGraphBrain` for edge execution while owning target selection and the SERVE/POSITION/HIT/AVOID state. It must not alter `LocalBrain` defaults because that brain powers the existing one-player mode. Alternatives considered: adding test switches throughout `LocalBrain` (couples test policy to the normal bot) or continuing to use `set_nav_route` (requires an external controller and does not select goals).
2. **Reuse `CPUInterceptionPredictor` and balloon runtime parameters.** Its fixed-physics stepping already applies configured gravity scale, damping, rebound and caps; extend it only where verified prediction requirements are missing, and expose predicted points/trajectory to presentation. Do not duplicate physics values in a second constants table. The predictor currently returns a crossing result rather than a full trajectory, so trajectory sampling should share its integration logic to avoid divergent physics. Alternative considered: analytic ballistic prediction, which would ignore damping, caps and rebounds.
3. **Choose only reachable graph targets.** Find the nearest usable current graph node, query weighted AStar paths, then rank reachable nodes by distance to predicted interception, with path cost and node id as stable tie breakers. Recompute the route when the chosen destination node changes; keep it when the predicted position moves within the same destination node. This follows the requested destination stability and avoids per-tick path churn. If no usable node or route exists, use `LocalBrain` as graceful fallback and disclose that fallback in decision telemetry.
4. **Keep contact authority in the existing match/balloon systems.** The brain checks `expected_balloon_player` and active match state before generating contact actions. `MatchManager` remains the authoritative validator. For an intended normal hit, model the current contact launch direction from `BalloonController`'s impulse calculation and permit a hit only when the resulting vertical velocity is non-descending; otherwise reposition/evade until a safe contact is possible. Test turn/fault behavior through the match manager rather than duplicating its rules.
5. **Treat decision snapshots as immutable presentation input.** Add a snapshot value containing state, short reason, target, current node, route, current edge/action, intent fields, and route-change reason. The overlay and side panel consume snapshots but never choose routes. Retain the previous route on target changes for the faded layer. Alternatives considered: UI reading brain internals (tight coupling) or emitting text directly from the brain to controls (presentation dependency).
6. **Bundle graph JSON in the game repo with provenance.** Copy each generated `../keepy-uppy-ai/graphs/*.json` into `data/nav_graphs/` as a versioned runtime asset, accompanied by provenance recording source path, source revision if available, and copy date. Validate `schema_version` and selected arena id using `NavGraph.load_graph`; reject invalid files and activate local fallback. Do not modify the sibling repo. Alternatives considered: loading relative paths outside the game at runtime (non-portable exports) or fetching graphs over TCP (adds Python/network dependency).
7. **Add a separate Test CPU menu branch and debug controller.** Reuse the arena catalog and selection UI but carry an explicit mode flag into match setup. Put debug pause/step/time-scale and visibility toggles in a test-only controller/panel; restore engine time scale and pause state on exit. Use dedicated debug actions with defaults on currently reserved function keys, Escape for pause/back, and display the bindings in the panel. Normal player-count routes do not instantiate or activate debug UI.
8. **Validate in layers with headless scripts.** Add focused tests for target selection, prediction safety, state transitions, snapshot contents, graph load/fallback and menu/mode isolation, then retain existing movement/match suite as regression coverage. No new dependency is needed.

## Risks / Trade-offs

- [The predictor and actual rigid-body collision solver can diverge near bounces] → share the integration routine for trajectory display and verify representative arena trajectories against headless physics tests.
- [Current graph coverage may be incomplete or stale] → record source provenance, validate every graph against its arena, and preserve a working local fallback.
- [A safe-hit estimate can miss a change in player velocity before contact] → gate the action using the current planned contact state each physics tick and keep `MatchManager` authoritative.
- [Time scale or pause can leak into a later match] → save prior engine values at mode entry and restore them on every exit path.
- [Debug UI may crowd the 320×180 logical view] → place a compact panel in a dedicated margin and verify it does not obscure the player, balloon, route target or scoreboard.
- [The existing `LocalBrain` fallback is not deterministic/error-free] → report its fallback state/reason accurately; the deterministic guarantee applies while the navigation brain has a usable graph and route.

## Migration Plan

No save migration is required. Add graph assets and provenance, implement the brain/telemetry and isolated mode, then test graph and fallback paths. Rollback consists of removing the Test CPU entry point and its mode-only nodes/assets; existing match modes and player data require no conversion.
