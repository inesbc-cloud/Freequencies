# freequencies_ui — the Freequencies Basecamp module

A fork of Scala's calendar view (see [UPSTREAM.md](UPSTREAM.md)), grown into the coordination tool for
Lisbon's independent culture one issue at a time ([docs/issues](../docs/issues/README.md)).
Nights are Scala events; Freequencies data rides in Scala's `ext` items (ADRs 0001–0009).

## Layout

| Path | What |
|---|---|
| `qml/FreequenciesView.qml` | Scala's view (forked) plus the Freequencies hooks, marked `Freequencies` |
| `qml/Field.qml` | Scala's text field, restyled |
| `qml/fq/` | Freequencies' own pieces, one file per thing: components, sections of the night panel, views, popups |
| `qml/fq/lib/*.js` | Freequencies logic as plain JavaScript libraries (no Qt calls), unit-tested in Node |
| `qml/fonts/` | Bebas Neue (bundled) and FT88 Serif (add it, see the README there) |
| `qml-harness/preview/` | Offscreen preview against a mock bridge (Scala, Loam, Kith, WhisperBox) |
| `test/` | Node tests for `qml/fq/lib` |

## Check your change

```sh
node freequencies-ui/test/run.mjs                      # logic
pip install PySide6                                    # once
python3 freequencies-ui/qml-harness/preview/preview.py freequencies-ui/qml/FreequenciesView.qml shots ""
```

The preview stubs the design system, so it tells you the view renders and has the right pieces; check
widths and overflow on real Basecamp (issue #29).

Every new file in `qml/` also goes in `qml/freequencies_ui.qrc`.
