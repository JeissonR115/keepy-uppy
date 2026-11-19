# Spec Delta

## ADDED Requirements

### Requirement: Spike hazard awards the point to the opponent
When the balloon explodes on spikes during an active round, the game SHALL award exactly one point to the opponent of the last valid player to touch the balloon; if there was no valid touch, it SHALL use the existing no-touch scoring rule.

#### Scenario: Last toucher sends the balloon into spikes
- **WHEN** the balloon touches spikes after Player 1 made the last valid touch
- **THEN** the balloon explodes and Player 2 receives exactly one point

#### Scenario: No player touched the balloon before spikes
- **WHEN** the balloon touches spikes without a valid player touch during the round
- **THEN** the balloon explodes and the existing no-touch scoring rule awards exactly one point

#### Scenario: Spike contact repeats while the round resolves
- **WHEN** additional spike contacts are reported for the same resolving round
- **THEN** they do not award additional points
