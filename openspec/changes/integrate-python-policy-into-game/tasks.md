# Tasks

## 1. Python launch configuration

- [ ] 1.1 Add user configuration for the launcher, AI project path, bridge port, and startup timeout; verify valid, missing, and invalid values with focused tests.
- [ ] 1.2 Launch the Python client with a fixed argument vector and no shell interpretation; verify arguments and error handling with a fake executable, and document the settings and expected `uv` command.

## 2. Live match bridge

- [ ] 2.1 Start a loopback bridge for a normal CPU match and serve geometry for the selected arena; verify the returned level and geometry against the active `LevelManager`.
- [ ] 2.2 Reject simulation-control commands in live-match mode while preserving supported action and geometry exchanges; verify unsupported commands return explicit protocol errors and headless simulation commands remain unchanged.

## 3. Normal CPU match selection

- [ ] 3.1 Start the client after `1 PLAYER | VS BOT` selects an arena, wait for connection and geometry readiness while the match is paused, then select `RemoteBrain`; verify a fake live client controls the bot in the visible match.
- [ ] 3.2 Keep player-versus-player and Test CPU on their existing brains; verify those menu flows do not launch Python or start the live bridge.
- [ ] 3.3 On missing configuration, launch failure, connection failure, or startup timeout, select `LocalBrain` and show an actionable status; verify the match still starts and remains playable in each case.

## 4. Runtime resilience and cleanup

- [ ] 4.1 Preserve remote action timeout and stale-sequence fallback during normal matches; verify delayed, mismatched, disconnected, and timed-out responses never replace the local fallback action.
- [ ] 4.2 Close the bridge and reap the Python child when returning to the menu or exiting; verify repeated matches release the port and leave no child process running.

## 5. Paired integration

- [ ] 5.1 Coordinate launcher arguments and geometry readiness with `live-python-policy-agent`; verify both projects agree on the live-client command, loopback port, and geometry response.
- [ ] 5.2 Run the paired Python client in a Godot one-player-versus-bot match and verify policy actions affect gameplay; run the existing PvP, Test CPU, remote-brain, and headless simulation tests to confirm no regressions.
