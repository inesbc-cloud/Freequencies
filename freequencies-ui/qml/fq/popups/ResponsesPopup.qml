// A form's answers (#20), decrypted by WhisperBox for its creator.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../lib/forms.js" as Forms

Win {
    id: rp
    property var app
    property var rows: []
    title: "answers.exe"
    width: 520
    function openFor(f) {
        rows = []; open()
        var w = app.wbForms[f.formId] || {}, qs = Array.isArray(w.questions) ? w.questions : []
        app.wb("getDecryptedResponses", [f.formId], function (r) {
            var res = app.j(r, {})
            if (!res || !res.ok || !Array.isArray(res.responses)) { rp.rows = [{ head: "Couldn't read the answers", lines: [res && res.error ? String(res.error) : "Only the form's creator can read them."] }]; return }
            var out = []
            for (var i = 0; i < res.responses.length; i++) {
                var rr = res.responses[i] || {}, ans = Array.isArray(rr.answers) ? rr.answers : [], lines = []
                for (var k = 0; k < ans.length; k++) {
                    var a = ans[k] || {}, qq = null
                    for (var m = 0; m < qs.length; m++) if (qs[m] && qs[m].id === a.questionId) { qq = qs[m]; break }
                    lines.push((qq ? String(qq.text) : String(a.questionId)) + ": " + Forms.answerText(qq, a.value))
                }
                out.push({ head: typeof rr.submittedAt === "number" ? Qt.formatDateTime(new Date(rr.submittedAt), "d MMM hh:mm") : "Answer " + (i + 1), lines: lines })
            }
            rp.rows = out.length ? out : [{ head: "No answers yet", lines: [] }]
        })
    }
    ScrollView {
        Layout.fillWidth: true; Layout.preferredHeight: Math.min(420, inner.implicitHeight + 4); clip: true
        ColumnLayout {
            id: inner
            width: rp.width - 40; spacing: 10
            Repeater { model: rp.rows
                delegate: ColumnLayout { required property var modelData; Layout.fillWidth: true; spacing: 2
                    FText { text: modelData.head; color: Fq.lime; font.pixelSize: 12 }
                    Repeater { model: modelData.lines; delegate: FText { required property var modelData; Layout.fillWidth: true; wrapMode: Text.Wrap; text: modelData; font.pixelSize: 13 } } } }
        }
    }
    FqButton { Layout.alignment: Qt.AlignRight; text: "Close"; onClicked: rp.close() }
}
