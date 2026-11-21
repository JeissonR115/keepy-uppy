# Spec Delta

## ADDED Requirements

### Requirement: Automatic running boost
Each player SHALL reach a moderately increased run speed by holding a horizontal movement direction, without activating a separate boost action.

#### Scenario: Player runs continuously
- **WHEN** a player holds left or right during normal movement
- **THEN** the player accelerates automatically up to the increased default run speed of 130 px/s

#### Scenario: Player releases movement
- **WHEN** a player releases horizontal movement
- **THEN** the player decelerates using the existing movement behavior and receives no automatic boost

#### Scenario: Player uses remappable controls
- **WHEN** a player views or edits their control bindings
- **THEN** movement, jump, dash, and grab remain available and no manual boost binding is exposed

### Requirement: Climbable arena walls
Each player SHALL be able to climb a designated climbable wall while holding that player's grab action, subject to climbing stamina and existing wall-jump behavior.

#### Scenario: Player grabs a climbable wall
- **WHEN** a player holds grab while adjacent to a climbable wall and has climbing stamina
- **THEN** the player enters the climb state and can move up or down the wall

#### Scenario: Player releases the wall or runs out of stamina
- **WHEN** a player releases grab, loses wall contact, or exhausts climbing stamina
- **THEN** the player leaves the climb state and resumes normal movement or wall sliding

#### Scenario: Player jumps away from a wall
- **WHEN** a player presses jump while climbing a wall
- **THEN** the player performs the configured wall jump and detaches from the wall
