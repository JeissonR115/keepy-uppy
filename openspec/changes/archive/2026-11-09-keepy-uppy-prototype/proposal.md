# Proposal

## Why

Keepy Uppy currently has a Godot project shell but no playable scene or game logic. This change defines and delivers the first runnable local two-player prototype, turning the brief's movement, balloon-rescue, competitive-round, and presentation goals into independently verifiable gameplay capabilities.

## What Changes

- Establish a runnable Godot 4.x/GDScript project foundation with a main scene, two-player arena, configurable input actions, and self-contained placeholders.
- Add independent player controllers with responsive movement, variable-height jumping, Coyote Time, Jump Buffer, and eight-direction dashing.
- Add predictable balloon physics, player-hit impulses, dash rescue, and configurable player-to-player interference with a visible priority state.
- Add round state, scoring, restart, a configurable win condition, and a minimal two-player scoreboard.
- Provide legible pixel-art-oriented presentation, visual feedback, an asset manifest, and repeatable manual verification steps without generating or downloading assets.
- Keep implementation sequenced into runnable increments; do not make online play, external services, or third-party plugins part of this prototype.

## Capabilities

### New Capabilities
- `player-control`: Independent local controls and expressive movement for exactly two players, including jump assistance, dash, and player collision.
- `balloon-interaction`: Balloon motion and environment contact, valid player hits, dash rescue, and priority-aware player interference.
- `round-scoring`: Round lifecycle, ground-contact outcome, score, restart, win condition, and the in-game scoreboard.
- `pixel-art-presentation`: Runnable placeholder-based arena, crisp pixel-art presentation, gameplay feedback, and the asset contract.

### Modified Capabilities

None. The project has no existing OpenSpec capability specs.

## Impact

- Affects the Godot project configuration and introduces scenes and GDScript under the proposed `src/` layout, plus asset directories and a README/asset manifest as implementation requires.
- Uses Godot 4.x built-in 2D nodes and Input Map; no external runtime dependencies or online services.
- Requires owner review of gameplay policies that the brief leaves undecided, especially score ownership, round-start priority, and simultaneous contacts, before those policies are treated as approved behavior.
