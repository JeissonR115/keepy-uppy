# Tasks

## 1. Player wall movement

- [x] 1.1 Resolve an explicit buffered wall jump while grounded beside a wall before starting a new climb, and add a regression case in `tests/test_player_wall_climb.gd`; verify jump launches upward and away while passive wall contact does not rebound.
- [x] 1.2 Prevent horizontal input from changing facing during the climb state and extend `tests/test_player_wall_climb.gd`; verify opposite input does not flip the character while climbing and normal turning resumes after leaving the wall.

## 2. Balloon explosion

- [x] 2.1 Create a non-looping `SpriteFrames` animation from the nine 64×64 atlas cells at row 1, columns 4–12 of `assets/sprites/Animations/ballow/Free Smoke Fx  Pixel 06.png`, attach it to the balloon scene, and verify frame count, dimensions, and atlas regions in `tests/test_balloon_burst.gd`.
- [x] 2.2 Route floor and spike impacts through one guarded effect path that hides the balloon immediately, stops its motion, disables its collision/contact handling, and preserves their existing signals; extend `tests/test_balloon_burst.gd` to verify both impacts, duplicate suppression, animation completion, and round-reset restoration.

## 3. Integrated verification

- [x] 3.1 Run the focused wall-climb, balloon-burst, and visual-asset tests, then run `openspec validate`; verify all targeted tests pass and the change validates without warnings.
