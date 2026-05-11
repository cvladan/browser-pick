import AppKit
import Foundation

@MainActor
enum DefaultBrowserManager {
    /// Bundle ID of whichever app is currently the system default for http URLs.
    static var currentDefaultBundleID: String? {
        guard let url = URL(string: "https://example.com"),
              let appURL = NSWorkspace.shared.urlForApplication(toOpen: url),
              let bundle = Bundle(url: appURL) else {
            return nil
        }
        return bundle.bundleIdentifier
    }

    static var isDefault: Bool {
        currentDefaultBundleID == Bundle.main.bundleIdentifier
    }

    /// Asks macOS to set BrowserPick as the default for http/https.
    /// macOS will show its own confirmation dialog. We can't bypass that.
    static func setAsDefault(completion: @escaping @Sendable @MainActor (Error?) -> Void) {
        let bundleURL = Bundle.main.bundleURL
        let workspace = NSWorkspace.shared

        workspace.setDefaultApplication(at: bundleURL, toOpenURLsWithScheme: "http") { httpErr in
            if let httpErr {
                Task { @MainActor in completion(httpErr) }
                return
            }
            workspace.setDefaultApplication(at: bundleURL, toOpenURLsWithScheme: "https") { httpsErr in
                Task { @MainActor in completion(httpsErr) }
            }
        }
    }
}
