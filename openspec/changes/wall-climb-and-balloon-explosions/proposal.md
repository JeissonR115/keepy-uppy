# Proposal

## Why

Wall jumps should remain available when a player is grounded against a wall, but ordinary wall contact must not cause an automatic rebound. While climbing, reversing horizontal input should not flip the character. Balloon impacts on the scoring floor and spikes also need consistent explosion feedback, with the balloon disappearing immediately.

## What Changes

- Allow an intentional wall jump when the player is touching both the floor and a wall, without changing passive wall-collision behavior.
- Keep the player's facing direction stable while climbing; allow normal facing updates after climbing ends.
- Replace the balloon's polygon burst with the same one-shot sprite animation for scoring-floor and spike impacts, and hide the balloon immediately while the effect plays.
- Use the final nine 64×64 cells in the first row of the existing smoke-effect sheet.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `player-control`: define grounded wall jumps and stable facing while climbing.
- `balloon-interaction`: define the shared impact animation and immediate balloon disappearance.
- `pixel-art-presentation`: define use of the existing 64×64 sprite-sheet frames for readable impact feedback.

## Impact

The change affects player movement/facing logic and its wall-climb tests, balloon impact handling and scene presentation, and balloon impact tests. The animation uses `assets/sprites/Animations/ballow/Free Smoke Fx  Pixel 06.png` (768×1472; 12 columns by 23 rows). The nine cells are interpreted as 1-based columns 4–12 of row 1 and will be read from the atlas rather than exported as duplicate image files. Existing floor scoring, spike handling, and round reset behavior remain intact.
