# #21 Public / private: the public copy of a night

- **Milestone:** C · Tools on each night
- **Size:** M
- **Depends on:** [#8](08-night-panel.md), [#10](10-lineup.md), [#20](20-forms.md)
- **Plan item (Track A):** Public/private toggle

## Why

Port ADR 0008 unchanged: `publicCopyOf` must be byte-identical to Android's or the two would rewrite each other.

## Scope

- `fq/lib/publiccopy.js` (`publicLinkOf`, `publicCopyOf`, `sameCopy`, `mirrorPlan`) + mirror loop in `fq/Store.qml`.
- `fq/sections/PublicSection.qml`, `fq/popups/PublicPopup.qml`.

## Data

ext `public`; copy event `pub-<id>` via `putEvent` — unchanged.

## Done when

- [ ] Golden test: same copy as `mobile/src/app/publish.ts` for the shared fixtures.

_Prototype reference: 0.5 (`prototypes/desktop-0.6/`)._
