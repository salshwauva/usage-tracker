import AppKit
import Foundation
import UsageTrackerCore

/// Front tab URL for browsers that speak AppleScript.
/// macOS will ask once for Automation permission per browser.
enum BrowserURL {
    static func current(bundleID: String) -> URL? {
        guard BrowserIDs.isBrowser(bundleID) else { return nil }
        guard let source = script(for: bundleID) else { return nil }
        guard let appleScript = NSAppleScript(source: source) else { return nil }
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)
        guard error == nil, let string = result.stringValue, let url = URL(string: string) else {
            return nil
        }
        return url
    }

    private static func script(for bundleID: String) -> String? {
        switch bundleID {
        case "com.google.Chrome", "com.google.Chrome.canary":
            return #"tell application "Google Chrome" to get URL of active tab of front window"#
        case "com.apple.Safari":
            return #"tell application "Safari" to get URL of current tab of front window"#
        case "com.brave.Browser":
            return #"tell application "Brave Browser" to get URL of active tab of front window"#
        case "com.microsoft.edgemac":
            return #"tell application "Microsoft Edge" to get URL of active tab of front window"#
        case "company.thebrowser.Browser":
            return #"tell application "Arc" to get URL of active tab of front window"#
        case "ai.perplexity.comet":
            return #"tell application id "ai.perplexity.comet" to get URL of active tab of front window"#
        default:
            return nil
        }
    }
}
