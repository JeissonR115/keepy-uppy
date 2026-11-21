# Spec Delta

## Purpose

Defines the one-time visual introduction to a match, presenting the actual opening server without changing the toss or delaying headless simulation.

## ADDED Requirements

### Requirement: Present the authoritative opening toss
The game SHALL present the starting player from the existing match toss in a short coin animation lasting 1.5 to 2 seconds, without deriving the result or consuming randomness from the animation.

#### Scenario: Present a player-versus-player toss
- **WHEN** a new player-versus-player match begins
- **THEN** a coin animates and stops while the actual starting player is highlighted below it

#### Scenario: Present a player-versus-CPU toss
- **WHEN** a new player-versus-CPU match begins
- **THEN** the same presentation identifies the actual starting player and labels the players "Jugador 1" and "Jugador 2"

#### Scenario: Match labels identify both players
- **WHEN** the coin presentation is visible
- **THEN** "Jugador 1" and "Jugador 2" appear below the coin in their existing player colors, with the starting player emphasized and the other player subdued

#### Scenario: Presentation matches the match toss
- **WHEN** the match toss selects either player as the first server
- **THEN** the presentation emphasizes that same player and does not perform another toss

### Requirement: Start visible gameplay after the toss presentation
The game SHALL keep player movement, balloon play, and the opening turn inactive until the visible match-start presentation completes.

#### Scenario: Release gameplay after presentation
- **WHEN** the visible coin presentation finishes
- **THEN** the match proceeds with its already-selected server and normal gameplay startup

### Requirement: Show the toss presentation once per match
The game SHALL show the coin presentation for a new match only, not for points, rounds, or sets within that match.

#### Scenario: Continue after a point or set
- **WHEN** a point, round, or set restarts within the current match
- **THEN** gameplay resumes without another coin presentation

### Requirement: Omit presentation delay in headless and CPU simulation
Headless runs and CPU simulations SHALL omit the coin visuals and any presentation gate, preserving their timing and episode events.

#### Scenario: Run a CPU simulation
- **WHEN** a CPU simulation starts a match
- **THEN** it starts without the coin presentation or an added wait and emits the same simulation events as before

#### Scenario: Start the game headlessly
- **WHEN** the project starts a match without a rendered display
- **THEN** the toss presentation completes with zero visual delay
