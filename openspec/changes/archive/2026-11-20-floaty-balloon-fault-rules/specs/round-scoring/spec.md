# Spec Delta

## MODIFIED Requirements

### Requirement: Ground-contact scoring
When the balloon reaches the scoring ground during an active round, the game SHALL award exactly one point to the opponent of the last valid player to touch the balloon; the server's serve SHALL count as that round's first contact.

#### Scenario: Ground contact produces a point
- **WHEN** the balloon touches the scoring ground after Player 1 was the last valid toucher
- **THEN** Player 2 receives exactly one point

#### Scenario: Serve counts as first contact
- **WHEN** Player 1 serves and no subsequent rally contact occurs before the balloon reaches the ground
- **THEN** the serve is treated as Player 1's first contact and Player 2 receives exactly one point

#### Scenario: No player touched the balloon
- **WHEN** the balloon touches the scoring ground before the opening server makes a serve contact
- **THEN** the opponent of the opening server receives exactly one point

#### Scenario: Duplicate ground notifications
- **WHEN** additional ground contacts are reported while the same round is resolving
- **THEN** they do not award additional points

### Requirement: Round restart
The game SHALL display the round result during a configurable short intermission, then reset round entities while retaining the match score unless the match has ended.

#### Scenario: Begin a subsequent round
- **WHEN** the configured intermission ends and no player has reached the match target
- **THEN** the round state resets, the balloon is positioned above the next server (the previous point winner), and play resumes with the existing match score

#### Scenario: Match ends during scoring
- **WHEN** the awarded point brings a player's score to the configured target
- **THEN** the winner is displayed and no subsequent round starts

### Requirement: Configurable match victory
The match SHALL use a configurable target score and stop normal play when either player reaches it.

#### Scenario: A player reaches the target
- **WHEN** a player's score reaches the configured target
- **THEN** that player is declared the match winner and another round does not start

#### Scenario: Scores are below the target
- **WHEN** a round ends and neither player has reached the match target
- **THEN** the match remains available for another round

### Requirement: Visible score
The game SHALL display the current score for both players and update it when a round point is awarded.

#### Scenario: Score changes
- **WHEN** a point is awarded
- **THEN** the visible scoreboard shows the updated score for both players

#### Scenario: Match ends
- **WHEN** a player wins the match
- **THEN** the visible match state identifies the winner

## ADDED Requirements

### Requirement: Alternating balloon contacts
The game SHALL allow only the player whose turn is active to make a valid balloon contact, beginning with the server's serve and alternating after every valid normal or dash-rescue contact.

#### Scenario: Server serves
- **WHEN** a new round begins
- **THEN** the balloon appears above the server and the server is the first eligible player; the server's accepted serve counts as the first contact and makes the opponent the next eligible player

#### Scenario: Eligible player contacts the balloon
- **WHEN** the expected player makes an accepted normal or dash-rescue contact
- **THEN** the contact updates last-touch attribution and the other player becomes eligible for the next contact

#### Scenario: Player touches out of turn
- **WHEN** a player contacts the balloon while the other player is expected to touch it
- **THEN** the contact is a fault, the rally ends, and the expected player receives exactly one point

### Requirement: Downward-hit fault scoring
The game SHALL award exactly one point to a player's opponent when that player's contact sends the balloon downward.

#### Scenario: Player sends balloon downward
- **WHEN** a player's hit or dash rescue produces a downward-directed balloon launch
- **THEN** that player commits a fault, the rally ends, and the opponent receives exactly one point

### Requirement: Fault resolution
Out-of-turn and downward-hit faults SHALL resolve as point results without waiting for a ground contact and SHALL use the normal round, set, and match progression.

#### Scenario: Fault ends a rally
- **WHEN** either fault is detected during an active round
- **THEN** gameplay outcomes stop and the rally awards one point to the opponent of the player who committed the fault

#### Scenario: Ground contact ends a rally
- **WHEN** a balloon reaches the scoring floor after valid contacts
- **THEN** the last valid toucher is faulted, the opponent receives one point, and the floor burst is shown
