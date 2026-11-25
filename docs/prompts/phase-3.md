# Freequencies · Phase 3 — prompt

You're continuing **Freequencies**, the coordination tool for Lisbon's independent culture scene:
collectives, promoters and venues co-organising events. It's a Logos Basecamp app (QML view
`freequencies_ui` over Scala's calendar core, plus our small `freequencies_core` module). Phases 1–2
built Home, Production, Promo, Funding, public listings from Luma and an EN | PT switch (see
`docs/adr/0010-promoters-workspace.md`, `docs/ROADMAP.md`). Phase 3 makes it the place promoters
**work together**, keep their **papers in order**, and **understand their numbers**, and gives it
three **skins**. Build all of it, carefully, in English and European Portuguese.

## Read first

- `CLAUDE.md`, ADRs 0001, 0009, 0010, `docs/ROADMAP.md`.
- `freequencies-ui/qml/FreequenciesView.qml` (the app; Scala's view, forked), `fq/` (our components,
  `views/`, `sections/`, `popups/`, `lib/*.js` logic with no Qt, unit-tested in Node).
- `fq/Fq.qml`: design tokens, `Fq.t()` translation, `Fq.fmtDate()`; `fq/lib/i18n.js`: the PT table.
- `fq/lib/production.js` (plans, versioned shared rows), `fq/lib/funding.js` (a shared library as
  ext items on one anchor event in its own calendar), `fq/lib/listings.js`, `fq/lib/home.js`.

## How this codebase works (keep to it)

- **No new core module unless the view truly can't do it.** Shared data is Scala `ext` items (ns
  `xyz.freequencies`) on events, synced to everyone on that calendar. One value per thing: newest
  wins (`putLatest`). Rows anyone may edit: versioned items, newest version per row wins
  (`prod-row` pattern). Libraries shared across collectives: ext items on an anchor event in a
  dedicated calendar (the Funding pattern), or in the shared **Lisboa** community calendar.
- **Logic in `fq/lib/*.js`** (pure, `.pragma library`), with tests in `freequencies-ui/test/`
  (`node freequencies-ui/test/run.mjs`). QML only lays things out.
- **Every visible string through `Fq.t()`**, with its Portuguese added to `fq/lib/i18n.js`
  (European Portuguese, informal "tu", Lisbon scene words: pré-reserva, cartaz, espaço, cachê,
  alinhamento, balanço). Don't wrap values that are compared or stored; translate them where shown.
  Dates through `Fq.fmtDate/fmtDateTime/fmtTime`. Library text that's shown takes a translator
  argument (see `home.js`).
- **Views have no network** (Basecamp's `DenyAllNetworkAccessManager`). Anything fetched goes through
  `freequencies_core` (fixed, official addresses only).
- New files go in `qml/freequencies_ui.qrc`; new `fq/` components in `fq/qmldir`.

## Design principles for Phase 3

- **Neat before complete-looking.** Every screen answers one question. Hide what's rarely needed
  behind "more", collapse empty sections to one line, no counters nobody reads, no duplicate ways to
  do the same thing. If a feature adds clutter for little value, leave it out and say so.
- **Shared by default, private when it should be.** Money, contracts, inspection notes and crew
  contacts stay sealed to the collective; what helps the whole scene (venues, gear, lessons, the
  Lisboa calendar) is shared in Lisboa.
- **Works on a bad night.** Big touch targets for the door, readable on a phone-sized window,
  everything offline-first.
- **Consolidate navigation.** Proposed tabs (adjust if a better shape emerges, and explain):
  **Home · Calendar · Production · Promo · Network · Resources · Reports**, plus **+ Event**,
  **EN | PT** (top right) and the **skin switcher** (bottom right). Venues moves into Network;
  Funding into Resources; Analytics becomes Reports.

## What to build

### 1. Reports (replaces Analytics)
Today's Analytics counts "events across every calendar you can see", which nobody can read. Rebuild
it around clear audiences, always showing **what it's counting** ("Freequencies collective · 2026").
- **Event results** (in the event panel and Production's Debrief): money in/out, break-even,
  cost per person, artists paid, audience vs capacity, ticket sales over time, plan vs actual.
- **Collective year report** (pick a collective calendar and a period): events, audience, money,
  artists booked, venues used, and **funder numbers** (local artists, women and non-binary artists,
  first-time performers, free/accessible events, volunteers). Add the optional fields this needs to
  the line-up/crew data. **"Copy for an application"** produces a short PT/EN paragraph and table;
  link from the Funding library.
- **City pulse** (from Lisboa + public listings): busy and empty weekends, clash hotspots, which
  nights are under-served. Helps choose dates.

### 2. Deal calculator (Production → Budget, and a quick version on its own)
Model artist deals: flat fee, door split, guarantee + %, "versus" deals, plus costs (venue, sound,
promo, staff) and ticket price × capacity. Shows break-even and what each party takes at 25/50/75/
100% full; save scenarios on the event (ext kind `deal`) and turn the chosen one into budget lines.

### 3. Co-promotion and settlement
Partners on an event (collectives, venue) with agreed shares of costs and income. After the event, a
**settlement sheet**: who paid what, who owes whom, one-tap "settled". Copy/print-friendly.

### 4. Network (shared in Lisboa)
- **Venue directory**: capacity, tech specs, accessibility, contacts (members only), typical deal,
  past events from the calendar; replaces the Venues tab.
- **Gear library**: what each collective can lend, availability on a date, borrow requests and
  returns.
- **Crew pool**: people opt in with skills and availability; shifts on events; sign-ups via a
  WhisperBox form; links to the event's Crew section.
- **Quick polls**: on an event or in Lisboa ("which date?", "which poster?"), one vote each, closes
  at a time.

### 5. Resources
- **Funding library** (exists; tidy it into Resources).
- **Legal toolkit** — information, not advice; reviewed by a lawyer or legal clinic before release
  (leave a visible "draft, under legal review" badge until then). **Research current Portuguese law
  from official sources** (Diário da República / dre.pt, ePortugal, IGAC, ANEPC, Câmara Municipal de
  Lisboa, ASAE, SPA/GDA/Audiogest/PassMúsica, Autoridade Tributária, Segurança Social, Ordem dos
  Advogados) and **cite each item in-app with a "last checked" date.** Write it PT-first, natively.
  - **Which legal form fits you**: informal collective, cultural association (Associação na Hora,
    statutes, bodies, accounts, VAT exemption for cultural services, funding eligibility), company /
    self-employed. A five-question guide that recommends one and explains why.
  - **Papers for an event**: promoter registration and age rating (IGAC), special noise licence and
    temporary/improvised venue licence (Câmara), opening hours (Lisbon's rules for nightlife areas),
    music rights, alcohol/food (ASAE), fire safety and capacity (SCIE/ANEPC), insurance (civil
    liability, volunteers' accident cover), artist contracts (Estatuto dos Profissionais da Área da
    Cultura) and withholding tax for foreign artists. Each: what, who issues it, how long, rough
    cost, what happens without it. A **"Licences" module in Production**, pre-filled per format.
  - **Your rights during an inspection**: who can inspect what (PSP, ASAE, IGAC, municipal),
    identification, when a warrant is needed, duty to identify, arguido rights (silence, lawyer),
    recording, how to complain (IGAI, Provedora de Justiça), the constitutional grounds (expression,
    assembly, cultural fruition). A printable one-page **door sheet**.
  - **Help now** (a red button, one tap from anywhere during an event): 112; the event's on-call
    contact and lawyer; Kosmicare (harm reduction); APAV 116 006; Linha de Emergência Social 144;
    collective-configurable numbers.
  - **Inspections log** (members of the collective, sealed): after the fact — date, area, body,
    what they checked, outcome, what would have helped. **No names of officers or attendees, no
    live "police are coming" alerts.** Anonymised patterns ("noise licence checked in 8 of 10 visits")
    can be shared to Lisboa if a collective opts in.
- **Lessons learnt**: debriefs a collective chooses to share, searchable by topic.

### 6. Skins (switcher bottom right, remembered)
Theme tokens in `Fq.qml` (colours, fonts, borders, corner style, decorations), swapped live:
- **Classic** — today's Freequencies: terminal green on black, Bebas Neue, ruled grid.
- **8-bit universe** — pixel font (OFL, bundled), chunky 2-px borders, starfield background,
  limited palette (deep space blue, magenta, cyan, star white), pixel icons.
- **90s rave old skool** — acid-smiley yellow, chequerboard and gradient accents, flyer-style type
  (OFL fonts), warped headings, a hint of strobe on hover (respect reduced motion).
Every screen must stay readable (contrast WCAG AA) in all three. Promo images keep their own look.

### 7. Language
Everything new in EN and PT; check no English slips through in PT (and vice versa).

## How to deliver

1. Plan first: a short note of the final navigation, data kinds (ext `kind`s, anchors), and what you
   decided to leave out to avoid clutter. Then build area by area.
2. Tests for every new `fq/lib` file; keep `run.mjs` green.
3. Preview each screen with `freequencies-ui/qml-harness/preview/preview.py` (offscreen, mock bridge)
   in **both languages and all three skins**; extend `mock.py` as needed.
4. Build `nix build "git+file://<repo>?dir=freequencies-ui#lgx-portable"`, install with portable
   `lgpm` into Basecamp (`~/Library/Application Support/Logos/LogosBasecamp/{modules,plugins}`),
   bump the version (`0.13.0`), restart Basecamp only when asked.
5. One branch, a commit per area, a PR with a clear description; update `docs/ROADMAP.md` and add
   ADR 0011 for the Phase 3 data model and the legal toolkit's sources and review status.
