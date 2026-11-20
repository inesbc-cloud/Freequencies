# #25 Clash warnings: venue double-booked, artist or crew in two places

- **Milestone:** D · Views, search and overviews
- **Size:** S
- **Depends on:** [#6](06-night-cards-and-colour.md), [#10](10-lineup.md), [#11](11-crew.md)
- **Plan item (Track A):** Conflict warnings

## Why

Scala warns about overlapping events in one calendar. Nights need: same venue overlapping across Freequencies calendars, and the same artist/crew on two nights.

## Scope

- `fq/lib/clashes.js`: `venueClashes`, `peopleDoubles` (0.5's `doubles`).
- ⚠ on cards; lines in the night panel.

## Data

None (derived).

## Reused from Scala

Scala's `clashMap` stays for same-calendar overlaps.

## Done when

- [ ] Unit tests for both.
- [ ] Cancelled nights never clash.
