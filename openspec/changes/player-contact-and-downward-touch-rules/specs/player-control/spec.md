# Spec Delta

## MODIFIED Requirements

### Requirement: Responsive horizontal movement
Each player SHALL move horizontally with configurable acceleration, deceleration, and air control, and SHALL collide with the arena and the other player.

#### Scenario: Accelerating and releasing movement
- **WHEN** a player holds a horizontal direction and then releases it
- **THEN** the player accelerates toward that direction and decelerates according to the configured movement parameters

#### Scenario: Moving in the air or into a boundary
- **WHEN** a player steers while airborne or contacts the arena or the other player
- **THEN** air control applies and physical movement respects the encountered collision

#### Scenario: Grounded contact with a wall
- **WHEN** a grounded player moves into a vertical arena wall
- **THEN** the player stops against the wall and can slide along it without an unintended rebound

## ADDED Requirements

### Requirement: Gameplay input does not leak across inactive transitions
The game SHALL accept jump input only during active gameplay and SHALL discard buffered jump input when gameplay becomes inactive or a new round is initialized.

#### Scenario: Start gameplay from a menu
- **WHEN** a menu action starts a match while the same key is mapped to jump
- **THEN** that key press starts the match without causing an unintended jump

#### Scenario: Round starts after a prior buffered input
- **WHEN** a new round becomes active after its entities are repositioned
- **THEN** no jump requested before activation is executed in the new round
