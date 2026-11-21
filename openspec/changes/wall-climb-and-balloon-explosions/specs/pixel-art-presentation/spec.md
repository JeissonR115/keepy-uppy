# Spec Delta

## ADDED Requirements

### Requirement: Balloon explosion uses the supplied pixel-art frames
The balloon impact animation SHALL use the supplied 64×64 frames at native frame dimensions and preserve crisp pixel edges.

#### Scenario: Balloon impact animation plays
- **WHEN** a scoring-floor or spike impact starts the explosion
- **THEN** the animation displays, in order, the nine 64×64 cells in columns 4–12 of the first row of `assets/sprites/Animations/ballow/Free Smoke Fx  Pixel 06.png`

#### Scenario: Explosion animation completes
- **WHEN** the final selected frame has been displayed
- **THEN** the explosion effect ends without looping
