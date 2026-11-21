# Spec Delta

## Purpose

Lets a normal interactive match use the configurable Python policy as its CPU opponent while preserving Godot's local brain as a playable fallback. The policy positions and routes using the live arena, balloon, and opponent state.

## ADDED Requirements

### Requirement: Launch Python for a normal CPU match
When a user starts a normal one-player-versus-bot match, the game SHALL start the configured Python live client and use its valid actions for the bot.

#### Scenario: Python client starts and connects
- **WHEN** a configured one-player-versus-bot match begins and the Python client connects
- **THEN** the bot uses the remote brain for subsequent decisions in the visible match

#### Scenario: Python client is not configured
- **WHEN** a one-player-versus-bot match begins without a usable Python configuration
- **THEN** the match continues with the local brain and the user is told why Python control is unavailable

### Requirement: Configure and launch the Python process safely
The game SHALL use explicit executable and project configuration to launch the Python client without shell interpretation, and SHALL bind its bridge to loopback only.

#### Scenario: Launch with configured paths
- **WHEN** a valid Python executable and AI project location are configured
- **THEN** the game starts the client with the selected bridge address and port as separate arguments

#### Scenario: Reject invalid launch configuration
- **WHEN** a configured executable or project location is invalid
- **THEN** the game reports the launch error and does not execute a shell command or block the match

### Requirement: Exchange live observations and actions
The Python live client SHALL respond to the game's sequenced observations with one valid action per decision without resetting or stepping the match.

#### Scenario: Apply a live decision
- **WHEN** the remote brain requests an action during a normal match and Python responds to that observation
- **THEN** the game applies the matching action through the existing player movement and match rules

#### Scenario: Observe changing turns
- **WHEN** the expected balloon toucher changes between players
- **THEN** the next Python decision uses the updated turn and current observations

### Requirement: Fall back when remote control is unavailable
If Python fails to start, connect, or respond before the action timeout, the game SHALL continue using the local brain and SHALL not apply a late or mismatched action.

#### Scenario: Python process exits or disconnects
- **WHEN** the live client exits or its bridge connection closes during a match
- **THEN** the local brain continues controlling the bot and the game reports the fallback reason

#### Scenario: Python action times out
- **WHEN** a response does not arrive before the configured timeout
- **THEN** the local brain controls that decision and any later response for the expired observation is ignored

### Requirement: Release the Python process with the match
The game SHALL close the bridge and stop the Python child process when a Python-controlled match returns to the menu or the game exits.

#### Scenario: Return to the menu
- **WHEN** the user leaves a Python-controlled match
- **THEN** the bridge session is closed and the child process is reaped before another match starts

### Requirement: Keep the opponent within a configurable dash-ready distance
On the opponent's turn, the Python policy SHALL maintain a reachable position near the balloon, defaulting to approximately one dash of travel while keeping a separate minimum no-contact distance.

#### Scenario: Use the default dash-ready distance
- **WHEN** the user has not overridden the preferred distance
- **THEN** the policy derives its default from the active movement constants for dash speed and duration and respects the minimum safe distance

#### Scenario: Override preferred distance
- **WHEN** the user configures a preferred distance in the Python policy settings
- **THEN** the policy uses that value without changing the independent minimum no-contact distance

### Requirement: Reassess the moving opponent as a route obstacle
The Python policy SHALL treat the other player as a moving obstacle and compare the expected cost of pushing through with the cost of routing around them.

#### Scenario: Passing through is faster
- **WHEN** the current observations indicate that pushing through the opponent is a lower-cost route than detouring
- **THEN** the policy selects the passing route and accounts for the movement slowdown caused by the push

#### Scenario: Detouring is faster
- **WHEN** the current observations indicate that going around the opponent is a lower-cost route
- **THEN** the policy selects the detour

#### Scenario: Opponent moves during planning
- **WHEN** a new observation shows that the opponent has moved
- **THEN** the policy reevaluates whether to pass through or detour using the updated position

### Requirement: Predict balloon rebounds from arena collision geometry
The Python policy SHALL use exported arena and tile collision geometry when predicting balloon motion and selecting a reachable route or interception.

#### Scenario: Balloon rebounds from a tile surface
- **WHEN** a predicted trajectory contacts a solid tile or platform within the prediction horizon
- **THEN** subsequent trajectory samples reflect the collision and remain consistent with the exported geometry

#### Scenario: Balloon rebounds from an arena wall
- **WHEN** a predicted trajectory reaches an arena wall
- **THEN** subsequent trajectory samples include the wall rebound and remain within playable bounds

### Requirement: Preserve existing non-Python match modes
Starting a Python-controlled normal match SHALL NOT change player-versus-player controls or the separate local Test CPU mode.

#### Scenario: Start a two-player match
- **WHEN** the user selects two human players
- **THEN** neither player starts or depends on the Python process

#### Scenario: Start Test CPU mode
- **WHEN** the user selects Test CPU
- **THEN** that mode continues to use its existing local test brain and visualization independently of Python startup
