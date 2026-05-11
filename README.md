# BrowserPick

A tiny macOS menubar utility that intercepts links and lets you pick which browser to open them in.

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

- **Language:** Swift 5.9+
- **UI:** SwiftUI for settings/chooser, AppKit (`NSStatusItem`) for the menubar.
- **Build:** Xcode project, signed locally for dev.
- **Min macOS:** 15 Sequoia.
- **Distribution:** GitHub Releases + standalone Homebrew Cask file (no tap, direct URL install).

### Why these choices

- Swift/SwiftUI: native, no runtime, smallest binary, best Gatekeeper story.
- AppKit menubar: SwiftUI's `MenuBarExtra` is fine but AppKit gives full control over the popup window behavior we want.
- Homebrew Cask: zero-friction install for the target audience (devs). Skips notarization pain initially — users can `xattr -dr com.apple.quarantine` if needed. Notarization can come later.

## URL handling

Registered in `Info.plist` via `CFBundleURLTypes` + `LSHandlerURLScheme` for `http` and `https`. macOS routes link clicks to whatever app the user has set as default browser in System Settings → Desktop & Dock → Default web browser.

## Build

```sh
open BrowserPick.xcodeproj
```

Hit Run. That's it for now.

## Release

No tap, no App Store, no notarization for now. The cask file lives in this repo at `browserpick.rb` and is installed directly by URL.

**Steps for each release:**

1. Build a Release archive in Xcode → export the `.app`.
2. Zip it: `ditto -c -k --keepParent BrowserPick.app BrowserPick.zip`
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

## Status

Pre-alpha. Repo just initialized.

## License

MIT (TBD — add `LICENSE` before first release).
