# Spec Delta

## Purpose

Define interacciones físicas reutilizables entre las arenas y sus elementos especiales, manteniendo configurables las fuerzas y claros sus efectos para la partida.

## ADDED Requirements

### Requirement: Trampoline launches players and balloon
Arena trampolines SHALL launch players and the balloon away from the contacted surface using a configurable rebound strength.

#### Scenario: Player lands on a trampoline
- **WHEN** a player contacts a trampoline from above during active play
- **THEN** the trampoline launches the player upward without changing horizontal movement or causing a balloon hit

#### Scenario: Balloon contacts a trampoline
- **WHEN** the balloon contacts a trampoline
- **THEN** the trampoline launches the balloon according to its configured rebound strength

### Requirement: Spikes trigger balloon hazard
Arena spikes SHALL detect balloon contact, visibly explode the balloon, and report one hazard event for the active round.

#### Scenario: Balloon touches spikes during an active round
- **WHEN** the balloon contacts spikes while a round is active
- **THEN** a visible balloon explosion occurs and exactly one spike hazard event is reported for that round

#### Scenario: Spike contact repeats during resolution
- **WHEN** the balloon remains in contact with spikes after a hazard event has been reported
- **THEN** no additional hazard events are reported for the resolving round

### Requirement: Fans create balloon-only air currents
Fans SHALL apply a configurable directional force to the balloon while it is inside their airflow region and SHALL NOT apply that force to players.

#### Scenario: Balloon enters fan airflow
- **WHEN** the balloon enters or remains inside a fan's airflow region
- **THEN** its velocity changes according to the fan's configured direction and strength

#### Scenario: Player enters fan airflow
- **WHEN** a player enters or remains inside a fan's airflow region
- **THEN** the fan does not alter the player's velocity

#### Scenario: Fan settings are changed
- **WHEN** an arena configures a fan's direction, strength, or airflow range
- **THEN** only the balloon behavior in that fan region uses those settings
