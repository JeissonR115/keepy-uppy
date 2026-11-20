# Proposal

## Why

The Godot game now exposes a versioned TCP/JSON bridge, reproducible headless simulation, level geometry, physical movement probes, and per-level navigation graphs. A separate Python project is needed to turn those interfaces into a maintainable client, training environment, and graph-generation tool without importing or modifying game code.

## What Changes

- Create `../keepy-uppy-ai` as an independent Git repository and Python 3.11+ project managed by `uv`, with the requested package layout, tests, documentation, generated-graph directory, and its own initialized OpenSpec root and conventions guide.
- Add a typed bridge client and Godot headless process launcher. Use the existing `docs/cpu-ai-bridge.md` contract for all commands, observations, actions, events, graph data, errors, and protocol versioning.
- Add a lightweight environment with `reset(seed, level)`, `step(action)`, and `close()` that exposes bridge observations and terminal-event reasons in a five-value Gymnasium-shaped result. It uses `reward=0.0` as an explicitly provisional placeholder, not a training signal. Because the unchanged bridge consumes an action response on the following physics tick, `step(action)` documents one-tick action-response latency and does not promise standard Gymnasium transition alignment; no algorithm or mandatory Gymnasium dependency is introduced.
- Add a geometry-driven graph generator for all four current levels. Generate WALK and DROP transitions from geometry rules and JUMP and DASH candidates validated with the real movement probe; export schema-version-1 JSON, load it in Godot, and check a reachable route.
- Report node counts, edge counts by action, rejected candidates, and nodes unreachable from either player spawn.
- Defer generation of WALL_JUMP edges in V1. The existing Godot probe only supports jump and dash; the Python generator will not label an unverified transition as WALL_JUMP. The graph format and bridge client remain compatible with WALL_JUMP edges supplied by other sources.
- Update the Godot repository's documentation only to point to the sibling AI project; do not change game code or the bridge protocol.

## Capabilities

### New Capabilities

- `python-godot-bridge`: Typed client and managed Godot headless process lifecycle using the documented TCP/JSON protocol.
- `python-training-environment`: Reset, step, close, observation, action, and terminal-event behavior for a minimal training environment.
- `navigation-graph-generation`: Per-level geometry analysis, movement-probe validation, schema-version-1 graph export, route smoke checks, and generation reports.

### Modified Capabilities

None. The existing Godot protocol and gameplay requirements remain unchanged.

## Impact

- New independent project at `../keepy-uppy-ai`; it will have its own Git history and OpenSpec root and will not import game modules.
- Python 3.11+ standard library at runtime, `uv` for project and environment management; no mandatory Gymnasium or NumPy dependency.
- The Godot project is only referenced through its filesystem path and the existing bridge. Its `docs/cpu-ai-bridge.md` receives a location reference, with no runtime changes.
- Optional end-to-end tests require `GODOT_BIN` and the path to this Godot project.
