#include "freequencies_core_impl.h"

#include <cstdio>
#include <cstring>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

namespace {
struct Feed { const char* id; const char* label; const char* url; };
// Official, published feeds only. Keep in step with SOURCES in freequencies-ui/qml/fq/lib/listings.js.
const Feed kFeeds[] = {
    { "luma-lisbon", "Luma", "https://api.lu.ma/ics/get?entity=discover&id=discplace-mgGFFo5EDdyekyE" },
};
const size_t kMaxBytes = 5 * 1024 * 1024;

const Feed* findFeed(const std::string& id) {
    for (const auto& f : kFeeds) if (id == f.id) return &f;
    return nullptr;
}

// curl is on every macOS and practically every Linux desktop; the URL is a fixed constant above
// (no user input reaches the command line).
std::string curlCommand(const char* url) {
#ifdef __APPLE__
    std::string curl = "/usr/bin/curl";
#else
    std::string curl = "curl";
#endif
    return curl + " -fsSL --max-time 30 --proto =https -A 'Freequencies/0.1 (+https://github.com/inesbc-cloud/Freequencies)' '" + url + "' 2>/dev/null";
}
}  // namespace

FreequenciesCoreImpl::FreequenciesCoreImpl() = default;
FreequenciesCoreImpl::~FreequenciesCoreImpl() = default;

std::string FreequenciesCoreImpl::coreVersion() const { return "0.1.0"; }

std::string FreequenciesCoreImpl::listFeeds() const {
    json out = json::array();
    for (const auto& f : kFeeds) out.push_back({ { "id", f.id }, { "label", f.label }, { "url", f.url } });
    return out.dump();
}

std::string FreequenciesCoreImpl::fetchFeed(const std::string& feedId) {
    const Feed* f = findFeed(feedId);
    if (!f) return json{ { "ok", false }, { "error", "unknown feed" } }.dump();
    FILE* p = popen(curlCommand(f->url).c_str(), "r");
    if (!p) return json{ { "ok", false }, { "error", "could not start curl" } }.dump();
    std::string body;
    char buf[16384];
    size_t n;
    while ((n = fread(buf, 1, sizeof buf, p)) > 0) {
        body.append(buf, n);
        if (body.size() > kMaxBytes) break;
    }
    int rc = pclose(p);
    if (body.size() > kMaxBytes) return json{ { "ok", false }, { "error", "feed too large" } }.dump();
    if (rc != 0 || body.find("BEGIN:VCALENDAR") == std::string::npos)
        return json{ { "ok", false }, { "error", "fetch failed" } }.dump();
    return json{ { "ok", true }, { "id", f->id }, { "body", body }, { "bytes", body.size() } }.dump();
}
