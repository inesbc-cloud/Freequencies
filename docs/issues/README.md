# Freequencies on Scala's app: issues

The 0.6 prototype (`prototypes/desktop-0.6/`) broken into small issues and rebuilt on top of Scala's own calendar app.
Each issue is one commit on the `rebuild-on-scala` branch, in this order. Data stays compatible with Scala and with the Android app (ADRs 0001–0009).

Sizes: S = under a day, M = one to two days, L = more.

## A · Fork and foundation

| # | Issue | Size | Depends on |
|---|---|---|---|
| 1 | [Fork Scala's calendar app as the Freequencies module](01-fork-scala-app.md) | S | — |
| 2 | [Preview harness and unit tests](02-preview-harness-and-tests.md) | S | #1 |
| 3 | [Freequencies look: tokens, square grid, header](03-freequencies-look.md) | M | #1 |
| 4 | [Fonts: Bebas Neue + FT88 Serif](04-fonts.md) | S | #3 |

## B · Nights on Scala's calendar

| # | Issue | Size | Depends on |
|---|---|---|---|
| 5 | [Freequencies calendars: schema and “Use for Freequencies”](05-freequencies-calendars.md) | S | #1 |
| 6 | [Night cards on the grid, colour by status / type / venue / calendar](06-night-cards-and-colour.md) | M | #3, #5 |
| 7 | [Drag & drop a night to another day](07-drag-and-drop.md) | S | #6 |
| 8 | [The night panel](08-night-panel.md) | M | #5, #6 |
| 9 | [Board view: lanes by venue, status or calendar](09-board-view.md) | M | #6, #7 |

## C · Tools on each night

| # | Issue | Size | Depends on |
|---|---|---|---|
| 10 | [Line-up from Kith](10-lineup.md) | M | #8 |
| 11 | [Crew, call times and check-in](11-crew.md) | M | #8 |
| 12 | [Tags on nights](12-tags.md) | S | #8 |
| 13 | [Ticket link and numbers](13-tickets.md) | S | #8 |
| 14 | [Files: members only / community](14-files.md) | S | #8 |
| 15 | [Poster preview](15-poster.md) | S | #8, #14 |
| 16 | [Tasks with deadlines](16-tasks.md) | S | #8 |
| 17 | [Equipment checklist](17-gear.md) | S | #16 |
| 18 | [Budget per night](18-budget.md) | S | #10, #13 |
| 19 | [Social media planner](19-social-planner.md) | S | #16 |
| 20 | [WhisperBox forms on a night](20-forms.md) | M | #8 |
| 21 | [Public / private: the public copy of a night](21-public-copy.md) | M | #8, #10, #20 |
| 22 | [Duplicate a night; repeats](22-duplicate-and-repeat.md) | S | #10, #11, #17 |

## D · Views, search and overviews

| # | Issue | Size | Depends on |
|---|---|---|---|
| 23 | [Timeline view (coming up / past)](23-timeline-view.md) | S | #6, #12, #13, #15 |
| 24 | [Search and filters for nights](24-search-and-filters.md) | S | #6, #10, #12 |
| 25 | [Clash warnings: venue double-booked, artist or crew in two places](25-clash-warnings.md) | S | #6, #10, #11 |
| 26 | [Venues view](26-venues-view.md) | S | #5 |
| 27 | [Analytics view](27-analytics-view.md) | S | #13, #18 |

## E · Parity and release

| # | Issue | Size | Depends on |
|---|---|---|---|
| 28 | [Android: read and write the new night data](28-android-parity.md) | L | #12, #13, #14, #15, #16, #17 … |
| 29 | [Test pass on real Basecamp](29-basecamp-test-pass.md) | S | #1, #2, #3, #4, #5, #6 … |

## Creating them on GitHub

```sh
for f in docs/issues/[0-9]*.md; do
  gh issue create --repo vpavlin/freequencies --title "$(head -1 "$f" | sed 's/^# #[0-9]* //')" --body-file "$f" --label track-a
done
```
