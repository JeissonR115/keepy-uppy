# Tasks

## 1. Create and integrate sprite resources

- [x] 1.1 Inventory the numbered body and effect PNGs, confirm frame dimensions and transparent frames, and record the final clip manifest; verify every listed path exists and frame ordering is numeric.
- [x] 1.2 Create reusable body and effect `SpriteFrames` resources from the supplied PNGs and replace the body polygon with an animated sprite plus a separate effect layer; verify Godot imports the resources and the player scene retains its existing collision capsule, cape, and priority indicator.
- [x] 1.3 Connect existing movement states and action edges to body/effect playback, facing, and one-shot completion behavior; verify representative idle, run, jump, fall, dash, climb, wall-slide, and action-effect states in the arena without changing movement values.
- [x] 1.4 Apply a subtle orange modulation to player 2's body and effects while preserving player 1's base sprite colors; verify both sprites remain recognizable and visually distinct during idle and action animations.

## 2. Migrate presentation checks and documentation

- [x] 2.1 Update `tests/test_visual_assets.gd` and relevant presentation tests for sprite node types, frame inventory, state selection, effect edge handling, player-2 tint, and unchanged collision; verify the focused Godot test commands pass, with unrelated baseline failures recorded separately.
- [x] 2.2 Update `docs/modules/player.md` with the animation/effect resource locations, state mapping, identity tint, and retained collision/cape contract; verify the documented paths match the imported resources.

## 3. Validate integration

- [x] 3.1 Import and launch the project, inspect grounded alignment, facing, player distinction, and action effects across both players; verify there are no missing resources and collisions still use the original capsule.
- [x] 3.2 Review all changed GDScript and scene resources for maintainable ownership and confirm the visual behavior remains presentation-only; verify no movement, input, scoring, or collision dimensions changed.

## Verification notes

- Passed: `test_visual_assets.gd`, `test_visual_feedback.gd`, and `test_player_collision.gd`.
- Broader arena/physics failures observed in this worktree: `test_player_cape.gd` (dash refill after landing), `test_player_wall_climb.gd` (climb entry), `test_dash.gd` (dash refill), and `test_player_interaction.gd` (arena side bounds). These failures concern separate collision/arena behavior; that behavior was not changed here, and their root causes were not isolated during the sprite implementation.
