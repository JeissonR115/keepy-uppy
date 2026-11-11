# Spec Delta

## Purpose

Defines the sound effects associated with Keepy Uppy gameplay and menus, including their assets, playback variation, spatial behavior, and delivery to multiplayer clients.

## ADDED Requirements

### Requirement: Sound assets preserve the manifest and output format
The sound library SHALL use the manifest's presets and file paths unchanged, and each listed output SHALL be a mono 16-bit PCM WAV at 44,100 Hz.

#### Scenario: Exact synthesizer exports are available
- **WHEN** the listed sound assets are generated
- **THEN** the 29 WAV files match the manifest paths and use the exact event presets and render variations

#### Scenario: Exact synthesizer exports are unavailable
- **WHEN** an event cannot be exported by its exact synthesizer
- **THEN** each affected path contains a 0.1-second silent WAV placeholder and `audio/PENDIENTES.md` records its event, preset, and render parameters for later export

### Requirement: Effects play only for assigned actions
The game SHALL trigger sound effects only for the actions assigned in the sound guide.

#### Scenario: Player movement triggers sounds
- **WHEN** a player jumps or wall-jumps, begins a dash, or runs on the ground for each 14 pixels while in the normal non-ducking state and moving faster than 10 pixels per second
- **THEN** the game plays `jump`, `dash`, or `footstep` respectively

#### Scenario: Balloon and match events trigger sounds
- **WHEN** a player touches the balloon, the balloon reaches its scoring-ground burst, a point is awarded, a set is won, a new match begins, or a menu option is confirmed
- **THEN** the game plays `balloon_touch`, `balloon_explode`, the point winner's laugh, the set winner's music, `match_start`, or `menu_select` respectively

#### Scenario: Unassigned actions remain silent
- **WHEN** a player lands, climbs, grabs a wall, refills dash, dies, respawns, or uses another action not assigned by the guide
- **THEN** no sound effect is triggered for that action

### Requirement: Playback applies configured variants and intensity
The game SHALL select sound variants and adjust playback volume and pitch using the manifest's mode and render rules.

#### Scenario: Balloon impact intensity
- **WHEN** a player touches the balloon
- **THEN** intensity is clamped from relative impact speed divided by the 240-pixel-per-second reference, selects the corresponding soft, medium, or hard tier, and controls volume from -12 to -2 dB

#### Scenario: Footstep speed variation
- **WHEN** a footstep is played
- **THEN** a random rendered variant is used, volume varies from -14 to -8 dB based on horizontal speed relative to maximum run speed, and pitch varies by up to 6 percent

#### Scenario: Events have multiple variants
- **WHEN** a laugh, footstep, or balloon-touch event is played repeatedly
- **THEN** a random variant is selected and the exact same file is not selected on consecutive plays of that event

### Requirement: Playback honors routing and spatial configuration
The game SHALL route and position each sound according to its manifest playback settings and allow overlapping effects to play independently.

#### Scenario: Positional and non-positional events
- **WHEN** an event is played
- **THEN** positional events use their world position and configured maximum distance, while non-positional events use a non-spatial player and the configured bus and volume

#### Scenario: Effects overlap
- **WHEN** multiple events are triggered before earlier sounds finish
- **THEN** each event continues on its own playback instance without cutting off another event

#### Scenario: A configured asset cannot load
- **WHEN** an event's WAV is missing or unreadable
- **THEN** playback does not interrupt gameplay and an actionable diagnostic identifies the event and asset path

### Requirement: Multiplayer sound events are delivered once
In a networked session, gameplay sounds SHALL reach each client once using the event ownership rules in the sound guide, while menu sounds remain local.

#### Scenario: Authority triggers a discrete gameplay event
- **WHEN** the authority triggers balloon touch, balloon burst, match start, point laugh, or set-winner music
- **THEN** every client plays that event once, using the supplied position and intensity where applicable

#### Scenario: A player triggers jump or dash
- **WHEN** a player starts a jump or dash
- **THEN** that player's client plays the sound immediately and sends the event unreliably to the other clients

#### Scenario: Remote players run or a local menu option is confirmed
- **WHEN** a remote player runs or a client confirms a menu option
- **THEN** footsteps are generated locally from the remote player's interpolated movement, and `menu_select` plays only on the confirming client
