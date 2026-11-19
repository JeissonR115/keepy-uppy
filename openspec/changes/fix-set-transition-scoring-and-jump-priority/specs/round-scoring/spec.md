# Spec Delta

## MODIFIED Requirements

### Requirement: Ground-contact scoring
When the balloon reaches the scoring ground during an active round, the game SHALL award exactly one point to the last valid player to touch the balloon; if there was no valid touch, it SHALL award the point to the opponent of the round's opening server.

#### Scenario: Ground contact produces a point
- **WHEN** the balloon touches the scoring ground after Player 1 was the last valid toucher
- **THEN** Player 1 receives exactly one point because Player 2 did not rescue the balloon

#### Scenario: No player touched the balloon
- **WHEN** the balloon touches the scoring ground and neither player made a valid touch during the round
- **THEN** the opponent of the opening server receives exactly one point

#### Scenario: Duplicate ground notifications
- **WHEN** additional ground contacts are reported while the same round is resolving
- **THEN** they do not award additional points

### Requirement: Round restart
The game SHALL display the round result during a configurable short intermission, then reset round entities while retaining the match score unless the match has ended.

#### Scenario: Begin a subsequent round
- **WHEN** the configured intermission ends and no player has reached the match target
- **THEN** pending contacts are cleared, players are repositioned, and their placement is allowed to settle before the balloon is placed and enabled for the next serve

#### Scenario: Begin a new set
- **WHEN** a set ends but the match is not complete
- **THEN** the next set uses the same staged reset, and no contact at the previous set's positions is counted as a touch of the new serve

#### Scenario: Match ends during scoring
- **WHEN** the awarded point brings a player's score to the configured target and the match is complete
- **THEN** the winner is displayed and no subsequent round or serve starts
