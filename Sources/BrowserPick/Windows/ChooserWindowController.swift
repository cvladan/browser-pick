import AppKit
import SwiftUI

final class ChooserWindowController: NSWindowController {
    private let store: BrowserStore
    private let onPick: (Browser, URL) -> Void
    private var currentURL: URL?

    init(store: BrowserStore, onPick: @escaping (Browser, URL) -> Void) {
        self.store = store
        self.onPick = onPick

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 400),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "BrowserPick"
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        super.init(window: panel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func show(for url: URL) {
        currentURL = url
        let view = ChooserView(
            store: store,
            url: url,
            onPick: { [weak self] browser in
                guard let url = self?.currentURL else { return }
                self?.onPick(browser, url)
            },
            onCancel: { [weak self] in
                self?.hide()
            }
        )
        window?.contentViewController = NSHostingController(rootView: view)
        window?.setContentSize(NSSize(width: 420, height: 400))
        window?.center()
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func hide() {
        window?.orderOut(nil)
        currentURL = nil
    }
}
