# Spec Delta

## Purpose

Defines how the sibling Python project turns the bridge's per-level geometry and real-physics probes into validated navigation graphs that Godot can load and exercise.

## ADDED Requirements

### Requirement: Generate level nodes from exported geometry
The graph generator SHALL use the selected level's exported bounds, spawns, collisions, platforms, and movement constants to produce world-space nodes on supported floor and platform surfaces, including endpoints, drop boundaries, wall bases, and spawn locations.

#### Scenario: Generate a graph for a current level
- **WHEN** graph generation is requested for `primary-flat`, `hazard-arena`, `classic`, or `sky-towers`
- **THEN** the generator reads that level's geometry from the bridge and produces nodes using its own dimensions and surfaces

#### Scenario: Movement constants come from Godot
- **WHEN** the generator evaluates candidate movement transitions
- **THEN** it uses the `movement_constants` returned by the bridge and does not substitute a Python copy of those values

### Requirement: Validate generated transitions
The generator SHALL derive WALK and DROP transitions from geometry and SHALL retain JUMP and DASH transitions only when a corresponding real-physics probe confirms the candidate landing; V1 SHALL NOT generate WALL_JUMP transitions.

#### Scenario: Confirm a jump or dash edge
- **WHEN** a jump or dash candidate is probed from its source node
- **THEN** the edge is retained only if the probe starts the action, lands, and reports a landing position matching the candidate destination

#### Scenario: Reject an unconfirmed transition
- **WHEN** a probe does not start, does not land, or lands away from the candidate destination
- **THEN** the candidate is excluded from the graph and recorded as discarded with its probe outcome

#### Scenario: Wall jump is unavailable in V1
- **WHEN** the generator creates an edge set
- **THEN** it emits no `WALL_JUMP` edges because the bridge probe does not validate that action

### Requirement: Export schema-version-one graphs
The generator SHALL export each graph to `graphs/<level>.json` using the bridge's schema-version-one JSON contract.

#### Scenario: Write a level graph
- **WHEN** generation completes for a level
- **THEN** the project stores valid graph JSON at `graphs/<level>.json` with that level id and `schema_version` set to `1`

### Requirement: Load and exercise generated graphs
The generator SHALL verify that Godot can load each generated graph and exercise a reachable route on the active level.

#### Scenario: Load a generated graph and request a route
- **WHEN** a generated graph is submitted through `load_nav_graph` and a reachable route is requested from a start node near player 2
- **THEN** Godot accepts the graph and returns the route node ids for the requested destination

#### Scenario: Exercise a generated route
- **WHEN** the route smoke check is run in simulation from the selected start node
- **THEN** it advances the simulation and verifies player 2 reaches the route destination; otherwise it reports the route check as failed

#### Scenario: Generate graphs at different level sizes
- **WHEN** graphs are generated for levels with different bounds
- **THEN** each graph preserves that level's world-space coordinates and remains loadable independently of other levels' dimensions

### Requirement: Report graph coverage and rejected candidates
The generator SHALL report node count, edge counts by action, discarded candidate transitions, and graph nodes unreachable from both player-spawn roots.

#### Scenario: Report generation results
- **WHEN** graph generation finishes for a level
- **THEN** the report distinguishes nodes and accepted edges by action, lists discarded candidates and probe outcomes, and identifies nodes not reachable from either spawn root
