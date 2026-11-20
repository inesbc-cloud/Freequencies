# #8 The night panel

- **Milestone:** B · Nights on Scala's calendar
- **Size:** M
- **Depends on:** [#5](05-freequencies-calendars.md), [#6](06-night-cards-and-colour.md)
- **Plan item (Track A):** Notes per event; status badges; one place per night

## Why

Selecting a night should open everything about it in the right pane, instead of Scala's generic editor.

## Scope

- Pane 3 shows `fq/NightPanel.qml` when a night is selected (Scala's day agenda otherwise).
- Poster block (acid green, date, title, time, venue, badges); quick status / venue (saved venues as chips) / type / repeats.
- Notes = the event's description, editable in place.
- “Edit details” opens Scala's editor (title, time, reminder, attachments, all fields).
- The panel is a column of section files (`fq/sections/*.qml`); later issues each add one.

## Data

Event `fields`, `description`, `recur` (Scala).

## Reused from Scala

Scala's editor popup, `updateEvent`, recurrence.

## Done when

- [ ] Status/venue/type change from the panel on the freshest copy (no lost edits).
- [ ] Read-only nights say so.

_Prototype reference: 0.6 night panel (`prototypes/desktop-0.6/`)._
