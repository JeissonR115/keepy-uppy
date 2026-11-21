# pixel-art-presentation Specification

## Purpose

Defines the runnable arena and visual presentation needed to make movement, contacts, priority, and match state legible without depending on finished art or audio.

## Requirements

### Requirement: Runnable placeholder arena
The project SHALL open and run its main 2D game scene without external assets, plugins, or network access.

#### Scenario: Start without finished assets
- **WHEN** the project is launched before finished artwork or audio exists
- **THEN** the main scene displays two players, a balloon, platforms, and scoring ground using built-in or project-local placeholders

#### Scenario: Project imports and launches
- **WHEN** Godot imports and starts the project
- **THEN** the main scene is available without missing-resource or import errors

### Requirement: Crisp pixel-art presentation
The game SHALL present a consistent pixel-art-oriented arena with readable player and balloon silhouettes and pixel edges that remain crisp at the chosen display scale.

#### Scenario: Display gameplay at the configured scale
- **WHEN** the arena is rendered at the selected internal resolution and display scale
- **THEN** pixels remain visually crisp and players, balloon, platforms, and ground remain distinguishable

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

### Requirement: Stable asset contract
Before an implementation adds scenes that depend on final art, the project SHALL have an asset manifest with exact paths, filenames, resource types, recommended dimensions, frame layout, animations, and in-game usage.

#### Scenario: Owner supplies final artwork
- **WHEN** an owner creates an asset from the approved manifest
- **THEN** its path and filename can be used without renaming or guessing its intended layout

#### Scenario: Optional audio is unavailable
- **WHEN** no music or sound-effect assets have been supplied
- **THEN** the game remains playable and communicates essential gameplay state visually

### Requirement: Balloon explosion uses the supplied pixel-art frames
The balloon impact animation SHALL use the supplied 64×64 frames at native frame dimensions and preserve crisp pixel edges.

#### Scenario: Balloon impact animation plays
- **WHEN** a scoring-floor or spike impact starts the explosion
- **THEN** the animation displays, in order, the nine 64×64 cells in columns 4–12 of the first row of `assets/sprites/Animations/ballow/Free Smoke Fx  Pixel 06.png`

#### Scenario: Explosion animation completes
- **WHEN** the final selected frame has been displayed
- **THEN** the explosion effect ends without looping

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
