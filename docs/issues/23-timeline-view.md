# #23 Timeline view (coming up / past)

- **Milestone:** D · Views, search and overviews
- **Size:** S
- **Depends on:** [#6](06-night-cards-and-colour.md), [#12](12-tags.md), [#13](13-tickets.md), [#15](15-poster.md)
- **Plan item (Track A):** Timeline view

## Why

A readable list of what's coming: date, poster, line-up, tags, tickets, open tasks.

## Scope

- `fq/lib/timeline.js` groups occurrences by month.
- `fq/views/TimelineView.qml`, coming up / past toggle.

## Data

None.

## Reused from Scala

Scala's `expandEvents`.

## Done when

- [ ] Clicking a row opens the night panel.
