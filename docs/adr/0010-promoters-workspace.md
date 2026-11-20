# 0010. Freequencies is a promoters' workspace; the calendar is one section of it

- Status: proposed
- Date: 2026-11-20

## Context

0009 rebuilt the desktop app on Scala's calendar view. It works, but it still reads as Scala with
extras: the calendar is the whole app, and everything else hangs off a night's side panel.
Promoters co-organising nights need more than a calendar: a plan for each event, comms, money,
funding, and ways to work across collectives. Louisa Prog's demo of 0.6 and her INTERSECT production
office (format → modules → a plan counted back from show day, custom modules) point the way.

## Decision

1. **The app has sections, one row of tabs:** Home · Calendar · Production · Funding · Venues ·
   Analytics (Promo next). Home is the landing page: what needs you and what's coming up. The
   calendar, with its own modes (month, week, day, board, timeline), is one section.
2. **Production** gives each night a working plan, picked by format (club night, concert,
   festival / all-dayer, residency / series, community / salon, workshop / talk, fundraiser, tour).
   A format switches on modules and seeds a timeline counted back from show day (T-42, T-28…),
   venue checks, a run of show, risks and a debrief. The night's existing data (line-up, crew,
   budget, tickets, social posts, gear, files) appear as modules, not copies. Custom modules from a
   short column spec. Structure after INTERSECT; the promoter formats and templates are our own.
3. **Shared by default, no new core module.** The plan is one ext item (`prod-plan`, newest wins);
   each table row is versioned ext items (`prod-row`): an edit posts a new version, the newest per
   row wins whoever wrote it, deleting is a version with `del: true`. So every co-organiser edits
   every row, which Scala's own rule (only an item's author edits it) would not allow.
4. **Funding** is a shared library in its own calendar (marker field `fq_funding`, one anchor
   event): winning applications with documents (attachments on the anchor) and links to funders
   and open calls (ext kinds `fund-app`, `fund-link`).
5. **The quick new-night form** asks for name, date, venue, times and line-up; kind of event,
   expected audience, tickets, age, accessibility and a link are optional (ext kind `details`).

## Consequences

- Phase 2: a Promo studio (posts and story images built from a night's data). Phase 3: collaboration
  across collectives (shared holds calendar, co-promotion splits and settlement, venue directory,
  gear library, crew pool, polls, lessons learnt).
- Android needs readers for `details`, `prod-plan`, `prod-row`, `fund-app`, `fund-link` (#28).
- A row's history grows with every edit; each writer retires their own older versions, others'
  stay until an editor cleans up. Fine at a night's scale.
