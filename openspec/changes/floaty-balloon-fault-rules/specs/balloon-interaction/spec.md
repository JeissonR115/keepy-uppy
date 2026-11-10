# Spec Delta

## MODIFIED Requirements

### Requirement: Predictable balloon motion
The balloon SHALL move under configurable floaty physics, interact with the floor and arena boundaries, and report contact with the scoring ground.

#### Scenario: Balloon moves and rebounds
- **WHEN** the balloon is in play and receives gravity or a valid hit
- **THEN** configurable gravity and air resistance produce a visibly slower, more sustained fall and it rebounds within configured horizontal and vertical speed limits

#### Scenario: Balloon responds to a valid hit
- **WHEN** a valid player contact changes balloon motion
- **THEN** the balloon follows the configured contact impulse and remains within its horizontal and vertical speed limits

#### Scenario: Balloon reaches the ground
- **WHEN** the balloon first makes contact with the scoring floor during a point
- **THEN** one ground-contact event is reported and a balloon burst effect is shown

### Requirement: Valid player hits
The balloon SHALL receive one configurable impulse from an eligible player contact, with launch direction and strength reflecting the player's velocity and contact direction.

#### Scenario: Player contacts the balloon
- **WHEN** an eligible player contacts the balloon while moving
- **THEN** the launch responds to the player's movement direction and speed as well as the contact direction, within configured impulse and velocity limits

#### Scenario: Player makes a downward-directed hit
- **WHEN** a player's contact would send the balloon downward
- **THEN** the contact is reported as a downward-hit fault for match resolution

#### Scenario: Dash rescue contact
- **WHEN** an eligible dash rescue contacts the balloon
- **THEN** one rescue impulse considers the dash direction and player movement and reports the contact for turn resolution

#### Scenario: Contact repeats too soon
- **WHEN** the same player attempts another contact before the configured minimum interval expires
- **THEN** no additional impulse or contact report is produced

### Requirement: Priority-aware player interference
The game SHALL maintain one player priority state that changes after a valid balloon contact and SHALL use that state to configure relative player-displacement strength. An opening coin toss SHALL assign the first serve and priority, and alternating-turn eligibility SHALL be resolved before priority for simultaneous contacts.

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
- **WHEN** an expected player's dash rescue and normal hit are both reported during the same physics tick
- **THEN** the dash-rescue contact determines that player's attribution and priority for the tick

#### Scenario: Same-kind contacts occur simultaneously
- **WHEN** both players report the same kind of contact during one physics tick
- **THEN** any player who was out of turn at the start of that tick commits a fault, independent of callback order

#### Scenario: Players push or obstruct one another
- **WHEN** the priority player and the other player collide or one dashes into the other
- **THEN** the priority player's configured displacement effect is stronger while both players retain movement

#### Scenario: Priority changes
- **WHEN** the priority player changes
- **THEN** the new priority state is available to presentation so players can identify the advantage
