# Spec Delta

## Purpose

Provides keyboard-accessible audio controls that let players adjust and retain the game's overall, music, and effects levels while playing.

## ADDED Requirements

### Requirement: Adjust audio levels from the menu
The menu SHALL provide master, music, and effects level controls and apply changes immediately to their corresponding audio output.

#### Scenario: Change the master level
- **WHEN** the player changes the master control
- **THEN** all game audio changes immediately by the selected amount

#### Scenario: Change music or effects level
- **WHEN** the player changes the music or effects control
- **THEN** the corresponding category changes immediately without changing the other category's selected level

### Requirement: Mute and preview effects
The audio settings SHALL provide a mute control and a way to preview an existing sound effect through the current effects level.

#### Scenario: Toggle mute
- **WHEN** the player toggles mute
- **THEN** all audio is muted or restored immediately without changing the selected master, music, or effects levels

#### Scenario: Preview an effect
- **WHEN** the player activates the effects preview
- **THEN** an existing game sound effect plays using the current effects level and mute state

### Requirement: Navigate audio settings with menu controls
Every audio setting and the effects preview SHALL be reachable and operable with the game's existing menu navigation, confirm, and back controls.

#### Scenario: Operate settings without a pointer
- **WHEN** the player opens audio settings and uses only menu controls
- **THEN** the player can focus, change, preview, and leave every setting

### Requirement: Persist audio settings
The game SHALL save audio levels and mute state using its existing settings mechanism and restore them when settings are loaded.

#### Scenario: Restore saved audio settings
- **WHEN** the game is restarted after audio settings have been saved
- **THEN** the saved levels and mute state are reapplied

#### Scenario: Load settings created before audio controls existed
- **WHEN** the game loads an existing settings file with no audio values
- **THEN** it uses the default audio levels and retains the player's existing control bindings
