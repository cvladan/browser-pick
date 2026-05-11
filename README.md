# BrowserPick

A tiny macOS menubar utility that intercepts links and lets you pick which browser to open them in.

**380 KB on disk · ~53 MB of memory at idle.** Native Swift, no Electron, no web views, no telemetry.

Register BrowserPick as your default browser, and every time something tries to open an `http(s)://` link, you get a quick chooser with all the browsers you've added. Pick one, link opens.

Inspired by [Velja](https://sindresorhus.com/velja) and [Choosy](https://choosy.app), but minimal, open source, and free.

> **Heads up:** the first launch is blocked by macOS Gatekeeper (the build is ad-hoc signed, not Apple-notarized). You'll see *"BrowserPick.app" was blocked to protect your Mac.* — one click in **System Settings → Privacy & Security → Open Anyway** unblocks it. Full steps in [Install](#install).

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
- **Distribution:** GitHub Releases + Homebrew tap at [cvladan/homebrew-tap](https://github.com/cvladan/homebrew-tap).

### Why these choices

- Swift 6 + SwiftUI hosted in AppKit: native, no runtime, smallest binary, best Gatekeeper story. AppKit for menubar gives us proper left-click vs right-click behavior that SwiftUI's `MenuBarExtra` can't.
- SPM over Xcode project: no `.xcodeproj` noise in the repo, builds from CLT, builds in CI without installing Xcode.
- Homebrew tap: zero-friction install for devs, plus `brew upgrade` works. Skips notarization pain initially — users can `xattr -dr com.apple.quarantine` if needed.

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
release.sh                                  build → zip → GitHub Release + tap bump
```

## Install

```sh
brew install --cask cvladan/tap/browserpick
```

Brew will auto-tap [cvladan/homebrew-tap](https://github.com/cvladan/homebrew-tap) on first install. To update later:

```sh
brew upgrade --cask browserpick
```

### First launch — unblock Gatekeeper

The release `.app` is ad-hoc signed, not Apple-notarized, so macOS quarantines it on download and refuses to launch the first time. Expect this — it's a one-time, two-click fix:

1. Brew installs the app to `/Applications/BrowserPick.app` and tries to launch it.
2. macOS shows: **"BrowserPick.app" was blocked to protect your Mac.** → click **Done**.
3. Open **System Settings → Privacy & Security**.
4. Scroll down to the security message: *"BrowserPick.app" was blocked to protect your Mac.* → click **Open Anyway**.
5. Confirm in the dialog (Touch ID or password).
6. The app launches and asks to be made the default browser — click **Use 'BrowserPick'**.

After this, BrowserPick launches normally, and `brew upgrade --cask browserpick` won't re-trigger the prompt for the same install path unless the binary identity changes.

CLI shortcut for the same thing (skips the Settings dance):

```sh
xattr -dr com.apple.quarantine /Applications/BrowserPick.app
```

If you didn't get the default-browser prompt automatically, set it manually in **System Settings → Desktop & Dock → Default web browser**.

## Release

No App Store, no notarization for now. Distribution has two pieces:

- **Source + release script** live in this repo.
- **Cask recipe** lives in a separate Homebrew tap repo: [cvladan/homebrew-tap](https://github.com/cvladan/homebrew-tap), at `Casks/browserpick.rb`.
- **The `.app` bundle** is **not** committed anywhere — it's attached as a binary asset to a GitHub Release in this repo, and the cask points brew at that URL.

The split is required because Homebrew taps must be in repos named `homebrew-*` and follow a specific layout. Keeping the recipe in its own repo also means `brew upgrade` works (you can't upgrade direct-URL cask installs).

### One-time setup

Install and authenticate the [GitHub CLI](https://cli.github.com) (only needed once per machine):

```sh
brew install gh
gh auth login
```

Clone the tap next to this repo so `release.sh` can write to it:

```sh
git clone https://github.com/cvladan/homebrew-tap ~/dev/homebrew-tap
```

`release.sh` looks for the tap at `~/dev/homebrew-tap`. Override with `TAP_DIR=/path/to/homebrew-tap ./release.sh ...` if you cloned it elsewhere.

### Cutting a release

For a routine patch release, run without an argument — the script reads the current version from `Info.plist` and bumps the patch component by one (e.g. `0.0.3` → `0.0.4`):

```sh
./release.sh
```

For a minor or major bump, pass the version explicitly:

```sh
./release.sh 0.1.0
```

That script:

1. Refuses to run if either working tree (this repo or the tap) is dirty, or if the tag already exists.
2. Pulls the tap to make sure it's up to date with origin.
3. Bumps `CFBundleShortVersionString` and `CFBundleVersion` in `Resources/Info.plist` via PlistBuddy, and commits the bump as `Release v0.0.2`. This is what the About panel reads — without this step every release would still show the old version.
4. Builds `.build/BrowserPick.app` (release config, ad-hoc signed).
5. Zips it to `.build/BrowserPick.zip` with `ditto` (preserves macOS metadata).
6. Computes the SHA256 of the zip.
7. Tags `v0.0.2` in this repo and pushes both `main` and the tag to `origin`.
8. Creates a GitHub Release `v0.0.2` here and uploads the zip as a release asset.
9. Rewrites `Casks/browserpick.rb` in the tap repo with the new `version` and `sha256`, commits (`browserpick 0.0.2`), and pushes the tap's `main`.

After it finishes, anyone in the world can `brew install --cask cvladan/tap/browserpick` (or `brew upgrade --cask browserpick`) and pick up the new build. Brew refreshes tap state with `brew update`, which usually runs implicitly.

### If something goes wrong mid-release

The script does effectful things in this order: bump Info.plist → commit → build → zip → tag → push main+tag → create release → edit tap cask → commit tap → push tap. If it dies partway, undo only what already happened:

- `git reset --hard HEAD~1` in this repo — undo the version-bump commit if it was made but nothing's been pushed yet.
- `git tag -d v0.0.2 && git push origin :refs/tags/v0.0.2` — delete a tag locally and on the remote.
- `gh release delete v0.0.2` — delete the Release if it was created.
- `cd ~/dev/homebrew-tap && git restore Casks/browserpick.rb` — undo the cask rewrite if the tap commit hasn't happened yet. If it has, `git reset --hard HEAD~1` (and force-push if you already pushed — only safe if no one else uses the tap).

Then fix the underlying issue and re-run.

## FAQ

**Why do I see a second process called "AutoFill (BrowserPick)" in Activity Monitor?**

That's `com.apple.AutoFillPanel`, a macOS XPC service for password/credit-card autofill UI. macOS automatically attaches it to any app registered as a browser (i.e. any app with `http`/`https` in `CFBundleURLTypes`) — you'll see the same helper next to Safari, Chrome, Arc, Velja, etc. BrowserPick does not start it and never invokes it (we have no web views or form input). It's a system-managed helper and costs ~12 MB. There's no way to opt out without giving up the http handler registration that makes the whole app work.

## Status

Alpha. Core features work: menubar icon, URL interception, browser chooser with keyboard shortcuts, settings window, browser discovery, launch at login. Not yet released.

## License

MIT (TBD — add `LICENSE` before first release).
