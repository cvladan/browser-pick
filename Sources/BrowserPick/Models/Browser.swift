import AppKit
import Foundation

struct Browser: Identifiable, Codable, Hashable {
    var id: String { bundleIdentifier }
    let bundleIdentifier: String
    var name: String
    var bundleURL: URL
    var shortcut: String? // single-character keyboard shortcut, lowercase

    static func discoverInstalled() -> [Browser] {
        guard let probeURL = URL(string: "https://example.com") else { return [] }
        let appURLs = NSWorkspace.shared.urlsForApplications(toOpen: probeURL)

        let ourBundleID = Bundle.main.bundleIdentifier ?? ""

        return appURLs.compactMap { url -> Browser? in
            guard let bundle = Bundle(url: url),
                  let bundleID = bundle.bundleIdentifier,
                  bundleID != ourBundleID else { return nil }

            let name = FileManager.default
                .displayName(atPath: url.path)
                .replacingOccurrences(of: ".app", with: "")

            return Browser(
                bundleIdentifier: bundleID,
                name: name,
                bundleURL: url,
                shortcut: nil
            )
        }
        .sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    func icon() -> NSImage {
        NSWorkspace.shared.icon(forFile: bundleURL.path)
    }
}
