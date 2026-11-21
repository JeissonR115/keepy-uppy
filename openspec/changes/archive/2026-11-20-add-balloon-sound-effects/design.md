# Design

## Context

See `proposal.md` for motivation and `specs/sound-effects/spec.md` for the behavior contract. The manifest already exists at `audio/sound_presets.json`; the project has background music but no SFX assets, audio autoload, or SFX/UI bus layout. Movement and dash timing live in `PlayerController` (`_begin_dash` starts after the dash freeze), balloon contacts and ground contact are reported by `BalloonController`, and `MatchManager` exposes round/set signals. The current game is local-only and has no RPC or peer setup. `MovementConstants.DASH_SPEED` is 240 px/s and `MAX_RUN` is 100 px/s.

## Goals / Non-Goals

**Goals:**
- Keep the existing manifest as the sole source of preset, path, bus, and playback configuration.
- Add sound playback and narrowly scoped event synchronization without changing movement, scoring, or the current local-match flow.
- Make unavailable synthesizer exporters and missing assets explicit and verifiable.

**Non-Goals:**
- Add general online multiplayer, movement replication, or player ownership infrastructure.
- Add sound to actions omitted by the guide or substitute approximate synthesized audio for the named presets.

## Decisions

1. **Keep the manifest authoritative.** Load `audio/sound_presets.json` without rewriting or normalizing preset objects. Use its event paths and playback settings directly. This avoids duplicated configuration and protects the nested JSON strings in Mixr/Jinglr presets.

2. **Use the exact sound tools or documented placeholders.** First determine whether the named synthesizer exporters are available. If they are not, generate valid 0.1-second silent WAVs at every required path and list each event, preset, tier/variant, and render parameters in `audio/PENDIENTES.md`. Do not approximate the sounds. Validate WAV headers and sample data independently of whether the export is silent.

3. **Centralize loading and playback in an autoload.** Add an `AudioManager` that validates and loads the manifest once, chooses files for `single`, `random_variant`, and `intensity` modes, and applies configured volume/pitch variation. Keep the last selected resource per event so a tier transition cannot accidentally replay the same file consecutively. Create one player per playback, using `AudioStreamPlayer2D` for positional events and a regular player otherwise; free it on completion. Configure the `SFX` and `UI` buses in a Godot bus layout. A missing or unreadable configured asset should leave gameplay running but emit an actionable diagnostic rather than fail silently.

4. **Trigger sounds at existing authoritative gameplay boundaries.**
   - In `PlayerController`, play `jump` only after a normal or wall jump actually begins. Play `dash` from `_begin_dash`, after the freeze, not when dash is merely requested. Accumulate running distance after `move_and_slide()` and emit footsteps every 14 pixels only while grounded, in the normal state, not ducking, and above the guide's speed threshold.
   - In `BalloonController`, derive normal-contact intensity from relative approach speed and preserve the contact speed with the pending contact data if playback occurs after contact resolution. Use the same 240 px/s reference as dash speed for dash-rescue contacts. Play the burst sound only on the already-guarded scoring-ground contact.
   - In `MatchManager`, play the point winner's laugh from the awarded-point event and the winner's set sound from `set_won`. Add a distinct match-start event for `_start_new_match`; do not infer match start from `round_started`, which also fires on round restarts. Initially allow the point laugh and set sound to overlap as the guide permits; adjust the set cue by 0.8 seconds only if listening confirms masking.
   - Play `menu_select` on confirmed/activated options in the player-count and pause/confirmation menus, not on focus movement. Keep this event local.

5. **Keep networking limited to sound delivery.** Provide a reliable authority event for discrete gameplay cues, and an unreliable owner-originated path for jump/dash that never waits on the network before local playback. Use remote movement interpolation for remote footsteps rather than replicating every step. In offline mode, play each event locally and do not require a multiplayer peer. Use the guide's modulo mapping for player-specific cues if additional player indices are introduced. Because no network layer exists today, validate the offline path and RPC declarations now; validate delivery-once behavior when a multiplayer peer is available.

6. **Test behavior at its boundaries.** Add tests for manifest parsing and preset preservation, event-to-action coverage and excluded actions, variant non-repetition across intensity tiers, footstep distance/speed behavior, impact tiers/volume, missing-resource diagnostics, independent overlapping players, and offline/network dispatch rules. Check all 29 file paths and their WAV format, and confirm the configured buses and disabled looping.

## Risks / Trade-offs

- **Exact synthesizer tools may be unavailable** → Use only silent placeholders with a complete pending-export inventory; do not claim those placeholders satisfy audible-quality review.
- **Network delivery cannot be exercised in the current local-only project** → Keep hooks dormant without a peer, preserve offline playback, and clearly mark peer-based acceptance as requiring a networked test environment.
- **Sound overlap may reduce cue clarity** → Start with the guide's simultaneous point/set cues and adjust only the set cue delay after listening.
- **Missing resources would otherwise be indistinguishable from intentionally silent events** → Emit a diagnostic with the event ID and path while allowing the match to continue.

## Migration Plan

This is additive: preserve the existing manifest and music playback. Register the autoload and bus layout, then integrate and verify event-by-event. Roll back by removing the new autoload/bus configuration and sound calls; existing gameplay and background music remain unchanged.

## Open Questions

None that block the specified behavior. Remote delivery acceptance depends on a multiplayer peer becoming available; general network gameplay remains out of scope.
