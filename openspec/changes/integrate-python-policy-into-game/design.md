# Design

## Context

See [proposal.md](proposal.md) and [specs/python-cpu-opponent/spec.md](specs/python-cpu-opponent/spec.md) for motivation and behavior. In the main scene, `CPUController` creates `LocalBrain`; `RemoteBrain` already handles asynchronous observations, action timeouts, and local fallback, but the normal game does not start a bridge server. The headless simulation runner already starts the server and exports active-level geometry.

The Python live client and its policy are owned by the paired `live-python-policy-agent` change in the sibling repository. This change only starts and supervises that client, provides the live game-side bridge, and selects the remote brain.

## Goals / Non-Goals

**Goals:**

- Add Python as the normal one-player-versus-bot brain when configured, without blocking Godot's physics loop.
- Reuse the current version-one bridge, `RemoteBrain`, and player intent pipeline.
- Keep launch paths explicit and user-configurable, with a reliable local-brain fallback.

**Non-Goals:**

- Run Python for player-versus-player or the existing local Test CPU mode.
- Change scoring, movement, collision rules, or the bridge protocol version.
- Implement Python trajectory or route algorithms in the Godot repository.

## Decisions

### Start a small match-scoped bridge coordinator

Add a coordinator owned by the normal match flow to manage `CPUBridgeServer`, the configured Python child PID, startup state, and cleanup. Start it only for `1 PLAYER | VS BOT`, after the arena is selected. Keep the existing headless `CPUSimulationRunner` lifecycle separate; sharing the server protocol and geometry exporter is preferable to reusing the simulation runner, which owns pause, step, reset, and episode behavior.

The live server accepts the existing version-one `get_level_geometry` request and returns geometry for the selected arena. Other simulation-control commands are rejected in live-match mode. The Python client and Godot agree on the live CLI arguments through `live-python-policy-agent`; no new wire format is needed.

### Gate remote control on bounded startup readiness

While the menu has the match paused, bind the loopback server, launch the configured client, and wait up to the startup timeout for a connection and successful active-level geometry request. Only then select `RemoteBrain` and start the match. If startup or geometry readiness fails, stop the partial session, select `LocalBrain`, show the reason, and proceed with the match. This avoids spending the remote action timeout on process startup and avoids blocking a physics tick.

During play, retain `RemoteBrain`'s existing per-action timeout and stale-sequence rejection. Its local brain remains the fallback if Python later disconnects or misses a response.

### Use an explicit user configuration and argument vector

Store launcher executable, Python AI project path, bridge port, and startup timeout in a dedicated `user://` configuration read by Godot. Launch the configured executable with a fixed argument list for `uv run --project <path> run-live --host 127.0.0.1 --port <port> --level <level>`; do not concatenate a shell command. Resolve relative project paths against the game project and validate the executable, project, port, and timeout before launch. The AI policy's preferred dash distance remains in the sibling Python project's policy configuration.

### Keep lifecycle bounded and visible

Show startup, active-remote, and local-fallback status in the existing game UI or a concise notification. When returning to the menu or exiting, close the bridge so the client can exit, wait a bounded grace period, then terminate and reap the child if necessary. Release the port before another match can start.

### Preserve non-Python paths

Do not alter `use_local_brain` for two-player and Test CPU flows. The normal single-player mode uses the Python brain only after readiness; absent or invalid configuration preserves playable local behavior. This keeps rollout reversible without changing match rules.

## Risks / Trade-offs

- [The default port may already be occupied] → Make the port configurable, report bind failure, and start the match with `LocalBrain`.
- [Python executable or AI project paths may differ across machines] → Keep both in user configuration, validate them before launch, and document the expected `uv` command.
- [Python startup can exceed the menu wait] → Bound readiness, show progress, and continue locally on timeout rather than blocking gameplay.
- [The live bridge could accidentally accept simulation controls] → Handle only geometry requests in normal matches and reject reset/step or route commands explicitly.
- [The child may remain after the user leaves a match] → Close the socket first, wait for graceful exit, then terminate and verify the PID is no longer running.
- [The Python policy is approximate and may disagree with Godot physics] → Keep actual actions and collision resolution in Godot; use the local fallback on communication errors and validate policy behavior in the paired Python change.

## Migration Plan

1. Add the user configuration and match-scoped bridge coordinator without changing the existing default brain selection.
2. Add the normal live geometry response and bounded Python readiness flow; exercise it with a fake client.
3. Select the remote brain for configured one-player matches and retain the existing local fallback.
4. Apply the paired Python change and verify an interactive match end to end; verify PvP, Test CPU, and headless simulation remain unchanged.

Rollback by removing or disabling the Python configuration; normal matches then use `LocalBrain`, with no saved-game migration required.
