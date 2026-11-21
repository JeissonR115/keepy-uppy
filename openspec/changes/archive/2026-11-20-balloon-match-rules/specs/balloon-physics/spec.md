# Spec Delta

## Purpose

Defines bounded balloon motion and readable responses to player and arena contacts. The balloon remains light, recoverable, and predictable during a competitive point.

## ADDED Requirements

### Requirement: Configurable bounded balloon motion
The balloon SHALL expose configurable vertical force, horizontal resistance, horizontal and vertical speed limits, and arena rebound strength.

#### Scenario: Balloon moves within configured bounds
- **WHEN** gravity or a valid player impact changes balloon motion
- **THEN** the balloon moves and rebounds while remaining within its configured horizontal and vertical speed limits

#### Scenario: Balloon contacts arena boundaries
- **WHEN** the balloon contacts a platform or arena boundary
- **THEN** it rebounds according to the configured bounce response and loses motion according to horizontal resistance

### Requirement: Valid balloon contacts
The game SHALL identify the player and contact type for each accepted normal or dash-rescue contact, apply one direction-aware impact within configured limits, and enforce the configured minimum interval between repeat contacts.

#### Scenario: Normal player contact
- **WHEN** a player makes an eligible body contact outside that player's repeat-contact interval
- **THEN** the balloon receives one impulse that reflects contact direction and speed and stays within configured impact limits

#### Scenario: Dash rescue contact
- **WHEN** the balloon enters the active dash rescue zone outside the repeat-contact interval
- **THEN** the balloon receives one rescue impulse that accounts for the dash direction and is reported as a dash-rescue contact

#### Scenario: Contact repeats too soon
- **WHEN** the same player attempts another contact before the configured minimum interval expires
- **THEN** that contact does not apply another impact or update match attribution

### Requirement: Single scoring-ground event
The balloon SHALL report no more than one scoring-ground contact for each active point.

#### Scenario: Balloon touches scoring ground
- **WHEN** the balloon first touches the designated scoring ground during an active point
- **THEN** one ground-contact event is reported to the match state

#### Scenario: Balloon remains on or re-enters ground
- **WHEN** further ground contacts occur while the point is resolving
- **THEN** no additional ground-contact event is reported for that point
