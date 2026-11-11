# Spec Delta

## Purpose

Define cómo el juego describe y descubre las arenas disponibles mediante datos consistentes para selección, carga y configuración de la partida.

## ADDED Requirements

### Requirement: Arena metadata
The game SHALL represent each selectable arena with a stable identifier, player-facing name, description, preview, playable bounds, player spawn positions, and playable scene reference.

#### Scenario: Arena is registered
- **WHEN** an arena is added to the catalog with valid metadata and a playable scene
- **THEN** the catalog exposes it as a selectable arena with those values

#### Scenario: Arena identifier is duplicated
- **WHEN** two registered arenas use the same identifier
- **THEN** the catalog rejects or excludes the duplicate and reports it for correction

### Requirement: Arena-specific gameplay settings
The catalog SHALL provide optional arena-specific physics adjustments with neutral defaults that preserve current gameplay when no adjustment is configured.

#### Scenario: Arena uses default physics
- **WHEN** a selected arena omits gameplay adjustments
- **THEN** the balloon and players use their existing movement and physics behavior

#### Scenario: Arena configures physics adjustments
- **WHEN** a selected arena defines supported balloon or player adjustments
- **THEN** those adjustments are available to the match setup for that arena only

### Requirement: Catalog discovery
The game SHALL expose all valid registered arenas in a deterministic order and SHALL not require changes to menu logic when an arena is added.

#### Scenario: New arena is added
- **WHEN** a valid arena resource is registered
- **THEN** it appears in the available arena list without adding a map-specific menu branch
