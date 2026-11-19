# Spec Delta

## ADDED Requirements

### Requirement: Suppress repeated balloon contact after dash rescue
After a player makes a valid balloon contact during a dash, the game SHALL ignore further balloon contacts from that same player until the same dash activation ends.

#### Scenario: Player touches balloon during dash
- **WHEN** a player makes a valid balloon contact during an active dash and the dash continues
- **THEN** further body contacts between that player and the balloon are ignored until the dash ends, while the other player's contacts remain available

#### Scenario: Player dashes without touching balloon
- **WHEN** a dash ends without making a valid balloon contact
- **THEN** the player's normal balloon contact remains available throughout the dash

#### Scenario: Dash activation ends
- **WHEN** a dash activation that touched the balloon ends
- **THEN** the player's normal balloon contact is available again for a later contact
