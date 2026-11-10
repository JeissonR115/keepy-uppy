# Tasks

## 1. Player actions and defaults

- [ ] 1.1 Configure the seven default actions per player (including physical top-row 1/2/3 for Player 2) and separate action reading from movement logic; update the input-map test and README binding table, then verify both players' default actions and simultaneous inputs without movement-script edits.

## 2. Binding validation and persistence

- [ ] 2.1 Implement one validator for prohibited keys, modifier chords, and duplicate bindings across both players; add automated validation cases and document rejected-key feedback, then verify invalid assignments leave the live binding unchanged.
- [ ] 2.2 Add versioned local save/load and default recovery for missing, partial, malformed, duplicate, or prohibited settings; add automated round-trip and fallback tests and document the settings file behavior, then verify valid bindings survive restart and damaged settings restore the complete defaults.

## 3. In-game control settings

- [ ] 3.1 Add a distinct, player-colored settings screen reachable from the HUD with action rows, current keys, capture prompt, cancel, validation messages, and restore defaults; add capture/cancel/reset coverage and README steps, then verify the screen can pause and resume gameplay without trapping input.
- [ ] 3.2 Connect capture to the settings manager and Input Map; verify all 14 actions display and rebind correctly, Escape cancels without becoming a binding, duplicates are rejected, and cancelling preserves the prior key; record a reproducible two-player manual checklist in README.

## 4. Accelerate boost

- [ ] 4.1 Implement the owner-approved temporary accelerate boost with configurable duration, intensity, cooldown, and speed cap (initial values: 0.8 seconds, 1.35x, 4 seconds, and 210 px/s); add automated duration/cooldown/cap tests and README checks, then verify normal horizontal acceleration remains distinct and both players' boost behavior is independent.

## 5. Integration verification

- [ ] 5.1 Run all available control-related automated tests and launch the Godot project; execute the README acceptance checklist for defaults, simultaneous input, capture, prohibited/duplicate keys, cancel, reset, persistence, damaged-file recovery, and accelerate, fixing any failures before recording results.
