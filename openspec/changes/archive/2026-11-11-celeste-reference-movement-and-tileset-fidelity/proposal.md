# Proposal

## Why

Keepy Uppy already contains Celeste style movement, player presentation, arena TileSets, and surface mechanics, but these were built within the game and have not been reconciled against the referenced demo's actual controller, state system, scenes, and assets. This change establishes a source grounded fidelity review and brings over compatible reference behavior and cleared content while preserving the balloon match rules and existing game specific features.

## What Changes

- Compare the reference project's Godot 4 branch, including its controller, state utilities, player scenes, movement-state presentation, dependencies, and licensing, against the current player system.
- Close verified behavioral gaps in movement, jumping, wall jump, wall slide, and dash by adapting compatible behavior; retain climbing, stamina, cape, and local player collisions as game-specific mechanics.
- Keep the existing Keepy Uppy arenas and arena TileSet. The reference contains no TileSet or TileMap data to transfer, so arena recreation and reference graphics are outside this change.
- Preserve valid balloon hits, dash rescue, alternating turns, scoring-ground detection, double-touch prevention, and CPU movement through shared player movement and match validation contracts.
- Record reference behavior not adopted and why; exclude reference code and art unless applicable reuse terms are established.
- Add focused movement, balloon interaction, match-rule, and CPU acceptance coverage and update player documentation.

## Capabilities

### New Capabilities

- `reference-movement`: Defines the expected movement, movement-state presentation, and player visual behavior adopted from the inspected reference while retaining compatible game-specific extensions.

## Impact

Relevant systems include `src/models/player/` (controller, movement constants/techniques, presentation, cape, and CPU controller), `src/models/balloon/balloon_controller.gd`, `src/managers/match_manager.gd`, tests, and `docs/modules/player.md`. The current project is Godot 4 and uses a shared controller for two local players and the CPU. The reference is `Eneskp3441/Godot-Celeste-Movement-Demo` at commit `950c817a33d2645575bfdb0b314fd7ea22f29189`; it contains no TileSet/TileMap, and its code and graphics are excluded because their reuse terms are not established for this project.
