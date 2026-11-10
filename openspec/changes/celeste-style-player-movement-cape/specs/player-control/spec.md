# Spec Delta

## MODIFIED Requirements

### Requirement: Independent player input
The game SHALL provide separate, remappable Input Map actions for each player's horizontal movement, jump, dash, and grab.

#### Scenario: Both players provide input simultaneously
- **WHEN** both players press different movement or action inputs during the same physics interval
- **THEN** each player's controller responds only to that player's mapped actions

#### Scenario: Player changes a binding
- **WHEN** a player changes an action binding in Godot's Input Map
- **THEN** that player's corresponding control uses the new binding without changing movement logic

#### Scenario: Player grabs a wall
- **WHEN** a player holds that player's mapped Grab action near a wall
- **THEN** only that player's controller receives the Grab input

#### Scenario: Player remaps grab
- **WHEN** a player changes that player's Grab binding in Godot's Input Map
- **THEN** wall-climb input uses the new binding without changing the other player's controls
