# #5 Freequencies calendars: schema and “Use for Freequencies”

- **Milestone:** B · Nights on Scala's calendar
- **Size:** S
- **Depends on:** [#1](01-fork-scala-app.md)
- **Plan item (Track A):** Status badges (Draft/Confirmed/Cancelled), venue, type

## Why

A calendar becomes a Freequencies calendar by carrying the Status / Venue / Type fields (ADR 0001). Scala's editor already edits schema fields.

## Scope

- `fq/lib/nights.js`: `statuses`, `types`, `freqFields`, `isFreqCal`, `adoptBlocker`, `fieldOf`.
- Sidebar: Freequencies calendars first; other Scala calendars below with “use for Freequencies →” (or why not).
- Status stays `Hold` in data (Android contract); the UI may label it “Hold / draft”.

## Data

Calendar `schema` gains `status` (enum Hold/Confirmed/Cancelled), `venue` (text), `type` (enum). Unchanged from 0.5.

## Reused from Scala

Scala's `updateCalendarMeta`, settings popup, schema editor.

## Done when

- [ ] Adopting keeps the calendar's own fields.
- [ ] A calendar with a foreign `status` field is left alone, with the reason shown.
- [ ] Unit tests for `isFreqCal` / `adoptBlocker`.

_Prototype reference: 0.5 `adoptCalendar` (`prototypes/desktop-0.6/`)._
