# #3 Freequencies look: tokens, square grid, header

- **Milestone:** A · Fork and foundation
- **Size:** M
- **Depends on:** [#1](01-fork-scala-app.md)
- **Plan item (Track A):** Design language (Freequencies site + posters)

## Why

Scala is warm Catppuccin with round cards; Freequencies is a terminal ground, acid green, ruled square grid, `>_` and `(( ))` motifs.

## Scope

- Swap Scala's palette block for Freequencies tokens (`fq/lib/tokens.js` + the view's `c*` colours): ground #050805, lime #6ef600, acid #7bf686, signal #4aa8ff, warn #ffc531, red #ff5a4a; body grey a shade lighter than the site's.
- Square corners everywhere (radius 0), 1 px ruled lines.
- Header: dish mark + FREEQUENCIES wordmark + `( coordination tool · lisboa )`, faint scanlines.
- Scala's `Field.qml` input restyled (dark field, lime focus).

## Data

None.

## Reused from Scala

Scala's layout, panes and popups unchanged in structure.

## Done when

- [ ] No Catppuccin colour left in the view (grep).
- [ ] Labels at least 12 px.
- [ ] Screenshot matches the mock-up's palette.
