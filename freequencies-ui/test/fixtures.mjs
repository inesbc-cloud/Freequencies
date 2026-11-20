// Shared fixtures: nights as the scala core returns them (listAllEvents), ext items included.
export const ME = "0xme", OTHER = "0xines";
export const ms = (y, mo, d, h = 0, mi = 0) => new Date(y, mo - 1, d, h, mi).getTime();
let n = 0;
export const ext = (kind, target, data, o = {}) => ({ id: o.id || kind + ":" + (++n), ns: o.ns || "xyz.freequencies", kind, target,
  author: o.author || ME, hlc: { wall: o.wall ?? 1000 + n, ctr: 0 }, data });
export const night = (id, o = {}) => ({ id, calendarId: o.cal || "cal-freq", title: o.title || id, startTime: o.start ?? ms(2026, 11, 25, 22),
  endTime: o.end ?? ms(2026, 11, 26, 4), fields: { status: o.status || "Hold", venue: o.venue ?? "Damas", type: o.type || "Club night" },
  ext: o.ext || [], rsvps: o.rsvps || {}, recur: o.recur });
