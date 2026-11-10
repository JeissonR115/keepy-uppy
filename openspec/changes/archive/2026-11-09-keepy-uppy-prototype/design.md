# Design

## Context

See [proposal.md](./proposal.md) for motivation and scope. The current repository contains a Godot 4.7 project configuration and icon, but no gameplay scenes, scripts, or capability specs. The project already selects Godot's 2D renderer path; the brief requires Godot 4.x/GDScript, local-only play, remappable Input Map actions, and a runnable project without finished assets.

The behavioral contracts are in [player-control](./specs/player-control/spec.md), [balloon-interaction](./specs/balloon-interaction/spec.md), [round-scoring](./specs/round-scoring/spec.md), and [pixel-art-presentation](./specs/pixel-art-presentation/spec.md).

## Goals / Non-Goals

**Goals:**
- Keep player movement, balloon physics, match policy, and presentation in separate, testable responsibilities.
- Keep each implementation increment runnable and avoid hidden gameplay constants.
- Make unsettled rules visible to the owner before they become implementation assumptions.

**Non-Goals:**
- Establish final balance values, final artwork, or final audio in this design.
- Add online play, account services, matchmaking, external plugins, or reusable network abstractions.

## Decisions

### Scene and responsibility boundaries

Use the brief's `src/` layout as the starting point: player, balloon, environment, and effects entities under `src/models/`; the main arena and HUD under `src/scenes/`; and match coordination under `src/managers/`. Keep movement and dash behavior with the player, balloon motion and contact handling with the balloon, and score/round state in one match coordinator. Entities report events through signals; the coordinator is the single authority for match-level state. Do not use an Autoload unless implementation demonstrates a genuinely cross-scene global service.

**Alternative considered:** Put all game behavior in one main-scene script. This is smaller initially but couples input, physics, collision outcomes, and scoring, making behavior difficult to test and balance independently.

### Balloon physics and contact processing

The owner approved a `RigidBody2D` balloon with rotation locked, constrained/configurable gravity and damping, bounded maximum speed, and exported bounce/impulse parameters. It best fits the requested light, rebounding object and gives player hits a direct impulse model. Keep contact eligibility and match attribution separate from applying impulses, so collision events do not become scoring policy.

Use `CharacterBody2D` for players as required. Represent the dash rescue interaction as a short-lived area associated with the dash path, with its dimensions, activation interval, and one-hit-per-activation rule configurable. Render the dash trail separately.

**Alternative considered:** A `CharacterBody2D` balloon with fully scripted motion gives tighter deterministic control but requires hand-built rebound and contact response. Select it only if playtesting shows the rigid-body approach cannot meet the predictability contract.

### Input and dash direction

Keep the named per-player movement, jump, and dash actions in Godot's Input Map. The supplied controls define horizontal, jump, and dash bindings, but do not define vertical directional actions needed for eight-way dash.

The owner approved `player_1_up`/`player_1_down` on W/S and `player_2_up`/`player_2_down` on Up/Down. Combine these with each player's horizontal axes to select one of eight normalized dash directions; if no direction is held, use the facing direction. Keep the bindings replaceable through Input Map.

### Approved priority and simultaneous-contact policies

The owner approved an opening coin toss: heads assigns the first serve and priority to Player 1; tails assigns them to Player 2. In each following round, the player awarded the previous point serves and receives opening priority. The score-attribution rule that determines the point winner remains pending approval in task 6.1.

Collect contacts for a physics tick before resolving priority, rather than relying on callback order. When a normal hit and dash rescue occur simultaneously, the rescue determines priority. When contacts of the same kind occur simultaneously, the player who did not hold priority before that tick wins the tie-break.

### Approved scoring and restart policies

The owner approved awarding the point to the opponent of the last player to validly touch the balloon. If there was no valid touch, the opponent of the round's opening server receives the point. The point winner is the server and opening-priority player for the next round.

The owner approved showing the round result during a configurable short intermission, then resetting round entities while retaining the match score. A player reaching the configured target ends the match without starting another round.

Implement tie resolution in one match-policy boundary, after collecting contacts for the tick, so physics callback order cannot silently decide priority.

### Tunable gameplay parameters

Expose movement, jump assist windows, dash duration/cooldown/velocity, balloon gravity/damping/bounce/maximum speed, hit strengths, push strengths, interaction-zone size/duration, round intermission, and target score through `@export` values or focused resources. Keep values grouped by owning entity. Use initial playtest values only as defaults, not as requirements. Avoid a general-purpose global balance singleton.

### Pixel-art viewport and placeholders

**Recommendation:** Start with a 320x180 logical viewport and integer 3x scaling to 960x540, using nearest-neighbor filtering and a fixed 2D camera over a compact platform arena. Confirm the scale on the target display before final art production. Use simple project-local geometry/placeholders until owner-supplied art is available; do not generate or download assets.

The owner approved the following asset manifest before any scenes reference final art. Dimensions are per frame unless stated; sheet layouts are horizontal. The names and paths are the stable asset contract; the prototype continues to use placeholders until assets are supplied.

| Exact relative path | Type | Frame size / sheet | Frames and animation | Use |
|---|---|---|---|---|
| `assets/sprites/players/player_1_idle.png` | PNG spritesheet | 16x24 px / 4 columns (64x24) | 4 idle frames | Player 1 idle |
| `assets/sprites/players/player_1_run.png` | PNG spritesheet | 16x24 px / 6 columns (96x24) | 6 run frames | Player 1 running |
| `assets/sprites/players/player_1_jump.png` | PNG | 16x24 px | 1 frame | Player 1 rising |
| `assets/sprites/players/player_1_fall.png` | PNG | 16x24 px | 1 frame | Player 1 falling |
| `assets/sprites/players/player_1_dash.png` | PNG spritesheet | 16x24 px / 2 columns (32x24) | 2 dash frames | Player 1 dash |
| `assets/sprites/players/player_2_idle.png` | PNG spritesheet | 16x24 px / 4 columns (64x24) | 4 idle frames | Player 2 idle |
| `assets/sprites/players/player_2_run.png` | PNG spritesheet | 16x24 px / 6 columns (96x24) | 6 run frames | Player 2 running |
| `assets/sprites/players/player_2_jump.png` | PNG | 16x24 px | 1 frame | Player 2 rising |
| `assets/sprites/players/player_2_fall.png` | PNG | 16x24 px | 1 frame | Player 2 falling |
| `assets/sprites/players/player_2_dash.png` | PNG spritesheet | 16x24 px / 2 columns (32x24) | 2 dash frames | Player 2 dash |
| `assets/sprites/balloon/balloon.png` | PNG spritesheet | 16x20 px / 4 columns (64x20) | 2 float frames, 2 impact frames | Balloon idle and hit feedback |
| `assets/sprites/environment/platform.png` | PNG tile | 16x16 px | 1 tile | Arena platforms |
| `assets/sprites/environment/ground.png` | PNG tile | 16x16 px | 1 tile | Scoring ground |
| `assets/sprites/effects/dash_trail.png` | PNG spritesheet | 16x16 px / 4 columns (64x16) | 4 trail frames | Dash visual trail, independent of collision |

The prototype remains fully playable without these files. Audio is optional and is not a dependency of any gameplay event.

### Verification approach

For each implementation increment, launch the project and run a written manual checklist. Verify input independence, jump-window boundaries, dash directions, balloon hit/rescue, ground-contact uniqueness, priority transitions, score/restart/win, and placeholder launch. Add automated tests where game rules can be isolated from the scene tree; retain manual two-player and visual checks for real-time interactions.

## Risks / Trade-offs

- [Rigid-body motion may feel unpredictable across collision order or frame conditions] → Clamp/configure motion, keep contact attribution separate, and verify in the running arena; switch to scripted `CharacterBody2D` behavior only if the acceptance contract fails.
- [Keyboard ghosting may prevent some simultaneous two-player combinations] → Use the specified separate key regions and test the actual supported bindings; keep Input Map remapping available.
- [Temporary placeholders can mask asset-scale or animation problems] → Approve the manifest before final art is created and validate replacement assets in the same scene.
- [Unapproved scoring or priority rules can invalidate implementation] → Gate these implementation tasks on explicit owner approval and update the change artifacts before coding those policies.

## Migration Plan

There is no existing gameplay state or saved data to migrate. Add the main scene and project settings in the first runnable increment, then implement the capabilities in the dependency order in `tasks.md`, launching the project at each checkpoint. If an increment fails acceptance, revert only that increment's introduced files/settings through the project's version-control workflow; preserve pre-existing project files and any owner-supplied assets. No external service or schema migration is involved.

## Open Questions

- Fine-tuning exported movement, physics, impulse, and intermission defaults can follow playtesting without changing the capability boundaries.
- Final palette, exact owner-created artwork, and optional music/SFX can be selected after the placeholder loop is playable.
