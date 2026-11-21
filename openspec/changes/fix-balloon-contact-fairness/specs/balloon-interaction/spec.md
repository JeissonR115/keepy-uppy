# Spec Delta

## MODIFIED Requirements

### Requirement: Dash rescue zone
Each dash SHALL create a temporary, configurable balloon-interaction zone associated with the dash trajectory, separate from its visual trail, and SHALL produce at most one rescue hit per dash activation.

#### Scenario: Balloon enters an active dash zone
- **WHEN** the balloon contacts the zone during its active interval and that dash activation has not rescued it
- **THEN** the balloon receives one rescue impulse that takes the dash direction into account

#### Scenario: One dash overlaps the balloon repeatedly
- **WHEN** the same dash activation remains in contact with or re-enters the balloon
- **THEN** that activation does not apply additional rescue hits

#### Scenario: Dash zone and afterimage both overlap the balloon
- **WHEN** the balloon contacts both the active dash zone and one or more afterimages from the same dash activation
- **THEN** at most one rescue impulse is applied across all of those contacts

#### Scenario: Trail and interaction are presented
- **WHEN** a dash is displayed
- **THEN** its visual trail can be rendered independently of the interaction zone and does not create an additional rescue hit

## ADDED Requirements

### Requirement: Fault visual feedback
The balloon SHALL provide a brief white flash when a gameplay fault is confirmed, then return to its regular appearance without changing the match's fault-resolution outcome.

#### Scenario: Confirmed gameplay fault
- **WHEN** the match confirms a gameplay fault
- **THEN** the balloon visibly flashes white and then returns to its regular appearance
