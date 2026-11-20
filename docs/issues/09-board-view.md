# #9 Board view: lanes by venue, status or calendar

- **Milestone:** B · Nights on Scala's calendar
- **Size:** M
- **Depends on:** [#6](06-night-cards-and-colour.md), [#7](07-drag-and-drop.md)
- **Plan item (Track A):** Board view (Freequencies' own)

## Why

Two weeks of nights with one column per venue (or status, or calendar): spot a free room or a double booking.

## Scope

- `fq/lib/lanes.js` (`buildLanes`, from `prototypes/lanes`).
- `fq/views/BoardView.qml` as a fourth mode beside Scala's month/week/day.
- Drop on a cell moves the day and sets venue/status for that lane.

## Data

None new.

## Reused from Scala

Scala's mode switch, `dragProxy`.

## Done when

- [ ] Unit tests for `buildLanes`.
- [ ] Dropping in another venue's column sets that venue.

_Prototype reference: 0.5 board (`prototypes/desktop-0.6/`)._
