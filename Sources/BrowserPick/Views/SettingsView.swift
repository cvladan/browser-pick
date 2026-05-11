import AppKit
import SwiftUI

struct SettingsView: View {
    @Bindable var store: BrowserStore
    @State private var selection: Browser.ID?
    @State private var launchAtLogin: Bool = LaunchAtLogin.isEnabled
    @State private var isDefault: Bool = DefaultBrowserManager.isDefault
    @State private var defaultErrorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            defaultBrowserSection

            Divider()

            Text("Browsers")
                .font(.headline)

            browserList

            HStack {
                Button {
                    addBrowser()
                } label: {
                    Image(systemName: "plus")
                }
                Button {
                    if let id = selection,
                       let b = store.browsers.first(where: { $0.id == id }) {
                        store.remove(b)
                    }
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(selection == nil)

                Button("Rediscover") {
                    store.rediscover()
                }

                Spacer()
            }

            Divider()

            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    LaunchAtLogin.isEnabled = newValue
                }
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 520)
    }

    private var defaultBrowserSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: isDefault ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .foregroundStyle(isDefault ? .green : .orange)
                if isDefault {
                    Text("BrowserPick is your default browser.")
                } else {
                    Text("BrowserPick is **not** your default browser.")
                }
                Spacer()
                if !isDefault {
                    Button("Set as Default") {
                        setAsDefault()
                    }
                }
            }
            if let message = defaultErrorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func setAsDefault() {
        defaultErrorMessage = nil
        DefaultBrowserManager.setAsDefault { error in
            if let error {
                defaultErrorMessage = "Failed: \(error.localizedDescription)"
            }
            isDefault = DefaultBrowserManager.isDefault
        }
    }

    private var browserList: some View {
        Table(store.browsers, selection: $selection) {
            TableColumn("") { browser in
                Image(nsImage: browser.icon())
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            .width(28)

            TableColumn("") { browser in
                TextField("", text: nameBinding(for: browser))
                    .background(ToolTip(browser.bundleIdentifier))
            }

            TableColumn("Shortcut") { browser in
                TextField("", text: shortcutBinding(for: browser))
                    .frame(width: 60)
                    .background(ToolTip("Single key. Pressing this letter in the chooser opens this browser. Leave blank to disable."))
            }
            .width(80)
        }
        .frame(minHeight: 240)
    }

    private func nameBinding(for browser: Browser) -> Binding<String> {
        Binding(
            get: { browser.name },
            set: { newValue in
                var updated = browser
                updated.name = newValue
                store.update(updated)
            }
        )
    }

    private func shortcutBinding(for browser: Browser) -> Binding<String> {
        Binding(
            get: { browser.shortcut ?? "" },
            set: { newValue in
                var updated = browser
                let trimmed = String(newValue.prefix(1)).lowercased()
                updated.shortcut = trimmed.isEmpty ? nil : trimmed
                store.update(updated)
            }
        )
    }

    private func addBrowser() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let bundle = Bundle(url: url),
              let bundleID = bundle.bundleIdentifier else { return }

        let name = FileManager.default
            .displayName(atPath: url.path)
            .replacingOccurrences(of: ".app", with: "")

        store.add(Browser(
            bundleIdentifier: bundleID,
            name: name,
            bundleURL: url,
            shortcut: nil
        ))
    }
}

// `.help()` is unreliable on TextFields inside Table cells — SwiftUI doesn't
// propagate the tooltip to the underlying NSTextField. Setting NSView.toolTip
// directly via a background NSView is the only reliable approach.
private struct ToolTip: NSViewRepresentable {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        v.toolTip = text
        return v
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.toolTip = text
    }
}
