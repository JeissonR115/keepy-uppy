# Spec Delta

## MODIFIED Requirements

### Requirement: Predictable balloon motion
The balloon SHALL move under configurable floaty physics, interact with the floor and arena boundaries, and report contact with the scoring ground.

#### Scenario: Balloon floats within configured bounds
- **WHEN** the balloon is in play between player contacts
- **THEN** its configurable gravity and air resistance produce a visibly slower, more sustained fall while its speed remains bounded

#### Scenario: Balloon responds to a valid hit
- **WHEN** a valid player contact changes balloon motion
- **THEN** the balloon follows the configured contact impulse and remains within its horizontal and vertical speed limits

#### Scenario: Balloon reaches the floor
- **WHEN** the balloon first makes contact with the scoring floor during a point
- **THEN** one ground-contact event is reported and a balloon burst effect is shown

### Requirement: Valid player hits
The balloon SHALL receive one configurable impulse from an eligible player contact, with launch direction and strength reflecting the player's velocity and contact direction.

#### Scenario: Player moves into the balloon
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
