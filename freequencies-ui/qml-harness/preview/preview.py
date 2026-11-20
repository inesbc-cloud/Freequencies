"""Offscreen preview of FreequenciesView.qml against a mock Basecamp bridge (mock.py).

  pip install PySide6
  python3 preview.py ../../qml/FreequenciesView.qml shots "" "view='month'" "?expr" "@objName.prop=value" "!drag x1,y1,x2,y2"

Each argument after the output folder is a step: a JS statement run on the view's root (then a
screenshot), "?expr" prints a value, "@name.prop=v" sets a property on the item with that objectName,
"%name: js" runs js in that item's own context (so ids inside its file are in scope),
"!drag" drags with the mouse, "!click x,y" clicks. NOT the real design system (stubs/): use it for "renders, no errors,
right pieces", and check widths/overflow on real Basecamp (docs/issues/29-basecamp-test-pass.md).
Drop poster-01.png / poster-02.png next to this file to see posters in the seeded nights.
"""
import json, os, sys
from PySide6.QtCore import QObject, QTimer, QUrl, QEventLoop
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlExpression
from PySide6.QtQuick import QQuickView
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mock import Bridge, EVENTS, CALS

def main():
    qml, outdir = sys.argv[1], sys.argv[2]
    scenarios = sys.argv[3:] or [""]
    os.makedirs(outdir, exist_ok=True)
    os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
    app = QGuiApplication(sys.argv)
    view = QQuickView()
    view.engine().addImportPath(os.path.join(os.path.dirname(__file__), "stubs"))
    bridge = Bridge()
    view.rootContext().setContextProperty("logos", bridge)
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    view.resize(int(os.environ.get("HW","1440")), int(os.environ.get("HH","900")))
    view.setSource(QUrl.fromLocalFile(os.path.abspath(qml)))
    for e in view.errors(): print("QML ERROR:", e.toString())
    if view.status() != QQuickView.Ready: sys.exit(1)
    view.show()
    def pump(msec):
        loop = QEventLoop(); QTimer.singleShot(msec, loop.quit); loop.exec()
    pump(1500)
    root = view.rootObject()
    for i, sc in enumerate(scenarios):
        if sc.startswith("!click"):
            from PySide6.QtTest import QTest
            from PySide6.QtCore import Qt, QPoint
            x, y = [int(v) for v in sc[6:].split(",")]
            QTest.mouseClick(view, Qt.LeftButton, Qt.NoModifier, QPoint(x, y)); pump(700); continue
        if sc.startswith("%"):
            # "%objName: js" runs js in that item's own QML context (its ids are in scope)
            from PySide6.QtQml import QQmlEngine
            from PySide6.QtCore import QObject as _Q
            name, js = sc[1:].split(":", 1)
            obj = root.findChild(_Q, name.strip())
            if obj is None: print("NO OBJECT", name); continue
            ex = QQmlExpression(QQmlEngine.contextForObject(obj), obj, js.strip()); v = ex.evaluate()
            if ex.hasError(): print("SCENARIO ERROR:", sc, ex.error().toString())
            elif v is not None and js.strip().startswith("?"): pass
            pump(900)
            if js.strip().endswith(";?"): print("EVAL", v); continue
        elif sc.startswith("!drag"):
            from PySide6.QtTest import QTest
            from PySide6.QtCore import Qt, QPoint
            x1, y1, x2, y2 = [int(v) for v in sc[5:].split(",")]
            QTest.mousePress(view, Qt.LeftButton, Qt.NoModifier, QPoint(x1, y1)); pump(50)
            for k in range(1, 21):
                QTest.mouseMove(view, QPoint(x1 + (x2 - x1) * k // 20, y1 + (y2 - y1) * k // 20)); pump(20)
            img = view.grabWindow(); img.save(os.path.join(outdir, "drag%02d.png" % i))
            QTest.mouseRelease(view, Qt.LeftButton, Qt.NoModifier, QPoint(x2, y2)); pump(900)
        elif sc.startswith("@"):
            name, rest = sc[1:].split(".", 1); prop, val = rest.split("=", 1)
            from PySide6.QtCore import QObject as _Q
            obj = root.findChild(_Q, name); obj.setProperty(prop.strip(), float(val)); pump(600)
        elif sc.startswith("?"):
            ex = QQmlExpression(view.rootContext(), root, sc[1:]); v = ex.evaluate()
            print("EVAL", sc[1:60], "=>", v if not ex.hasError() else ex.error().toString()); continue
        elif sc:
            ex = QQmlExpression(view.rootContext(), root, sc)
            ex.evaluate()
            if ex.hasError(): print("SCENARIO ERROR:", sc, ex.error().toString())
            pump(900)
        img = view.grabWindow()
        p = os.path.join(outdir, "shot%02d.png" % i); img.save(p); print("saved", p)

if __name__ == "__main__":
    main()
