# Design

## Context

The balloon collides with TileSet physics layers 1, 2, and 4, while scoring is currently identified by the `scoring_ground` group on a `TileMapLayer`. One-way platforms use collision layer 4, so the balloon currently collides with them. Player climbing already has stamina, grab input, and wall jumps, but wall detection accepts any nearby collider. Manual acceleration is exposed as a remappable action and caps at 210 px/s; normal run speed is 110 px/s.

## Goals / Non-Goals

**Goals:**
- Give map authors independent TileMapLayers for scoring floors, pass-through platforms, trampolines, and climbable walls.
- Make collision and gameplay response follow those explicit roles.
- Replace the discrete boost action with a 130 px/s automatic run cap while keeping movement acceleration and arena speed scaling.
- Reuse existing climb stamina, grab bindings, and wall-jump behavior on explicitly marked walls.

**Non-Goals:**
- Rebalance dash, jump, balloon hit strength, or CPU strategy beyond adapting to the increased run cap.
- Add a map editor or per-cell scripting system.

## Decisions

1. **Represent specialized roles with separate TileMapLayers and node groups.** Keep scoring ground in `scoring_ground`, mark pass-through platforms `one_way_platform`, trampolines `trampoline`, and climbable walls `climbable_wall`. This follows the existing map-authoring pattern and lets each layer use distinct TileSet physics. Per-cell metadata or a custom tile registry would add complexity without a current need.

2. **Separate collision masks by role.** Keep ordinary solid/scoring tiles on the solid physics layer. Keep one-way player platforms on layer 4 and remove that bit from the balloon's collision mask so the balloon passes through them. Give trampoline tiles a dedicated collision layer/body group that both players and balloon can detect. Tag the climbable wall TileMapLayer and make player wall probes check the actual collider group; ordinary arena boundaries remain non-climbable. This avoids treating every arena boundary as climbable.

3. **Keep scoring as an explicit opt-in.** The balloon reports ground contact only for the `scoring_ground` group. A trampoline handler applies an upward impulse/rebound to the balloon and never emits ground contact; the player receives an upward launch when landing on its group. Ordinary solids and climbable walls block/rebound without ending a point.

4. **Use continuous run tuning instead of a temporary boost state.** Remove accelerate action handling and its control-catalog entry. Set the normal run-speed constant to 130 px/s; preserve existing acceleration/deceleration, air-control multiplier, and arena multiplier. Leave `grab` and its existing bindings intact. Old saved accelerate bindings become unused and are not shown in control settings.

5. **Validate behavior at both resource and gameplay levels.** Add TileSet assertions for collision layers and one-way flags, plus runtime tests for balloon pass-through, scoring-only contact, trampoline bounce, player bounce/climb, and automatic speed cap. Update level/player docs where map and control setup are described.

## Risks / Trade-offs

- [Dedicated collision layers change the masks used by existing maps] → Update both shipped arena TileMapLayers and assert the balloon/player masks against each role in scene tests.
- [Removing the accelerate action can leave stale saved bindings] → Ignore unknown legacy bindings during loading and exclude the action from current default settings and UI.
- [A higher run cap changes CPU interception timing] → Keep CPU speed prediction sourced from the player controller's active movement cap and run the relevant CPU behavior tests.
