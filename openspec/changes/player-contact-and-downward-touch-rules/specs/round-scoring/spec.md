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

#### Scenario: Ground contact during downward warning
- **WHEN** the balloon reaches the scoring ground while the downward warning is active
- **THEN** the active downward-touch fault is recorded and its existing consecutive-fault penalty policy is applied

#### Scenario: Ground contact after downward warning expires
- **WHEN** the balloon reaches the scoring ground after a downward warning has expired without another touch
- **THEN** the point is awarded to the last valid toucher because the opponent failed to rescue the balloon

#### Scenario: Opponent rescues during downward warning
- **WHEN** the opponent of the player who made the downward hit touches the balloon during the warning
- **THEN** the warning ends, the rescue is recorded as a valid touch, and play continues under the normal turn rules

### Requirement: Round restart
The game SHALL display the round result during a configurable short intermission, then reset round entities while retaining the match score unless the match has ended.

#### Scenario: Begin a subsequent round
- **WHEN** the configured intermission ends and no player has reached the match target
- **THEN** players are repositioned and gameplay input is cleared, their placement is allowed to settle, and only then is the balloon placed and enabled for the next serve

#### Scenario: Match ends during scoring
- **WHEN** the awarded point brings a player's score to the configured target
- **THEN** the winner is displayed and no subsequent round starts
