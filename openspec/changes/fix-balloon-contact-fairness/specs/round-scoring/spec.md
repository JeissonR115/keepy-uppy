# Spec Delta

## ADDED Requirements

### Requirement: Downward-hit faults require timely ground contact
A downward-directed balloon contact SHALL remain pending until the balloon reaches the scoring ground or the two-second confirmation window expires.

#### Scenario: Downward hit reaches the floor in time
- **WHEN** a downward-directed hit is followed by scoring-ground contact within two seconds and the opponent has not made a valid contact
- **THEN** the downward fault is confirmed and the existing downward-fault replay or penalty resolution is applied exactly once

#### Scenario: Opponent touches before the floor
- **WHEN** the opponent makes a valid balloon contact before the pending downward-hit fault reaches the floor
- **THEN** the pending fault is canceled, the contact is handled under normal turn rules, and play continues without a downward fault

#### Scenario: Confirmation window expires
- **WHEN** two seconds pass after a downward-directed hit without scoring-ground contact
- **THEN** the pending fault is cleared and play continues normally

#### Scenario: Expired downward hit later reaches the floor
- **WHEN** the balloon reaches the scoring ground after its downward-fault window has expired
- **THEN** the game applies ordinary ground-contact scoring and does not restore the expired downward fault

### Requirement: Dash contacts have a brief turn-resolution grace window
The game SHALL provide a short, configurable grace window after a valid dash contact so an opponent's timely balloon contact is not treated as an out-of-turn fault.

#### Scenario: Opponent touches during dash grace
- **WHEN** the opponent makes a valid balloon contact during the grace window after a dash contact
- **THEN** the contact is accepted without an out-of-turn fault and subsequent turn eligibility reflects that contact

#### Scenario: Grace window expires without an opponent contact
- **WHEN** the configured grace window ends without a valid opponent contact
- **THEN** the normal alternating-turn rule applies to later contacts

### Requirement: Round entities reset before opening contact is enabled
At match start and round restart, the game SHALL place both players at their configured spawn positions before enabling opening balloon contact, and SHALL keep the balloon spawn clear of the non-serving player.

#### Scenario: Start or restart a round
- **WHEN** a match starts or a subsequent round is initialized
- **THEN** both players are at their configured positions before the balloon can register a contact, and the balloon does not overlap the non-serving player

#### Scenario: Player previously occupied the balloon spawn
- **WHEN** a player was left near the balloon spawn by the prior round
- **THEN** that stale position does not cause an automatic opening contact after the round reset
