# Proposal

## Why

The game has a configurable control screen but no pause menu, and its existing controls screen is primarily operated with mouse buttons. Players need a consistent keyboard-only flow for pausing, resuming, restarting safely, and changing or restoring bindings.

## What Changes

- Add a pause menu with Resume, Restart, and Controls options, opened and closed with Escape.
- Make the pause menu, restart confirmation, and controls screen fully navigable with Player 1's current bindings: directional actions move through the menu layout, Jump confirms, and Dash goes back. Escape toggles pause outside capture mode.
- Keep pause options in one vertical column and share repeated menu-navigation and selection helpers through the UI utilities.
- Require a confirmation step before restarting; default the confirmation selection to No and let the user cancel without changing the current match.
- Make the existing controls screen a submenu of pause, preserving its binding capture and conflict validation while adding keyboard navigation and a clear restore-defaults option.
- Keep Escape reserved from binding capture so the pause shortcut remains available.

## Capabilities

### New Capabilities

- `pause-menu`: Pause, resume, safely restart a match, and navigate the pause flow using Player 1 controls.
- `control-settings`: Navigate and operate the existing remappable control screen with Player 1 controls, including restoring both players' defaults.

### Modified Capabilities

- `player-control`: Require the current Player 1 directional, jump, and dash actions to operate menus independently of gameplay.

## Impact

The change affects the scoreboard HUD entry point, pause and confirmation UI, the existing control settings screen, the settings manager's reserved Escape binding, and main-scene pause/restart wiring. It uses Godot's existing Input Map, pause processing, scene reload, and dynamically assigned Player 1 actions; it adds no external dependencies.
