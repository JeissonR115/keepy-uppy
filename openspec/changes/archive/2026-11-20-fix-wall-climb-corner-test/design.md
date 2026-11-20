# Design

## Context

See `proposal.md` for the motivation. `PlayerSurfaceTechniques.update_ceiling_contact` only attempts correction while the player is moving upward and `is_on_ceiling()` is true. The test creates a ceiling whose left edge is `x=160`, but starts the player at `x=155`; that path rises beside the edge and never triggers ceiling contact.

The test failed identically on HEAD (`92d8ca3a5453496ae4c073ab56994f2f7f31d0cc`) and the pre-bridge base (`c1f44625e566f6e6f48871285470366c4b0d1370`). A temporary test copy with the start position changed to `x=159` exited successfully on both revisions. No repository code was changed during these experiments.

## Goals / Non-Goals

**Goals:**

- Make the fixture exercise the existing ceiling corner correction.
- Retain the trajectory assertion and its bound from `MovementConstants.CEILING_CORNER_CORRECTION`.
- Record that the failure predates `cpu-ai-bridge`.

**Non-Goals:**

- Change ceiling collision handling, player controls, or CPU intent behavior.
- Weaken the corner-correction assertion or change its allowed correction distance.

## Decisions

- Move only the test's corner-case spawn from `x=155` to `x=159`, keeping the ceiling's left edge at `x=160`. This setup was experimentally verified to pass the entire test on both HEAD and the pre-bridge base.
- Do not alter production code. The correction helper is correctly gated on real ceiling contact; the original fixture never supplied that condition.
- Do not replace the assertion with a direct helper call or a looser outcome check. The test should continue to verify the real physics path and bounded displacement.

## Risks / Trade-offs

- [Risk] A future change to the test fixture or player collision shape could make `x=159` stop exercising ceiling contact. The existing movement and displacement assertions should fail in that case; update the fixture position based on the collision geometry without relaxing those assertions.

## Migration Plan

No migration is needed. Rollback consists of reverting the test spawn adjustment; production behavior and saved data are unaffected.

## Validation

Run `tests/test_player_wall_climb.gd`, then the related Godot tests named in the proposal and the three `test_cpu_bridge*.py` tests. The targeted test must pass with the existing correction-distance bound unchanged.
