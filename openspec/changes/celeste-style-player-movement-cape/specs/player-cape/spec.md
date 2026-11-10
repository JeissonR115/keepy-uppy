# Spec Delta

## Purpose

Defines the local player's lightweight, simulated cape and its color feedback so the cape communicates player identity and whether a dash is available.

## ADDED Requirements

### Requirement: Simulate an attached cape
Each player SHALL display a cosmetic, non-colliding pixel-aligned cape that follows the player's motion and remains attached at two mirrored shoulder anchors.

#### Scenario: Follow player motion
- **WHEN** a player moves, jumps, dashes, or changes facing direction
- **THEN** the cape follows the player, flips its anchors with facing, and trails according to the player's motion without detaching

#### Scenario: Maintain cape geometry
- **WHEN** the cape is simulated during normal movement
- **THEN** its two-column, six-row Verlet particle grid uses 2.5 px segment lengths and tapers to 0.6 of its anchor width, maintaining total length within 15 percent of the configured length

#### Scenario: Stabilize cape simulation
- **WHEN** the cape is updated each physics tick
- **THEN** Verlet integration uses 250 px/s² gravity, 0.90 damping, 3.0 wind gain, and four constraint iterations, and rendered points are rounded to whole pixels

#### Scenario: Reset after teleport or respawn
- **WHEN** the player teleports, respawns, or the cape exceeds the documented 48 px reset distance
- **THEN** the cape resets to a stable position attached to both shoulder anchors

#### Scenario: Recover from invalid simulation points
- **WHEN** a cape simulation point becomes non-finite
- **THEN** the cape resets to a stable position attached to both shoulder anchors

#### Scenario: Render cape behind the player
- **WHEN** the cape is displayed with its player
- **THEN** the cape fill and darkened outline render behind the player sprite and do not collide with the world

#### Scenario: Preserve the cape when facing changes
- **WHEN** the player changes facing direction
- **THEN** the anchors mirror to the opposite side while cape points retain their world positions and settle through simulation

### Requirement: Communicate dash availability with color
The cape SHALL use its player's configured color and distinguish an available dash from a spent dash by saturation and brightness.

#### Scenario: Dash is available
- **WHEN** the player spawns or regains a dash charge by landing
- **THEN** the cape displays the player's hue with at least 0.9 saturation and full brightness

#### Scenario: Dash is spent
- **WHEN** the player uses a dash before landing
- **THEN** the cape displays the same player hue at 0.35 of its base saturation and 0.6 of its base brightness until the dash charge is restored

#### Scenario: Preserve player identity
- **WHEN** either player's dash state changes
- **THEN** only that player's cape changes dash-availability styling and the other player's color remains unchanged

#### Scenario: Keep spent cape visible
- **WHEN** dash is unavailable
- **THEN** the cape remains opaque and visible in the same hue, with its outline darkened by 0.4

### Requirement: Stop cape simulation during local dash freeze
The cape SHALL respect the player's local dash-freeze interval without pausing the rest of the match.

#### Scenario: Freeze cape with its player
- **WHEN** the player enters dash freeze
- **THEN** the cape's simulation pauses with that player and resumes when the freeze ends
