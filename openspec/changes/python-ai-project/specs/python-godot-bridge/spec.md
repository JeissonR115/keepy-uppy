# Spec Delta

## Purpose

Provides a typed Python interface to the existing Godot TCP/JSON bridge and manages a headless game process without importing game code or changing the protocol.

## ADDED Requirements

### Requirement: Python client follows the documented bridge protocol
The Python client SHALL expose typed operations for every documented control command and SHALL preserve the protocol's session, sequence, action, observation, geometry, graph, probe, and episode-event data.

#### Scenario: Use all documented control operations
- **WHEN** a caller requests reset, step, speed, geometry, movement probe, graph load, route selection, or close
- **THEN** the client sends the corresponding version-1 command and returns its typed result without changing payload semantics

#### Scenario: Exchange an action and observation
- **WHEN** the server sends a version-1 observation during a step
- **THEN** the client exposes the documented player, balloon, turn, score, level, movement-state fields and accepts an action with all six required intent fields

#### Scenario: Receive an episode event
- **WHEN** the server emits an episode event asynchronously
- **THEN** the client makes its type, reason, player, winner, and score available to the caller

### Requirement: Bridge failures are explicit
The Python client SHALL reject unsupported protocol versions and invalid or incomplete messages, and SHALL report timeout, disconnection, and server errors without returning success-shaped defaults.

#### Scenario: Server protocol version is incompatible
- **WHEN** the hello or a subsequent message has a protocol version other than the documented version
- **THEN** the client raises an identifiable protocol error before accepting the message

#### Scenario: Bridge times out or disconnects
- **WHEN** a read or command exceeds its configured timeout or the socket closes unexpectedly
- **THEN** the client reports an identifiable timeout or connection error to the caller

#### Scenario: Server rejects a command
- **WHEN** the server returns a protocol error
- **THEN** the client surfaces the server's error code and message to the caller

### Requirement: Godot launcher manages headless process lifecycle
The launcher SHALL start the configured Godot project in headless mode, wait for a valid bridge handshake, and close or terminate the child process when its owner finishes.

#### Scenario: Start with a free local port
- **WHEN** a caller starts a simulation without specifying a port
- **THEN** the launcher selects an available loopback port, passes it with the requested level, speed, seed, and mode, and returns a connected bridge client only after a valid hello

#### Scenario: Start with explicit configuration
- **WHEN** settings are supplied through command-line options, environment variables, or the optional TOML configuration file
- **THEN** the resolved Godot binary, project path, port, level, speed, and seed use command-line values before environment values, environment values before file values, and defaults last

#### Scenario: Godot fails to start or handshake
- **WHEN** the child exits, cannot bind the selected port, or does not provide a valid hello before the startup timeout
- **THEN** startup fails with a diagnostic and the child process is reaped

#### Scenario: Close a launched simulation
- **WHEN** the owner closes the managed simulation
- **THEN** the launcher sends the bridge close command when possible, waits for graceful shutdown, and terminates the child if it does not exit within the configured grace period
