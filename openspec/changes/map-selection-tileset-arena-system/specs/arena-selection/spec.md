# Spec Delta

## Purpose

Permite que las personas elijan una arena antes de jugar y entiendan sus dimensiones, tema y características con una vista previa clara.

## ADDED Requirements

### Requirement: Browse available arenas
The pre-match interface SHALL display every valid arena from the catalog with its name and allow the user to choose one before gameplay starts.

#### Scenario: Multiple arenas are available
- **WHEN** the user opens arena selection
- **THEN** each valid catalog entry is selectable and the current player-count or game-mode flow is preserved

#### Scenario: No valid arenas are available
- **WHEN** the selection screen has no valid arena entries
- **THEN** it communicates that no arenas are available and does not start a match with an invalid scene

### Requirement: Show selected arena details
The selection interface SHALL show the selected arena's preview and available descriptive metadata, including its name, recommended player count or size classification, and theme.

#### Scenario: Selection changes
- **WHEN** the user moves selection to another arena
- **THEN** the preview and metadata update to match that arena

#### Scenario: Preview is missing
- **WHEN** an arena has no preview texture
- **THEN** the interface displays a neutral fallback preview and keeps the arena selectable

### Requirement: Start match on selected arena
The game SHALL load the selected arena and apply its spawn positions and bounds before starting the match.

#### Scenario: Confirm arena selection
- **WHEN** the user confirms a valid arena
- **THEN** that arena becomes active, the match starts with its configured spawns, and gameplay resumes

#### Scenario: Return from arena selection
- **WHEN** the user cancels arena selection
- **THEN** the interface returns to the preceding mode or player-count screen without starting a match
