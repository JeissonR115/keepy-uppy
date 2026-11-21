# Spec Delta

## Purpose

Define el comportamiento del oponente CPU local para que compita durante ambos turnos sin reemplazar las físicas compartidas ni las reglas autoritativas de la partida.

## ADDED Requirements

### Requirement: CPU responds to match turns
When enabled for a player, the CPU SHALL select behavior from the active match state and the player expected to contact the balloon.

#### Scenario: CPU has the expected balloon turn
- **WHEN** the match is active and the CPU player is the expected balloon player
- **THEN** the CPU selects its own-turn behavior and may pursue a valid balloon contact

#### Scenario: Human has the expected balloon turn
- **WHEN** the match is active and another player is expected to contact the balloon
- **THEN** the CPU selects rival-turn behavior instead of remaining idle

#### Scenario: CPU is disabled or match is inactive
- **WHEN** the CPU is disabled or the match is not active
- **THEN** the CPU issues no autonomous movement or action intents

### Requirement: CPU intercepts the balloon on its turn
On its own turn, the CPU SHALL pursue a predicted balloon interception point and use the shared player movement and contact mechanics to attempt a valid return.

#### Scenario: Balloon is moving toward an attainable contact
- **WHEN** the CPU has the expected turn and the balloon has a predictable interception within the configured horizon
- **THEN** the CPU steers toward the predicted contact point, applying its configured reaction delay and prediction error

#### Scenario: Interception needs a dash
- **WHEN** the predicted contact cannot be reached with ordinary movement and the configured dash threshold is met
- **THEN** the CPU requests a dash only if the player's existing dash rules permit it

#### Scenario: No reliable interception exists
- **WHEN** no interception can be predicted within the configured horizon
- **THEN** the CPU uses a safe recovery target and does not issue an unbounded chase target

### Requirement: CPU avoids invalid balloon contact on the rival turn
When another player is expected to contact the balloon, the CPU SHALL prioritize avoiding an unintended balloon contact over tactical obstruction.

#### Scenario: Balloon threatens the CPU
- **WHEN** the projected balloon path intersects the CPU's contact area during the rival's turn
- **THEN** the CPU moves toward a safe position outside that projected path

#### Scenario: Evading while rival owns the turn
- **WHEN** the CPU moves or dashes during the rival's turn
- **THEN** any resulting balloon contact remains subject to normal MatchManager validation and is resolved as an out-of-turn fault if invalid

### Requirement: CPU may tactically obstruct the rival
During the rival's turn, the CPU SHALL attempt tactical positioning only when its safety check passes and its configured aggression decision selects obstruction.

#### Scenario: Safe obstruction is selected
- **WHEN** the CPU is outside the projected balloon threat and the aggression decision selects obstruction
- **THEN** the CPU positions itself toward the direct path between the rival and the balloon using ordinary player collision behavior

#### Scenario: Safety takes precedence
- **WHEN** obstruction would place the CPU in the projected balloon threat or cause an avoidable invalid contact
- **THEN** the CPU selects the safe position instead of obstructing

### Requirement: CPU difficulty is configurable
The CPU SHALL expose configurable reaction delay, prediction-error bound, obstruction aggression, and dash-decision threshold.

#### Scenario: Difficulty parameters are adjusted
- **WHEN** a valid difficulty parameter is changed
- **THEN** the corresponding CPU decision reflects the new value without changing human-player movement or match rules

#### Scenario: Prediction error is applied
- **WHEN** prediction error is enabled
- **THEN** the CPU's interception target deviates by no more than the configured maximum error

### Requirement: CPU decisions are repeatable
Given the same match seed, initial game state, CPU configuration, and sequence of physics states, the CPU SHALL produce the same decisions.

#### Scenario: Repeat an identical match setup
- **WHEN** two runs use identical initial state, seed, configuration, and physics-state sequence
- **THEN** the CPU selects the same states, targets, movement intents, and actions in both runs

#### Scenario: Change the difficulty seed
- **WHEN** the initial state and configuration are unchanged but the match seed differs
- **THEN** seeded imperfection may produce a different bounded prediction error or aggression decision without exceeding configured limits
