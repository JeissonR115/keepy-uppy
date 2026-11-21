# Spec Delta

## Purpose

Defines point, set, and match progression for local two-player play. The scoreboard presents both the current set score and the accumulated match result.

## ADDED Requirements

### Requirement: Resolve each point once
The game SHALL resolve one point when the balloon first contacts the scoring ground during active play and SHALL ignore later ground notifications for that point.

#### Scenario: First ground contact ends a point
- **WHEN** the balloon first touches the scoring ground during an active point
- **THEN** gameplay outcomes stop and exactly one point result is resolved

#### Scenario: Duplicate ground event arrives
- **WHEN** another ground-contact notification arrives while that point is resolving
- **THEN** neither player receives an additional point

### Requirement: Last-touch point attribution
The game SHALL award the point to the opponent of the last valid toucher; the serve SHALL count as the server's first valid touch of that point. The owner confirmed that a serve is a contact, so a point never falls without an attributed touch.

#### Scenario: Last valid toucher is faulted
- **WHEN** the balloon touches the scoring ground after an accepted player contact
- **THEN** the opponent of the last valid toucher receives the point

#### Scenario: Serve is the last touch
- **WHEN** the balloon reaches the ground before either player makes another valid contact after the serve
- **THEN** the point is awarded to the opponent of the server

### Requirement: Set and match progression
Each set SHALL be won by the first player to reach five points, and the match SHALL be won by the first player to win three sets, without requiring a two-point lead.

#### Scenario: Player wins a set
- **WHEN** a player reaches five points in the current set
- **THEN** that player receives one set win, the current set points reset to zero, and the match score remains intact

#### Scenario: Match remains active after a set
- **WHEN** a set ends and neither player has won three sets
- **THEN** the next set begins without another coin toss and its first server is the winner of the final point of the previous set

#### Scenario: Match ends
- **WHEN** a player wins a third set
- **THEN** the match ends, identifies that player as match winner, and does not start another point or set

#### Scenario: Set reaches four points each
- **WHEN** both players have four points in a set
- **THEN** the winner of the next point wins that set

### Requirement: Display competitive match state
The game SHALL display current points, sets won, next server, priority player, coin-toss result, point and set results, and match winner.

#### Scenario: Competitive state changes
- **WHEN** a point, set, server, priority, coin toss, or match result changes
- **THEN** the visible interface displays the corresponding current state and result without obscuring the balloon or players
