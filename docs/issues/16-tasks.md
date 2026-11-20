# #16 Tasks with deadlines

- **Milestone:** C · Tools on each night
- **Size:** S
- **Depends on:** [#8](08-night-panel.md)
- **Plan item (Track A):** Task list with deadlines (social posts, payments, contracts)

## Scope

- `tasksOf`, `overdue`, `dueSoon`; `fq/sections/ChecklistSection.qml` (shared with #17, #19); `fq/popups/ItemPopup.qml`.
- Overdue count in the header.

## Data

ext `task` `{text, due?, cat, done}`.

## Done when

- [ ] Amber 3 days before, red when overdue.
- [ ] Unit tests.
