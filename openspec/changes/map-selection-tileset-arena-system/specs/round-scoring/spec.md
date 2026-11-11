# Spec Delta

## MODIFIED Requirements

### Requirement: Ground-contact scoring
When the balloon reaches a surface explicitly designated as scoring ground during an active round, the game SHALL award exactly one point to the opponent of the last valid player to touch the balloon; if there was no valid touch, it SHALL award the point to the opponent of the round's opening server. Contact with a non-scoring platform SHALL NOT end the round.

#### Scenario: Ground contact produces a point
- **WHEN** the balloon touches a scoring surface after Player 1 was the last valid toucher
- **THEN** Player 2 receives exactly one point

#### Scenario: No player touched the balloon
- **WHEN** the balloon touches a scoring surface and neither player made a valid touch during the round
- **THEN** the opponent of the opening server receives exactly one point

#### Scenario: Duplicate ground notifications
- **WHEN** additional scoring-surface contacts are reported while the same round is resolving
- **THEN** they do not award additional points

#### Scenario: Balloon lands on a non-scoring platform
- **WHEN** the balloon contacts an arena platform that is not designated as scoring ground
- **THEN** the round remains active and no point is awarded
