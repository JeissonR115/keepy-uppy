# Spec Delta

## ADDED Requirements

### Requirement: Balloon color follows the active turn after a downward warning
When a downward-touch warning ends, the balloon SHALL display the color associated with the player expected to make the next valid touch.

#### Scenario: Warning expires without another touch
- **WHEN** the downward-touch warning expires and the rally continues
- **THEN** the balloon displays the current expected player's turn color instead of white

#### Scenario: A valid rescue touch ends the warning
- **WHEN** a valid touch ends the warning and updates the expected player
- **THEN** the balloon displays the new expected player's turn color after the touch presentation completes
