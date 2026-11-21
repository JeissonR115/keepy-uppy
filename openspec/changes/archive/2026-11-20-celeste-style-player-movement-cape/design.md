# Design

## Context

See `proposal.md` for motivation and scope. The existing game uses two local `CharacterBody2D` players with per-player input readers, a shared controller that also supports the bot, a dash-rescue area, and match-managed player bumps. The player scene has no cape. The project uses a 320x180 viewport and currently relies on Godot's default physics tick rate rather than declaring the guide's 60 Hz explicitly.

The guide assumes online authority and no player-to-player collision. This design deliberately keeps the current local-only match and collision/push behavior instead.

## Goals / Non-Goals

**Goals:**
- Keep one movement implementation for both local human players and the existing bot.
- Make movement timing and tuning explicit at 60 physics ticks per second.
- Add the guide's Normal, Dash, and Climb states while retaining the existing match interaction hooks.
- Simulate each cape locally in world coordinates and derive its appearance from player color and dash availability.
- Keep movement and cape tests deterministic and dependency-free using the existing project test setup.

**Non-Goals:**
- Network play, remote player interpolation, authority transfer, or `MultiplayerSynchronizer`.
- Removing, disabling, or redesigning player collision, bump priority, balloon rescue, or the existing boost mechanic.
- Cape/world collision, cloth tearing, dash refill crystals, or new accessibility settings.

## Decisions

### Extend the existing controller and input reader

Keep the current player controller as the owner of movement state, timers, dash charge, stamina, and transition events. Introduce a single constants module for the guide's tuning values and organize the per-physics-tick flow into input/timer updates, replenishment, state logic, `move_and_slide()` and transition handling, then cape update. Preserve the controller's existing human/bot split for input sourcing so the bot exercises the same movement rules.

Add a remappable `grab` action per player through the existing action catalog and input reader; do not make movement code depend on raw keyboard events. Reserve non-conflicting defaults (P1: `R`, P2: `4`) and keep them editable through the existing key configuration. Existing boost and dash-rescue signals remain separate from the new movement state machine.

### Use an explicit per-player state machine and timers

Represent normal movement, dash, and climb as explicit states. Keep jump buffer, coyote time, variable jump, dash and refill cooldowns, wall-slide timing, forced wall-jump direction, and local dash-freeze as per-player state rather than shared/global timers. Process movement at 60 Hz and use the exact constants in the movement and cape specs; tune distances only if a measured player scale requires it, and record any intentional adjustment in the implementation tests/docs.

The dash-freeze timer suspends only that player's motion and cape simulation. It must not change `Engine.time_scale`, pause the scene tree, or delay the other player, match manager, balloon, or score timers. Continue collecting dash-direction input during the freeze so the resulting dash uses the latest normalized direction.

Keep dash availability independent from the dash cooldown: activating dash immediately spends its one charge, and only grounded refill after the specified refill delay restores it. A wall contact or wall climb never restores dash. Resolve super/hyper/ultra and wall-bounce transitions before ending the dash so the documented exit velocities and retained momentum are applied once.

### Preserve collision and match interaction contracts

Retain the current collision layer/mask setup and `player_bumped` reporting to `MatchManager`. The normal/dash priority behavior remains owned by the match system, not duplicated in the new movement states. Keep the existing dash-rescue area and its signal path so the balloon interaction continues to work.

Use the existing character collider unless tests show that the guide's ducking posture requires a reduced shape for floor hyper jumps. If a posture-specific collider is needed, change it only while grounded and restore it on every exit path; do not alter collision between players. Preserve the bot's ability to steer and use existing actions, adding Grab behavior only through the same action abstraction.

### Build the cape as a local cosmetic scene

Add a player-owned cape scene with a `Node2D` simulation script, `Polygon2D` fill, and closed `Line2D` outline. Use two mirrored shoulder anchors (initial guide positions `(0, -8)` and `(-3, -6)`, adjusted to the current sprite), six Verlet points per side, and the guide's segment, taper, gravity, damping, wind, iteration, and reset constants. Store particle positions in global coordinates (`top_level`) so the cape trails rather than inheriting player rotation/transform. Pin anchor rows on every constraint pass, update after `move_and_slide()`, round rendered vertices to integer pixels, and draw behind the player sprite.

On facing changes, mirror the anchor positions but retain the simulated points in world space. On spawn, teleport, respawn, excessive anchor displacement, or non-finite particle data, reset the cape to its anchors. Offset both anchors downward by 3 px while ducking. The cape has no collision shape and contributes no gameplay physics.

Read the player's existing identity color and dash availability as inputs. Derive the vivid/dull variants from those inputs rather than storing a second color state. Apply the derived color to fill and a 0.4-darkened version to the outline. Pause only the cape's simulation during its owner's dash-freeze interval.

### Verify with existing tests and measurable acceptance checks

Extend the existing controller, dash, and player-interaction tests, and add focused cape tests in the current GDScript test framework. Cover state transitions and boundary timing (coyote, jump buffer, dash/refill cooldown, stamina), directional dash and momentum, wall interactions, and preservation of player bumps and balloon rescue. Cape tests should check anchor pinning, mirrored anchors, reset behavior, pixel rounding, dash color derivation, and that each player updates independently.

Add repeatable assertions or a documented manual checklist for the guide's observable criteria: ground stop/start under 0.1 s, full jump near 28 px, dash near 36 px, hyper speed of 325 px/s, climb stamina durations near 2.4 s upward and 11 s stationary, corner correction up to 4 px, and cape length variation below 15 percent. Run the existing movement, dash, interaction, input-remapping, and scene tests after integration.

## Risks / Trade-offs

- [The movement guide's pixel values may not align with the current capsule or arena scale] → Keep values centralized, test against the existing 320x180 arena and 8 px tiles, and adjust only the scale-dependent distances with documented acceptance evidence.
- [The expanded state machine may regress existing dash-rescue, boost, bot, or bump behavior] → Preserve those interfaces and test them alongside every movement-state change.
- [A Verlet cape can stretch or become unstable during abrupt motion] → Pin anchors during all constraint iterations, use the guide's reset threshold, guard non-finite positions, and test high-speed dash and respawn cases.
- [Changing the global physics tick rate can affect unrelated physics] → Explicitly set the required 60 Hz, then run match, collision, and movement tests; keep the project tick rate unchanged if it is already 60.
- [Two local players can have visually similar colors] → Retain each configured identity hue and verify vivid and muted variants remain distinguishable in the existing player palette.

## Migration Plan

1. Add and test the centralized movement tuning values and explicit 60 Hz physics setting.
2. Extend per-player input mapping with Grab and implement the Normal/Dash/Climb state machine while preserving existing match signals and bot input.
3. Add the cape scene and local simulation; connect it to player color, dash charge, facing, ducking, and per-player freeze.
4. Update player documentation and run movement, cape, remapping, collision, rescue, and full scene checks.
5. Rollback, if required, by restoring the prior controller and player scene, removing the added Grab actions/cape files, and reverting the explicit physics tick setting; no save-data migration is needed.
