# Spec Delta

## Purpose

Provides a small episode-oriented Python environment over the Godot bridge, so callers can reset a seeded level, apply actions, and observe terminal outcomes without adopting a training algorithm.

## ADDED Requirements

### Requirement: Reset starts a seeded level
The environment SHALL reset the bridge with the requested seed and level and return the resulting observation together with reset metadata.

#### Scenario: Reset a supported level
- **WHEN** a caller resets with an integer seed and a supported level id
- **THEN** the environment returns the bridge's initial observation and metadata containing the selected seed and level

#### Scenario: Reset fails
- **WHEN** the bridge rejects the level, cannot reset, or disconnects
- **THEN** the environment surfaces the identifiable bridge error and does not return a fabricated initial observation

### Requirement: Step exposes the bridge's one-tick action-response latency
The environment SHALL return `(observation, reward, terminated, truncated, info)` and SHALL document that the submitted action is sent in response to an observation and is consumed on the following physics tick; the result describes the just-completed bridge step. V1 SHALL use `reward=0.0` only as an explicitly provisional placeholder.

#### Scenario: Apply a valid action
- **WHEN** the caller submits an action with all documented intent fields
- **THEN** the environment sends it with the matching observation sequence, records that sequence and the queued-action status in `info`, and returns the completed step's observation with `reward=0.0` and `truncated=false`

#### Scenario: First action after reset
- **WHEN** the caller submits an action before an observation sequence is outstanding
- **THEN** the environment advances one bridge step to obtain an observation, replies with the action, and indicates in `info` that the action has not yet affected the returned state

#### Scenario: Invalid action
- **WHEN** the action omits a required field or contains an invalid value
- **THEN** the environment rejects it before sending a partial action to Godot

#### Scenario: Episode-ending event
- **WHEN** the bridge marks the step as episode-ending and supplies a terminal point or match event
- **THEN** `terminated` is true for the completed bridge step and `info` includes the event and its reason, independently of whether the submitted action is still queued

#### Scenario: Non-terminal replay event
- **WHEN** the bridge reports a downward-fault replay without ending the episode
- **THEN** `terminated` remains false and `info` preserves the replay event

### Requirement: Close releases environment resources
The environment SHALL close its bridge session and any Godot process it owns when the caller closes it.

#### Scenario: Close an active environment
- **WHEN** the caller closes an environment with an active session
- **THEN** the environment requests protocol close, waits for managed process shutdown, and leaves no owned child process running
