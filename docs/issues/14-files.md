# #14 Files: members only / community

- **Milestone:** C · Tools on each night
- **Size:** S
- **Depends on:** [#8](08-night-panel.md)
- **Plan item (Track A):** File attachments; private vs public files

## Why

Scala already stores attachments in Logos Storage, sealed with the calendar key. Add the night-panel view and a community flag.

## Scope

- `fq/sections/FilesSection.qml` listing the event's `attachments` with open / use as poster / remove; upload through Scala's uploader.
- Members only / Community flag per file.

## Data

Scala `attachments`; ext `file` `{cid, visibility}`.

## Reused from Scala

Scala's upload + poll code.

## Done when

- [ ] The flag never makes bytes public (that needs Scala's public tier); the UI says so.
