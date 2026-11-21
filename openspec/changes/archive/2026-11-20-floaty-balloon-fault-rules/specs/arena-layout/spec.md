# Spec Delta

## Purpose

Defines the playable collision surfaces in the arena so rallies use a clear floor-only layout without floating platforms interrupting play.

## ADDED Requirements

### Requirement: Floor-only playable platforms
The arena SHALL provide the scoring floor and side boundaries without floating platforms inside the play area.

#### Scenario: Players and balloon move through the arena
- **WHEN** a point is active
- **THEN** the floor and arena side boundaries provide solid arena collisions, and no extra elevated platform blocks player or balloon movement
