# #2 Preview harness and unit tests

- **Milestone:** A · Fork and foundation
- **Size:** S
- **Depends on:** [#1](01-fork-scala-app.md)
- **Plan item (Track A):** Engineering

## Why

Every following issue should be checkable without Basecamp: render the view against a mock bridge, and unit-test the pure logic.

## Scope

- `freequencies-ui/qml-harness/preview/`: PySide6 offscreen renderer, mock `scala`, `loam_core`, `kith`, `whisperbox_core` with seeded Lisbon data, stub `Logos.Theme` / `Logos.Controls`.
- Freequencies logic lives in `qml/fq/lib/*.js` (`.pragma library`, no Qt calls) so Node can test it: `node freequencies-ui/test/run.mjs`.
- Document both in the module README.

## Data

None.

## Reused from Scala

Scala's `qml-harness/render.sh` idea (it pins the real DS via nix; this one stubs it, so it's for structure, not DS metrics).

## Done when

- [ ] `python3 qml-harness/preview/preview.py qml/FreequenciesView.qml shots ''` renders with no QML errors.
- [ ] `node test/run.mjs` runs and passes.
