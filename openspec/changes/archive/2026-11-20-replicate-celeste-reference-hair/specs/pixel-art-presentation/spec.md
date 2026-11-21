# Spec Delta

## ADDED Requirements

### Requirement: Reference-faithful procedural hair for both players
P1 and P2 SHALL display the same cosmetic pixel-hair behavior, following the position-trail, constrained-line, and idle-extension behavior of the referenced Godot Celeste movement demo.

#### Scenario: Hair is visible at rest
- **WHEN** either player is idle
- **THEN** a pixel-art hair base remains attached at the top of the head and the short trail settles opposite the facing direction with only the bounded downward extension of the reference rig, not an unconstrained sag

#### Scenario: Hair follows movement
- **WHEN** either player moves, accelerates, brakes, or reverses
- **THEN** the hair follows the recent player-position trail, retains at most six trail points, constrains each adjacent point difference to at most two pixels per axis, and trails in the direction opposite the player's facing while idle

#### Scenario: Hair follows facing and animation
- **WHEN** the player turns or changes body animation
- **THEN** the hair pivot mirrors to the new facing and remains attached to the corresponding head pose without a visible gap or offset drift

#### Scenario: Hair changes color with movement state
- **WHEN** the player dashes, lands, or returns to the ground after a dash
- **THEN** the hair transitions to the reference dash-blue color, briefly flashes white on landing, and returns to the default hair color using the reference transition behavior

#### Scenario: Hair remains cosmetic
- **WHEN** either player's hair overlaps a player, balloon, or arena surface
- **THEN** it produces no physical collision, balloon contact, rescue, or match event

#### Scenario: Hair resets with its player
- **WHEN** a round reset or respawn relocates either player
- **THEN** its historical trail is cleared and the visible hair base and trail are reanchored to the player's current head pose

### Requirement: External hair textures require verified permission
The game SHALL include the reference hair textures only after their applicable redistribution permission is documented for this project.

#### Scenario: Reference texture use is authorized
- **WHEN** applicable permission for the reference hair textures is documented
- **THEN** the exact reference base and trail textures may be included with recorded provenance

#### Scenario: Reference texture use is not authorized
- **WHEN** applicable permission cannot be documented
- **THEN** the project does not import or redistribute those textures and records the unresolved asset dependency before selecting replacement art
