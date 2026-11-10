# Spec Delta

## Purpose

Defines the independent keyboard actions and initial bindings used by the two local players. Both players can act simultaneously, and bindings remain changeable through the control settings capability.

## ADDED Requirements

### Requirement: Independent local player actions
The game SHALL expose separate keyboard actions for both players' left, right, up, down, jump, dash, and accelerate controls.

#### Scenario: Both players act at once
- **WHEN** both players press their own movement or action keys during the same input interval
- **THEN** each player's controller receives the corresponding actions independently

### Requirement: Default player bindings
The game SHALL start with the documented default key for every configurable action unless the player has a valid saved binding.

#### Scenario: Player 1 default bindings
- **WHEN** no saved configuration overrides Player 1's controls
- **THEN** left, right, up, down, jump, dash, and accelerate are bound to A, D, W, S, F, G, and H respectively

#### Scenario: Player 2 default bindings
- **WHEN** no saved configuration overrides Player 2's controls
- **THEN** left, right, up, down, jump, dash, and accelerate are bound to the Left, Right, Up, Down arrows, and the top-row 1, 2, and 3 keys respectively

### Requirement: Configurable accelerate boost
The game SHALL expose a distinct accelerate action for each player that triggers a temporary speed boost with configurable duration, intensity, cooldown, and maximum speed, separate from ordinary horizontal movement acceleration.

#### Scenario: Player activates accelerate
- **WHEN** a player presses their accelerate action while its cooldown is ready
- **THEN** that player's speed is boosted for the configured duration and does not exceed the configured maximum speed

#### Scenario: Accelerate is cooling down
- **WHEN** a player presses their accelerate action during its cooldown
- **THEN** no new boost begins

#### Scenario: Boost ends
- **WHEN** the configured boost duration expires
- **THEN** the player returns to ordinary movement behavior and the accelerate action remains unavailable until its cooldown expires
