# Spec Delta

## ADDED Requirements

### Requirement: Player 1 actions operate menu navigation
The game SHALL route Player 1's currently mapped Up, Down, Jump, and Dash actions to the focused menu while menus are active.

#### Scenario: Menu follows remapped Player 1 controls
- **WHEN** Player 1 changes one of the Up, Down, Jump, or Dash bindings and opens a menu
- **THEN** the newly mapped key moves selection, confirms, or returns according to that action

#### Scenario: Menus capture input without gameplay actions
- **WHEN** the pause or control settings menu is active
- **THEN** Player 1 menu inputs do not trigger movement, jumping, dashing, or accelerating in the paused arena
