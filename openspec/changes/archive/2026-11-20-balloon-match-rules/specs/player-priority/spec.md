# Spec Delta

## Purpose

Defines how the server and current priority player are selected and how valid balloon contacts affect competitive advantage. Point winner, next server, and in-point priority remain distinct states.

## ADDED Requirements

### Requirement: Opening server and service contact
The game SHALL select the first server by one random coin toss per match, assign that player opening priority, and count the serve as that player's first valid balloon contact of the point.

#### Scenario: Match opens with heads or tails
- **WHEN** a new match performs its coin toss
- **THEN** heads selects Player 1 and tails selects Player 2 as first server and opening-priority player, and the result is shown

#### Scenario: Point is served
- **WHEN** the server puts the balloon into play
- **THEN** the serve is recorded as that player's valid contact and last-touch attribution for the point

### Requirement: Priority follows accepted contacts
The game SHALL track the last valid toucher and current priority independently from point score, and SHALL reset opening priority to the server at each new point.

#### Scenario: Player makes a normal contact
- **WHEN** a normal contact is accepted for a point
- **THEN** that player becomes the last valid toucher and current priority player

#### Scenario: Player makes a dash rescue contact
- **WHEN** a dash-rescue contact is accepted for a point
- **THEN** that player becomes the last valid toucher and current priority player

#### Scenario: Next point begins
- **WHEN** the next point is prepared
- **THEN** its server is the previous point winner and that server receives opening priority

### Requirement: Deterministic simultaneous-contact resolution
The game SHALL resolve contacts collected in the same physics tick by contact type and prior priority rather than callback order.

#### Scenario: Dash rescue and normal hit coincide
- **WHEN** a dash-rescue contact and a normal hit are both accepted during one physics tick
- **THEN** the dash-rescue player is selected as the last toucher and priority player for that tick

#### Scenario: Same-type contacts coincide
- **WHEN** both players make accepted contacts of the same type during one physics tick
- **THEN** the player who did not hold priority before that tick receives priority and last-touch attribution

### Requirement: Priority-weighted bounded displacement
Player collisions SHALL apply configurable stronger displacement from the priority player while preserving movement for both players and keeping them inside the arena.

#### Scenario: Priority changes collision strength
- **WHEN** either player displaces the opponent through a normal collision or dash
- **THEN** the configured priority strength is greater than the non-priority strength and resulting velocity stays within its configured bound

#### Scenario: Priority state is visible
- **WHEN** the priority player changes
- **THEN** the presentation identifies the new priority player
