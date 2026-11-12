# Tasks

## 1. Reference and Current-System Audit

- [x] 1.1 Inspect `README.md`, `project.godot`, `CelesteExample/Scripts/Player.gd`, `Hair.gd`, `dash_effect.gd`, the shared `CharacterControllerPlatformer` source, `CelesteExample/States/`, player scenes/animations, `Utils/StateSystem/`, `Utils/Collision/`, particle/shockwave utilities, addons, assets, arena scene geometry, and all license/asset notices in `Eneskp3441/Godot-Celeste-Movement-Demo` at commit `950c817a33d2645575bfdb0b314fd7ea22f29189`; record source revision, dependencies, behavior, geometry, and reuse findings in `docs/reference-celeste-demo-comparison.md`.
- [x] 1.2 Compare findings with the existing player movement modules, presentation/cape, CPU, balloon/match managers, current arena TileSet/maps/catalog, tests, and module docs; document confirmed gaps, compatible and retained game-specific behavior, absent reference TileSet data, and excluded content in `docs/reference-celeste-demo-comparison.md`.

## 2. Movement Parity in Existing Player Modules

- [ ] 2.1 Reconcile horizontal movement, jump assistance, wall jump, wall slide, and corner correction against `CharacterControllerPlatformer.gd` and `Celeste.tres`; implement only confirmed behavior gaps in the existing constants/technique modules, preserve climbing/stamina and jump-combo extensions, cover timing/velocity/collision cases in `tests/test_player_controller.gd`, `test_player_jump.gd`, `test_climbable_walls.gd`, and `test_player_wall_climb.gd`, and update `docs/modules/player.md` with adapted values and intentional differences.
- [ ] 2.2 Reconcile dash direction, charge/refill, duration, velocity, and state exit against `CharacterController.gd`, `CharacterControllerPlatformer.gd`, `Celeste.tres`, and `Player.gd`; retain the local freeze, dash rescue, combo moves, and CPU request path, exclude reference code/art, cover measured distance/state boundaries and all directions in `tests/test_dash.gd` and `test_dash_rescue.gd`, and document adaptations in `docs/modules/player.md`.
- [ ] 2.3 Verify player presentation reflects adopted grounded, rising, falling, wall-slide, wall-jump, and dash states through the existing presentation/cape contracts; avoid editing sprite-frame assets or player-scene hierarchy owned by the active `player-sprite-animation-visuals` change, update `docs/modules/player.md` for the reference's different hair/effect implementation, and verify state feedback and independent player visuals in `tests/test_visual_feedback.gd` and `test_player_cape.gd`.
- [ ] 2.4 Verify that both human players and CPU use the shared movement executor and retain valid balloon hits, one rescue per dash, bumps, alternating turns, and scoring validation; add or adjust coverage in `tests/test_player_interaction.gd`, `test_balloon_turns.gd`, `test_full_match.gd`, and CPU tests as required, and update `docs/modules/balloon.md` and `docs/modules/match.md` only if interaction details change.

## 3. Integrated Movement Acceptance

- [ ] 3.1 Run movement, wall, dash, presentation, balloon, CPU, and match tests together and launch the project headlessly to check movement state transitions, scene loading, and rule preservation; record any baseline failures separately and confirm the current arenas and `assets/sprites/arena/arena_tileset.tres` remain unchanged.
