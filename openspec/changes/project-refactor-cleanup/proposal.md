# Proposal

## Why

Keepy Uppy already has a small, executable codebase and broad automated coverage, but some responsibilities and presentation/configuration data are repeated across its managers, controllers, and UI scripts. A focused architecture pass can make later feature work safer and easier to review while preserving the current game exactly.

## What Changes

- Map the current script, scene, signal, resource, and test relationships before restructuring them; keep the existing `src/` organization unless a concrete boundary justifies a move.
- Reduce unnecessary dynamic calls and brittle node lookups by making dependencies explicit and typed where that improves clarity without changing scene behavior.
- Align control action metadata used by `ControlSettingsManager`, `ControlSettings`, and `PlayerInputReader` so action identifiers and labels do not drift.
- Review the match, player, balloon, and UI scripts for mixed responsibilities; extract a component only where it has a cohesive owner and can be verified independently.
- Group meaningful UI style/layout values and repeated player presentation data in a small shared theme/config resource where they are genuinely shared; keep gameplay balance values with their owning exported properties.
- Replace repeated non-obvious literals with named constants or shared configuration, remove confirmed dead state/code, and avoid creating a general-purpose `utils/` bucket for one-off helpers.
- Retain all existing player controls, match and scoring rules, physics, menu navigation, save format, scene entry points, and visible presentation.
- Establish a regression baseline from the current automated suite and main-scene launch, then verify the same acceptance checks after each refactoring group.

## Capabilities

### New Capabilities

None. This change introduces no new user-visible behavior.

### Modified Capabilities

None. Existing runtime behavior and interfaces are to remain unchanged; this is a pure internal refactor.

Configure this change with `skip_specs: true` because no behavior specification changes are intended.

## Impact

The review covers `project.godot`, the scripts and scenes under `src/`, the 22 automated scripts under `tests/`, and the project guidance in `README.md`. No external dependencies or asset downloads are expected. The current settings file format and saved user bindings must remain compatible.
