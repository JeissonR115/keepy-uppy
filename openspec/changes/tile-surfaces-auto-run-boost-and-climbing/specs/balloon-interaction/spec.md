# Spec Delta

## MODIFIED Requirements

### Requirement: Predictable balloon motion
The balloon SHALL move under configurable lightweight physics, interact with arena surfaces according to their declared roles, and report contact with the scoring ground.

#### Scenario: Balloon moves and rebounds
- **WHEN** the balloon is in play and receives gravity or a valid hit
- **THEN** it moves and rebounds according to the configured physics parameters without unbounded speed

#### Scenario: Balloon reaches the ground
- **WHEN** the balloon makes contact with a surface designated as scoring ground
- **THEN** one ground-contact event is reported for the current round

#### Scenario: Balloon reaches a non-scoring solid surface
- **WHEN** the balloon collides with an ordinary solid surface that is not designated as scoring ground
- **THEN** it rebounds or is blocked according to that surface's physics without reporting ground contact

#### Scenario: Balloon passes through a one-way platform
- **WHEN** the balloon reaches a one-way platform intended only for player traversal
- **THEN** it passes through without reporting ground contact

#### Scenario: Balloon rebounds from a trampoline
- **WHEN** the balloon contacts a trampoline surface
- **THEN** it receives an upward rebound and remains in play without reporting ground contact or ending the round

#### Scenario: Repeated contact with scoring ground
- **WHEN** the balloon remains in contact with or re-enters the scoring ground during the same round
- **THEN** only one ground-contact event is reported for that round
