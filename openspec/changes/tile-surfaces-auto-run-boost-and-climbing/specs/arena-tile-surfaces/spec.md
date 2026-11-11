# Spec Delta

## Purpose

Define cómo los tiles de una arena distinguen superficies de puntuación, paso, rebote y escalada para que los mapas puedan combinar estas mecánicas sin lógica específica por arena.

## ADDED Requirements

### Requirement: Tile surfaces declare gameplay roles
Arena tiles used for collision SHALL have a consistent role that determines which entities collide with them and what gameplay response they trigger.

#### Scenario: Map uses a scoring floor
- **WHEN** the balloon contacts a tile designated as scoring floor
- **THEN** it produces the scoring-ground contact response for the current round

#### Scenario: Balloon reaches a pass-through platform
- **WHEN** the balloon reaches a one-way player platform
- **THEN** it passes through without triggering a scoring-ground response

#### Scenario: Player stands on a pass-through platform
- **WHEN** a player lands on a one-way platform from above
- **THEN** the player can stand on it, jump upward through it, and drop through it

#### Scenario: Balloon contacts a trampoline
- **WHEN** the balloon contacts a trampoline tile
- **THEN** the balloon rebounds upward without triggering scoring-ground contact

#### Scenario: Player contacts a trampoline
- **WHEN** a player lands on a trampoline tile
- **THEN** the player receives an upward bounce without taking damage or ending the round

#### Scenario: Player contacts a climbable wall
- **WHEN** a player holds the existing grab action while adjacent to a climbable wall
- **THEN** the player can climb according to the configured climbing stamina and movement rules

#### Scenario: Ordinary solid arena tile
- **WHEN** a solid tile is not designated as scoring floor, trampoline, or climbable wall
- **THEN** it blocks entities according to its configured collision role without awarding a point by itself
