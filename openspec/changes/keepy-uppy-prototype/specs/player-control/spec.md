# Spec Delta

## Purpose

Defines the local two-player controls and movement behavior that make each player independently responsive and able to contest or rescue the balloon.

## ADDED Requirements

### Requirement: Independent player input
The game SHALL provide separate, remappable Input Map actions for each player's horizontal movement, jump, and dash.

#### Scenario: Both players provide input simultaneously
- **WHEN** both players press different movement or action inputs during the same physics interval
- **THEN** each player's controller responds only to that player's mapped actions

#### Scenario: Player changes a binding
- **WHEN** a player changes an action binding in Godot's Input Map
- **THEN** that player's corresponding control uses the new binding without changing movement logic

### Requirement: Responsive horizontal movement
Each player SHALL move horizontally with configurable acceleration, deceleration, and air control, and SHALL collide with the arena and the other player.

#### Scenario: Accelerating and releasing movement
- **WHEN** a player holds a horizontal direction and then releases it
- **THEN** the player accelerates toward that direction and decelerates according to the configured movement parameters

#### Scenario: Moving in the air or into a boundary
- **WHEN** a player steers while airborne or contacts the arena or the other player
- **THEN** air control applies and physical movement respects the encountered collision

### Requirement: Assisted variable-height jump
Each player SHALL have a configurable jump whose height responds to button hold duration and whose input is buffered around loss or gain of ground contact.

#### Scenario: Releasing jump early
- **WHEN** the player releases jump before reaching the configured maximum hold duration
- **THEN** the jump rises less than a maximum-duration jump

#### Scenario: Jumping just before landing
- **WHEN** jump is pressed within the configured buffer interval before landing
- **THEN** the player jumps upon landing

#### Scenario: Jumping just after leaving a ledge
- **WHEN** jump is pressed within the configured Coyote Time interval after leaving a ledge
- **THEN** the player jumps as if still grounded

### Requirement: Eight-direction dash
Each player SHALL be able to dash in eight directions using configurable duration, cooldown, and movement parameters, with a deterministic fallback direction when no direction is held.

#### Scenario: Dashing in a selected direction
- **WHEN** the player activates dash while holding a cardinal or diagonal direction
- **THEN** the dash travels in that direction for the configured duration

#### Scenario: Dashing without a direction input
- **WHEN** the player activates dash without a directional input
- **THEN** the dash uses the player's current facing direction

#### Scenario: Dash is unavailable
- **WHEN** a player activates dash while its cooldown is active
- **THEN** no new dash begins
