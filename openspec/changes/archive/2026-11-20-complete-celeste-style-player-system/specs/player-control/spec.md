# Spec Delta

## MODIFIED Requirements

### Requirement: Independent player input
The game SHALL provide separate, remappable Input Map actions for each player's horizontal movement, jump, dash, and any explicitly supported traversal action, without coupling those actions to player appearance.

#### Scenario: Both players provide input simultaneously
- **WHEN** both players press different movement or action inputs during the same physics interval
- **THEN** each player's controller responds only to that player's mapped actions

#### Scenario: Player changes a binding
- **WHEN** a player changes an action binding in Godot's Input Map
- **THEN** that player's corresponding control uses the new binding without changing movement logic

### Requirement: Responsive horizontal movement
Each player SHALL use the same configurable horizontal movement rules, including acceleration, braking, reversal, maximum speed, ground friction, and air control, and SHALL collide with the arena and the other player.

#### Scenario: Accelerating and releasing movement
- **WHEN** a player holds a horizontal direction and then releases it
- **THEN** the player accelerates toward that direction and decelerates according to the configured movement parameters

#### Scenario: Reversing direction
- **WHEN** a player immediately presses the opposite direction
- **THEN** acceleration and braking follow the configured ground or air response without unbounded horizontal speed

#### Scenario: Moving in the air or into a boundary
- **WHEN** a player steers while airborne or contacts the arena or the other player
- **THEN** air control applies and physical movement respects the encountered collision

#### Scenario: Both players use the same movement profile
- **WHEN** P1 and P2 receive identical movement intents in equivalent physical situations
- **THEN** their movement, physics, and collision outcomes are equivalent regardless of their visual profile or human/CPU input source

### Requirement: Assisted variable-height jump
Each player SHALL have a configurable jump whose height responds to button hold duration and whose input is buffered around loss or gain of ground contact, including a bounded coyote interval and a bounded post-landing jump buffer.

#### Scenario: Releasing jump early
- **WHEN** the player releases jump before reaching the configured maximum hold duration
- **THEN** the jump rises less than a maximum-duration jump

#### Scenario: Jumping just before landing
- **WHEN** jump is pressed within the configured buffer interval before landing
- **THEN** the player jumps upon landing

#### Scenario: Jumping just after leaving a ledge
- **WHEN** jump is pressed within the configured Coyote Time interval after leaving a ledge
- **THEN** the player jumps as if still grounded

#### Scenario: Jump buffer expires
- **WHEN** a buffered jump is not eligible before its configured interval expires
- **THEN** the jump is discarded and cannot trigger later unexpectedly

### Requirement: Eight-direction dash
Each player SHALL be able to dash in eight directions using configurable duration, cooldown, and movement parameters, with normalized diagonal direction and a deterministic fallback direction when no direction is held.

#### Scenario: Dashing in a selected direction
- **WHEN** the player activates dash while holding a cardinal or diagonal direction
- **THEN** the dash travels in that direction for the configured duration and diagonal speed is normalized

#### Scenario: Dashing without a direction input
- **WHEN** the player activates dash without a directional input
- **THEN** the dash uses the player's current facing direction

#### Scenario: Dash is unavailable
- **WHEN** a player activates dash while its cooldown or charge restriction is active
- **THEN** no new dash begins

#### Scenario: Dash contacts a surface
- **WHEN** a dash meets a floor, wall, ceiling, or corner
- **THEN** collision resolution prevents passage through the surface and applies the configured dash termination or continuation rule

#### Scenario: Dash charge refills
- **WHEN** a player satisfies the configured refill condition after using a dash
- **THEN** exactly one dash charge becomes available according to the configured refill timing

## ADDED Requirements

### Requirement: Wall traversal and collision response
Each player SHALL detect and resolve floor, wall, and ceiling contacts consistently for normal movement, jumping, wall sliding, wall jumping, and dashing, using physical hitboxes independent of sprite dimensions.

#### Scenario: Falling beside a wall
- **WHEN** an airborne player presses toward a detected wall while descending
- **THEN** the player enters wall-slide behavior and its falling speed follows the configured slide limit

#### Scenario: Wall jump
- **WHEN** the player jumps while a valid wall contact is within range
- **THEN** the player receives the configured vertical and away-from-wall impulse and any bounded directional lock

#### Scenario: Landing and touching ceilings
- **WHEN** the player's collision body reaches a floor or ceiling
- **THEN** vertical movement and grounded/jump state update consistently without embedding the body in geometry

#### Scenario: Hitbox is independent of appearance
- **WHEN** P1 and P2 use visual assets with different dimensions
- **THEN** equivalent collision configuration yields identical physical extents and contact behavior

#### Scenario: Narrow surfaces and corners
- **WHEN** the player approaches a narrow ledge or geometric corner during normal motion or dash
- **THEN** the configured support and correction rules avoid false grounded/wall contacts and prevent tunneling through colliders

### Requirement: Match-safe movement execution
Human and CPU movement SHALL pass through one shared movement and collision contract while preserving existing contact validation, dash-rescue limits, arena-surface roles, and turn behavior.

#### Scenario: CPU chooses a movement action
- **WHEN** the CPU chooses movement, jump, or dash
- **THEN** the same movement physics and collision rules used by human players execute that intent

#### Scenario: Movement creates a balloon contact
- **WHEN** a player contacts or rescues the balloon during a movement action
- **THEN** the existing turn and contact validation determines whether the contact is accepted

#### Scenario: One dash overlaps the balloon more than once
- **WHEN** one dash activation remains in contact with or re-enters the balloon
- **THEN** it cannot register additional hits beyond the existing dash-rescue contract

#### Scenario: Arena surface grants a movement interaction
- **WHEN** a player contacts a configured trampoline, one-way platform, climbable surface, or scoring ground
- **THEN** only that surface's existing game rule is applied and unrelated movement states do not change its role
