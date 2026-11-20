# #12 Tags on nights

- **Milestone:** C · Tools on each night
- **Size:** S
- **Depends on:** [#8](08-night-panel.md)
- **Plan item (Track A):** Tags (techno, ambient, live, workshop…)

## Why

Free tags with suggestions; used by filters, timeline, analytics.

## Scope

- `fq/lib/tools.js` `tagsOf`; `fq/sections/TagsSection.qml`.

## Data

ext `tags` `{tags:[…]}`; newest item wins (ADR 0009).

## Done when

- [ ] Unit tests for newest-wins.
