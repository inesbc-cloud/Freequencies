# #15 Poster preview

- **Milestone:** C · Tools on each night
- **Size:** S
- **Depends on:** [#8](08-night-panel.md), [#14](14-files.md)
- **Plan item (Track A):** Poster preview

## Why

Show the poster on the panel, cards and timeline.

## Scope

- `posterOf`; pick an image attachment (fetched from Logos Storage) or an image link.

## Data

ext `poster` `{url}` or `{cid,name}`; newest wins.

## Reused from Scala

Scala's `downloadAttachment` / `attachmentStatus`.

## Done when

- [ ] Poster from an attachment renders after fetching.
