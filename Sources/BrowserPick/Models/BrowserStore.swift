import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class BrowserStore {
    private(set) var browsers: [Browser] = []

    private let storageKey = "browsers"
    private let defaults = UserDefaults.standard

    init() {
        load()
        if browsers.isEmpty {
            browsers = Browser.discoverInstalled()
            save()
        }
    }

    func add(_ browser: Browser) {
        guard !browsers.contains(where: { $0.bundleIdentifier == browser.bundleIdentifier }) else {
            return
        }
        browsers.append(browser)
        save()
    }

    func remove(at offsets: IndexSet) {
        browsers.remove(atOffsets: offsets)
        save()
    }

    func remove(_ browser: Browser) {
        browsers.removeAll { $0.bundleIdentifier == browser.bundleIdentifier }
        save()
    }

    func update(_ browser: Browser) {
        guard let idx = browsers.firstIndex(where: { $0.bundleIdentifier == browser.bundleIdentifier }) else {
            return
        }
        browsers[idx] = browser
        save()
    }

    func rediscover() {
        let discovered = Browser.discoverInstalled()
        let existingIDs = Set(browsers.map(\.bundleIdentifier))
        for b in discovered where !existingIDs.contains(b.bundleIdentifier) {
            browsers.append(b)
        }
        save()
    }

    func browser(forShortcut key: String) -> Browser? {
        browsers.first { $0.shortcut?.lowercased() == key.lowercased() }
    }

    func browser(at index: Int) -> Browser? {
        guard browsers.indices.contains(index) else { return nil }
        return browsers[index]
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Browser].self, from: data) else {
            return
        }
        browsers = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(browsers) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
