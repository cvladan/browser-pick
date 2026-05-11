# BrowserPick

A tiny macOS menubar utility that intercepts links and lets you pick which browser to open them in.

**380 KB on disk · ~53 MB of memory at idle.** Native Swift, no Electron, no web views, no telemetry.

Register BrowserPick as your default browser, and every time something tries to open an `http(s)://` link, you get a quick chooser with all the browsers you've added. Pick one, link opens.

Inspired by [Velja](https://sindresorhus.com/velja) and [Choosy](https://choosy.app), but minimal, open source, and free.

## Features

Minimum viable scope:

- Menubar icon — no dock icon. Icon indicates the app is running. Clicking it opens **Settings**. Right-click (or menu) has two items: **Settings** and **Quit**.
- Registers as the system handler for `http` and `https`.
- Chooser popup on every intercepted URL — keyboard-driven (number keys / arrows + return).
- Settings window:
  - Manage browser list — add/remove any `.app` that can open URLs.
  - Per-browser custom name, icon, and keyboard shortcut.
  - Launch at Login toggle.

## Tech

- **Language:** Swift 6
- **UI:** SwiftUI hosted inside AppKit windows (`NSPanel`, `NSWindow`). Menubar via `NSStatusItem`.
- **State:** `@Observable` macro, persisted to `UserDefaults`.
- **Launch at Login:** `SMAppService.mainApp`.
- **Build system:** Swift Package Manager + shell script that assembles a `.app` bundle. No Xcode required — just Command Line Tools.
- **Min macOS:** 15 Sequoia.
- **Distribution:** GitHub Releases + standalone Homebrew Cask file (no tap, direct URL install).

### Why these choices

- Swift 6 + SwiftUI hosted in AppKit: native, no runtime, smallest binary, best Gatekeeper story. AppKit for menubar gives us proper left-click vs right-click behavior that SwiftUI's `MenuBarExtra` can't.
- SPM over Xcode project: no `.xcodeproj` noise in the repo, builds from CLT, builds in CI without installing Xcode.
- Homebrew Cask: zero-friction install for devs. Skips notarization pain initially — users can `xattr -dr com.apple.quarantine` if needed.

## URL handling

Registered in `Info.plist` via `CFBundleURLTypes` for `http` and `https`. Runtime URL events handled by `NSAppleEventManager` (`kAEGetURL`). macOS routes link clicks to whatever app the user set as default browser in System Settings → Desktop & Dock → Default web browser.

## Prerequisites

- **macOS 15+ (Sequoia or later)**
- **Xcode Command Line Tools:** `xcode-select --install`
- **Swift 6.0+:** ships with CLT on macOS 15+. Verify with `swift --version`.

Nothing else needed. No Xcode, no Homebrew, no extra package managers.

## Build & run

For development, use `install.sh`. It builds, copies the app to `/Applications`, registers it with Launch Services, and launches it:

```sh
./install.sh           # debug
./install.sh release   # release
```

**Why install to `/Applications`?** macOS only considers apps in Launch-Services-indexed locations (mainly `/Applications`) as candidates for the default browser. Running from `.build/` works for basic UI testing but the system won't let you set it as default and link interception won't work reliably.

On first launch, BrowserPick automatically asks macOS to make it the default browser — you'll see the system confirmation dialog ("Do you want to use 'BrowserPick' to open web pages?"). Click **Use 'BrowserPick'**.

The menubar icon (branch arrow) appears in the top right. Left-click → Settings. Right-click → Settings/Quit menu.

### Build only (without install)

If you just want to compile and inspect the bundle:

```sh
./build.sh           # debug
./build.sh release   # release
```

Output: `.build/BrowserPick.app`, ad-hoc signed.

## Project layout

```
Sources/BrowserPick/
├── main.swift                              entry point
├── AppDelegate.swift                       menubar + URL events
├── LaunchAtLogin.swift                     SMAppService wrapper
├── Models/
│   ├── Browser.swift                       browser model + discovery
│   └── BrowserStore.swift                  @Observable store, UserDefaults
├── Views/
│   ├── SettingsView.swift                  SwiftUI
│   └── ChooserView.swift                   SwiftUI
└── Windows/
    ├── SettingsWindowController.swift      NSWindowController + NSHostingController
    └── ChooserWindowController.swift       NSPanel floating chooser

Resources/Info.plist                        URL types, LSUIElement
build.sh                                    SPM build → .app assembly
install.sh                                  build → copy to /Applications → launch
browserpick.rb                              Homebrew cask
```

## Release

No tap, no App Store, no notarization for now. The cask file lives in this repo at `browserpick.rb` and is installed directly by URL.

**Steps for each release:**

1. `./build.sh release`
2. Zip the app: `ditto -c -k --keepParent .build/BrowserPick.app BrowserPick.zip`
3. Get the SHA256: `shasum -a 256 BrowserPick.zip`
4. Create a GitHub Release `vX.Y.Z` and upload the zip.
5. Update `browserpick.rb` with new `version` and `sha256`, commit, push.

## Install

```sh
brew install --cask https://raw.githubusercontent.com/cvladan/browser-pick/main/browserpick.rb
```

If Gatekeeper complains after install:

```sh
xattr -dr com.apple.quarantine /Applications/BrowserPick.app
```

Then set BrowserPick as default browser in System Settings → Desktop & Dock → Default web browser.

> **Note:** direct-URL casks don't auto-update via `brew upgrade`. To update, re-run the install command. A proper tap can come later if it matters.

## FAQ

**Why do I see a second process called "AutoFill (BrowserPick)" in Activity Monitor?**

That's `com.apple.AutoFillPanel`, a macOS XPC service for password/credit-card autofill UI. macOS automatically attaches it to any app registered as a browser (i.e. any app with `http`/`https` in `CFBundleURLTypes`) — you'll see the same helper next to Safari, Chrome, Arc, Velja, etc. BrowserPick does not start it and never invokes it (we have no web views or form input). It's a system-managed helper and costs ~12 MB. There's no way to opt out without giving up the http handler registration that makes the whole app work.

## Status

Alpha. Core features work: menubar icon, URL interception, browser chooser with keyboard shortcuts, settings window, browser discovery, launch at login. Not yet released.

## License

MIT (TBD — add `LICENSE` before first release).
