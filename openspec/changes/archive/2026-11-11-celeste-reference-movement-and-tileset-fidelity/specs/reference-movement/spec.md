# Spec Delta

## Purpose

Defines how movement and player presentation are reconciled with the inspected Godot 4 Celeste movement demo while keeping the platform controller usable by both local players and the Keepy Uppy CPU.

## ADDED Requirements

### Requirement: Reference mechanics are behaviorally traceable
Movement behaviors adopted from the reference SHALL be compared against its source implementation and documented with their adapted parameters and any intentional differences required by Keepy Uppy.

#### Scenario: Reference behavior is adopted
- **WHEN** a movement mechanic from the reference is integrated or adjusted
- **THEN** its source behavior and any project-specific adaptation are recorded and covered by an observable acceptance check

#### Scenario: A reference mechanic conflicts with match play
- **WHEN** a reference behavior would bypass a Keepy Uppy movement, collision, or match rule
- **THEN** the game-specific rule remains authoritative and the difference is documented

### Requirement: Shared player movement supports reference platform mechanics
The shared player movement system SHALL provide the compatible reference behaviors for horizontal movement, jump assistance, wall jump, wall slide, and directional dash to both human and CPU controlled players.

#### Scenario: Human player uses an adopted mechanic
- **WHEN** a human player performs a supported movement action
- **THEN** the player follows the adopted behavior and configured movement parameters

#### Scenario: CPU uses an adopted mechanic
- **WHEN** the CPU chooses an available movement action
- **THEN** it uses the same movement execution and collision rules as a human player

### Requirement: Movement presentation follows movement state
Player animation and movement-related visual effects SHALL reflect the actual movement state and direction, including wall interaction and dash, without changing collision or match outcomes.

#### Scenario: Player changes movement state
- **WHEN** the player lands, jumps, slides on a wall, wall jumps, or dashes
- **THEN** the visible animation and effects correspond to the active state and settle back to the normal appearance when the state ends

### Requirement: Match interaction remains validated during movement
Additional movement capabilities SHALL continue to submit balloon contacts through the existing match validation flow and SHALL NOT create extra valid touches from one dash activation.

#### Scenario: Movement creates a balloon contact
- **WHEN** a player contacts or rescues the balloon during a movement action
- **THEN** the existing turn and contact validation determines whether the contact is accepted

#### Scenario: One dash overlaps the balloon more than once
- **WHEN** one dash activation remains in contact with or re-enters the balloon
- **THEN** it cannot register additional hits beyond the existing dash-rescue contract
