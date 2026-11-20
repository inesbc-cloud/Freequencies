# #7 Drag & drop a night to another day

- **Milestone:** B · Nights on Scala's calendar
- **Size:** S
- **Depends on:** [#6](06-night-cards-and-colour.md)
- **Plan item (Track A):** Drag & drop calendar

## Why

Scala already moves an event when it's dragged from the day agenda onto a month cell (`moveEventToDay`). Extend that to the cards themselves.

## Scope

- Cards in month and week views start Scala's `dragProxy`; week columns get a `DropArea`.
- Keep Scala's move semantics (time of day kept; a repeating event moves as a series).

## Data

Normal Scala event edit.

## Reused from Scala

`dragProxy`, `moveEventToDay`, month `DropArea`.

## Done when

- [ ] Dragging a card to another day moves it and shows a toast.
- [ ] Read-only calendars refuse the drop with a message.
