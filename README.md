# Swift Quit
Swift Quit enables automatic quitting of macOS apps when closing their windows (clicking the red x). It can be configured to quit when the last window of any app closed, or restricted to a specific list of apps. Additionally, you can exclude apps you dont want to quit automatically.

# Fork maintenance
This fork handles apps that retain hidden controller windows after their user-facing window closes. After a real window-close Accessibility event, it checks the WindowServer for a normal visible window instead of relying on the accessibility client's cached window list. It does not scan or quit inactive apps in the background.

# Build and install this fork
This fork uses its own app identity (`Swift Quit Fork`), so it can coexist with the original Swift Quit installation. On a Mac with Xcode installed, check out `main`, run `swift test`, then run `./Scripts/build-and-install-local.sh`. It builds, validates, and installs `Swift Quit Fork.app` in Applications. Enable that app in System Settings → Privacy & Security → Accessibility before using it.

When replacing a previous fork install, the script moves it to `.build/PreviousInstall/Swift Quit Fork.app` first. Remove or rename that backup before a later replacement.

The local build is intended for use on the Mac that built it. It is not a notarized replacement for the original developer's public release.

# Use At Your Own Risk
Some users have reported issues with unwanted closing of windows or other problems so use at your own risk.

# Website
https://swiftquit.com

# Download
https://swiftquit.com/downloads/Swift%20Quit.zip

# Installation Instructions
https://www.youtube.com/watch?v=WwWF-yekX-U

1. Install via Homebrew "brew install --cask swift-quit"
2. Or download from https://swiftquit.com, unzip, and move app to applications folder.
------------
3. Open finder to applications folder and ctrl+click swift quit.app then select open (You may need to do this twice)
5. When prompted click open system preferences
6. Unlock system preferences by clicking the lock icon
7. Drag Swift Quit.app into the accessibility list and enable it
8. Double click Swift Quit.app
9. Optionally enable start automatically in settings

# Upgrading To A New Version
In order to upgrade to a new version you must first remove the old version from Sytem Preferences => Security & Privacy => Accessibility.  Then you can drag the new version in and enable it.
