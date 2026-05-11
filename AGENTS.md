# Agent guide

Notes for AI agents working in this repo.

## What this is

BrowserPick — macOS menubar app that registers as default `http(s)` handler and shows a chooser. See `README.md` for product scope.

## Build system

**Not** Xcode project. **Not** XcodeGen. Pure SPM + `build.sh` that assembles a `.app` bundle from the SPM-built executable. This is intentional:

- No `.xcodeproj` noise in the repo
- Builds with only Command Line Tools, no full Xcode required
- Trivial to build in CI

To build and test: `./build.sh && open .build/BrowserPick.app`. The user's machine has Swift 6.3.1 via CLT; this is enough.

## Stack

- Swift 6 (strict concurrency on — most things need `@MainActor`)
- SwiftUI for views, hosted in AppKit windows via `NSHostingController`
- AppKit `NSStatusItem` for menubar (clicking icon = Settings; right-click = menu)
- `@Observable` macro for state, persisted to `UserDefaults` as JSON
- `SMAppService.mainApp` for Launch at Login
- `NSAppleEventManager` for runtime URL events (`kAEGetURL`)
- macOS 15 Sequoia minimum, set in `Package.swift` and `Info.plist`

## Code layout

```
Sources/BrowserPick/
├── main.swift                              ~5 LOC entry point
├── AppDelegate.swift                       menubar + URL events
├── LaunchAtLogin.swift                     SMAppService wrapper
├── Models/{Browser,BrowserStore}.swift
├── Views/{Settings,Chooser}View.swift
└── Windows/{Settings,Chooser}WindowController.swift
Resources/Info.plist
build.sh
```

`main.swift` sets `NSApplication.activationPolicy = .accessory` — this is what makes the app a menubar-only app (combined with `LSUIElement = true` in Info.plist).

## Swift 6 concurrency notes

- `AppDelegate` is `@MainActor`. Same for `BrowserStore`.
- SwiftUI views inherit `@MainActor` so no annotation needed there.
- If you add a worker that runs off the main actor, marshal back via `await MainActor.run` before touching `BrowserStore`.

## Conventions

- Keep it small. Push back on scope creep. See "What NOT to add" below.
- Native macOS feel. No web views, no Electron. System fonts/colors, standard shortcuts.
- No analytics, no telemetry, no network calls. The app intercepts URLs and hands them off — that's the entire trust surface.
- Prefer SwiftUI for views; drop to AppKit for menubar (`NSStatusItem`), borderless transient panels (`NSPanel`), and other things SwiftUI doesn't give us fine control over.
- One settings window. Don't build a preferences pane with five tabs.

## Code style

- Swift API design guidelines. No Hungarian prefixes.
- File per type unless types are trivially small and tightly coupled.
- Comments only where the *why* is non-obvious (Gatekeeper quirks, undocumented AppKit behavior). Don't narrate the code.

## Gotchas

- **Default browser registration.** Changing the system default browser triggers a macOS confirmation dialog the user must click. Can't bypass.
- **Launch Services cache.** During development, URL routing may stop working after rebuilds. Fix: `/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user`.
- **Focus stealing.** The chooser panel must take focus and accept keyboard input when shown from a background context. We call `NSApp.activate(ignoringOtherApps: true)` before `makeKeyAndOrderFront`. Test from a background app (Slack, Mail) clicking a link.
- **Browser discovery.** Use `LSCopyAllHandlersForURLScheme("http")`. Exclude our own bundle ID from the discovered list.
- **Code signing.** `build.sh` does ad-hoc signing (`codesign --sign -`). For Release with notarization, that comes later when we ship a real version.
- **`NSStatusItem` menu trick.** To get left-click=action and right-click=menu on a `NSStatusItem`, do not set `statusItem.menu`. Instead set a button action, check the event type, and call `performClick` after temporarily setting the menu for the right-click case. Reset menu to nil after, asynchronously.
- **`SMAppService.mainApp.register()`** requires the app to be in `/Applications` or `~/Applications` (and properly signed for some macOS versions). It will silently fail elsewhere — that's fine for dev; just don't be surprised when toggling Launch at Login from a build in `.build/` doesn't survive a reboot.

## Distribution

- GitHub Releases for the zipped `.app`.
- Cask file `browserpick.rb` lives in repo root. Install via direct URL — no tap.
- No notarization yet. Users can `xattr -dr com.apple.quarantine` if Gatekeeper complains.

## What NOT to add

- A built-in browser.
- URL rewriting / tracking-param stripping (separate concern, separate tool).
- Sync, accounts, cloud anything.
- A plugin system.
- Cross-platform support.
- Multiple settings tabs.
- "Open last used" mode — explicitly removed. Always ask.
- Auto-update mechanism. Homebrew handles upgrades.

## Tested state

Build verified clean on macOS 26.4.1 with Swift 6.3.1 CLT. App launches, registers in menubar, accepts URL events. Visual UI not exhaustively tested — when adding/changing UI flows, build and `open .build/BrowserPick.app` to verify manually.

## When in doubt

Ask. Small, sharp, finished is the goal.
