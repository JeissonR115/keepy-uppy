# CPU AI bridge protocol

The Godot bridge is a TCP server bound to `127.0.0.1`. It accepts one client
at a time and exchanges UTF-8 JSON objects, one per line. Each line is limited
to 1 MiB. The protocol version is `1`.

## Connection and message ordering

1. Connect to the configured port. The first server message is:

   ```json
   {"type":"hello","protocol_version":1,"session_id":"..."}
   ```

2. Copy `session_id` into every command and action. The server rejects messages
   from another session.
3. Commands use a positive, strictly increasing `sequence`. Action responses
   reuse the `sequence` of their observation; they do not consume command
   sequence numbers. A response for an expired observation is rejected.
4. `reset` returns the initial state in
   `command_result.result.observation`. Read and answer sequenced `observation`
   messages during `step`; the step result contains the state after the batch.
5. Send the `close` command before closing the TCP connection.

Every client message includes `type`, `protocol_version`, and `session_id`.
The server validates each JSON line independently. A rejected message produces
an `error` with a stable `code` and explanatory `message`.

## Control commands

Commands use this envelope:

```json
{
  "type":"command",
  "protocol_version":1,
  "session_id":"...",
  "sequence":1,
  "command":"reset",
  "payload":{"seed":42,"level":"classic"}
}
```

| Command | Payload | Meaning |
| --- | --- | --- |
| `reset` | `{"seed": integer, "level": string}` | Start an episode with the requested seed and level. |
| `step` | `{"n": positive_integer}` | Advance up to `n` fixed physics steps. |
| `set_speed` | `{"speed": positive_finite_number}` | Set simulation speed without changing the physics step. |
| `get_level_geometry` | `{}` or `{"level": string}` | Request geometry for the active or named level. |
| `probe_movement` | Movement, start position, and action-specific direction data | Probe a jump or dash with the real player physics in an isolated world. |
| `load_nav_graph` | `{"graph": object}` | Validate and cache a navigation graph for its level. |
| `set_nav_route` | `{"level": string, "start_node": integer, "destination_node": integer}` | Make player 2's CPU follow a route in the active level's loaded graph. |
| `close` | `{}` | End this bridge session. |

A successful command returns:

```json
{
  "type":"command_result",
  "protocol_version":1,
  "session_id":"...",
  "sequence":1,
  "ok":true,
  "result":{}
}
```

`reset` includes the selected `seed`, `level`, and first complete state under
`result.observation`. A `step` result includes `steps`,
`physics_frames_elapsed`, `complete`, and the final `observation`. The
`set_speed` result reports the effective `speed`,
`physics_ticks_per_second`, and `physics_delta`; rates are rounded to a whole
physics tick and capped at 1200 ticks per second so the per-tick delta remains
fixed.

`step` stops at a completed point or match, and its result sets
`episode_ended` when such a terminal event occurs. An event is also delivered
asynchronously:

```json
{
  "type":"episode_event",
  "protocol_version":1,
  "session_id":"...",
  "event":{
    "type":"fault",
    "reason":"out_of_turn_contact",
    "player":"player_2",
    "winner":"player_1",
    "score":{
      "points":{"player_1":1,"player_2":0},
      "sets":{"player_1":0,"player_2":0}
    }
  }
}
```

Event types are `fault` and `point` (a fault is followed by its resulting
point), `downward_fault_replay`, `set`, and `match`. Reasons include
`out_of_turn_contact`, `ground_before_valid_contact`, `ball_grounded`,
`spikes`, `downward_hit`, `score_target_reached`, and `sets_target_reached`.
Every event includes `player`, `winner`, and `score`; a non-terminal replay
uses an empty `winner`. The step result's `events` array contains the same
events produced during that step.

## Observation

Godot sends an observation whenever the CPU needs a decision:

```json
{
  "type":"observation",
  "protocol_version":1,
  "session_id":"...",
  "sequence":7,
  "observation":{
    "tick":120,
    "bot_player":"player_2",
    "players":{
      "player_1":{
        "position":{"x":72.0,"y":144.0},
        "velocity":{"x":0.0,"y":0.0},
        "on_floor":true,
        "wall_contact":0.0,
        "dash_cooldown":0.0,
        "dash_available":true,
        "stamina":110.0
      },
      "player_2":{
        "position":{"x":248.0,"y":144.0},
        "velocity":{"x":0.0,"y":0.0},
        "on_floor":true,
        "wall_contact":0.0,
        "dash_cooldown":0.0,
        "dash_available":true,
        "stamina":110.0
      }
    },
    "balloon":{
      "position":{"x":160.0,"y":90.0},
      "velocity":{"x":0.0,"y":0.0},
      "waiting_for_first_touch":true
    },
    "current_turn":"player_1",
    "score":{
      "points":{"player_1":0,"player_2":0},
      "sets":{"player_1":0,"player_2":0}
    },
    "level":"classic"
  }
}
```

`wall_contact` is `-1` for left contact, `1` for right contact, and `0` for no
contact. `current_turn` is the expected player id, or an empty string when no
turn is assigned. Positions and velocities are world-space pixels and pixels
per second.

## Action

Reply to an observation with its sequence number:

```json
{
  "type":"action",
  "protocol_version":1,
  "session_id":"...",
  "sequence":7,
  "action":{
    "horizontal":-1.0,
    "jump":false,
    "dash":true,
    "dash_direction":{"x":-1.0,"y":0.0},
    "down":false,
    "grab":true
  }
}
```

`horizontal` must be finite and in `[-1, 1]`; `jump`, `dash`, `down`, and
`grab` must be booleans. `dash_direction.x` and `.y` must be finite numbers.
All six fields are required. An action is applied only once and only while its
observation sequence is outstanding.

## Errors

Errors have this shape; `sequence` is included when it can be identified:

```json
{
  "type":"error",
  "protocol_version":1,
  "session_id":"...",
  "sequence":7,
  "code":"invalid_action",
  "message":"Action horizontal must be between -1 and 1."
}
```

Common codes include `malformed_json`, `invalid_session`, `invalid_sequence`,
`invalid_payload`, `invalid_action`, `unknown_command`, and
`message_too_large`. Invalid messages do not partially apply.

## Headless simulation launcher

Start the simulation scene directly; it has no menus and listens on loopback:

```sh
godot --headless --path . res://src/scenes/simulation/cpu_simulation.tscn -- \
  --port=8765 --level=classic --speed=1 --seed=42 --mode=cpu-vs-cpu
```

The runner accepts `--port`, `--level`, `--speed`, `--seed`, and `--mode`, in
either `--name=value` or `--name value` form. Defaults are port `8765`, level
`classic`, speed `1`, seed `1`, and mode `cpu-vs-cpu`. The port must be in
`1..65535`; level must be an available arena id; seed is an integer; and speed
must be positive and finite. Current level ids are `primary-flat`,
`hazard-arena`, `classic`, and `sky-towers`. Modes are `cpu-vs-cpu` and
`cpu-vs-scripted`.
In CPU-vs-CPU mode, player 2 uses the remote brain when connected and falls
back to its local brain otherwise. CPU-vs-scripted assigns the scripted brain
to player 2. Player 1 uses the local brain in both modes.

Speed scales the physics tick rate while preserving the per-tick physics
delta. The effective speed is rounded to a whole tick and the rate is capped
at 1200 ticks per second; values that round below one tick per second or
exceed the cap are rejected. The machine's throughput still limits how fast
wall-clock execution can advance.

For example, launch CPU versus the scripted player on another arena:

```sh
godot --headless --path . res://src/scenes/simulation/cpu_simulation.tscn -- \
  --port=8766 --level=sky-towers --speed=2 --seed=123 --mode=cpu-vs-scripted
```

Connect the included client to reset the episode, exchange two one-tick
steps, and close:

```sh
python3 examples/cpu_bridge_client.py --host 127.0.0.1 --port 8765 \
  --level classic --seed 42
```

To run a batch of `N` episodes, keep a client connected and repeat `reset`
with each episode's seed and level. Call `step(1)` until its result has
`episode_ended: true`; answer every observation with an action, collect any
`episode_event` messages, then record the result and reset for the next
episode. Using one-tick steps and waiting for each result before requesting
the next step keeps the action sequence explicit.

Reproducibility is scoped to the same Godot version, physics configuration,
level, seed, and action sequence. It is not a guarantee of bit-identical
physics across engine versions, platforms, or different simulation settings.
For remote control, the client must also answer observations before requesting
the next step; a late or missing action uses the local-brain fallback.

## Level geometry

`get_level_geometry` accepts an optional level id; without it, the active
level is exported. Its `command_result.result` has `schema_version: 1`,
the `level` id, `bounds` and `safe_bounds` rectangles, both player `spawns`,
generated `auxiliary_bounds`, `collisions`, `platforms`, and
`movement_constants`. Rectangles use `{ "position": { "x", "y" }, "size":
{ "x", "y" } }`. The auxiliary entries describe the left, right, and ceiling
safe-boundary rectangles created by `LevelManager`.

The following is a shortened but valid excerpt from `classic`; the arrays
contain one entry here, while a real response contains every collision:

```json
{
  "schema_version":1,
  "level":"classic",
  "bounds":{"position":{"x":0,"y":0},"size":{"x":320,"y":180}},
  "safe_bounds":{"position":{"x":8,"y":8},"size":{"x":304,"y":164}},
  "spawns":{
    "player_1":{"x":72,"y":144},
    "player_2":{"x":248,"y":144}
  },
  "auxiliary_bounds":[
    {"name":"SafeLeftBoundary","center":{"x":4,"y":90},"size":{"x":8,"y":180}},
    {"name":"SafeRightBoundary","center":{"x":316,"y":90},"size":{"x":8,"y":180}},
    {"name":"SafeCeilingBoundary","center":{"x":160,"y":4},"size":{"x":304,"y":8}}
  ],
  "collisions":[
    {
      "source":"LeftBoundary/CollisionShape2D",
      "shape":{"type":"rectangle","size":{"x":16,"y":180}},
      "transform":{
        "origin":{"x":0,"y":90},
        "x_axis":{"x":1,"y":0},
        "y_axis":{"x":0,"y":1}
      },
      "collision_layer":1,
      "collision_mask":0,
      "one_way":false
    }
  ],
  "platforms":[
    {
      "source":"OneWayPlatforms",
      "cell":{"x":8,"y":14},
      "cell_position":{"x":68,"y":116},
      "cell_transform":{
        "alternative":0,
        "flip_h":false,
        "flip_v":false,
        "transpose":false
      },
      "physics_layer":1,
      "collision_layer":4,
      "collision_mask":0,
      "points":[
        {"x":-4,"y":-4},{"x":4,"y":-4},
        {"x":4,"y":4},{"x":-4,"y":4}
      ],
      "one_way":true,
      "one_way_margin":2
    }
  ],
  "movement_constants":{
    "GRAVITY":1100,
    "MAX_FALL":220,
    "JUMP_SPEED":-250,
    "DASH_SPEED":300,
    "DASH_TIME":0.2,
    "DASH_COOLDOWN":0.2
  }
}
```

Non-tile collision entries include the local `shape` descriptor and an affine
`transform` (`origin`, `x_axis`, and `y_axis`) in world coordinates. Supported
shape descriptors include rectangles, circles, capsules, segments, convex
and concave polygons, world boundaries, and separation rays. Tile polygons
are exported individually: `points` are relative to the cell center,
`cell_position` is that center in world coordinates, and `cell_transform`
reports the alternative id and its flip/transpose flags. `collision_layer`
and `collision_mask` are the actual TileSet physics values. One-way polygons
are placed in `platforms` with their one-way margin; other TileSet polygons
are in `collisions`. Movement constant names and numeric values are read from
`PlayerMovementConstants` at runtime.

## Physical movement probes

`probe_movement` runs a duplicate of the selected arena and the actual
`PlayerController` in a separate `World2D`, so it does not advance or modify
the active match, its balloon, or its score. A jump waits until the player is
grounded before triggering; its horizontal intent must be finite and in
`[-1, 1]`. A dash requires a non-zero finite direction vector, which Godot
normalizes. Both commands require a world-space `start_position`; `level` is
optional and defaults to the active level.

Jump request:

```json
{
  "movement":"jump",
  "level":"classic",
  "start_position":{"x":160,"y":152},
  "horizontal":0
}
```

Dash request:

```json
{
  "movement":"dash",
  "level":"classic",
  "start_position":{"x":80,"y":152},
  "direction":{"x":1,"y":-1}
}
```

The result reports `action_started`, `landed`, `landing_position` (null if
the probe did not land within 1200 physics frames), `final_position`,
`physics_frames_elapsed`, the fixed `physics_delta`, and a `reason` when the
probe did not land. For example, a successful jump in `classic` returns:

```json
{
  "level":"classic",
  "movement":"jump",
  "start_position":{"x":160,"y":152},
  "action_started":true,
  "landed":true,
  "landing_position":{"x":160,"y":151.9953},
  "final_position":{"x":160,"y":151.9953},
  "physics_frames_elapsed":57,
  "physics_delta":0.0166667,
  "reason":""
}
```

## Navigation graph

`load_nav_graph` accepts a graph object with `schema_version: 1`:

- `level` is an arena id from the level catalog.
- `nodes` is a non-empty array. Each node has a unique integer `id` and a
  finite world-space `position` with numeric `x` and `y`.
- `edges` is an array of directed transitions. Each edge has integer `from`
  and `to` node ids, a supported `action`, and a finite positive `cost`.
  `bidirectional` is optional and defaults to `false`; when true, the reverse
  transition is added with the same action and cost.
- Supported actions are `WALK`, `JUMP`, `DASH`, `DROP`, and `WALL_JUMP`.
- Node ids must be unique, edge references must exist, self-edges and
  duplicate directed edges are rejected, and an invalid graph does not replace
  a previously loaded graph.

The coordinates use world-space pixels, as in the matching level-geometry
response; graph dimensions are not shared across arenas. `AStar2D` chooses the
lowest-cost route, independent of edge length. The action and cost belong to
each directed edge.

This valid `classic` example includes all action types. Its low-cost path from
node `1` to node `6` is `1 -> 2 -> 3 -> 4 -> 5 -> 6`, rather than the direct,
higher-cost WALK edge:

```json
{
  "schema_version": 1,
  "level": "classic",
  "nodes": [
    {"id": 1, "position": {"x": 248.0, "y": 144.0}},
    {"id": 2, "position": {"x": 232.0, "y": 144.0}},
    {"id": 3, "position": {"x": 200.0, "y": 110.0}},
    {"id": 4, "position": {"x": 160.0, "y": 110.0}},
    {"id": 5, "position": {"x": 120.0, "y": 148.0}},
    {"id": 6, "position": {"x": 80.0, "y": 110.0}}
  ],
  "edges": [
    {"from": 1, "to": 2, "action": "WALK", "cost": 1.0, "bidirectional": true},
    {"from": 2, "to": 3, "action": "JUMP", "cost": 1.2},
    {"from": 3, "to": 4, "action": "DASH", "cost": 0.9},
    {"from": 4, "to": 5, "action": "DROP", "cost": 1.1},
    {"from": 5, "to": 6, "action": "WALL_JUMP", "cost": 1.8},
    {"from": 1, "to": 6, "action": "WALK", "cost": 20.0}
  ]
}
```

Load the graph with the normal command envelope and then request the route:

```json
{
  "type": "command",
  "protocol_version": 1,
  "session_id": "...",
  "sequence": 8,
  "command": "set_nav_route",
  "payload": {
    "level": "classic",
    "start_node": 1,
    "destination_node": 6
  }
}
```

`set_nav_route` requires the named level to be active, its graph to be loaded,
and player 2 to be within 24 world-space pixels of the start node. On success
the result includes `route_node_ids`; missing graphs, inactive levels and
invalid or unreachable routes return explicit protocol errors. The debug
overlay draws the active level's nodes and edges and highlights the selected
route. Resetting to a level displays only that level's cached graph (or clears
the overlay if none is loaded); a reset selects the default CPU brain, so send
`set_nav_route` again to start following a route in the new episode.

The example's schema and weighted path are exercised by the headless
simulation-control test, which also checks route movement, overlay display and
switching between `classic` and `sky-towers`. The graph schema validates data
shape and connectivity, not whether a transition is physically feasible;
validate proposed transitions with `probe_movement` and the target arena's
exported geometry.

## Python client

The standard-library client in
[`examples/cpu_bridge_client.py`](../examples/cpu_bridge_client.py) implements
framing, session/sequence fields, command helpers, action validation, and
server error reporting. Run it against a simulation that has started its
bridge:

```sh
python3 examples/cpu_bridge_client.py --host 127.0.0.1 --port 8765 \
  --level classic --seed 42
```

The example resets the episode, executes two single-tick steps while answering
any observations, and closes the session. For CPU decisions, answer an
observation before requesting the next step so its action is ready for that
physics tick.
