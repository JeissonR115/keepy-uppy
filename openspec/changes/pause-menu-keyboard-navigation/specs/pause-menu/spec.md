# Spec Delta

## Purpose

Provides a keyboard-operated pause flow for a local two-player match, including safe resume, restart confirmation, and entry to control settings.

## ADDED Requirements

### Requirement: Pause and resume a match
The game SHALL let Player 1 pause and resume gameplay from the keyboard while keeping pause UI responsive.

#### Scenario: Open pause menu
- **WHEN** Player 1 presses Escape during active gameplay
- **THEN** gameplay pauses and the pause menu displays Resume, Restart, and Controls

#### Scenario: Resume from the pause menu
- **WHEN** Player 1 selects Resume or presses Escape while the pause menu is active
- **THEN** the menu closes and gameplay resumes without changing the match state

#### Scenario: Open controls from pause
- **WHEN** Player 1 selects Controls in the pause menu
- **THEN** the control settings screen opens while gameplay remains paused

### Requirement: Navigate menus with Player 1 controls
Pause, confirmation, and submenu navigation SHALL use Player 1's current mapped Up, Down, Jump, and Dash actions for selection, confirmation, and back navigation.

#### Scenario: Move the menu selection
- **WHEN** Player 1 presses Up or Down while a menu is open
- **THEN** the selection moves and the highlighted option is visible

#### Scenario: Confirm or go back
- **WHEN** Player 1 presses Jump or Dash while a menu is open
- **THEN** the focused option is activated or the current submenu is left, respectively

#### Scenario: Menu input does not affect gameplay
- **WHEN** Player 1 navigates or confirms an option while gameplay is paused
- **THEN** those inputs operate the menu without moving or triggering player actions in the arena

### Requirement: Confirm match restart
The game SHALL require explicit confirmation before restarting and SHALL preserve the current match when restart is cancelled.

#### Scenario: Choose restart
- **WHEN** Player 1 selects Restart
- **THEN** a confirmation dialog appears with No selected by default

#### Scenario: Cancel restart
- **WHEN** Player 1 selects No or presses Dash in the confirmation dialog
- **THEN** the dialog closes and the paused match state remains unchanged

#### Scenario: Confirm restart
- **WHEN** Player 1 selects Yes in the confirmation dialog
- **THEN** the current match is replaced by a new match while saved control bindings remain available
