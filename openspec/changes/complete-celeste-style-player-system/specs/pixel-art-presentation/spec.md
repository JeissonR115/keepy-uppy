# Spec Delta

## MODIFIED Requirements

### Requirement: Readable gameplay feedback
The game SHALL visually distinguish each player's movement states, balloon impacts, dash activity, and current priority without requiring audio, while keeping each player's identity readable when both are visible.

#### Scenario: Player movement state changes
- **WHEN** a player is idle, running, rising, falling, wall-sliding, wall-jumping, or dashing
- **THEN** the player's visual state communicates the corresponding movement state

#### Scenario: Balloon or player interaction occurs
- **WHEN** the balloon is hit, a dash rescue occurs, or priority changes
- **THEN** visible feedback communicates the interaction and identifies the priority player

#### Scenario: Both players are visible
- **WHEN** P1 and P2 appear in the same view with different visual profiles
- **THEN** each remains distinguishable and their animation direction follows their own movement state

## ADDED Requirements

### Requirement: Player-specific visual profiles
The game SHALL support independent visual profiles for P1 and P2 while deriving animation state from their shared gameplay state and keeping appearance separate from physical properties.

#### Scenario: P1 selects its visual profile
- **WHEN** P1 is instantiated in an arena
- **THEN** it uses its configured P1 sprite frames and animation mapping

#### Scenario: P2 selects its visual profile
- **WHEN** P2 is instantiated in an arena
- **THEN** it uses its configured P2 sprite frames and animation mapping without changing movement parameters or collision geometry

#### Scenario: Visual asset rights are unresolved
- **WHEN** a reference asset lacks documented permission or license terms applicable to this project
- **THEN** that asset is not redistributed or imported and the profile uses cleared owner-supplied or original replacement art

### Requirement: Procedural P2 hair follows movement
P2 SHALL present procedural hair that follows its visual anchor and responds to movement while remaining cosmetic and outside gameplay collision detection.

#### Scenario: P2 accelerates or changes direction
- **WHEN** P2 gains speed, brakes, reverses direction, or turns in place
- **THEN** the hair trails and settles in a manner consistent with the change in velocity and facing

#### Scenario: P2 jumps, falls, or dashes
- **WHEN** P2 jumps, rises, falls, lands, or dashes
- **THEN** hair motion reacts to the corresponding movement and dash impulse and returns to stable follow behavior afterward

#### Scenario: Hair simulation receives an invalid or reset state
- **WHEN** P2 is reset for a round or hair simulation receives invalid positional data
- **THEN** the hair returns to valid anchor-relative geometry without affecting the player body or match state

#### Scenario: Hair overlaps terrain or players
- **WHEN** rendered hair overlaps arena geometry, the balloon, or another player
- **THEN** it creates no physical collision, balloon contact, or match event
