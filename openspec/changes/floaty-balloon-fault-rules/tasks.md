# Tasks

## 1. Floaty balloon physics and hits

- [x] 1.1 Tune configurable gravity, damping, rebound, and speed caps for longer hang time; verify bounded velocity and slower fall in `test_balloon_physics.gd`.
- [x] 1.2 Make normal and dash-rescue launch vectors use player velocity and contact direction; detect downward launches as faults and add tests for direction, speed scaling, caps, and downward fault reporting.

## 2. Serve turns and fault scoring

- [x] 2.1 Add an expected-toucher state separate from collision priority; require the server's serve first, alternate eligible normal/dash contacts, and award out-of-turn/downward faults exactly once through normal match progression. Verify both players' turns, callback-order cases, match/set progression, and non-duplicated fault points.
- [x] 2.2 Position the balloon above the opening server and each subsequent point winner, preserving the serve as the first contact; verify toss-selected and next-point spawn placement and contact attribution.
- [x] 2.3 Update README with the serve/alternation and fault rules, then verify documented behavior against the scoring tests.

## 3. Floor-only arena and burst

- [x] 3.1 Remove elevated platform instances from the arena while retaining the floor and side boundaries; verify the loaded arena has no elevated platform collision bodies.
- [x] 3.2 Add a brief balloon burst on scoring-floor contact and verify it appears once per point without delaying score resolution or next-point reset.

## 4. Integration verification

- [x] 4.1 Run balloon physics, player interaction, scoring, full-match, and scene-launch acceptance checks; tune or fix failures and record reproducible results in README.
