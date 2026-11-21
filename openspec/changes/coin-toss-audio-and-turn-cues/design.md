# Design

## Context

See `proposal.md` for motivation and the capability deltas for user-visible behavior.

- `Main` contains the arena and `PlayerCountMenu`; the CPU simulation scene contains the arena alone. The arena's `MatchManager` does not start on ready. A selected match calls `restart_match()`.
- On a new match, `MatchManager` emits `coin_toss_completed(result, first_server)` before its deferred round setup. Player input remains disabled and the balloon is not armed until setup completes. Point/round restarts do not emit a new toss. The CPU runner supplies `coin_toss_override` from its episode RNG.
- The toss currently uses `randi_range()` unless overridden; `match_seed` is assigned after the toss. Therefore `match_seed_override` does not currently seed the toss. Presentation must use the emitted server and must not add RNG calls or change this behavior.
- The coin art is four separate RGBA PNGs (`1.png`–`4.png`), each 128×128, not a sprite sheet. No separate heads/tails mapping is documented; the player labels, not an inferred coin side, will communicate the authoritative outcome.
- The bus layout has `Master`, `SFX`, and `UI`; music players currently use `Master` with local levels of -6 dB and -4 dB. `ControlSettingsManager` stores version-1 bindings in `user://controls.cfg`, and its current save path rewrites the file. The optional `[audio]` section must survive control saves and recovery.
- Player identity colors live in `PlayerActionCatalog`. Player tint is currently supplied by separate visual profiles, while dash afterimages have a separate tint. The settings screen and scoreboard already use keyboard navigation and match signals.

## Goals / Non-Goals

**Goals:**

- Present the existing toss in the playable main scene, then release the already-pending match setup.
- Keep visuals and any presentation gate out of CPU simulation and at zero duration when no display is available.
- Reuse existing audio assets and buses while retaining current relative music and effect mixing.
- Make player tint adjustable once and keep the turn cue tied to authoritative turn state.

**Non-Goals:**

- Change toss selection, match seeds, scoring, turns, CPU behavior, episode events, or simulation timing.
- Add music or sound effects, replace placeholder audio, or add pointer-dependent settings navigation.
- Repeat the coin presentation for points, rounds, or sets.

## Decisions

### Main-scene presentation and optional start gate

Add a presentation controller to `main.tscn`, not to the shared arena. It is present before the player selects a match, listens for the existing toss signal, and presents the `first_server` argument. A main-scene-only opt-in gate in match setup keeps input disabled and the balloon unarmed until the animation finishes. The gate applies to a new match only; point and round setup retain their existing timing.

When no visible presenter is registered, setup follows the existing path. A headless presenter completes immediately, and the CPU simulation scene remains unchanged and has no presenter. This avoids simulation waits and leaves the episode-seeded `coin_toss_override` authoritative. The animation uses no random selection. The four images are cycled as animation frames; the final emphasis is on the server's label because the art has no specified heads/tails mapping.

### Turn cue in world space

The same main-scene presentation controller listens to `balloon_turn_changed`. It positions a small cue in arena world space above the expected player, using `PlayerActionCatalog` colors so camera movement follows naturally. The cue is visible only while the match is active and `round_has_valid_contact` is true. It stays hidden during serve setup, when the scoreboard already names the server, and outside a rally.

### One shared player-tint setting

Add one shared visual-settings resource with the exported tint-strength parameter and reference it from both player profiles. Blend each profile's existing sprite tint toward its `PlayerActionCatalog` identity color. Apply that blend to the body and action-effect sprites in one place; apply the same identity color to afterimage RGB while preserving the configured afterimage alpha and fade. This is preferred to per-player strength values, which could drift. Arrow geometry and motion use named constants or exported settings, never hard-coded player colors.

### Audio routing and settings storage

Add a `Music` bus sending to `Master`; retain existing `Master`, `SFX`, and `UI` buses and their sends. Assign the existing music players to `Music` without changing their local -6 dB/-4 dB levels. The effects slider adjusts both `SFX` and `UI`, since both contain non-music effects and neither bus is a child of the other. The mute switch mutes `Master` without overwriting the selected levels.

Add an `AUDIO SETTINGS` entry to `PlayerCountMenu` that opens a separate keyboard-navigable settings page and returns to the same menu/pause state. Use the existing `jump` event for the effect preview; add no sound asset. Save levels and mute state in an optional `[audio]` section of `user://controls.cfg`. Missing audio keys in a valid older file use audio defaults without invalidating bindings. Update control saves to preserve other sections instead of replacing the whole file.

### Validation

- Extend coin-toss tests to cover both overridden toss outcomes, displayed server, a blocked visible start until completion, and no repeated presentation after a point/round.
- Exercise headless/main-scene and CPU simulation setup to verify no additional wait or episode events.
- Extend settings persistence tests for audio round-trip, mute, old files without audio data, and preservation of audio values during binding saves/recovery.
- Test that each turn change points the cue to the new expected player, that it is hidden before the first contact and outside active play, and that tint reaches state sprites and afterimages.
- Verify the new bus and unchanged music local levels, then run the existing focused match, audio, CPU bridge, and simulation tests.

## Risks / Trade-offs

- [A lost presentation completion callback could leave visible gameplay gated] → Use a single completion path for animation finish and presenter teardown, and test that the gate releases exactly once.
- [The existing `jump` WAV is a silent placeholder, as documented in `audio/PENDIENTES.md`] → Reuse the existing event as requested and do not add an effect; the preview will become audible when the placeholder is replaced.
- [Changing bus routing could alter the current mix] → Keep existing sends and music player gains; default bus levels preserve the current output.
- [A tint strong enough to identify a player could obscure sprite art] → Keep the strength in one shared resource and validate both player profiles, including faces and afterimages.

## Migration Plan

No user data migration is required. Existing version-1 control files remain valid; absent audio settings use defaults. Binding writes update only the control sections and preserve any saved audio section. New bus defaults keep existing music gains and effect levels unchanged.
