# Design

## Context

See [proposal.md](./proposal.md). The scoreboard is a `CanvasLayer` that already owns the HUD and embeds the dynamically generated control settings screen. That screen can capture bindings, reject duplicates through `ControlSettingsManager`, restore defaults, and pause/resume the tree, but its buttons do not accept keyboard focus. The main scene loads the versioned control map before the arena starts. Escape is already reserved by the binding validator.

## Goals / Non-Goals

**Goals:**
- Add a keyboard-driven pause flow without moving match state out of the existing match coordinator.
- Reuse the live Player 1 Input Map actions for menu navigation so remapping those controls also remaps menu operation.
- Make restart an explicit, cancellable decision and retain persisted controls after restarting.
- Keep the existing conflict validation and default recovery behavior.

**Non-Goals:**
- Add new player actions or make Escape configurable.
- Change balloon, scoring, or match rules.
- Remove mouse support from existing buttons; mouse remains optional while every menu action is also keyboard reachable.

## Decisions

### Keep pause presentation with the existing scoreboard layer

Add pause and restart-confirmation panels to the existing scoreboard CanvasLayer, alongside the control settings screen. This layer already processes while the tree is paused, and it has access to the match UI without adding a global singleton. Only one menu panel is shown at a time: pause, restart confirmation, or control settings.

**Alternative considered:** Create a separate global menu scene or autoload. There is one main game scene and no title/menu scene, so a scene-local UI flow avoids global state and ownership across scenes.

### Route menu navigation through the current Player 1 actions

Read `player_1_up` and `player_1_down` to move the selected row, `player_1_jump` to activate it, and `player_1_dash` to go back. These action names resolve through Input Map at runtime, so changes made in control settings also affect menus. Escape remains a fixed pause/cancel key and stays reserved. While a capture is active, action navigation is suspended so keys intended for rebinding do not also activate menu controls; Escape cancels capture.

**Alternative considered:** Hard-code W/S/F/G in menu scripts. That would stop navigation working when Player 1 rebinds those actions, so menus use the existing action map instead.

### Keep restart confirmation separate and default to No

Selecting Restart replaces the pause options with a compact Yes/No confirmation, with No selected initially. Dash or No returns to pause without changing match state. Yes unpauses and reloads the current main scene; the scene's control settings manager loads the saved controls again before gameplay starts. Scene reload resets match scores, set scores, serve, and toss together through their existing initialization path.

**Alternative considered:** Add a second reset method to MatchManager. Scene reload already represents a fresh game and resets all match-owned state consistently while preserving `user://controls.cfg`.

### Treat control settings as a submenu that preserves pause

Entering controls from pause leaves the tree paused. Dash returns to the pause panel without unpausing; Escape cancels an active key capture, and the menu-level Escape handler closes the pause flow when capture is inactive. Give every action row, capture cancel, restore-defaults, and close/return control a visible keyboard focus state. Keep input capture exclusive while waiting for a binding. Restore Defaults continues to use the settings manager's existing atomic full-map reset and save path.

**Alternative considered:** Open controls as a separate overlay that resumes gameplay when closed. Returning to the pause screen is more predictable and avoids gameplay resuming between menu steps.

## Risks / Trade-offs

- [Player 1's remapped menu actions can conflict with gameplay keys] → Pause the tree before routing navigation and use the current actions so menu input never moves the arena players.
- [Escape is also used to cancel key capture] → Give active capture first priority; only route Escape to pause after capture has ended.
- [Scene reload may briefly show the old paused frame] → Unpause immediately before reloading and test that a fresh match starts with saved bindings intact.
- [The controls list and buttons exceed the viewport's visible focus area] → Keep the current compact layout, scroll focused rows into view, and verify every control can be reached at the logical viewport size.

## Migration Plan

1. Add pause and restart-confirmation panels to the current scoreboard layer and wire Escape open/close behavior.
2. Add Player 1 action-based focus, activation, and back navigation to the pause flow.
3. Make the control settings screen keyboard navigable and connect its back path to the still-paused pause panel.
4. Verify restart cancellation and confirmed scene reload, including persisted bindings.
5. Run the menu/control tests and main-scene launch checks. Rollback can remove the new panels and input routing while leaving the existing settings manager and mouse controls intact.
