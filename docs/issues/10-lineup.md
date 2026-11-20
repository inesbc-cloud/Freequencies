# #10 Line-up from Kith

- **Milestone:** C · Tools on each night
- **Size:** M
- **Depends on:** [#8](08-night-panel.md)
- **Plan item (Track A):** Artist database (Kith)

## Why

Port ADR 0004: artists picked from Kith address books, with status, set time and fee.

## Scope

- `fq/lib/lineup.js` (`lineupOf`, `feesTotal`, `artistKey`).
- `fq/sections/LineupSection.qml`, `fq/popups/ArtistPopup.qml` (Kith search, free name, status, set, fee).
- Module depends on `kith`.

## Data

ext `xyz.freequencies` / `artist` — unchanged from 0.5.

## Reused from Scala

Scala `postExt` / `deleteExt`.

## Done when

- [ ] Same data as Android 0.5: a booking made on one shows on the other.
- [ ] Unit tests.

_Prototype reference: 0.5 (`prototypes/desktop-0.6/`)._
