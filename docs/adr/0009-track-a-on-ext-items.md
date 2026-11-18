# 0009. Track A features ride on ext items; the desktop view takes the Freequencies look

- Status: proposed
- Date: 2026-11-18

## Context

The Freequencies plan (Track A, "What Logos engineers are building") lists what collectives asked
for: drag & drop calendar, month / week / timeline views, colour coding, status badges, ticket links
and numbers, recurring nights, permissions, notes, files (some private, some for the community),
public/private, search and filters, conflict warnings, tags, comments, poster previews, and as
nice-to-haves venues, crew, gear, budget, tasks with deadlines, a social planner, analytics and
one-click duplicate. The desktop view also had to look like Freequencies (site + posters), not Scala.

## Decision

1. **No new core module.** Everything stays in Scala's mechanisms (ADR 0002):
   - the night itself: title, times, `description` (= Notes), `recur` (= Repeats), `attachments`
     (= Files, Logos Storage, sealed with the calendar key, Scala ADR 0017);
   - Freequencies data: `ext` items, ns `xyz.freequencies`, new kinds:

   | kind | shape of `data` | cardinality |
   |---|---|---|
   | `tags` | `{tags: [string]}` | one value per night: newest item wins |
   | `tickets` | `{url?, sold?, capacity?, price?, currency?}` | one value per night: newest wins |
   | `poster` | `{url}` or `{cid, name}` (an attachment's storage CID) | one value per night: newest wins |
   | `file` | `{cid, visibility: "private" \| "public"}` | per attachment CID: newest wins |
   | `task` | `{text, due?, cat, done}` | list, edited by id |
   | `gear` | `{item, done}` | list, edited by id |
   | `budget` | `{label, amount, currency, dir: "in" \| "out"}` | list, edited by id |
   | `post` | `{text, when?, channel, done}` | list, edited by id |

   "Newest wins" = highest `hlc` (wall, ctr), whoever wrote it. A write posts a fresh id
   (`<kind>:<nightId>:<random>`) and deletes the writer's own older items of that kind, so nobody
   needs to edit someone else's item and deleted ids are never reused (Scala keeps them deleted).
2. **Derived, not stored:** venues (every venue a night used), analytics, venue clashes (same venue,
   overlapping, not cancelled, across all Freequencies calendars), the budget's artist fees (line-up)
   and ticket revenue (sold × price).
3. **Drag & drop** edits the night on a fresh copy (`getEvent` → `updateEvent`, as `setField`). On the
   board a drop on another lane also sets the venue or status. A repeating night moves as a series.
4. **Duplicate** creates the night one week later as a Hold and copies line-up (asked again), crew
   roles (as open slots), gear (unpacked) and tags. Not tasks, budget, tickets or comments.
5. **The public copy (ADR 0008) is unchanged.** `publicCopyOf` must stay identical on desktop and
   Android or the two would keep rewriting each other's copy. "Community" files are a flag only until
   Scala has a public tier; the bytes stay sealed for members.
6. **Look:** Freequencies tokens (#050805 ground, #6ef600 lime, #7bf686 acid, #4aa8ff signal),
   square ruled grid, `>_` section heads, `(( ))` brackets, acid-green poster block for the night.
   Fonts: Bebas Neue (display, bundled, OFL) and FT88 Serif (body, Velvetyne, OFL, drop into
   `qml/fonts/FT88-Serif.otf`; system monospace until then). Labels are at least 12 px.

## Consequences

- Android needs the same readers (`tags`, `tickets`, `poster`, `file`, `task`, `gear`, `budget`, `post`)
  before these count as done under the Basecamp + Android parity rule.
- KYM (ADR 0006) can later take over budgets; the `budget` items are simple enough to migrate.
- List items can only be changed by their author (Scala ext rule); others see a clear message.
- Ticket numbers are typed in; a ticketing integration can later write the same `tickets` item.
