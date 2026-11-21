# Spec Delta

## ADDED Requirements

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
