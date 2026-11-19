# Spec Delta

## Purpose

Define la composición mínima de las arenas nuevas, su encuadre seguro y la correspondencia de sus vistas previas con el mapa que se juega.

## ADDED Requirements

### Requirement: Primary compact arena
The arena catalog SHALL provide a 320 × 180 primary arena with a visible floor and no visible platforms or other gameplay surfaces, and SHALL select it as the default arena.

#### Scenario: Match starts without a prior arena selection
- **WHEN** a new match starts without an arena selected
- **THEN** the 320 × 180 primary arena loads with only its floor visible and invisible boundaries keeping gameplay entities in frame

### Requirement: Safe gameplay margins
Every selectable arena SHALL define a configurable safe margin that keeps players, the balloon, and interactive arena elements within the visible play area.

#### Scenario: Entity reaches the safe margin
- **WHEN** a player or balloon moves toward an arena edge
- **THEN** the arena boundary prevents its gameplay footprint from leaving the visible play area

#### Scenario: Arena contains an interactive element near an edge
- **WHEN** an arena is loaded with trampolines, spikes, or fans
- **THEN** those elements remain within the arena's configured safe margin and are not clipped by the camera

### Requirement: Arena preview reflects map content
Each selectable arena SHALL have a preview that represents its current geometry and interactive elements.

#### Scenario: Arena layout changes
- **WHEN** an arena's floor, platforms, or interactive elements change
- **THEN** its selector preview is updated to reflect the changed layout

#### Scenario: New arenas are added
- **WHEN** the primary and secondary new arenas are registered in the catalog
- **THEN** both are selectable with previews corresponding to their layouts
