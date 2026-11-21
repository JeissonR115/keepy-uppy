# Spec Delta

## Purpose

Defines a bounded additional balloon rescue opportunity created by active dash afterimages after the primary dash rescue.

## ADDED Requirements

### Requirement: Allow one additional rescue from an active dash trail
After a primary dash rescue succeeds, an active dash afterimage SHALL be able to produce one additional valid balloon rescue without being blocked by the cooldown created by the primary rescue.

#### Scenario: Rescue through a dash afterimage
- **WHEN** a player has completed a successful primary dash rescue and the armed balloon contacts one of that dash's active afterimages
- **THEN** the afterimage applies one additional dash rescue

#### Scenario: Ignore only the primary rescue cooldown
- **WHEN** the additional afterimage contact occurs during the cooldown created by the primary dash rescue
- **THEN** that cooldown does not prevent the additional rescue while other balloon-contact eligibility checks remain in effect

### Requirement: Limit the additional trail rescue to once per dash
The game SHALL accept no more than one successful balloon rescue through all afterimages created by a single dash.

#### Scenario: Multiple afterimages overlap the balloon
- **WHEN** another afterimage from the same dash contacts the balloon after the additional rescue has succeeded
- **THEN** no further rescue is applied

#### Scenario: A new dash begins
- **WHEN** the player starts another dash
- **THEN** one new afterimage rescue opportunity is available for that dash
