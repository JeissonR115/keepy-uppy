# Spec Delta

## Purpose

Establece el comportamiento de las arenas construidas con tiles para que sus superficies, límites y dimensiones sean reutilizables y configurables por mapa.

## ADDED Requirements

### Requirement: Tile-based arena geometry
An arena SHALL use reusable tile graphics and collision definitions to construct solid terrain and one-way platforms.

#### Scenario: Player crosses a one-way platform upward
- **WHEN** a player jumps into a one-way platform from below
- **THEN** the player passes through it and can land on it from above

#### Scenario: Player drops through a one-way platform
- **WHEN** a player invokes the existing down-and-jump action while standing on a one-way platform
- **THEN** the player passes downward through that platform

#### Scenario: Solid terrain contact
- **WHEN** a player or balloon contacts solid arena terrain
- **THEN** the terrain blocks movement according to its collision geometry

### Requirement: Arena world boundaries
Each arena SHALL define playable bounds that constrain players and the balloon and inform camera limits.

#### Scenario: Entity reaches a horizontal boundary
- **WHEN** a player or balloon reaches the left or right edge of the playable bounds
- **THEN** it remains within the arena according to the configured boundary behavior

#### Scenario: Camera follows within arena bounds
- **WHEN** the shared camera follows players and balloon
- **THEN** its view remains constrained to the active arena bounds

### Requirement: Scalable arena dimensions
The arena system SHALL support maps with different world dimensions and spawn positions without hard-coded map-specific behavior in gameplay systems.

#### Scenario: Larger arena is loaded
- **WHEN** an arena with larger bounds than the default map is selected
- **THEN** the active playable world and camera limits use those larger bounds

### Requirement: Extensible terrain properties
Arena terrain definitions SHALL allow future gameplay properties to be added without changing the behavior of ordinary solid and one-way surfaces.

#### Scenario: Terrain has no special property
- **WHEN** a tile has no gameplay property configured
- **THEN** it behaves as ordinary terrain of its configured collision type
