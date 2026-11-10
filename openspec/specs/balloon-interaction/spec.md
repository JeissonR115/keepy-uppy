# balloon-interaction Specification

## Purpose

Defines how the balloon interacts with players and the arena so its motion remains readable, recoverable, and central to two-player competition.

## Requirements

### Requirement: Predictable balloon motion
The balloon SHALL move under configurable lightweight physics, interact with the arena, and report contact with the scoring ground.

#### Scenario: Balloon moves and rebounds
- **WHEN** the balloon is in play and receives gravity or a valid hit
- **THEN** it moves and rebounds according to the configured physics parameters without unbounded speed

#### Scenario: Balloon reaches the ground
- **WHEN** the balloon makes contact with the designated scoring ground
- **THEN** one ground-contact event is reported for the current round

### Requirement: Valid player hits
The balloon SHALL receive a configurable impulse from valid player contacts, with impulse direction and strength reflecting the contact.

#### Scenario: Player contacts the balloon
- **WHEN** a player makes a valid body contact with the balloon
- **THEN** the balloon receives one readable impulse based on the contact direction and configured hit strength

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

### Requirement: Priority-aware player interference
The game SHALL maintain one player priority state that changes after a valid balloon contact and SHALL use that state to configure relative player-displacement strength. An opening coin toss SHALL assign the first serve and priority, and simultaneous contacts SHALL resolve by the approved priority policy.

#### Scenario: Initial server is selected
- **WHEN** a match begins and the opening coin toss is heads or tails
- **THEN** Player 1 serves and receives opening priority on heads, and Player 2 does so on tails

#### Scenario: Previous point winner serves
- **WHEN** a point is awarded and the next round begins
- **THEN** the player awarded that point serves and receives opening priority

#### Scenario: Player earns priority
- **WHEN** a player's normal hit or dash rescue is accepted as a valid balloon contact
- **THEN** that player becomes the priority player for the next dispute

#### Scenario: Dash rescue coincides with a normal hit
- **WHEN** a valid dash rescue and a normal hit occur during the same physics tick
- **THEN** the dash rescue determines priority for that tick

#### Scenario: Same-kind contacts occur simultaneously
- **WHEN** both players produce valid contacts of the same kind during one physics tick
- **THEN** the player who did not hold priority before that tick receives priority

#### Scenario: Players push or obstruct one another
- **WHEN** the priority player and the other player collide or one dashes into the other
- **THEN** the priority player's configured displacement effect is stronger while both players retain movement

#### Scenario: Priority changes
- **WHEN** the priority player changes
- **THEN** the new priority state is available to presentation so players can identify the advantage
