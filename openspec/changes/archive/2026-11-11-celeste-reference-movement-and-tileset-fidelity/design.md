# Design

## Context

See proposal.md for motivation and specs for observable behavior. The current project already has a shared `PlayerController`, movement technique modules/constants, a generated cape, `CPUController`, balloon dash rescue, match-managed contacts, `ArenaData`/`ArenaCatalog`, and role-based TileMapLayers. The prior `celeste-style-player-movement-cape`, `map-selection-tileset-arena-system`, and `tile-surfaces-auto-run-boost-and-climbing` changes implement these systems, so this work must reconcile them with the reference rather than re-create them.

The reference target is `main-4.x` at commit `950c817a33d2645575bfdb0b314fd7ea22f29189` of `Eneskp3441/Godot-Celeste-Movement-Demo`. Its controller/state/presentation dependencies are recorded in `docs/reference-celeste-demo-comparison.md`. The inspected repository contains no TileSet or TileMap, only sprite backgrounds and a compound collision polygon. It has no root code license; the README's EXOK permission statement does not establish rights for all code, assets, or redistribution in this project.

## Goals / Non-Goals

**Goals:**
- Trace each desired mechanic and visual to actual reference code/scenes and compare with the current implementation before changing it.
- Port or adapt only compatible behavior while continuing to route both local players and the CPU through the shared movement executor.
- Preserve the match's contact validation, dash rescue, scoring-ground, map catalog, and role-based arena surfaces.
- Keep the current arena catalog, TileSet, and maps unchanged; exclude reference code and artwork from copied project files.

**Non-Goals:**
- Replacing the current controller, arena selection, or match architecture wholesale with the demo's project structure.
- Adding online multiplayer, the reference demo's unrelated utilities, or mechanics not present in either project.
- Arena recreation or TileSet migration, because the reference has no such data and the accepted scope keeps current arenas.
- Copying reference code or art into the project without terms establishing reuse rights.

## Decisions

### Compare behavior before choosing what to port

Build a mechanic-by-mechanic comparison from the reference controller/resource/state implementation and player scene. Compare it to `src/models/player/player_controller.gd`, `player_movement_constants.gd`, the jump/dash/surface/climb technique modules, `player_presentation_controller.gd`, `cape.gd`, and `cpu_controller.gd`. Record current behavior, reference behavior, chosen adaptation, and a measurable verification for every adopted or intentionally omitted behavior. Implement behavior in the existing project modules; do not transplant reference code or assets.

The reference presentation has event-driven jump/land/dash reactions, directional animation, dash particles/afterimages, shockwave feedback, and hair behavior. Keepy Uppy already has a separate sprite-animation change in progress and a per-player generated cape. This change leaves sprite resources and scene presentation to that work, preserves the cape, and limits presentation changes to exposing/validating the adopted movement state. Do not add reference art or an independent parallel visual system.

### Keepy Uppy remains the authority for gameplay contracts

Keep the current `PlayerController` as the only movement executor. Extend its existing inputs, state/technique modules, or presentation hooks according to the comparison rather than introducing a second parallel controller. CPU decisions may choose actions, but movement and collision continue through that same controller. Any retained/new visual effect is cosmetic and cannot become a hitbox.

Keep `BalloonController` contact events and `MatchManager` turn resolution authoritative. Dash rescue continues through the existing single-use-per-dash path; ordinary contacts still pass through expected-player validation. Preserve player collision/bump behavior, serve sequence, scoring-ground-only point outcomes, and CPU turn constraints. This is preferred over copying the demo's standalone character scene and raw input wiring because those do not represent the local two-player match architecture.

### Preserve the current arena system

The reference has no TileSet/TileMap resource to migrate, so leave `assets/sprites/arena/arena_tileset.tres`, arena scenes, `ArenaData`, and `ArenaCatalog` unchanged. The current explicit scoring/platform/trampoline/climbable roles remain authoritative.

### Exclude uncleared source files and artwork

The repository has no root license and its README does not define terms for all code/assets or onward distribution. Do not copy reference code, graphics, or scenes. Port only compatible behavior within the current modules and retain the documented source revision and exclusion rationale.

## Risks / Trade-offs

- [Reference abstractions or dependencies may not match this project's Godot 4 APIs or scene architecture] → Trace the base controller, state utilities, addons, project settings, and resource dependencies before choosing a port; adapt at the shared controller boundary and document deviations.
- [A seemingly small movement change may affect balloon contact timing, player bumps, or CPU interception] → Verify state transitions for human and CPU and test balloon/turn interactions with the same movement paths.
- [Movement tuning from a solo platformer may alter balloon play or turn timing] → Keep game-specific combo moves and rescue behavior, use the shared executor, and verify both human/CPU paths against match rules.
- [Reference behavior is not licensed for direct copying] → Implement adapted behavior in existing modules without copying source files; exclude reference artwork and document the decision.

## Migration Plan

1. Complete the source and current-project inventory, record the comparison and licensing/provenance findings, and identify only confirmed behavior/content gaps.
2. Adapt compatible movement behavior inside existing player modules; add focused checks and update the movement documentation in the same work group.
3. Preserve sprite/cape presentation ownership in the current player scene and the separate player-animation change; update only movement-state feedback required by the adopted behavior.
4. Verify movement for both human players and CPU, balloon rescue/contact validation, turns, scoring, and existing arena loading.

## Open Questions

None. The accepted scope excludes arena recreation and reference assets.
