# BrowserPick

A tiny macOS menubar utility that intercepts links and lets you pick which browser to open them in.

Register BrowserPick as your default browser, and every time something tries to open an `http(s)://` link, you get a quick chooser with all the browsers you've added. Pick one, link opens.

Inspired by [Velja](https://sindresorhus.com/velja) and [Choosy](https://choosy.app), but minimal, open source, and free.

## Features

Minimum viable scope:

- Menubar app (no dock icon).
- Registers as the system handler for `http` and `https`.
- Chooser popup on every intercepted URL — keyboard-driven (number keys / arrows + return).
- Settings window to add/remove browsers manually (any `.app` that can open URLs).
- Per-browser custom name, icon, and keyboard shortcut.
- "Open last used" and "Always ask" modes.
- Launch at login.

## Tech

- **Language:** Swift 5.9+
- **UI:** SwiftUI for settings/chooser, AppKit (`NSStatusItem`) for the menubar.
- **Build:** Xcode project, signed locally for dev.
- **Min macOS:** 13 Ventura (revisit once we know what APIs we actually need).
- **Distribution:** GitHub Releases + Homebrew Cask.

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

## Install (once released)

```sh
brew install --cask browserpick
```

If Gatekeeper complains after install:

```sh
xattr -dr com.apple.quarantine /Applications/BrowserPick.app
```

Then set BrowserPick as default browser in System Settings.

## Status

Pre-alpha. Repo just initialized.

## License

MIT (TBD — add `LICENSE` before first release).
