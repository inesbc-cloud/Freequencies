# #29 Test pass on real Basecamp

- **Milestone:** E · Parity and release
- **Size:** S
- **Depends on:** [#1](01-fork-scala-app.md), [#2](02-preview-harness-and-tests.md), [#3](03-freequencies-look.md), [#4](04-fonts.md), [#5](05-freequencies-calendars.md), [#6](06-night-cards-and-colour.md), [#7](07-drag-and-drop.md), [#8](08-night-panel.md), [#9](09-board-view.md), [#10](10-lineup.md), [#11](11-crew.md), [#12](12-tags.md), [#13](13-tickets.md), [#14](14-files.md), [#15](15-poster.md), [#16](16-tasks.md), [#17](17-gear.md), [#18](18-budget.md), [#19](19-social-planner.md), [#20](20-forms.md), [#21](21-public-copy.md), [#22](22-duplicate-and-repeat.md), [#23](23-timeline-view.md), [#24](24-search-and-filters.md), [#25](25-clash-warnings.md), [#26](26-venues-view.md), [#27](27-analytics-view.md)
- **Plan item (Track A):** Release

## Why

The preview stubs the design system; real Basecamp's metrics differ (Scala's harness warns about this).

## Scope

- Install from a local repo; walk the checklist below; fix overflow/metrics.

## Done when

- [ ] Checklist ticked on Basecamp 0.3.x.
## Checklist

- [ ] Installs beside Scala; both open; Scala's intents still go to Scala.
- [ ] Month / week / day / board / timeline / venues / analytics render without overflow at 1280×800 and 1920×1080.
- [ ] Drag a night on the grid, in week view and on the board (to another venue column).
- [ ] Night panel: every section adds, edits and removes; read-only calendars refuse with a message.
- [ ] Upload a file (Logos Storage), use it as the poster, open it, flag it Community.
- [ ] Line-up and crew pick from Kith; a form is created in WhisperBox and its answers open.
- [ ] Make a night public; the copy appears in the public calendar and on an Android phone.
- [ ] FT88 Serif present → used; absent → monospace, nothing breaks.
