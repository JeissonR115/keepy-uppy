# Design

## Context

See `proposal.md` and the `pixel-art-presentation` delta for motivation and observable behavior. `player_placeholder.tscn` is instantiated as both `Player1` and `Player2`; `input_prefix` distinguishes them. Its `Visual` child is currently a colored `Polygon2D`, while the collision capsule, cape, and priority indicator are independent children. `PlayerPresentationController` currently colors and transforms that polygon from existing movement values. The supplied body art is under `assets/sprites/Animations/player/` (13 folders, 148 PNG frames); the effects are under `assets/sprites/Animations/player_sweat/` (6 folders, 25 PNG frames). The controller already tracks dash, climb, ducking, velocity, wall-slide timing, and facing after physics updates.

## Goals / Non-Goals

**Goals:**

- Render the supplied body sequences and action-effect sequences without coupling sprites to physics or collision.
- Preserve the existing player scene contract and use its movement state for animation selection.
- Make player 2's body and action effects subtly orange while retaining player 1's unmodified sprite colors.
- Keep animation selection maintainable and verify the exact local assets used.

**Non-Goals:**

- Changing movement, action timing, input, player identity, scoring, or collision geometry.
- Tinting the cape, priority indicator, balloon, or interface as part of this change.
- Requiring newly drawn assets, a third-party package, or gameplay use of GIF previews.

## Decisions

### Keep one shared player scene and select tint by identity

Keep `player_placeholder.tscn` shared by both instances. Pass the existing `input_prefix` or an already-derived identity color into presentation setup, and apply a warm, low-intensity orange modulation to player 2's body and effect layers. Leave player 1 at neutral modulation so the supplied art is unchanged. Choose and review the exact modulation color in the running arena; it must read orange while preserving sprite detail. This avoids duplicate scenes and keeps the one-player bot configuration visually consistent. The alternative, maintaining a separate player-2 scene or duplicated resources, would add drift without changing behavior.

### Use native frame playback from the numbered PNG sequences

Create reusable `SpriteFrames` resources for the body and effects from numerically ordered `f0.png`, `f1.png`, etc. in the existing folders. Do not use GIFs at runtime; they are preview references. Map existing states to available clips: idle/run (`idle`, `runSlow`, `runFast`), takeoff/rise (`flip` or `dangling`), descent (`fall`, `fallFast`), dash (`dash`), wall slide (`wallslide`), and climb (`climbPull`, `climbPush`, `climbup`). Keep ducking and landing behavior tied to existing states rather than inventing new gameplay states. Use supplied effect clips (`jump`, `climb`, `climbLoop`, `danger`, and `still`) only for their corresponding existing action/state edges; inspect the `idle` effect frame and omit it if it is empty. Select the closest existing clip when runtime state does not distinguish a supplied variant; do not add movement logic solely to force every clip into use.

Native `AnimatedSprite2D` playback keeps frame timing out of physics and supports looping and one-shot presentation. A hand-coded frame timer would duplicate engine playback behavior and increase state handling. The presentation component remains responsible for choosing clips and edge-triggering one-shots; `PlayerController` remains authoritative for movement.

### Preserve collision and supporting visuals

Replace only the body `Visual` polygon with a centered animated sprite, add a separate effect sprite above it, and retain the existing root, collision capsule, cape, priority indicator, anchors, and touch feedback. Body and effect sprites mirror from `facing_direction`; effect playback never creates collision. Determine a small vertical sprite offset by comparing the supplied frame bounds with the unchanged capsule in the arena. Keep player-specific orange modulation on the body and effect sprites only.

### Migrate the visual contract and documentation with the implementation

Update `tests/test_visual_assets.gd`, whose current body assertion expects a four-point polygon even though the scene polygon has seven points, to check sprite node types, frame assets, player tint difference, and unchanged collision. Keep unrelated font, canvas, cape, and UI assertions intact. Update `docs/modules/player.md` to describe animated presentation and identity tint. Verify imported resources and representative states in Godot before considering the mapping complete.

## Risks / Trade-offs

- [The sprite feet may not align with the existing capsule] → Keep collision dimensions fixed, tune only the visual offset, and inspect grounded poses in the arena.
- [Orange modulation may obscure the source artwork or look too strong] → Apply it uniformly at low strength to player 2 only and visually review both idle and action frames.
- [One-shot effects may restart while a state remains active] → Trigger them only on state/event edges and verify they play once per transition.
- [Some supplied clips may not have a distinct matching runtime state] → Keep them available in the resource manifest and use only mappings supported by existing state.

## Migration Plan

1. Build and inspect body/effect frame resources from the local PNG inventory.
2. Replace the body polygon and add the effect layer while preserving the scene's collision and helper nodes.
3. Connect existing movement and action transitions to animation playback and apply the player-2 tint.
4. Migrate visual assertions and player documentation, then import and inspect the arena.
5. Rollback can restore the polygon visual and prior presentation code without changing movement or collision interfaces.
