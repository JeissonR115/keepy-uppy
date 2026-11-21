# Proposal

## Why

The earlier cleanup clarified ownership and consolidated player action metadata, but the current codebase has since grown and still contains three first-party GDScripts above the requested 400-line ceiling. The previous ownership map and verification notes also describe an older project snapshot, so the next refactor needs a current, file-backed plan before implementation.

## What Changes

- Refresh the runtime ownership and dependency map against the current scenes, scripts, resources, tests, and project configuration.
- Enforce a 400-line maximum for first-party `.gd` and `.tscn` files, excluding generated files, external dependencies, and resources that must remain intact; split only cohesive responsibilities.
- Modularize the player controller, CPU prediction logic, and oversized player-controller test script while preserving their existing contracts and behavior.
- Audit weakly typed arena and service boundaries, duplicated presentation effects, and potential orphan assets/scenes; remove files only after repository and project-reference checks confirm they are unused.
- Correct project documentation that no longer matches current controls, tests, or asset/runtime usage.
- Preserve gameplay rules, physics values, input names/defaults, settings persistence, scene entry points, UI behavior, and network/audio contracts.

## Capabilities

### New Capabilities

None. This is an internal refactor and maintenance pass.

### Modified Capabilities

None. Existing observable behavior remains unchanged. The change opts out of specs with `skip_specs: true` in `.openspec.yaml`.

## Impact

The work affects `src/models/player/`, `src/models/balloon/`, `src/managers/`, `src/resources/`, `src/scenes/ui/`, selected scenes and resources, `tests/`, and project documentation including `README.md`. It introduces no external dependencies, changes no saved settings format, and does not add or remove gameplay features. The pre-refactor baseline contained 39 `tests/test_*.gd` scripts; the current work adds focused predictor, split-player, palette, retained-resource, and touch-effect checks. The headless test loop and main-scene launch remain the regression checks.
