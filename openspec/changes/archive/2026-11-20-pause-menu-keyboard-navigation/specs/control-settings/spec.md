# Spec Delta

## Purpose

Lets Player 1 operate the existing local control settings screen entirely from the keyboard while both players' conflict-free bindings remain editable.

## ADDED Requirements

### Requirement: Navigate control settings with Player 1
The control settings screen SHALL use Player 1's current mapped Up, Down, Jump, and Dash actions for focus movement, activation, and returning to the pause menu.

#### Scenario: Browse control rows
- **WHEN** Player 1 presses Up or Down outside key-capture mode
- **THEN** keyboard focus moves among the displayed controls and settings actions

#### Scenario: Start or leave a control submenu
- **WHEN** Player 1 presses Jump on a focused action or Dash outside key-capture mode
- **THEN** capture begins for that action or the control screen returns to the pause menu

#### Scenario: Keep gameplay paused
- **WHEN** Player 1 enters or leaves control settings from the pause menu
- **THEN** the settings screen changes while the match remains paused

### Requirement: Capture conflict-free bindings
The control settings screen SHALL capture valid keyboard keys for all fourteen actions and reject reserved, modified, or already assigned keys without changing the existing binding.

#### Scenario: Accept an available key
- **WHEN** Player 1 presses an available, unmodified, non-reserved key during capture
- **THEN** the selected action uses and displays that key

#### Scenario: Reject an unavailable key
- **WHEN** Player 1 presses a prohibited key, modifier chord, or key assigned to another action
- **THEN** the binding remains unchanged and the screen explains the rejection

#### Scenario: Cancel capture
- **WHEN** Player 1 presses Escape or Dash during key capture
- **THEN** capture ends without assigning Escape or changing the selected action's previous binding

### Requirement: Restore both players' default bindings
The control settings screen SHALL offer a keyboard-accessible action that restores and saves every configurable binding for both players.

#### Scenario: Restore defaults
- **WHEN** Player 1 focuses Restore Defaults and presses Jump
- **THEN** all fourteen bindings return to their documented defaults and the displayed keys update

#### Scenario: Preserve current settings when leaving
- **WHEN** Player 1 returns to the pause menu after changing valid bindings
- **THEN** the accepted bindings remain saved and active
