# #18 Budget per night

- **Milestone:** C · Tools on each night
- **Size:** S
- **Depends on:** [#10](10-lineup.md), [#13](13-tickets.md)
- **Plan item (Track A):** Budget tracker

## Why

Income and costs; artist fees and ticket sales count by themselves.

## Scope

- `moneyOf`; `fq/sections/BudgetSection.qml`; budget lines in `ItemPopup`.

## Data

ext `budget` `{label, amount, currency, dir}`.

## Done when

- [ ] In / out / result tiles.
- [ ] Unit tests.

## Not in this issue

- Moving budgets to KYM (ADR 0006).
