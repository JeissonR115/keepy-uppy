# Spec Delta

## MODIFIED Requirements

### Requirement: Readable gameplay feedback
The game SHALL visually distinguish the players' movement states, balloon impacts, dash activity, and current priority without requiring audio.

#### Scenario: Player movement state changes
- **WHEN** a player is idle, running, rising, falling, climbing, sliding on a wall, or dashing
- **THEN** the player's animated sprite communicates the corresponding movement state

#### Scenario: Player body animations advance
- **WHEN** a body animation with multiple frames is selected
- **THEN** its frames advance at the configured animation rate instead of remaining frozen on one frame

#### Scenario: Player one-shot animation completes
- **WHEN** a jump or climb-entry one-shot reaches its final frame
- **THEN** playback completion releases the one-shot state so the next movement-state animation can play

#### Scenario: Balloon or player interaction occurs
- **WHEN** the balloon is hit, a dash rescue occurs, or priority changes
- **THEN** visible feedback communicates the interaction and identifies the priority player

#### Scenario: Player action effects
- **WHEN** a player performs an action represented by an available action-effect animation
- **THEN** the corresponding visual effect appears in sync with that action and does not alter collision behavior

#### Scenario: Distinguish the second player
- **WHEN** both players are visible
- **THEN** player 2 uses the same body and action-effect animations with a subtle orange tint, while player 1 retains the base sprite colors
