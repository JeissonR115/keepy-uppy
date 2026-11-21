# Tasks

## 1. Match-start presentation

- [ ] 1.1 Add an opt-in visible-match start gate driven by the existing toss signal, and verify with both toss overrides that input and balloon play remain inactive until the presenter releases the gate.
- [ ] 1.2 Animate the four separate coin frames and show colored "Jugador 1"/"Jugador 2" labels with the actual starter emphasized; verify both outcomes and that points, rounds, and sets do not repeat the presentation.
- [ ] 1.3 Keep the presenter out of CPU simulation and release it immediately without a display; verify the existing CPU bridge/simulation tests retain their event sequence and timing.

## 2. Audio settings

- [ ] 2.1 Add and route the `Music` bus while preserving existing bus sends and music-player gains; verify menu and match music still use their current relative levels.
- [ ] 2.2 Persist audio levels and mute state in an optional `[audio]` section of `controls.cfg`, preserving that section during binding saves and recovery; verify reload, old-file defaults, and binding compatibility in the settings persistence test.
- [ ] 2.3 Add the keyboard-navigable Audio Settings page and menu entry with live master/music/effects controls, mute, and the existing effect preview; verify focus/back navigation, live bus changes, mute behavior, and preview event routing.

## 3. Player tint and turn cue

- [ ] 3.1 Add one shared exported tint-strength setting and apply identity-color blending to player sprites, action effects, and dash afterimages; verify both profiles retain readable details and tint through dash/climb states.
- [ ] 3.2 Add the world-space turn arrow driven by the authoritative turn signal; verify it follows the expected player after valid contacts and stays hidden during serve setup, intermission, headless runs, and CPU simulation.

## 4. Integration validation

- [ ] 4.1 Run `openspec validate` and the focused coin-toss, audio/settings, player-presentation, CPU bridge, and simulation tests; verify all pass without changing match rules or simulation output.
