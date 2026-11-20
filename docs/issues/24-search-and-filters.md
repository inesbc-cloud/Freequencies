# #24 Search and filters for nights

- **Milestone:** D · Views, search and overviews
- **Size:** S
- **Depends on:** [#6](06-night-cards-and-colour.md), [#10](10-lineup.md), [#12](12-tags.md)
- **Plan item (Track A):** Search & filters

## Why

Scala searches title/location/notes/fields and filters by one field value. Nights also need artists, crew, tags; and filters by status, type, tag, venue together.

## Scope

- Extend Scala's `eventsMatching` haystack with line-up, crew and tags.
- Filter chips: status (multi), type, tag, venue; applied in every view; “clear”.
- Keep Scala's date-range presets for search results.

## Data

None.

## Reused from Scala

Scala's search field, `rangeWindow`, `matchesFieldFilter`.

## Done when

- [ ] Typing an artist's name finds their nights.
- [ ] Filters combine.
- [ ] Unit tests for the matcher.
