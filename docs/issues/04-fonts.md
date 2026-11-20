# #4 Fonts: Bebas Neue + FT88 Serif

- **Milestone:** A · Fork and foundation
- **Size:** S
- **Depends on:** [#3](03-freequencies-look.md)
- **Plan item (Track A):** Design language

## Why

The brand pairs a condensed display face with a pixel-mono serif.

## Scope

- Bundle Bebas Neue (OFL) in `qml/fonts/`; load FT88 Serif from `qml/fonts/FT88-Serif.otf` if present (Velvetyne, OFL), else system monospace.
- `fq/FText.qml` (body) and `fq/DText.qml` (display) as separate files (not inline components: Scala's rule for every Qt runtime Basecamp bundles).
- Headings, dates, act names in Bebas; everything else FT88.

## Data

None.

## Reused from Scala

Scala's `LogosText` stays the base type.

## Done when

- [ ] Missing FT88 file doesn't break anything.
- [ ] Fonts listed in the qrc.
