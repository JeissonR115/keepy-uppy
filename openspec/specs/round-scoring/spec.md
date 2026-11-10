# round-scoring Specification

## Purpose

Defines the match and round lifecycle for two local players, including the ground-contact outcome, score display, restart, and configurable victory threshold.

## Requirements

### Requirement: Two-player match state
The game SHALL manage exactly two local players and expose whether a round is active, resolving, or the match is complete.

#### Scenario: Start a match
- **WHEN** the main game scene starts
- **THEN** a new match begins with two players, a balloon, and initialized round and score state

#### Scenario: Resolve a round
- **WHEN** the balloon reaches the scoring ground during active play
- **THEN** the round stops accepting gameplay outcomes while its result is resolved

### Requirement: Ground-contact scoring
When the balloon reaches the scoring ground during an active round, the game SHALL award exactly one point to the opponent of the last valid player to touch the balloon; if there was no valid touch, it SHALL award the point to the opponent of the round's opening server.

#### Scenario: Ground contact produces a point
- **WHEN** the balloon touches the scoring ground after Player 1 was the last valid toucher
- **THEN** Player 2 receives exactly one point

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
- **THEN** the round state resets and play resumes with the existing match score

#### Scenario: Match ends during scoring
- **WHEN** the awarded point brings a player's score to the configured target
- **THEN** the winner is displayed and no subsequent round starts

### Requirement: Configurable match victory
The match SHALL use a configurable target score and stop normal play when either player reaches it.

#### Scenario: A player reaches the target
- **WHEN** a player's score reaches the configured target
- **THEN** that player is declared the match winner and another round does not start

#### Scenario: Scores are below the target
- **WHEN** a round ends and neither player has reached the configured target
- **THEN** the match remains available for another round

### Requirement: Visible score
The game SHALL display the current score for both players and update it when a round point is awarded.

#### Scenario: Score changes
- **WHEN** a point is awarded
- **THEN** the visible scoreboard shows the updated score for both players

#### Scenario: Match ends
- **WHEN** a player wins the match
- **THEN** the visible match state identifies the winner
