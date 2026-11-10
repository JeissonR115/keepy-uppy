# Proposal

## Why

Keepy Uppy currently reads player actions from Godot's Input Map, but players cannot change bindings from inside the game or retain those changes between runs. This change adds independent local controls with the requested defaults and a persistent, validated keybinding screen.

## What Changes

- Set the requested default keys for movement, jump, dash, and accelerate for both players.
- Add an in-game control settings screen that displays and captures per-player bindings, supports cancel and reset, and saves preferences locally.
- Centralize key validation, reject duplicate or prohibited bindings, and explain rejected keys in the interface.
- Add a configurable temporary speed boost on the accelerate actions, using the owner-approved proposal as initial tuning.

## Capabilities

### New Capabilities

- `control-settings`: In-game binding display and capture, validation feedback, reset, cancel, and persistence.
- `player-control`: Player action defaults and the new accelerate input actions.

### Modified Capabilities
None. The repository has no canonical specs yet; the earlier `player-control` definition is part of another pending change, not an existing main spec.

## Impact

The change affects `project.godot`, player input configuration and reading, a new control settings scene and its UI logic, local settings storage, and README verification steps. It uses Godot's built-in Input Map and local configuration facilities without plugins or external services. The owner approved a configurable temporary accelerate boost with initial values documented in `design.md`.
