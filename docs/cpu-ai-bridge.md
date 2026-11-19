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
| `load_nav_graph` | `{"graph": object}` | Load a navigation graph. |
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
