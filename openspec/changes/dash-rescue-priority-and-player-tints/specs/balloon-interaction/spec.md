# Spec Delta

## MODIFIED Requirements

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
- **THEN** that player becomes the priority player for resolving contacts and player interference until the next valid contact changes that state

#### Scenario: Dash rescue coincides with a normal hit
- **WHEN** a valid dash rescue and a normal hit occur during the same physics tick
- **THEN** the dash rescue determines contact priority for that tick

#### Scenario: Same-kind contacts occur simultaneously
- **WHEN** both players produce valid contacts of the same kind during one physics tick
- **THEN** the player who did not hold priority before that tick receives priority

#### Scenario: Players push or obstruct one another
- **WHEN** the players collide or one player dashes into the other
- **THEN** the applicable configured displacement effect is applied while both players retain movement

#### Scenario: Rescuer dashes into the opponent
- **WHEN** the player expected to rescue the balloon dashes into the other player
- **THEN** the rescuer's configured displacement effect is stronger for that dash, independently of which player last earned contact priority

#### Scenario: Non-rescuer dashes into the opponent
- **WHEN** the player not expected to rescue the balloon dashes into the other player
- **THEN** the configured non-rescuer displacement effect applies

#### Scenario: Priority changes
- **WHEN** the priority player changes
- **THEN** the new priority state is available to presentation so players can identify the advantage
