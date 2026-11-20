# #13 Ticket link and numbers

- **Milestone:** C · Tools on each night
- **Size:** S
- **Depends on:** [#8](08-night-panel.md)
- **Plan item (Track A):** Ticket link integration

## Why

Paste the ticket page; keep sold / capacity / price.

## Scope

- `ticketsOf`, `ticketLine`; `fq/sections/TicketsSection.qml`; `fq/popups/TicketsPopup.qml`.

## Data

ext `tickets` `{url?, sold?, capacity?, price?, currency?}`; newest wins.

## Done when

- [ ] Sales show as a bar against capacity.
- [ ] Unit tests.

## Not in this issue

- Live sync with a ticketing API (later: the same item, written by an integration).
