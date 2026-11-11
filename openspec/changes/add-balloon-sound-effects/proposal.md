# Proposal

## Why

The project currently plays background music but has no sound-effect system, while `KEEPY_UPPY_BALLOON_SOUNDS.md` defines an exact sound manifest, action mapping, variation rules, and acceptance criteria. This change adds those sounds without altering the source presets or assigning effects to actions the guide excludes.

## What Changes

- Add a manifest-driven `AudioManager` autoload with SFX/UI buses, positional and non-positional playback, volume/pitch variation, intensity tiers, and consecutive-variant avoidance.
- Produce the 29 WAV assets specified by the manifest. Use the exact synthesizer exporters when available; otherwise create only the documented silent placeholders and list every pending export in `audio/PENDIENTES.md`.
- Connect the listed sounds to jump/wall jump, dash, running footsteps, balloon contacts and ground burst, point/set outcomes, match start, and confirmed menu selections.
- Add audio event replication hooks for gameplay events while keeping jump/dash immediate for the local player and menu sounds local. Do not add general online movement or match networking.
- Add focused tests and verify manifest preservation, audio file format, event coverage, variation rules, and behavior for actions that must remain silent.

## Capabilities

### New Capabilities
- `sound-effects`: Manifest-based sound playback, action triggers, variation, spatialization, and multiplayer audio-event behavior.

### Modified Capabilities
- None. Existing balloon, player-control, and scoring requirements remain unchanged; this adds a separate audio behavior.

## Impact

- Project setup: `project.godot` and a new audio bus layout/autoload.
- Runtime integration: `src/models/player/player_controller.gd`, `src/models/balloon/balloon_controller.gd`, `src/managers/match_manager.gd`, and the menu/scoreboard scripts.
- Assets and tests: `audio/sfx/`, `audio/PENDIENTES.md` when required, and focused audio tests.
- Multiplayer constraint: the current project has no RPC or network-peer implementation. The audio RPC hooks must work without changing existing local play; remote delivery can only be exercised when a multiplayer peer/authority is present.
