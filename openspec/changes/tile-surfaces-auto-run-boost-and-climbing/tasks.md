# Tasks

## 1. TileSet Surface Roles

- [x] 1.1 Add atlas collision variants and dedicated TileMapLayers for scoring floor, player-only one-way platforms, trampoline, and climbable walls in both arenas; verify each layer's collision bits, one-way behavior, and node group in a Godot resource test.
- [x] 1.2 Add tests that verify solid tiles remain collidable, the balloon mask excludes one-way platforms, and trampoline/wall layers are discoverable by their gameplay groups.
- [x] 1.3 Document the four map surface roles and how to place each TileMapLayer in `docs/modules/levels.md`; verify each documented group and resource path exists.

## 2. Balloon and Trampoline Behavior

- [x] 2.1 Limit balloon ground events to designated scoring surfaces and add the trampoline rebound response; verify a scoring tile reports once, while ordinary solids, one-way platforms, and trampolines do not score.
- [x] 2.2 Add gameplay tests for balloon pass-through on one-way platforms, upward trampoline bounce, player trampoline launch, and one-score-per-round behavior; verify the balloon remains in play after trampoline contact.
- [x] 2.3 Update balloon interaction documentation for scoring, platform pass-through, and trampoline behavior; verify it matches the tested collision roles.

## 3. Automatic Run Speed

- [x] 3.1 Remove manual accelerate input, its remappable catalog entries, and temporary boost state; set the default run cap to 130 px/s while preserving acceleration and arena scaling, then verify the player reaches but does not exceed that cap.
- [x] 3.2 Update control settings and persistence tests to omit boost while retaining legacy saved settings safely; verify current remappable controls expose movement, jump, dash, and grab only.
- [x] 3.3 Update player movement documentation and verify the stated automatic speed and remaining controls match the implementation.

## 4. Climbable Walls

- [x] 4.1 Restrict climb initiation to explicitly tagged climbable wall collisions while retaining grab, stamina, and wall-jump behavior; verify ordinary arena boundaries cannot be climbed.
- [x] 4.2 Add tests for climbing up/down, stamina exit, release, and wall jump on a TileSet wall; verify the climb state ends when wall contact or grab ends.
- [x] 4.3 Document wall-layer setup and grab controls; verify the arena authoring steps create a climbable wall recognized by the player.

## 5. Integration

- [x] 5.1 Run arena selection and match-round integration checks on both maps; verify scoring floors end a round once, trampolines and transit platforms do not score, camera bounds still work, and no scene/resource errors occur.
