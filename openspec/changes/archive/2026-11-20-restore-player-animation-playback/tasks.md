# Tasks

## 1. Restore playback and add focused regression coverage

- [x] 1.1 Restore normal playback on the shared `Visual` AnimatedSprite2D without changing per-clip `SpriteFrames` speeds or loop flags; verify the configured playback scale is nonzero and frame indices advance for P1 and P2.
- [x] 1.2 Extend `tests/test_visual_feedback.gd` to let a non-looping `flip` or `climbup` clip finish and verify its `animation_finished` signal releases the one-shot gate so the next movement clip plays; extend `tests/test_visual_assets.gd` to assert body playback is enabled and the requested background/hair/body/effect z-index values remain `-100/8/10/11`.
- [x] 1.3 Update `docs/modules/player.md` with the shared body playback setting and the one-shot completion behavior; verify the description matches `player_placeholder.tscn` and `PlayerPresentationController`.

## 2. Verify player presentation integration

- [x] 2.1 Run `tests/test_visual_assets.gd`, `tests/test_visual_feedback.gd`, `tests/test_player_collision.gd`, `tests/test_player_hair.gd`, and `tests/test_player_dash_afterimages.gd`; verify P1/P2 movement clips progress, jump/climb one-shots return to state playback, and sprite playback changes do not affect collision or afterimage behavior.
- [x] 2.2 Run `scripts/check_source_line_limits.sh` and `openspec validate restore-player-animation-playback`; verify the presentation code remains within its source limit and all change artifacts validate.
