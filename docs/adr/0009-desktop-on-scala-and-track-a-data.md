# 0009. The desktop app is a fork of Scala's view; Track A data rides on ext items

- Status: proposed
- Date: 2026-11-20

## Context

The Freequencies plan (Track A) lists what collectives asked for: drag & drop, month / week /
timeline views, colour coding, status badges, ticket links, recurring nights, permissions, notes,
files (private or for the community), public/private, search and filters, conflict warnings, tags,
comments, poster previews; and as nice-to-haves venues, crew, gear, budget, tasks with deadlines, a
social planner, analytics and one-click duplicate.

A desktop prototype (0.6, `prototypes/desktop-0.6/`) tried them all in one 3,000-line view next to
Scala, re-implementing a calendar Scala already has: month/week/day grids, the event editor,
attachments in Logos Storage, comments, RSVPs, roles, invites, identities and keycard.

## Decision

1. **The desktop module is a fork of Scala's own view** (`scala-ui/qml/CalendarView.qml` →
   `freequencies-ui/qml/FreequenciesView.qml`, fork point in `freequencies-ui/UPSTREAM.md`). Scala's
   code stays as it is where it can; Freequencies adds hooks marked `Freequencies (#n)` and its own
   files in `qml/fq/`: components, `sections/` of the night panel, `views/`, `popups/`, and
   `lib/*.js` logic with no Qt calls, unit-tested in Node. No app intents (Scala keeps them).
2. **The work is cut into issues** (`docs/issues/`), one commit each, every issue depending only on
   earlier ones.
3. **No new core module.** Nights are Scala events: `fields` (status / venue / type, ADR 0001),
   `description` (notes), `recur` (repeats), `attachments` (files, Logos Storage, sealed with the
   calendar key). Everything else is an `ext` item, ns `xyz.freequencies`:

   | kind | `data` | how many |
   |---|---|---|
   | `artist` (ADR 0004), `crew`, `checkin` (ADR 0007), `form` (ADR 0005), `public` (ADR 0008) | unchanged | as before |
   | `tags` | `{tags: [string]}` | one value per night: the newest wins |
   | `tickets` | `{url?, sold?, capacity?, price?, currency?}` | one value per night: the newest wins |
   | `poster` | `{url}` or `{cid, name}` (an attachment) | one value per night: the newest wins |
   | `file` | `{cid, visibility: "private" \| "public"}` | per attachment: the newest wins |
   | `task` | `{text, due?, cat, done}` | a list, edited by id |
   | `gear` | `{item, done}` | a list, edited by id |
   | `budget` | `{label, amount, currency, dir: "in" \| "out"}` | a list, edited by id |
   | `post` | `{text, when?, channel, done}` | a list, edited by id |

   "Newest wins" = highest `hlc` (wall, ctr), whoever wrote it. A write posts a fresh id
   (`<kind>:<nightId>:<random>`) and deletes the writer's own older items of that kind, so nobody
   edits someone else's item and a deleted id is never reused (Scala keeps deleted ids deleted).
4. **Derived, never stored:** venues, analytics, venue clashes, the people double-booked, the
   budget's artist fees and ticket sales.
5. **The public copy is unchanged** and must stay identical to Android's: `fq/lib/publiccopy.js` is
   checked against `mobile/src/app/publish.ts` by a golden test. "Community" files are a flag until
   Scala can publish files; their bytes stay sealed for members.

## Consequences

- Scala fixes can be pulled into the fork (`UPSTREAM.md`); Freequencies' own code is easy to find.
- Android needs readers for the new kinds before they count as done (issue #28).
- Budget lines are ext items until ADR 0006 (KYM) is decided; their shape is simple to move there.
- List items can only be changed by their author or an editor (Scala's ext rule); the UI says so.
- The design system is stubbed in the preview; real Basecamp metrics are checked in issue #29.
