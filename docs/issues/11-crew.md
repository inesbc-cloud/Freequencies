# #11 Crew, call times and check-in

- **Milestone:** C · Tools on each night
- **Size:** M
- **Depends on:** [#8](08-night-panel.md)
- **Plan item (Track A):** Crew/staff

## Why

Port ADR 0007.

## Scope

- `fq/lib/crew.js`.
- `fq/sections/CrewSection.qml`, `fq/popups/CrewPopup.qml`; “I'm here” check-in.

## Data

ext `crew`, `checkin` — unchanged.

## Reused from Scala

Kith loader shared with #10.

## Done when

- [ ] Unit tests; same data as Android.

_Prototype reference: 0.5 (`prototypes/desktop-0.6/`)._
