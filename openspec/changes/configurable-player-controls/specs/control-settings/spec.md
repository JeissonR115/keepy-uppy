# Spec Delta

## Purpose

Allows both local players to inspect and safely customize their keyboard controls in the game. Valid bindings persist across launches and recover to known defaults when saved settings are missing or invalid.

## ADDED Requirements

### Requirement: Per-player binding overview
The game SHALL provide a control settings screen that identifies each player separately and shows the current key for every configurable action.

#### Scenario: Open control settings
- **WHEN** a player opens the control settings screen
- **THEN** the screen shows separate, visually distinguishable sections for both players and the current key for each action

### Requirement: Capture and cancel a binding
The game SHALL let a player select an action, capture one replacement keyboard key, and cancel capture without changing the existing binding.

#### Scenario: Begin key capture
- **WHEN** a player selects an action to rebind
- **THEN** the selected row enters capture mode and displays a message that it is waiting for a key

#### Scenario: Cancel capture
- **WHEN** the player cancels capture before a valid key is accepted
- **THEN** capture mode ends and the action retains its previous key

#### Scenario: Accept a valid key
- **WHEN** the player presses an available key allowed by the validation rules
- **THEN** the selected action displays and uses that key

### Requirement: Reject prohibited and duplicate keys
The game SHALL reject prohibited keys, system shortcut combinations, and keys already assigned to another player action, with a reason visible to the player.

#### Scenario: Prohibited key is pressed
- **WHEN** the player presses F1 through F12, Escape, or an individual Shift, Ctrl, Alt, or Meta key as a binding
- **THEN** the key is not assigned and the screen explains that the key is reserved

#### Scenario: Shortcut combination is pressed
- **WHEN** the captured key event includes a modifier combination that could invoke a system shortcut
- **THEN** the key is not assigned and the screen explains that modified shortcuts cannot be used

#### Scenario: Duplicate key is pressed
- **WHEN** the player selects a key that is assigned to any other configurable action
- **THEN** the key is not assigned and the screen identifies the duplicate-binding conflict

#### Scenario: Protected system shortcut
- **WHEN** an operating system handles a protected shortcut before the game receives its key event
- **THEN** the game does not attempt to intercept or block that shortcut

### Requirement: Restore default bindings
The game SHALL provide a control that restores all actions for both players to the documented default bindings.

#### Scenario: Restore defaults
- **WHEN** the player activates restore defaults
- **THEN** all configurable actions return to their specified defaults and the restored configuration is saved

### Requirement: Persist valid bindings
The game SHALL save accepted bindings locally and load them on later launches, falling back to defaults if saved data is absent, malformed, incomplete, or invalid.

#### Scenario: Reuse saved bindings
- **WHEN** the game starts with a valid saved control configuration
- **THEN** the saved bindings are applied to the corresponding Input Map actions

#### Scenario: Recover from unavailable or damaged settings
- **WHEN** no saved configuration exists or saved data cannot be fully validated
- **THEN** the game applies the complete default configuration and remains playable

#### Scenario: Keep simultaneous local input
- **WHEN** both players use their independently assigned keys during the same input interval
- **THEN** both players' matching actions are available to gameplay independently
