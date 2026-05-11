cask "browserpick" do
  version "0.0.1"
  sha256 "6a476b8bac99b8c5e3b6bd43b6efc468bd00a0b1c33fa8a9428201aaab607d70"

  url "https://github.com/cvladan/browser-pick/releases/download/v#{version}/BrowserPick.zip"
  name "BrowserPick"
  desc "Pick which browser opens a link"
  homepage "https://github.com/cvladan/browser-pick"

  app "BrowserPick.app"

  zap trash: [
    "~/Library/Preferences/com.cvladan.BrowserPick.plist",
    "~/Library/Application Support/BrowserPick",
  ]
end
