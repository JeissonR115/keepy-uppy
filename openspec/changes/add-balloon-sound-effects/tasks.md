# Tasks

## 1. Sound assets and import configuration

- [x] 1.1 Check for the exact named synthesizer exporters; generate all 29 manifest WAVs without changing presets, or create 0.1-second silent placeholders and a complete `audio/PENDIENTES.md`; verify every manifest path, pending entry, mono/16-bit/44.1 kHz WAV header, and disabled looping.

## 2. Audio playback foundation

- [x] 2.1 Add the SFX/UI bus layout and register the `AudioManager` autoload; verify the project starts and the existing background music remains unchanged.
- [x] 2.2 Implement manifest validation/loading, single/random/intensity selection, configured volume/pitch and spatial playback, no consecutive duplicate variants, independent playback instances, and actionable missing-asset diagnostics; add and run focused tests for each behavior.
- [x] 2.3 Update the README audio section with the sound library, placeholder/pending-export behavior, and commands for the new audio tests; verify each documented command is valid.

## 3. Player and balloon integration

- [x] 3.1 Connect jump, wall jump, post-freeze dash, and 14-pixel running footsteps to `PlayerController`; add and run tests for trigger timing, speed-based footsteps, and silent unassigned movement actions.
- [x] 3.2 Connect balloon-touch intensity and the guarded scoring-ground burst to `BalloonController`; add and run tests for impact tiers/volume, consecutive variant avoidance, and one burst per ground contact.

## 4. Match, menu, and network integration

- [x] 4.1 Connect point-winner laughs, set-winner cues, match-start cues, and confirmed menu selections; test both player variants, match restart versus round restart, and local-only menu playback.
- [x] 4.2 Add authority-delivered reliable gameplay cues and immediate owner-local/unreliable jump and dash cues, with remote footsteps derived from interpolated motion; test offline behavior and, when a peer is available, delivery exactly once per client. Offline dispatch passed; the project has no configured network peer or movement-interpolation layer, so remote RPC delivery remains unverified.

## 5. Acceptance verification

- [x] 5.1 Run the dedicated audio tests, the existing Godot headless test suite, and a headless main-scene launch; verify all 29 assets and the guide's assigned/unassigned action list, then report any pending audible exports or peer-based checks that could not be exercised. Focused audio tests and asset checks pass, and the headless scene launches. The broader suite also exposes existing failures in `test_balloon_spawn`, `test_cpu_prediction`, `test_dash`, `test_player_controller`, and `test_visual_feedback`; their assertions are stale/timing-sensitive or call `_flash_impact` without its required argument. All WAVs remain silent placeholders, and live-peer delivery was unavailable.
