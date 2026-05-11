import AppKit
import SwiftUI

struct ChooserView: View {
    @Bindable var store: BrowserStore
    let url: URL
    let onPick: (Browser) -> Void
    let onCancel: () -> Void

    @FocusState private var focused: Bool
    @State private var keyMonitor: Any?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "link")
                Text(url.absoluteString)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Divider()

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(Array(store.browsers.enumerated()), id: \.element.id) { index, browser in
                        BrowserRow(
                            browser: browser,
                            index: index,
                            onPick: { onPick(browser) }
                        )
                    }
                }
            }
            .frame(maxHeight: 320)

            HStack {
                Text("Press number or shortcut, Esc to cancel")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
        }
        .padding(16)
        .frame(width: 420)
        .focusable()
        .focused($focused)
        .onAppear {
            focused = true
            installKeyMonitor()
        }
        .onDisappear { removeKeyMonitor() }
    }

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKey(event) ? nil : event
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    private func handleKey(_ event: NSEvent) -> Bool {
        // Escape
        if event.keyCode == 53 {
            onCancel()
            return true
        }
        guard let chars = event.charactersIgnoringModifiers else { return false }

        // Numbers 1-9
        if let digit = Int(chars), digit >= 1, digit <= store.browsers.count {
            onPick(store.browsers[digit - 1])
            return true
        }
        // Letter shortcut
        if let browser = store.browser(forShortcut: chars) {
            onPick(browser)
            return true
        }
        return false
    }
}

private struct BrowserRow: View {
    let browser: Browser
    let index: Int
    let onPick: () -> Void

    var body: some View {
        Button(action: onPick) {
            HStack(spacing: 10) {
                Text(indexLabel)
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 22, alignment: .center)
                    .foregroundStyle(.secondary)

                Image(nsImage: browser.icon())
                    .resizable()
                    .frame(width: 24, height: 24)

                Text(browser.name)

                Spacer()

                if let shortcut = browser.shortcut {
                    Text(shortcut.uppercased())
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: .rect(cornerRadius: 4))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var indexLabel: String {
        index < 9 ? "\(index + 1)" : "•"
    }
}
