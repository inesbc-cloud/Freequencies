"""Mock Basecamp bridge for the offscreen preview: scala, loam_core, kith, whisperbox_core, with seeded Lisbon data."""
import json, os, sys, time, random, string, datetime as dt
from PySide6.QtCore import QObject, Slot, QTimer
from PySide6.QtQml import QJSValue

HERE = os.path.dirname(os.path.abspath(__file__))
ME = "0xme00000000000000000000000000000000000001"
OTHER = "0xines000000000000000000000000000000000002"

def ms(y, mo, d, h=0, mi=0):
    return int(dt.datetime(y, mo, d, h, mi).timestamp() * 1000)

SCHEMA = [
    {"key": "status", "label": "Status", "type": "enum", "options": ["Hold", "Confirmed", "Cancelled"]},
    {"key": "venue", "label": "Venue", "type": "text"},
    {"key": "type", "label": "Type", "type": "enum", "options": ["Club night", "Concert", "Residency", "Other"]},
]
CALS = [
    {"id": "cal-freq", "name": "Freequencies", "schema": SCHEMA, "owner": ME, "authorAddr": ME, "roles": {OTHER: "editor"}, "collab": True, "open": True, "color": "#6ef600", "encryptionKey": "k1"},
    {"id": "cal-coll", "name": "Lisbon collectives", "schema": SCHEMA, "owner": OTHER, "authorAddr": ME, "roles": {ME: "editor"}, "collab": True, "open": True, "color": "#4aa8ff"},
    {"id": "cal-pub", "name": "Freequencies (public)", "schema": [], "owner": ME, "authorAddr": ME, "roles": {}, "collab": False, "open": False, "color": "#6ef600"},
    {"id": "cal-home", "name": "Personal", "schema": [], "owner": ME, "authorAddr": ME, "roles": {}, "collab": False, "open": True, "color": "#888"},
]
_ctr = [0]
def ext(ns, kind, target, data, id=None, author=ME, wall=None):
    _ctr[0] += 1
    return {"id": id or ("x" + str(_ctr[0])), "ns": ns, "kind": kind, "target": target, "author": author,
            "hlc": {"wall": wall or ms(2026, 11, 10, 12, _ctr[0] % 60), "ctr": 0}, "data": data}

def F(t, kind, data, **kw): return ext("xyz.freequencies", kind, t, data, **kw)

E25 = "ev-25nov"
EVENTS = [
    {"id": E25, "calendarId": "cal-freq", "title": "Freequencies 02", "startTime": ms(2026, 11, 25, 17), "endTime": ms(2026, 11, 25, 23),
     "creatorId": ME, "fields": {"status": "Confirmed", "venue": "Damas", "type": "Concert"},
     "description": "19h conversation: the challenges of organising culture today, with three Lisbon artists and promoters.\nInstall station by the bar. Bring laptops.",
     "rsvps": {ME: "going", OTHER: "going", "0xa": "going", "0xb": "maybe", "0xc": "going"},
     "attachments": [{"name": "EVENTO-02_poster.png", "mime": "image/png", "size": 812345, "storageCid": "zDvZRwzm2poster", "blobId": "b1"},
                     {"name": "Damas_tech_rider.pdf", "mime": "application/pdf", "size": 120400, "storageCid": "zDvZRwzm3rider", "blobId": "b2"}],
     "ext": [
        F(E25, "artist", {"name": "Perolidade", "status": "confirmed", "fee": 250, "currency": "EUR", "set": "20:00", "contact": "k1", "book": "bk1"}),
        F(E25, "artist", {"name": "Oseias", "status": "confirmed", "fee": 300, "currency": "EUR", "set": "21:15", "contact": "k2", "book": "bk1"}),
        F(E25, "artist", {"name": "Collective Unconscious", "status": "confirmed", "fee": 200, "currency": "EUR", "set": "17:00"}),
        F(E25, "artist", {"name": "Post Carbon", "status": "asked", "fee": 150, "currency": "EUR", "set": "22:15"}),
        F(E25, "crew", {"name": "Lola", "role": "Door", "status": "confirmed", "call": "16:30"}, id="crew1"),
        F(E25, "crew", {"name": "Ines", "role": "Sound", "status": "confirmed", "call": "15:00"}, id="crew2"),
        F(E25, "crew", {"name": "", "role": "Bar", "status": "asked"}, id="crew3"),
        F(E25, "checkin", {"crew": "crew2", "at": ms(2026, 11, 25, 15, 4)}, id="checkin:crew2:aa"),
        F(E25, "tags", {"tags": ["live coding", "talk", "free entry"]}, id="tags:" + E25),
        F(E25, "tickets", {"url": "https://lu.ma/freequencies-02", "sold": 142, "capacity": 180, "price": 0, "currency": "EUR"}, id="tickets:" + E25),
        F(E25, "gear", {"item": "CDJ-3000 ×2", "done": True}, id="gear1"),
        F(E25, "gear", {"item": "DJM-900 mixer", "done": True}, id="gear2"),
        F(E25, "gear", {"item": "Projector + HDMI run to booth", "done": False}, id="gear3"),
        F(E25, "gear", {"item": "Install station: 2 laptops, power strip", "done": False}, id="gear4"),
        F(E25, "task", {"text": "Announce line-up on IG", "due": ms(2026, 11, 18, 18), "cat": "social", "done": True}, id="t1"),
        F(E25, "task", {"text": "Send PR to local press", "due": ms(2026, 11, 20, 12), "cat": "comms", "done": False}, id="t2"),
        F(E25, "task", {"text": "Pay Damas deposit", "due": ms(2026, 11, 17, 12), "cat": "payment", "done": False}, id="t3"),
        F(E25, "task", {"text": "Countersign Oseias contract", "due": ms(2026, 11, 22, 12), "cat": "contract", "done": False}, id="t4"),
        F(E25, "budget", {"label": "Logos support", "amount": 2000, "currency": "EUR", "dir": "in"}, id="b1"),
        F(E25, "budget", {"label": "Bar share", "amount": 450, "currency": "EUR", "dir": "in"}, id="b2"),
        F(E25, "budget", {"label": "Venue", "amount": 400, "currency": "EUR", "dir": "out"}, id="b3"),
        F(E25, "budget", {"label": "Posters + print", "amount": 120, "currency": "EUR", "dir": "out"}, id="b4"),
        F(E25, "budget", {"label": "Sound hire", "amount": 220, "currency": "EUR", "dir": "out"}, id="b5"),
        F(E25, "post", {"text": "Line-up reveal carousel", "when": ms(2026, 11, 19, 18), "channel": "Instagram", "done": False}, id="p1"),
        F(E25, "post", {"text": "Day-of story: install station", "when": ms(2026, 11, 25, 12), "channel": "Instagram", "done": False}, id="p2"),
        F(E25, "poster", {"url": "file://" + os.path.join(HERE, "poster-02.png")}, id="poster:" + E25),
        ext("scala", "comment", E25, {"text": "Damas confirmed the bar share. Doors 17h."}, author=OTHER),
        ext("scala", "comment", E25, {"text": "Post Carbon to confirm by Friday."}, author=ME),
     ]},
    {"id": "ev-7oct", "calendarId": "cal-freq", "title": "Freequencies 01", "startTime": ms(2026, 10, 7, 18), "endTime": ms(2026, 10, 7, 23),
     "creatorId": ME, "fields": {"status": "Confirmed", "venue": "Damas", "type": "Concert"}, "rsvps": {},
     "ext": [F("ev-7oct", "artist", {"name": "SoundPreta", "status": "confirmed", "set": "18:00"}),
             F("ev-7oct", "artist", {"name": "Rezmorah", "status": "confirmed", "set": "20:00"}),
             F("ev-7oct", "artist", {"name": "Van Der", "status": "confirmed", "set": "21:00"}),
             F("ev-7oct", "artist", {"name": "TopLap.pt", "status": "confirmed", "set": "22:00"}),
             F("ev-7oct", "tickets", {"sold": 95, "capacity": 150, "price": 0}, id="tickets:ev-7oct"),
             F("ev-7oct", "poster", {"url": "file://" + os.path.join(HERE, "poster-01.png")}, id="poster:ev-7oct")]},
    {"id": "ev-dec", "calendarId": "cal-freq", "title": "Freequencies 03 · closing", "startTime": ms(2026, 12, 17, 18), "endTime": ms(2026, 12, 17, 23, 30),
     "creatorId": ME, "fields": {"status": "Hold", "venue": "Damas", "type": "Concert"}, "rsvps": {},
     "ext": [F("ev-dec", "tags", {"tags": ["closing", "integration report"]}, id="tags:ev-dec")]},
    {"id": "ev-rq", "calendarId": "cal-coll", "title": "Rádio Quântica night", "startTime": ms(2026, 11, 21, 23), "endTime": ms(2026, 11, 22, 5),
     "creatorId": OTHER, "fields": {"status": "Confirmed", "venue": "Lounge", "type": "Club night"}, "rsvps": {},
     "ext": [F("ev-rq", "artist", {"name": "SoundPreta", "status": "confirmed", "set": "01:00"}, author=OTHER),
             F("ev-rq", "tags", {"tags": ["techno", "radio"]}, id="tags:ev-rq", author=OTHER)]},
    {"id": "ev-zdb", "calendarId": "cal-coll", "title": "Live coding jam", "startTime": ms(2026, 11, 25, 21), "endTime": ms(2026, 11, 26, 1),
     "creatorId": OTHER, "fields": {"status": "Hold", "venue": "Damas", "type": "Other"}, "rsvps": {},
     "ext": [F("ev-zdb", "artist", {"name": "Post Carbon", "status": "asked"}, author=OTHER),
             F("ev-zdb", "tags", {"tags": ["live coding", "workshop"]}, id="tags:ev-zdb", author=OTHER)]},
    {"id": "ev-res", "calendarId": "cal-coll", "title": "Perolidade residency", "startTime": ms(2026, 11, 6, 23), "endTime": ms(2026, 11, 7, 4),
     "creatorId": OTHER, "fields": {"status": "Confirmed", "venue": "Musicbox", "type": "Residency"}, "rsvps": {},
     "recur": {"freq": "weekly", "interval": 2, "until": ms(2026, 12, 31)},
     "ext": [F("ev-res", "artist", {"name": "Perolidade", "status": "confirmed", "set": "00:30"}, author=OTHER)]},
    {"id": "ev-fund", "calendarId": "cal-coll", "title": "Quinta do Mocho fundraiser", "startTime": ms(2026, 11, 28, 16), "endTime": ms(2026, 11, 28, 22),
     "creatorId": OTHER, "fields": {"status": "Hold", "venue": "Quinta do Mocho", "type": "Other"}, "rsvps": {},
     "ext": [F("ev-fund", "tags", {"tags": ["fundraiser", "outdoor"]}, id="tags:ev-fund", author=OTHER)]},
    {"id": "ev-canc", "calendarId": "cal-coll", "title": "Ambient Sunday", "startTime": ms(2026, 11, 22, 17), "endTime": ms(2026, 11, 22, 21),
     "creatorId": OTHER, "fields": {"status": "Cancelled", "venue": "Lounge", "type": "Concert"}, "rsvps": {},
     "ext": [F("ev-canc", "tags", {"tags": ["ambient"]}, id="tags:ev-canc", author=OTHER)]},
    {"id": "pub-" + E25, "calendarId": "cal-pub", "title": "Freequencies 02", "startTime": ms(2026, 11, 25, 17), "endTime": ms(2026, 11, 25, 23), "fields": {}, "ext": []},
]
EVENTS[0]["ext"].append(F(E25, "public", {"calendar": "cal-pub"}, id="public:" + E25 + ":abc"))
EVENTS[0]["ext"].append(F(E25, "file", {"cid": "zDvZRwzm2poster", "visibility": "public"}, id="file:" + E25 + ":zDvZRwzm2poster"))

WB_FORMS = {}

BOOKS = [{"id": "bk1", "name": "Lisbon artists"}]
CONTACTS = {"bk1": [{"id": "k1", "name": {"display": "Perolidade"}}, {"id": "k2", "name": {"display": "Oseias"}},
                    {"id": "k3", "name": {"display": "SoundPreta"}}, {"id": "k4", "name": {"display": "Rezmorah"}},
                    {"id": "k5", "name": {"display": "Van Der"}}]}

def rid(): return "".join(random.choice(string.ascii_lowercase + string.digits) for _ in range(10))

class Bridge(QObject):
    def handle(self, module, method, a):
        if module == "scala":
            if method == "coreVersion": return "0.12.7"
            if method == "getIdentity": return ME
            if method == "hdState": return {"pending": 0, "error": ""}
            if method == "keycardState": return {"active": False}
            if method == "updateCalendarMeta":
                patch = json.loads(a[1])
                for c in CALS:
                    if c["id"] == a[0]: c.update(patch); return True
                return False
            if method == "deleteEvent":
                for i, e in enumerate(EVENTS):
                    if e["id"] == a[1] or e["id"] == a[0]: EVENTS.pop(i); return True
                return False
            if method == "createCalendar":
                cid = "cal-" + rid()
                CALS.append({"id": cid, "name": a[0], "color": a[1] or "#6ef600", "owner": ME, "authorAddr": ME, "roles": {}, "schema": [],
                             "encryptionKey": "k", "open": True, "collab": False})
                return cid
            if method == "listCalendars": return CALS
            if method == "listAllEvents": return EVENTS
            if method == "getEvent":
                for e in EVENTS:
                    if e["id"] == a[0]: return e
                return None
            if method == "updateEvent":
                up = json.loads(a[0])
                for i, e in enumerate(EVENTS):
                    if e["id"] == up["id"]:
                        up["ext"] = e.get("ext", []); up["rsvps"] = e.get("rsvps", {}); EVENTS[i] = up; return up["id"]
                return ""
            if method == "createEvent":
                ev = json.loads(a[1]); ev["id"] = "ev-" + rid(); ev["calendarId"] = a[0]; ev["ext"] = []; ev["creatorId"] = ME
                EVENTS.append(ev); return ev["id"]
            if method == "putEvent":
                ev = json.loads(a[2]); ev["id"] = a[1]; ev["calendarId"] = a[0]; ev.setdefault("ext", [])
                for i, e in enumerate(EVENTS):
                    if e["id"] == a[1] and e["calendarId"] == a[0]: EVENTS[i] = ev; return a[1]
                EVENTS.append(ev); return a[1]
            if method == "postExt":
                item = json.loads(a[1]); item.setdefault("id", rid()); item["author"] = ME
                item["hlc"] = {"wall": int(time.time() * 1000), "ctr": 0}
                for e in EVENTS:
                    if e["id"] == item["target"]:
                        e["ext"] = [x for x in e.get("ext", []) if x["id"] != item["id"]] + [item]
                        return {"ok": True, "id": item["id"]}
                return {"ok": False, "error": "no such event"}
            if method == "deleteExt":
                for e in EVENTS:
                    n = len(e.get("ext", []))
                    e["ext"] = [x for x in e.get("ext", []) if x["id"] != a[1]]
                    if len(e["ext"]) != n: return {"ok": True}
                return {"ok": False}
            if method == "uploadAttachment": return "up:" + os.path.basename(a[1])
            if method == "downloadAttachment": return "dl:" + a[1]
            if method == "attachmentStatus":
                ref = a[0]
                if ref.startswith("dl:"):   # a download: posters map to the seeded images next to this file
                    p = os.path.join(HERE, "poster-02.png" if "poster" in ref else "poster-01.png")
                    return {"ok": True, "path": p}
                return {"ok": True, "cid": "zNEW" + rid(), "name": ref[3:] or "file.pdf", "mime": "application/pdf", "size": 1000, "blobId": "b9"}
            if method == "createInvite": return {"ok": True, "link": "scala://join?x"}
            return ""
        if module == "loam_core":
            if method == "listIdentities": return [{"id": "device", "kind": "device", "label": "This device", "address": ME}]
            if method == "getDefaultIdentityId": return "device"
            if method == "hdStatus": return {"exists": False, "unlocked": False}
            if method == "identityForContainer": return {"id": "device"}
            return ""
        if module == "kith":
            if method == "listBooks": return BOOKS
            if method == "listContacts": return CONTACTS.get(a[0], [])
        if module == "whisperbox_core":
            if method == "snapshot": return {"state": {"forms": WB_FORMS}, "creatorView": {"responses": {}}}
            if method == "createForm":
                d = json.loads(a[0]); fid = "f-" + rid(); WB_FORMS[fid] = d; return {"ok": True, "formId": fid}
            if method == "shareUri": return {"ok": True, "uri": "whisperbox://form/" + a[0]}
            if method == "formSummary":
                f = WB_FORMS.get(a[0], {}); return {"ok": True, "title": f.get("title", "Form"), "status": "open", "canRead": True, "responses": 2, "newResponses": 1}
            if method == "getDecryptedResponses":
                f = WB_FORMS.get(a[0], {}); qs = f.get("questions", [])
                return {"ok": True, "responses": [{"submittedAt": int(time.time() * 1000) - 3600e3,
                         "answers": [{"questionId": q.get("id"), "value": "Lola + 1" if i == 0 else "lola@example.org"} for i, q in enumerate(qs[:2])]}]}
        return ""

    @Slot(str, str, "QVariantList", QJSValue, int)
    def callModuleAsync(self, module, method, args, cb, timeout):
        res = self.handle(module, method, list(args))
        out = json.dumps(res)
        QTimer.singleShot(5, lambda: cb.call([out]))


