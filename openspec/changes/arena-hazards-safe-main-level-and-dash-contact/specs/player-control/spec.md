# Spec Delta

## MODIFIED Requirements

### Requirement: Responsive horizontal movement
Each player SHALL move horizontally with configurable acceleration, deceleration, and air control, collide with the arena and the other player, and respond to trampoline surfaces.

#### Scenario: Accelerating and releasing movement
- **WHEN** a player holds a horizontal direction and then releases it
- **THEN** the player accelerates toward that direction and decelerates according to the configured movement parameters

#### Scenario: Moving in the air or into a boundary
- **WHEN** a player steers while airborne or contacts the arena or the other player
- **THEN** air control applies and physical movement respects the encountered collision

#### Scenario: Player lands on a trampoline
- **WHEN** a descending player contacts a trampoline from above
- **THEN** the player receives the configured upward rebound while retaining its horizontal velocity
