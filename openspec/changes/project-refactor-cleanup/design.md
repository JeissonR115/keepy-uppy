# Design

## Context

See proposal.md for motivation. The current project uses Godot 4.7 and keeps runtime code under `src/`: match and controls managers, balloon and player controllers, a player input reader, and three UI scripts. The pause and control settings interfaces build most of their controls in GDScript. The control settings manager owns action defaults and persistence; action names and labels are also represented in the settings UI and input reader. The match manager coordinates scoring and match flow, while the balloon and player controllers own their physics and movement properties. Twenty-two SceneTree scripts provide automated coverage, and README documents the test suite.

Constraints: preserve observable gameplay and UI behavior, control settings compatibility (`user://controls.cfg`), scene entry points, and the existing project organization unless a concrete boundary justifies a change. Avoid new dependencies and autoloads without a demonstrated need.

## Ownership Map

- `project.godot` selects `src/scenes/main/main.tscn` and defines the InputMap actions. Main owns `ControlSettingsManager` and instantiates the arena.
- `src/scenes/levels/arena.tscn` owns both player instances, the balloon, `MatchManager`, the scoreboard, floor, and side walls. The match manager coordinates match state and subscribes to player bump signals; it calls the balloon controller to resolve queued contact impulses.
- `player_placeholder.tscn` owns `PlayerController`, its `PlayerInputReader`, collision/visual nodes, rescue area, and dash trail. `PlayerController` reads input and owns movement, timers, player collision notifications, and movement presentation.
- `balloon_placeholder.tscn` owns `BalloonController`, the physics/contact shapes, impact visual, string, and ground burst. The controller owns balloon motion, contacts, contact cooldowns, and impact/burst presentation.
- `scoreboard.tscn` owns `Scoreboard`, `PauseMenu`, and `ControlSettings`. Scoreboard subscribes to match signals and routes pause/restart/settings requests; the two UI scripts own their dynamic interface construction and keyboard navigation. Settings UI depends on the manager in Main.
- Control action identifiers/defaults/labels had parallel definitions in `ControlSettingsManager` and `ControlSettings`, while `PlayerInputReader` formed names from a prefix and pause/menu navigation embedded player-one action strings. These are consolidated in `PlayerActionCatalog`; `project.godot` remains the engine-facing InputMap declaration and is checked for parity by tests.
- Dynamic calls were present between player/input reader, match/balloon, and scoreboard/settings UI; direct typed script references now cover these stable relationships. The balloon's pending contact payload remains a dictionary because it is produced asynchronously by physics callbacks and consumed by the match manager.

The original project has eight runtime GDScripts across the listed ownership boundaries; the refactor adds the ninth script, `PlayerActionCatalog`, to own the shared control definitions. The environment platform scene is a reusable model resource but is not instantiated by the current floor-only arena. No cohesive utility or global service is shared by unrelated scenes, so no `utils/` or autoload was introduced.

## Goals / Non-Goals

**Goals:**

- Make configuration and dependencies easier to trace without changing their values or timing.
- Keep ownership close to the systems that use it, while sharing only data and helpers with multiple real consumers.
- Make each refactoring step small enough to compare against the existing test and launch baseline.

**Non-Goals:**

- Change game rules, physics tuning, controls, menu behavior, visual output, or saved settings.
- Introduce broad design patterns, a general-purpose utilities folder, or a global configuration service by default.
- Rewrite the test framework or add external packages.

## Decisions

1. **Audit ownership before extracting code.** Trace scene node paths, signals, and script calls; then change only boundaries that reduce actual coupling. Keep match flow and scoring in the match manager unless the audit identifies an independently owned responsibility. Keep balloon physics and player movement/balance values with their owning controllers. This favors local, exported settings over a global configuration object. Alternative considered: split each large script preemptively; rejected because it adds interfaces and behavior risk without a demonstrated cohesive component.

2. **Use one source for player action metadata.** Consolidate identifiers, defaults, and user-facing labels in a small control-domain definition consumed by the settings manager/UI and input reader. Preserve the existing InputMap names, physical keys, labels, and settings serialization. Alternative considered: leave parallel lists and add consistency checks; rejected because metadata will still have multiple edit points.

3. **Make dependencies explicit at scene boundaries.** Prefer typed references and exported/onready node references where scene ownership is stable; use signals for one-way notifications. Remove string-based `call()` and absolute paths only where the typed form is clear and preserves initialization order. Avoid autoloads for objects already owned by the main scene. Alternative considered: globally register managers; rejected because it widens lifetime and coupling.

4. **Share presentation configuration only when it has multiple consumers.** If the audit confirms duplicated colors, fonts, or style metrics across UI/player presentation, centralize those values in a narrowly named theme/resource and keep per-screen layout local. Do not move single-use dimensions or gameplay tuning into shared configuration. Alternative considered: a broad constants/config singleton; rejected because it obscures ownership and creates needless global state.

5. **Treat behavior as a regression contract.** Capture baseline results before edits, then run the relevant automated checks and headless main-scene launch after each group, followed by all 22 SceneTree tests and the launch check. Review changes for unchanged input action names, save schema, signal order, scene paths, physics values, and visible layout. Tests are verification gates, not an invitation to alter expected behavior.

## Risks / Trade-offs

- [A cleanup can accidentally alter initialization order, signal timing, or physics] → Refactor incrementally and verify affected scenes/tests after each group; keep diffs scoped and compare exported physics values and signal flow.
- [Centralized metadata can change labels or saved bindings through an unnoticed mismatch] → Preserve exact action identifiers, labels, defaults, and serialization; add or adapt coverage around the existing settings tests.
- [Extracting UI styling can create resource-loading or theme-inheritance differences] → Share only confirmed common values and verify both menus in their existing scenes.
- [The existing tests may not cover every visual detail] → Include scene launch checks and inspect relevant scene/resource diffs; avoid speculative visual redesign.

## Migration Plan

1. Record baseline test and headless launch results; map scene/script ownership and duplicated values.
2. Refactor control action metadata and its consumers, keeping persisted data compatible.
3. Clarify scene-owned dependencies and extract only responsibilities supported by the audit.
4. Consolidate genuinely shared presentation values, name meaningful repeated literals, and remove only confirmed dead state.
5. Update README only for changed internal organization or verification instructions; run the complete regression checks and review the final diff.

Rollback is by reverting the isolated refactoring group. No user data migration or external deployment step is required; preserve the existing controls file format throughout.
