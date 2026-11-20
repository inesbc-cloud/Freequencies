# #6 Night cards on the grid, colour by status / type / venue / calendar

- **Milestone:** B · Nights on Scala's calendar
- **Size:** M
- **Depends on:** [#3](03-freequencies-look.md), [#5](05-freequencies-calendars.md)
- **Plan item (Track A):** Colour-coded events; status badges; month view

## Why

Scala's month cells show dots; nights need titles, times and status at a glance. Scala's code invites this: “a Freequencies-style app maps a custom-field value to colour itself”.

## Scope

- `fq/NightCard.qml`: compact card (time + title, colour bar, ⚠ on clash, strikeout when cancelled).
- Month cells list cards (as many as fit, then “+N more” → week view); week columns use full cards.
- Colour-by switch (status / type / venue / calendar) + legend; `evColor` follows it.

## Data

None (view preference only).

## Reused from Scala

Scala's month grid, week columns, `evColor`, `clashMark`.

## Done when

- [ ] Switching colour-by recolours every card and the legend.
- [ ] Cancelled nights are struck through.
