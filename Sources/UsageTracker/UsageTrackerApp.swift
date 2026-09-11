import SwiftUI
import UsageTrackerCore

@main
struct UsageTrackerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(appDelegate.appState)
        } label: {
            MenuBarLabel()
                .environmentObject(appDelegate.appState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appDelegate.appState)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let appState = AppState()
    let monitor = ActivityMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        monitor.start(appState: appState)
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.flushForQuit()
    }
}
