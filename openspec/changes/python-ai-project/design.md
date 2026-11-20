# Design

## Context

See [proposal.md](./proposal.md) for motivation and the capability specs for observable requirements. The project is a sibling of the Godot repository and may interact with it only through the version-1 TCP/JSON contract in [docs/cpu-ai-bridge.md](../../../docs/cpu-ai-bridge.md). The existing client example uses the Python standard library. The bridge serializes commands, actions, observations, and events over one connection; a step can emit observations and episode events before its command result.

## Goals / Non-Goals

**Goals:**
- Keep the Python package independent of Godot source and third-party runtime dependencies.
- Preserve protocol ordering and make simulation, graph generation, and episode behavior reproducible and diagnosable.
- Exercise exported graphs through the same public commands that downstream users will use.

**Non-Goals:**
- Change Godot behavior or the bridge contract.
- Provide reward design, policy learning, or a full Gymnasium implementation.
- Infer transitions that the real-physics probe cannot validate.

## Decisions

### Package and dependency model

Use `uv` with a `pyproject.toml`, Python `>=3.11`, and a `src/keepy_ai` package divided into `bridge`, `godot`, `graph`, and `env`. Keep runtime dependencies in the standard library; use `tomllib` for an optional `keepy-ai.toml` configuration file. Test-only tools may be development dependencies. This avoids imposing Gymnasium or NumPy on bridge-only users; using either as a required dependency was considered and rejected because the selected API needs neither.

Keep the requested CLI entry points thin: `generate-graph` coordinates geometry retrieval, graph export and route validation; `run-episode` coordinates the launcher, environment and result reporting. Reusable behavior remains in package modules so unit tests can exercise it without starting Godot.

### Bridge client and message ordering

Implement a synchronous, single-owner TCP client modeled on `examples/cpu_bridge_client.py`. Dataclasses represent the stable protocol concepts (actions, observations, episode events, command results, and probe results); geometry and graph payloads preserve their nested JSON structure while receiving validated top-level types. A single line reader validates UTF-8 JSON, the 1 MiB limit, session id, protocol version, and message type. It routes observations to the active step, stores episode events until the matching result is assembled, and matches command results by sequence. Only one command is in flight at a time; this matches the simulation's serialized operations and avoids a second concurrency model.

The client uses explicit exceptions for socket timeout, disconnect, malformed data, incompatible protocol, and server rejection. It does not convert an error or missing message into a neutral action or empty result. Every action is validated locally against the six documented fields before it is sent.

### Launcher and configuration

Resolve each setting in this order: command-line option, environment variable, optional `keepy-ai.toml`, then documented default. Use `GODOT_BIN` and `GODOT_PROJECT_PATH` for the executable and sibling game path; keep simulation options (`port`, `level`, `speed`, `seed`, and `mode`) available at each configuration layer.

When no port is configured, ask the OS for an ephemeral loopback port, close the temporary socket, and launch the documented headless scene with that port. Because the port can be claimed between selection and Godot binding, detect startup failure and retry a bounded number of times with a new port. Require a valid protocol hello before exposing the client. Drain captured child output so diagnostics remain available without blocking the process. Shutdown sends `close` when possible, waits for the configured grace period, then terminates and reaps the child.

### Environment semantics

Use a dependency-injected bridge client, with an optional owned launcher, so tests can use a fake server and callers can manage process lifetime explicitly. `reset(seed, level)` forwards the request and returns its observation plus seed/level metadata. `step(action)` performs one bridge `step(1)`, answers the outstanding observation with the action, and collects the completed step's final observation and events.

The public result is Gymnasium-shaped but not Gymnasium-equivalent: the bridge consumes a response on the following physics tick. Therefore the action passed to `step` is queued for the next tick, and the observation and terminal status in that call describe the just-completed tick, not the queued action. Immediately after reset there is no outstanding observation sequence, so the first `step(action)` obtains one during its bridge tick and reports that the submitted action has not yet affected the returned state. Include the answered sequence and queued-action status in `info`; retain events from the completed tick. `terminated` follows the bridge's episode-ending result, `truncated` is false in V1, and reward remains the documented `0.0` placeholder. A synchronous action-aligned transition would require a bridge change and is deliberately not simulated in Python.

### Geometry and graph generation

Convert exported geometry to world-space support surfaces using each collision transform and each platform cell transform; include one-way platform tops as drop-capable surfaces. Use bounds and safe bounds to discard nodes outside the playable region. Generate a deterministic node order from surface position, adding nodes at support endpoints, drop boundaries, wall bases, and spawn positions. WALK and DROP candidates use conservative geometric adjacency and obstruction checks.

Use `movement_constants` returned by `get_level_geometry` to bound JUMP and DASH candidate distances; never keep a separate copy of movement physics constants. Probe each candidate from its source node with the documented action and retain it only when the probe starts, lands, and its landing position matches the target node within the graph match tolerance. Preserve each rejected candidate and probe outcome in the report. V1 emits no WALL_JUMP edge. Assign deterministic positive costs using documented action-specific weights; these weights express route preference, not movement constants or a training reward.

Assign integer node ids in deterministic position order and serialize nodes and directed edges deterministically to `graphs/<level>.json`. Write to a temporary sibling file and replace the target only after serialization and local schema validation succeed. For reachability, use the graph node nearest each exported spawn as a root; report a node as unreachable only when neither root can reach it in the directed graph.

For route smoke validation, load the graph, reset the active level, then select the node nearest player 2's spawn as the start and a distinct reachable destination. Require the start to satisfy Godot's documented 24-pixel start-node tolerance. Call `set_nav_route`, then advance one-tick steps and inspect player 2's world position until it reaches the destination using the current navigation brain's 8-pixel arrival radius or a bounded deadline expires. Report route failure separately from graph serialization so a usable graph is not misreported as physically exercised.

## Risks / Trade-offs

- [Ephemeral port can be claimed before Godot binds it] → Retry startup a bounded number of times with a newly selected port, and report child output if all attempts fail.
- [The environment's delayed action semantics can be mistaken for a standard Gymnasium transition] → State the one-tick latency in package documentation and `info`; do not claim transition alignment.
- [Geometry can describe surfaces that are not safely traversable] → Use conservative geometric candidates, validate jump/dash with the real probe, and report rejected probes rather than silently retaining them.
- [WALL_JUMP transitions cannot be confirmed by the current probe] → Exclude them in V1 and preserve compatibility with the bridge's graph format.
- [Godot navigation arrival behavior may change independently of protocol version] → Keep the route smoke-check tolerance isolated and make a failed physical route check explicit.
- [Determinism is limited across Godot versions, platforms, and physics configurations] → Record level, seed, speed, protocol version, and Godot executable/version with episode and graph reports; claim repeatability only within the contract's stated scope.

