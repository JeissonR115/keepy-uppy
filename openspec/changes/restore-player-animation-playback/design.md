# Design

## Context

See `proposal.md` for the observed failure and `specs/pixel-art-presentation/spec.md` for the playback contract. P1 and P2 instance the same `player_placeholder.tscn` and use the same body `SpriteFrames`; each clip already has its own speed and loop setting. The scene currently sets `Visual.speed_scale` to zero. `PlayerPresentationController` releases `body_one_shot_active` only from `AnimatedSprite2D.animation_finished`, so a frozen non-looping clip cannot release the gate.

## Goals / Non-Goals

**Goals:**

- Restore normal `AnimatedSprite2D` playback while keeping the supplied per-clip speeds and loop flags authoritative.
- Prove that body frames advance and a completed jump/climb one-shot permits later movement clips for both players.
- Preserve the current render order: backgrounds `-100`, hair `8`, body `10`, and action effects `11`.

**Non-Goals:**

- Retiming, replacing, or editing the imported animation frames.
- Changing movement-state selection, movement physics, hair positioning, tints, collisions, or dash afterimages.

## Decisions

### Use the native sprite playback scale

Set the shared body sprite's `speed_scale` to `1.0` (or remove its zero override so the engine default applies). Keep `SpriteFrames` clip speeds and loop modes unchanged. This restores every mapped animation at once and lets the existing `animation_finished` signal release non-looping one-shots. A custom frame timer or per-animation workaround is rejected because it duplicates native playback and could diverge from the existing per-clip timings.

### Test actual frame and one-shot progression

Extend visual regression coverage to advance the scene long enough for a multi-frame body clip to change frames, then play a non-looping one-shot through its completion and verify the controller accepts the next state clip. Run these checks for P1 and P2 because both share the scene and resource setup. Keep separate state-selection assertions for idle, run, fall, climb, and dash so a progressing sprite cannot mask a mapping regression.

### Preserve the requested canvas order

The recent user-directed ordering is part of the current scene setup. Keep each affected layer at its stated value while restoring sprite playback, and assert the body remains above hair and both remain above arena backgrounds. Do not change the action-effect ordering above the body.

## Risks / Trade-offs

- [Tests that wait for animation completion can become timing-sensitive] → Use clip metadata and a bounded wait with a clear failure if `animation_finished` does not arrive.
- [Changing the shared speed scale could expose clips that were previously hidden by the frozen first frame] → Exercise the existing mapped states and preserve each clip's authored speed and loop mode.

## Migration Plan

1. Restore the body `AnimatedSprite2D` playback scale in the shared player scene.
2. Add regression assertions for frame advancement and one-shot completion/state recovery for P1 and P2.
3. Run the focused visual tests and verify the requested render-layer values remain intact.

Rollback consists of restoring the prior scene playback scale and reverting the new regression assertions; no animation assets or movement systems need migration.
