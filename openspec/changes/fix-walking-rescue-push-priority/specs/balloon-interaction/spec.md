# Spec Delta

## MODIFIED Requirements

### Requirement: Priority-aware player interference
The game SHALL maintain contact priority to resolve competing balloon contacts and SHALL favor the player expected to rescue the balloon when applying relative displacement strength. An opening coin toss SHALL assign the first serve and contact priority, and simultaneous contacts SHALL resolve by the approved priority policy.

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
- **WHEN** the players collide while walking or one player dashes into the other
- **THEN** the expected rescuer applies the stronger configured displacement effect when initiating the collision, the other player applies the normal configured effect, and both retain movement

#### Scenario: Player 1 is the expected rescuer
- **WHEN** Player 1 initiates a collision with Player 2 while walking or dashing and Player 1 is expected to rescue the balloon
- **THEN** Player 1 applies the stronger configured displacement effect regardless of contact priority

#### Scenario: Player 2 is the expected rescuer
- **WHEN** Player 2 initiates a collision with Player 1 while walking or dashing and Player 2 is expected to rescue the balloon
- **THEN** Player 2 applies the stronger configured displacement effect regardless of contact priority

#### Scenario: Collision is reported by both players
- **WHEN** the same player collision is reported by both participants during one physics tick
- **THEN** its displacement effect is applied only once

#### Scenario: Priority changes
- **WHEN** the contact-priority player changes
- **THEN** the new contact priority remains available to presentation independently of which player is expected to rescue the balloon
