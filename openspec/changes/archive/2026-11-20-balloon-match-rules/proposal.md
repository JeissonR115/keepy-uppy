# Proposal

## Why

Keepy Uppy has a working balloon, priority, and single score-to-win loop, but the match lacks the requested set format and does not present all competitive state. This change formalizes the lightweight balloon model and player interactions, then expands point scoring into a match won by the first player to win three sets.

## What Changes

- Make balloon motion and contact responses independently tunable, including separate speed bounds, damping, rebound, impact ranges, contact timing, and collision zones.
- Formalize service, last-touch tracking, priority changes, simultaneous-contact tie-breaks, and bounded player displacement.
- Replace the current single target-score match with sets to five points and a match won at three sets; do not require a two-point lead.
- Show point and set scores, next server, priority, opening coin-toss result, point/set results, and match winner.
- Award each point to the opponent of the last valid toucher. The owner clarified that a serve counts as the server's first valid balloon contact, so a point cannot have an uncredited no-contact fall.

## Capabilities

### New Capabilities

- `balloon-physics`: Bounded, configurable balloon motion, body contacts, dash rescue contact, and scoring-ground notification.
- `player-priority`: Server-based opening priority, valid-contact changes, deterministic simultaneous-contact handling, and priority-weighted player displacement.
- `set-match-scoring`: Point, set, and match progression, including one opening toss, server alternation, and visible results.

### Modified Capabilities

None. `openspec/specs/` has no canonical specs yet; related baseline requirements exist only in the pending `keepy-uppy-prototype` change. This change describes the next match format and rule layer without editing that separate change.

## Impact

The implementation affects `src/models/balloon/balloon_controller.gd` and its scene, the existing `src/managers/match_manager.gd`, the scoreboard HUD, tests, and README manual checks. It uses Godot 4.x built-in 2D physics and signals; no plugins or external services are required. The existing `RigidBody2D` balloon and one match coordinator remain the starting architecture. The owner clarified serve contact and last-touch attribution before scoring implementation.
