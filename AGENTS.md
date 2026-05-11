# Agent guide

Notes for AI agents (Claude Code, etc.) working in this repo. Humans can read this too.

## What this project is

BrowserPick is a macOS menubar app that registers as the default `http(s)` handler and presents a chooser when a link is opened. See `README.md` for product scope.

## Stack

- Swift + SwiftUI + AppKit (`NSStatusItem`, `NSWorkspace`)
- Xcode project (not SPM-only — we need an `.app` bundle with Info.plist URL handler registration)
- macOS 13+

## Conventions

- Keep it small. This is a utility, not a platform. If a feature needs more than a few hundred LOC, push back and ask whether it belongs in v1.
- Native macOS feel. No web views, no Electron, no cross-platform abstractions. Use system fonts, system colors, standard keyboard shortcuts.
- No analytics, no telemetry, no network calls. The app intercepts URLs and hands them off — that's the entire trust surface.
- Prefer SwiftUI for views; drop to AppKit only where SwiftUI is awkward (menubar item, borderless transient panels, focus stealing).
- One window's worth of settings. Don't build a preferences pane with five tabs.

## Code style

- Swift API design guidelines. No Hungarian prefixes.
- File per type unless types are trivially small and tightly coupled.
- Comments only where the *why* is non-obvious (Gatekeeper quirks, undocumented AppKit behavior, etc.). Don't narrate the code.

## Things to be careful about

- **Default browser registration:** changing the system default browser triggers a macOS confirmation dialog the user must click. We can't and shouldn't try to bypass it.
- **Launch Services cache:** `lsregister` quirks during development. If URL routing stops working, `/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user` usually fixes it. Document any such gotcha in code comments.
- **Focus stealing:** the chooser popup must take focus immediately and accept keyboard input. This is finicky — test it from a background app (Slack, Mail) clicking a link.
- **Browser discovery:** list `LSCopyAllHandlersForURLScheme("http")` rather than hardcoding browser bundle IDs, but allow the user to add any `.app` manually.
- **Code signing / notarization:** dev builds are ad-hoc signed. Notarization is deferred until v1 release. Don't add notarization scripts speculatively.

## Distribution

- GitHub Releases for the `.zip` of the `.app`.
- Homebrew Cask in a separate repo (`homebrew-browserpick` or upstream `homebrew-cask` once stable).
- No auto-update mechanism in v1 — Homebrew handles upgrades.

## What NOT to add

- A built-in browser.
- URL rewriting / tracking-param stripping (separate concern, separate tool).
- Sync, accounts, cloud anything.
- A plugin system.
- Cross-platform support.

## When in doubt

Ask. This is a one-person side project, not a roadmap-driven product. Small, sharp, finished is the goal.
