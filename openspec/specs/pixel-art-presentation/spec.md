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
- **WHEN** a player is idle, running, rising, falling, or dashing
- **THEN** the player's visual state communicates the corresponding movement state

#### Scenario: Balloon or player interaction occurs
- **WHEN** the balloon is hit, a dash rescue occurs, or priority changes
- **THEN** visible feedback communicates the interaction and identifies the priority player

### Requirement: Stable asset contract
Before an implementation adds scenes that depend on final art, the project SHALL have an asset manifest with exact paths, filenames, resource types, recommended dimensions, frame layout, animations, and in-game usage.

#### Scenario: Owner supplies final artwork
- **WHEN** an owner creates an asset from the approved manifest
- **THEN** its path and filename can be used without renaming or guessing its intended layout

#### Scenario: Optional audio is unavailable
- **WHEN** no music or sound-effect assets have been supplied
- **THEN** the game remains playable and communicates essential gameplay state visually
