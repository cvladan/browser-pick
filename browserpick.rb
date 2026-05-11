cask "browserpick" do
  version "0.0.1"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

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
