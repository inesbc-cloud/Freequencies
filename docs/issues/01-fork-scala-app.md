# #1 Fork Scala's calendar app as the Freequencies module

- **Milestone:** A · Fork and foundation
- **Size:** S
- **Depends on:** —
- **Plan item (Track A):** Foundation for every Track A item

## Why

Freequencies 0.5/0.6 re-implemented a calendar next to Scala's. Starting from Scala's own view gives the month/week/day grid, editor, attachments, comments, RSVPs, roles, invites, identities and keycard for free, and keeps Freequencies close to Scala so fixes flow both ways.

## Scope

- Copy `scala-ui/qml` from Scala at a pinned commit into `freequencies-ui/qml` (`CalendarView.qml` → `FreequenciesView.qml`, `Field.qml`).
- Module stays `freequencies_ui`; version 0.7.0; depends on `scala` and `loam_core` (as Scala's view does).
- Drop Scala's app-intent `provides` from metadata and stop answering `scala.*` intents, so Scala and Freequencies can be installed side by side.
- Record the fork point (Scala commit) in `freequencies-ui/UPSTREAM.md`, with how to pull later Scala fixes.
- Keep the 0.6 prototype under `prototypes/desktop-0.6/` for reference.

## Data

None. Same Scala calendars and events.

## Reused from Scala

All of Scala's view.

## Done when

- [ ] Installing the module shows Scala's calendar under the name Freequencies, working exactly as Scala does.
- [ ] Scala's own app keeps answering intents; Freequencies answers none.
- [ ] `UPSTREAM.md` names the Scala commit the fork started from.
