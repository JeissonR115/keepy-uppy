# Spec Delta

## ADDED Requirements

### Requirement: Grounded jump takes priority over nearby collisions
When a player requests a jump while grounded, the game SHALL start the grounded jump even if the player is touching an arena wall or the opponent, and collision displacement SHALL NOT cancel that jump.

#### Scenario: Jump beside a wall
- **WHEN** a grounded player requests a jump while touching a wall
- **THEN** the player jumps upward without being diverted into a wall jump

#### Scenario: Jump beside the opponent
- **WHEN** a grounded player requests a jump while colliding with the opponent
- **THEN** the player's jump starts and the bump does not replace its vertical jump motion

#### Scenario: Wall jump while airborne
- **WHEN** a player requests a jump while airborne and in contact with a climbable wall
- **THEN** the player performs the configured wall jump away from that wall
