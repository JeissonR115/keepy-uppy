# Design

## Context

See [proposal.md](./proposal.md) for motivation and scope. The current game has twelve Input Map actions (movement, jump, and dash), with keys in `project.godot`; `PlayerController` reads those actions directly through a per-player prefix. There is no title or pause menu, and the HUD is a `CanvasLayer` in the arena. The project has no canonical OpenSpec specs yet; this change establishes the `player-control` capability alongside `control-settings`.

## Goals / Non-Goals

**Goals:**
- Load validated local bindings into Godot's Input Map before gameplay reads them.
- Keep capture, validation, persistence, and movement concerns separate.
- Preserve independent two-player input and expose all seven actions per player.
- Make invalid settings recover safely to the complete default map.

**Non-Goals:**
- Intercepting operating-system shortcuts or promising that a key event will reach the game.
- Supporting controller bindings or multi-key chords in this change.
- Implementing an accelerate gameplay effect before the owner approves it.

## Decisions

### Keep one action map and separate input reading from movement

Retain the `player_1_*` and `player_2_*` action naming convention and use Godot Input Map as the live source used by gameplay. Add the accelerate actions without conflating them with horizontal movement acceleration. Move action-name construction and state sampling behind a small player input reader/interface; keep the shared `PlayerController` responsible for movement and dash behavior. This avoids copying a controller per player and lets the settings UI change bindings without movement-script edits.

**Alternative considered:** Keep all `Input` calls in `PlayerController`. It is smaller, but couples the movement model to global keyboard state and makes configured action changes and isolated input tests harder to maintain.

### Use physical keys and capture only unmodified key presses

Use physical key codes for defaults and saved bindings so QWERTY-style positions remain stable across keyboard layouts. P1 defaults are A/D/W/S/F/G/H; P2 defaults are the arrow keys and the physical top-row 1/2/3 keys. Capture only a pressed, non-echo `InputEventKey`. Reject F1-F12, Escape, individual modifiers, and any event carrying Shift, Ctrl, Alt, or Meta. This conservative rule avoids maintaining a fragile platform-specific list of shortcut chords. Escape and an on-screen cancel control end capture; Escape is never stored as a binding.

**Alternative considered:** Permit modifier chords except known protected shortcuts. Shortcut reservations vary by operating system and desktop environment, so a partial allowlist could misleadingly claim that a protected shortcut is safe.

### Centralize validation across all fourteen actions

Put key validity and duplicate detection in one validation boundary used by both capture and settings loading. Treat bindings as one physical key per action and compare the requested key against every other action for both players, excluding the action currently being edited. A rejected binding leaves Input Map and the saved configuration unchanged and returns a player-readable reason. Do not attempt to suppress keys consumed by the operating system.

**Alternative considered:** Validate only within one player. That would let one physical key trigger two players' actions, undermining independent local controls and making the conflict hard to diagnose.

### Load and save through a local settings manager

Store the complete versioned map in a Godot `ConfigFile` under `user://controls.cfg`. A `ControlSettingsManager` child of the main scene applies validated settings from `_enter_tree`, before arena/player nodes become ready and read actions. It owns defaults, validation, Input Map updates, serialization, and reset; the settings screen owns presentation and capture state. Keep it scene-local rather than adding an Autoload because the game has one main scene and no demonstrated cross-scene global service need.

On startup, require a complete valid set for all actions. Missing, malformed, duplicate, prohibited, or incomplete data causes the entire map to fall back to defaults and be rewritten as a valid configuration. On a user's accepted change or reset, update the live Input Map and save the full map. If saving fails, restore the previous in-memory/Input Map binding and show an error rather than claiming the preference persisted.

**Alternative considered:** Save only overrides and merge them with defaults. A partial merge makes migrations and duplicate detection dependent on subtle precedence rules; a full versioned snapshot has one validation and recovery path.

### Add a discoverable screen from the HUD

Add a Controls button to the existing scoreboard HUD and present a dedicated control settings panel/screen with separate P1 and P2 visual sections, action rows, current-key labels, capture prompt, validation message, cancel, and restore-defaults control. Keep the settings scene independent from the scoreboard logic; connect it to the manager through a narrow API/signals. Show the panel over gameplay and pause the gameplay tree while it is open so keyboard capture does not move the players. The button and mouse interactions remain available for closing and restoring settings.

**Alternative considered:** Use Escape as the only way to enter and exit settings. Escape is reserved during capture, and a visible button is discoverable without taking a gameplay key away from its binding.

### Implement the owner-approved accelerate boost

The owner approved a temporary speed boost on `player_1_accelerate` and `player_2_accelerate`, distinct from the existing acceleration/deceleration used to reach normal run speed. Expose duration, intensity, cooldown, and maximum speed as player tuning values; use 0.8 seconds, 1.35x normal run speed, 4 seconds, and 210 px/s as initial values. The effect applies independently to each player and cannot exceed its configured speed cap.

## Risks / Trade-offs

- [A key may be reserved by an OS in a way the game cannot observe] → Reject modifier chords conservatively, do not promise protected-shortcut capture, and explain that the operating system may consume such input.
- [A settings file may be corrupted or become incompatible] → Validate the entire versioned map and restore all defaults on any invalid entry.
- [Many bindings may be rejected because duplicates are global] → Show the action that owns the conflicting key and let the user rebind either row.
- [Pausing the tree can block interface nodes] → Keep the settings screen and HUD processing while the arena is paused, and verify close/reset/cancel paths manually.
- [Temporary speed boost may affect competitive balance] → Keep duration, intensity, cooldown, and speed cap configurable and verify both players under the same tuning.

## Migration Plan

1. Add a versioned local settings manager and apply the complete defaults when no valid file exists.
2. Add the seven Input Map actions per player and update the player input reader to use the shared action model.
3. Add and connect the settings panel; verify it is reachable from the HUD and can pause/resume gameplay safely.
4. Verify capture validation, cancellation, reset, save/load, and damaged-file fallback with automated checks where isolatable and a manual two-player checklist.
5. If the change is rolled back, remove the settings screen/manager and the added accelerate actions, and restore the former action defaults in `project.godot`; the user data file can be ignored by the application after rollback.

