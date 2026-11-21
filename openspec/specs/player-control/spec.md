# player-control Specification

## Purpose

Defines the local two-player controls and movement behavior that make each player independently responsive and able to contest or rescue the balloon.

## Requirements

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

### Requirement: Wall movement uses arena surfaces only
Players SHALL be able to wall-jump or climb only from valid arena wall surfaces, not from another player, while player-to-player physical collisions remain enabled.

#### Scenario: Players collide without becoming wall surfaces
- **WHEN** one player contacts the other player while moving, jumping, or dashing
- **THEN** their physical collision is preserved, but the contact does not enable wall-jumping or climbing

#### Scenario: Player attempts to climb or wall-jump from opponent
- **WHEN** a player holds the climb input or requests a wall jump while only another player is beside them
- **THEN** no wall-climb or wall-jump action is triggered by that player contact

### Requirement: Grounded wall contact does not trigger a wall jump
A player who is grounded SHALL use the normal grounded jump when jumping beside a wall and SHALL NOT receive an automatic lateral wall-jump impulse from that contact.

#### Scenario: Jumping from the floor beside a wall
- **WHEN** a grounded player presses jump while touching or checking for a nearby wall
- **THEN** the player performs the normal grounded jump without a wall-jump bounce

### Requirement: Intentional wall jump while grounded
The player SHALL be able to jump away from an adjacent wall while grounded when jump is explicitly requested, without rebounding from passive wall contact.

#### Scenario: Jump is requested while grounded beside a wall
- **WHEN** the player is touching the floor and an adjacent wall and presses jump
- **THEN** the player launches upward and away from the wall

#### Scenario: Player contacts a wall without requesting a jump
- **WHEN** a grounded player moves into a vertical wall without pressing jump
- **THEN** the player remains against the wall without an automatic rebound

### Requirement: Facing remains stable while climbing
The player's facing direction SHALL remain unchanged while the player is attached to a climbable wall.

#### Scenario: Horizontal input points away while climbing
- **WHEN** the player is climbing and presses the opposite horizontal direction
- **THEN** the player keeps the facing direction held on entering the climb

#### Scenario: Climbing ends
- **WHEN** the player leaves the climbing state and provides horizontal input
- **THEN** the player's facing direction updates according to that input
