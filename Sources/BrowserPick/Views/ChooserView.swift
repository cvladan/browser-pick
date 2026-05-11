import AppKit
import SwiftUI

struct ChooserView: View {
    @Bindable var store: BrowserStore
    let url: URL
    let onPick: (Browser) -> Void
    let onCancel: () -> Void

    @State private var keyMonitor: Any?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // URL header
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .foregroundStyle(.secondary)
                Text(url.absoluteString)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // Browser rows
            VStack(spacing: 2) {
                ForEach(Array(store.browsers.enumerated()), id: \.element.id) { index, browser in
                    BrowserRow(
                        browser: browser,
                        index: index,
                        onPick: { onPick(browser) }
                    )
                }
            }
            .padding(6)

            Divider()

            // Footer hint
            Text("Press number or shortcut · Esc to cancel")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        .frame(width: 380)
        .background(.regularMaterial, in: .rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
        .focusEffectDisabled()
        .pointerStyle(.default)
        .onAppear { installKeyMonitor() }
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

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 12) {
            Text(indexLabel)
                .font(.system(size: 13, design: .monospaced))
                .frame(width: 18, alignment: .center)
                .foregroundStyle(.tertiary)

            Image(nsImage: browser.icon())
                .resizable()
                .frame(width: 22, height: 22)

            Text(browser.name)
                .font(.system(size: 13))

            Spacer()

            if let shortcut = browser.shortcut {
                Text(shortcut.uppercased())
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: .rect(cornerRadius: 4))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(hovering ? Color.accentColor.opacity(0.15) : Color.clear, in: .rect(cornerRadius: 6))
        .contentShape(.rect)
        .onHover { hovering = $0 }
        .onTapGesture { onPick() }
        .pointerStyle(.link)
    }

    private var indexLabel: String {
        index < 9 ? "\(index + 1)" : "•"
    }
}
