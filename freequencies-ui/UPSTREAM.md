# Upstream: Scala's calendar view

`qml/FreequenciesView.qml` and `qml/Field.qml` started as a copy of Scala's view:

- repository: https://github.com/vpavlin/scala
- path: `scala-ui/qml/CalendarView.qml`, `scala-ui/qml/Field.qml`
- commit: `48f644787b9762ad60c43e34a12ff63ae9db2e61` (scala_ui 0.12.1)

Changes on top are one commit per issue in `docs/issues/`. Freequencies' own code lives in `qml/fq/`
and in blocks marked `Freequencies` in the view, so Scala's parts can be compared with upstream.

## Pulling a later Scala fix

```sh
git -C ../scala diff 48f6447..<new> -- scala-ui/qml/CalendarView.qml > /tmp/scala.patch
patch -p3 --merge qml/FreequenciesView.qml < /tmp/scala.patch   # resolve conflicts, then bump the commit above
```

The app-intent block (`provides` in Scala's metadata, `handleIntent` in its view) is left out on purpose:
Scala answers `scala.*` intents, so both can be installed side by side.
