# Tasks

## 1. Project foundation

- [x] 1.1 Add the main 2D arena scene, two placeholder players, placeholder balloon, platforms, and scoring ground using the proposed `src/` layout; verify the project imports and launches in Godot without missing-resource errors.
- [x] 1.2 Configure the logical viewport, integer pixel scaling, and texture filtering; run the scene at the proposed scale and record a manual launch/render checklist in the project README.

## 2. Player controller

- [x] 2.1 Configure independent, remappable Input Map actions for the owner-approved W/S and Up/Down dash directions while preserving the brief's original bindings; run the input-map test and confirm remappings require no movement-logic edits.
- [x] 2.2 Implement configurable horizontal acceleration, deceleration, air control, and player/arena collisions; verify both players respond simultaneously and remapping changes movement without script edits, then document the manual checks in the README.
- [x] 2.3 Implement variable-height jump, Coyote Time, and Jump Buffer with exposed tuning values; add automated tests for timing boundaries where isolatable and document reproducible in-scene checks for ledge and landing cases.
- [x] 2.4 Implement eight-direction dash, facing-direction fallback, duration, and cooldown; verify all eight directions and cooldown behavior in the running scene and add the results to the manual checklist.

## 3. Balloon physics

- [x] 3.1 Implement the approved balloon physics model, arena rebound, bounded configurable motion, and separate valid-contact detection/impulse application; verify player hits produce one readable impulse and ground contact reports once per round.

## 4. Dash rescue

- [x] 4.1 Implement the configurable temporary dash interaction zone and independent visual trail; verify direction-aware rescue, active-window boundaries, and one rescue hit per activation, then document the manual checks.

## 5. Player interaction and priority

- [x] 5.1 Review the proposed opening-priority, round alternation, and simultaneous-contact policies with the owner; record approved rules in the specs and design before implementing priority resolution.
- [x] 5.2 Implement priority-aware normal and dash displacement with configurable strengths while preserving both players' movement; test every approved tie-break and priority transition and document a two-player manual checklist.

## 6. Round and score

- [x] 6.1 Review and approve the proposed ground-contact scoring and restart policies with the owner; update the `round-scoring` spec and design to match the selected rules before implementing score attribution.
- [x] 6.2 Implement single-authority round/match state, ground-contact outcome, restart, and configurable win target; add automated tests for duplicate ground events, point assignment, score retention, and win termination, and verify the scene still launches.
- [x] 6.3 Implement the two-player scoreboard and result/winner state; verify visible score updates and winner display in the game and add these checks to the manual checklist.

## 7. Level and presentation

- [x] 7.1 Confirm the proposed asset manifest paths, dimensions, and sheet layouts with the owner before referencing final-art files; construct the platform arena and camera so placeholders continue to work when no assets are supplied.
- [x] 7.2 Implement readable idle/run/rise/fall/dash states, balloon impact feedback, dash trail, and priority indication; verify each state and interaction visually without audio and record the manual checks.
- [x] 7.3 Add optional audio hooks only where owner-supplied assets exist; verify the complete game remains playable and communicates essential events when no audio files are present.

## 8. Polish and verification

- [ ] 8.1 Tune exported movement and physics defaults through a complete two-player match; run the full acceptance checklist from all four specs, fix blocking failures, and record the final reproducible manual test list.
- [ ] 8.2 Run Godot import/launch and all automated tests from a clean project state; verify there are no missing resources, runtime errors, or unfinished acceptance criteria before considering the prototype complete.
