# BrowserPick

A tiny macOS menubar utility that intercepts links and lets you pick which browser to open them in.

Register BrowserPick as your default browser, and every time something tries to open an `http(s)://` link, you get a quick chooser with all the browsers you've added. Pick one, link opens.

Inspired by [Velja](https://sindresorhus.com/velja) and [Choosy](https://choosy.app), but minimal, open source, and free.

## Features

Minimum viable scope:

- Menubar icon — no dock icon. Icon shows the app is running; menu has two items: **Launch at Login** toggle and **Quit**.
- Registers as the system handler for `http` and `https`.
- Chooser popup on every intercepted URL — keyboard-driven (number keys / arrows + return).
- Settings window to add/remove browsers manually (any `.app` that can open URLs).
- Per-browser custom name, icon, and keyboard shortcut.
- "Open last used" and "Always ask" modes.

## Tech

- **Language:** Swift 5.9+
- **UI:** SwiftUI for settings/chooser, AppKit (`NSStatusItem`) for the menubar.
- **Build:** Xcode project, signed locally for dev.
- **Min macOS:** 15 Sequoia.
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

## Release

Releases are distributed via a personal Homebrew tap — no App Store, no notarization required initially.

**Steps for each release:**

1. Build a Release archive in Xcode → export the `.app`.
2. Zip it: `ditto -c -k --keepParent BrowserPick.app BrowserPick.zip`
3. Create a GitHub Release and upload the zip. Note the SHA256: `shasum -a 256 BrowserPick.zip`
4. Update the cask in `homebrew-tap/Casks/browserpick.rb` with the new version, URL, and SHA256.

**Homebrew tap setup** (one-time, in a separate repo `cvladan/homebrew-tap`):

```ruby
# Casks/browserpick.rb
cask "browserpick" do
  version "0.1.0"
  sha256 "..."

  url "https://github.com/cvladan/browser-pick/releases/download/v#{version}/BrowserPick.zip"
  name "BrowserPick"
  desc "Pick which browser opens a link"
  homepage "https://github.com/cvladan/browser-pick"

  app "BrowserPick.app"
end
```

**Install:**

```sh
brew tap cvladan/tap
brew install --cask browserpick
```

If Gatekeeper complains after install:

```sh
xattr -dr com.apple.quarantine /Applications/BrowserPick.app
```

Then set BrowserPick as default browser in System Settings → Desktop & Dock → Default web browser.

## Status

Pre-alpha. Repo just initialized.

## License

MIT (TBD — add `LICENSE` before first release).
