# Proposal

## Why

Match starts currently expose the coin toss only as game state, while players have no in-menu audio controls and player identity/turn feedback can be clearer. This change presents the existing toss and turn state, adds persistent live audio controls, and introduces one bounded rescue from dash afterimages.

## What Changes

- Add a short opening coin animation that presents the existing starting server in PvP and vs CPU, then allows gameplay to begin. Show it only once per match.
- Add keyboard-navigable master, music, and effects volume controls plus mute and an existing-effect preview, persisted with the current settings.
- Strengthen player-color tinting consistently across character states and afterimages, and show a small, player-colored cue for the player expected to touch the balloon during rallies.
- Allow one additional successful balloon rescue from a dash afterimage after the primary dash rescue, capped at one trail rescue per dash.
- Omit presentation delays in headless and CPU simulation runs; do not alter simulation events, toss results, or any other match rules.

## Capabilities

### New Capabilities

- `match-start-presentation`: Present the authoritative opening toss and gate visible gameplay until the short presentation ends.
- `audio-settings`: Provide live, persistent, keyboard-navigable audio controls.
- `dash-trail-rescue`: Provide one bounded additional balloon rescue through an active dash afterimage.

### Modified Capabilities

- `pixel-art-presentation`: Strengthen consistent player identity tinting and add a readable, camera-independent rally turn cue.

## Impact

- Match startup and presentation in `MatchManager`, the main scene, and the player-count menu; CPU simulation must remain ungated.
- Audio bus layout and `AudioManager`; control settings persistence and menu UI.
- Player visual profiles, presentation/afterimage tinting, and `Scoreboard` turn feedback.
- Player and balloon contact handling for the bounded dash-trail rescue.
- Focused Godot tests for toss presentation, simulation behavior, audio settings persistence, dash-trail rescue, and turn/tint presentation. No new audio assets or dependencies.
