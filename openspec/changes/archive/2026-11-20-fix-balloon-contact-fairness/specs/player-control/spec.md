# Spec Delta

## ADDED Requirements

### Requirement: Wall movement uses arena surfaces only
Players SHALL be able to wall-jump or climb only from valid arena wall surfaces, not from another player, while player-to-player physical collisions remain enabled.

#### Scenario: Players collide without becoming wall surfaces
- **WHEN** one player contacts the other player while moving, jumping, or dashing
- **THEN** their physical collision is preserved, but the contact does not enable wall-jumping or climbing

#### Scenario: Player attempts to climb or wall-jump from opponent
- **WHEN** a player holds the climb input or requests a wall jump while only another player is beside them
- **THEN** no wall-climb or wall-jump action is triggered by that player contact

### Requirement: Grounded wall contact does not trigger a wall jump
A player who is grounded SHALL use the normal grounded jump when jumping beside a wall and SHALL NOT receive an automatic lateral wall-jump impulse from that contact.

#### Scenario: Jumping from the floor beside a wall
- **WHEN** a grounded player presses jump while touching or checking for a nearby wall
- **THEN** the player performs the normal grounded jump without a wall-jump bounce
