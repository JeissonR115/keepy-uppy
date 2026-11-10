# Spec Delta

## Purpose

Defines the local player's momentum-based movement, jump assistance, dash techniques, and wall climbing so both human players and the existing bot can move consistently in the arena.

## ADDED Requirements

### Requirement: Momentum-based run and fall behavior
Each player SHALL use the documented 60 Hz movement tuning for acceleration, deceleration, air control, gravity, and fall limits, while retaining horizontal momentum produced by movement techniques.

#### Scenario: Preserve speed gained from a technique
- **WHEN** a player moves faster than the 90 px/s run speed and keeps steering in the same direction
- **THEN** excess speed decays at the 400 px/s² reduction rate instead of being clamped to run speed

#### Scenario: Release or reverse direction
- **WHEN** a player has excess horizontal speed and releases or reverses directional input
- **THEN** the 1000 px/s² acceleration response removes the excess promptly, scaled by the 0.65 air-control multiplier while airborne

#### Scenario: Falling and fast-falling
- **WHEN** a player is airborne
- **THEN** gravity advances downward speed at 900 px/s² toward 160 px/s, or toward 240 px/s when holding Down after reaching normal fall speed

#### Scenario: Light gravity near the jump apex
- **WHEN** a player is airborne, holding Jump, and has vertical speed within 40 px/s of the apex
- **THEN** gravity is reduced by half

#### Scenario: Accelerate into a fast fall
- **WHEN** a player holds Down after reaching normal fall speed
- **THEN** downward speed approaches the 240 px/s fast-fall limit at 300 px/s²

### Requirement: Buffered variable-height jump
Each player SHALL support a variable-height jump with a 0.1 second coyote window, a 0.08 second input buffer, and a 0.2 second variable-jump interval.

#### Scenario: Short and held jumps
- **WHEN** a player releases Jump before the variable-jump interval ends
- **THEN** the jump is shorter than when Jump remains held

#### Scenario: Coyote jump
- **WHEN** a player presses Jump within 0.1 seconds after leaving a ledge
- **THEN** the jump starts as if the player were still grounded

#### Scenario: Buffered landing jump
- **WHEN** a player presses Jump up to 0.08 seconds before landing
- **THEN** the jump starts on landing

#### Scenario: Ceiling contact
- **WHEN** an ascending player contacts the ceiling
- **THEN** variable upward motion is cancelled after the 0.05 second grace interval, and a ceiling corner with at most 4 px of horizontal overlap can be corrected

#### Scenario: Add horizontal jump boost
- **WHEN** a player starts a jump while pressing horizontally
- **THEN** 40 px/s is added to horizontal velocity in the input direction

### Requirement: Single-use directional dash and ground refill
Each player SHALL have one normalized eight-direction dash that consumes its charge on activation and only regains it after landing.

#### Scenario: Start a dash
- **WHEN** a player with a dash charge presses Dash outside cooldown
- **THEN** the player freezes locally for 0.05 seconds, then travels at 240 px/s for 0.15 seconds in the normalized eight-way held direction or current facing direction

#### Scenario: Preserve the local match during dash freeze
- **WHEN** one player is in dash freeze
- **THEN** only that player's movement freezes and the other player and match continue simulating

#### Scenario: Prevent repeated air dashes
- **WHEN** a player has used a dash and has not landed
- **THEN** further Dash presses do not start a dash, including after touching a wall

#### Scenario: Refill on landing
- **WHEN** a player lands after using Dash and the 0.1 second refill cooldown has elapsed
- **THEN** the dash charge is restored

#### Scenario: Apply dash cooldown and exit speed
- **WHEN** a dash starts and later ends by duration
- **THEN** the 0.2 second dash cooldown is started and exit velocity is 160 px/s in the dash direction, with upward velocity multiplied by 0.75

#### Scenario: Correct a dash corner
- **WHEN** a dash collides with a corner with at most 4 px of overlap
- **THEN** the player can be shifted around the corner rather than stopping at the collision

#### Scenario: Downward dash on the ground
- **WHEN** a downward dash contacts the ground
- **THEN** the player enters a ducking posture suitable for a hyper jump

### Requirement: Chain dash-derived jumps
During dash, each player SHALL be able to perform the specified ultra, super jump, hyper jump, and upward-dash wall bounce without discarding the resulting horizontal momentum.

#### Scenario: Ultra from a downward diagonal dash
- **WHEN** a downward diagonal dash contacts the floor
- **THEN** horizontal speed is multiplied by 1.2, vertical speed becomes zero, and the dash continues for its remaining duration

#### Scenario: Super jump from horizontal dash
- **WHEN** a player presses Jump on the floor during a horizontal dash
- **THEN** the dash ends and the player performs a super jump at 260 px/s horizontally and -105 px/s vertically

#### Scenario: Hyper jump from ducking dash
- **WHEN** a player presses Jump on the floor during a ducking downward dash
- **THEN** the dash ends, ducking ends, and the player performs a hyper jump at 325 px/s horizontally and -52.5 px/s vertically

#### Scenario: Wall bounce during upward dash
- **WHEN** a player presses Jump during a vertical upward dash within 3 pixels of a wall
- **THEN** the player bounces away from the wall at 170 px/s horizontally and -160 px/s vertically with a 0.25 second variable jump and 0.2 second forced-direction input

#### Scenario: Ultra from downward diagonal dash
- **WHEN** a downward diagonal dash contacts the floor
- **THEN** horizontal speed is multiplied by 1.2, vertical speed becomes zero, ducking is enabled, and the dash continues for its remaining duration

#### Scenario: Retain buffered jump after a technique
- **WHEN** a technique is followed by landing while Jump remains buffered
- **THEN** the buffered jump can trigger on that landing

### Requirement: Wall slide, wall jump, and climb
Each player SHALL be able to slide on, jump away from, and climb a nearby wall using the documented wall distances, speed curves, and stamina costs.

#### Scenario: Wall slide
- **WHEN** an airborne player falls while steering toward a wall
- **THEN** fall speed starts at 20 px/s and increases linearly toward 160 px/s over 1.2 seconds

#### Scenario: Wall jump
- **WHEN** a player presses Jump within 3 pixels of a wall without requiring Grab
- **THEN** the player jumps away at 130 px/s horizontally and -105 px/s vertically, with variable jump and forced-direction input for 0.16 seconds

#### Scenario: Enter and leave climb
- **WHEN** a player holds Grab within 2 pixels of a wall with stamina remaining
- **THEN** the player climbs, descends, or holds position without gravity and spends stamina at the corresponding rate
- **WHEN** Grab is released, the wall is lost, or stamina reaches zero
- **THEN** climbing ends

#### Scenario: Exhaust climbing stamina
- **WHEN** the player climbs upward, waits, jumps from the wall, or falls below the 20 stamina tired threshold
- **THEN** stamina is spent at 45.5/s, 10/s, or 27.5 per climb jump as applicable, and tired state gives visual feedback

#### Scenario: Restore stamina on ground
- **WHEN** a player touches the ground outside dash
- **THEN** stamina returns to 110

#### Scenario: Climb at configured speeds
- **WHEN** a player climbs upward, descends, or holds position on a wall
- **THEN** vertical speeds are -45 px/s, 80 px/s, or 0 px/s respectively, without gravity

#### Scenario: Blink when tired
- **WHEN** climbing stamina falls below 20
- **THEN** the player blinks to indicate the tired state

#### Scenario: Restore stamina only on ground
- **WHEN** a player remains on a wall or in the air
- **THEN** stamina does not refill; it returns to 110 only on the ground

### Requirement: Preserve local player interactions
Movement changes SHALL preserve arena collisions, player-to-player contact and priority-scaled bumps, balloon dash rescue, and the existing local bot behavior.

#### Scenario: Collide with the other player
- **WHEN** two players' bodies meet during play
- **THEN** they remain physically blocked and the existing match rules apply the appropriate normal or dash bump

#### Scenario: Use dash to rescue the balloon
- **WHEN** a player's dash-rescue area contacts the balloon during a dash
- **THEN** the existing dash-rescue and turn-resolution behavior continues to work
