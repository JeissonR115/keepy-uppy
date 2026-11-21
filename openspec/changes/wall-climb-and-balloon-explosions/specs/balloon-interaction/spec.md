# Spec Delta

## ADDED Requirements

### Requirement: Shared balloon impact animation
The balloon SHALL use the same one-shot explosion effect for scoring-floor and spike impacts, while the balloon itself disappears as soon as either impact is registered.

#### Scenario: Balloon impacts the scoring floor
- **WHEN** the balloon makes a valid scoring-floor contact
- **THEN** the balloon visual disappears immediately, the shared explosion plays, and one ground-contact event is reported

#### Scenario: Balloon impacts spikes
- **WHEN** an armed balloon contacts spikes
- **THEN** the balloon visual disappears immediately, the same explosion plays, and one spike-contact event is reported

#### Scenario: An impact is reported more than once
- **WHEN** further floor or spike contacts occur after the round's impact has been registered
- **THEN** the explosion and corresponding contact event are not triggered again

#### Scenario: A new round begins
- **WHEN** the balloon is reset for a new round
- **THEN** the balloon visual and its collision behavior are restored and the prior explosion is no longer visible
