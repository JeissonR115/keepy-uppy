# Tasks

## 1. Player movement and input lifecycle

- [x] 1.1 Adjust grounded wall collision response so horizontal motion stops without rebound; verify by running into and sliding along a vertical arena wall.
- [x] 1.2 Gate and clear buffered jump input outside active gameplay and during round setup; verify pressing the menu start key does not jump a player and stale input does not fire on serve.

## 2. Balloon contact and serve setup

- [x] 2.1 Deduplicate balloon contacts by dash activation across rescue-zone, trail, and ordinary contact routes; verify one activation queues no more than one valid touch, including repeated overlap.
- [x] 2.2 Stage round setup by repositioning players, waiting for physics placement to settle, then placing and arming the balloon; verify no player can touch the balloon before serve setup completes.

## 3. Downward-touch warning and scoring

- [x] 3.1 Add configurable warning duration with a 1.5-second default and a cancellable white/player-color flash; verify start, timeout, touch cancellation, and point-resolution cleanup.
- [x] 3.2 Route ground contact during the warning through the existing consecutive downward-fault policy; verify a first fault replays and a consecutive fault by the same player applies the configured existing penalty.
- [x] 3.3 Resolve ground contact after warning expiry for the last valid toucher; verify an opponent rescue during the warning clears it and continues the rally under turn and double-touch rules.

## 4. Integrated gameplay review

- [ ] 4.1 Play through menu start, normal serve, player relocation, dash rescue, downward-hit warning, rescue, warning-ground fault, and ordinary ground scoring; verify score, serve, fault, and visual outcomes match all three delta specs.
