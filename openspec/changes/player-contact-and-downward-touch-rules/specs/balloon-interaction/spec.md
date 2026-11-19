# Spec Delta

## MODIFIED Requirements

### Requirement: Dash rescue zone
Each dash SHALL create a temporary, configurable balloon-interaction zone associated with the dash trajectory, separate from its visual trail.

#### Scenario: Balloon enters an active dash zone
- **WHEN** the balloon contacts the zone during its active interval
- **THEN** the balloon receives a rescue impulse that takes the dash direction into account

#### Scenario: One dash overlaps the balloon repeatedly
- **WHEN** the same dash activation remains in contact with or re-enters the balloon
- **THEN** that activation does not apply additional rescue hits unless the approved design explicitly enables them

#### Scenario: Trail and interaction are presented
- **WHEN** a dash is displayed
- **THEN** its visual trail can be rendered independently of the interaction zone

#### Scenario: Dash overlaps multiple contact paths
- **WHEN** one dash activation contacts the balloon through its rescue zone, trail, or ordinary player contact
- **THEN** it produces at most one valid balloon touch for that activation

## ADDED Requirements

### Requirement: Downward touch warning state
A downward-directed valid balloon hit SHALL start a configurable warning window, defaulting to 1.5 seconds, during which the balloon flashes between white and the active player's turn color.

#### Scenario: Downward hit starts warning
- **WHEN** a valid hit launches the balloon downward
- **THEN** the balloon flashes white and the active player's color for the configured warning duration without immediately ending the point

#### Scenario: A valid touch occurs during warning
- **WHEN** either player makes a valid touch before the warning expires
- **THEN** the warning ends and normal turn and double-touch rules determine whether play continues or a fault is called

#### Scenario: Warning expires
- **WHEN** the configured warning duration elapses without another valid touch
- **THEN** the warning state ends and the balloon returns to its normal presentation

#### Scenario: Point is resolved during warning
- **WHEN** the point ends while the warning is active
- **THEN** the warning is cleared and the balloon stops flashing
