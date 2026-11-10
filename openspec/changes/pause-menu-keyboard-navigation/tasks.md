# Tasks

## 1. Pause menu and keyboard navigation

- [x] 1.1 Add a pause menu with Resume, Restart, and Controls options; open it with Escape, pause gameplay, and route selection/confirmation/back through Player 1's live Up/Down/Jump/Dash actions. Add automated pause, navigation, and gameplay-input isolation coverage, and document the keyboard map in README.

## 2. Safe restart

- [x] 2.1 Add a restart confirmation dialog that selects No by default, returns to pause without changing match state when cancelled, and starts a fresh match when confirmed while retaining saved controls. Add automated cancel/restart/persistence coverage and README acceptance steps.

## 3. Keyboard-operated control settings

- [x] 3.1 Make all fourteen binding rows, capture cancel, Restore Defaults, and return controls reachable and operable with Player 1's current menu actions; preserve conflict rejection and Escape/Dash cancellation during capture. Add automated keyboard navigation, capture, cancel, conflict, and reset coverage, and update README controls-menu steps.

## 4. Integration verification

- [x] 4.1 Run all pause/menu/control tests, launch the main scene, and complete the README acceptance checklist for pause/resume, restart confirmation, controls navigation, conflicting keys, default reset, and persisted bindings; fix failures and record reproducible results.
