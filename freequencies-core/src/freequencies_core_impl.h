#pragma once

#include <string>
#include "logos_module_context.h"

/**
 * FreequenciesCoreImpl - the Freequencies view's background helper.
 *
 * Basecamp gives ui_qml views no network access, so the view asks this core module for the public
 * listings feeds it shows in its calendar (Luma's official "What's Happening in Lisbon" feed for
 * now). The view names a feed by id; the address is fixed here, so nothing else can be fetched.
 *
 * Pure C++ (no Qt). Public methods are the module's API (logos-cpp-generator).
 */
class FreequenciesCoreImpl : public LogosModuleContext {
public:
    FreequenciesCoreImpl();
    ~FreequenciesCoreImpl() override;

    /// Module version, for the view's debug panel.
    std::string coreVersion() const;
    /// The feed ids this module can fetch, as a JSON array of {id, label, url}.
    std::string listFeeds() const;
    /// Fetch one feed by id. JSON: {"ok":true,"id":…,"body":"<ics text>","bytes":N} or {"ok":false,"error":…}.
    std::string fetchFeed(const std::string& feedId);
};
