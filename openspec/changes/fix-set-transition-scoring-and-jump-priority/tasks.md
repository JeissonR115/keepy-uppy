# Tasks

## 1. Ground-contact scoring and set transitions

- [x] 1.1 Award ground-contact points to the last valid toucher while preserving the no-touch opening-server fallback; verify a player's touch followed by an unrescued ground contact awards that player exactly one point.
- [x] 1.2 Reconcile the ground-scoring deltas in `player-contact-and-downward-touch-rules` and `map-selection-tileset-arena-system` with the confirmed last-toucher rule; verify no active delta specifies the opposite point winner.
- [x] 1.3 Clear prior-round contacts and stage set transitions before arming the next serve; verify an old-position or pre-existing overlap cannot register as a new serve touch.

## 2. Turn-color restoration

- [x] 2.1 Restore the balloon to the expected player's color when the downward warning or impact presentation ends; verify both warning timeout and a valid rescue leave the balloon showing the next turn color.

## 3. Grounded jump and wall-jump behavior

- [x] 3.1 Prioritize a grounded jump before wall-jump detection; verify a grounded player beside a wall jumps normally and an airborne player still performs a wall jump.
- [x] 3.2 Preserve jump vertical velocity when player-bump displacement is applied; verify jumping while touching the opponent still moves the player upward.

## 4. Integrated gameplay review

- [ ] 4.1 Play through a set-winning point, next-set serve, last-touch scoring, downward-warning expiry and rescue, and grounded/wall jumps; verify the turn, score, spawn, color, and movement outcomes match all delta specs.
