# Tasks

## 1. Sibling project bootstrap

- [ ] 1.1 Create `../keepy-uppy-ai` as an independent Git repository with the Python `>=3.11` `uv` project, requested `src/keepy_ai` package layout, `tests/`, `docs/`, and `graphs/`; verify `uv sync`, the expected paths, and that Git/OpenSpec resolve to the sibling project.
- [ ] 1.2 Add the project README and OpenSpec conventions guide with setup, configuration precedence, and a link to the Godot bridge contract; verify the links and documented setup commands resolve.

## 2. Typed bridge client

- [ ] 2.1 Implement protocol value types, TCP line framing, hello/session/version validation, sequence handling, action validation, observation/event dispatch, and explicit transport/protocol errors; verify them with unit tests against a fake TCP server.
- [ ] 2.2 Add typed helpers for reset, step, set_speed, get_level_geometry, probe_movement, load_nav_graph, set_nav_route, and close; verify payloads, response matching, timeout/disconnect behavior, and document that the Godot bridge contract remains authoritative.

## 3. Godot launcher

- [ ] 3.1 Implement CLI/environment/TOML/default configuration resolution, ephemeral loopback port selection, headless process startup, handshake wait, bounded startup retry, diagnostics, and graceful-to-forced shutdown; verify lifecycle and failure paths with a fake Godot executable.
- [ ] 3.2 Document launcher settings and add a separately marked integration test requiring `GODOT_BIN` and the Godot project path; verify the test can launch, connect, reset, and close a real simulation when configured.

## 4. Training environment and episode CLI

- [ ] 4.1 Implement `reset`, `step`, and `close` with the five-value step result, provisional `reward=0.0`, explicit one-tick action-response latency, terminal-event metadata, and resource ownership; verify reset, first-step queuing, subsequent action sequencing, replay, termination, invalid actions, and close with focused tests, and document the non-Gymnasium transition alignment.
- [ ] 4.2 Implement `run-episode` with level, seed, speed, and episode-count options using the launcher and environment; verify a fake-bridge episode reports its seed, level, and terminal reason and that CLI help matches the documented options.

## 5. Navigation graph pipeline

- [ ] 5.1 Implement typed geometry parsing and deterministic support-node generation from bounds, transformed collisions, one-way platforms, wall bases, drop boundaries, and spawns; verify node placement on fixtures for different level dimensions and document geometry assumptions.
- [ ] 5.2 Implement WALK/DROP candidates, JUMP/DASH probe validation, V1 exclusion of WALL_JUMP, positive action-specific costs, schema-version-one serialization, and spawn-root reachability reporting; verify accepted and discarded edges, deterministic JSON, per-action counts, and unreachable-node reporting with focused tests.
- [ ] 5.3 Implement `generate-graph` for one or all current levels, writing `graphs/<level>.json`, loading each graph in Godot, and running a bounded physical route check from a node near player 2's spawn; verify CLI behavior with a fake bridge and document route-check outcomes.

## 6. Cross-project integration

- [ ] 6.1 Add only a location reference to the sibling AI project in the Godot bridge documentation; verify the link points to `../keepy-uppy-ai` without changing game code or protocol text.
- [ ] 6.2 Run the optional real-Godot integration suite across all four levels, exercising a generated graph route and multiple seeded episodes; verify graph loading, route arrival, clean process shutdown, and repeatable results under the same Godot/physics configuration.
