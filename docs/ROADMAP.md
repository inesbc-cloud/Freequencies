# Roadmap

Four steps, in order (see [ADR 0001](adr/0001-architecture.md)). Every feature ships on both
Basecamp (desktop) and Android before it counts as done.

Legend: ✅ done · 🔨 in progress · ⬜ not started · 🧪 built, awaiting review/device test

## 1. Scala as the spine (in [vpavlin/scala](https://github.com/vpavlin/scala), merged to `main`)

Already in Scala before this project: month/week/day views, text search, duplicate, drag to
move, custom fields with badges, RSVP, owner/editor/viewer and Closed/Open/Collaborative.

| Feature | Mobile | Desktop | Notes |
|---|---|---|---|
| Clash warnings (overlapping events in a calendar) | 🧪 | 🧪 | `d93cc4e`; tests in `mobile/test/clashes.test.mjs` |
| Filter by field value and date range | 🧪 | 🧪 | `33d17fd`; enum/yes-no fields, presets; tests in `mobile/test/filters.test.mjs`. Core `searchEvents` unchanged (title/description/location only) |
| Comments per event (Scala ADR 0024, on ADR 0021 `ext` events) | 🧪 | 🧪 | both folds + parity fixtures; core `postExt`/`deleteExt`; Freequencies reads the same items |
| Poster thumbnails from image attachments | ⬜ | ⬜ | phones can fetch but not upload attachments yet |
| Desktop reminders follow each event's reminder setting | n/a | 🧪 | `66a5011`; the in-app banner used to fire 15 min before every event |
| Hardening: core reads other members' data with `json::value()` (throws on a wrong type) | ✅ | ✅ | typed reads in both folds + malformed parity fixtures; every read in `scala_impl.cpp` converted (`scala` 0.12.2); malformed catch-up frames dropped (0.12.3) |
| Public "community" tier | ⬜ | ⬜ | needs a key-publishing design first |

**Released (2026-10-10):** desktop `scala` 0.12.2 + `scala_ui` 0.12.1 (Linux x86_64, Linux ARM64, macOS)
on apps.vpavlin.xyz and freequencies.vpavlin.xyz; Android 0.9.118 (vc139) on both F-Droid repos.
`scala` 0.12.3 (catch-up frame guard) is in testing.

## 2. Link the modules we have

| Feature | Status | Notes |
|---|---|---|
| Kith: artists from a Kith book; line-up, set times and fees per night (ADR 0004) | ✅ | fees live on the night, not on the contact; Android uses [kith-sdk](https://github.com/vpavlin/kith-sdk) |
| KYM: a budget per night, linked to the event id | ⬜ | design proposed in ADR 0006; needs budget-scoped calls in KYM |
| WhisperBox forms: artist booking requests, crew sign-up, guest lists, feedback (ADR 0005) | ✅ | desktop `freequencies_ui` 0.3.0 (needs `whisperbox_core` 0.4.2); Android 0.3.0 on whisperbox-sdk. Phone test of forms pending |

**Released (2026-10-10):** desktop `freequencies_ui` 0.3.0 (needs `scala` 0.12.2 + `kith` 0.3.2 + `whisperbox_core` 0.4.2)
and Android 0.3.0 (vc3) on [freequencies.vpavlin.xyz](https://freequencies.vpavlin.xyz). `freequencies_ui` 0.3.1 is in testing.

## 3. New modules

| Module | Status |
|---|---|
| Crew: roster, assignments, "I'm here" check-in | 🧪 roles, call times, open slots and check-in per night ([ADR 0007](adr/0007-crew-on-the-night.md)); desktop `freequencies_ui` 0.4.0 + Android 0.4.0 in testing |
| Gear: inventory, per-event checklist | ⬜ |
| Tasks: lists, deadlines (as Scala events), reminders | ⬜ |
| Availability polling | ⬜ |

## 4. Freequencies itself

| Feature | Status | Notes |
|---|---|---|
| Desktop app `freequencies_ui` (ADR 0002): nights board, night panel, new night, "Use for Freequencies" | ✅ | public, Linux x86_64/ARM64 and macOS |
| Nights board = the Lanes view (columns by venue / status / calendar) | ✅ | in `freequencies_ui`; logic from `prototypes/lanes` |
| Android app (ADR 0003): list board, night sheet, new night, calendars (create / join / Use for Freequencies) | ✅ | public F-Droid repo; arm64; needs the Loam app |
| Event page linking artists, crew, budget, tasks, gear | ⬜ | |
| "Same artist booked twice" warnings | ✅ | same Kith contact (or name) on overlapping or same-day nights; `mobile/src/app/lineup.ts` |
| Analytics (events per month, attendance, revenue) | ⬜ | |
| Integrations: tickets, weather, venue maps | ⬜ | |
| Public copy of a night for attendees, kept in step automatically ([ADR 0008](adr/0008-public-copy-of-a-night.md)) | 🧪 | desktop `freequencies_ui` 0.5.0 (needs `scala` 0.12.4) + Android 0.5.0 in testing |

## 5. Track A on the desktop: Freequencies rebuilt on Scala's app ([ADR 0009](adr/0009-desktop-on-scala-and-track-a-data.md))

`freequencies_ui` 0.7.0 is a fork of Scala's own view, built one issue at a time
([docs/issues](issues/README.md)). 🧪 = built and checked in the offscreen preview and by Node tests,
not yet on real Basecamp (issue #29); none counts as done until Android reads it too (issue #28).

| Plan item | Issue | Desktop |
|---|---|---|
| Freequencies look (Bebas Neue + FT88 Serif, acid green, ruled grid) | #3 #4 | 🧪 |
| Month / week / day (Scala's), board, timeline | #6 #9 #23 | 🧪 |
| Drag & drop (grid, week, board lanes) | #7 #9 | 🧪 |
| Colour by status / type / venue / calendar; status badges | #6 #8 | 🧪 |
| Night panel: status, venue, type, notes, repeats, duplicate | #8 #22 | 🧪 |
| Line-up from Kith; crew and check-in | #10 #11 | 🧪 (data as Android 0.5) |
| Tags; tickets; poster; files members-only / community | #12–#15 | 🧪 |
| Tasks with deadlines; gear; budget; social planner | #16–#19 | 🧪 |
| WhisperBox forms; public copy (golden-tested against Android) | #20 #21 | 🧪 |
| Search and filters; clash warnings | #24 #25 | 🧪 |
| Venues; analytics | #26 #27 | 🧪 |
| Quick new night (name, date, venue, times, line-up; optional kind, audience, tickets, age, access, link) and a Details section; ext kind `details` | — | 🧪 |
| Sections: Home (what needs you) · Calendar · Production · Funding · Venues · Analytics ([ADR 0010](adr/0010-promoters-workspace.md)) | — | 🧪 |
| Production: plan per night by format (8 promoter formats, T-minus timeline, team, venue & ops, hospitality, suppliers, run of show, risks, debrief, custom modules; the night's line-up/crew/budget/tickets/posts/gear as modules), after Louisa Prog's INTERSECT production office; ext kinds `prod-plan` / `prod-row` | — | 🧪 |
| Funding library: winning applications with documents, links to funders and open calls; its own "Funding library" calendar (marker field `fq_funding`, one anchor event), ext kinds `fund-app` / `fund-link` | — | 🧪 |
| Android readers for the new kinds | #28 | ⬜ |
| Test pass on real Basecamp | #29 | ⬜ |
| Not planned yet: weather, availability polling, push notifications, ticketing API | — | ⬜ |

