# Spec Delta

## ADDED Requirements

### Requirement: Preserve readable player identity tint
Player characters SHALL use their existing player identity colors with one shared, adjustable tint strength that remains consistent across gameplay states and afterimages without obscuring sprite details.

#### Scenario: Render player identity colors
- **WHEN** both player characters are displayed
- **THEN** each character has a visibly stronger tint from its existing identity color while facial and sprite details remain legible

#### Scenario: Change movement state or spawn an afterimage
- **WHEN** a player dashes, climbs, changes another visual state, or creates a dash afterimage
- **THEN** the same player identity tint remains visible without replacing the state's animation or fade

### Requirement: Indicate the player expected to touch the balloon
During an active rally after the opening serve contact, the game SHALL show a small, gently oscillating arrow above the player expected to touch the balloon, using that player's existing identity color without obscuring the character.

#### Scenario: Update the cue after a valid touch
- **WHEN** a player makes a valid balloon touch and the expected player changes
- **THEN** the arrow moves to the newly expected player and uses that player's identity color

#### Scenario: Wait for the opening serve contact
- **WHEN** the balloon is waiting for its first valid touch in a round
- **THEN** the arrow remains hidden while the existing turn display identifies the server

#### Scenario: Hide the cue outside an active rally
- **WHEN** the match is in a setup, serve-waiting, or round-intermission state
- **THEN** no turn arrow is displayed

#### Scenario: Follow players in every arena
- **WHEN** a rally is shown in any arena
- **THEN** the arrow follows its player in world space and remains positioned above rather than over the character

#### Scenario: Omit the cue in headless simulation
- **WHEN** the game runs headlessly or in CPU simulation
- **THEN** no turn-arrow visual or simulation delay is introduced
