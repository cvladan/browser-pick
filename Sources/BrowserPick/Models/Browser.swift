import AppKit
import Foundation

struct Browser: Identifiable, Codable, Hashable {
    var id: String { bundleIdentifier }
    let bundleIdentifier: String
    var name: String
    var bundleURL: URL
    var shortcut: String? // single-character keyboard shortcut, lowercase

    static func discoverInstalled() -> [Browser] {
        // Find all apps registered as handlers for http://
        let handlers = LSCopyAllHandlersForURLScheme("http" as CFString)?
            .takeRetainedValue() as? [String] ?? []

        let ourBundleID = Bundle.main.bundleIdentifier ?? ""

        return handlers.compactMap { bundleID -> Browser? in
            guard bundleID != ourBundleID else { return nil }
            guard let url = NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: bundleID
            ) else { return nil }

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
