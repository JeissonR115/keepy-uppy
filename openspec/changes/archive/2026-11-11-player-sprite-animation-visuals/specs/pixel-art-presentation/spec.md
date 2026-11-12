# Spec Delta

## ADDED Requirements

### Requirement: Animated player state presentation
The player SHALL display an existing sprite animation that corresponds to its current movement state, with only one primary animation active at a time.

#### Scenario: Grounded movement
- **WHEN** the player is stationary or moving along the ground
- **THEN** the idle, slow-run, or fast-run animation communicates that state

#### Scenario: Airborne movement
- **WHEN** the player jumps, rises, falls, or falls quickly
- **THEN** the corresponding existing action or airborne animation communicates that state

#### Scenario: Dash or wall interaction
- **WHEN** the player dashes, climbs, or slides along a wall
- **THEN** the matching existing animation takes precedence over the ordinary grounded or airborne animation

### Requirement: Player action effects follow gameplay events
Secondary player effects SHALL use supplied effect frames, follow the corresponding existing player action or state, and never replace the primary player animation.

#### Scenario: Jump and climb effects
- **WHEN** a jump begins or climbing becomes active
- **THEN** the matching jump or climb effect plays at the action's start or for the duration of the active state, as appropriate to that effect

#### Scenario: No matching action is active
- **WHEN** no gameplay event or state mapped to a secondary effect is active
- **THEN** no secondary action effect is shown

### Requirement: Player sprite visuals remain presentation-only
Player sprites and effects SHALL follow the player's facing and position without changing movement, collision geometry, or gameplay event detection.

#### Scenario: Player animation updates
- **WHEN** the player's movement state or facing direction changes
- **THEN** its visual presentation updates while the existing collision shape and movement behavior remain unchanged
