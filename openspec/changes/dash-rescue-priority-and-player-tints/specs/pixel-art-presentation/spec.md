# Spec Delta

## MODIFIED Requirements

### Requirement: Readable gameplay feedback
The game SHALL visually distinguish the players' movement states, balloon impacts, dash activity, current contact priority, and the player expected to rescue the balloon without requiring audio.

#### Scenario: Player movement state changes
- **WHEN** a player is idle, running, rising, falling, or dashing
- **THEN** the player's visual state communicates the corresponding movement state

#### Scenario: Balloon or player interaction occurs
- **WHEN** the balloon is hit, a dash rescue occurs, or contact priority changes
- **THEN** visible feedback communicates the interaction and identifies the player with contact priority

#### Scenario: Rescuer changes
- **WHEN** the player expected to rescue the balloon changes
- **THEN** a clearly visible triangle above that player identifies the current rescuer

## ADDED Requirements

### Requirement: Distinct blue player tints
The game SHALL apply blue tints to both players while preserving recognizable character details, with Player 2's blue tint visibly stronger than Player 1's.

#### Scenario: Players appear in the arena
- **WHEN** both player characters are displayed
- **THEN** Player 1 has a blue tint and Player 2 has a more intense blue tint, and their silhouettes and animations remain readable
